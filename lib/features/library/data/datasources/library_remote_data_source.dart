import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:student_management/core/constants/supabase_constants.dart';
import 'package:student_management/core/errors/app_exception.dart';
import 'package:student_management/core/errors/error_handler.dart';
import 'package:student_management/shared/models/book.dart';
import 'package:student_management/shared/models/borrow_record.dart';

class LibraryRemoteDataSource {
  final SupabaseClient _supabase;
  final Dio _dio;

  LibraryRemoteDataSource({required SupabaseClient supabase, Dio? dio})
    : _supabase = supabase,
      _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 15),
            ),
          );

  /// Searches books across Open Library API and cross-references with local Supabase books.
  Future<List<Book>> searchBooks(String query) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) return [];

    try {
      final isISBN = RegExp(r'^\d{10,13}$').hasMatch(trimmedQuery);
      final url =
          isISBN
              ? 'https://openlibrary.org/api/books?bibkeys=ISBN:$trimmedQuery&format=json&jscmd=data'
              : 'https://openlibrary.org/search.json?q=${Uri.encodeComponent(trimmedQuery)}&limit=10';

      final response = await _dio.get(url);
      final List<Book> books = [];

      if (response.statusCode == 200) {
        final dynamic rawData = response.data;
        final decoded = rawData is String ? json.decode(rawData) : rawData;

        if (isISBN) {
          final data =
              decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
          final bookData = data['ISBN:$trimmedQuery'] as Map<String, dynamic>?;

          if (bookData != null) {
            final title = (bookData['title'] ?? 'Unknown Title').toString();
            final authors = bookData['authors'] as List<dynamic>?;
            final author =
                authors != null && authors.isNotEmpty
                    ? (authors[0]['name'] ?? 'Unknown Author').toString()
                    : 'Unknown Author';
            final cover = bookData['cover'] as Map<String, dynamic>?;
            final coverUrl = (cover?['medium'] ?? '').toString();

            int copies = 4;
            try {
              copies = await getAvailableBookCopies(trimmedQuery);
            } catch (_) {
              copies = 4;
            }

            books.add(
              Book(
                id: trimmedQuery,
                title: title,
                author: author,
                isbn: trimmedQuery,
                coverUrl: coverUrl,
                copies: copies,
              ),
            );
          }
        } else {
          final data =
              decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
          final docs = (data['docs'] as List<dynamic>?) ?? [];

          for (final doc in docs) {
            if (doc is! Map<String, dynamic>) continue;
            final title = (doc['title'] ?? 'Unknown Title').toString();
            final authorNames = doc['author_name'] as List<dynamic>?;
            final author =
                authorNames != null && authorNames.isNotEmpty
                    ? authorNames.first.toString()
                    : 'Unknown Author';
            final isbns = doc['isbn'] as List<dynamic>?;
            final isbn =
                isbns != null && isbns.isNotEmpty
                    ? isbns.first.toString()
                    : 'N/A';
            final coverI = doc['cover_i'];
            final coverUrl =
                coverI != null
                    ? 'https://covers.openlibrary.org/b/id/$coverI-M.jpg'
                    : '';

            int availableCopies = 4;
            if (isbn != 'N/A' && isbn.isNotEmpty) {
              try {
                availableCopies = await getAvailableBookCopies(isbn);
              } catch (_) {
                availableCopies = 4;
              }
            }

            books.add(
              Book(
                id:
                    isbn != 'N/A' && isbn.isNotEmpty
                        ? isbn
                        : '${title}_$author',
                title: title,
                author: author,
                isbn: isbn,
                coverUrl: coverUrl,
                copies: availableCopies,
              ),
            );
          }
        }
      }

      return books;
    } catch (e) {
      throw ErrorHandler.handleException(e);
    }
  }

  /// Gets available copies count for a book by its [isbn].
  Future<int> getAvailableBookCopies(String isbn) async {
    try {
      final bookRecord =
          await _supabase
              .from(SupabaseConstants.booksTable)
              .select('id, copies')
              .eq('isbn', isbn)
              .maybeSingle();

      final totalCopies = (bookRecord?['copies'] as num?)?.toInt() ?? 4;

      final borrowedRecords = await _supabase
          .from(SupabaseConstants.borrowRecordsTable)
          .select('id')
          .eq('isbn', isbn)
          .filter('returned_at', 'is', null);

      final borrowedCount = (borrowedRecords as List<dynamic>).length;
      final available = totalCopies - borrowedCount;
      return available < 0 ? 0 : available;
    } catch (e) {
      throw ErrorHandler.handleException(e);
    }
  }

  /// Issues a book to a student with due date and atomic inventory deduction.
  Future<void> borrowBook({
    required String studentAuthId,
    required String studentRegisterNumber,
    required Book book,
    required DateTime dueDate,
  }) async {
    try {
      if (studentAuthId.trim().isEmpty) {
        throw const ValidationException('Student user ID cannot be empty.');
      }
      if (studentRegisterNumber.trim().isEmpty) {
        throw const ValidationException(
          'Student register number cannot be empty.',
        );
      }

      // 1. Ensure book exists in the books table and resolve targetBookId FIRST
      Map<String, dynamic>? existingBook;
      if (book.isbn.isNotEmpty && book.isbn != 'N/A') {
        existingBook =
            await _supabase
                .from(SupabaseConstants.booksTable)
                .select()
                .eq('isbn', book.isbn)
                .maybeSingle();
      } else if (book.id.isNotEmpty &&
          book.id != 'N/A' &&
          !book.id.contains('_')) {
        existingBook =
            await _supabase
                .from(SupabaseConstants.booksTable)
                .select()
                .eq('id', book.id)
                .maybeSingle();
      } else {
        existingBook =
            await _supabase
                .from(SupabaseConstants.booksTable)
                .select()
                .eq('title', book.title)
                .maybeSingle();
      }

      String targetBookId;
      int currentCopies = 4;

      if (existingBook != null) {
        targetBookId = existingBook['id'].toString();
        currentCopies = (existingBook['copies'] as num?)?.toInt() ?? 4;
      } else {
        final inserted =
            await _supabase
                .from(SupabaseConstants.booksTable)
                .insert({
                  'title': book.title,
                  'author': book.author,
                  'isbn': book.isbn,
                  'cover_url': book.coverUrl,
                  'copies': 4,
                  'created_at': DateTime.now().toIso8601String(),
                })
                .select()
                .maybeSingle();

        if (inserted == null) {
          throw const DatabaseException(
            'Failed to register book in inventory database.',
          );
        }
        targetBookId = inserted['id'].toString();
        currentCopies = (inserted['copies'] as num?)?.toInt() ?? 4;
      }

      // 2. Accurate duplicate loan check by targetBookId (prevents 'N/A' ISBN collisions)
      final activeLoan =
          await _supabase
              .from(SupabaseConstants.borrowRecordsTable)
              .select('id')
              .eq('register_number', studentRegisterNumber.trim())
              .eq('book_id', targetBookId)
              .filter('returned_at', 'is', null)
              .maybeSingle();

      if (activeLoan != null) {
        throw const ValidationException(
          'Student has already borrowed an unreturned copy of this book.',
        );
      }

      // 3. Verify available copies
      final activeBorrowRecords = await _supabase
          .from(SupabaseConstants.borrowRecordsTable)
          .select('id')
          .eq('book_id', targetBookId)
          .filter('returned_at', 'is', null);

      final activeCount = (activeBorrowRecords as List<dynamic>).length;
      if (activeCount >= currentCopies || currentCopies <= 0) {
        throw const ValidationException(
          'No copies of this book are currently available.',
        );
      }

      final now = DateTime.now();

      // 4. Insert borrow record
      final insertedRecord =
          await _supabase
              .from(SupabaseConstants.borrowRecordsTable)
              .insert({
                'user_id': studentAuthId,
                'register_number': studentRegisterNumber.trim(),
                'book_id': targetBookId,
                'isbn': book.isbn,
                'borrowed_at': now.toIso8601String(),
                'due_date': dueDate.toIso8601String(),
                'returned_at': null,
                'status': 'borrowed',
              })
              .select('id')
              .maybeSingle();

      final borrowRecordId = insertedRecord?['id']?.toString();

      // 5. Decrement book copies with compensating rollback if failed
      try {
        final newCopies = (currentCopies - 1) < 0 ? 0 : currentCopies - 1;
        await _supabase
            .from(SupabaseConstants.booksTable)
            .update({'copies': newCopies})
            .eq('id', targetBookId);
      } catch (e) {
        // Compensating rollback: remove the newly inserted borrow record
        if (borrowRecordId != null) {
          await _supabase
              .from(SupabaseConstants.borrowRecordsTable)
              .delete()
              .eq('id', borrowRecordId);
        }
        throw ErrorHandler.handleException(e);
      }
    } catch (e) {
      throw ErrorHandler.handleException(e);
    }
  }

  /// Fetches active (unreturned) loans for a student by their register number.
  Future<List<BorrowRecord>> getActiveLoansForStudent(
    String registerNumber,
  ) async {
    try {
      final response = await _supabase
          .from(SupabaseConstants.borrowRecordsTable)
          .select('''
            id,
            user_id,
            register_number,
            isbn,
            book_id,
            borrowed_at,
            due_date,
            returned_at,
            status,
            books (
              id,
              title,
              author,
              cover_url,
              isbn,
              copies
            )
          ''')
          .eq('register_number', registerNumber.trim())
          .filter('returned_at', 'is', null)
          .order('borrowed_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      return data
          .map((json) => BorrowRecord.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ErrorHandler.handleException(e);
    }
  }

  /// Processes returning a borrowed book and increments available copies.
  Future<void> returnBook({
    required String borrowRecordId,
    required String bookId,
  }) async {
    try {
      if (borrowRecordId.trim().isEmpty) {
        throw const ValidationException('Borrow record ID cannot be empty.');
      }

      final now = DateTime.now().toIso8601String();

      // 1. Atomically update borrow record ONLY if returned_at IS NULL (idempotency guard)
      final updateResult = await _supabase
          .from(SupabaseConstants.borrowRecordsTable)
          .update({'returned_at': now, 'status': 'returned'})
          .eq('id', borrowRecordId.trim())
          .filter('returned_at', 'is', null)
          .select('id, book_id');

      final updatedList = (updateResult as List<dynamic>?) ?? [];

      // If no row was updated, check if the record exists and was already returned
      if (updatedList.isEmpty) {
        final existing =
            await _supabase
                .from(SupabaseConstants.borrowRecordsTable)
                .select('id, returned_at')
                .eq('id', borrowRecordId.trim())
                .maybeSingle();

        if (existing != null && existing['returned_at'] != null) {
          // Already returned. Idempotent no-op to prevent duplicate inventory increment!
          return;
        } else {
          throw const NotFoundException('Active borrow record not found.');
        }
      }

      // Resolve actual book_id from the verified borrow record
      final resolvedBookId =
          (bookId.trim().isNotEmpty)
              ? bookId.trim()
              : (updatedList.first['book_id']?.toString() ?? '');

      // 2. Increment book copies if bookId is available with compensating rollback
      if (resolvedBookId.isNotEmpty) {
        final bookRecord =
            await _supabase
                .from(SupabaseConstants.booksTable)
                .select('copies')
                .eq('id', resolvedBookId)
                .maybeSingle();

        if (bookRecord != null) {
          final currentCopies = (bookRecord['copies'] as num?)?.toInt() ?? 0;
          try {
            await _supabase
                .from(SupabaseConstants.booksTable)
                .update({'copies': currentCopies + 1})
                .eq('id', resolvedBookId);
          } catch (e) {
            // Compensating rollback: restore the borrow record to unreturned
            await _supabase
                .from(SupabaseConstants.borrowRecordsTable)
                .update({'returned_at': null, 'status': 'borrowed'})
                .eq('id', borrowRecordId.trim());
            throw ErrorHandler.handleException(e);
          }
        }
      }
    } catch (e) {
      throw ErrorHandler.handleException(e);
    }
  }

  /// Fetches global borrow history log with optional standard, status, and sort filters.
  Future<List<BorrowRecord>> getGlobalBorrowHistory({
    String? standard,
    String? statusFilter,
    String? sortOrder,
  }) async {
    try {
      final response = await _supabase
          .from(SupabaseConstants.borrowRecordsTable)
          .select('''
            id,
            user_id,
            register_number,
            isbn,
            book_id,
            borrowed_at,
            due_date,
            returned_at,
            status,
            books (
              id,
              title,
              author,
              cover_url,
              isbn,
              copies
            )
          ''')
          .order('borrowed_at', ascending: false);

      final List<dynamic> borrowList = response as List<dynamic>;

      // Enrich with students info from public.students to resolve studentName and standard
      // (Bypasses missing DB foreign key between borrow_records and students)
      final studentsResponse = await _supabase
          .from(SupabaseConstants.studentsTable)
          .select(
            'id, user_id, register_number, first_name, last_name, standard',
          );

      final List<dynamic> studentList =
          (studentsResponse as List<dynamic>?) ?? [];
      final Map<String, Map<String, dynamic>> studentsByReg = {};
      final Map<String, Map<String, dynamic>> studentsByUserId = {};

      for (final st in studentList) {
        if (st is! Map<String, dynamic>) continue;
        final reg = st['register_number']?.toString();
        final uid = st['user_id']?.toString() ?? st['id']?.toString();
        if (reg != null && reg.isNotEmpty) studentsByReg[reg] = st;
        if (uid != null && uid.isNotEmpty) studentsByUserId[uid] = st;
      }

      List<BorrowRecord> records =
          borrowList.map((item) {
            final map = Map<String, dynamic>.from(item as Map<String, dynamic>);
            final reg = map['register_number']?.toString() ?? '';
            final uid = map['user_id']?.toString() ?? '';

            final studentData = studentsByReg[reg] ?? studentsByUserId[uid];
            if (studentData != null) {
              final fname = studentData['first_name']?.toString() ?? '';
              final lname = studentData['last_name']?.toString() ?? '';
              final name = '$fname $lname'.trim();
              map['student_name'] = name.isNotEmpty ? name : 'Unknown Student';
              map['standard'] = studentData['standard']?.toString() ?? 'N/A';
            } else {
              map['student_name'] = 'Student #$reg';
              map['standard'] = 'N/A';
            }

            return BorrowRecord.fromJson(map);
          }).toList();

      // Apply standard filter
      if (standard != null && standard.isNotEmpty && standard != 'All') {
        records = records.where((r) => r.standard == standard).toList();
      }

      // Apply status filter
      if (statusFilter != null &&
          statusFilter.isNotEmpty &&
          statusFilter != 'All') {
        records =
            records.where((r) {
              final statusName = r.status.name.toLowerCase();
              return statusName == statusFilter.toLowerCase();
            }).toList();
      }

      // Apply sorting
      if (sortOrder != null) {
        switch (sortOrder) {
          case 'A-Z':
            records.sort(
              (a, b) => a.bookTitle.toLowerCase().compareTo(
                b.bookTitle.toLowerCase(),
              ),
            );
            break;
          case 'Z-A':
            records.sort(
              (a, b) => b.bookTitle.toLowerCase().compareTo(
                a.bookTitle.toLowerCase(),
              ),
            );
            break;
          case 'Register Number ↑':
            records.sort(
              (a, b) =>
                  a.studentRegisterNumber.compareTo(b.studentRegisterNumber),
            );
            break;
          case 'Register Number ↓':
            records.sort(
              (a, b) =>
                  b.studentRegisterNumber.compareTo(a.studentRegisterNumber),
            );
            break;
          case 'Due Date ↑':
            records.sort((a, b) => a.dueDate.compareTo(b.dueDate));
            break;
          case 'Due Date ↓':
            records.sort((a, b) => b.dueDate.compareTo(a.dueDate));
            break;
          default:
            records.sort((a, b) => b.borrowedAt.compareTo(a.borrowedAt));
            break;
        }
      }

      return records;
    } catch (e) {
      throw ErrorHandler.handleException(e);
    }
  }

  /// Fetches personal borrow history for a specific student by [studentAuthId].
  Future<List<BorrowRecord>> getStudentBorrowHistory(
    String studentAuthId,
  ) async {
    try {
      final response = await _supabase
          .from(SupabaseConstants.borrowRecordsTable)
          .select('''
            id,
            user_id,
            register_number,
            isbn,
            book_id,
            borrowed_at,
            due_date,
            returned_at,
            status,
            books (
              id,
              title,
              author,
              cover_url,
              isbn,
              copies
            )
          ''')
          .eq('user_id', studentAuthId)
          .order('borrowed_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      return data
          .map((json) => BorrowRecord.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ErrorHandler.handleException(e);
    }
  }
}
