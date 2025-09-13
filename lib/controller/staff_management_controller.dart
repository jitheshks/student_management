import 'package:flutter/material.dart';
import 'package:student_management/controller/base_controller.dart';
import 'package:student_management/model/staff_model.dart';
import 'package:student_management/services/staff_service.dart';
import 'package:collection/collection.dart'; // << Added for firstWhereOrNull

class StaffManagementController extends ChangeNotifier
    with BaseController<StaffModel> {
  final StaffService staffService;

  StaffManagementController({required this.staffService});

  // For sorting/filtering
  String _selectedSort = 'A-Z';
  String get selectedSort => _selectedSort;

  String _selectedDesignationFilter = 'All';
  String get selectedDesignationFilter => _selectedDesignationFilter;

  bool isDeleting = false;

  // Lifecycle safety
  bool _disposed = false;
  bool get isDisposed => _disposed;

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  /// Apply sorting & filtering — entity specific
  @override
  void applySortAndFilter() {
    List<StaffModel> filteredList = [...items];

    if (_selectedDesignationFilter != 'All') {
      filteredList = filteredList
          .where((staff) => staff.designation == _selectedDesignationFilter)
          .toList();
    }

    switch (_selectedSort) {
      case 'A-Z':
        filteredList.sort((a, b) => a.firstName.compareTo(b.firstName));
        break;
      case 'Z-A':
        filteredList.sort((a, b) => b.firstName.compareTo(a.firstName));
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
    _selectedDesignationFilter = newFilter;
    applySortAndFilter();
  }

  @override
  Future<void> fetchUsers() async {
    isLoading = true;
    errorMessage = null;
    _safeNotify();

    try {
      items = await staffService.fetchStaffs();
      selectedItems.clear();
      applySortAndFilter();
    } catch (e) {
      errorMessage = 'Failed to fetch staff: $e';
    } finally {
      isLoading = false;
      _safeNotify();
    }
  }

  @override
  Future<void> deleteUser(String rowId, String userId) async {
    if (userId.isEmpty) {
      errorMessage = 'Invalid userId for delete';
      _safeNotify();
      return;
    }

    isLoading = true;
    errorMessage = null;
    _safeNotify();

    try {
      // Fetch staff row to get email for fallback deletion
      final StaffModel? staff = items.firstWhereOrNull((s) => s.id == rowId);
      final String? email = staff?.email;

      // userId here is Auth UID from staff.user_id
await staffService.deleteStaffByUserIdFull(userId, email: email);

      items.removeWhere((s) => s.id == rowId);
      selectedItems.remove(rowId);
      applySortAndFilter();
    } catch (e) {
      errorMessage = 'Failed to delete staff: $e';
    } finally {
      isLoading = false;
      _safeNotify();
    }
  }

  /// Bulk delete helper
  Future<Map<String, int>> bulkDeleteSelected({
    required List<StaffModel> sourceList,
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

          // ✅ Make staff nullable
          final StaffModel? staff = sourceList.firstWhereOrNull((u) => u.id == id);

          if (staff == null) {
            debugPrint('[StaffBulkDelete] Staff row not found for id: $id');
            fail++;
            return;
          }

          if ((staff.authId?.isNotEmpty ?? false)) {
            try {
              await _deleteStaffSilently(staff.id, staff.authId!);
              success++;
            } catch (e) {
              debugPrint(
                  '[StaffBulkDelete] Delete failed for ${staff.id}: $e');
              fail++;
            }
          } else {
            debugPrint(
                '[StaffBulkDelete] Missing authId for staff ${staff.id}');
            fail++;
          }
        }).toList();

        await Future.wait(chunk);
      }

      selectedItems.clear();
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

  /// Internal silent delete helper for bulk
  Future<void> _deleteStaffSilently(String rowId, String authId) async {
    if (isDisposed) return;

    // Fetch staff row to get email for fallback deletion
    final StaffModel? staff = items.firstWhereOrNull((s) => s.id == rowId);
    final String? email = staff?.email;

  await staffService.deleteStaffByUserIdFull(authId, email: email);
    if (isDisposed) return;

    items.removeWhere((s) => s.id == rowId);
    selectedItems.remove(rowId);
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
