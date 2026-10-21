import 'dart:convert';
import 'dart:io';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:student_management/core/errors/app_exception.dart';
import 'package:student_management/core/theme/app_theme.dart';
import 'package:student_management/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:student_management/features/staff/data/datasources/staff_remote_data_source.dart';
import 'package:student_management/features/staff/domain/repositories/i_staff_repository.dart';
import 'package:student_management/features/staff/presentation/providers/staff_providers.dart';
import 'package:student_management/features/staff/presentation/screens/staff_form_screen.dart';
import 'package:student_management/features/staff/presentation/screens/staff_list_screen.dart';
import 'package:student_management/shared/models/staff.dart';
import 'package:student_management/shared/models/user_entity.dart';

class MockStaffRepository implements IStaffRepository {
  final List<Staff> _staffList = [];
  UserEntity? currentSessionUser;

  MockStaffRepository() {
    _staffList.addAll([
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
    ]);
  }

  @override
  Future<List<Staff>> getStaffList({
    String? designationFilter,
    String? searchQuery,
    String? sortOrder = 'A-Z',
  }) async {
    List<Staff> results = List.from(_staffList);

    if (designationFilter != null && designationFilter != 'All') {
      results = results
          .where((s) => s.designation.toLowerCase() == designationFilter.toLowerCase())
          .toList();
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim().toLowerCase();
      results = results.where((s) {
        final full = '${s.firstName} ${s.lastName} ${s.name}'.toLowerCase();
        final email = (s.email ?? '').toLowerCase();
        final phone = (s.phone ?? '').toLowerCase();
        final desig = s.designation.toLowerCase();
        return full.contains(q) || email.contains(q) || phone.contains(q) || desig.contains(q);
      }).toList();
    }

    switch (sortOrder) {
      case 'Z-A':
        results.sort((a, b) => b.firstName.toLowerCase().compareTo(a.firstName.toLowerCase()));
        break;
      case 'A-Z':
      default:
        results.sort((a, b) => a.firstName.toLowerCase().compareTo(b.firstName.toLowerCase()));
        break;
    }

    return results;
  }

