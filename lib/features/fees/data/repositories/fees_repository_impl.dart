import 'package:student_management/features/fees/data/datasources/fees_remote_data_source.dart';
import 'package:student_management/features/fees/domain/repositories/i_fees_repository.dart';
import 'package:student_management/shared/models/fee_record.dart';

class FeesRepositoryImpl implements IFeesRepository {
  final IFeesRemoteDataSource remoteDataSource;

  FeesRepositoryImpl({required this.remoteDataSource});

  @override
  Future<FeesSummary> getInstitutionalFeesSummary() async {
    return remoteDataSource.fetchFeesSummary();
  }

  @override
  Future<List<FeeRecord>> getStudentFeeRecords(String studentId) async {
    return remoteDataSource.fetchFeeRecordsForStudent(studentId);
  }

  @override
  Future<List<FeeRecord>> getAllFeeRecords() async {
    return remoteDataSource.fetchAllFeeRecords();
  }
}
