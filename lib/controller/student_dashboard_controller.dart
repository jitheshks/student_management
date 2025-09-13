import 'package:flutter/material.dart';
import 'package:student_management/controller/base_dashboard_controller.dart';

class StudentDashboardController extends BaseDashboardController {
@override
Future<void> load() async {
// optional: preload simple counters later
}

@override
List<Map<String, dynamic>> managementOptions(BuildContext context) => const [];
}