import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:student_management/core/errors/app_exception.dart';
import 'package:student_management/features/library/presentation/providers/library_providers.dart';
import 'package:student_management/features/students/presentation/providers/student_providers.dart';
import 'package:student_management/shared/models/book.dart';
import 'package:student_management/shared/models/student.dart';

class BorrowBookState {
  final Book? selectedBook;
  final Student? verifiedStudent;
  final bool isSearchingStudent;
  final bool isSearchingBooks;
  final bool isSubmitting;
  final DateTime dueDate;
  final List<Book> searchResults;
  final String? errorMessage;
  final String? successMessage;

  BorrowBookState({
    this.selectedBook,
    this.verifiedStudent,
    this.isSearchingStudent = false,
    this.isSearchingBooks = false,
    this.isSubmitting = false,
    DateTime? dueDate,
    this.searchResults = const [],
    this.errorMessage,
    this.successMessage,
  }) : dueDate = dueDate ?? DateTime.now().add(const Duration(days: 14));

  BorrowBookState copyWith({
    Book? selectedBook,
    bool clearBook = false,
    Student? verifiedStudent,
    bool clearStudent = false,
    bool? isSearchingStudent,
    bool? isSearchingBooks,
    bool? isSubmitting,
    DateTime? dueDate,
    List<Book>? searchResults,
    String? errorMessage,
    bool clearError = false,
    String? successMessage,
    bool clearSuccess = false,
  }) {
    return BorrowBookState(
      selectedBook: clearBook ? null : (selectedBook ?? this.selectedBook),
      verifiedStudent:
          clearStudent ? null : (verifiedStudent ?? this.verifiedStudent),
      isSearchingStudent: isSearchingStudent ?? this.isSearchingStudent,
      isSearchingBooks: isSearchingBooks ?? this.isSearchingBooks,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      dueDate: dueDate ?? this.dueDate,
      searchResults: searchResults ?? this.searchResults,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage:
          clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}

class BorrowBookController extends AutoDisposeNotifier<BorrowBookState> {
  @override
  BorrowBookState build() {
    return BorrowBookState();
  }

  void setSelectedBook(Book book) {
    state = state.copyWith(
      selectedBook: book,
      clearError: true,
      clearSuccess: true,
    );
  }

  void clearSelectedBook() {
    state = state.copyWith(clearBook: true, clearError: true);
  }

  Future<void> searchBooks(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      state = state.copyWith(searchResults: []);
      return;
    }

    state = state.copyWith(isSearchingBooks: true, clearError: true);
    try {
      final repository = ref.read(libraryRepositoryProvider);
      final results = await repository.searchBooks(trimmed);
      state = state.copyWith(searchResults: results, isSearchingBooks: false);
    } on AppException catch (e) {
      state = state.copyWith(isSearchingBooks: false, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(
        isSearchingBooks: false,
        errorMessage: 'Failed to search books: $e',
      );
    }
  }

  void clearSearchResults() {
    state = state.copyWith(searchResults: []);
  }

  Future<void> verifyStudentByRegister(String registerNumber) async {
    final trimmed = registerNumber.trim();
    if (trimmed.isEmpty) {
      state = state.copyWith(clearStudent: true);
      return;
    }

    state = state.copyWith(isSearchingStudent: true, clearError: true);
    try {
      final studentRepository = ref.read(studentRepositoryProvider);
      final student = await studentRepository.getStudentByRegisterNumber(
        trimmed,
      );
      if (student != null) {
        state = state.copyWith(
          verifiedStudent: student,
          isSearchingStudent: false,
          clearError: true,
        );
      } else {
        state = state.copyWith(
          clearStudent: true,
          isSearchingStudent: false,
          errorMessage: 'No student found with register number $trimmed',
        );
      }
    } on AppException catch (e) {
      state = state.copyWith(
        clearStudent: true,
        isSearchingStudent: false,
        errorMessage: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        clearStudent: true,
        isSearchingStudent: false,
        errorMessage: 'Failed to lookup student: $e',
      );
    }
  }

  void setDueDate(DateTime date) {
    state = state.copyWith(dueDate: date);
  }

  Future<bool> borrowBook() async {
    final book = state.selectedBook;
    final student = state.verifiedStudent;

    if (book == null) {
      state = state.copyWith(errorMessage: 'Please select a book to borrow.');
      return false;
    }
    if (student == null) {
      state = state.copyWith(
        errorMessage: 'Please verify a student by registration number.',
      );
      return false;
    }

    state = state.copyWith(
      isSubmitting: true,
      clearError: true,
      clearSuccess: true,
    );
    try {
      final libraryRepository = ref.read(libraryRepositoryProvider);
      await libraryRepository.borrowBook(
        studentAuthId: student.userId,
        studentRegisterNumber: student.registerNumber,
        book: book,
        dueDate: state.dueDate,
      );

      state = state.copyWith(
        isSubmitting: false,
        clearBook: true,
        clearStudent: true,
        successMessage: 'Book "${book.title}" borrowed successfully!',
      );
      return true;
    } on AppException catch (e) {
      state = state.copyWith(isSubmitting: false, errorMessage: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Failed to process borrowing: $e',
      );
      return false;
    }
  }
}
