import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_management/controller/base_dashboard_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StaffProfileController extends BaseDashboardController {
  @override
  Future<void> load() async {
    try {
      final supabase = Supabase.instance.client;

      // Count students
      final students = await supabase.from('students').select('id');
      totalStudents = students.length;

      // Count staff
      final staffRows = await supabase.from('staff').select('id');
      totalStaff = staffRows.length;

      // Load staff first name from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('userData');
      String? nameFromPrefs;

      if (raw != null) {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        nameFromPrefs = (map['first_name'] as String?)?.trim();
      }

      if (nameFromPrefs == null || nameFromPrefs.isEmpty) {
        final uid = Supabase.instance.client.auth.currentUser?.id;
        if (uid != null) {
          // Fetch from staff table
          final row = await supabase
              .from('staff')
              .select('first_name')
              .eq('user_id', uid)
              .maybeSingle();

          final fetched = (row?['first_name'] as String?)?.trim();

          if (fetched != null && fetched.isNotEmpty) {
            displayName = fetched;

            // Persist for next time
            if (raw != null) {
              final map = jsonDecode(raw) as Map<String, dynamic>;
              map['first_name'] = fetched;
              await prefs.setString('userData', jsonEncode(map));
            }
          } else {
            // fallback to email local-part
            final email = (jsonDecode(raw ?? '{}') as Map<String, dynamic>)['email'] as String?;
            displayName = (email != null && email.contains('@')) ? email.split('@').first : 'Staff';
          }
        } else {
          displayName = 'Staff';
        }
      } else {
        displayName = nameFromPrefs;
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading staff dashboard data: $e');
      notifyListeners();
    }
  }

  @override
  List<Map<String, dynamic>> managementOptions(BuildContext context) => [
        {
          'label': 'Student Management',
          'icon': Icons.person,
          'action': () {
            Navigator.pushNamed(context, '/studentManagement');
          },
        },
        {
          'label': 'Library Management',
          'icon': Icons.library_books,
          'action': () {
            Navigator.pushNamed(context, '/libraryManagement');
          },
        },
        {
          'label': 'Fees Management',
          'icon': Icons.attach_money,
          'action': () {
            Navigator.pushNamed(context, '/feesDashboard');
          },
        },
      ];
}
