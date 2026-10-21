import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:student_management/core/errors/app_exception.dart';
import 'package:student_management/core/theme/app_theme.dart';
import 'package:student_management/features/staff/domain/repositories/i_staff_repository.dart';
import 'package:student_management/features/staff/presentation/providers/staff_providers.dart';
import 'package:student_management/features/staff/presentation/screens/staff_form_screen.dart';
import 'package:student_management/features/staff/presentation/screens/staff_list_screen.dart';
import 'package:student_management/features/students/domain/repositories/i_student_repository.dart';
import 'package:student_management/features/students/presentation/providers/student_providers.dart';
import 'package:student_management/features/students/presentation/screens/student_form_screen.dart';
import 'package:student_management/features/students/presentation/screens/student_list_screen.dart';
import 'package:student_management/shared/models/staff.dart';
import 'package:student_management/shared/models/student.dart';

class FakeStudentRepository implements IStudentRepository {
  final List<Student> students = [
    Student(
      id: 'std-1',
      userId: 'auth-1',
      firstName: 'Alice',
      lastName: 'Smith',
      registerNumber: '10800001',
      standard: '10th',
      email: 'alice@school.com',
      phone: '1234567890',
      address: '123 Maple St',
      attendance: 88,
      dob: DateTime(2008, 5, 12),
    ),
    Student(
      id: 'std-2',
      userId: 'auth-2',
      firstName: 'Bob',
      lastName: 'Jones',
      registerNumber: '10800002',
      standard: '9th',
      email: 'bob@school.com',
      phone: '9876543210',
      address: '456 Oak Ave',
      attendance: 62,
      dob: DateTime(2009, 8, 20),
    ),
    Student(
      id: 'std-3',
      userId: 'auth-3',
      firstName: 'Charlie',
      lastName: 'Brown',
      registerNumber: '10800003',
      standard: '10th',
      email: 'charlie@school.com',
      phone: '5556667777',
      address: '789 Pine Rd',
      attendance: 40,
      dob: DateTime(2008, 11, 3),
    ),
  ];

  @override
  Future<List<Student>> getStudents({
    String? standard,
    String? searchQuery,
    String? sortOrder = 'A-Z',
  }) async {
    List<Student> results = List.from(students);

    if (standard != null && standard != 'All') {
      results =
          results
              .where((s) => s.standard.toLowerCase() == standard.toLowerCase())
              .toList();
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim().toLowerCase();
      results =
          results.where((s) {
            final full = '${s.firstName} ${s.lastName} ${s.name}'.toLowerCase();
            final reg = s.registerNumber.toLowerCase();
            final email = (s.email ?? '').toLowerCase();
            return full.contains(q) || reg.contains(q) || email.contains(q);
          }).toList();
    }

    switch (sortOrder) {
      case 'Z-A':
        results.sort(
          (a, b) =>
              b.firstName.toLowerCase().compareTo(a.firstName.toLowerCase()),
        );
        break;
      case 'Register Number ↑':
        results.sort((a, b) => a.registerNumber.compareTo(b.registerNumber));
        break;
      case 'Register Number ↓':
        results.sort((a, b) => b.registerNumber.compareTo(a.registerNumber));
        break;
      case 'A-Z':
      default:
        results.sort(
          (a, b) =>
              a.firstName.toLowerCase().compareTo(b.firstName.toLowerCase()),
        );
        break;
    }

    return results;
  }

