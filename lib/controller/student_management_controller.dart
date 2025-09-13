// lib/controller/student_management_controller.dart

import 'package:flutter/material.dart';
import 'package:student_management/controller/base_controller.dart';
import 'package:student_management/model/student_model.dart';
import 'package:student_management/services/student_services.dart';
import 'package:collection/collection.dart';


class StudentManagementController extends ChangeNotifier
    with BaseController<StudentModel> {
  final StudentService studentService;

  StudentManagementController({required this.studentService});

  String _selectedSort = 'A-Z';
  String get selectedSort => _selectedSort;

  String _selectedStandard = 'All';
  String get selectedStandard => _selectedStandard;

  bool isDeleting = false;

  bool _disposed = false;
  bool get isDisposed => _disposed;

  void _safeNotify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  void applySortAndFilter() {
    List<StudentModel> filteredList = [...items];

    if (_selectedStandard != 'All') {
      filteredList = filteredList
          .where((student) => student.standard == _selectedStandard)
          .toList();
    }

    switch (_selectedSort) {
      case 'A-Z':
        filteredList.sort((a, b) => a.firstName.compareTo(b.firstName));
        break;
      case 'Z-A':
        filteredList.sort((a, b) => b.firstName.compareTo(a.firstName));
        break;
      case 'Register Number ↑':
        filteredList.sort(
            (a, b) => a.registerNumber.compareTo(b.registerNumber));
        break;
      case 'Register Number ↓':
        filteredList.sort(
            (a, b) => b.registerNumber.compareTo(a.registerNumber));
        break;
    }

    filteredItems = filteredList;
    _safeNotify();
  }

  void updateSort(String newSort) {
    _selectedSort = newSort;
    applySortAndFilter();
  }

  void updateFilter(String newFilter) {
    _selectedStandard = newFilter;
    applySortAndFilter();
  }

  @override
  Future<void> fetchUsers() async {
    isLoading = true;
    errorMessage = null;
    _safeNotify();
    try {
      items = await studentService.fetchStudents();
      selectedItems.clear();
      applySortAndFilter();
    } catch (e) {
      errorMessage = 'Failed to fetch students: $e';
    } finally {
      isLoading = false;
      _safeNotify();
    }
  }

@override
Future<void> deleteUser(String studentRowId, String userId) async {
  isLoading = true;
  errorMessage = null;
  _safeNotify();

  try {
    final StudentModel? student =
        items.firstWhereOrNull((s) => s.id == studentRowId);
    final String? email = student?.email;

    await studentService.deleteStudentByUserId(userId: userId, email: email);

    items.removeWhere((student) => student.id == studentRowId);
    selectedItems.remove(studentRowId);
    applySortAndFilter();
  } catch (e) {
    errorMessage = 'Failed to delete student: $e';
  } finally {
    isLoading = false;
    _safeNotify();
  }
}

  // Bulk delete with re-entry guard and internal selection clearing
  Future<Map<String, int>> bulkDeleteSelected({
    required List<dynamic> sourceList,
  }) async {
    if (isDeleting || selectedItems.isEmpty) {
      return {'success': 0, 'fail': 0};
    }

    isDeleting = true;
    _safeNotify();

    int success = 0, fail = 0;

    try {
      final ids = List<String>.from(selectedItems);
      const maxConcurrent = 4;

      for (var i = 0; i < ids.length; i += maxConcurrent) {
        if (isDisposed) break;

        final slice =
            ids.sublist(i, (i + maxConcurrent).clamp(0, ids.length));

        final chunk = slice.map((id) async {
          if (isDisposed) return;

          final user = sourceList.cast<dynamic>().firstWhere(
                (u) => (u.id as String) == id,
                orElse: () => null,
              );

          if (user == null) {
            fail++;
            return;
          }

          try {
            if (user is StudentModel &&
                (user.userId.isNotEmpty )) {
              await _deleteStudentSilently(user.id, user.userId);
              success++;
            } else {
              fail++;
            }
          } catch (_) {
            fail++;
          }
        }).toList();

        await Future.wait(chunk);
      }

      selectedItems.clear(); // clear selections after bulk delete

      if (!isDisposed) {
        applySortAndFilter();
        _safeNotify();
      }
    } finally {
      isDeleting = false;
      _safeNotify();
    }

    return {'success': success, 'fail': fail};
  }

Future<void> _deleteStudentSilently(String studentRowId, String userId) async {
  if (isDisposed) return;

  try {
    final StudentModel? student =
        items.firstWhereOrNull((s) => s.id == studentRowId);
    final String? email = student?.email;

    await studentService.deleteStudentByUserId(userId: userId, email: email);
  } catch (e) {
    debugPrint('Silent delete failed for $studentRowId: $e');
    rethrow;
  }

  if (isDisposed) return;

  items.removeWhere((s) => s.id == studentRowId);
  selectedItems.remove(studentRowId);
}

  void toggleUserSelection(String id) {
    if (selectedItems.contains(id)) {
      selectedItems.remove(id);
    } else {
      selectedItems.add(id);
    }
    _safeNotify();
  }

  void clearSelectedUsers() {
    selectedItems.clear();
    _safeNotify();
  }
}
