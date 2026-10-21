import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:student_management/core/errors/app_exception.dart';
import 'package:student_management/core/errors/error_handler.dart';
import 'package:student_management/features/auth/presentation/providers/auth_providers.dart';
import 'package:student_management/shared/models/user_entity.dart';

class LoginController extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {
    // Initial state is AsyncData(null)
  }

  Future<UserEntity?> login({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final normalizedPassword = password.trim();

    if (normalizedEmail.isEmpty || normalizedPassword.isEmpty) {
      state = AsyncError(
        const ValidationException('Please enter both email and password.'),
        StackTrace.current,
      );
      return null;
    }

    state = const AsyncLoading();

    try {
      final authRepository = ref.read(authRepositoryProvider);
      final userEntity = await authRepository.signInWithPassword(
        email: normalizedEmail,
        password: normalizedPassword,
      );

      state = const AsyncData(null);
      return userEntity;
    } catch (e, st) {
      final exception = ErrorHandler.handleException(e);
      state = AsyncError(exception, st);
      return null;
    }
  }

  Future<void> logout() async {
    state = const AsyncLoading();
    try {
      final authRepository = ref.read(authRepositoryProvider);
      await authRepository.signOut();
      state = const AsyncData(null);
    } catch (e, st) {
      final exception = ErrorHandler.handleException(e);
      state = AsyncError(exception, st);
    }
  }
}

final loginControllerProvider =
    AutoDisposeAsyncNotifierProvider<LoginController, void>(
      LoginController.new,
    );
