import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:student_management/core/errors/app_exception.dart';
import 'package:student_management/features/library/data/datasources/library_remote_data_source.dart';
import 'package:student_management/features/library/domain/repositories/i_library_repository.dart';
import 'package:student_management/features/library/presentation/providers/library_providers.dart';
import 'package:student_management/features/library/presentation/screens/borrow_book_screen.dart';
import 'package:student_management/features/library/presentation/screens/library_history_screen.dart';
import 'package:student_management/features/library/presentation/screens/library_management_screen.dart';
import 'package:student_management/features/library/presentation/screens/return_book_screen.dart';
import 'package:student_management/features/students/domain/repositories/i_student_repository.dart';
import 'package:student_management/features/students/presentation/providers/student_providers.dart';
import 'package:student_management/shared/models/book.dart';
import 'package:student_management/shared/models/borrow_record.dart';
import 'package:student_management/shared/models/student.dart';
import 'dart:io';

class MockDioAdapter implements HttpClientAdapter {
  final ResponseBody Function(RequestOptions options) handler;
  MockDioAdapter(this.handler);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

class MockStudentRepository implements IStudentRepository {
  final List<Student> _students = [
    Student(
      id: 'std-1',
      userId: 'auth-std-1',
      firstName: 'Alice',
      lastName: 'Smith',
      registerNumber: '10800001',
      standard: '10th',
      email: 'alice@school.com',
      phone: '1234567890',
      address: '123 Maple St',
      dob: DateTime(2008, 5, 12),
    ),
    Student(
      id: 'std-2',
      userId: 'auth-std-2',
      firstName: 'Bob',
      lastName: 'Jones',
      registerNumber: '10800002',
      standard: '9th',
      email: 'bob@school.com',
      phone: '9876543210',
      address: '456 Oak Ave',
      dob: DateTime(2009, 8, 20),
    ),
  ];

  @override
  Future<Student?> getStudentByRegisterNumber(String registerNumber) async {
    final match = _students.where((s) => s.registerNumber == registerNumber);
    return match.isNotEmpty ? match.first : null;
  }

  @override
  Future<List<Student>> getStudents({String? standard, String? searchQuery, String? sortOrder = 'A-Z'}) async {
    return _students;
  }

  @override
  Future<Student> getStudentById(String id) async => _students.firstWhere((s) => s.id == id);

  @override
  Future<void> createStudent({required Student student, required String password, File? avatarFile}) async {}

  @override
  Future<void> updateStudent({required Student student, File? avatarFile}) async {}

  @override
  Future<void> deleteStudent({required String studentId, required String authId, String? email}) async {}

  @override
  Future<Map<String, int>> bulkDeleteStudents(List<Student> students) async => {'success': students.length, 'fail': 0};

  @override
  Future<String> generateNextRegisterNumber() async => '10800099';
}

class MockLibraryRepository implements ILibraryRepository {
  final List<Book> _books = [
    Book(
      id: 'bk-1',
      title: 'The Great Gatsby',
      author: 'F. Scott Fitzgerald',
      isbn: '9780743273565',
      coverUrl: '',
      copies: 4,
    ),
    Book(
      id: 'bk-2',
      title: 'To Kill a Mockingbird',
      author: 'Harper Lee',
      isbn: '9780061120084',
      coverUrl: '',
      copies: 0, // out of stock
    ),
    Book(
      id: 'bk-3',
      title: '1984',
      author: 'George Orwell',
      isbn: '9780451524935',
      coverUrl: '',
      copies: 2,
    ),
  ];

