import 'package:student_management/services/user_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:student_management/model/student_model.dart';
import 'package:flutter/foundation.dart';

class StudentService {
  final SupabaseClient client = Supabase.instance.client;
  final UserService userService;

  StudentService({required this.userService});

  Future<List<StudentModel>> fetchStudents() async {
    debugPrint('>>> [StudentService] fetchStudents CALLED');
    try {
      final response = await client
          .from('students')
          .select(
              'id, first_name, last_name, profile_image_url, register_number, attendance, user_id, address, phone, email, dob, standard')
          .order('register_number', ascending: true);

      debugPrint('>>> [StudentService] raw response: $response');

      final students = (response as List)
          .map((item) => StudentModel.fromJson(item))
          .toList();

      debugPrint('>>> [StudentService] returning ${students.length} students');
      return students;
    } catch (e, stackTrace) {
      debugPrint('❌ Error fetching students: $e');
      debugPrint('❌ StackTrace: $stackTrace');
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
    } catch (e) {
      debugPrint('❌ Error fetching student by register: $e');
      return null;
    }
  }

  /// Delete a student and all related data for given Auth UID or fallback by email
  Future<void> deleteStudentByUserId({required String userId, String? email}) async {
    debugPrint('>>> [StudentService] deleteStudentByUserId CALLED with userId=$userId, email=$email');

    try {
      // 0) Delete profile image from storage
      try {
        final fileName = '$userId.jpg'; // always non-null
        await client.storage.from('profile_pictures').remove([fileName]);
        debugPrint('>>> [StudentService] profile image deleted: $fileName');
      } catch (e) {
        debugPrint('⚠️ [StudentService] failed to delete profile image: $e');
      }

      // 1) Restore copies for any active borrows
      final response = await client
          .from('borrow_records')
          .select('book_id')
          .eq('user_id', userId)
          .isFilter('returned_at', null);

      final activeBorrows = List<Map<String, dynamic>>.from(response);
      debugPrint('>>> [StudentService] active borrows count: ${activeBorrows.length}');

      for (final row in activeBorrows) {
        final bookId = row['book_id'] as String?;
        if (bookId == null) continue;

        final book = await client
            .from('books')
            .select('copies')
            .eq('id', bookId)
            .maybeSingle();

        if (book != null && book['copies'] is int) {
          final newCopies = (book['copies'] as int) + 1;
          await client.from('books').update({'copies': newCopies}).eq('id', bookId);
          debugPrint('>>> [StudentService] Restored a copy for book $bookId (new copies=$newCopies)');
        }
      }

      // 2) Delete borrow records
      final delBorrows = await client
          .from('borrow_records')
          .delete()
          .eq('user_id', userId)
          .select();
      debugPrint('>>> [StudentService] deleted borrow rows=${(delBorrows as List?)?.length ?? 0}');

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
        } catch (e) {
          debugPrint('⚠️ [StudentService] fallback student delete by email failed: $e');
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
        debugPrint('⚠️ [StudentService] users delete failed (non-blocking): ${e.code} ${e.message}');
      }

      // 5) Auth deletion must be done server-side (Edge Function with service_role)
    } on PostgrestException catch (e) {
      debugPrint('❌ Postgrest delete error: ${e.code} ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('❌ Unexpected delete error: $e');
      rethrow;
    }
  }
}
