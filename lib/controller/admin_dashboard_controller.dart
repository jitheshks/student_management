import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:student_management/controller/base_dashboard_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminDashboardController extends BaseDashboardController {
  @override
  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final supabase = Supabase.instance.client;
      final students = await supabase.from('students').select('id');
      final staff = await supabase.from('staff').select('id');

      totalStudents = students.length;
      totalStaff = staff.length;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[AdminDashboardController] Error loading dashboard data: $e',
        );
      }
      errorMessage = 'Failed to load dashboard metrics';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  @override
  List<Map<String, dynamic>> managementOptions(BuildContext context) => [
    {
      'label': 'Student Management',
      'icon': Icons.person,
      'action': () {
        context.push('/studentManagement');
      },
    },
    {
      'label': 'Library Management',
      'icon': Icons.library_books,
      'action': () {
        context.push('/libraryManagement');
      },
    },
    {
      'label': 'Staff Management',
      'icon': Icons.people,
      'action': () {
        context.push('/staffManagement');
      },
    },
    {
      'label': 'Fees Management',
      'icon': Icons.attach_money,
      'action': () {
        context.push('/feesDashboard');
      },
    },
  ];
}
