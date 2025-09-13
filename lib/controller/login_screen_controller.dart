import 'package:flutter/material.dart';
import 'package:student_management/services/user_service.dart';
import 'package:student_management/model/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

class LoginScreenController with ChangeNotifier {
  final UserService userService;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _isLoading = false;

  LoginScreenController({required this.userService});

  bool get isLoading => _isLoading;
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

Future<void> login(BuildContext context) async {
  final email = emailController.text.trim();
  final password = passwordController.text.trim();
  print('[Login] Email: $email');
  print('[Login] Password: $password');

  if (email.isEmpty || password.isEmpty) {
    if (context.mounted)
      _showSnackBar(context, '⚠️ Please enter both email and password');
    return;
  }

  _setLoading(true);

  try {
    final response = await userService.signIn(email, password);
    if (response.user != null) {
      final authUser = Supabase.instance.client.auth.currentUser;
      final uid = authUser?.id;

      final user = await userService.fetchUserByEmail(email);
      if (user != null) {
        String? firstName;
        String? lastName;

        // Fetch from auth metadata as a fallback
        final meta = authUser?.userMetadata ?? {};
        firstName = (meta['first_name'] as String?)?.trim();
        lastName = (meta['last_name'] as String?)?.trim();

        // If staff, fetch first_name from staff table
        if (user.role == 'staff' && uid != null) {
          final staffRow = await Supabase.instance.client
              .from('staff')
              .select('first_name')
              .eq('user_id', uid)
              .maybeSingle();

          final staffName = (staffRow?['first_name'] as String?)?.trim();
          if (staffName != null && staffName.isNotEmpty) {
            firstName = staffName;
          }
        }

        // fallback to email local-part if firstName still null
        final emailLocal = email.contains('@') ? email.split('@').first : null;
        final resolvedFirst = (firstName != null && firstName.isNotEmpty)
            ? firstName
            : emailLocal;
        final resolvedLast = (lastName != null && lastName.isNotEmpty) ? lastName : null;

        // Save session with safe name fields
        await _saveUserSession(
          user,
          firstName: resolvedFirst,
          lastName: resolvedLast,
        );

        // Debug print to confirm
        final prefs = await SharedPreferences.getInstance();
        debugPrint('[Login] Saved userData: ${prefs.getString('userData')}');

        // Navigate based on role
        if (context.mounted) {
          switch (user.role) {
            case 'admin':
              Navigator.pushReplacementNamed(context, '/adminDashboard');
              break;
            case 'staff':
              Navigator.pushReplacementNamed(context, '/staffDashboard');
              break;
            default:
              Navigator.pushNamedAndRemoveUntil(context, '/studentDashboard',    (_) => false,arguments: {
            'studentId': user.id,
              });
              break;
          }
        }
      } else {
        if (context.mounted) _showSnackBar(context, '❌ User role not found.');
      }
    } else {
      if (context.mounted)
        _showSnackBar(context, '❌ Login failed. Invalid credentials.');
    }
  } on AuthException catch (e) {
    if (context.mounted) _showSnackBar(context, e.message);
  } catch (e) {
    if (context.mounted)
      _showSnackBar(context, 'An unexpected error occurred.');
  } finally {
    if (context.mounted) _setLoading(false);
  }
}

Future<void> _saveUserSession(
  UserModel user, {
  String? firstName,
  String? lastName,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final map = user.toJson();

  // ✅ Add name fields if available
  if (firstName != null) map['first_name'] = firstName;
  if (lastName != null) map['last_name'] = lastName;

  await prefs.setBool('isLoggedIn', true);
  await prefs.setString('userData', jsonEncode(map));
  await prefs.setString('userRole', user.role);
  await prefs.setString('user_id', user.id);
}

  Future<UserModel?> getUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('userData');
    if (userData == null) return null;
    return UserModel.fromJson(jsonDecode(userData));
  }

  void _showSnackBar(BuildContext context, String message) {
    print('[SnackBar] $message');
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
