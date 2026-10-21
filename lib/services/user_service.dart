import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:student_management/model/user_model.dart';
import 'package:flutter/foundation.dart';

class UserService {
  final SupabaseClient client;

  UserService({SupabaseClient? client})
      : client = client ?? Supabase.instance.client;

  // public.users table
  static const String tableName = 'users';

  /// Fetch a user by email from the public.users table
  Future<UserModel?> fetchUserByEmail(String email) async {
    try {
      final response = await client
          .from(tableName)
  .select('id, email, role, created_at') .eq('email', email)
          .maybeSingle();

      if (response != null) {
        debugPrint('>>> [UserService] User record fetched successfully');
        return UserModel.fromJson(response);
      }
      return null;
    } on PostgrestException catch (e) {
      debugPrint('❌ [UserService] Postgrest error fetching user by email [${e.code}]: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('❌ [UserService] Error fetching user by email: ${e.runtimeType}');
      return null;
    }
  }

  /// Perform login with Supabase Auth (auth.users)
  Future<AuthResponse> signIn(String email, String password) {
    return client.auth.signInWithPassword(email: email, password: password);
  }

  /// Logout
  Future<void> signOut() async {
    await client.auth.signOut();
  }

  /// Delete profile row from public.users by Auth UID
  /// IMPORTANT: In your schema, public.users keeps the Auth UID in 'id' (not 'user_id').
  Future<void> deleteUserProfileByUserId(String authUserId) async {
    try {
      final res = await client
          .from(tableName)
          .delete()
          .eq('id', authUserId) // match by id
          .select();

      final deleted = (res as List?)?.length ?? 0;
      debugPrint('>>> [UserService] Deleted profile rows (by id): $deleted');
    } on PostgrestException catch (e) {
      debugPrint('❌ [UserService] Postgrest error deleting user profile [${e.code}]: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('❌ [UserService] Error deleting user profile: ${e.runtimeType}');
      rethrow;
    }
  }

  /// Delete profile row by its internal primary key (public.users.id)
  Future<void> deleteUserRowById(String id) async {
    try {
      final res = await client
          .from(tableName)
          .delete()
          .eq('id', id)
          .select();
      final deleted = (res as List?)?.length ?? 0;
      debugPrint('>>> [UserService] Deleted profile rows (by id): $deleted');
    } on PostgrestException catch (e) {
      debugPrint('❌ [UserService] Postgrest error deleting user row [${e.code}]: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('❌ [UserService] Error deleting user row: ${e.runtimeType}');
      rethrow;
    }
  }
}
