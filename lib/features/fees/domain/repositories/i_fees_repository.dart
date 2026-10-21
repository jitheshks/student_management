import 'package:student_management/shared/models/fee_record.dart';

abstract class IFeesRepository {
  /// Fetches institutional fee collection overview and metrics.
  Future<FeesSummary> getInstitutionalFeesSummary();

  /// Fetches fee records for a specific student by [studentId].
  Future<List<FeeRecord>> getStudentFeeRecords(String studentId);

  /// Fetches all fee records across the institution.
  Future<List<FeeRecord>> getAllFeeRecords();
}
