import 'package:flutter/material.dart';
import 'package:student_management/model/student_model.dart';
import 'package:student_management/services/student_services.dart';

class StudentProfileController with ChangeNotifier {
  final StudentService service;
  StudentModel? student;
  bool isLoading = false;
  String? error;

  bool _disposed = false; // Track disposal status

  StudentProfileController({required this.service});

  Future<void> loadStudent(String studentId) async {
    isLoading = true;
    safeNotify();

    try {
      final response =
          await service.client
              .from('students')
              .select()
              .eq('user_id', studentId)
              .maybeSingle();

      if (response != null) {
        student = StudentModel.fromJson(response);
        error = null;
      } else {
        student = null;
        error = "Student not found";
      }
    } catch (e) {
      student = null;
      error = "Failed to load student: $e";
    }

    isLoading = false;
    safeNotify();
  }

  void safeNotify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