  final List<BorrowRecord> _borrowRecords = [
    BorrowRecord(
      id: 'rec-1',
      bookId: 'bk-1',
      bookTitle: 'The Great Gatsby',
      bookAuthor: 'F. Scott Fitzgerald',
      isbn: '9780743273565',
      coverUrl: '',
      userId: 'auth-std-1',
      studentRegisterNumber: '10800001',
      studentName: 'Alice Smith',
      standard: '10th',
      borrowedAt: DateTime.now().subtract(const Duration(days: 2)),
      dueDate: DateTime.now().add(const Duration(days: 10)),
    ),
    BorrowRecord(
      id: 'rec-2',
      bookId: 'bk-3',
      bookTitle: '1984',
      bookAuthor: 'George Orwell',
      isbn: '9780451524935',
      coverUrl: '',
      userId: 'auth-std-2',
      studentRegisterNumber: '10800002',
      studentName: 'Bob Jones',
      standard: '9th',
      borrowedAt: DateTime(2026, 9, 1),
      dueDate: DateTime(2026, 9, 15),
      returnedAt: DateTime(2026, 9, 14),
    ),
    BorrowRecord(
      id: 'rec-3',
      bookId: 'bk-1',
      bookTitle: 'The Great Gatsby',
      bookAuthor: 'F. Scott Fitzgerald',
      isbn: '9780743273565',
      coverUrl: '',
      userId: 'auth-std-2',
      studentRegisterNumber: '10800002',
      studentName: 'Bob Jones',
      standard: '9th',
      borrowedAt: DateTime(2026, 9, 1),
      dueDate: DateTime(2026, 9, 10), // overdue because dueDate is before now
    ),
  ];

  @override
  Future<List<Book>> searchBooks(String query) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return _books;
    return _books.where((b) => b.title.toLowerCase().contains(q) || b.author.toLowerCase().contains(q) || b.isbn.contains(q)).toList();
  }

  @override
  Future<int> getAvailableBookCopies(String isbn) async {
    final book = _books.firstWhere((b) => b.isbn == isbn, orElse: () => Book(id: '', title: '', author: '', isbn: isbn, coverUrl: '', copies: 4));
    final activeLoans = _borrowRecords.where((r) => r.isbn == isbn && r.returnedAt == null).length;
    return (book.copies - activeLoans).clamp(0, 9999);
  }

  @override
  Future<void> borrowBook({
    required String studentAuthId,
    required String studentRegisterNumber,
    required Book book,
    required DateTime dueDate,
  }) async {
    final available = await getAvailableBookCopies(book.isbn);
    if (available <= 0) {
      throw ValidationException('No available copies left for "${book.title}".');
    }

    final hasActive = _borrowRecords.any(
      (r) =>
          r.studentRegisterNumber == studentRegisterNumber &&
          (r.bookId == book.id || (book.isbn.isNotEmpty && book.isbn != 'N/A' && r.isbn == book.isbn)) &&
          r.returnedAt == null,
    );
    if (hasActive) {
      throw ValidationException('Student already has an active borrow record for this book.');
    }

    final newRecord = BorrowRecord(
      id: 'rec-${_borrowRecords.length + 1}',
      bookId: book.id,
      bookTitle: book.title,
      bookAuthor: book.author,
      isbn: book.isbn,
      coverUrl: book.coverUrl,
      userId: studentAuthId,
      studentRegisterNumber: studentRegisterNumber,
      studentName: 'Verified Student',
      standard: '10th',
      borrowedAt: DateTime.now(),
      dueDate: dueDate,
    );
    _borrowRecords.add(newRecord);
  }

  @override
  Future<List<BorrowRecord>> getActiveLoansForStudent(String registerNumber) async {
    return _borrowRecords
        .where((r) => r.studentRegisterNumber == registerNumber && r.returnedAt == null)
        .toList();
  }

  @override
  Future<void> returnBook({
    required String borrowRecordId,
    required String bookId,
  }) async {
    final index = _borrowRecords.indexWhere((r) => r.id == borrowRecordId);
    if (index == -1) {
      throw NotFoundException('Borrow record not found.');
    }

    final old = _borrowRecords[index];
    if (old.returnedAt != null) {
      // Idempotency guard: already returned, no duplicate action
      return;
    }
    _borrowRecords[index] = BorrowRecord(
      id: old.id,
      bookId: old.bookId,
      bookTitle: old.bookTitle,
      bookAuthor: old.bookAuthor,
      isbn: old.isbn,
      coverUrl: old.coverUrl,
      userId: old.userId,
      studentRegisterNumber: old.studentRegisterNumber,
      studentName: old.studentName,
      standard: old.standard,
      borrowedAt: old.borrowedAt,
      dueDate: old.dueDate,
      returnedAt: DateTime.now(),
    );
  }

