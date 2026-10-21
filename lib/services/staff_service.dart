import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:student_management/model/staff_model.dart';
import 'package:student_management/services/user_service.dart';

class StaffService {
  StaffService({required this.userService, SupabaseClient? client})
      : client = client ?? Supabase.instance.client;

  final SupabaseClient client;
  final UserService userService;

  /// Fetch all staff members
  Future<List<StaffModel>> fetchStaffs() async {
    debugPrint('>>> [StaffService] fetchStaffs CALLED');
    try {
      final response = await client
          .from('staff')
          .select(
              'id, user_id, first_name, last_name, profile_image_url, designation, email, address, phone, dob')
          .order('first_name', ascending: true);

      final staffs = (response as List)
          .map((item) => StaffModel.fromJson(item))
          .toList();

      debugPrint('>>> [StaffService] returning ${staffs.length} staff records');
      return staffs;
    } on PostgrestException catch (e) {
      debugPrint('❌ [StaffService] Postgrest error fetching staff [${e.code}]: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('❌ [StaffService] Error fetching staff: ${e.runtimeType}');
      rethrow;
    }
  }

  /// Fetch single staff by email
  Future<StaffModel?> fetchStaffByEmail(String email) async {
    debugPrint('>>> [StaffService] fetchStaffByEmail CALLED');
    try {
      final response = await client
          .from('staff')
          .select(
              'id, user_id, first_name, last_name, profile_image_url, designation, email, address, phone, dob')
          .eq('email', email.trim())
          .maybeSingle();

      if (response != null) {
        return StaffModel.fromJson(response);
      }
      return null;
    } on PostgrestException catch (e) {
      debugPrint('❌ [StaffService] Postgrest error fetching staff by email [${e.code}]: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('❌ [StaffService] Error fetching staff by email: ${e.runtimeType}');
      return null;
    }
  }

  /// Call Edge Function to delete Auth user
  Future<void> deleteAuthUserServerSide(String userId) async {
    final jwt = client.auth.currentSession?.accessToken;

    final res = await client.functions.invoke(
      'delete-auth-user',
      body: {'userId': userId},
      headers: { if (jwt != null) 'Authorization': 'Bearer $jwt' },
    );

    // Check if the server returned an error
  final data = res.data;
  if (data is Map && data['error'] != null) {
    throw Exception('Auth delete failed: ${data['error']}');
  }


    debugPrint('>>> [StaffService] Auth user deleted: $userId');
  }

  /// Delete staff fully: storage + DB + users + Auth
  Future<void> deleteStaffByUserIdFull(String userId, {String? email}) async {
    debugPrint('>>> [StaffService] deleteStaffByUserIdFull called: $userId');

    try {
      // 0) Delete profile image from storage
      try {
        final staffRow = await client
            .from('staff')
            .select('profile_image_key')
            .eq('user_id', userId)
            .maybeSingle();

        final String? imageKey = staffRow?['profile_image_key'] as String?;
        final bucketName = 'profile_pictures';
        final keyToDelete = imageKey ?? '$userId.jpg';

        if (keyToDelete.isNotEmpty) {
          await client.storage.from(bucketName).remove([keyToDelete]);
          debugPrint('>>> [StaffService] storage removed: $keyToDelete');
        }
      } catch (e) {
        debugPrint('⚠️ [StaffService] Storage delete warning: ${e.runtimeType}');
      }

      // 1) Delete staff rows
      final delStaff = await client
          .from('staff')
          .delete()
          .eq('user_id', userId)
          .select();
      final staffDeleted = (delStaff as List?)?.length ?? 0;
      debugPrint('>>> [StaffService] staff rows deleted=$staffDeleted');

      // Optional fallback: delete by email
      if (staffDeleted == 0 && email != null && email.isNotEmpty) {
        try {
          final delFallback = await client
              .from('staff')
              .delete()
              .eq('email', email.toLowerCase())
              .select();
          final fallbackDeleted = (delFallback as List?)?.length ?? 0;
          debugPrint('>>> [StaffService] staff fallback rows deleted=$fallbackDeleted');
        } on PostgrestException catch (e) {
          debugPrint('⚠️ [StaffService] staff fallback delete failed [${e.code}]: ${e.message}');
        } catch (e) {
          debugPrint('⚠️ [StaffService] staff fallback delete failed: ${e.runtimeType}');
        }
      }

      // 2) Delete from users table
      try {
        final delUsers = await client
            .from('users')
            .delete()
            .eq('id', userId)
            .select();
        final usersDeleted = (delUsers as List?)?.length ?? 0;
        debugPrint('>>> [StaffService] users rows deleted=$usersDeleted');
      } on PostgrestException catch (e) {
        debugPrint('⚠️ [StaffService] users delete failed [${e.code}]: ${e.message}');
      } catch (e) {
        debugPrint('⚠️ [StaffService] users delete failed: ${e.runtimeType}');
      }

      // 3) Delete Auth user via Edge Function
      await deleteAuthUserServerSide(userId);

    } on PostgrestException catch (e) {
      debugPrint('❌ [StaffService] Postgrest delete error: ${e.code} ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('❌ [StaffService] Unexpected delete error: ${e.runtimeType}');
      rethrow;
    }
  }

  /// Backward-compatible alias
  Future<void> deleteStaff({required String userId}) =>
      deleteStaffByUserIdFull(userId);
}