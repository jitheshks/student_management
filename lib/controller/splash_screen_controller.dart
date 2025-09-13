import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SplashScreenController with ChangeNotifier {
 Future<void> checkSession(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  final String? userRole = prefs.getString('userRole');
  final session = Supabase.instance.client.auth.currentSession;

  // Optional splash delay for animation/branding
  await Future.delayed(const Duration(seconds: 2));
  if (!context.mounted) return;

  // If a valid Supabase session is present, try to get role (cached or fetch live)
  if (session != null) {
    String? role = userRole;

    // If role isn't cached, fetch it from the 'users' table and save in prefs
    if (role == null) {
      final response = await Supabase.instance.client
          .from('users')
          .select('role')
          .eq('id', session.user.id)
          .maybeSingle();
      if (response != null && response['role'] != null) {
        role = response['role'] as String;
        await prefs.setString('userRole', role);
        await prefs.setString('user_id', session.user.id);
      }
    }

    // Navigate based on the user's role
    switch (role) {
      case 'admin':
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/adminDashboard',
          (_) => false,
        );
        break;

      case 'staff':
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/staffDashboard',
          (_) => false,
        );
        break;

      case 'student':
        final studentId = prefs.getString('user_id');
        if (studentId != null&& studentId.isNotEmpty) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/studentDashboard',
            (_) => false,
            arguments: {'studentId': studentId},
          );
        } else {
          Navigator.pushReplacementNamed(context, '/loginScreen');
        }
        break;

      default:
        Navigator.pushReplacementNamed(context, '/loginScreen');
    }
  } else {
    // No session, so go to login
    Navigator.pushReplacementNamed(context, '/loginScreen');
  }
}

}
