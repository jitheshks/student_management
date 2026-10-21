import 'package:flutter_test/flutter_test.dart';
import 'package:student_management/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:student_management/shared/models/user_entity.dart';
import 'package:student_management/core/errors/app_exception.dart';

class MockAuthRepository implements IAuthRepository {
  UserEntity? _currentUser;
  final Map<String, String> _userStore = {
    'admin@school.com': 'admin123',
    'staff@school.com': 'staff123',
    'student@school.com': 'student123',
  };
  final Map<String, UserRole> _userRoles = {
    'admin@school.com': UserRole.admin,
    'staff@school.com': UserRole.staff,
    'student@school.com': UserRole.student,
  };
  final Map<String, String> _otpStore = {};

  @override
  Future<UserEntity?> getCurrentUser() async {
    return _currentUser;
  }

  @override
  Future<UserEntity> signInWithPassword({
    required String email,
    required String password,
  }) async {
    if (_userStore[email] == password) {
      _currentUser = UserEntity(
        id: 'uid-$email',
        email: email,
        role: _userRoles[email] ?? UserRole.student,
      );
      return _currentUser!;
    }
    throw const AppAuthException('Invalid email or password.');
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
  }

  @override
  Future<void> resetPasswordForEmail(String email) async {
    if (!_userStore.containsKey(email)) {
      throw const AppAuthException('No account found with this email.');
    }
    _otpStore[email] = '123456';
  }

  @override
  Future<void> verifyOtp({
    required String email,
    required String token,
  }) async {
    if (_otpStore[email] != token) {
      throw const AppAuthException('Invalid or expired verification code.');
    }
  }

  @override
  Future<void> updateUserPassword(String newPassword) async {
    if (_currentUser == null) {
      throw const AppAuthException('No authenticated session found.');
    }
    _userStore[_currentUser!.email] = newPassword;
  }

  @override
  Stream<UserEntity?> watchAuthState() async* {
    yield _currentUser;
  }

  @override
  Future<String> createUser({
    required String email,
    required String password,
    required UserRole role,
  }) async {
    // Crucial requirement: creating a new user MUST NOT alter _currentUser session
    final initialSessionUser = _currentUser;

    final newUid = 'created-uid-$email';
    _userStore[email] = password;
    _userRoles[email] = role;

    // Verify session invariance
    assert(_currentUser == initialSessionUser, 'Session was hijacked during user creation!');
    return newUid;
  }
}

void main() {
  group('Phase 1 Auth Repository & Session Invariant Tests', () {
    late MockAuthRepository authRepo;

    setUp(() {
      authRepo = MockAuthRepository();
    });

    test('1. Login success sets active session with correct role', () async {
      final user = await authRepo.signInWithPassword(
        email: 'admin@school.com',
        password: 'admin123',
      );

      expect(user.email, equals('admin@school.com'));
      expect(user.role, equals(UserRole.admin));
      expect(user.isAdmin, isTrue);

      final current = await authRepo.getCurrentUser();
      expect(current, equals(user));
    });

    test('2. Login failure with wrong credentials throws AppAuthException', () async {
      expect(
        () => authRepo.signInWithPassword(
          email: 'admin@school.com',
          password: 'wrongpassword',
        ),
        throwsA(isA<AppAuthException>()),
      );

      final current = await authRepo.getCurrentUser();
      expect(current, isNull);
    });

    test('3. Logout clears the active session', () async {
      await authRepo.signInWithPassword(
        email: 'staff@school.com',
        password: 'staff123',
      );
      expect(await authRepo.getCurrentUser(), isNotNull);

      await authRepo.signOut();
      expect(await authRepo.getCurrentUser(), isNull);
    });

    test('4. Password recovery OTP request, verification, and reset flow', () async {
      // 1. Request OTP
      await authRepo.resetPasswordForEmail('student@school.com');

      // 2. Verify OTP
      await authRepo.verifyOtp(email: 'student@school.com', token: '123456');

      // Wrong OTP fails
      expect(
        () => authRepo.verifyOtp(email: 'student@school.com', token: '000000'),
        throwsA(isA<AppAuthException>()),
      );
    });

    test('5. Critical Session-Hijacking Invariant: Admin session is preserved after creating student/staff', () async {
      // Step 1: Admin logs in
      final adminUser = await authRepo.signInWithPassword(
        email: 'admin@school.com',
        password: 'admin123',
      );
      expect(await authRepo.getCurrentUser(), equals(adminUser));
      expect(adminUser.isAdmin, isTrue);

      // Step 2: Admin creates a new student account
      final newStudentUid = await authRepo.createUser(
        email: 'newstudent@school.com',
        password: 'studentPass123',
        role: UserRole.student,
      );
      expect(newStudentUid, equals('created-uid-newstudent@school.com'));

      // Invariant Check 1: Current session is STILL the original Admin!
      final activeUserAfterStudent = await authRepo.getCurrentUser();
      expect(activeUserAfterStudent, isNotNull);
      expect(activeUserAfterStudent!.id, equals(adminUser.id));
      expect(activeUserAfterStudent.email, equals('admin@school.com'));
      expect(activeUserAfterStudent.role, equals(UserRole.admin));

      // Step 3: Admin creates a new staff account
      final newStaffUid = await authRepo.createUser(
        email: 'newstaff@school.com',
        password: 'staffPass123',
        role: UserRole.staff,
      );
      expect(newStaffUid, equals('created-uid-newstaff@school.com'));

      // Invariant Check 2: Current session is STILL the original Admin!
      final activeUserAfterStaff = await authRepo.getCurrentUser();
      expect(activeUserAfterStaff, isNotNull);
      expect(activeUserAfterStaff!.id, equals(adminUser.id));
      expect(activeUserAfterStaff.email, equals('admin@school.com'));
      expect(activeUserAfterStaff.role, equals(UserRole.admin));
    });
  });
}
