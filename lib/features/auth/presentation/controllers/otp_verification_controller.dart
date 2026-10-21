import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:student_management/core/errors/error_handler.dart';
import 'package:student_management/features/auth/presentation/providers/auth_providers.dart';

class OtpState {
  final int cooldown;
  final bool isVerifying;
  final bool isResending;
  final String? errorMessage;
  final bool isSuccess;

  const OtpState({
    this.cooldown = 60,
    this.isVerifying = false,
    this.isResending = false,
    this.errorMessage,
    this.isSuccess = false,
  });

  bool get canResend => cooldown == 0 && !isResending && !isVerifying;

  OtpState copyWith({
    int? cooldown,
    bool? isVerifying,
    bool? isResending,
    String? errorMessage,
    bool clearError = false,
    bool? isSuccess,
  }) {
    return OtpState(
      cooldown: cooldown ?? this.cooldown,
      isVerifying: isVerifying ?? this.isVerifying,
      isResending: isResending ?? this.isResending,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

class OtpVerificationController
    extends AutoDisposeFamilyNotifier<OtpState, String> {
  Timer? _timer;

  @override
  OtpState build(String arg) {
    ref.onDispose(() {
      _timer?.cancel();
    });
    _initTimer();
    return const OtpState(cooldown: 60);
  }

  void _initTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.cooldown <= 1) {
        timer.cancel();
        state = state.copyWith(cooldown: 0);
      } else {
        state = state.copyWith(cooldown: state.cooldown - 1);
      }
    });
  }

  void _startTimer(int seconds) {
    state = state.copyWith(cooldown: seconds, clearError: true);
    _initTimer();
  }

  Future<bool> verifyOtp(String token) async {
    final trimmedToken = token.trim();
    if (trimmedToken.length < 6) {
      state = state.copyWith(
        errorMessage: 'Please enter the complete 6-digit code.',
      );
      return false;
    }

    state = state.copyWith(isVerifying: true, clearError: true);

    try {
      final authRepository = ref.read(authRepositoryProvider);
      await authRepository.verifyOtp(email: arg, token: trimmedToken);
      state = state.copyWith(isVerifying: false, isSuccess: true);
      return true;
    } catch (e) {
      final exception = ErrorHandler.handleException(e);
      state = state.copyWith(
        isVerifying: false,
        errorMessage: exception.message,
      );
      return false;
    }
  }

  Future<bool> resendOtp() async {
    if (!state.canResend) return false;

    state = state.copyWith(isResending: true, clearError: true);

    try {
      final authRepository = ref.read(authRepositoryProvider);
      await authRepository.resetPasswordForEmail(arg);
      state = state.copyWith(isResending: false);
      _startTimer(60);
      return true;
    } catch (e) {
      final exception = ErrorHandler.handleException(e);
      state = state.copyWith(
        isResending: false,
        errorMessage: exception.message,
      );
      return false;
    }
  }
}

final otpVerificationControllerProvider = AutoDisposeNotifierProviderFamily<
  OtpVerificationController,
  OtpState,
  String
>(OtpVerificationController.new);
