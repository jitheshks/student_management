import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:student_management/controller/student_bottom_navigation_controller.dart';
import 'package:student_management/common/widgets/student_bottom_navigation.dart';
import 'package:student_management/view/screens/student_profile_screen/student_profile_screen.dart';
import 'package:student_management/view/screens/student_library_screen/student_library_screen.dart';
import 'package:student_management/view/screens/student_fees_screen/student_fees_screen.dart';

class StudentTabsShell extends StatelessWidget {
  final String id; // student’s id or auth uid
  final bool filterByUserId; // true if using auth uid for Library

  const StudentTabsShell({
    super.key,
    required this.id,
    this.filterByUserId = true,
  });

  @override
  Widget build(BuildContext context) {
    final index = context.watch<StudentBottomNavController>().currentIndex;

    final pages = <Widget>[
      StudentProfileScreen(studentId: id),
      StudentLibraryScreen(id: id, filterByUserId: filterByUserId),
      const StudentFeesScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: const StudentBottomNavigation(),
    );
  }
}
