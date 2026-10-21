import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:student_management/core/network/supabase_client_provider.dart';
import 'package:student_management/features/auth/presentation/providers/auth_providers.dart';
import 'package:student_management/features/students/data/datasources/student_remote_data_source.dart';
import 'package:student_management/features/students/data/repositories/student_repository_impl.dart';
import 'package:student_management/features/students/domain/repositories/i_student_repository.dart';
import 'package:student_management/features/students/presentation/controllers/student_form_controller.dart';
import 'package:student_management/features/students/presentation/controllers/student_list_controller.dart';
import 'package:student_management/shared/models/student.dart';

/// Provides the remote data source for Student database operations.
final studentRemoteDataSourceProvider = Provider<StudentRemoteDataSource>((
  ref,
) {
  final client = ref.watch(supabaseClientProvider);
  final authRemoteDataSource = ref.watch(authRemoteDataSourceProvider);
  return StudentRemoteDataSource(
    client: client,
    authRemoteDataSource: authRemoteDataSource,
  );
});

/// Provides the canonical Student domain repository.
final studentRepositoryProvider = Provider<IStudentRepository>((ref) {
  final remoteDataSource = ref.watch(studentRemoteDataSourceProvider);
  return StudentRepositoryImpl(remoteDataSource);
});

/// Reactive controller managing the Student List, search, filter, sort, and selection.
final studentListControllerProvider =
    AutoDisposeNotifierProvider<StudentListController, StudentListState>(
      StudentListController.new,
    );

/// Reactive controller managing Student Form input, validation, and submission.
final studentFormControllerProvider =
    AutoDisposeNotifierProvider<StudentFormController, StudentFormState>(
      StudentFormController.new,
    );

/// Auto-disposing family provider for loading an individual student profile by ID or user ID.
final studentProfileProvider = FutureProvider.autoDispose
    .family<Student, String>((ref, studentId) async {
      final repository = ref.watch(studentRepositoryProvider);
      return repository.getStudentById(studentId);
    });
