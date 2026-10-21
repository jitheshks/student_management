import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SplashScreenController with ChangeNotifier {
  final SupabaseClient? _clientOverride;
  final SharedPreferences? _prefsOverride;

  SplashScreenController({
    SupabaseClient? clientOverride,
    SharedPreferences? prefsOverride,
  })  : _clientOverride = clientOverride,
        _prefsOverride = prefsOverride;

  Future<void> checkSession(BuildContext context) async {
    final prefs = _prefsOverride ?? await SharedPreferences.getInstance();

    SupabaseClient? client = _clientOverride;
    if (client == null) {
      try {
        client = Supabase.instance.client;
      } catch (_) {
        client = null;
      }
    }

    // Optional splash delay for animation/branding
    await Future.delayed(const Duration(seconds: 2));
    if (!context.mounted) return;

    if (client == null) {
      await _clearCachedAuthPrefs(prefs);
      if (!context.mounted) return;
      context.go('/loginScreen');
      return;
    }

    final session = client.auth.currentSession;

    // Validate that session exists and is NOT expired
    if (session == null || session.isExpired || session.user.id.isEmpty) {
      await _clearCachedAuthPrefs(prefs);
      if (!context.mounted) return;
      context.go('/loginScreen');
      return;
    }

    final userId = session.user.id;

    // Authoritative role resolution: query PostgreSQL public.users strictly.
    // If user profile record does not exist in the database, fail closed.
    String? verifiedRole;
    try {
      final response = await client
          .from('users')
          .select('role')
          .eq('id', userId)
          .maybeSingle();
      if (response == null || response['role'] == null) {
        await _clearCachedAuthPrefs(prefs);
        if (!context.mounted) return;
        context.go('/loginScreen');
        return;
      }

      final dbRole = response['role'].toString().trim().toLowerCase();
      if (dbRole.isEmpty) {
        await _clearCachedAuthPrefs(prefs);
        if (!context.mounted) return;
        context.go('/loginScreen');
        return;
      }

      verifiedRole = dbRole;
    } catch (e) {
      debugPrint('[SplashScreenController] Role fetch error: $e');
      await _clearCachedAuthPrefs(prefs);
      if (!context.mounted) return;
      context.go('/loginScreen');
      return;
    }

    // Update verified cache in SharedPreferences without clearing unrelated preferences
    await prefs.setString('userRole', verifiedRole);
    await prefs.setString('user_id', userId);

    if (!context.mounted) return;

    // Navigate safely based on the verified role
    switch (verifiedRole) {
      case 'admin':
        context.go('/adminDashboard');
        break;

      case 'staff':
        context.go('/staffDashboard');
        break;

      case 'student':
        context.go('/studentDashboard');
        break;

      default:
        await _clearCachedAuthPrefs(prefs);
        if (!context.mounted) return;
        context.go('/loginScreen');
    }
  }

  Future<void> _clearCachedAuthPrefs(SharedPreferences prefs) async {
    await prefs.remove('userRole');
    await prefs.remove('user_id');
    await prefs.remove('studentId');
  }
}
