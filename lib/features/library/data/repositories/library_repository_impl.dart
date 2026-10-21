import 'package:student_management/features/library/data/datasources/library_remote_data_source.dart';
import 'package:student_management/features/library/domain/repositories/i_library_repository.dart';
import 'package:student_management/shared/models/book.dart';
import 'package:student_management/shared/models/borrow_record.dart';

class LibraryRepositoryImpl implements ILibraryRepository {
  final LibraryRemoteDataSource _remoteDataSource;

  LibraryRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<Book>> searchBooks(String query) {
    return _remoteDataSource.searchBooks(query);
  }

  @override
  Future<int> getAvailableBookCopies(String isbn) {
    return _remoteDataSource.getAvailableBookCopies(isbn);
  }

  @override
  Future<void> borrowBook({
    required String studentAuthId,
    required String studentRegisterNumber,
    required Book book,
    required DateTime dueDate,
  }) {
    return _remoteDataSource.borrowBook(
      studentAuthId: studentAuthId,
      studentRegisterNumber: studentRegisterNumber,
      book: book,
      dueDate: dueDate,
    );
  }

  @override
  Future<List<BorrowRecord>> getActiveLoansForStudent(String registerNumber) {
    return _remoteDataSource.getActiveLoansForStudent(registerNumber);
  }

  @override
  Future<void> returnBook({
    required String borrowRecordId,
    required String bookId,
  }) {
    return _remoteDataSource.returnBook(
      borrowRecordId: borrowRecordId,
      bookId: bookId,
    );
  }

  @override
  Future<List<BorrowRecord>> getGlobalBorrowHistory({
    String? standard,
    String? statusFilter,
    String? sortOrder,
  }) {
    return _remoteDataSource.getGlobalBorrowHistory(
      standard: standard,
      statusFilter: statusFilter,
      sortOrder: sortOrder,
    );
  }

  @override
  Future<List<BorrowRecord>> getStudentBorrowHistory(String studentAuthId) {
    return _remoteDataSource.getStudentBorrowHistory(studentAuthId);
  }
}
