import 'dart:io';
import 'package:student_management/shared/models/student.dart';

abstract class IStudentRepository {
  /// Fetches a list of students with optional filtering and sorting.
  Future<List<Student>> getStudents({
    String? standard,
    String? searchQuery,
    String? sortOrder,
  });

  /// Fetches a student by their unique register number.
  Future<Student?> getStudentByRegisterNumber(String registerNumber);

  /// Fetches a student by their primary ID / user ID.
  Future<Student> getStudentById(String studentId);

  /// Creates a new student record and auth credentials without hijacking the active session.
  Future<void> createStudent({
    required Student student,
    required String password,
    File? avatarFile,
  });

  /// Updates an existing student record and optionally uploads a new avatar.
  Future<void> updateStudent({required Student student, File? avatarFile});

  /// Deletes a single student record and associated auth account.
  Future<void> deleteStudent({
    required String studentId,
    required String authId,
    String? email,
  });

  /// Bulk deletes a list of students, returning counts of success and failure.
  Future<Map<String, int>> bulkDeleteStudents(List<Student> students);

  /// Generates the next sequential register number for students.
  Future<String> generateNextRegisterNumber();
}
