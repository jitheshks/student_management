import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:student_management/core/network/supabase_client_provider.dart';
import 'package:student_management/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:student_management/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:student_management/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:student_management/shared/models/user_entity.dart';

/// Provides [AuthRemoteDataSource] instance.
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return AuthRemoteDataSource(client);
});

/// Provides canonical [IAuthRepository] implementation.
final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  final remoteDataSource = ref.watch(authRemoteDataSourceProvider);
  return AuthRepositoryImpl(remoteDataSource);
});

/// Single canonical reactive source for authenticated user state.
final authStateProvider = StreamProvider<UserEntity?>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.watchAuthState();
});

/// Fetches the currently authenticated user entity once.
final currentUserProvider = FutureProvider<UserEntity?>((ref) async {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.getCurrentUser();
});
