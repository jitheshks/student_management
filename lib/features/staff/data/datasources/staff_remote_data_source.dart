import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:student_management/core/constants/supabase_constants.dart';
import 'package:student_management/core/errors/app_exception.dart';
import 'package:student_management/core/errors/error_handler.dart';
import 'package:student_management/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:student_management/shared/models/staff.dart';

class StaffRemoteDataSource {
  final SupabaseClient _client;
  final AuthRemoteDataSource _authRemoteDataSource;

  StaffRemoteDataSource({
    required SupabaseClient client,
    AuthRemoteDataSource? authRemoteDataSource,
  }) : _client = client,
       _authRemoteDataSource =
           authRemoteDataSource ?? AuthRemoteDataSource(client);

  /// Fetches all staff records ordered by first name ascending
  Future<List<Staff>> fetchStaffList() async {
    try {
      final response = await _client
          .from(SupabaseConstants.staffTable)
          .select()
          .order('first_name', ascending: true);

      final List<dynamic> data = response as List<dynamic>;
      return data
          .map((json) => Staff.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ErrorHandler.handleException(e);
    }
  }

  /// Fetches a single staff record by primary row ID or auth user ID
  Future<Staff?> fetchStaffById(String id) async {
    try {
      final response =
          await _client
              .from(SupabaseConstants.staffTable)
              .select()
              .or('id.eq.$id,user_id.eq.$id')
              .maybeSingle();

      if (response == null) return null;
      return Staff.fromJson(response);
    } catch (e) {
      throw ErrorHandler.handleException(e);
    }
  }

  /// Fetches a single staff record by email
  Future<Staff?> fetchStaffByEmail(String email) async {
    try {
      final response =
          await _client
              .from(SupabaseConstants.staffTable)
              .select()
              .eq('email', email.trim().toLowerCase())
              .maybeSingle();

      if (response == null) return null;
      return Staff.fromJson(response);
    } catch (e) {
      throw ErrorHandler.handleException(e);
    }
  }

  /// Uploads or updates an avatar image in the profile_pictures bucket
  Future<String?> uploadProfilePicture({
    required String staffId,
    required File imageFile,
  }) async {
    try {
      final fileName = '$staffId.jpg';
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
        '⚠️ [StaffRemoteDataSource] Error uploading profile image: $e',
      );
      return null;
    }
  }

