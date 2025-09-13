import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:student_management/common/widgets/custom_app_bar.dart';
import 'package:student_management/controller/student_bottom_navigation_controller.dart';
import 'package:student_management/controller/student_profile_controller.dart';
import 'package:intl/intl.dart';
import 'package:student_management/services/student_services.dart';
import 'package:student_management/services/user_service.dart';
import 'package:student_management/controller/student_dashboard_controller.dart';
class StudentProfileScreen extends StatelessWidget {
  final String studentId;
  final int totalDays;

  const StudentProfileScreen({
    super.key,
    required this.studentId,
    this.totalDays = 250, // default, can be dynamic
  });

  String _formatDate(DateTime? date) =>
      date == null ? 'N/A' : DateFormat('d/M/yyyy').format(date);

  @override
  Widget build(BuildContext context) {
    final navController = context.watch<StudentBottomNavController>();
    final currentIndex = navController.currentIndex;
    return ChangeNotifierProvider(
      create: (_) {
        final userService = UserService();
        final studentService = StudentService(userService: userService);
        final controller = StudentProfileController(service: studentService);
        controller.loadStudent(studentId); // Fetch when created
        return controller;
      },
      builder: (context, _) {
        final controller = context.watch<StudentProfileController>();
        final student = controller.student;

        if (controller.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (controller.error != null) {
          return Scaffold(body: Center(child: Text(controller.error!)));
        }
        if (student == null) {
          return Scaffold(body: Center(child: Text('No data found!')));
        }

        // Attendance
        final int daysPresent = student.attendance;
        final double attendancePercent =
            (daysPresent / (totalDays == 0 ? 1 : totalDays)) * 100;

        Color attendanceColor;
        if (attendancePercent < 50) {
          attendanceColor = Colors.red;
        } else if (attendancePercent <= 75) {
          attendanceColor = Colors.orange;
        } else {
          attendanceColor = Colors.green;
        }

        return Scaffold(
          backgroundColor: Colors.blue[100],
          body: CustomScrollView(
            slivers: [
              // ✅ Replaced header with CustomSliverHeader
            CustomSliverHeader(
  icon: student.profileImageUrl != null && student.profileImageUrl!.isNotEmpty
      ? CircleAvatar(
          backgroundImage: NetworkImage(student.profileImageUrl!),
          backgroundColor: Colors.white,
        )
      : Text(
          "${student.firstName.isNotEmpty ? student.firstName[0] : ''}"
          "${student.lastName.isNotEmpty ? student.lastName[0] : ''}",
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1976D2),
          ),
        ),
  title: Text("${student.firstName} ${student.lastName}"),
  subtitle: Text("Standard ${student.standard}"),
  actions: [
    Builder(
      builder: (context) => IconButton(
        icon: const Icon(Icons.logout),
        tooltip: 'Logout',
        onPressed: () => context.read<StudentDashboardController>().logout(context),
      ),
    ),
  ],
),

              // ✅ The rest of your cards wrapped in SliverToBoxAdapter
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  child: Column(
                    children: [
                      // Personal Info
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(18.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  Icon(Icons.person, color: Colors.blue),
                                  SizedBox(width: 8),
                                  Text(
                                    "Personal Information",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 24),
                              _infoRow(
                                "Full Name",
                                "${student.firstName} ${student.lastName}",
                              ),
                              _infoRow(
                                "Register Number",
                                student.registerNumber,
                              ),
                              _infoRow(
                                "Date of Birth",
                                _formatDate(student.dob),
                              ),
                              _infoRow("Phone Number", student.phone ?? ''),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Address Card
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(18.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  Icon(Icons.location_on, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text(
                                    "Address Details",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 24),
                              Text(
                                student.address ?? "",
                                style: const TextStyle(fontSize: 15),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Attendance
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        color: attendanceColor.withOpacity(0.08),
                        child: Padding(
                          padding: const EdgeInsets.all(18.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Attendance",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: attendanceColor,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "${attendancePercent.toStringAsFixed(1)}%",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 32,
                                      color: attendanceColor,
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text("$daysPresent days present"),
                                      Text(
                                        "of $totalDays total days",
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                value: daysPresent /
                                    (totalDays == 0 ? 1 : totalDays),
                                backgroundColor: attendanceColor.withOpacity(
                                  0.2,
                                ),
                                color: attendanceColor,
                                minHeight: 7,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

Widget _infoRow(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style:
                  const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(value, style: const TextStyle(fontSize: 15)),
          ),
        ],
      ),
    );
