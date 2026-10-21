import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_management/services/user_service.dart';

abstract class BaseDashboardController extends ChangeNotifier {
  int totalStudents = 0;
  int totalStaff = 0;
  String displayName = 'Administrator';
  bool isLoading = false;
  String? errorMessage;

  Future<void> load();

  Future<void> logout(BuildContext context) async {
    if (kDebugMode) {
      debugPrint('[BaseDashboardController] Initiating user sign out');
    }
    await context.read<UserService>().signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (context.mounted) {
      context.go('/loginScreen');
    }
  }

  List<Map<String, dynamic>> managementOptions(BuildContext context);
}
