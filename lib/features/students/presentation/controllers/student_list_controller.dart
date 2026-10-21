import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:student_management/core/errors/error_handler.dart';
import 'package:student_management/features/students/presentation/providers/student_providers.dart';
import 'package:student_management/shared/models/student.dart';

class StudentListState {
  final List<Student> students;
  final List<Student> filteredStudents;
  final String selectedSort;
  final String selectedStandard;
  final String searchQuery;
  final Set<String> selectedIds;
  final bool isLoading;
  final bool isDeleting;
  final String? errorMessage;

  const StudentListState({
    this.students = const [],
    this.filteredStudents = const [],
    this.selectedSort = 'A-Z',
    this.selectedStandard = 'All',
    this.searchQuery = '',
    this.selectedIds = const {},
    this.isLoading = false,
    this.isDeleting = false,
    this.errorMessage,
  });

  bool get hasSelection => selectedIds.isNotEmpty;
  int get selectedCount => selectedIds.length;

  StudentListState copyWith({
    List<Student>? students,
    List<Student>? filteredStudents,
    String? selectedSort,
    String? selectedStandard,
    String? searchQuery,
    Set<String>? selectedIds,
    bool? isLoading,
    bool? isDeleting,
    String? errorMessage,
    bool clearError = false,
  }) {
    return StudentListState(
      students: students ?? this.students,
      filteredStudents: filteredStudents ?? this.filteredStudents,
      selectedSort: selectedSort ?? this.selectedSort,
      selectedStandard: selectedStandard ?? this.selectedStandard,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedIds: selectedIds ?? this.selectedIds,
      isLoading: isLoading ?? this.isLoading,
      isDeleting: isDeleting ?? this.isDeleting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class StudentListController extends AutoDisposeNotifier<StudentListState> {
  @override
  StudentListState build() {
    // Schedule fetch after build
    Future.microtask(() => loadStudents());
    return const StudentListState(isLoading: true);
  }

  Future<void> loadStudents() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final repository = ref.read(studentRepositoryProvider);
      final fetched = await repository.getStudents();
      state = state.copyWith(
        students: fetched,
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

  void setStandard(String standard) {
    state = state.copyWith(selectedStandard: standard);
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
    final allIds = state.filteredStudents.map((s) => s.id).toSet();
    state = state.copyWith(selectedIds: allIds);
  }

  void clearSelections() {
    state = state.copyWith(selectedIds: {});
  }

  Future<bool> deleteStudent(Student student) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final repository = ref.read(studentRepositoryProvider);
      await repository.deleteStudent(
        studentId: student.id,
        authId: student.userId,
        email: student.email,
      );

      final updatedAll =
          state.students.where((s) => s.id != student.id).toList();
      final updatedSelected = Set<String>.from(state.selectedIds)
        ..remove(student.id);

      state = state.copyWith(
        students: updatedAll,
        selectedIds: updatedSelected,
        isLoading: false,
      );
      _applyFilters();
      return true;
    } catch (e) {
      final failure = ErrorHandler.handleFailure(e);
      state = state.copyWith(isLoading: false, errorMessage: failure.message);
      return false;
    }
  }

  Future<Map<String, int>> bulkDeleteSelected() async {
    if (state.selectedIds.isEmpty || state.isDeleting) {
      return {'success': 0, 'fail': 0};
    }

    state = state.copyWith(isDeleting: true, clearError: true);

    try {
      final repository = ref.read(studentRepositoryProvider);
      final targets =
          state.students
              .where((s) => state.selectedIds.contains(s.id))
              .toList();

      final results = await repository.bulkDeleteStudents(targets);

      // Re-fetch list to stay perfectly synchronized
      final fetched = await repository.getStudents();
      final failCount = results['fail'] ?? 0;
      state = state.copyWith(
        students: fetched,
        selectedIds: {},
        isDeleting: false,
        errorMessage: failCount > 0
            ? 'Failed to delete $failCount student(s). Students with active book loans cannot be deleted until books are returned.'
            : null,
      );
      _applyFilters();
      return results;
    } catch (e) {
      final failure = ErrorHandler.handleFailure(e);
      state = state.copyWith(isDeleting: false, errorMessage: failure.message);
      return {'success': 0, 'fail': state.selectedIds.length};
    }
  }

  void _applyFilters() {
    List<Student> list = List<Student>.from(state.students);

    // Filter by standard
    if (state.selectedStandard != 'All' &&
        state.selectedStandard.trim().isNotEmpty) {
      list =
          list
              .where(
                (s) =>
                    s.standard.toLowerCase() ==
                    state.selectedStandard.trim().toLowerCase(),
              )
              .toList();
    }

    // Filter by search query
    if (state.searchQuery.trim().isNotEmpty) {
      final q = state.searchQuery.trim().toLowerCase();
      list =
          list.where((s) {
            final fullName =
                '${s.firstName} ${s.lastName} ${s.name}'.toLowerCase();
            final reg = s.registerNumber.toLowerCase();
            final email = (s.email ?? '').toLowerCase();
            return fullName.contains(q) || reg.contains(q) || email.contains(q);
          }).toList();
    }

    // Sort order
    switch (state.selectedSort) {
      case 'Z-A':
        list.sort(
          (a, b) =>
              b.firstName.toLowerCase().compareTo(a.firstName.toLowerCase()),
        );
        break;
      case 'Register Number ↑':
        list.sort((a, b) => a.registerNumber.compareTo(b.registerNumber));
        break;
      case 'Register Number ↓':
        list.sort((a, b) => b.registerNumber.compareTo(a.registerNumber));
        break;
      case 'A-Z':
      default:
        list.sort(
          (a, b) =>
              a.firstName.toLowerCase().compareTo(b.firstName.toLowerCase()),
        );
        break;
    }

    state = state.copyWith(filteredStudents: list);
  }
}
