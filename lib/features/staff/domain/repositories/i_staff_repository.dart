import 'dart:io';
import 'package:student_management/shared/models/staff.dart';

abstract class IStaffRepository {
  /// Fetches a list of staff members with optional designation filter, search query, and sorting.
  Future<List<Staff>> getStaffList({
    String? designationFilter,
    String? searchQuery,
    String? sortOrder,
  });

  /// Fetches a single staff member by their primary row ID or user ID.
  Future<Staff?> getStaffById(String id);

  /// Fetches a staff member by their email.
  Future<Staff?> getStaffByEmail(String email);

  /// Creates a new staff record and auth credentials without hijacking the active session.
  Future<void> createStaff({
    required Staff staff,
    required String password,
    File? avatarFile,
  });

  /// Updates an existing staff record and optionally uploads a new avatar.
  Future<void> updateStaff({required Staff staff, File? avatarFile});

  /// Deletes a single staff record and associated auth account.
  Future<void> deleteStaff({
    required String staffId,
    required String authId,
    String? email,
  });

  /// Bulk deletes a list of staff members, returning counts of success and failure.
  Future<Map<String, int>> bulkDeleteStaff(List<Staff> staffList);
}
