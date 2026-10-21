import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:student_management/core/errors/app_exception.dart';
import 'package:student_management/features/students/data/datasources/student_remote_data_source.dart';
import 'package:student_management/services/student_services.dart';
import 'package:student_management/services/user_service.dart';

void main() {
  const supabaseUrl = 'https://fake-project-id.supabase.co';
  const anonKey = 'fake-anon-key';

  group('Student Borrowing-History Preservation Tests', () {
    test('1. StudentRemoteDataSource.deleteStudent throws ValidationException when active unreturned loans exist', () async {
      final List<String> recordedMethods = [];
      final List<String> recordedUrls = [];

      final mockHttpClient = MockClient((request) async {
        recordedMethods.add(request.method);
        recordedUrls.add(request.url.toString());

        // Active borrow_records query
        if (request.url.path.contains('/rest/v1/borrow_records') && request.method == 'GET') {
          return http.Response(
            jsonEncode([
              {'id': 'borrow-record-1', 'book_id': 'book-uuid-1'},
            ]),
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
      });

      final client = SupabaseClient(
        supabaseUrl,
        anonKey,
        httpClient: mockHttpClient,
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      );

      final dataSource = StudentRemoteDataSource(client: client);

      expect(
        () => dataSource.deleteStudent(
          studentId: 'std-100',
          authId: 'auth-user-100',
        ),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.message,
            'message',
            contains('active book loan(s)'),
          ),
        ),
      );

      // Verify no DELETE calls were issued to students or users
      expect(recordedMethods.contains('DELETE'), isFalse);
    });

    test('2. StudentRemoteDataSource.deleteStudent never issues DELETE to borrow_records when deleting clear student', () async {
      final List<Map<String, String>> recordedRequests = [];

      final mockHttpClient = MockClient((request) async {
        recordedRequests.add({
          'method': request.method,
          'path': request.url.path,
        });

        // 1. Query for active borrow_records -> returns empty
        if (request.url.path.contains('/rest/v1/borrow_records') && request.method == 'GET') {
          return http.Response(
            jsonEncode([]),
            200,
            request: request,
            headers: {'content-type': 'application/json'},
          );
        }

        // 2. Storage removal -> 200
        if (request.url.path.contains('/storage/v1/object/profile_pictures')) {
          return http.Response(
            jsonEncode([{'name': 'auth-user-100.jpg'}]),
            200,
            request: request,
            headers: {'content-type': 'application/json'},
          );
        }

        // 3. Delete student profile -> returns deleted row
        if (request.url.path.contains('/rest/v1/students') && request.method == 'DELETE') {
          return http.Response(
            jsonEncode([{'id': 'std-100', 'user_id': 'auth-user-100'}]),
            200,
            request: request,
            headers: {'content-type': 'application/json'},
          );
        }

        // 4. Delete public.users -> returns deleted row
        if (request.url.path.contains('/rest/v1/users') && request.method == 'DELETE') {
          return http.Response(
            jsonEncode([{'id': 'auth-user-100'}]),
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
      });

      final client = SupabaseClient(
        supabaseUrl,
        anonKey,
        httpClient: mockHttpClient,
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      );

      final dataSource = StudentRemoteDataSource(client: client);

      await dataSource.deleteStudent(
        studentId: 'std-100',
        authId: 'auth-user-100',
      );

      // CRITICAL INVARIANT: Zero DELETE requests to borrow_records
      final borrowDeletes = recordedRequests.where(
        (r) => r['method'] == 'DELETE' && r['path']!.contains('/rest/v1/borrow_records'),
      );
      expect(borrowDeletes, isEmpty, reason: 'borrow_records must never be deleted by client code');

      // Verify students and users delete requests WERE sent
      final studentDeletes = recordedRequests.where(
        (r) => r['method'] == 'DELETE' && r['path']!.contains('/rest/v1/students'),
      );
      expect(studentDeletes, isNotEmpty);

      final userDeletes = recordedRequests.where(
        (r) => r['method'] == 'DELETE' && r['path']!.contains('/rest/v1/users'),
      );
      expect(userDeletes, isNotEmpty);
    });

    test('3. StudentService.deleteStudentByUserId throws ValidationException when active loans exist', () async {
      final List<String> recordedMethods = [];

      final mockHttpClient = MockClient((request) async {
        recordedMethods.add(request.method);

        if (request.url.path.contains('/rest/v1/borrow_records') && request.method == 'GET') {
          return http.Response(
            jsonEncode([
              {'id': 'borrow-record-2', 'book_id': 'book-uuid-2'},
            ]),
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
      });

      final client = SupabaseClient(
        supabaseUrl,
        anonKey,
        httpClient: mockHttpClient,
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      );

      final service = StudentService(
        userService: UserService(client: client),
        client: client,
      );

      expect(
        () => service.deleteStudentByUserId(userId: 'auth-user-200'),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.message,
            'message',
            contains('active book loan(s)'),
          ),
        ),
      );

      // No DELETE issued
      expect(recordedMethods.contains('DELETE'), isFalse);
    });

    test('4. StudentService.deleteStudentByUserId never deletes borrow_records for clear student', () async {
      final List<Map<String, String>> recordedRequests = [];

      final mockHttpClient = MockClient((request) async {
        recordedRequests.add({
          'method': request.method,
          'path': request.url.path,
        });

        if (request.url.path.contains('/rest/v1/borrow_records') && request.method == 'GET') {
          return http.Response(
            jsonEncode([]),
            200,
            request: request,
            headers: {'content-type': 'application/json'},
          );
        }

        if (request.url.path.contains('/storage/v1/object/profile_pictures')) {
          return http.Response(
            jsonEncode([{'name': 'auth-user-200.jpg'}]),
            200,
            request: request,
            headers: {'content-type': 'application/json'},
          );
        }

        if (request.url.path.contains('/rest/v1/students') && request.method == 'DELETE') {
          return http.Response(
            jsonEncode([{'id': 'std-200', 'user_id': 'auth-user-200'}]),
            200,
            request: request,
            headers: {'content-type': 'application/json'},
          );
        }

        if (request.url.path.contains('/rest/v1/users') && request.method == 'DELETE') {
          return http.Response(
            jsonEncode([{'id': 'auth-user-200'}]),
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
      });

      final client = SupabaseClient(
        supabaseUrl,
        anonKey,
        httpClient: mockHttpClient,
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      );

      final service = StudentService(
        userService: UserService(client: client),
        client: client,
      );

      await service.deleteStudentByUserId(userId: 'auth-user-200');

      // CRITICAL INVARIANT: Zero DELETE requests to borrow_records
      final borrowDeletes = recordedRequests.where(
        (r) => r['method'] == 'DELETE' && r['path']!.contains('/rest/v1/borrow_records'),
      );
      expect(borrowDeletes, isEmpty, reason: 'borrow_records must never be deleted by client code');
    });
  });
}
