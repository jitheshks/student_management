import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:student_management/core/errors/app_exception.dart';
import 'package:student_management/features/library/presentation/providers/library_providers.dart';
import 'package:student_management/shared/models/borrow_record.dart';

class LibraryHistoryState {
  final List<BorrowRecord> history;
  final bool isLoading;
  final String? errorMessage;
  final String selectedSort;
  final String selectedStandard;
  final String selectedStatus;
  final String searchQuery;

  const LibraryHistoryState({
    this.history = const [],
    this.isLoading = false,
    this.errorMessage,
    this.selectedSort = 'A-Z',
    this.selectedStandard = 'All',
    this.selectedStatus = 'All',
    this.searchQuery = '',
  });

  LibraryHistoryState copyWith({
    List<BorrowRecord>? history,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    String? selectedSort,
    String? selectedStandard,
    String? selectedStatus,
    String? searchQuery,
  }) {
    return LibraryHistoryState(
      history: history ?? this.history,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      selectedSort: selectedSort ?? this.selectedSort,
      selectedStandard: selectedStandard ?? this.selectedStandard,
      selectedStatus: selectedStatus ?? this.selectedStatus,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  List<BorrowRecord> get filteredHistory {
    if (searchQuery.trim().isEmpty) return history;
    final q = searchQuery.trim().toLowerCase();
    return history.where((item) {
      final titleMatch = item.bookTitle.toLowerCase().contains(q);
      final authorMatch = item.bookAuthor.toLowerCase().contains(q);
      final nameMatch = (item.studentName ?? '').toLowerCase().contains(q);
      final regMatch = item.studentRegisterNumber.toLowerCase().contains(q);
      final isbnMatch = item.isbn.toLowerCase().contains(q);
      return titleMatch || authorMatch || nameMatch || regMatch || isbnMatch;
    }).toList();
  }
}

class LibraryHistoryController
    extends AutoDisposeNotifier<LibraryHistoryState> {
  @override
  LibraryHistoryState build() {
    Future.microtask(() => loadHistory());
    return const LibraryHistoryState(isLoading: true);
  }

  Future<void> loadHistory() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final repository = ref.read(libraryRepositoryProvider);
      final records = await repository.getGlobalBorrowHistory(
        standard: state.selectedStandard,
        statusFilter: state.selectedStatus,
        sortOrder: state.selectedSort,
      );
      state = state.copyWith(
        history: records,
        isLoading: false,
        clearError: true,
      );
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load library history: $e',
      );
    }
  }

  void setSort(String sortOption) {
    if (state.selectedSort == sortOption) return;
    state = state.copyWith(selectedSort: sortOption);
    loadHistory();
  }

  void setStandard(String standardOption) {
    if (state.selectedStandard == standardOption) return;
    state = state.copyWith(selectedStandard: standardOption);
    loadHistory();
  }

  void setStatus(String statusOption) {
    if (state.selectedStatus == statusOption) return;
    state = state.copyWith(selectedStatus: statusOption);
    loadHistory();
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }
}
