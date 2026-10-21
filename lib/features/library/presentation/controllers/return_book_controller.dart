import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:student_management/core/errors/app_exception.dart';
import 'package:student_management/features/library/presentation/providers/library_providers.dart';
import 'package:student_management/shared/models/borrow_record.dart';

class ReturnBookState {
  final String searchedRegisterNumber;
  final List<BorrowRecord> activeLoans;
  final bool isLoading;
  final bool isReturning;
  final String? returningRecordId;
  final String? errorMessage;
  final String? successMessage;
  final bool hasSearched;

  const ReturnBookState({
    this.searchedRegisterNumber = '',
    this.activeLoans = const [],
    this.isLoading = false,
    this.isReturning = false,
    this.returningRecordId,
    this.errorMessage,
    this.successMessage,
    this.hasSearched = false,
  });

  ReturnBookState copyWith({
    String? searchedRegisterNumber,
    List<BorrowRecord>? activeLoans,
    bool? isLoading,
    bool? isReturning,
    String? returningRecordId,
    bool clearReturningRecord = false,
    String? errorMessage,
    bool clearError = false,
    String? successMessage,
    bool clearSuccess = false,
    bool? hasSearched,
  }) {
    return ReturnBookState(
      searchedRegisterNumber:
          searchedRegisterNumber ?? this.searchedRegisterNumber,
      activeLoans: activeLoans ?? this.activeLoans,
      isLoading: isLoading ?? this.isLoading,
      isReturning: isReturning ?? this.isReturning,
      returningRecordId:
          clearReturningRecord
              ? null
              : (returningRecordId ?? this.returningRecordId),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage:
          clearSuccess ? null : (successMessage ?? this.successMessage),
      hasSearched: hasSearched ?? this.hasSearched,
    );
  }
}

class ReturnBookController extends AutoDisposeNotifier<ReturnBookState> {
  @override
  ReturnBookState build() {
    return const ReturnBookState();
  }

  Future<void> searchLoans(String registerNumber) async {
    final trimmed = registerNumber.trim();
    if (trimmed.isEmpty) {
      state = state.copyWith(
        searchedRegisterNumber: '',
        activeLoans: [],
        hasSearched: false,
        clearError: true,
      );
      return;
    }

    state = state.copyWith(
      searchedRegisterNumber: trimmed,
      isLoading: true,
      hasSearched: true,
      clearError: true,
      clearSuccess: true,
    );

    try {
      final repository = ref.read(libraryRepositoryProvider);
      final loans = await repository.getActiveLoansForStudent(trimmed);
      state = state.copyWith(
        activeLoans: loans,
        isLoading: false,
        clearError: true,
      );
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to search borrowed books: $e',
      );
    }
  }

  Future<bool> returnBook(BorrowRecord record) async {
    state = state.copyWith(
      isReturning: true,
      returningRecordId: record.id,
      clearError: true,
      clearSuccess: true,
    );

    try {
      final repository = ref.read(libraryRepositoryProvider);
      await repository.returnBook(
        borrowRecordId: record.id,
        bookId: record.bookId,
      );

      final updatedLoans =
          state.activeLoans.where((b) => b.id != record.id).toList();
      state = state.copyWith(
        activeLoans: updatedLoans,
        isReturning: false,
        clearReturningRecord: true,
        successMessage: 'Book "${record.bookTitle}" returned successfully!',
      );
      return true;
    } on AppException catch (e) {
      state = state.copyWith(
        isReturning: false,
        clearReturningRecord: true,
        errorMessage: e.message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isReturning: false,
        clearReturningRecord: true,
        errorMessage: 'Failed to return book: $e',
      );
      return false;
    }
  }

  void clearSearch() {
    state = const ReturnBookState();
  }
}