  @override
  Future<List<BorrowRecord>> getGlobalBorrowHistory({
    String? standard,
    String? statusFilter,
    String? sortOrder = 'A-Z',
  }) async {
    List<BorrowRecord> records = List.from(_borrowRecords);

    if (standard != null && standard != 'All') {
      records = records.where((r) => r.standard == standard).toList();
    }

    if (statusFilter != null && statusFilter != 'All') {
      records = records.where((r) => r.status.displayName.toLowerCase() == statusFilter.toLowerCase()).toList();
    }

    switch (sortOrder) {
      case 'Z-A':
        records.sort((a, b) => b.bookTitle.toLowerCase().compareTo(a.bookTitle.toLowerCase()));
        break;
      case 'Register Number ↑':
        records.sort((a, b) => a.studentRegisterNumber.compareTo(b.studentRegisterNumber));
        break;
      case 'Register Number ↓':
        records.sort((a, b) => b.studentRegisterNumber.compareTo(a.studentRegisterNumber));
        break;
      case 'Due Date ↑':
        records.sort((a, b) => a.dueDate.compareTo(b.dueDate));
        break;
      case 'Due Date ↓':
        records.sort((a, b) => b.dueDate.compareTo(a.dueDate));
        break;
      case 'A-Z':
      default:
        records.sort((a, b) => a.bookTitle.toLowerCase().compareTo(b.bookTitle.toLowerCase()));
        break;
    }

    return records;
  }

  @override
  Future<List<BorrowRecord>> getStudentBorrowHistory(String studentAuthId) async {
    return _borrowRecords.where((r) => r.userId == studentAuthId).toList();
  }
}

