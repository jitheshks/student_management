import 'dart:io';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:student_management/core/errors/app_exception.dart';
import 'package:student_management/core/theme/app_theme.dart';
import 'package:student_management/features/students/domain/repositories/i_student_repository.dart';
import 'package:student_management/features/students/presentation/providers/student_providers.dart';
import 'package:student_management/features/students/presentation/screens/student_form_screen.dart';
import 'package:student_management/features/students/presentation/screens/student_list_screen.dart';
import 'package:student_management/shared/models/student.dart';
import 'package:student_management/shared/models/user_entity.dart';

class MockStudentRepository implements IStudentRepository {
  final List<Student> _students = [];
  UserEntity? currentSessionUser;

  MockStudentRepository() {
    _students.addAll([
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
        attendance: 85,
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
        attendance: 65,
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
        attendance: 45,
        dob: DateTime(2008, 11, 3),
      ),
    ]);
  }

  @override
  Future<List<Student>> getStudents({
    String? standard,
    String? searchQuery,
    String? sortOrder = 'A-Z',
  }) async {
    List<Student> results = List.from(_students);

    if (standard != null && standard != 'All') {
      results = results.where((s) => s.standard.toLowerCase() == standard.toLowerCase()).toList();
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim().toLowerCase();
      results = results.where((s) {
        final full = '${s.firstName} ${s.lastName} ${s.name}'.toLowerCase();
        final reg = s.registerNumber.toLowerCase();
        final email = (s.email ?? '').toLowerCase();
        return full.contains(q) || reg.contains(q) || email.contains(q);
      }).toList();
    }

    switch (sortOrder) {
      case 'Z-A':
        results.sort((a, b) => b.firstName.toLowerCase().compareTo(a.firstName.toLowerCase()));
        break;
      case 'Register Number ↑':
        results.sort((a, b) => a.registerNumber.compareTo(b.registerNumber));
        break;
      case 'Register Number ↓':
        results.sort((a, b) => b.registerNumber.compareTo(a.registerNumber));
        break;
      case 'A-Z':
      default:
        results.sort((a, b) => a.firstName.toLowerCase().compareTo(b.firstName.toLowerCase()));
        break;
    }

    return results;
  }

  @override
  Future<Student?> getStudentByRegisterNumber(String registerNumber) async {
    try {
      return _students.firstWhere((s) => s.registerNumber == registerNumber);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Student> getStudentById(String studentId) async {
    try {
      return _students.firstWhere((s) => s.id == studentId || s.userId == studentId);
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
    // Critical Session Invariance check: current admin session MUST NOT be wiped
    final sessionBefore = currentSessionUser;

    final reg = student.registerNumber.isNotEmpty
        ? student.registerNumber
        : await generateNextRegisterNumber();

    final newStudent = student.copyWith(
      id: 'std-${_students.length + 1}',
      userId: 'auth-${_students.length + 1}',
      registerNumber: reg,
    );
    _students.add(newStudent);

    // Verify session was not changed
    assert(currentSessionUser == sessionBefore, 'Session hijacked during student creation!');
  }

  @override
  Future<void> updateStudent({
    required Student student,
    File? avatarFile,
  }) async {
    final index = _students.indexWhere((s) => s.id == student.id);
    if (index != -1) {
      _students[index] = student;
    } else {
      throw NotFoundException('Cannot update. Student not found.');
    }
  }

  final Set<String> studentsWithActiveLoans = {};

  @override
  Future<void> deleteStudent({
    required String studentId,
    required String authId,
    String? email,
  }) async {
    if (studentsWithActiveLoans.contains(studentId) ||
        studentsWithActiveLoans.contains(authId)) {
      throw const ValidationException(
        'Cannot delete student: The student currently has 1 active book loan(s). '
        'Please ensure all borrowed books are returned in Library Management before deleting this student.',
      );
    }
    _students.removeWhere((s) => s.id == studentId || s.userId == authId);
  }

  @override
  Future<Map<String, int>> bulkDeleteStudents(List<Student> students) async {
    int success = 0;
    int fail = 0;
    for (final s in students) {
      if (studentsWithActiveLoans.contains(s.id) ||
          studentsWithActiveLoans.contains(s.userId)) {
        fail++;
      } else {
        _students.removeWhere((x) => x.id == s.id);
        success++;
      }
    }
    return {'success': success, 'fail': fail};
  }

  @override
  Future<String> generateNextRegisterNumber() async {
    final nextNum = _students.length + 1;
    return '1080${nextNum.toString().padLeft(4, '0')}';
  }
}

void main() {
  group('Phase 2 Student Repository & State Management Tests', () {
    late MockStudentRepository repository;

    setUp(() {
      repository = MockStudentRepository();
    });

    test('1. Student list loads and sorts correctly', () async {
      final listAsc = await repository.getStudents(sortOrder: 'A-Z');
      expect(listAsc.first.firstName, equals('Alice'));
      expect(listAsc.last.firstName, equals('Charlie'));

      final listDesc = await repository.getStudents(sortOrder: 'Z-A');
      expect(listDesc.first.firstName, equals('Charlie'));
      expect(listDesc.last.firstName, equals('Alice'));
    });

    test('2. Student filtering by standard and search query works', () async {
      final tenthStudents = await repository.getStudents(standard: '10th');
      expect(tenthStudents.length, equals(2));
      expect(tenthStudents.every((s) => s.standard == '10th'), isTrue);

      final searchBob = await repository.getStudents(searchQuery: 'bob');
      expect(searchBob.length, equals(1));
      expect(searchBob.first.firstName, equals('Bob'));

      final searchReg = await repository.getStudents(searchQuery: '10800003');
      expect(searchReg.length, equals(1));
      expect(searchReg.first.firstName, equals('Charlie'));
    });

    test('3. Student creation, update, and deletion operate cleanly', () async {
      final newStudent = Student(
        id: '',
        userId: '',
        firstName: 'David',
        lastName: 'Miller',
        registerNumber: '',
        standard: '8th',
        email: 'david@school.com',
      );

      await repository.createStudent(
        student: newStudent,
        password: 'David@2008',
      );

      final all = await repository.getStudents();
      expect(all.length, equals(4));
      expect(all.any((s) => s.firstName == 'David'), isTrue);

      final created = all.firstWhere((s) => s.firstName == 'David');
      final updated = created.copyWith(standard: '9th', attendance: 90);
      await repository.updateStudent(student: updated);

      final fetchedUpdated = await repository.getStudentById(created.id);
      expect(fetchedUpdated.standard, equals('9th'));
      expect(fetchedUpdated.attendance, equals(90));

      await repository.deleteStudent(studentId: created.id, authId: created.userId);
      final remaining = await repository.getStudents();
      expect(remaining.length, equals(3));
      expect(remaining.any((s) => s.firstName == 'David'), isFalse);
    });

    test('4. Critical Session Preservation Invariant: Admin session is preserved after creating student', () async {
      final adminUser = const UserEntity(
        id: 'admin-uid-1',
        email: 'admin@school.com',
        role: UserRole.admin,
      );
      repository.currentSessionUser = adminUser;

      final student = Student(
        id: '',
        userId: '',
        firstName: 'Eva',
        lastName: 'Green',
        registerNumber: '',
        standard: '7th',
        email: 'eva@school.com',
      );

      await repository.createStudent(
        student: student,
        password: 'Eva@2009',
      );

      expect(repository.currentSessionUser, isNotNull);
      expect(repository.currentSessionUser!.id, equals('admin-uid-1'));
      expect(repository.currentSessionUser!.email, equals('admin@school.com'));
      expect(repository.currentSessionUser!.role, equals(UserRole.admin));
    });

    test('5. Bulk deletion deletes multiple students and returns counts', () async {
      final initial = await repository.getStudents();
      expect(initial.length, equals(3));

      final toDelete = initial.take(2).toList();
      final res = await repository.bulkDeleteStudents(toDelete);

      expect(res['success'], equals(2));
      expect(res['fail'], equals(0));

      final after = await repository.getStudents();
      expect(after.length, equals(1));
      expect(after.first.firstName, equals('Charlie'));
    });

    test('6. Student with active loans cannot be deleted and throws ValidationException', () async {
      final initial = await repository.getStudents();
      final target = initial.first; // Alice
      repository.studentsWithActiveLoans.add(target.id);

      expect(
        () => repository.deleteStudent(
          studentId: target.id,
          authId: target.userId,
        ),
        throwsA(isA<ValidationException>()),
      );

      // Student is still in the repository and historical record is not deleted
      final after = await repository.getStudents();
      expect(after.any((s) => s.id == target.id), isTrue);
    });

    test('7. Bulk deletion reports failures and preserves students with active loans', () async {
      final initial = await repository.getStudents();
      expect(initial.length, equals(3));

      // Mark Bob as having active loans
      final bob = initial.firstWhere((s) => s.firstName == 'Bob');
      repository.studentsWithActiveLoans.add(bob.id);

      // Attempt to bulk delete Alice and Bob
      final targets = initial.take(2).toList();
      final res = await repository.bulkDeleteStudents(targets);

      expect(res['success'], equals(1));
      expect(res['fail'], equals(1));

      // Bob must still exist; Alice must be deleted
      final remaining = await repository.getStudents();
      expect(remaining.any((s) => s.firstName == 'Bob'), isTrue);
      expect(remaining.any((s) => s.firstName == 'Alice'), isFalse);
    });

    test('8. StudentListController bulkDeleteSelected surfaces error message when active loans prevent deletion', () async {
      final container = ProviderContainer(
        overrides: [
          studentRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      // Initialize students in controller
      await container.read(studentListControllerProvider.notifier).loadStudents();
      final students = container.read(studentListControllerProvider).students;
      expect(students.length, equals(3));

      // Mark first student as having active loans
      repository.studentsWithActiveLoans.add(students.first.id);

      // Select all students
      container.read(studentListControllerProvider.notifier).selectAll();

      // Trigger bulk delete
      final results = await container.read(studentListControllerProvider.notifier).bulkDeleteSelected();

      expect(results['fail'], equals(1));
      final state = container.read(studentListControllerProvider);
      expect(state.errorMessage, isNotNull);
      expect(state.errorMessage, contains('Students with active book loans cannot be deleted'));
    });
  });

  group('Phase 2 Riverpod Widget Tests', () {
    late MockStudentRepository repository;

    setUp(() {
      repository = MockStudentRepository();
    });

    testWidgets('StudentListScreen renders student cards and responsive grid', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            studentRepositoryProvider.overrideWithValue(repository),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const StudentListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Student Management'), findsOneWidget);
      expect(find.text('Alice Smith'), findsOneWidget);
      expect(find.text('Bob Jones'), findsOneWidget);
      expect(find.text('Charlie Brown'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('StudentFormScreen renders fields and validates required inputs', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            studentRepositoryProvider.overrideWithValue(repository),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const StudentFormScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Add Student'), findsOneWidget);
      expect(find.text('First Name'), findsOneWidget);
      expect(find.text('Last Name'), findsOneWidget);
      expect(find.text('Address'), findsOneWidget);
      expect(find.text('Phone Number'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Standard / Class'), findsOneWidget);
      expect(find.text('Create Student'), findsOneWidget);

      // Ensure button is visible in scrollview and tap submit with empty form to trigger validation
      await tester.ensureVisible(find.text('Create Student'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create Student'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter First Name'), findsOneWidget);
      expect(find.text('Please enter Last Name'), findsOneWidget);
      expect(find.text('Please enter address'), findsOneWidget);
      expect(find.text('Please enter phone number'), findsOneWidget);
      expect(find.text('Please enter an email'), findsOneWidget);
    });
  });
}
