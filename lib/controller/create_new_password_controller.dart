import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CreateNewPasswordController with ChangeNotifier {
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmController = TextEditingController();

  bool isSubmitting = false;

  void setSubmitting(bool v) {
    isSubmitting = v;
    notifyListeners();
  }

  Future<bool> changePassword({
    required void Function(String msg) onError,
  }) async {
    final pwd = passwordController.text.trim();
    final confirm = confirmController.text.trim();

    // Basic client-side checks
    if (pwd.isEmpty || confirm.isEmpty) {
      onError('Please fill out both fields.');
      return false;
    }
    if (pwd.length < 6) {
      onError('Password must be at least 6 characters.');
      return false;
    }
    if (pwd != confirm) {
      onError('Passwords do not match.');
      return false;
    }

    setSubmitting(true);
    try {
      // User must already be signed in from verifyOTP
      final res = await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: pwd),
      );
      if (res.user == null) {
        onError('Password update failed. Try again.');
        return false;
      }
      return true;
    } on AuthException catch (e) {
      onError(e.message);
      return false;
    } catch (e) {
      onError('Unexpected error: $e');
      return false;
    } finally {
      setSubmitting(false);
    }
  }

  @override
  void dispose() {
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }
}
