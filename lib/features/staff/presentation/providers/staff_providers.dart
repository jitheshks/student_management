import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:student_management/core/network/supabase_client_provider.dart';
import 'package:student_management/features/auth/presentation/providers/auth_providers.dart';
import 'package:student_management/features/staff/data/datasources/staff_remote_data_source.dart';
import 'package:student_management/features/staff/data/repositories/staff_repository_impl.dart';
import 'package:student_management/features/staff/domain/repositories/i_staff_repository.dart';
import 'package:student_management/features/staff/presentation/controllers/staff_form_controller.dart';
import 'package:student_management/features/staff/presentation/controllers/staff_list_controller.dart';
import 'package:student_management/shared/models/staff.dart';

/// Provides the remote data source for Staff database operations.
final staffRemoteDataSourceProvider = Provider<StaffRemoteDataSource>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final authRemoteDataSource = ref.watch(authRemoteDataSourceProvider);
  return StaffRemoteDataSource(
    client: client,
    authRemoteDataSource: authRemoteDataSource,
  );
});

/// Provides the canonical Staff domain repository.
final staffRepositoryProvider = Provider<IStaffRepository>((ref) {
  final remoteDataSource = ref.watch(staffRemoteDataSourceProvider);
  return StaffRepositoryImpl(remoteDataSource);
});

/// Reactive controller managing Staff List, search, filter, sort, and selection.
final staffListControllerProvider =
    AutoDisposeNotifierProvider<StaffListController, StaffListState>(
      StaffListController.new,
    );

/// Reactive controller managing Staff Form input, validation, and submission.
final staffFormControllerProvider =
    AutoDisposeNotifierProvider<StaffFormController, StaffFormState>(
      StaffFormController.new,
    );

/// Auto-disposing family provider for loading an individual staff profile by ID or user ID.
final staffProfileProvider = FutureProvider.autoDispose.family<Staff?, String>((
  ref,
  staffId,
) async {
  final repository = ref.watch(staffRepositoryProvider);
  return repository.getStaffById(staffId);
});
