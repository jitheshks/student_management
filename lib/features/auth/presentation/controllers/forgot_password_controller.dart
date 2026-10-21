import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:student_management/core/errors/app_exception.dart';
import 'package:student_management/core/errors/error_handler.dart';
import 'package:student_management/features/auth/presentation/providers/auth_providers.dart';

class ForgotPasswordController extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> sendResetOtp(String email) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty) {
      state = AsyncError(
        const ValidationException('Please enter your email address.'),
        StackTrace.current,
      );
      return false;
    }

    state = const AsyncLoading();

    try {
      final authRepository = ref.read(authRepositoryProvider);
      await authRepository.resetPasswordForEmail(normalizedEmail);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      final exception = ErrorHandler.handleException(e);
      state = AsyncError(exception, st);
      return false;
    }
  }
}

final forgotPasswordControllerProvider =
    AutoDisposeAsyncNotifierProvider<ForgotPasswordController, void>(
      ForgotPasswordController.new,
    );