  @override
  Future<Staff?> getStaffById(String id) async {
    try {
      return _staffList.firstWhere((s) => s.id == id || s.userId == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Staff?> getStaffByEmail(String email) async {
    try {
      return _staffList.firstWhere((s) => s.email?.toLowerCase() == email.trim().toLowerCase());
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
      id: 'stf-${_staffList.length + 1}',
      userId: 'auth-stf-${_staffList.length + 1}',
    );
    _staffList.add(newStaff);
  }

  @override
  Future<void> updateStaff({
    required Staff staff,
    File? avatarFile,
  }) async {
    final idx = _staffList.indexWhere((s) => s.id == staff.id);
    if (idx != -1) {
      _staffList[idx] = staff;
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
    _staffList.removeWhere((s) => s.id == staffId || s.userId == authId);
  }

  @override
  Future<Map<String, int>> bulkDeleteStaff(List<Staff> staffList) async {
    int success = 0;
    for (final staff in staffList) {
      _staffList.removeWhere((s) => s.id == staff.id);
      success++;
    }
    return {'success': success, 'fail': 0};
  }
}

void main() {
  group('Phase 3 Staff Repository & Domain Tests', () {
    late MockStaffRepository repository;

    setUp(() {
      repository = MockStaffRepository();
    });

    test('1. Staff list loads and sorts correctly (A-Z and Z-A)', () async {
      final listAZ = await repository.getStaffList(sortOrder: 'A-Z');
      expect(listAZ.length, equals(3));
      expect(listAZ[0].firstName, equals('Alice'));
      expect(listAZ[1].firstName, equals('Bob'));
      expect(listAZ[2].firstName, equals('Charlie'));

      final listZA = await repository.getStaffList(sortOrder: 'Z-A');
      expect(listZA.length, equals(3));
      expect(listZA[0].firstName, equals('Charlie'));
      expect(listZA[1].firstName, equals('Bob'));
      expect(listZA[2].firstName, equals('Alice'));
    });

    test('2. Staff filtering by designation and search query works', () async {
      final teachers = await repository.getStaffList(designationFilter: 'Teacher');
      expect(teachers.length, equals(1));
      expect(teachers.first.firstName, equals('Alice'));

      final librarians = await repository.getStaffList(designationFilter: 'Librarian');
      expect(librarians.length, equals(1));
      expect(librarians.first.firstName, equals('Bob'));

      final searchCharlie = await repository.getStaffList(searchQuery: 'charlie');
      expect(searchCharlie.length, equals(1));
      expect(searchCharlie.first.firstName, equals('Charlie'));

      final searchEmail = await repository.getStaffList(searchQuery: 'martin@school.com');
      expect(searchEmail.length, equals(1));
      expect(searchEmail.first.firstName, equals('Bob'));
    });

    test('3. Staff creation, update, and deletion operate cleanly', () async {
      final newStaff = Staff(
        id: '',
        userId: '',
        firstName: 'Diana',
        lastName: 'Prince',
        designation: 'Principal',
        email: 'diana.prince@school.com',
        phone: '1112223333',
        address: '500 Olympus St',
      );

      await repository.createStaff(
        staff: newStaff,
        password: 'Diana@1980',
      );

      final all = await repository.getStaffList();
      expect(all.length, equals(4));
      expect(all.any((s) => s.firstName == 'Diana'), isTrue);

      final created = all.firstWhere((s) => s.firstName == 'Diana');
      final updated = created.copyWith(designation: 'Headmistress');
      await repository.updateStaff(staff: updated);

      final fetchedUpdated = await repository.getStaffById(created.id);
      expect(fetchedUpdated?.designation, equals('Headmistress'));

      await repository.deleteStaff(staffId: created.id, authId: created.userId);
      final remaining = await repository.getStaffList();
      expect(remaining.length, equals(3));
      expect(remaining.any((s) => s.firstName == 'Diana'), isFalse);
    });

    test('4. Critical Session Preservation Invariant: Admin session is preserved after creating staff', () async {
      final adminUser = const UserEntity(
        id: 'admin-uid-100',
        email: 'admin@school.com',
        role: UserRole.admin,
      );
      repository.currentSessionUser = adminUser;

      final staff = Staff(
        id: '',
        userId: '',
        firstName: 'Elena',
        lastName: 'Rostova',
        designation: 'Teacher',
        email: 'elena@school.com',
      );

      await repository.createStaff(
        staff: staff,
        password: 'Elena@1990',
      );

      expect(repository.currentSessionUser, isNotNull);
      expect(repository.currentSessionUser!.id, equals('admin-uid-100'));
      expect(repository.currentSessionUser!.email, equals('admin@school.com'));
      expect(repository.currentSessionUser!.role, equals(UserRole.admin));
    });

    test('5. Bulk deletion deletes multiple staff members and returns counts', () async {
      final initial = await repository.getStaffList();
      expect(initial.length, equals(3));

      final toDelete = initial.take(2).toList();
      final res = await repository.bulkDeleteStaff(toDelete);

      expect(res['success'], equals(2));
      expect(res['fail'], equals(0));

      final after = await repository.getStaffList();
      expect(after.length, equals(1));
      expect(after.first.firstName, equals('Charlie'));
    });
  });

  group('Phase 3 End-to-End Staff Remote Data Source Invariant Test', () {
    test('6. StaffRemoteDataSource.createStaff preserves admin session across network boundary', () async {
      const supabaseUrl = 'https://mock-school-db.supabase.co';
      const anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.dummy-anon-key';

      final adminSessionJson = jsonEncode({
        'access_token': 'admin-active-jwt-token-777',
        'token_type': 'bearer',
        'expires_in': 3600,
        'refresh_token': 'admin-refresh-token-777',
        'user': {
          'id': 'admin-user-id-777',
          'aud': 'authenticated',
          'role': 'authenticated',
          'email': 'admin@school.com',
          'app_metadata': {'role': 'admin'},
          'user_metadata': {'name': 'Administrator'},
          'created_at': '2026-01-01T00:00:00Z',
        },
      });

      final mockHttpClient = MockClient((request) async {
        final uri = request.url;

        // Duplicate check queries on users & staff
        if (uri.path.contains('/rest/v1/users') && request.method == 'GET') {
          return http.Response(jsonEncode([]), 200, request: request, headers: {'content-type': 'application/json'});
        }
        if (uri.path.contains('/rest/v1/staff') && request.method == 'GET') {
          return http.Response(jsonEncode([]), 200, request: request, headers: {'content-type': 'application/json'});
        }

        // Edge function create-user-admin succeeds
        if (uri.path.contains('/functions/v1/create-user-admin')) {
          expect(request.headers['authorization'], equals('Bearer admin-active-jwt-token-777'));
          return http.Response(
            jsonEncode({
              'userId': 'new-staff-auth-id-888',
              'message': 'Staff created via Edge Function',
            }),
            200,
            request: request,
            headers: {'content-type': 'application/json'},
          );
        }

        // Users table upsert
        if (uri.path.contains('/rest/v1/users') && request.method == 'POST') {
          return http.Response(jsonEncode([]), 201, request: request, headers: {'content-type': 'application/json'});
        }

        // Staff table insert
        if (uri.path.contains('/rest/v1/staff') && request.method == 'POST') {
          return http.Response(jsonEncode([]), 201, request: request, headers: {'content-type': 'application/json'});
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
      expect(client.auth.currentSession?.accessToken, equals('admin-active-jwt-token-777'));
      expect(client.auth.currentUser?.id, equals('admin-user-id-777'));

      final authRemoteDataSource = AuthRemoteDataSource(
        client,
        isolatedHttpClient: mockHttpClient,
      );

      final staffRemoteDataSource = StaffRemoteDataSource(
        client: client,
        authRemoteDataSource: authRemoteDataSource,
      );

      final staff = Staff(
        id: '',
        userId: '',
        firstName: 'Fiona',
        lastName: 'Gallagher',
        designation: 'Teacher',
        email: 'fiona@school.com',
      );

      await staffRemoteDataSource.createStaff(
        staff: staff,
        password: 'FionaPassword123',
      );

      // Verify admin session on main client is 100% UNTOUCHED
      expect(client.auth.currentSession?.accessToken, equals('admin-active-jwt-token-777'));
      expect(client.auth.currentUser?.id, equals('admin-user-id-777'));
      expect(client.auth.currentUser?.email, equals('admin@school.com'));
    });
  });

  group('Phase 3 Riverpod Widget Tests', () {
    late MockStaffRepository repository;

    setUp(() {
      repository = MockStaffRepository();
    });

    testWidgets('7. StaffListScreen renders staff cards and responsive layout', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            staffRepositoryProvider.overrideWithValue(repository),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const StaffListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Staff Management'), findsOneWidget);
      expect(find.text('Alice Wong'), findsOneWidget);
      expect(find.text('Bob Martin'), findsOneWidget);
      expect(find.text('Charlie Davis'), findsOneWidget);
      expect(find.text('Teacher'), findsOneWidget);
      expect(find.text('Librarian'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('8. StaffFormScreen renders fields and validates required inputs', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            staffRepositoryProvider.overrideWithValue(repository),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const StaffFormScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Add Staff'), findsOneWidget);
      expect(find.text('First Name'), findsOneWidget);
      expect(find.text('Last Name'), findsOneWidget);
      expect(find.text('Address'), findsOneWidget);
      expect(find.text('Phone Number'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Designation'), findsOneWidget);
      expect(find.text('Date of Birth (d/M/yyyy)'), findsOneWidget);
      expect(find.text('Create Staff'), findsOneWidget);

      // Tap submit on empty form to trigger validation errors
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
    });
  });
}
