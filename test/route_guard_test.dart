import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:student_management/core/routing/app_router.dart';
import 'package:student_management/features/staff/domain/repositories/i_staff_repository.dart';
import 'package:student_management/features/staff/presentation/providers/staff_providers.dart';
import 'package:student_management/features/students/domain/repositories/i_student_repository.dart';
import 'package:student_management/features/students/presentation/providers/student_providers.dart';
import 'package:student_management/shared/models/staff.dart';
import 'package:student_management/shared/models/student.dart';
import 'package:student_management/controller/splash_screen_controller.dart';
import 'package:student_management/view/screens/student_tab_screen/student_tab_screen.dart';
import 'package:student_management/view/screens/student_profile_screen/student_profile_screen.dart';
import 'package:student_management/view/screens/student_library_screen/student_library_screen.dart';
import 'package:student_management/view/screens/student_fees_screen/student_fees_screen.dart';
import 'package:student_management/features/students/presentation/screens/student_list_screen.dart';

class MockStudentRepository implements IStudentRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<List<Student>> getStudents({
    String? standard,
    String? searchQuery,
    String? sortOrder,
  }) async => [];

  @override
  Future<Student> getStudentById(String studentId) async => Student(
    id: 'profile-1',
    userId: 'student-auth-1',
    registerNumber: 'REG-001',
    standard: '10th',
    name: 'Test Student',
  );
}

class MockStaffRepository implements IStaffRepository {
  @override
  Future<List<Staff>> getStaffList({
    String? designationFilter,
    String? searchQuery,
    String? sortOrder = 'A-Z',
  }) async => [];

  @override
  Future<Staff?> getStaffById(String id) async => null;

  @override
  Future<Staff?> getStaffByEmail(String email) async => null;

  @override
  Future<void> createStaff({
    required Staff staff,
    required String password,
    dynamic avatarFile,
  }) async {}

  @override
  Future<void> updateStaff({required Staff staff, dynamic avatarFile}) async {}

  @override
  Future<void> deleteStaff({
    required String staffId,
    required String authId,
    String? email,
  }) async {}

  @override
  Future<Map<String, int>> bulkDeleteStaff(List<Staff> staffList) async => {
    'success': 0,
    'fail': 0,
  };
}

Future<SupabaseClient> createMockSupabaseClient({
  required String userId,
  required String email,
  Map<String, dynamic>? appMetadata,
  Map<String, dynamic>? userMetadata,
  String? dbRole,
  bool isExpired = false,
  bool isAuthenticated = true,
  bool dbThrowsError = false,
}) async {
  const supabaseUrl = 'https://mock-school-db.supabase.co';
  const anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.dummy-anon-key';

  final mockHttpClient = MockClient((request) async {
    final uri = request.url;

    if (uri.path.contains('/rest/v1/users')) {
      if (dbThrowsError) {
        return http.Response(
          jsonEncode({'message': 'Internal Server Error', 'code': '500'}),
          500,
          request: request,
          headers: {'content-type': 'application/json'},
        );
      }
      if (dbRole != null) {
        final acceptHeader = request.headers['accept'] ?? '';
        if (acceptHeader.contains('application/vnd.pgrst.object+json')) {
          return http.Response(
            jsonEncode({'role': dbRole}),
            200,
            request: request,
            headers: {'content-type': 'application/vnd.pgrst.object+json'},
          );
        }
        return http.Response(
          jsonEncode([
            {'role': dbRole},
          ]),
          200,
          request: request,
          headers: {'content-type': 'application/json'},
        );
      } else {
        return http.Response(
          jsonEncode([]),
          200,
          request: request,
          headers: {'content-type': 'application/json'},
        );
      }
    }

    return http.Response('Not Found: ${uri.path}', 404, request: request);
  });

  final client = SupabaseClient(
    supabaseUrl,
    anonKey,
    httpClient: mockHttpClient,
    authOptions: const AuthClientOptions(autoRefreshToken: false),
  );

  if (isAuthenticated) {
    final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final expSeconds = isExpired ? nowSeconds - 100 : nowSeconds + 3600;
    final header = base64Url.encode(
      utf8.encode(jsonEncode({'alg': 'HS256', 'typ': 'JWT'})),
    );
    final payload = base64Url.encode(
      utf8.encode(jsonEncode({'exp': expSeconds, 'sub': userId})),
    );
    final jwtToken = '$header.$payload.signature';

    final sessionJson = jsonEncode({
      'access_token': jwtToken,
      'token_type': 'bearer',
      'expires_in': isExpired ? -100 : 3600,
      'expires_at': expSeconds,
      'refresh_token': 'mock-refresh-token-xyz',
      'user': {
        'id': userId,
        'aud': 'authenticated',
        'role': 'authenticated',
        'email': email,
        'app_metadata': appMetadata ?? {},
        'user_metadata': userMetadata ?? {},
        'created_at': '2026-01-01T00:00:00Z',
      },
    });
    await client.auth.setInitialSession(sessionJson);
  }

  return client;
}

