import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:student_management/features/fees/data/datasources/fees_remote_data_source.dart';
import 'package:student_management/features/fees/data/repositories/fees_repository_impl.dart';
import 'package:student_management/features/fees/domain/repositories/i_fees_repository.dart';
import 'package:student_management/shared/models/fee_record.dart';

final feesRemoteDataSourceProvider = Provider<IFeesRemoteDataSource>((ref) {
  return FeesRemoteDataSource(supabase: Supabase.instance.client);
});

final feesRepositoryProvider = Provider<IFeesRepository>((ref) {
  final remoteDataSource = ref.watch(feesRemoteDataSourceProvider);
  return FeesRepositoryImpl(remoteDataSource: remoteDataSource);
});

final institutionalFeesSummaryProvider =
    FutureProvider.autoDispose<FeesSummary>((ref) async {
      final repo = ref.watch(feesRepositoryProvider);
      return repo.getInstitutionalFeesSummary();
    });

final allFeeRecordsProvider = FutureProvider.autoDispose<List<FeeRecord>>((
  ref,
) async {
  final repo = ref.watch(feesRepositoryProvider);
  return repo.getAllFeeRecords();
});

final studentFeeRecordsProvider = FutureProvider.autoDispose
    .family<List<FeeRecord>, String>((ref, studentId) async {
      final repo = ref.watch(feesRepositoryProvider);
      return repo.getStudentFeeRecords(studentId);
    });
