import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OtpVerificationController with ChangeNotifier {
  OtpVerificationController({required this.email, this.initialCooldown = 60}) {
    _cooldown = initialCooldown;
    _startTimer();
  }

  final String email;
  final int initialCooldown;

  final TextEditingController otpController = TextEditingController();
  bool isVerifying = false;
  bool isResending = false;

  int _cooldown = 0;
  Timer? _timer;

  int get cooldown => _cooldown;
  bool get canResend => _cooldown == 0 && !isResending && !isVerifying;

  void _startTimer() {
    _timer?.cancel();
    if (_cooldown <= 0) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_cooldown <= 1) {
        t.cancel();
        _cooldown = 0;
      } else {
        _cooldown -= 1;
      }
      notifyListeners();
    });
  }

  Future<void> resendOtp({
    required VoidCallback onTooManyRequests,
    required VoidCallback onResent,
    required void Function(String message) onError,
  }) async {
    if (!canResend) return;
    isResending = true;
    notifyListeners();
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
      _cooldown = initialCooldown;
      _startTimer();
      onResent();
    } on AuthException catch (e) {
      final msg = e.message;
      if (e.statusCode == 429 || msg.toLowerCase().contains('rate limit')) {
        _cooldown = initialCooldown * 2;
        _startTimer();
        onTooManyRequests();
      } else {
        onError(msg);
      }
    } catch (e) {
      onError('Failed to resend code: $e');
    } finally {
      isResending = false;
      notifyListeners();
    }
  }

  Future<void> verifyAndProceed({
    required BuildContext context,
    required void Function(String message) onError,
  }) async {
    final code = otpController.text.trim();
    if (code.length != 6) {
      onError('Please enter the 6-digit code.');
      return;
    }
    isVerifying = true;
    notifyListeners();
    try {
      final res = await Supabase.instance.client.auth.verifyOTP(
        email: email,
        token: code,
        type: OtpType.recovery,
      );

      if (res.session == null) {
        onError('Invalid or expired code. Please try again.');
        return;
      }

      if (!context.mounted) return;
      // Navigate to the screen where the new password will be set
      Navigator.pushReplacementNamed(context, '/createNewPassword');
    } on AuthException catch (e) {
      onError(e.message);
    } catch (e) {
      onError('Verification failed: $e');
    } finally {
      isVerifying = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    otpController.dispose();
    super.dispose();
  }
}