void main() {
  group('Phase 4 Library Repository Unit Tests', () {
    late MockLibraryRepository libraryRepo;

    setUp(() {
      libraryRepo = MockLibraryRepository();
    });

    test('1. Search books returns matching items by title or author', () async {
      final results = await libraryRepo.searchBooks('gatsby');
      expect(results.length, equals(1));
      expect(results.first.title, equals('The Great Gatsby'));

      final authorResults = await libraryRepo.searchBooks('Orwell');
      expect(authorResults.length, equals(1));
      expect(authorResults.first.author, equals('George Orwell'));
    });

    test('2. Available copies calculates total minus unreturned loans', () async {
      // bk-1 has 4 total copies, 2 active unreturned records (rec-1 and rec-3)
      final available = await libraryRepo.getAvailableBookCopies('9780743273565');
      expect(available, equals(2));

      // bk-2 has 0 copies
      final zeroAvailable = await libraryRepo.getAvailableBookCopies('9780061120084');
      expect(zeroAvailable, equals(0));
    });

    test('3. Borrow book enforces stock availability and duplicate checks', () async {
      final outOfStockBook = Book(
        id: 'bk-2',
        title: 'To Kill a Mockingbird',
        author: 'Harper Lee',
        isbn: '9780061120084',
        coverUrl: '',
        copies: 0,
      );

      // Throws when out of stock
      expect(
        () => libraryRepo.borrowBook(
          studentAuthId: 'auth-std-1',
          studentRegisterNumber: '10800001',
          book: outOfStockBook,
          dueDate: DateTime.now().add(const Duration(days: 7)),
        ),
        throwsA(isA<ValidationException>()),
      );

      final inStockBook = Book(
        id: 'bk-1',
        title: 'The Great Gatsby',
        author: 'F. Scott Fitzgerald',
        isbn: '9780743273565',
        coverUrl: '',
        copies: 4,
      );

      // Throws when student already has an active loan of this book
      expect(
        () => libraryRepo.borrowBook(
          studentAuthId: 'auth-std-1',
          studentRegisterNumber: '10800001',
          book: inStockBook,
          dueDate: DateTime.now().add(const Duration(days: 7)),
        ),
        throwsA(isA<ValidationException>()),
      );

      // Successfully borrows book 1984 for student 1
      final borrowBook3 = Book(
        id: 'bk-3',
        title: '1984',
        author: 'George Orwell',
        isbn: '9780451524935',
        coverUrl: '',
        copies: 2,
      );

      await libraryRepo.borrowBook(
        studentAuthId: 'auth-std-1',
        studentRegisterNumber: '10800001',
        book: borrowBook3,
        dueDate: DateTime.now().add(const Duration(days: 14)),
      );

      final activeLoans = await libraryRepo.getActiveLoansForStudent('10800001');
      expect(activeLoans.length, equals(2));
      expect(activeLoans.any((l) => l.bookTitle == '1984'), isTrue);
    });

    test('4. Return book updates record status and timestamp', () async {
      final beforeLoans = await libraryRepo.getActiveLoansForStudent('10800001');
      expect(beforeLoans.length, equals(1));
      final recordId = beforeLoans.first.id;

      await libraryRepo.returnBook(borrowRecordId: recordId, bookId: beforeLoans.first.bookId);

      final afterLoans = await libraryRepo.getActiveLoansForStudent('10800001');
      expect(afterLoans.isEmpty, isTrue);
    });

    test('5. Global borrow history filters by standard, status and sorts', () async {
      final tenthGrade = await libraryRepo.getGlobalBorrowHistory(standard: '10th');
      expect(tenthGrade.length, equals(1));
      expect(tenthGrade.first.studentName, equals('Alice Smith'));

      final returned = await libraryRepo.getGlobalBorrowHistory(statusFilter: 'Returned');
      expect(returned.length, equals(1));
      expect(returned.first.status, equals(BorrowStatus.returned));

      final sortedZA = await libraryRepo.getGlobalBorrowHistory(sortOrder: 'Z-A');
      expect(sortedZA.first.bookTitle, equals('The Great Gatsby'));
      expect(sortedZA.last.bookTitle, equals('1984'));
    });
  });

  group('Phase 4 Riverpod Controller State Tests', () {
    late MockLibraryRepository libraryRepo;
    late MockStudentRepository studentRepo;
    late ProviderContainer container;

    setUp(() {
      libraryRepo = MockLibraryRepository();
      studentRepo = MockStudentRepository();
      container = ProviderContainer(
        overrides: [
          libraryRepositoryProvider.overrideWithValue(libraryRepo),
          studentRepositoryProvider.overrideWithValue(studentRepo),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('6. BorrowBookController student verification and book selection flow', () async {
      final controller = container.read(borrowBookControllerProvider.notifier);

      // Initial state
      expect(container.read(borrowBookControllerProvider).selectedBook, isNull);
      expect(container.read(borrowBookControllerProvider).verifiedStudent, isNull);

      // Verify student lookup failure
      await controller.verifyStudentByRegister('99999999');
      expect(container.read(borrowBookControllerProvider).verifiedStudent, isNull);
      expect(container.read(borrowBookControllerProvider).errorMessage, contains('No student found'));

      // Verify student lookup success
      await controller.verifyStudentByRegister('10800001');
      expect(container.read(borrowBookControllerProvider).verifiedStudent?.firstName, equals('Alice'));
      expect(container.read(borrowBookControllerProvider).errorMessage, isNull);

      // Select book
      final book = Book(
        id: 'bk-3',
        title: '1984',
        author: 'George Orwell',
        isbn: '9780451524935',
        coverUrl: '',
        copies: 2,
      );
      controller.setSelectedBook(book);
      expect(container.read(borrowBookControllerProvider).selectedBook?.title, equals('1984'));

      // Perform borrow
      final success = await controller.borrowBook();
      expect(success, isTrue);
      expect(container.read(borrowBookControllerProvider).successMessage, contains('borrowed successfully'));
      expect(container.read(borrowBookControllerProvider).selectedBook, isNull);
      expect(container.read(borrowBookControllerProvider).verifiedStudent, isNull);
    });

    test('7. ReturnBookController searches student loans and executes return', () async {
      final controller = container.read(returnBookControllerProvider.notifier);

      // Search with active loans
      await controller.searchLoans('10800001');
      var state = container.read(returnBookControllerProvider);
      expect(state.hasSearched, isTrue);
      expect(state.activeLoans.length, equals(1));
      expect(state.activeLoans.first.bookTitle, equals('The Great Gatsby'));

      // Return the loan
      final success = await controller.returnBook(state.activeLoans.first);
      expect(success, isTrue);

      state = container.read(returnBookControllerProvider);
      expect(state.activeLoans.isEmpty, isTrue);
      expect(state.successMessage, contains('returned successfully'));
    });

    test('8. LibraryHistoryController filters, searches and sorts records', () async {
      final controller = container.read(libraryHistoryControllerProvider.notifier);

      await controller.loadHistory();
      var state = container.read(libraryHistoryControllerProvider);
      expect(state.history.length, equals(3));
      expect(state.filteredHistory.length, equals(3));

      // Filter by search query
      controller.setSearchQuery('Orwell');
      state = container.read(libraryHistoryControllerProvider);
      expect(state.filteredHistory.length, equals(1));
      expect(state.filteredHistory.first.bookTitle, equals('1984'));

      // Clear search and filter by standard
      controller.setSearchQuery('');
      controller.setStandard('10th');
      await controller.loadHistory();
      state = container.read(libraryHistoryControllerProvider);
      expect(state.filteredHistory.length, equals(1));
      expect(state.filteredHistory.first.studentName, equals('Alice Smith'));
    });
  });

  group('Phase 4 Riverpod Widget Tests', () {
    late MockLibraryRepository libraryRepo;
    late MockStudentRepository studentRepo;

    setUp(() {
      libraryRepo = MockLibraryRepository();
      studentRepo = MockStudentRepository();
    });

    testWidgets('9. LibraryManagementScreen renders three hub action cards', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            libraryRepositoryProvider.overrideWithValue(libraryRepo),
            studentRepositoryProvider.overrideWithValue(studentRepo),
          ],
          child: const MaterialApp(
            home: LibraryManagementScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Library Management'), findsOneWidget);
      expect(find.text('Borrow Book'), findsOneWidget);
      expect(find.text('Return Book'), findsOneWidget);
      expect(find.text('Library History Page'), findsOneWidget);
      expect(find.byIcon(Icons.menu_book), findsOneWidget);
      expect(find.byIcon(Icons.assignment_returned), findsOneWidget);
      expect(find.byIcon(Icons.history), findsOneWidget);
    });

    testWidgets('10. ReturnBookScreen renders input, searches student and shows loans', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            libraryRepositoryProvider.overrideWithValue(libraryRepo),
            studentRepositoryProvider.overrideWithValue(studentRepo),
          ],
          child: const MaterialApp(
            home: ReturnBookScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Return Books'), findsOneWidget);
      expect(find.text('Registration Number'), findsOneWidget);
      expect(find.text('Enter a student registration number\nto view active borrowed books.'), findsOneWidget);

      // Enter register number and tap search
      await tester.enterText(find.byType(TextFormField), '10800001');
      await tester.tap(find.text('Search'));
      await tester.pumpAndSettle();

      // Loan card for The Great Gatsby should appear
      expect(find.text('The Great Gatsby'), findsOneWidget);
      expect(find.text('by F. Scott Fitzgerald'), findsOneWidget);
      expect(find.text('Return Book'), findsWidgets);
    });

    testWidgets('11. LibraryHistoryScreen renders search bar, filters and history cards', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            libraryRepositoryProvider.overrideWithValue(libraryRepo),
            studentRepositoryProvider.overrideWithValue(studentRepo),
          ],
          child: const MaterialApp(
            home: LibraryHistoryScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Library History'), findsOneWidget);
      expect(find.text('The Great Gatsby'), findsWidgets);
      expect(find.text('1984'), findsOneWidget);
      expect(find.text('Alice Smith (10800001)'), findsOneWidget);
      expect(find.text('Bob Jones (10800002)'), findsWidgets);
      expect(find.text('Class: 10th'), findsOneWidget);
      expect(find.text('Borrowed'), findsOneWidget);
      expect(find.text('Returned'), findsOneWidget);
      expect(find.text('Overdue'), findsOneWidget);
    });

    testWidgets('12. BorrowBookScreen validates required selection before submission', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            libraryRepositoryProvider.overrideWithValue(libraryRepo),
            studentRepositoryProvider.overrideWithValue(studentRepo),
          ],
          child: const MaterialApp(
            home: BorrowBookScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Borrow Book'), findsWidgets);
      expect(find.text('Tap to search and select a book'), findsOneWidget);
      expect(find.text('Registration Number'), findsOneWidget);
      expect(find.text('2. Student Verification'), findsOneWidget);
      expect(find.text('Return Due Date'), findsOneWidget);

      final submitBtn = tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Borrow Book'));
      expect(submitBtn.onPressed, isNull);
    });
  });

  group('Phase 4 Open Library Network Response Mapping Test', () {
    test('13. Open Library JSON response correctly maps to Book model with copies', () async {
      final dio = Dio();
      dio.httpClientAdapter = MockDioAdapter((options) {
        if (options.uri.host == 'openlibrary.org' && options.uri.path.contains('/search.json')) {
          return ResponseBody.fromString(
            jsonEncode({
              'numFound': 1,
              'docs': [
                {
                  'title': 'Design Patterns',
                  'author_name': ['Erich Gamma', 'Richard Helm'],
                  'isbn': ['9780201633610'],
                  'cover_i': 123456,
                }
              ]
            }),
            200,
            headers: {
              'content-type': ['application/json'],
            },
          );
        }
        return ResponseBody.fromString('{}', 404);
      });

      // Construct a mock supabase client pointing to dummy host
      final client = SupabaseClient('https://mock.supabase.co', 'dummy-key');
      final dataSource = LibraryRemoteDataSource(supabase: client, dio: dio);

      final books = await dataSource.searchBooks('Design Patterns');
      expect(books.length, equals(1));
      expect(books.first.title, equals('Design Patterns'));
      expect(books.first.author, equals('Erich Gamma'));
      expect(books.first.isbn, equals('9780201633610'));
      expect(books.first.coverUrl, contains('123456'));
    });

    test('14. Repeated return requests on already-returned record are idempotent', () async {
      final repo = MockLibraryRepository();
      final loans = await repo.getActiveLoansForStudent('10800001');
      expect(loans.length, equals(1));
      final loanId = loans.first.id;
      final bookId = loans.first.bookId;

      // 1st return
      await repo.returnBook(borrowRecordId: loanId, bookId: bookId);
      final remaining = await repo.getActiveLoansForStudent('10800001');
      expect(remaining.isEmpty, isTrue);

      // 2nd repeated return does not throw or corrupt state
      await repo.returnBook(borrowRecordId: loanId, bookId: bookId);
      final stillEmpty = await repo.getActiveLoansForStudent('10800001');
      expect(stillEmpty.isEmpty, isTrue);
    });

    test('15. Duplicate loan checks by book identifier correctly allow different N/A ISBN books', () async {
      final repo = MockLibraryRepository();

      // Book A with N/A ISBN
      final bookA = Book(id: 'manual-bk-A', title: 'Dracula', author: 'Bram Stoker', isbn: 'N/A', coverUrl: '', copies: 2);
      // Book B with N/A ISBN
      final bookB = Book(id: 'manual-bk-B', title: 'Frankenstein', author: 'Mary Shelley', isbn: 'N/A', coverUrl: '', copies: 2);

      // Student 1 borrows Book A
      await repo.borrowBook(
        studentAuthId: 'auth-std-1',
        studentRegisterNumber: '10800001',
        book: bookA,
        dueDate: DateTime.now().add(const Duration(days: 14)),
      );

      // Student 1 borrowing Book A again should be blocked as duplicate
      expect(
        () => repo.borrowBook(
          studentAuthId: 'auth-std-1',
          studentRegisterNumber: '10800001',
          book: bookA,
          dueDate: DateTime.now().add(const Duration(days: 7)),
        ),
        throwsA(isA<ValidationException>()),
      );

      // Student 1 borrowing Book B (also with N/A ISBN) should NOT be falsely blocked!
      await repo.borrowBook(
        studentAuthId: 'auth-std-1',
        studentRegisterNumber: '10800001',
        book: bookB,
        dueDate: DateTime.now().add(const Duration(days: 14)),
      );

      final studentLoans = await repo.getActiveLoansForStudent('10800001');
      expect(studentLoans.any((l) => l.bookTitle == 'Frankenstein'), isTrue);
    });
  });
}
