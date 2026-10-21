import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:student_management/core/constants/supabase_constants.dart';
import 'package:student_management/core/errors/error_handler.dart';
import 'package:student_management/shared/models/fee_record.dart';

abstract class IFeesRemoteDataSource {
  Future<List<FeeRecord>> fetchFeeRecordsForStudent(String studentId);
  Future<List<FeeRecord>> fetchAllFeeRecords();
  Future<FeesSummary> fetchFeesSummary();
}

class FeesRemoteDataSource implements IFeesRemoteDataSource {
  final SupabaseClient supabase;

  FeesRemoteDataSource({required this.supabase});

  @override
  Future<List<FeeRecord>> fetchFeeRecordsForStudent(String studentId) async {
    try {
      final List<dynamic> response = await supabase
          .from(SupabaseConstants.feesTable)
          .select()
          .eq('student_id', studentId)
          .order('installment_no', ascending: true);

      if (response.isEmpty) {
        // Try resolving if studentId was actually a auth user_id
        final studentRes =
            await supabase
                .from(SupabaseConstants.studentsTable)
                .select('id')
                .eq('user_id', studentId)
                .maybeSingle();

        if (studentRes != null && studentRes['id'] != null) {
          final realStudentId = studentRes['id'] as String;
          final List<dynamic> retryRes = await supabase
              .from(SupabaseConstants.feesTable)
              .select()
              .eq('student_id', realStudentId)
              .order('installment_no', ascending: true);
          return retryRes
              .map(
                (row) =>
                    FeeRecord.fromJson(Map<String, dynamic>.from(row as Map)),
              )
              .toList();
        }
      }

      return response
          .map(
            (row) => FeeRecord.fromJson(Map<String, dynamic>.from(row as Map)),
          )
          .toList();
    } catch (e) {
      throw ErrorHandler.handleException(e);
    }
  }

  @override
  Future<List<FeeRecord>> fetchAllFeeRecords() async {
    try {
      final List<dynamic> response = await supabase
          .from(SupabaseConstants.feesTable)
          .select()
          .order('created_at', ascending: false);

      return response
          .map(
            (row) => FeeRecord.fromJson(Map<String, dynamic>.from(row as Map)),
          )
          .toList();
    } catch (e) {
      // If created_at doesn't exist, fallback to plain select
      try {
        final List<dynamic> fallback =
            await supabase.from(SupabaseConstants.feesTable).select();
        return fallback
            .map(
              (row) =>
                  FeeRecord.fromJson(Map<String, dynamic>.from(row as Map)),
            )
            .toList();
      } catch (inner) {
        throw ErrorHandler.handleException(inner);
      }
    }
  }

  @override
  Future<FeesSummary> fetchFeesSummary() async {
    try {
      final records = await fetchAllFeeRecords();

      double totalCollected = 0.0;
      double totalPending = 0.0;
      double totalOverdue = 0.0;
      final Set<String> allStudentsWithFees = {};
      final Set<String> paidStudents = {};

      for (final r in records) {
        totalCollected += r.paidAmount;
        totalPending += r.dueAmount;
        if (r.status == FeeStatus.overdue) {
          totalOverdue += r.dueAmount;
        }
        allStudentsWithFees.add(r.studentId);
        if (r.status == FeeStatus.paid) {
          paidStudents.add(r.studentId);
        }
      }

      int totalStudents = allStudentsWithFees.length;
      try {
        final studentsRes = await supabase
            .from(SupabaseConstants.studentsTable)
            .select('id');
        final count = (studentsRes as List).length;
        if (count > totalStudents) {
          totalStudents = count;
        }
      } catch (_) {
        // Fall back to student count from fees
      }

      return FeesSummary(
        totalCollected: totalCollected,
        totalPending: totalPending,
        totalOverdue: totalOverdue,
        totalStudents: totalStudents,
        paidStudentsCount: paidStudents.length,
      );
    } catch (e) {
      throw ErrorHandler.handleException(e);
    }
  }
}
