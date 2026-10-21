import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:student_management/core/errors/app_exception.dart';
import 'package:student_management/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:student_management/features/students/data/datasources/student_remote_data_source.dart';
import 'package:student_management/shared/models/student.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const supabaseUrl = 'https://mock-school-db.supabase.co';
  const anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.dummy-anon-key';

  final adminSessionJson = jsonEncode({
    'access_token': 'admin-jwt-token-active-session',
    'token_type': 'bearer',
    'expires_in': 3600,
    'refresh_token': 'admin-refresh-token-xyz',
    'user': {
      'id': 'admin-uid-100',
      'aud': 'authenticated',
      'role': 'authenticated',
      'email': 'admin@school.com',
      'app_metadata': {'role': 'admin'},
      'user_metadata': {'name': 'School Administrator'},
      'created_at': '2026-01-01T00:00:00Z',
    },
  });

  group('Phase 2.1 Admin Session Preservation Regression Tests', () {
    test('1. Edge Function available: Admin session is preserved and returns new student auth UID', () async {
      final mockHttpClient = MockClient((request) async {
        final uri = request.url;

        // Edge function create-user-admin
        if (uri.path.contains('/functions/v1/create-user-admin')) {
          final authHeader = request.headers['authorization'];
          expect(authHeader, equals('Bearer admin-jwt-token-active-session'));

          return http.Response(
            jsonEncode({
              'userId': 'student-auth-uid-from-edge',
              'message': 'User created successfully via Edge Function',
            }),
            200,
            request: request,
            headers: {'content-type': 'application/json'},
          );
        }

        // Postgrest users table upsert
        if (uri.path.contains('/rest/v1/users')) {
          return http.Response(
            jsonEncode([]),
            201,
            request: request,
            headers: {'content-type': 'application/json'},
          );
        }

        return http.Response('Not Found: ${uri.path}', 404, request: request);
      });

      final client = SupabaseClient(
        supabaseUrl,
        anonKey,
        httpClient: mockHttpClient,
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      );

      // Establish authenticated admin session before operation
      await client.auth.setInitialSession(adminSessionJson);
      expect(client.auth.currentSession?.accessToken, equals('admin-jwt-token-active-session'));
      expect(client.auth.currentUser?.id, equals('admin-uid-100'));
      expect(client.auth.currentUser?.email, equals('admin@school.com'));

      final authRemoteDataSource = AuthRemoteDataSource(
        client,
        isolatedHttpClient: mockHttpClient,
      );

      final newStudentUid = await authRemoteDataSource.adminCreateUser(
        email: 'alice@school.com',
        password: 'AlicePassword123',
        role: 'student',
      );

      // 1. Result check: returns the student's auth UID
      expect(newStudentUid, equals('student-auth-uid-from-edge'));

      // 2. CRITICAL SESSION INVARIANT: Admin identity and session are completely preserved!
      expect(client.auth.currentSession?.accessToken, equals('admin-jwt-token-active-session'));
      expect(client.auth.currentUser?.id, equals('admin-uid-100'));
      expect(client.auth.currentUser?.email, equals('admin@school.com'));
    });

    test('2. Edge Function fails -> Isolated client fallback: Admin session is preserved even when signUp returns a session', () async {
      final mockHttpClient = MockClient((request) async {
        final uri = request.url;

        // Edge function create-user-admin: FAILS (unavailable or not deployed)
        if (uri.path.contains('/functions/v1/create-user-admin')) {
          return http.Response(
            '{"error": "Function not found"}',
            404,
            request: request,
            headers: {'content-type': 'application/json'},
          );
        }

        // Auth signUp endpoint: returns a full session (auto-confirm disabled)
        if (uri.path.contains('/auth/v1/signup')) {
          // Reflect real Supabase gateway behavior: missing apikey returns 401
          final apikeyHeader = request.headers['apikey'];
          if (apikeyHeader == null || apikeyHeader.isEmpty) {
            return http.Response(
              jsonEncode({'code': 401, 'msg': 'Missing apikey header'}),
              401,
              request: request,
              headers: {'content-type': 'application/json'},
            );
          }
          expect(apikeyHeader, equals(anonKey), reason: 'Fallback client must transmit configured apikey');

          return http.Response(
            jsonEncode({
              'access_token': 'new-student-jwt-access-token-999',
              'token_type': 'bearer',
              'expires_in': 3600,
              'refresh_token': 'new-student-refresh-token-999',
              'user': {
                'id': 'student-auth-uid-from-fallback',
                'aud': 'authenticated',
                'role': 'authenticated',
                'email': 'bob@school.com',
                'app_metadata': {'role': 'student'},
                'user_metadata': {},
                'created_at': '2026-10-16T12:00:00Z',
              },
            }),
            200,
            request: request,
            headers: {'content-type': 'application/json'},
          );
        }

        // Postgrest users table upsert
        if (uri.path.contains('/rest/v1/users')) {
          return http.Response(
            jsonEncode([]),
            201,
            request: request,
            headers: {'content-type': 'application/json'},
          );
        }

        return http.Response('Not Found: ${uri.path}', 404, request: request);
      });

      final client = SupabaseClient(
        supabaseUrl,
        anonKey,
        httpClient: mockHttpClient,
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      );

      // Establish authenticated admin session before operation
      await client.auth.setInitialSession(adminSessionJson);
      expect(client.auth.currentSession?.accessToken, equals('admin-jwt-token-active-session'));
      expect(client.auth.currentUser?.id, equals('admin-uid-100'));
      expect(client.auth.currentUser?.email, equals('admin@school.com'));

      final authRemoteDataSource = AuthRemoteDataSource(
        client,
        isolatedHttpClient: mockHttpClient,
      );

      // Track if any auth change event is emitted on the main client
      final emittedEvents = <AuthChangeEvent>[];
      final subscription = client.auth.onAuthStateChange.listen((data) {
        emittedEvents.add(data.event);
      });

      final newStudentUid = await authRemoteDataSource.adminCreateUser(
        email: 'bob@school.com',
        password: 'BobPassword123',
        role: 'student',
      );

      await Future.delayed(const Duration(milliseconds: 50));
      await subscription.cancel();

      // 1. Result check: successfully returns the new student's auth ID
      expect(newStudentUid, equals('student-auth-uid-from-fallback'));

      // 2. CRITICAL INVARIANT: Admin identity and token on main client remain 100% UNTOUCHED
      expect(client.auth.currentSession?.accessToken, equals('admin-jwt-token-active-session'));
      expect(client.auth.currentUser?.id, equals('admin-uid-100'));
      expect(client.auth.currentUser?.email, equals('admin@school.com'));

      // 3. Main client NEVER emitted a signedIn event for the new student
      expect(emittedEvents.contains(AuthChangeEvent.signedIn), isFalse);
    });

    test('3. Verification of vulnerable legacy pattern: Direct client.auth.signUp WOULD have hijacked the session', () async {
      final mockHttpClient = MockClient((request) async {
        if (request.url.path.contains('/auth/v1/signup')) {
          return http.Response(
            jsonEncode({
              'access_token': 'hijacker-student-jwt',
              'token_type': 'bearer',
              'expires_in': 3600,
              'refresh_token': 'hijacker-refresh-token',
              'user': {
                'id': 'hijacker-student-uid',
                'aud': 'authenticated',
                'role': 'authenticated',
                'email': 'student@school.com',
                'created_at': '2026-10-16T12:00:00Z',
              },
            }),
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
        httpClient: mockHttpClient,
        authOptions: const AuthClientOptions(
          autoRefreshToken: false,
          authFlowType: AuthFlowType.implicit,
        ),
      );

      await client.auth.setInitialSession(adminSessionJson);
      expect(client.auth.currentUser?.id, equals('admin-uid-100'));

      // Directly calling client.auth.signUp (the old vulnerable way)
      await client.auth.signUp(
        email: 'student@school.com',
        password: 'password123',
      );

      // Demonstrates that the old way HIJACKED the admin session:
      expect(client.auth.currentUser?.id, equals('hijacker-student-uid'));
      expect(client.auth.currentSession?.accessToken, equals('hijacker-student-jwt'));
    });

    test('4. Full StudentRemoteDataSource.createStudent integration preserves admin session', () async {
      final mockHttpClient = MockClient((request) async {
        final uri = request.url;

        // Check existing email in users
        if (uri.path.contains('/rest/v1/users') && request.method == 'GET') {
          return http.Response(
            jsonEncode([]),
            200,
            request: request,
            headers: {'content-type': 'application/json'},
          );
        }

        // Check existing email in students
        if (uri.path.contains('/rest/v1/students') && request.method == 'GET') {
          // If query is for highest register_number
          if (uri.query.contains('order=register_number.desc')) {
            return http.Response(
              jsonEncode([{'register_number': '10800010'}]),
              200,
              request: request,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response(
            jsonEncode([]),
            200,
            request: request,
            headers: {'content-type': 'application/json'},
          );
        }

        // Edge function create-user-admin: not available
        if (uri.path.contains('/functions/v1/create-user-admin')) {
          return http.Response(
            '{"error": "Function not found"}',
            404,
            request: request,
            headers: {'content-type': 'application/json'},
          );
        }

        // Fallback signUp returns session
        if (uri.path.contains('/auth/v1/signup')) {
          // Reflect real Supabase gateway behavior: missing apikey returns 401
          final apikeyHeader = request.headers['apikey'];
          if (apikeyHeader == null || apikeyHeader.isEmpty) {
            return http.Response(
              jsonEncode({'code': 401, 'msg': 'Missing apikey header'}),
              401,
              request: request,
              headers: {'content-type': 'application/json'},
            );
          }
          expect(apikeyHeader, equals(anonKey), reason: 'Fallback client must transmit configured apikey');

          return http.Response(
            jsonEncode({
              'access_token': 'student-isolated-jwt',
              'token_type': 'bearer',
              'expires_in': 3600,
              'refresh_token': 'student-isolated-refresh',
              'user': {
                'id': 'created-student-auth-id-555',
                'aud': 'authenticated',
                'role': 'authenticated',
                'email': 'charlie@school.com',
                'created_at': '2026-10-16T12:00:00Z',
              },
            }),
            200,
            request: request,
            headers: {'content-type': 'application/json'},
          );
        }

        // Users table upsert
        if (uri.path.contains('/rest/v1/users') && request.method == 'POST') {
          return http.Response(
            jsonEncode([]),
            201,
            request: request,
            headers: {'content-type': 'application/json'},
          );
        }

        // Students table insert
        if (uri.path.contains('/rest/v1/students') && request.method == 'POST') {
          return http.Response(
            jsonEncode([]),
            201,
            request: request,
            headers: {'content-type': 'application/json'},
          );
        }

        return http.Response('Not Found: ${uri.path}', 404, request: request);
      });

      final client = SupabaseClient(
        supabaseUrl,
        anonKey,
        httpClient: mockHttpClient,
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      );

      await client.auth.setInitialSession(adminSessionJson);
      expect(client.auth.currentSession?.accessToken, equals('admin-jwt-token-active-session'));
      expect(client.auth.currentUser?.id, equals('admin-uid-100'));

      final authRemoteDataSource = AuthRemoteDataSource(
        client,
        isolatedHttpClient: mockHttpClient,
      );

      final studentRemoteDataSource = StudentRemoteDataSource(
        client: client,
        authRemoteDataSource: authRemoteDataSource,
      );

      final student = Student(
        id: '',
        userId: '',
        firstName: 'Charlie',
        lastName: 'Brown',
        registerNumber: '',
        standard: '9th',
        email: 'charlie@school.com',
      );

      await studentRemoteDataSource.createStudent(
        student: student,
        password: 'CharliePassword123',
      );

      // Invariant check: Admin session on client remains intact!
      expect(client.auth.currentSession?.accessToken, equals('admin-jwt-token-active-session'));
      expect(client.auth.currentUser?.id, equals('admin-uid-100'));
      expect(client.auth.currentUser?.email, equals('admin@school.com'));
    });

    test('5. Missing admin session: Calling adminCreateUser without an active session throws AppAuthException', () async {
      final mockHttpClient = MockClient((request) async => http.Response('Not Found', 404, request: request));

      final client = SupabaseClient(
        supabaseUrl,
        anonKey,
        httpClient: mockHttpClient,
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      );

      // Verify NO session exists
      expect(client.auth.currentSession, isNull);
      expect(client.auth.currentUser, isNull);

      final authRemoteDataSource = AuthRemoteDataSource(
        client,
        isolatedHttpClient: mockHttpClient,
      );

      expect(
        () => authRemoteDataSource.adminCreateUser(
          email: 'unauth@school.com',
          password: 'Password123',
          role: 'student',
        ),
        throwsA(
          isA<AppAuthException>().having(
            (e) => e.message,
            'message',
            contains('An active authenticated admin session is required'),
          ),
        ),
      );
    });

    test('6. Missing API key configuration: throws AppAuthException when apikey cannot be resolved', () async {
      final mockHttpClient = MockClient((request) async {
        final uri = request.url;
        // Edge function create-user-admin: FAILS
        if (uri.path.contains('/functions/v1/create-user-admin')) {
          return http.Response(
            '{"error": "Function not found"}',
            404,
            request: request,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found: ${uri.path}', 404, request: request);
      });

      // Construct a client with an empty anon key
      final client = SupabaseClient(
        supabaseUrl,
        '',
        httpClient: mockHttpClient,
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      );

      await client.auth.setInitialSession(adminSessionJson);

      final authRemoteDataSource = AuthRemoteDataSource(
        client,
        isolatedHttpClient: mockHttpClient,
      );

      expect(
        () => authRemoteDataSource.adminCreateUser(
          email: 'noapikey@school.com',
          password: 'Password123',
          role: 'student',
        ),
        throwsA(
          isA<AppAuthException>().having(
            (e) => e.message,
            'message',
            contains('Supabase API key is missing'),
          ),
        ),
      );
    });
  });
}
