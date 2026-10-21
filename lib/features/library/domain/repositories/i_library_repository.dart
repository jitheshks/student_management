import 'package:student_management/shared/models/book.dart';
import 'package:student_management/shared/models/borrow_record.dart';

abstract class ILibraryRepository {
  /// Searches books across Open Library API and local database cache.
  Future<List<Book>> searchBooks(String query);

  /// Gets available copies count for a book by its [isbn].
  Future<int> getAvailableBookCopies(String isbn);

  /// Issues a book to a student with due date and atomic inventory deduction.
  Future<void> borrowBook({
    required String studentAuthId,
    required String studentRegisterNumber,
    required Book book,
    required DateTime dueDate,
  });

  /// Fetches active (unreturned) loans for a student by their register number.
  Future<List<BorrowRecord>> getActiveLoansForStudent(String registerNumber);

  /// Processes returning a borrowed book and increments available copies.
  Future<void> returnBook({
    required String borrowRecordId,
    required String bookId,
  });

  /// Fetches global borrow history log with optional standard, status, and sort filters.
  Future<List<BorrowRecord>> getGlobalBorrowHistory({
    String? standard,
    String? statusFilter,
    String? sortOrder,
  });

  /// Fetches personal borrow history for a specific student by [studentAuthId].
  Future<List<BorrowRecord>> getStudentBorrowHistory(String studentAuthId);
}
