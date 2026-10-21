import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:student_management/core/errors/error_handler.dart';
import 'package:student_management/features/students/presentation/providers/student_providers.dart';
import 'package:student_management/shared/models/student.dart';

class StudentFormState {
  final bool isSubmitting;
  final bool isEditing;
  final String? studentId;
  final String? userId;
  final String? registerNumber;
  final String? selectedStandard;
  final File? avatarFile;
  final String? networkImageUrl;
  final String? errorMessage;
  final bool isSuccess;

  const StudentFormState({
    this.isSubmitting = false,
    this.isEditing = false,
    this.studentId,
    this.userId,
    this.registerNumber,
    this.selectedStandard,
    this.avatarFile,
    this.networkImageUrl,
    this.errorMessage,
    this.isSuccess = false,
  });

  StudentFormState copyWith({
    bool? isSubmitting,
    bool? isEditing,
    String? studentId,
    String? userId,
    String? registerNumber,
    String? selectedStandard,
    File? avatarFile,
    String? networkImageUrl,
    String? errorMessage,
    bool? isSuccess,
    bool clearError = false,
    bool clearAvatar = false,
  }) {
    return StudentFormState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isEditing: isEditing ?? this.isEditing,
      studentId: studentId ?? this.studentId,
      userId: userId ?? this.userId,
      registerNumber: registerNumber ?? this.registerNumber,
      selectedStandard: selectedStandard ?? this.selectedStandard,
      avatarFile: clearAvatar ? null : (avatarFile ?? this.avatarFile),
      networkImageUrl: networkImageUrl ?? this.networkImageUrl,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

class StudentFormController extends AutoDisposeNotifier<StudentFormState> {
  @override
  StudentFormState build() {
    return const StudentFormState();
  }

  void init(Student? initialStudent) {
    if (initialStudent != null) {
      state = StudentFormState(
        isEditing: true,
        studentId: initialStudent.id,
        userId: initialStudent.userId,
        registerNumber: initialStudent.registerNumber,
        selectedStandard:
            initialStudent.standard.isNotEmpty ? initialStudent.standard : null,
        networkImageUrl: initialStudent.profileImageUrl,
      );
    } else {
      state = const StudentFormState();
    }
  }

  void setStandard(String standard) {
    state = state.copyWith(selectedStandard: standard, clearError: true);
  }

  void setAvatar(File? file) {
    state = state.copyWith(avatarFile: file, clearError: true);
  }

  Future<bool> createStudent({
    required String firstName,
    required String lastName,
    required String email,
    required String standard,
    required String dobString,
    required String address,
    required String phone,
    required int attendance,
  }) async {
    state = state.copyWith(isSubmitting: true, clearError: true);

    try {
      DateTime? parsedDob;
      if (dobString.isNotEmpty) {
        try {
          parsedDob = DateFormat('d/M/yyyy').parse(dobString);
        } catch (_) {
          parsedDob = DateTime.tryParse(dobString);
        }
      }

      final normalizedEmail = email.trim().toLowerCase();
      final yearPart =
          dobString.contains('/') ? dobString.split('/').last : '2005';
      final generatedPassword = '$firstName@$yearPart';

      final newStudent = Student(
        id: '', // Will be assigned by Auth
        userId: '',
        firstName: firstName.trim(),
        lastName: lastName.trim(),
        name: '$firstName $lastName'.trim(),
        registerNumber: '', // Will be generated sequentially
        standard: standard,
        email: normalizedEmail,
        phone: phone.trim(),
        address: address.trim(),
        attendance: attendance,
        dob: parsedDob,
      );

      final repository = ref.read(studentRepositoryProvider);
      await repository.createStudent(
        student: newStudent,
        password: generatedPassword,
        avatarFile: state.avatarFile,
      );

      state = state.copyWith(isSubmitting: false, isSuccess: true);
      return true;
    } catch (e) {
      final failure = ErrorHandler.handleFailure(e);
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: failure.message,
      );
      return false;
    }
  }

  Future<bool> updateStudent({
    required String firstName,
    required String lastName,
    required String email,
    required String standard,
    required String dobString,
    required String address,
    required String phone,
    required int attendance,
  }) async {
    if (state.studentId == null || state.studentId!.isEmpty) {
      state = state.copyWith(
        errorMessage: 'No student ID provided for update.',
      );
      return false;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);

    try {
      DateTime? parsedDob;
      if (dobString.isNotEmpty) {
        try {
          parsedDob = DateFormat('d/M/yyyy').parse(dobString);
        } catch (_) {
          parsedDob = DateTime.tryParse(dobString);
        }
      }

      final updatedStudent = Student(
        id: state.studentId!,
        userId: state.userId ?? state.studentId!,
        firstName: firstName.trim(),
        lastName: lastName.trim(),
        name: '$firstName $lastName'.trim(),
        registerNumber: state.registerNumber ?? '',
        standard: standard,
        email: email.trim().toLowerCase(),
        phone: phone.trim(),
        address: address.trim(),
        attendance: attendance,
        profileImageUrl: state.networkImageUrl,
        dob: parsedDob,
      );

      final repository = ref.read(studentRepositoryProvider);
      await repository.updateStudent(
        student: updatedStudent,
        avatarFile: state.avatarFile,
      );

      state = state.copyWith(isSubmitting: false, isSuccess: true);
      return true;
    } catch (e) {
      final failure = ErrorHandler.handleFailure(e);
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: failure.message,
      );
      return false;
    }
  }
}