  /// Creates a staff record and associated auth credentials safely without hijacking admin session
  Future<void> createStaff({
    required Staff staff,
    required String password,
    File? avatarFile,
  }) async {
    try {
      final email = (staff.email ?? '').trim().toLowerCase();
      if (email.isEmpty) {
        throw const ValidationException(
          'Email is required to create a staff account.',
        );
      }

      // Step 1: Check if email already exists in users or staff table
      final existingUser =
          await _client
              .from(SupabaseConstants.usersTable)
              .select('id')
              .eq('email', email)
              .maybeSingle();

      final existingStaff =
          await _client
              .from(SupabaseConstants.staffTable)
              .select('id')
              .eq('email', email)
              .maybeSingle();

      if (existingUser != null || existingStaff != null) {
        throw const DatabaseException(
          'An account with this email is already registered.',
          '23505',
        );
      }

      // Step 2: Create Auth user safely via centralized AuthRemoteDataSource
      final newAuthUid = await _authRemoteDataSource.adminCreateUser(
        email: email,
        password: password,
        role: 'staff',
      );

      // Step 3: Upload profile picture if provided
      String? imageUrl = staff.profileImageUrl;
      if (avatarFile != null) {
        final uploadedUrl = await uploadProfilePicture(
          staffId: newAuthUid,
          imageFile: avatarFile,
        );
        if (uploadedUrl != null) {
          imageUrl = uploadedUrl;
        }
      }

      // Step 4: Insert into staff table
      final dobFormatted = staff.dob?.toIso8601String().split('T').first;

      await _client.from(SupabaseConstants.staffTable).insert({
        'id': newAuthUid,
        'user_id': newAuthUid,
        'first_name': staff.firstName,
        'last_name': staff.lastName,
        'email': email,
        'address': staff.address ?? '',
        'phone': staff.phone ?? '',
        'designation': staff.designation,
        if (dobFormatted != null) 'dob': dobFormatted,
        if (imageUrl != null) 'profile_image_url': imageUrl,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw ErrorHandler.handleException(e);
    }
  }

  /// Updates an existing staff record and optionally uploads a new avatar
  Future<void> updateStaff({required Staff staff, File? avatarFile}) async {
    try {
      String? imageUrl = staff.profileImageUrl;

      if (avatarFile != null) {
        final uploadedUrl = await uploadProfilePicture(
          staffId: staff.id,
          imageFile: avatarFile,
        );
        if (uploadedUrl != null) {
          imageUrl = uploadedUrl;
        }
      }

      final dobFormatted = staff.dob?.toIso8601String().split('T').first;

      final updatedData = <String, dynamic>{
        'first_name': staff.firstName,
        'last_name': staff.lastName,
        'email': staff.email?.trim().toLowerCase(),
        'address': staff.address ?? '',
        'phone': staff.phone ?? '',
        'designation': staff.designation,
        if (dobFormatted != null) 'dob': dobFormatted,
        if (imageUrl != null) 'profile_image_url': imageUrl,
      };

      await _client
          .from(SupabaseConstants.staffTable)
          .update(updatedData)
          .eq('id', staff.id);
    } catch (e) {
      throw ErrorHandler.handleException(e);
    }
  }

  /// Deletes a staff record, storage avatar, public.users entry, and calls deleteAuthUser Edge Function
  Future<void> deleteStaff({
    required String staffId,
    required String authId,
    String? email,
  }) async {
    try {
      final targetUserId = authId.isNotEmpty ? authId : staffId;

      // 1. Delete profile picture from storage
      try {
        final fileName = '$targetUserId.jpg';
        await _client.storage
            .from(SupabaseConstants.profilePicturesBucket)
            .remove([fileName, '$staffId.jpg']);
      } catch (e) {
        debugPrint(
          '⚠️ [StaffRemoteDataSource] Failed to delete profile picture: $e',
        );
      }

      // 2. Delete staff row by user_id
      final delStaff =
          await _client
              .from(SupabaseConstants.staffTable)
              .delete()
              .eq('user_id', targetUserId)
              .select();

      final deletedCount = (delStaff as List?)?.length ?? 0;

      // Fallback: delete by id if user_id did not match
      if (deletedCount == 0 && staffId.isNotEmpty) {
        await _client
            .from(SupabaseConstants.staffTable)
            .delete()
            .eq('id', staffId);
      }

      // Fallback: delete by email if still not deleted
      if (deletedCount == 0 && email != null && email.isNotEmpty) {
        try {
          await _client
              .from(SupabaseConstants.staffTable)
              .delete()
              .eq('email', email.trim().toLowerCase());
        } catch (_) {}
      }

      // 3. Delete from public.users table
      try {
        await _client
            .from(SupabaseConstants.usersTable)
            .delete()
            .eq('id', targetUserId);
      } catch (e) {
        debugPrint(
          '⚠️ [StaffRemoteDataSource] Deleting from users table (non-blocking): $e',
        );
      }

      // 4. Invoke Edge Function delete-auth-user if available
      try {
        final jwt = _client.auth.currentSession?.accessToken;
        await _client.functions.invoke(
          SupabaseConstants.deleteAuthUserFunction,
          body: {'userId': targetUserId},
          headers: {if (jwt != null) 'Authorization': 'Bearer $jwt'},
        );
      } catch (e) {
        debugPrint(
          '⚠️ [StaffRemoteDataSource] Server-side auth user deletion notice: $e',
        );
      }
    } catch (e) {
      throw ErrorHandler.handleException(e);
    }
  }
}