class FakeGoRouterState implements GoRouterState {
  @override
  final Uri uri;
  @override
  final String matchedLocation;
  @override
  final String fullPath;
  @override
  final Object? extra;

  FakeGoRouterState(String path, {this.extra})
    : uri = Uri.parse(path),
      matchedLocation = path,
      fullPath = path;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

GoRouterState createTestRouterState(String path, {Object? extra}) =>
    FakeGoRouterState(path, extra: extra);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Staff Management Route Guard Unit Tests', () {
    test(
      '1. Unauthenticated user: null session redirects to /loginScreen',
      () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final client = await createMockSupabaseClient(
          userId: '',
          email: '',
          isAuthenticated: false,
        );

        final fakeState = createTestRouterState('/staffManagement');

        final redirect = await staffManagementGuard(
          null as dynamic,
          fakeState,
          clientOverride: client,
          prefsOverride: prefs,
        );

        expect(redirect, equals('/loginScreen'));
      },
    );

    test('2. Expired session redirects to /loginScreen', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final client = await createMockSupabaseClient(
        userId: 'admin-1',
        email: 'admin@school.com',
        appMetadata: {'role': 'admin'},
        isExpired: true,
      );

      final fakeState = createTestRouterState('/staffManagement');

      final redirect = await staffManagementGuard(
        null as dynamic,
        fakeState,
        clientOverride: client,
        prefsOverride: prefs,
      );

      expect(redirect, equals('/loginScreen'));
    });

    test(
      '3. Missing profile defense: session with app_metadata claiming "admin" but missing database profile is DENIED (redirects to /loginScreen)',
      () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final client = await createMockSupabaseClient(
          userId: 'admin-101',
          email: 'admin@school.com',
          appMetadata: {'role': 'admin'},
          // No dbRole: simulates missing or deleted public.users row
        );

        final fakeState = createTestRouterState('/staffManagement');

        final redirect = await staffManagementGuard(
          null as dynamic,
          fakeState,
          clientOverride: client,
          prefsOverride: prefs,
        );

        // Under hardened fail-closed policy: missing database row must fail closed
        expect(redirect, equals('/loginScreen'));
      },
    );

    test(
      '4. Admin user (Database role lookup): access is granted (redirect returns null)',
      () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final client = await createMockSupabaseClient(
          userId: 'admin-102',
          email: 'admin2@school.com',
          dbRole: 'admin',
        );

        final fakeState = createTestRouterState('/staffForm');

        final redirect = await staffManagementGuard(
          null as dynamic,
          fakeState,
          clientOverride: client,
          prefsOverride: prefs,
        );

        expect(redirect, isNull);
        expect(prefs.getString('userRole'), equals('admin'));
      },
    );

    test('5. Staff user denial: redirects to /staffDashboard', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final client = await createMockSupabaseClient(
        userId: 'staff-201',
        email: 'teacher@school.com',
        appMetadata: {'role': 'staff'},
        dbRole: 'staff',
      );

      final fakeState = createTestRouterState('/staffManagement');

      final redirect = await staffManagementGuard(
        null as dynamic,
        fakeState,
        clientOverride: client,
        prefsOverride: prefs,
      );

      expect(redirect, equals('/staffDashboard'));
    });

    test(
      '6. Student user denial: redirects to /studentDashboard with studentId query parameter',
      () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final client = await createMockSupabaseClient(
          userId: 'student-301',
          email: 'learner@school.com',
          appMetadata: {'role': 'student'},
          dbRole: 'student',
        );

        final fakeState = createTestRouterState('/staffList');

        final redirect = await staffManagementGuard(
          null as dynamic,
          fakeState,
          clientOverride: client,
          prefsOverride: prefs,
        );

        expect(redirect, equals('/studentDashboard?studentId=student-301'));
      },
    );

    test('7. Missing role state: redirects safely to /loginScreen', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final client = await createMockSupabaseClient(
        userId: 'norole-401',
        email: 'norole@school.com',
      );

      final fakeState = createTestRouterState('/staffManagement');

      final redirect = await staffManagementGuard(
        null as dynamic,
        fakeState,
        clientOverride: client,
        prefsOverride: prefs,
      );

      expect(redirect, equals('/loginScreen'));
    });

    test(
      '8. Invalid role state (e.g. "guest"): redirects safely to /loginScreen',
      () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final client = await createMockSupabaseClient(
          userId: 'guest-501',
          email: 'guest@school.com',
          appMetadata: {'role': 'guest'},
        );

        final fakeState = createTestRouterState('/staffManagement');

        final redirect = await staffManagementGuard(
          null as dynamic,
          fakeState,
          clientOverride: client,
          prefsOverride: prefs,
        );

        expect(redirect, equals('/loginScreen'));
      },
    );

    test(
      '9. Tampered SharedPreferences defense: staff session with tampered admin in prefs is DENIED',
      () async {
        // Attacker manually sets 'userRole' = 'admin' in SharedPreferences, but database reports 'staff'
        SharedPreferences.setMockInitialValues({
          'userRole': 'admin',
          'user_id': 'staff-601',
        });
        final prefs = await SharedPreferences.getInstance();

        final client = await createMockSupabaseClient(
          userId: 'staff-601',
          email: 'staff601@school.com',
          dbRole: 'staff', // Verified database role
        );

        final fakeState = createTestRouterState('/staffManagement');

        final redirect = await staffManagementGuard(
          null as dynamic,
          fakeState,
          clientOverride: client,
          prefsOverride: prefs,
        );

        // Must be denied and redirected to /staffDashboard
        expect(redirect, equals('/staffDashboard'));
        // And prefs must be corrected to 'staff'
        expect(prefs.getString('userRole'), equals('staff'));
      },
    );

    test(
      '10. Stale SharedPreferences defense: cached user_id does not match session user ID',
      () async {
        // SharedPreferences has an admin role cached from an old session
        SharedPreferences.setMockInitialValues({
          'userRole': 'admin',
          'user_id': 'old-admin-uid',
        });
        final prefs = await SharedPreferences.getInstance();

        // Active session belongs to a different user with no metadata or DB role
        final client = await createMockSupabaseClient(
          userId: 'new-unassigned-uid',
          email: 'newuser@school.com',
        );

        final fakeState = createTestRouterState('/staffManagement');

        final redirect = await staffManagementGuard(
          null as dynamic,
          fakeState,
          clientOverride: client,
          prefsOverride: prefs,
        );

        // Must NOT trust the mismatched SharedPreferences and redirect to login
        expect(redirect, equals('/loginScreen'));
      },
    );

    test(
      '11. Conflicting role defense: user_metadata claims "admin", but database reports "staff" -> DENIED',
      () async {
        // Attacker attempts privilege escalation via user-editable user_metadata
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();

        final client = await createMockSupabaseClient(
          userId: 'staff-701',
          email: 'staff701@school.com',
          userMetadata: {'role': 'admin'}, // Tampered claim
          dbRole: 'staff', // Authoritative DB role
        );

        final fakeState = createTestRouterState('/staffManagement');

        final redirect = await staffManagementGuard(
          null as dynamic,
          fakeState,
          clientOverride: client,
          prefsOverride: prefs,
        );

        // Authoritative non-admin DB role MUST take precedence
        expect(redirect, equals('/staffDashboard'));
        expect(prefs.getString('userRole'), equals('staff'));
      },
    );

    test(
      '12. Conflicting role defense: user_metadata claims "admin", but database reports "student" -> DENIED',
      () async {
        // Student attempts privilege escalation via user_metadata
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();

        final client = await createMockSupabaseClient(
          userId: 'student-702',
          email: 'student702@school.com',
          userMetadata: {'role': 'admin'}, // Tampered claim
          dbRole: 'student', // Authoritative DB role
        );

        final fakeState = createTestRouterState('/staffList');

        final redirect = await staffManagementGuard(
          null as dynamic,
          fakeState,
          clientOverride: client,
          prefsOverride: prefs,
        );

        // Authoritative student DB role takes precedence, with authenticated studentId in URL
        expect(redirect, equals('/studentDashboard?studentId=student-702'));
        expect(prefs.getString('userRole'), equals('student'));
      },
    );

    test(
      '13. Untrusted user_metadata defense: user_metadata claims "admin" with missing DB record -> fails closed to /loginScreen',
      () async {
        // User with no authoritative role attempts to gain admin via user_metadata
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();

        final client = await createMockSupabaseClient(
          userId: 'attacker-703',
          email: 'attacker@school.com',
          userMetadata: {'role': 'admin'},
          // No appMetadata, no dbRole (db returns empty)
        );

        final fakeState = createTestRouterState('/staffManagement');

        final redirect = await staffManagementGuard(
          null as dynamic,
          fakeState,
          clientOverride: client,
          prefsOverride: prefs,
        );

        // Must fail closed; user_metadata alone cannot establish admin access
        expect(redirect, equals('/loginScreen'));
      },
    );

    test(
      '14. Untrusted SharedPreferences defense: prefs claims "admin" with missing DB record -> fails closed to /loginScreen',
      () async {
        // Tampered SharedPreferences for current user, but no authoritative DB record
        SharedPreferences.setMockInitialValues({
          'userRole': 'admin',
          'user_id': 'user-704',
        });
        final prefs = await SharedPreferences.getInstance();

        final client = await createMockSupabaseClient(
          userId: 'user-704',
          email: 'user704@school.com',
          // No appMetadata, no dbRole
        );

        final fakeState = createTestRouterState('/staffForm');

        final redirect = await staffManagementGuard(
          null as dynamic,
          fakeState,
          clientOverride: client,
          prefsOverride: prefs,
        );

        // Must fail closed; SharedPreferences alone cannot establish admin access
        expect(redirect, equals('/loginScreen'));
      },
    );

    test(
      '15. Database query failure defense: network/PostgREST error fails closed to /loginScreen',
      () async {
        // Database query throws an exception / fails
        SharedPreferences.setMockInitialValues({
          'userRole': 'admin',
          'user_id': 'user-705',
        });
        final prefs = await SharedPreferences.getInstance();

        final client = await createMockSupabaseClient(
          userId: 'user-705',
          email: 'user705@school.com',
          dbThrowsError: true, // Simulates DB failure
        );

        final fakeState = createTestRouterState('/staffManagement');

        final redirect = await staffManagementGuard(
          null as dynamic,
          fakeState,
          clientOverride: client,
          prefsOverride: prefs,
        );

        // Must fail closed safely to /loginScreen, ignoring untrusted prefs claim
        expect(redirect, equals('/loginScreen'));
      },
    );

    test(
      '16. Student redirect identity validation: studentId strictly comes from session.user.id',
      () async {
        // SharedPreferences has a different user_id stored from another user
        SharedPreferences.setMockInitialValues({
          'user_id': 'different-student-999',
        });
        final prefs = await SharedPreferences.getInstance();

        final client = await createMockSupabaseClient(
          userId: 'authenticated-student-123',
          email: 'auth_student@school.com',
          dbRole: 'student',
        );

        final fakeState = createTestRouterState('/staffManagement');

        final redirect = await staffManagementGuard(
          null as dynamic,
          fakeState,
          clientOverride: client,
          prefsOverride: prefs,
        );

        // Redirect must strictly use the authenticated session user ID
        expect(
          redirect,
          equals('/studentDashboard?studentId=authenticated-student-123'),
        );
      },
    );
  });

  group('Staff Management Route Guard GoRouter Widget Integration Tests', () {
    testWidgets(
      '17. Admin accessing /staffManagement successfully navigates to Staff Management screen',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final adminClient = await createMockSupabaseClient(
          userId: 'admin-777',
          email: 'admin@school.com',
          appMetadata: {'role': 'admin'},
          dbRole: 'admin',
        );

        final router = createAppRouter(
          initialLocation: '/staffManagement',
          clientOverride: adminClient,
          prefsOverride: prefs,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              staffRepositoryProvider.overrideWithValue(MockStaffRepository()),
            ],
            child: MaterialApp.router(routerConfig: router),
          ),
        );

        await tester.pumpAndSettle();

        // Admin accesses Staff Management screen directly
        expect(find.text('Staff Management'), findsOneWidget);
      },
    );

    testWidgets(
      '18. Staff attempting to access /staffManagement is redirected to /staffDashboard',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          'userData': jsonEncode({'first_name': 'Sarah'}),
        });
        final prefs = await SharedPreferences.getInstance();
        final staffClient = await createMockSupabaseClient(
          userId: 'staff-888',
          email: 'sarah@school.com',
          appMetadata: {'role': 'staff'},
          dbRole: 'staff',
        );

        final router = createAppRouter(
          initialLocation: '/staffManagement',
          clientOverride: staffClient,
          prefsOverride: prefs,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              staffRepositoryProvider.overrideWithValue(MockStaffRepository()),
            ],
            child: MaterialApp.router(routerConfig: router),
          ),
        );

        await tester.pumpAndSettle();

        // Guard intercepts and redirects to Staff Dashboard
        expect(find.text('Staff Dashboard'), findsOneWidget);
        expect(find.text('Staff Management'), findsNothing);
      },
    );

    testWidgets(
      '19. Unauthenticated user attempting to access /staffList is redirected to /loginScreen',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final unauthClient = await createMockSupabaseClient(
          userId: '',
          email: '',
          isAuthenticated: false,
        );

        final router = createAppRouter(
          initialLocation: '/staffList',
          clientOverride: unauthClient,
          prefsOverride: prefs,
        );

        await tester.pumpWidget(
          ProviderScope(child: MaterialApp.router(routerConfig: router)),
        );

        await tester.pumpAndSettle();

        // Guard intercepts and redirects to Login Screen
        expect(find.text('Sign In'), findsOneWidget);
        expect(find.text('Staff Management'), findsNothing);
      },
    );

    testWidgets(
      '20. Staff attempting to access /staffForm is redirected to /staffDashboard',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          'userData': jsonEncode({'first_name': 'John'}),
        });
        final prefs = await SharedPreferences.getInstance();
        final staffClient = await createMockSupabaseClient(
          userId: 'staff-999',
          email: 'john@school.com',
          appMetadata: {'role': 'staff'},
          dbRole: 'staff',
        );

        final router = createAppRouter(
          initialLocation: '/staffForm',
          clientOverride: staffClient,
          prefsOverride: prefs,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              staffRepositoryProvider.overrideWithValue(MockStaffRepository()),
            ],
            child: MaterialApp.router(routerConfig: router),
          ),
        );

        await tester.pumpAndSettle();

        // Guard intercepts and redirects to Staff Dashboard
        expect(find.text('Staff Dashboard'), findsOneWidget);
        expect(find.text('Add Staff'), findsNothing);
      },
    );
  });

  group('Admin Guard Unit & Stale Role Tests', () {
    test('21. adminGuard: unauthenticated user redirects to /loginScreen', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final client = await createMockSupabaseClient(
        userId: '',
        email: '',
        isAuthenticated: false,
      );

      final redirect = await adminGuard(
        null,
        createTestRouterState('/adminDashboard'),
        clientOverride: client,
        prefsOverride: prefs,
      );

      expect(redirect, equals('/loginScreen'));
    });

    test('22. adminGuard: admin user access granted (null)', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final client = await createMockSupabaseClient(
        userId: 'admin-adm',
        email: 'admin@school.com',
        dbRole: 'admin',
      );

      final redirect = await adminGuard(
        null,
        createTestRouterState('/adminDashboard'),
        clientOverride: client,
        prefsOverride: prefs,
      );

      expect(redirect, isNull);
    });

    test('23. adminGuard: staff user rejected and redirected to /staffDashboard', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final client = await createMockSupabaseClient(
        userId: 'staff-stf',
        email: 'staff@school.com',
        dbRole: 'staff',
      );

      final redirect = await adminGuard(
        null,
        createTestRouterState('/adminDashboard'),
        clientOverride: client,
        prefsOverride: prefs,
      );

      expect(redirect, equals('/staffDashboard'));
    });

    test('24. adminGuard: student user rejected and redirected to /studentDashboard', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final client = await createMockSupabaseClient(
        userId: 'student-std',
        email: 'student@school.com',
        dbRole: 'student',
      );

      final redirect = await adminGuard(
        null,
        createTestRouterState('/adminDashboard'),
        clientOverride: client,
        prefsOverride: prefs,
      );

      expect(redirect, equals('/studentDashboard?studentId=student-std'));
    });

    test('25. adminGuard: unknown or missing role fails closed to /loginScreen', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final client = await createMockSupabaseClient(
        userId: 'unknown-unk',
        email: 'unknown@school.com',
        dbRole: 'alien',
      );

      final redirect = await adminGuard(
        null,
        createTestRouterState('/adminDashboard'),
        clientOverride: client,
        prefsOverride: prefs,
      );

      expect(redirect, equals('/loginScreen'));
    });

    test('26. adminGuard: demoted admin with stale JWT app_metadata is rejected based on DB role', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      // JWT token still claims 'admin', but DB record was demoted to 'staff'
      final client = await createMockSupabaseClient(
        userId: 'demoted-user-1',
        email: 'demoted@school.com',
        appMetadata: {'role': 'admin'},
        dbRole: 'staff',
      );

      final redirect = await adminGuard(
        null,
        createTestRouterState('/adminDashboard'),
        clientOverride: client,
        prefsOverride: prefs,
      );

      // Must be rejected from admin dashboard and redirected to staff dashboard
      expect(redirect, equals('/staffDashboard'));
      expect(prefs.getString('userRole'), equals('staff'));
    });

    test('26a. adminGuard: deleted admin profile (JWT claims admin, DB profile missing) fails closed to /loginScreen', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      // Admin account was deleted from public.users; JWT still contains admin claim
      final client = await createMockSupabaseClient(
        userId: 'deleted-admin-99',
        email: 'deleted_admin@school.com',
        appMetadata: {'role': 'admin'},
        // No dbRole: simulates deleted profile in public.users
      );

      final redirect = await adminGuard(
        null,
        createTestRouterState('/adminDashboard'),
        clientOverride: client,
        prefsOverride: prefs,
      );

      // Must fail closed to /loginScreen and NOT grant admin from stale JWT claim
      expect(redirect, equals('/loginScreen'));
    });

    test('26b. adminGuard: empty database role string fails closed to /loginScreen', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final client = await createMockSupabaseClient(
        userId: 'empty-role-user',
        email: 'empty@school.com',
        dbRole: '', // Empty role in public.users
      );

      final redirect = await adminGuard(
        null,
        createTestRouterState('/adminDashboard'),
        clientOverride: client,
        prefsOverride: prefs,
      );

      expect(redirect, equals('/loginScreen'));
    });

    test('26c. adminGuard: database lookup error fails closed to /loginScreen', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final client = await createMockSupabaseClient(
        userId: 'db-err-user',
        email: 'dberr@school.com',
        appMetadata: {'role': 'admin'},
        dbThrowsError: true, // Simulates database outage / timeout
      );

      final redirect = await adminGuard(
        null,
        createTestRouterState('/adminDashboard'),
        clientOverride: client,
        prefsOverride: prefs,
      );

      // Must fail closed safely to /loginScreen without granting access via JWT
      expect(redirect, equals('/loginScreen'));
    });
  });

  group('Staff Guard Unit Tests', () {
    test('27. staffGuard: unauthenticated user redirects to /loginScreen', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final client = await createMockSupabaseClient(
        userId: '',
        email: '',
        isAuthenticated: false,
      );

      final redirect = await staffGuard(
        null,
        createTestRouterState('/staffDashboard'),
        clientOverride: client,
        prefsOverride: prefs,
      );

      expect(redirect, equals('/loginScreen'));
    });

    test('28. staffGuard: staff user access granted (null)', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final client = await createMockSupabaseClient(
        userId: 'staff-ok',
        email: 'staffok@school.com',
        dbRole: 'staff',
      );

      final redirect = await staffGuard(
        null,
        createTestRouterState('/staffDashboard'),
        clientOverride: client,
        prefsOverride: prefs,
      );

      expect(redirect, isNull);
    });

    test('29. staffGuard: student rejected to /studentDashboard', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final client = await createMockSupabaseClient(
        userId: 'student-rej',
        email: 'studentrej@school.com',
        dbRole: 'student',
      );

      final redirect = await staffGuard(
        null,
        createTestRouterState('/staffDashboard'),
        clientOverride: client,
        prefsOverride: prefs,
      );

      expect(redirect, equals('/studentDashboard?studentId=student-rej'));
    });

    test('30. staffGuard: admin rejected to /adminDashboard following staff-only policy', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final client = await createMockSupabaseClient(
        userId: 'admin-rej',
        email: 'adminrej@school.com',
        dbRole: 'admin',
      );

      final redirect = await staffGuard(
        null,
        createTestRouterState('/staffDashboard'),
        clientOverride: client,
        prefsOverride: prefs,
      );

      expect(redirect, equals('/adminDashboard'));
    });
  });

  group('Shared Management Guard Unit Tests', () {
    test('31. staffOrAdminGuard: unauthenticated user redirects to /loginScreen', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final client = await createMockSupabaseClient(
        userId: '',
        email: '',
        isAuthenticated: false,
      );

      final redirect = await staffOrAdminGuard(
        null,
        createTestRouterState('/studentManagement'),
        clientOverride: client,
        prefsOverride: prefs,
      );

      expect(redirect, equals('/loginScreen'));
    });

    test('32. staffOrAdminGuard: admin user access granted (null)', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final client = await createMockSupabaseClient(
        userId: 'admin-ok',
        email: 'adminok@school.com',
        dbRole: 'admin',
      );

      final redirect = await staffOrAdminGuard(
        null,
        createTestRouterState('/studentManagement'),
        clientOverride: client,
        prefsOverride: prefs,
      );

      expect(redirect, isNull);
    });

    test('33. staffOrAdminGuard: staff user access granted (null)', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final client = await createMockSupabaseClient(
        userId: 'staff-ok-2',
        email: 'staffok2@school.com',
        dbRole: 'staff',
      );

      final redirect = await staffOrAdminGuard(
        null,
        createTestRouterState('/libraryManagement'),
        clientOverride: client,
        prefsOverride: prefs,
      );

      expect(redirect, isNull);
    });

    test('34. staffOrAdminGuard: student rejected and redirected to /studentDashboard', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final client = await createMockSupabaseClient(
        userId: 'student-no-mgmt',
        email: 'studentnomgmt@school.com',
        dbRole: 'student',
      );

      final redirect = await staffOrAdminGuard(
        null,
        createTestRouterState('/feesDashboard'),
        clientOverride: client,
        prefsOverride: prefs,
      );

      expect(redirect, equals('/studentDashboard?studentId=student-no-mgmt'));
    });
  });

  group('Student Portal Guard & IDOR Defense Unit Tests', () {
    test('35. studentPortalGuard: unauthenticated user redirects to /loginScreen', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final client = await createMockSupabaseClient(
        userId: '',
        email: '',
        isAuthenticated: false,
      );

      final redirect = await studentPortalGuard(
        null,
        createTestRouterState('/studentDashboard'),
        clientOverride: client,
        prefsOverride: prefs,
      );

      expect(redirect, equals('/loginScreen'));
    });

    test('36. studentPortalGuard: student access granted (null)', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final client = await createMockSupabaseClient(
        userId: 'student-ok',
        email: 'studentok@school.com',
        dbRole: 'student',
      );

      final redirect = await studentPortalGuard(
        null,
        createTestRouterState('/studentDashboard'),
        clientOverride: client,
        prefsOverride: prefs,
      );

      expect(redirect, isNull);
    });

    test('37. studentPortalGuard: admin redirected to /adminDashboard', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final client = await createMockSupabaseClient(
        userId: 'admin-student-redir',
        email: 'adminstd@school.com',
        dbRole: 'admin',
      );

      final redirect = await studentPortalGuard(
        null,
        createTestRouterState('/studentDashboard'),
        clientOverride: client,
        prefsOverride: prefs,
      );

      expect(redirect, equals('/adminDashboard'));
    });

    test('38. studentPortalGuard: staff redirected to /staffDashboard', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final client = await createMockSupabaseClient(
        userId: 'staff-student-redir',
        email: 'staffstd@school.com',
        dbRole: 'staff',
      );

      final redirect = await studentPortalGuard(
        null,
        createTestRouterState('/studentDashboard'),
        clientOverride: client,
        prefsOverride: prefs,
      );

      expect(redirect, equals('/staffDashboard'));
    });

    testWidgets('39. Student portal IDOR immunity: query parameter ?studentId=victim-uuid is ignored in favor of authenticated session ID', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final studentClient = await createMockSupabaseClient(
        userId: 'authenticated-student-uuid',
        email: 'student@school.com',
        dbRole: 'student',
      );

      // Caller attempts IDOR by providing a different student's UUID in the query parameter
      final router = createAppRouter(
        initialLocation: '/studentDashboard?studentId=victim-other-student-uuid',
        clientOverride: studentClient,
        prefsOverride: prefs,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            studentRepositoryProvider.overrideWithValue(MockStudentRepository()),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      await tester.pumpAndSettle();

      // Find StudentTabsShell widget mounted in the tree
      final shellFinder = find.byType(StudentTabsShell);
      expect(shellFinder, findsOneWidget);

      final shell = tester.widget<StudentTabsShell>(shellFinder);
      // The shell must strictly receive the authenticated session user ID, NOT the victim's UUID
      expect(shell.id, equals('authenticated-student-uuid'));
      expect(shell.authUserId, equals('authenticated-student-uuid'));
    });

    testWidgets('40. StudentTabsShell ID separation: passes authUserId to Library and studentProfileId to Profile and Fees', (tester) async {
      const authId = 'auth-uid-001';
      const profileId = 'profile-pk-999';

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            studentRepositoryProvider.overrideWithValue(MockStudentRepository()),
          ],
          child: const MaterialApp(
            home: StudentTabsShell(
              id: authId,
              authUserId: authId,
              studentProfileId: profileId,
              filterByUserId: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify StudentProfileScreen receives studentProfileId
      final profileFinder = find.byType(StudentProfileScreen);
      expect(profileFinder, findsOneWidget);
      final profileScreen = tester.widget<StudentProfileScreen>(profileFinder);
      expect(profileScreen.studentId, equals(profileId));

      // Switch to Library tab
      await tester.tap(find.text('Library'));
      await tester.pumpAndSettle();

      // Verify StudentLibraryScreen receives authUserId with filterByUserId = true
      final libraryFinder = find.byType(StudentLibraryScreen);
      expect(libraryFinder, findsOneWidget);
      final libraryScreen = tester.widget<StudentLibraryScreen>(libraryFinder);
      expect(libraryScreen.id, equals(authId));
      expect(libraryScreen.filterByUserId, isTrue);

      // Switch to Fees tab
      await tester.tap(find.text('Fees'));
      await tester.pumpAndSettle();

      // Verify StudentFeesScreen receives studentProfileId
      final feesFinder = find.byType(StudentFeesScreen);
      expect(feesFinder, findsOneWidget);
      final feesScreen = tester.widget<StudentFeesScreen>(feesFinder);
      expect(feesScreen.studentId, equals(profileId));
    });
  });

  group('Splash Navigation & Session Safety Tests', () {
    testWidgets('41. Missing session with cached admin in prefs clears auth prefs and navigates to /loginScreen', (tester) async {
      SharedPreferences.setMockInitialValues({
        'userRole': 'admin',
        'user_id': 'old-admin-uid',
        'theme_mode': 'dark', // Unrelated preference
      });
      final prefs = await SharedPreferences.getInstance();

      final client = await createMockSupabaseClient(
        userId: '',
        email: '',
        isAuthenticated: false,
      );

      final controller = SplashScreenController(
        clientOverride: client,
        prefsOverride: prefs,
      );

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => Builder(
              builder: (ctx) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  controller.checkSession(ctx);
                });
                return const Scaffold(body: Text('Splash Screen'));
              },
            ),
          ),
          GoRoute(
            path: '/loginScreen',
            builder: (context, state) => const Scaffold(body: Text('Login Screen')),
          ),
          GoRoute(
            path: '/adminDashboard',
            builder: (context, state) => const Scaffold(body: Text('Admin Dashboard')),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      // Fast forward past the splash animation delay (2 seconds)
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      expect(find.text('Login Screen'), findsOneWidget);
      expect(find.text('Admin Dashboard'), findsNothing);
      // Auth prefs cleared
      expect(prefs.getString('userRole'), isNull);
      expect(prefs.getString('user_id'), isNull);
      // Unrelated preference preserved
      expect(prefs.getString('theme_mode'), equals('dark'));
    });

    testWidgets('42. Expired session with cached admin in prefs clears auth prefs and navigates to /loginScreen', (tester) async {
      SharedPreferences.setMockInitialValues({
        'userRole': 'admin',
        'user_id': 'expired-admin-uid',
      });
      final prefs = await SharedPreferences.getInstance();

      final client = await createMockSupabaseClient(
        userId: 'expired-admin-uid',
        email: 'admin@school.com',
        dbRole: 'admin',
        isExpired: true,
      );

      final controller = SplashScreenController(
        clientOverride: client,
        prefsOverride: prefs,
      );

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => Builder(
              builder: (ctx) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  controller.checkSession(ctx);
                });
                return const Scaffold(body: Text('Splash Screen'));
              },
            ),
          ),
          GoRoute(
            path: '/loginScreen',
            builder: (context, state) => const Scaffold(body: Text('Login Screen')),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      expect(find.text('Login Screen'), findsOneWidget);
      expect(prefs.getString('userRole'), isNull);
    });

    testWidgets('43. Demoted user in database updates cached role and navigates to permitted dashboard', (tester) async {
      SharedPreferences.setMockInitialValues({
        'userRole': 'admin', // Stale cache claims admin
        'user_id': 'user-101',
      });
      final prefs = await SharedPreferences.getInstance();

      final client = await createMockSupabaseClient(
        userId: 'user-101',
        email: 'staff@school.com',
        dbRole: 'staff', // Authoritative DB reports staff
      );

      final controller = SplashScreenController(
        clientOverride: client,
        prefsOverride: prefs,
      );

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => Builder(
              builder: (ctx) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  controller.checkSession(ctx);
                });
                return const Scaffold(body: Text('Splash Screen'));
              },
            ),
          ),
          GoRoute(
            path: '/staffDashboard',
            builder: (context, state) => const Scaffold(body: Text('Staff Dashboard')),
          ),
          GoRoute(
            path: '/adminDashboard',
            builder: (context, state) => const Scaffold(body: Text('Admin Dashboard')),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      // Successfully routes to staff dashboard and corrects cached role
      expect(find.text('Staff Dashboard'), findsOneWidget);
      expect(find.text('Admin Dashboard'), findsNothing);
      expect(prefs.getString('userRole'), equals('staff'));
    });
  });

  group('Protected Routes Widget Integration & Bypass Tests', () {
    testWidgets('44. Unauthenticated user accessing /adminDashboard is intercepted and redirected to /loginScreen', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final unauthClient = await createMockSupabaseClient(
        userId: '',
        email: '',
        isAuthenticated: false,
      );

      final router = createAppRouter(
        initialLocation: '/adminDashboard',
        clientOverride: unauthClient,
        prefsOverride: prefs,
      );

      await tester.pumpWidget(
        ProviderScope(child: MaterialApp.router(routerConfig: router)),
      );

      await tester.pumpAndSettle();

      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Admin Dashboard'), findsNothing);
    });

    testWidgets('45. Student attempting to access /adminDashboard is intercepted and redirected to /studentDashboard', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final studentClient = await createMockSupabaseClient(
        userId: 'student-attacker-uuid',
        email: 'student@school.com',
        dbRole: 'student',
      );

      final router = createAppRouter(
        initialLocation: '/adminDashboard',
        clientOverride: studentClient,
        prefsOverride: prefs,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            studentRepositoryProvider.overrideWithValue(MockStudentRepository()),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      await tester.pumpAndSettle();

      // Guard blocks admin dashboard and redirects to student dashboard
      expect(find.byType(StudentTabsShell), findsOneWidget);
      expect(find.text('Admin Dashboard'), findsNothing);
    });

    testWidgets('46. Student attempting to access /studentManagement is intercepted and redirected to /studentDashboard', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final studentClient = await createMockSupabaseClient(
        userId: 'student-attacker-uuid-2',
        email: 'student2@school.com',
        dbRole: 'student',
      );

      final router = createAppRouter(
        initialLocation: '/studentManagement',
        clientOverride: studentClient,
        prefsOverride: prefs,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            studentRepositoryProvider.overrideWithValue(MockStudentRepository()),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(StudentTabsShell), findsOneWidget);
      expect(find.text('Student Management'), findsNothing);
    });

    testWidgets('47. Staff user accessing /studentManagement successfully navigates to Student List screen', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final staffClient = await createMockSupabaseClient(
        userId: 'staff-mgmt-ok',
        email: 'staff@school.com',
        dbRole: 'staff',
      );

      final router = createAppRouter(
        initialLocation: '/studentManagement',
        clientOverride: staffClient,
        prefsOverride: prefs,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            studentRepositoryProvider.overrideWithValue(MockStudentRepository()),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(StudentListScreen), findsOneWidget);
      expect(find.text('Student Management'), findsOneWidget);
    });
  });
}
