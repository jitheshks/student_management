import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:student_management/core/constants/supabase_constants.dart';
import 'package:student_management/core/errors/app_exception.dart';
import 'package:student_management/core/errors/error_handler.dart';
import 'package:student_management/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:student_management/shared/models/student.dart';

class StudentRemoteDataSource {
  final SupabaseClient _client;
  final AuthRemoteDataSource _authRemoteDataSource;

  StudentRemoteDataSource({
    required SupabaseClient client,
    AuthRemoteDataSource? authRemoteDataSource,
  }) : _client = client,
       _authRemoteDataSource =
           authRemoteDataSource ?? AuthRemoteDataSource(client);

  /// Fetches all student records ordered by register number ascending
  Future<List<Student>> fetchStudents() async {
    try {
      final response = await _client
          .from(SupabaseConstants.studentsTable)
          .select()
          .order('register_number', ascending: true);

      final List<dynamic> data = response as List<dynamic>;
      return data
          .map((json) => Student.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ErrorHandler.handleException(e);
    }
  }

  /// Fetches a single student record by their primary ID or auth user ID
  Future<Student?> fetchStudentById(String id) async {
    try {
      final response =
          await _client
              .from(SupabaseConstants.studentsTable)
              .select()
              .or('id.eq.$id,user_id.eq.$id')
              .maybeSingle();

      if (response == null) return null;
      return Student.fromJson(response);
    } catch (e) {
      throw ErrorHandler.handleException(e);
    }
  }

  /// Fetches a single student record by register number
  Future<Student?> fetchStudentByRegisterNumber(String registerNumber) async {
    try {
      final response =
          await _client
              .from(SupabaseConstants.studentsTable)
              .select()
              .eq('register_number', registerNumber.trim())
              .maybeSingle();

      if (response == null) return null;
      return Student.fromJson(response);
    } catch (e) {
      throw ErrorHandler.handleException(e);
    }
  }

  /// Generates the next sequential register number with format '1080XXXX'
  Future<String> generateNextRegisterNumber() async {
    try {
      final response =
          await _client
              .from(SupabaseConstants.studentsTable)
              .select('register_number')
              .order('register_number', ascending: false)
              .limit(1)
              .maybeSingle();

      int lastNumber = 0;
      if (response != null && response['register_number'] != null) {
        final lastReg = response['register_number'].toString();
        if (lastReg.length > 4) {
          lastNumber = int.tryParse(lastReg.substring(4)) ?? 0;
        } else {
          lastNumber = int.tryParse(lastReg) ?? 0;
        }
      }
      final newNumber = lastNumber + 1;
      return '1080${newNumber.toString().padLeft(4, '0')}';
    } catch (e) {
      debugPrint(
        '⚠️ [StudentRemoteDataSource] Failed to query last register number: $e. Using fallback.',
      );
      return '10800001';
    }
  }

  /// Uploads or updates an avatar image in the profile_pictures bucket
  Future<String?> uploadProfilePicture({
    required String studentId,
    required File imageFile,
  }) async {
    try {
      final fileName = '$studentId.jpg';
      await _client.storage
          .from(SupabaseConstants.profilePicturesBucket)
          .upload(
            fileName,
            imageFile,
            fileOptions: const FileOptions(upsert: true),
          );
      return _client.storage
          .from(SupabaseConstants.profilePicturesBucket)
          .getPublicUrl(fileName);
    } catch (e) {
      debugPrint(
        '⚠️ [StudentRemoteDataSource] Error uploading profile image: $e',
      );
      return null;
    }
  }

  /// Creates a student record with associated auth credentials without hijacking the active session
  Future<void> createStudent({
    required Student student,
    required String password,
    File? avatarFile,
  }) async {
    try {
      final email = (student.email ?? '').trim().toLowerCase();
      if (email.isEmpty) {
        throw const ValidationException(
          'Email is required to create a student account.',
        );
      }

      // Step 1: Check if email already exists in users or students table
      final existingUser =
          await _client
              .from(SupabaseConstants.usersTable)
              .select('id')
              .eq('email', email)
              .maybeSingle();

      final existingStudent =
          await _client
              .from(SupabaseConstants.studentsTable)
              .select('id')
              .eq('email', email)
              .maybeSingle();

      if (existingUser != null || existingStudent != null) {
        throw const DatabaseException(
          'An account with this email is already registered.',
          '23505',
        );
      }

      // Step 2: Create Auth user safely via centralized AuthRemoteDataSource
      final newAuthUid = await _authRemoteDataSource.adminCreateUser(
        email: email,
        password: password,
        role: 'student',
      );

      // Step 3: Ensure sequential register number
      String regNo = student.registerNumber.trim();
      if (regNo.isEmpty) {
        regNo = await generateNextRegisterNumber();
      }

      // Step 4: Upload profile picture if provided
      String? imageUrl = student.profileImageUrl;
      if (avatarFile != null) {
        final uploadedUrl = await uploadProfilePicture(
          studentId: newAuthUid,
          imageFile: avatarFile,
        );
        if (uploadedUrl != null) {
          imageUrl = uploadedUrl;
        }
      }

      // Step 5: Insert into students table
      final dobFormatted = student.dob?.toIso8601String().split('T').first;

      await _client.from(SupabaseConstants.studentsTable).insert({
        'id': newAuthUid,
        'user_id': newAuthUid,
        'first_name': student.firstName,
        'last_name': student.lastName,
        'address': student.address ?? '',
        'phone': student.phone ?? '',
        'register_number': regNo,
        'attendance': student.attendance,
        'email': email,
        'standard': student.standard,
        if (dobFormatted != null) 'dob': dobFormatted,
        if (imageUrl != null) 'profile_image_url': imageUrl,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw ErrorHandler.handleException(e);
    }
  }

  /// Updates an existing student record and optionally uploads a new avatar
  Future<void> updateStudent({
    required Student student,
    File? avatarFile,
  }) async {
    try {
      String? imageUrl = student.profileImageUrl;

      if (avatarFile != null) {
        final uploadedUrl = await uploadProfilePicture(
          studentId: student.id,
          imageFile: avatarFile,
        );
        if (uploadedUrl != null) {
          imageUrl = uploadedUrl;
        }
      }

      final dobFormatted = student.dob?.toIso8601String().split('T').first;

      final updatedData = <String, dynamic>{
        'first_name': student.firstName,
        'last_name': student.lastName,
        'address': student.address ?? '',
        'phone': student.phone ?? '',
        'attendance': student.attendance,
        if (student.email != null) 'email': student.email!.trim().toLowerCase(),
        'standard': student.standard,
        if (dobFormatted != null) 'dob': dobFormatted,
        if (imageUrl != null) 'profile_image_url': imageUrl,
      };

      await _client
          .from(SupabaseConstants.studentsTable)
          .update(updatedData)
          .eq('id', student.id);
    } catch (e) {
      throw ErrorHandler.handleException(e);
    }
  }

  /// Deletes a student profile, avatar, borrow records, and public.users entry
  Future<void> deleteStudent({
    required String studentId,
    required String authId,
    String? email,
  }) async {
    try {
      final targetUserId = authId.isNotEmpty ? authId : studentId;

      // 1. Guard: Check for active unreturned borrows and block deletion
      final activeResponse = await _client
          .from(SupabaseConstants.borrowRecordsTable)
          .select('id, book_id')
          .eq('user_id', targetUserId)
          .isFilter('returned_at', null);

      final activeBorrows = List<Map<String, dynamic>>.from(activeResponse);
      if (activeBorrows.isNotEmpty) {
        throw ValidationException(
          'Cannot delete student: The student currently has ${activeBorrows.length} active book loan(s). '
          'Please ensure all borrowed books are returned in Library Management before deleting this student.',
        );
      }

      // 2. Delete profile picture from storage
      try {
        final fileName = '$targetUserId.jpg';
        await _client.storage
            .from(SupabaseConstants.profilePicturesBucket)
            .remove([fileName]);
      } catch (e) {
        debugPrint(
          '⚠️ [StudentRemoteDataSource] Failed to delete profile picture: $e',
        );
      }

      // 3. Historical borrow records are preserved: DO NOT DELETE FROM borrowRecordsTable

      // 4. Delete student record
      final delStudents =
          await _client
              .from(SupabaseConstants.studentsTable)
              .delete()
              .eq('user_id', targetUserId)
              .select();

      final deletedCount = (delStudents as List?)?.length ?? 0;

      // Fallback: delete by id if user_id did not match
      if (deletedCount == 0 && studentId.isNotEmpty) {
        await _client
            .from(SupabaseConstants.studentsTable)
            .delete()
            .eq('id', studentId);
      }

      // Fallback: delete by email if still not deleted
      if (deletedCount == 0 && email != null && email.isNotEmpty) {
        try {
          await _client
              .from(SupabaseConstants.studentsTable)
              .delete()
              .eq('email', email.trim().toLowerCase());
        } catch (_) {}
      }

      // 5. Delete from public.users table
      try {
        await _client
            .from(SupabaseConstants.usersTable)
            .delete()
            .eq('id', targetUserId);
      } catch (e) {
        debugPrint(
          '⚠️ [StudentRemoteDataSource] Deleting from users table (non-blocking): $e',
        );
      }
    } catch (e) {
      throw ErrorHandler.handleException(e);
    }
  }
}