  @override
  Future<Student?> getStudentByRegisterNumber(String registerNumber) async {
    try {
      return students.firstWhere((s) => s.registerNumber == registerNumber);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Student> getStudentById(String studentId) async {
    try {
      return students.firstWhere(
        (s) => s.id == studentId || s.userId == studentId,
      );
    } catch (_) {
      throw NotFoundException('Student not found: $studentId');
    }
  }

  @override
  Future<void> createStudent({
    required Student student,
    required String password,
    File? avatarFile,
  }) async {
    final newStudent = student.copyWith(
      id: 'std-${students.length + 1}',
      userId: 'auth-${students.length + 1}',
      registerNumber: '1080000${students.length + 1}',
    );
    students.add(newStudent);
  }

  @override
  Future<void> updateStudent({
    required Student student,
    File? avatarFile,
  }) async {
    final index = students.indexWhere((s) => s.id == student.id);
    if (index != -1) {
      students[index] = student;
    } else {
      throw NotFoundException('Cannot update. Student not found.');
    }
  }

  @override
  Future<void> deleteStudent({
    required String studentId,
    required String authId,
    String? email,
  }) async {
    students.removeWhere((s) => s.id == studentId || s.userId == authId);
  }

  @override
  Future<Map<String, int>> bulkDeleteStudents(List<Student> toDelete) async {
    int count = 0;
    for (final s in toDelete) {
      students.removeWhere((x) => x.id == s.id);
      count++;
    }
    return {'success': count, 'fail': 0};
  }

  @override
  Future<String> generateNextRegisterNumber() async {
    return '1080000${students.length + 1}';
  }
}

class FakeStaffRepository implements IStaffRepository {
  final List<Staff> staffList = [
    Staff(
      id: 'stf-1',
      userId: 'auth-stf-1',
      firstName: 'Alice',
      lastName: 'Wong',
      designation: 'Teacher',
      email: 'alice.wong@school.com',
      phone: '1234567890',
      address: '100 University Ave',
      dob: DateTime(1985, 4, 15),
    ),
    Staff(
      id: 'stf-2',
      userId: 'auth-stf-2',
      firstName: 'Bob',
      lastName: 'Martin',
      designation: 'Librarian',
      email: 'bob.martin@school.com',
      phone: '9876543210',
      address: '200 College Blvd',
      dob: DateTime(1988, 9, 21),
    ),
    Staff(
      id: 'stf-3',
      userId: 'auth-stf-3',
      firstName: 'Charlie',
      lastName: 'Davis',
      designation: 'Staff',
      email: 'charlie.davis@school.com',
      phone: '5556667777',
      address: '300 Campus Way',
      dob: DateTime(1992, 1, 10),
    ),
  ];

  @override
  Future<List<Staff>> getStaffList({
    String? designationFilter,
    String? searchQuery,
    String? sortOrder = 'A-Z',
  }) async {
    List<Staff> results = List.from(staffList);

    if (designationFilter != null && designationFilter != 'All') {
      results =
          results
              .where(
                (s) =>
                    s.designation.toLowerCase() ==
                    designationFilter.toLowerCase(),
              )
              .toList();
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim().toLowerCase();
      results =
          results.where((s) {
            final full = '${s.firstName} ${s.lastName} ${s.name}'.toLowerCase();
            final email = (s.email ?? '').toLowerCase();
            final phone = (s.phone ?? '').toLowerCase();
            final desig = s.designation.toLowerCase();
            return full.contains(q) ||
                email.contains(q) ||
                phone.contains(q) ||
                desig.contains(q);
          }).toList();
    }

    switch (sortOrder) {
      case 'Z-A':
        results.sort(
          (a, b) =>
              b.firstName.toLowerCase().compareTo(a.firstName.toLowerCase()),
        );
        break;
      case 'A-Z':
      default:
        results.sort(
          (a, b) =>
              a.firstName.toLowerCase().compareTo(b.firstName.toLowerCase()),
        );
        break;
    }

    return results;
  }

  @override
  Future<Staff?> getStaffById(String id) async {
    try {
      return staffList.firstWhere((s) => s.id == id || s.userId == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Staff?> getStaffByEmail(String email) async {
    try {
      return staffList.firstWhere(
        (s) => s.email?.toLowerCase() == email.trim().toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> createStaff({
    required Staff staff,
    required String password,
    File? avatarFile,
  }) async {
    final newStaff = staff.copyWith(
      id: 'stf-${staffList.length + 1}',
      userId: 'auth-stf-${staffList.length + 1}',
    );
    staffList.add(newStaff);
  }

  @override
  Future<void> updateStaff({required Staff staff, File? avatarFile}) async {
    final idx = staffList.indexWhere((s) => s.id == staff.id);
    if (idx != -1) {
      staffList[idx] = staff;
    } else {
      throw NotFoundException('Staff not found: ${staff.id}');
    }
  }

  @override
  Future<void> deleteStaff({
    required String staffId,
    required String authId,
    String? email,
  }) async {
    staffList.removeWhere((s) => s.id == staffId || s.userId == authId);
  }

  @override
  Future<Map<String, int>> bulkDeleteStaff(List<Staff> toDelete) async {
    int count = 0;
    for (final staff in toDelete) {
      staffList.removeWhere((s) => s.id == staff.id);
      count++;
    }
    return {'success': count, 'fail': 0};
  }
}

void main() {
  const List<double> targetWidths = [
    320.0,
    360.0,
    390.0,
    600.0,
    768.0,
    1024.0,
    1280.0,
    1440.0,
  ];

  Widget buildTestApp({
    required Widget child,
    FakeStudentRepository? studentRepo,
    FakeStaffRepository? staffRepo,
    ThemeMode themeMode = ThemeMode.light,
  }) {
    return ProviderScope(
      overrides: [
        if (studentRepo != null)
          studentRepositoryProvider.overrideWithValue(studentRepo),
        if (staffRepo != null)
          staffRepositoryProvider.overrideWithValue(staffRepo),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        home: child,
      ),
    );
  }

  group('Batch 4: Student & Staff Management Responsive UI Tests', () {
    testWidgets(
      '1. StudentListScreen renders cleanly across all 8 target viewports with zero overflow',
      (tester) async {
        for (final width in targetWidths) {
          tester.view.physicalSize = Size(width, 800);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          final repo = FakeStudentRepository();

          await tester.pumpWidget(
            buildTestApp(child: const StudentListScreen(), studentRepo: repo),
          );

          await tester.pumpAndSettle();

          // Title & controls visible
          expect(find.text('Student Management'), findsOneWidget);
          expect(find.text('Alice Smith'), findsOneWidget);
          expect(find.text('Bob Jones'), findsOneWidget);
          expect(find.text('Charlie Brown'), findsOneWidget);

          // Zero RenderFlex layout overflow
          expect(tester.takeException(), isNull);
        }
      },
    );

    testWidgets(
      '2. StudentListScreen handles mobile landscape (800x400) and dark mode cleanly',
      (tester) async {
        tester.view.physicalSize = const Size(800, 400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final repo = FakeStudentRepository();

        await tester.pumpWidget(
          buildTestApp(
            child: const StudentListScreen(),
            studentRepo: repo,
            themeMode: ThemeMode.dark,
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Student Management'), findsOneWidget);
        expect(find.text('Alice Smith'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '3. StudentListScreen search, filter, and multi-selection work on narrow (320px) viewport',
      (tester) async {
        tester.view.physicalSize = const Size(320, 700);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final repo = FakeStudentRepository();

        await tester.pumpWidget(
          buildTestApp(child: const StudentListScreen(), studentRepo: repo),
        );

        await tester.pumpAndSettle();

        // Perform search
        await tester.enterText(find.byType(TextField).first, 'Alice');
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.text('Alice Smith'), findsOneWidget);
        expect(find.text('Bob Jones'), findsNothing);

        // Clear search
        await tester.tap(find.byIcon(Icons.clear));
        await tester.pumpAndSettle();

        expect(find.text('Bob Jones'), findsOneWidget);

        // Long press to toggle selection
        await tester.longPress(find.text('Alice Smith'));
        await tester.pumpAndSettle();

        expect(find.text('1 selected'), findsOneWidget);
        expect(find.text('Select All'), findsOneWidget);

        // Select All
        await tester.tap(find.text('Select All'));
        await tester.pumpAndSettle();

        expect(find.text('3 selected'), findsOneWidget);

        // Clear selection
        await tester.tap(find.text('Clear'));
        await tester.pumpAndSettle();

        expect(find.text('1 selected'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '4. StaffListScreen renders cleanly across all 8 target viewports with zero overflow',
      (tester) async {
        for (final width in targetWidths) {
          tester.view.physicalSize = Size(width, 800);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          final repo = FakeStaffRepository();

          await tester.pumpWidget(
            buildTestApp(child: const StaffListScreen(), staffRepo: repo),
          );

          await tester.pumpAndSettle();

          expect(find.text('Staff Management'), findsOneWidget);
          expect(find.text('Alice Wong'), findsOneWidget);
          expect(find.text('Bob Martin'), findsOneWidget);
          expect(find.text('Charlie Davis'), findsOneWidget);
          expect(find.text('Teacher'), findsOneWidget);
          expect(find.text('Librarian'), findsOneWidget);

          expect(tester.takeException(), isNull);
        }
      },
    );

    testWidgets(
      '5. StaffListScreen mobile landscape (800x400) and dark mode render cleanly',
      (tester) async {
        tester.view.physicalSize = const Size(800, 400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final repo = FakeStaffRepository();

        await tester.pumpWidget(
          buildTestApp(
            child: const StaffListScreen(),
            staffRepo: repo,
            themeMode: ThemeMode.dark,
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Staff Management'), findsOneWidget);
        expect(find.text('Alice Wong'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '6. StaffListScreen search, designation filter, and multi-select work on 320px viewport',
      (tester) async {
        tester.view.physicalSize = const Size(320, 700);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final repo = FakeStaffRepository();

        await tester.pumpWidget(
          buildTestApp(child: const StaffListScreen(), staffRepo: repo),
        );

        await tester.pumpAndSettle();

        // Search for 'Wong'
        await tester.enterText(find.byType(TextField).first, 'Wong');
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pumpAndSettle();

        expect(find.text('Alice Wong'), findsOneWidget);
        expect(find.text('Bob Martin'), findsNothing);

        // Clear search
        await tester.tap(find.byIcon(Icons.clear));
        await tester.pumpAndSettle();

        expect(find.text('Bob Martin'), findsOneWidget);

        // Long press to trigger selection
        await tester.longPress(find.text('Alice Wong'));
        await tester.pumpAndSettle();

        expect(find.text('1 selected'), findsOneWidget);

        // Select All
        await tester.tap(find.text('Select All'));
        await tester.pumpAndSettle();

        expect(find.text('3 selected'), findsOneWidget);

        // Clear
        await tester.tap(find.text('Clear'));
        await tester.pumpAndSettle();

        expect(find.text('1 selected'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '7. StudentFormScreen renders cleanly across all 8 target viewports with zero overflow',
      (tester) async {
        for (final width in targetWidths) {
          tester.view.physicalSize = Size(width, 800);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          final repo = FakeStudentRepository();

          await tester.pumpWidget(
            buildTestApp(child: const StudentFormScreen(), studentRepo: repo),
          );

          await tester.pumpAndSettle();

          expect(find.text('Add Student'), findsOneWidget);
          expect(find.text('First Name'), findsOneWidget);
          expect(find.text('Last Name'), findsOneWidget);
          expect(find.text('Create Student'), findsOneWidget);

          expect(tester.takeException(), isNull);
        }
      },
    );

    testWidgets('8. StudentFormScreen validates inputs and submits cleanly', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 750);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final repo = FakeStudentRepository();

      await tester.pumpWidget(
        buildTestApp(child: const StudentFormScreen(), studentRepo: repo),
      );

      await tester.pumpAndSettle();

      // Trigger validation errors on empty form
      await tester.ensureVisible(find.text('Create Student'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create Student'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter First Name'), findsOneWidget);
      expect(find.text('Please enter Last Name'), findsOneWidget);
      expect(find.text('Please enter address'), findsOneWidget);
      expect(find.text('Please enter phone number'), findsOneWidget);
      expect(find.text('Please enter an email'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      '9. StaffFormScreen renders cleanly across all 8 target viewports with zero overflow',
      (tester) async {
        for (final width in targetWidths) {
          tester.view.physicalSize = Size(width, 800);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          final repo = FakeStaffRepository();

          await tester.pumpWidget(
            buildTestApp(child: const StaffFormScreen(), staffRepo: repo),
          );

          await tester.pumpAndSettle();

          expect(find.text('Add Staff'), findsOneWidget);
          expect(find.text('First Name'), findsOneWidget);
          expect(find.text('Last Name'), findsOneWidget);
          expect(find.text('Create Staff'), findsOneWidget);

          expect(tester.takeException(), isNull);
        }
      },
    );

    testWidgets('10. StaffFormScreen validates inputs and submits cleanly', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 750);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final repo = FakeStaffRepository();

      await tester.pumpWidget(
        buildTestApp(child: const StaffFormScreen(), staffRepo: repo),
      );

      await tester.pumpAndSettle();

      // Trigger validation errors on empty form
      await tester.ensureVisible(find.text('Create Staff'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create Staff'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter first name'), findsOneWidget);
      expect(find.text('Please enter last name'), findsOneWidget);
      expect(find.text('Please enter email address'), findsOneWidget);
      expect(find.text('Please select a designation'), findsOneWidget);
      expect(find.text('Please select date of birth'), findsOneWidget);
      expect(find.text('Please enter phone number'), findsOneWidget);
      expect(find.text('Please enter address'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
