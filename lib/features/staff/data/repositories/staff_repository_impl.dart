import 'dart:io';
import 'package:student_management/core/errors/error_handler.dart';
import 'package:student_management/features/staff/data/datasources/staff_remote_data_source.dart';
import 'package:student_management/features/staff/domain/repositories/i_staff_repository.dart';
import 'package:student_management/shared/models/staff.dart';

class StaffRepositoryImpl implements IStaffRepository {
  final StaffRemoteDataSource _remoteDataSource;

  StaffRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<Staff>> getStaffList({
    String? designationFilter,
    String? searchQuery,
    String? sortOrder = 'A-Z',
  }) async {
    try {
      final allStaff = await _remoteDataSource.fetchStaffList();
      List<Staff> filtered = List<Staff>.from(allStaff);

      // 1. Designation Filter
      if (designationFilter != null &&
          designationFilter != 'All' &&
          designationFilter.trim().isNotEmpty) {
        filtered =
            filtered
                .where(
                  (s) =>
                      s.designation.toLowerCase() ==
                      designationFilter.trim().toLowerCase(),
                )
                .toList();
      }

      // 2. Search Query Filter
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final query = searchQuery.trim().toLowerCase();
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
      switch (sortOrder) {
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

      return filtered;
    } catch (e) {
      throw ErrorHandler.handleException(e);
    }
  }

  @override
  Future<Staff?> getStaffById(String id) async {
    try {
      return await _remoteDataSource.fetchStaffById(id);
    } catch (e) {
      throw ErrorHandler.handleException(e);
    }
  }

  @override
  Future<Staff?> getStaffByEmail(String email) async {
    try {
      return await _remoteDataSource.fetchStaffByEmail(email);
    } catch (e) {
      throw ErrorHandler.handleException(e);
    }
  }

  @override
  Future<void> createStaff({
    required Staff staff,
    required String password,
    File? avatarFile,
  }) async {
    try {
      await _remoteDataSource.createStaff(
        staff: staff,
        password: password,
        avatarFile: avatarFile,
      );
    } catch (e) {
      throw ErrorHandler.handleException(e);
    }
  }

  @override
  Future<void> updateStaff({required Staff staff, File? avatarFile}) async {
    try {
      await _remoteDataSource.updateStaff(staff: staff, avatarFile: avatarFile);
    } catch (e) {
      throw ErrorHandler.handleException(e);
    }
  }

  @override
  Future<void> deleteStaff({
    required String staffId,
    required String authId,
    String? email,
  }) async {
    try {
      await _remoteDataSource.deleteStaff(
        staffId: staffId,
        authId: authId,
        email: email,
      );
    } catch (e) {
      throw ErrorHandler.handleException(e);
    }
  }

  @override
  Future<Map<String, int>> bulkDeleteStaff(List<Staff> staffList) async {
    int success = 0;
    int fail = 0;
    const batchSize = 4;

    for (var i = 0; i < staffList.length; i += batchSize) {
      final chunk = staffList.sublist(
        i,
        (i + batchSize > staffList.length) ? staffList.length : i + batchSize,
      );

      final futures = chunk.map((staff) async {
        try {
          await _remoteDataSource.deleteStaff(
            staffId: staff.id,
            authId: staff.userId,
            email: staff.email,
          );
          return true;
        } catch (_) {
          return false;
        }
      });

      final results = await Future.wait(futures);
      for (final res in results) {
        if (res) {
          success++;
        } else {
          fail++;
        }
      }
    }

    return {'success': success, 'fail': fail};
  }
}
