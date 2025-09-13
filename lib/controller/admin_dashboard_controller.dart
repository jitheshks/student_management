import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:student_management/controller/base_dashboard_controller.dart';
import 'package:student_management/controller/staff_management_controller.dart';
import 'package:student_management/controller/student_management_controller.dart';
import 'package:student_management/services/staff_service.dart';
import 'package:student_management/services/student_services.dart';
import 'package:student_management/view/screens/user_management/user_management_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminDashboardController extends BaseDashboardController {
  @override
  int totalStudents = 0;

  @override
  int totalStaff = 0;

  @override
  Future<void> load() async {
    try {
      final supabase = Supabase.instance.client;
      final students = await supabase.from('students').select('id');
      final staff    = await supabase.from('staff').select('id');

      totalStudents = students.length;
      totalStaff    = staff.length;

      notifyListeners();
    } catch (e) {
      print('Error loading dashboard data: $e');
      notifyListeners();
    }
  }

 
  @override
  List<Map<String, dynamic>> managementOptions(BuildContext context) => [
        {
          'label': 'Student Management',
          'icon': Icons.person,
          'action': () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (ctx) => ChangeNotifierProvider<StudentManagementController>(
                  create: (ctx2) {
                    final ctrl = StudentManagementController(
                      studentService: ctx2.read<StudentService>(),
                    );
                    WidgetsBinding.instance.addPostFrameCallback((_) => ctrl.fetchUsers());
                    return ctrl;
                  },
                  child: const UserManagementScreen<StudentManagementController>(
                    userType: 'student',
                    title: 'Student Management',
                    showSort: true,
                    formRoute: '/userForm',
                  ),
                ),
              ),
            );
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
          'label': 'Staff Management',
          'icon': Icons.people,
          'action': () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (ctx) => ChangeNotifierProvider<StaffManagementController>(
                  create: (ctx2) {
                    final ctrl = StaffManagementController(
                      staffService: ctx2.read<StaffService>(),
                    );
                    WidgetsBinding.instance.addPostFrameCallback((_) => ctrl.fetchUsers());
                    return ctrl;
                  },
                  child: const UserManagementScreen<StaffManagementController>(
                    userType: 'staff',
                    title: 'Staff Management',
                    showSort: false,
                    formRoute: '/userForm',
                  ),
                ),
              ),
            );
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
