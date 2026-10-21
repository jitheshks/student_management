// ignore_for_file: deprecated_member_use
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:student_management/controller/login_screen_controller.dart';
import 'package:student_management/controller/forgot_password_screen_controller.dart';
import 'package:student_management/controller/borrow_book_controller.dart';
import 'package:student_management/controller/student_form_page_controller.dart';
import 'package:student_management/model/student_model.dart';
import 'package:student_management/services/borrow_book_services.dart';
import 'package:student_management/services/staff_service.dart';
import 'package:student_management/services/student_services.dart';
import 'package:student_management/services/user_service.dart';
import 'package:student_management/services/return_book_services.dart';

class FakeStudentService extends Fake implements StudentService {
  final StudentModel? returnStudent;
  FakeStudentService({this.returnStudent});

  @override
  Future<StudentModel?> fetchStudentByRegister(String registerNumber) async {
    return returnStudent;
  }
}

class FakeBorrowBookService extends Fake implements BorrowBookService {}

class FakeUserService extends Fake implements UserService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const supabaseUrl = 'https://mock-school-db.supabase.co';
  const anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.dummy-anon-key';

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: anonKey,
        httpClient: MockClient((request) async {
          if (request.url.path.contains('/auth/v1/recover')) {
            return http.Response(
              jsonEncode({}),
              200,
              request: request,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response(
            jsonEncode({}),
            200,
            request: request,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
    } catch (_) {}
  });

  group('Phase B Batch 1 & 1A: Credential and Sensitive Logging Remediation Tests', () {
    late List<String> capturedLogs;
    late DebugPrintCallback originalDebugPrint;

    setUp(() {
      capturedLogs = [];
      originalDebugPrint = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null) {
          capturedLogs.add(message);
        }
      };
    });

    tearDown(() {
      debugPrint = originalDebugPrint;
    });

    test('1. StaffService.fetchStaffs does NOT log JWT access token or raw staff PII', () async {
      final mockStaffResponse = [
        {
          'id': 'stf-001',
          'user_id': 'auth-001',
          'first_name': 'Jane',
          'last_name': 'Smith',
          'profile_image_url': 'https://example.com/jane.jpg',
          'designation': 'Professor',
          'email': 'jane.smith@synthetic-test-domain.com',
          'address': '742 Evergreen Terrace, Springfield',
          'phone': '+1-555-0199',
          'dob': '1980-05-12',
        },
        {
          'id': 'stf-002',
          'user_id': 'auth-002',
          'first_name': 'John',
          'last_name': 'Doe',
          'profile_image_url': null,
          'designation': 'Counselor',
          'email': 'john.doe@synthetic-test-domain.com',
          'address': '123 Fake Street, Springfield',
          'phone': '+1-555-0188',
          'dob': '1985-08-20',
        },
      ];

      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/rest/v1/staff')) {
          return http.Response(
            jsonEncode(mockStaffResponse),
            200,
            request: request,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404, request: request);
      });

      final client = SupabaseClient(
        supabaseUrl,
        anonKey,
        httpClient: mockClient,
      );

      final userService = UserService(client: client);
      final staffService = StaffService(userService: userService, client: client);

      final result = await staffService.fetchStaffs();
      expect(result.length, equals(2));

      // Assert zero JWT or token logging
      final tokenLeaks = capturedLogs.where((l) =>
          l.contains('Current JWT:') ||
          l.toLowerCase().contains('bearer') ||
          l.contains('accessToken') ||
          l.contains('eyJ'));
      expect(tokenLeaks, isEmpty, reason: 'StaffService should never log JWT access tokens');

      // Assert zero raw response or staff PII logging
      final rawResponseLogs = capturedLogs.where((l) => l.contains('raw response:'));
      expect(rawResponseLogs, isEmpty, reason: 'StaffService should never log raw response map');

      final piiLeaks = capturedLogs.where((l) =>
          l.contains('742 Evergreen Terrace') ||
          l.contains('+1-555-0199') ||
          l.contains('123 Fake Street') ||
          l.contains('+1-555-0188'));
      expect(piiLeaks, isEmpty, reason: 'StaffService should never log staff phone or address');

      // Assert safe diagnostic logs remain present
      expect(capturedLogs.any((l) => l.contains('fetchStaffs CALLED')), isTrue);
      expect(capturedLogs.any((l) => l.contains('returning 2 staff records')), isTrue);
    });

    test('2. StaffService.fetchStaffByEmail does NOT log staff email address', () async {
      const targetEmail = 'target.faculty@synthetic-domain.com';
      final mockResponse = {
        'id': 'stf-003',
        'user_id': 'auth-003',
        'first_name': 'Mark',
        'last_name': 'Taylor',
        'profile_image_url': null,
        'designation': 'Lecturer',
        'email': targetEmail,
        'address': '456 Academic Way',
        'phone': '+1-555-0177',
        'dob': '1975-03-10',
      };

      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/rest/v1/staff')) {
          final acceptHeader = request.headers['accept'] ?? '';
          if (acceptHeader.contains('application/vnd.pgrst.object+json')) {
            return http.Response(
              jsonEncode(mockResponse),
              200,
              request: request,
              headers: {'content-type': 'application/vnd.pgrst.object+json'},
            );
          }
          return http.Response(
            jsonEncode([mockResponse]),
            200,
            request: request,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404, request: request);
      });

      final client = SupabaseClient(
        supabaseUrl,
        anonKey,
        httpClient: mockClient,
      );

      final userService = UserService(client: client);
      final staffService = StaffService(userService: userService, client: client);

      final staff = await staffService.fetchStaffByEmail(targetEmail);
      expect(staff, isNotNull);

      // Verify email address is not printed in logs
      final emailLogs = capturedLogs.where((l) => l.contains(targetEmail));
      expect(emailLogs, isEmpty, reason: 'StaffService should not print plain email addresses in fetchStaffByEmail');

      expect(capturedLogs.any((l) => l.contains('fetchStaffByEmail CALLED')), isTrue);
    });

    test('3. StudentService.fetchStudents does NOT log raw student database records or PII', () async {
      final mockStudentResponse = [
        {
          'id': 'std-001',
          'user_id': 'auth-std-001',
          'first_name': 'Alice',
          'last_name': 'Johnson',
          'profile_image_url': 'https://example.com/alice.jpg',
          'register_number': '10800001',
          'attendance': 92,
          'address': '555 Pine Lane, Springfield',
          'phone': '+1-555-0144',
          'email': 'alice.j@synthetic-domain.com',
          'dob': '2008-11-15',
          'standard': '10th',
        },
        {
          'id': 'std-002',
          'user_id': 'auth-std-002',
          'first_name': 'Bob',
          'last_name': 'Williams',
          'profile_image_url': null,
          'register_number': '10800002',
          'attendance': 85,
          'address': '777 Maple Drive, Springfield',
          'phone': '+1-555-0155',
          'email': 'bob.w@synthetic-domain.com',
          'dob': '2008-07-22',
          'standard': '10th',
        },
      ];

      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/rest/v1/students')) {
          return http.Response(
            jsonEncode(mockStudentResponse),
            200,
            request: request,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404, request: request);
      });

      final client = SupabaseClient(
        supabaseUrl,
        anonKey,
        httpClient: mockClient,
      );

      final userService = UserService(client: client);
      final studentService = StudentService(userService: userService, client: client);

      final result = await studentService.fetchStudents();
      expect(result.length, equals(2));

      // Assert zero raw response logging
      final rawLogs = capturedLogs.where((l) => l.contains('raw response:'));
      expect(rawLogs, isEmpty, reason: 'StudentService should never log raw response dictionary');

      // Assert student PII is not leaked
      final piiLogs = capturedLogs.where((l) =>
          l.contains('555 Pine Lane') ||
          l.contains('+1-555-0144') ||
          l.contains('777 Maple Drive') ||
          l.contains('+1-555-0155'));
      expect(piiLogs, isEmpty, reason: 'StudentService should never log student address or phone');

      // Assert safe diagnostic logs remain present
      expect(capturedLogs.any((l) => l.contains('fetchStudents CALLED')), isTrue);
      expect(capturedLogs.any((l) => l.contains('returning 2 students')), isTrue);
    });

    test('4. UserService.fetchUserByEmail does NOT dump raw user dictionary containing email', () async {
      const email = 'user.test@synthetic-domain.com';
      final mockUserResponse = {
        'id': 'usr-001',
        'email': email,
        'role': 'staff',
        'created_at': '2026-01-01T00:00:00Z',
      };

      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/rest/v1/users')) {
          final acceptHeader = request.headers['accept'] ?? '';
          if (acceptHeader.contains('application/vnd.pgrst.object+json')) {
            return http.Response(
              jsonEncode(mockUserResponse),
              200,
              request: request,
              headers: {'content-type': 'application/vnd.pgrst.object+json'},
            );
          }
          return http.Response(
            jsonEncode([mockUserResponse]),
            200,
            request: request,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404, request: request);
      });

      final client = SupabaseClient(
        supabaseUrl,
        anonKey,
        httpClient: mockClient,
      );

      final userService = UserService(client: client);
      final user = await userService.fetchUserByEmail(email);
      expect(user, isNotNull);

      final rawDumps = capturedLogs.where((l) => l.contains('User fetched: {'));
      expect(rawDumps, isEmpty, reason: 'UserService should not dump raw user record with email');

      expect(capturedLogs.any((l) => l.contains('User record fetched successfully')), isTrue);
    });

    test('5. ReturnBookService.fetchBorrowedBooks logs record count without dumping raw loan dictionary', () async {
      const regNo = '10800099';
      final mockLoans = [
        {
          'id': 'loan-1',
          'book_id': 'bk-1',
          'isbn': '9780132350884',
          'borrowed_at': '2026-02-01T10:00:00Z',
          'due_date': '2026-02-15T10:00:00Z',
          'books': {
            'title': 'Clean Code',
            'author': 'Robert C. Martin',
            'cover_url': 'https://example.com/cc.jpg',
          },
        },
      ];

      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/rest/v1/borrow_records')) {
          return http.Response(
            jsonEncode(mockLoans),
            200,
            request: request,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404, request: request);
      });

      final client = SupabaseClient(
        supabaseUrl,
        anonKey,
        httpClient: mockClient,
      );

      final returnService = ReturnBookService(supabase: client);
      final loans = await returnService.fetchBorrowedBooks(regNo);
      expect(loans.length, equals(1));

      // Assert no raw response print
      final rawPrints = capturedLogs.where((l) =>
          l.contains('Supabase response for') ||
          l.contains('Sample record:'));
      expect(rawPrints, isEmpty, reason: 'ReturnBookService should not print raw borrow records or sample dicts');

      // Safe count is present
      expect(capturedLogs.any((l) => l.contains('Fetched 1 borrowed book records')), isTrue);
    });

    testWidgets('6. LoginScreenController.login does NOT log plain email address', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {},
                child: const Text('Go'),
              ),
            ),
          ),
        ),
      );

      final controller = LoginScreenController(userService: FakeUserService());
      controller.emailController.text = 'sensitive.login@synthetic-domain.com';
      controller.passwordController.text = ''; // Triggers early return after initial diagnostic

      final element = tester.element(find.byType(ElevatedButton));
      await controller.login(element);

      // Verify email was not logged
      final emailLogs = capturedLogs.where((l) => l.contains('sensitive.login@synthetic-domain.com'));
      expect(emailLogs, isEmpty, reason: 'LoginScreenController should never log user email addresses');

      // Verify safe operational diagnostic was logged
      expect(capturedLogs.any((l) => l.contains('[Login] Attempting login authentication request')), isTrue);

      debugPrint = originalDebugPrint;
    });

    test('7. ForgotPasswordScreenController.requestOtp does NOT log plain email address', () async {
      const targetEmail = 'target.reset@synthetic-domain.com';
      final controller = ForgotPasswordScreenController();
      controller.emailController.text = targetEmail;

      await controller.requestOtp();

      // Assert email is not leaked in debugPrint
      final emailLeaks = capturedLogs.where((l) => l.contains(targetEmail));
      expect(emailLeaks, isEmpty, reason: 'ForgotPasswordScreenController should never log email address');

      // Assert safe status is logged
      expect(capturedLogs.any((l) => l.contains('Forgot: Password reset OTP request succeeded')), isTrue);
    });

    test('8. BorrowBookController.fetchStudentDetails does NOT log StudentModel or register number', () async {
      final fakeStudent = StudentModel(
        id: 'std-fake-999',
        firstName: 'SecretAlice',
        lastName: 'SecretBob',
        address: '99 Secret Highway',
        phone: '+1-555-8888',
        attendance: 95,
        email: 'secret.borrower@synthetic-domain.com',
        standard: '10th',
        registerNumber: '10809999',
        userId: 'auth-fake-999',
      );

      final fakeStudentService = FakeStudentService(returnStudent: fakeStudent);
      final fakeBorrowBookService = FakeBorrowBookService();
      final controller = BorrowBookController(fakeStudentService, fakeBorrowBookService);

      await controller.fetchStudentDetails('10809999');

      // Assert no student PII or register number leaks
      final piiLeaks = capturedLogs.where((l) =>
          l.contains('SecretAlice') ||
          l.contains('SecretBob') ||
          l.contains('99 Secret Highway') ||
          l.contains('+1-555-8888') ||
          l.contains('secret.borrower@synthetic-domain.com') ||
          l.contains('10809999'));
      expect(piiLeaks, isEmpty, reason: 'BorrowBookController should never log student PII or register number');

      // Assert safe diagnostic message
      expect(capturedLogs.any((l) => l.contains('✅ Found student record')), isTrue);
    });

    test('9. StudentFormPageController.loadStudentData does NOT log StudentModel PII', () {
      final controller = StudentFormPageController();
      final student = StudentModel(
        id: 'std-form-999',
        firstName: 'FormFirstName',
        lastName: 'FormLastName',
        address: '404 Encrypted Road',
        phone: '+1-555-3333',
        attendance: 98,
        email: 'form.student@synthetic-domain.com',
        standard: '11th',
        registerNumber: '10807777',
        userId: 'auth-form-999',
      );

      controller.loadStudentData(student);

      // Assert no student PII or register number leaks
      final piiLeaks = capturedLogs.where((l) =>
          l.contains('FormFirstName') ||
          l.contains('FormLastName') ||
          l.contains('404 Encrypted Road') ||
          l.contains('+1-555-3333') ||
          l.contains('form.student@synthetic-domain.com') ||
          l.contains('10807777'));
      expect(piiLeaks, isEmpty, reason: 'StudentFormPageController should never log student PII when loading data');

      // Assert safe diagnostic message
      expect(capturedLogs.any((l) => l.contains('Loaded Student Data successfully.')), isTrue);
    });

    testWidgets('10. StudentFormPageController.updateStudent does NOT log payload or PII', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {},
                child: const Text('Update'),
              ),
            ),
          ),
        ),
      );

      final controller = StudentFormPageController();
      controller.loadStudentData(StudentModel(
        id: 'std-update-001',
        firstName: 'UpdatedAlice',
        lastName: 'UpdatedSmith',
        address: '100 Update Boulevard',
        phone: '+1-555-9999',
        attendance: 99,
        email: 'updated.alice@synthetic-domain.com',
        standard: '12th',
        registerNumber: '10805555',
        userId: 'auth-update-001',
      ));

      final element = tester.element(find.byType(ElevatedButton));
      await controller.updateStudent(element);

      // Verify no PII or raw map is logged
      final piiLeaks = capturedLogs.where((l) =>
          l.contains('UpdatedAlice') ||
          l.contains('UpdatedSmith') ||
          l.contains('100 Update Boulevard') ||
          l.contains('+1-555-9999') ||
          l.contains('updated.alice@synthetic-domain.com') ||
          l.contains('10805555') ||
          l.contains('Updating student with data:'));
      expect(piiLeaks, isEmpty, reason: 'StudentFormPageController.updateStudent must never log student PII or payload');

      // Verify safe diagnostic was logged
      expect(capturedLogs.any((l) => l.contains('Updating student record with validated fields')), isTrue);

      debugPrint = originalDebugPrint;
    });

    test('11. Service exception logging does NOT leak sensitive identifiers or query emails on failure', () async {
      final failingClient = MockClient((request) async {
        throw http.ClientException(
          'Connection timed out',
          request.url,
        );
      });

      final client = SupabaseClient(supabaseUrl, anonKey, httpClient: failingClient);
      final userService = UserService(client: client);
      final staffService = StaffService(userService: userService, client: client);
      final studentService = StudentService(userService: userService, client: client);

      const secretEmail = 'secret.error.leak@synthetic-domain.com';
      const secretRegNo = '99998888';

      await staffService.fetchStaffByEmail(secretEmail);
      await studentService.fetchStudentByRegister(secretRegNo);
      await userService.fetchUserByEmail(secretEmail);

      final leakedSensitiveData = capturedLogs.where((l) =>
          l.contains(secretEmail) || l.contains(secretRegNo));
      expect(leakedSensitiveData, isEmpty,
          reason: 'Service exception handlers must never leak query parameters or sensitive identifiers on network error');
    });
  });
}
