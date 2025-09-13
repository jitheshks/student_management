import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_management/services/user_service.dart';

abstract class BaseDashboardController extends ChangeNotifier {
  int totalStudents = 0;
  int totalStaff = 0;
 String displayName = 'Administrator'; 
  Future<void> load();

  Future<void> logout(BuildContext context) async {
    await context.read<UserService>().signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/loginScreen', (_) => false);
    }
  }

  List<Map<String, dynamic>> managementOptions(BuildContext context);
}
