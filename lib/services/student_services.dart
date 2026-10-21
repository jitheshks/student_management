import 'package:student_management/services/user_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:student_management/model/student_model.dart';
import 'package:student_management/core/errors/app_exception.dart';
import 'package:flutter/foundation.dart';

class StudentService {
  final SupabaseClient client;
  final UserService userService;

  StudentService({required this.userService, SupabaseClient? client})
      : client = client ?? Supabase.instance.client;

  Future<List<StudentModel>> fetchStudents() async {
    debugPrint('>>> [StudentService] fetchStudents CALLED');
    try {
      final response = await client
          .from('students')
          .select(
              'id, first_name, last_name, profile_image_url, register_number, attendance, user_id, address, phone, email, dob, standard')
          .order('register_number', ascending: true);

      final students = (response as List)
          .map((item) => StudentModel.fromJson(item))
          .toList();

      debugPrint('>>> [StudentService] returning ${students.length} students');
      return students;
    } on PostgrestException catch (e) {
      debugPrint('❌ [StudentService] Postgrest error fetching students [${e.code}]: ${e.message}');
      return [];
    } catch (e) {
      debugPrint('❌ [StudentService] Error fetching students: ${e.runtimeType}');
      return [];
    }
  }

  Future<StudentModel?> fetchStudentByRegister(String registerNumber) async {
    try {
      final response = await client
          .from('students')
          .select(
              'id, first_name, last_name, profile_image_url, register_number, attendance, user_id, address, phone, email, dob, standard')
          .eq('register_number', registerNumber.trim())
          .maybeSingle();

      if (response != null) {
        return StudentModel.fromJson(response);
      }
      return null;
    } on PostgrestException catch (e) {
      debugPrint('❌ [StudentService] Postgrest error fetching student by register [${e.code}]: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('❌ [StudentService] Error fetching student by register: ${e.runtimeType}');
      return null;
    }
  }

  /// Delete a student and all related data for given Auth UID or fallback by email
  Future<void> deleteStudentByUserId({required String userId, String? email}) async {
    debugPrint('>>> [StudentService] deleteStudentByUserId CALLED with userId=$userId');

    try {
      // 0) Guard: Check for active (unreturned) book loans and block deletion
      final response = await client
          .from('borrow_records')
          .select('id, book_id')
          .eq('user_id', userId)
          .isFilter('returned_at', null);

      final activeBorrows = List<Map<String, dynamic>>.from(response);
      debugPrint('>>> [StudentService] active borrows count: ${activeBorrows.length}');

      if (activeBorrows.isNotEmpty) {
        throw ValidationException(
          'Cannot delete student: The student currently has ${activeBorrows.length} active book loan(s). '
          'Please ensure all borrowed books are returned in Library Management before deleting this student.',
        );
      }

      // 1) Delete profile image from storage
      try {
        final fileName = '$userId.jpg'; // always non-null
        await client.storage.from('profile_pictures').remove([fileName]);
        debugPrint('>>> [StudentService] profile image deleted: $fileName');
      } catch (e) {
        debugPrint('⚠️ [StudentService] failed to delete profile image: ${e.runtimeType}');
      }

      // 2) Historical borrow records are preserved: DO NOT DELETE FROM borrow_records

      // 3) Delete student profile row
      final delStudents = await client
          .from('students')
          .delete()
          .eq('user_id', userId)
          .select();
      final studentDeleted = (delStudents as List?)?.length ?? 0;
      debugPrint('>>> [StudentService] deleted student rows=$studentDeleted');

      // Fallback: if no student deleted and email provided, try delete by email
      if (studentDeleted == 0 && (email != null && email.isNotEmpty)) {
        try {
          final delFallback = await client
              .from('students')
              .delete()
              .eq('email', email.toLowerCase())
              .select();
          debugPrint('>>> [StudentService] fallback deleted student rows=${(delFallback as List?)?.length ?? 0}');
        } on PostgrestException catch (e) {
          debugPrint('⚠️ [StudentService] fallback student delete by email failed [${e.code}]: ${e.message}');
        } catch (e) {
          debugPrint('⚠️ [StudentService] fallback student delete by email failed: ${e.runtimeType}');
        }
      }

      // 4) Delete from public.users by id
      try {
        final delUsers = await client
            .from('users')
            .delete()
            .eq('id', userId)
            .select();
        debugPrint('>>> [StudentService] deleted users rows=${(delUsers as List?)?.length ?? 0}');
      } on PostgrestException catch (e) {
        debugPrint('⚠️ [StudentService] users delete failed (non-blocking) [${e.code}]: ${e.message}');
      } catch (e) {
        debugPrint('⚠️ [StudentService] users delete failed (non-blocking): ${e.runtimeType}');
      }

      // 5) Auth deletion must be done server-side (Edge Function with service_role)
    } on PostgrestException catch (e) {
      debugPrint('❌ [StudentService] Postgrest delete error: ${e.code} ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('❌ [StudentService] Unexpected delete error: ${e.runtimeType}');
      rethrow;
    }
  }
}
