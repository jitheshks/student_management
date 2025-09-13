import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ForgotPasswordScreenController with ChangeNotifier {
  final TextEditingController emailController = TextEditingController();
  bool isLoading = false;

  void setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

 Future<bool> requestOtp() async {
  final email = emailController.text.trim();
  if (email.isEmpty) return false;

  setLoading(true);
  try {
    await Supabase.instance.client.auth.resetPasswordForEmail(email);
    debugPrint('Forgot: OTP send succeeded for $email');
    return true;
  } on AuthException catch (e) {
    debugPrint('Forgot: OTP send failed (AuthException): ${e.message}');
    return false;
  } catch (e) {
    debugPrint('Forgot: OTP send failed (Exception): $e');
    return false;
  } finally {
    setLoading(false);
  }
}


  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }
}
