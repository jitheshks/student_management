import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:student_management/core/errors/app_exception.dart';
import 'package:student_management/core/errors/error_handler.dart';
import 'package:student_management/features/students/data/datasources/student_remote_data_source.dart';
import 'package:student_management/features/students/domain/repositories/i_student_repository.dart';
import 'package:student_management/shared/models/student.dart';

class StudentRepositoryImpl implements IStudentRepository {
  final StudentRemoteDataSource _remoteDataSource;

  StudentRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<Student>> getStudents({
    String? standard,
    String? searchQuery,
    String? sortOrder = 'A-Z',
  }) async {
    try {
      final allStudents = await _remoteDataSource.fetchStudents();
      List<Student> filtered = List<Student>.from(allStudents);

      // 1. Standard Filter
      if (standard != null && standard != 'All' && standard.trim().isNotEmpty) {
        filtered =
            filtered
                .where(
                  (s) =>
                      s.standard.toLowerCase() == standard.trim().toLowerCase(),
                )
                .toList();
      }

      // 2. Search Query Filter
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final query = searchQuery.trim().toLowerCase();
        filtered =
            filtered.where((s) {
              final fullName =
                  '${s.firstName} ${s.lastName} ${s.name}'.toLowerCase();
              final regNo = s.registerNumber.toLowerCase();
              final email = (s.email ?? '').toLowerCase();
              return fullName.contains(query) ||
                  regNo.contains(query) ||
                  email.contains(query);
            }).toList();
      }

      // 3. Sort Order
      switch (sortOrder) {
        case 'Z-A':
          filtered.sort(
            (a, b) =>
                b.firstName.toLowerCase().compareTo(a.firstName.toLowerCase()),
          );
          break;
        case 'Register Number ↑':
          filtered.sort((a, b) => a.registerNumber.compareTo(b.registerNumber));
          break;
        case 'Register Number ↓':
          filtered.sort((a, b) => b.registerNumber.compareTo(a.registerNumber));
          break;
        case 'A-Z':
        default:
          filtered.sort(
            (a, b) =>
                a.firstName.toLowerCase().compareTo(b.firstName.toLowerCase()),
          );
          break;
      }

      return filtered;
    } catch (e) {
      throw ErrorHandler.handleException(e);
    }
  }

  @override
  Future<Student?> getStudentByRegisterNumber(String registerNumber) async {
    try {
      return await _remoteDataSource.fetchStudentByRegisterNumber(
        registerNumber,
      );
    } catch (e) {
      throw ErrorHandler.handleException(e);
    }
  }

  @override
  Future<Student> getStudentById(String studentId) async {
    try {
      final student = await _remoteDataSource.fetchStudentById(studentId);
      if (student == null) {
        throw NotFoundException('Student with ID $studentId not found.');
      }
      return student;
    } catch (e) {
      throw ErrorHandler.handleException(e);
    }
  }

  @override
  Future<void> createStudent({
    required Student student,
    required String password,
    File? avatarFile,
  }) async {
    try {
      await _remoteDataSource.createStudent(
        student: student,
        password: password,
        avatarFile: avatarFile,
      );
    } catch (e) {
      throw ErrorHandler.handleException(e);
    }
  }

  @override
  Future<void> updateStudent({
    required Student student,
    File? avatarFile,
  }) async {
    try {
      await _remoteDataSource.updateStudent(
        student: student,
        avatarFile: avatarFile,
      );
    } catch (e) {
      throw ErrorHandler.handleException(e);
    }
  }

  @override
  Future<void> deleteStudent({
    required String studentId,
    required String authId,
    String? email,
  }) async {
    try {
      await _remoteDataSource.deleteStudent(
        studentId: studentId,
        authId: authId,
        email: email,
      );
    } catch (e) {
      throw ErrorHandler.handleException(e);
    }
  }

  @override
  Future<Map<String, int>> bulkDeleteStudents(List<Student> students) async {
    int success = 0;
    int fail = 0;
    const maxConcurrent = 4;

    for (var i = 0; i < students.length; i += maxConcurrent) {
      final chunk = students.sublist(
        i,
        (i + maxConcurrent).clamp(0, students.length),
      );
      final futures = chunk.map((student) async {
        try {
          await deleteStudent(
            studentId: student.id,
            authId: student.userId,
            email: student.email,
          );
          success++;
        } catch (e) {
          debugPrint('⚠️ [StudentRepositoryImpl] Failed to delete student (${student.id}): $e');
          fail++;
        }
      });
      await Future.wait(futures);
    }

    return {'success': success, 'fail': fail};
  }

  @override
  Future<String> generateNextRegisterNumber() async {
    try {
      return await _remoteDataSource.generateNextRegisterNumber();
    } catch (e) {
      throw ErrorHandler.handleException(e);
    }
  }
}
