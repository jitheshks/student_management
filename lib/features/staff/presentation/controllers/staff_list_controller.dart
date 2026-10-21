import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:student_management/core/errors/error_handler.dart';
import 'package:student_management/features/staff/presentation/providers/staff_providers.dart';
import 'package:student_management/shared/models/staff.dart';

class StaffListState {
  final List<Staff> staffList;
  final List<Staff> filteredStaffList;
  final String selectedSort;
  final String selectedDesignationFilter;
  final String searchQuery;
  final Set<String> selectedIds;
  final bool isLoading;
  final bool isDeleting;
  final String? errorMessage;

  const StaffListState({
    this.staffList = const [],
    this.filteredStaffList = const [],
    this.selectedSort = 'A-Z',
    this.selectedDesignationFilter = 'All',
    this.searchQuery = '',
    this.selectedIds = const {},
    this.isLoading = false,
    this.isDeleting = false,
    this.errorMessage,
  });

  bool get hasSelection => selectedIds.isNotEmpty;
  int get selectedCount => selectedIds.length;

  StaffListState copyWith({
    List<Staff>? staffList,
    List<Staff>? filteredStaffList,
    String? selectedSort,
    String? selectedDesignationFilter,
    String? searchQuery,
    Set<String>? selectedIds,
    bool? isLoading,
    bool? isDeleting,
    String? errorMessage,
    bool clearError = false,
  }) {
    return StaffListState(
      staffList: staffList ?? this.staffList,
      filteredStaffList: filteredStaffList ?? this.filteredStaffList,
      selectedSort: selectedSort ?? this.selectedSort,
      selectedDesignationFilter:
          selectedDesignationFilter ?? this.selectedDesignationFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedIds: selectedIds ?? this.selectedIds,
      isLoading: isLoading ?? this.isLoading,
      isDeleting: isDeleting ?? this.isDeleting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class StaffListController extends AutoDisposeNotifier<StaffListState> {
  @override
  StaffListState build() {
    Future.microtask(() => loadStaff());
    return const StaffListState(isLoading: true);
  }

  Future<void> loadStaff() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final repository = ref.read(staffRepositoryProvider);
      final fetched = await repository.getStaffList();
      state = state.copyWith(
        staffList: fetched,
        isLoading: false,
        clearError: true,
      );
      _applyFilters();
    } catch (e) {
      final failure = ErrorHandler.handleFailure(e);
      state = state.copyWith(isLoading: false, errorMessage: failure.message);
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    _applyFilters();
  }

  void setDesignationFilter(String designation) {
    state = state.copyWith(selectedDesignationFilter: designation);
    _applyFilters();
  }

  void setSort(String sort) {
    state = state.copyWith(selectedSort: sort);
    _applyFilters();
  }

  void toggleSelection(String id) {
    final updated = Set<String>.from(state.selectedIds);
    if (updated.contains(id)) {
      updated.remove(id);
    } else {
      updated.add(id);
    }
    state = state.copyWith(selectedIds: updated);
  }

  void selectAll() {
    final allIds = state.filteredStaffList.map((s) => s.id).toSet();
    state = state.copyWith(selectedIds: allIds);
  }

  void clearSelection() {
    state = state.copyWith(selectedIds: {});
  }

  void _applyFilters() {
    List<Staff> filtered = List<Staff>.from(state.staffList);

    // 1. Designation Filter
    if (state.selectedDesignationFilter != 'All' &&
        state.selectedDesignationFilter.trim().isNotEmpty) {
      filtered =
          filtered
              .where(
                (s) =>
                    s.designation.toLowerCase() ==
                    state.selectedDesignationFilter.trim().toLowerCase(),
              )
              .toList();
    }

    // 2. Search Query Filter
    if (state.searchQuery.trim().isNotEmpty) {
      final query = state.searchQuery.trim().toLowerCase();
      filtered =
          filtered.where((s) {
            final fullName =
                '${s.firstName} ${s.lastName} ${s.name}'.toLowerCase();
            final email = (s.email ?? '').toLowerCase();
            final phone = (s.phone ?? '').toLowerCase();
            final designation = s.designation.toLowerCase();
            return fullName.contains(query) ||
                email.contains(query) ||
                phone.contains(query) ||
                designation.contains(query);
          }).toList();
    }

    // 3. Sort Order
    switch (state.selectedSort) {
      case 'Z-A':
        filtered.sort(
          (a, b) =>
              b.firstName.toLowerCase().compareTo(a.firstName.toLowerCase()),
        );
        break;
      case 'A-Z':
      default:
        filtered.sort(
          (a, b) =>
              a.firstName.toLowerCase().compareTo(b.firstName.toLowerCase()),
        );
        break;
    }

    state = state.copyWith(filteredStaffList: filtered);
  }

  Future<bool> deleteSingleStaff(Staff staff) async {
    state = state.copyWith(isDeleting: true, clearError: true);
    try {
      final repository = ref.read(staffRepositoryProvider);
      await repository.deleteStaff(
        staffId: staff.id,
        authId: staff.userId,
        email: staff.email,
      );

      final updatedList =
          state.staffList.where((s) => s.id != staff.id).toList();
      final updatedSelected = Set<String>.from(state.selectedIds)
        ..remove(staff.id);

      state = state.copyWith(
        staffList: updatedList,
        selectedIds: updatedSelected,
        isDeleting: false,
      );
      _applyFilters();
      return true;
    } catch (e) {
      final failure = ErrorHandler.handleFailure(e);
      state = state.copyWith(isDeleting: false, errorMessage: failure.message);
      return false;
    }
  }

  Future<Map<String, int>> deleteSelectedStaff() async {
    if (state.selectedIds.isEmpty) return {'success': 0, 'fail': 0};

    state = state.copyWith(isDeleting: true, clearError: true);
    try {
      final toDelete =
          state.staffList
              .where((s) => state.selectedIds.contains(s.id))
              .toList();

      final repository = ref.read(staffRepositoryProvider);
      final result = await repository.bulkDeleteStaff(toDelete);

      // Re-fetch to ensure sync with database
      await loadStaff();
      state = state.copyWith(selectedIds: {}, isDeleting: false);
      return result;
    } catch (e) {
      final failure = ErrorHandler.handleFailure(e);
      state = state.copyWith(isDeleting: false, errorMessage: failure.message);
      return {'success': 0, 'fail': state.selectedIds.length};
    }
  }
}
