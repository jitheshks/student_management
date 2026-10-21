import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:student_management/core/errors/app_exception.dart';
import 'package:student_management/core/errors/error_handler.dart';
import 'package:student_management/features/auth/presentation/providers/auth_providers.dart';

class CreateNewPasswordController extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> resetPassword({
    required String newPassword,
    required String confirmPassword,
  }) async {
    final pwd = newPassword.trim();
    final confirm = confirmPassword.trim();

    if (pwd.isEmpty || confirm.isEmpty) {
      state = AsyncError(
        const ValidationException('Please fill out both password fields.'),
        StackTrace.current,
      );
      return false;
    }

    if (pwd.length < 6) {
      state = AsyncError(
        const ValidationException(
          'Password must be at least 6 characters long.',
        ),
        StackTrace.current,
      );
      return false;
    }

    if (pwd != confirm) {
      state = AsyncError(
        const ValidationException('Passwords do not match.'),
        StackTrace.current,
      );
      return false;
    }

    state = const AsyncLoading();

    try {
      final authRepository = ref.read(authRepositoryProvider);
      await authRepository.updateUserPassword(pwd);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      final exception = ErrorHandler.handleException(e);
      state = AsyncError(exception, st);
      return false;
    }
  }
}

final createNewPasswordControllerProvider =
    AutoDisposeAsyncNotifierProvider<CreateNewPasswordController, void>(
      CreateNewPasswordController.new,
    );
