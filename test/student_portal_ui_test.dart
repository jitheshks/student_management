import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart' as legacy_provider;
import 'package:student_management/common/widgets/student_bottom_navigation.dart';
import 'package:student_management/controller/student_bottom_navigation_controller.dart';
import 'package:student_management/controller/student_dashboard_controller.dart';
import 'package:student_management/controller/student_library_controller.dart';
import 'package:student_management/core/theme/app_theme.dart';
import 'package:student_management/features/fees/domain/repositories/i_fees_repository.dart';
import 'package:student_management/features/fees/presentation/providers/fees_providers.dart';
import 'package:student_management/features/students/presentation/providers/student_providers.dart';
import 'package:student_management/shared/models/fee_record.dart';
import 'package:student_management/shared/models/student.dart';
import 'package:student_management/shared/widgets/empty_state_view.dart';
import 'package:student_management/shared/widgets/error_view.dart';
import 'package:student_management/view/screens/student_fees_screen/student_fees_screen.dart';
import 'package:student_management/view/screens/student_library_screen/student_library_screen.dart';
import 'package:student_management/view/screens/student_profile_screen/student_profile_screen.dart';
import 'package:student_management/view/screens/student_tab_screen/student_tab_screen.dart';

class MockStudentDashboardController extends StudentDashboardController {
  bool logoutCalled = false;

  @override
  Future<void> logout(BuildContext context) async {
    logoutCalled = true;
  }
}

class FakeFeesRepoForError implements IFeesRepository {
  @override
  Future<List<FeeRecord>> getAllFeeRecords() async => [];

  @override
  Future<FeesSummary> getInstitutionalFeesSummary() async => const FeesSummary(
    totalCollected: 0,
    totalPending: 0,
    totalOverdue: 0,
    totalStudents: 0,
    paidStudentsCount: 0,
  );

  @override
  Future<List<FeeRecord>> getStudentFeeRecords(String studentId) async {
    throw Exception('Database connection timeout');
  }
}

class FakeStudentLibraryController extends StudentLibraryController {
  bool loadCalled = false;

  FakeStudentLibraryController({
    List<StudentLibraryItem>? initialItems,
    bool initialLoading = false,
    String? initialError,
  }) {
    items = initialItems ?? [];
    loading = initialLoading;
    error = initialError;
  }

  @override
  Future<void> load(String id, {required bool filterByUserId}) async {
    loadCalled = true;
  }
}

void main() {
  const targetWidths = [
    320.0,
    360.0,
    390.0,
    600.0,
    768.0,
    1024.0,
    1280.0,
    1440.0,
  ];

  final mockStudent = Student(
    id: 'student-001',
    userId: 'user-001',
    firstName: 'Alex',
    lastName: 'Johnson',
    registerNumber: 'REG-2026-0042',
    standard: '10-A',
    email: 'alex.johnson@example.com',
    phone: '+91 9876543210',
    address: '42 Baker Street, London',
    attendance: 200,
    totalWorkingDays: 250,
    daysPresent: 200,
    dob: DateTime(2008, 5, 14),
  );

  final mockFeeRecords = [
    FeeRecord(
      id: 'fee-1',
      studentId: 'student-001',
      title: 'Term 1 Tuition Fee',
      amount: 45000.0,
      paidAmount: 45000.0,
      dueAmount: 0.0,
      academicYear: '2025-2026',
      dueDate: DateTime(2026, 6, 15),
      paidDate: DateTime(2026, 6, 10),
      status: FeeStatus.paid,
      receiptNumber: 'REC-2026-101',
    ),
    FeeRecord(
      id: 'fee-2',
      studentId: 'student-001',
      title: 'Term 2 Tuition Fee',
      amount: 45000.0,
      paidAmount: 20000.0,
      dueAmount: 25000.0,
      academicYear: '2025-2026',
      dueDate: DateTime(2026, 11, 15),
      paidDate: null,
      status: FeeStatus.pending,
      receiptNumber: null,
    ),
    FeeRecord(
      id: 'fee-3',
      studentId: 'student-001',
      title: 'Annual Library Fee',
      amount: 5000.0,
      paidAmount: 0.0,
      dueAmount: 5000.0,
      academicYear: '2025-2026',
      dueDate: DateTime(2026, 3, 1),
      paidDate: null,
      status: FeeStatus.overdue,
      receiptNumber: null,
    ),
  ];

  final mockLibraryItems = [
    StudentLibraryItem(
      id: 'loan-1',
      coverUrl: '',
      title: 'Clean Architecture in Practice',
      author: 'Robert C. Martin',
      borrowedAt: DateTime(2026, 1, 10),
      returnedAt: DateTime(2026, 1, 24),
      dueDate: DateTime(2026, 1, 24),
      status: 'returned',
    ),
    StudentLibraryItem(
      id: 'loan-2',
      coverUrl: '',
      title: 'Design Patterns: Elements of Reusable Object-Oriented Software',
      author: 'Erich Gamma et al.',
      borrowedAt: DateTime(2026, 2, 1),
      returnedAt: null,
      dueDate: DateTime(2026, 2, 15),
      status: 'overdue',
    ),
    StudentLibraryItem(
      id: 'loan-3',
      coverUrl: '',
      title: 'Flutter Apprentice',
      author: 'Raywenderlich Team',
      borrowedAt: DateTime(2026, 3, 1),
      returnedAt: null,
      dueDate: DateTime(2026, 3, 20),
      status: 'borrowed',
    ),
  ];

  Widget buildTestableShell({
    required double width,
    double height = 800.0,
    ThemeMode themeMode = ThemeMode.light,
    Student? student,
    List<FeeRecord>? feeRecords,
    StudentLibraryController? libraryController,
    StudentBottomNavController? bottomNavController,
    StudentDashboardController? dashboardController,
  }) {
    final effectiveStudent = student ?? mockStudent;
    final effectiveFees = feeRecords ?? mockFeeRecords;
    final effectiveLib =
        libraryController ??
        FakeStudentLibraryController(initialItems: mockLibraryItems);
    final effectiveNav = bottomNavController ?? StudentBottomNavController();
    final effectiveDash =
        dashboardController ?? MockStudentDashboardController();

    return ProviderScope(
      overrides: [
        studentProfileProvider(
          effectiveStudent.id,
        ).overrideWith((ref) => effectiveStudent),
        studentFeeRecordsProvider(
          effectiveStudent.id,
        ).overrideWith((ref) => effectiveFees),
      ],
      child: legacy_provider.MultiProvider(
        providers: [
          legacy_provider.ChangeNotifierProvider<
            StudentBottomNavController
          >.value(value: effectiveNav),
          legacy_provider.ChangeNotifierProvider<
            StudentDashboardController
          >.value(value: effectiveDash),
          legacy_provider.ChangeNotifierProvider<
            StudentLibraryController
          >.value(value: effectiveLib),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          home: MediaQuery(
            data: MediaQueryData(size: Size(width, height)),
            child: SizedBox(
              width: width,
              height: height,
              child: StudentTabsShell(
                id: effectiveStudent.id,
                filterByUserId: false,
                libraryController: effectiveLib,
              ),
            ),
          ),
        ),
      ),
    );
  }

  group('Batch 7: Student Portal Responsive UI Tests', () {
    testWidgets(
      '1. StudentTabsShell renders cleanly across all 8 target viewports with zero overflow',
      (tester) async {
        for (final width in targetWidths) {
          tester.view.physicalSize = Size(width, 900.0);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

          await tester.pumpWidget(
            buildTestableShell(width: width, height: 900.0),
          );
          await tester.pumpAndSettle();

          // Zero overflow errors
          expect(tester.takeException(), isNull);

          // Correct navigation layout based on viewport breakpoint
          if (width >= 768.0) {
            expect(find.byType(NavigationRail), findsOneWidget);
            expect(find.byType(StudentBottomNavigation), findsNothing);
          } else {
            expect(find.byType(StudentBottomNavigation), findsOneWidget);
            expect(find.byType(NavigationRail), findsNothing);
          }

          // Initial tab is StudentProfileScreen
          expect(find.byType(StudentProfileScreen), findsOneWidget);
        }
      },
    );

    testWidgets(
      '2. Tab switching between Profile, Library, and Fees works properly',
      (tester) async {
        tester.view.physicalSize = const Size(390.0, 844.0);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final navController = StudentBottomNavController();
        await tester.pumpWidget(
          buildTestableShell(
            width: 390.0,
            height: 844.0,
            bottomNavController: navController,
          ),
        );
        await tester.pumpAndSettle();

        // 1. Initial tab: Profile
        expect(navController.currentIndex, equals(0));
        expect(find.byType(StudentProfileScreen), findsOneWidget);

        // 2. Switch to Library
        navController.toLibrary();
        await tester.pumpAndSettle();
        expect(navController.currentIndex, equals(1));
        expect(find.text('Library History'), findsOneWidget);
        expect(find.text('Clean Architecture in Practice'), findsOneWidget);

        // 3. Switch to Fees
        navController.toFees();
        await tester.pumpAndSettle();
        expect(navController.currentIndex, equals(2));
        expect(find.text('My Fees'), findsOneWidget);
        expect(find.text('Fee Summary'), findsOneWidget);
      },
    );

    testWidgets(
      '3. StudentProfileScreen presents complete details, attendance calculations, and logout',
      (tester) async {
        tester.view.physicalSize = const Size(360.0, 740.0);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final dashboardController = MockStudentDashboardController();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              studentProfileProvider(
                mockStudent.id,
              ).overrideWith((ref) => mockStudent),
            ],
            child: legacy_provider.ChangeNotifierProvider<
              StudentDashboardController
            >.value(
              value: dashboardController,
              child: MaterialApp(
                theme: AppTheme.lightTheme,
                home: StudentProfileScreen(
                  studentId: mockStudent.id,
                  totalDays: 250,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verification of personal information (appears in hero header and personal info card)
        expect(find.text('Alex Johnson'), findsNWidgets(2));
        expect(find.text('Standard 10-A'), findsOneWidget);
        expect(find.text('REG-2026-0042'), findsOneWidget);
        expect(find.text('alex.johnson@example.com'), findsOneWidget);
        expect(find.text('+91 9876543210'), findsOneWidget);
        expect(find.text('42 Baker Street, London'), findsOneWidget);

        // Verification of attendance calculation (200 / 250 = 80.0%)
        expect(find.text('80.0%'), findsOneWidget);
        expect(find.text('200 days present'), findsOneWidget);
        expect(find.text('of 250 total days'), findsOneWidget);
        expect(find.text('Excellent'), findsOneWidget);

        // Verification of logout action
        final logoutBtn = find.byTooltip('Logout');
        expect(logoutBtn, findsOneWidget);
        await tester.tap(logoutBtn);
        await tester.pump();
        expect(dashboardController.logoutCalled, isTrue);
      },
    );

    testWidgets(
      '4. StudentProfileScreen correctly adapts attendance states (<50%, <=75%, >75%)',
      (tester) async {
        final lowAttendanceStudent = mockStudent.copyWith(
          attendance: 100, // 100/250 = 40.0%
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              studentProfileProvider(
                lowAttendanceStudent.id,
              ).overrideWith((ref) => lowAttendanceStudent),
            ],
            child: legacy_provider.ChangeNotifierProvider<
              StudentDashboardController
            >.value(
              value: MockStudentDashboardController(),
              child: MaterialApp(
                theme: AppTheme.lightTheme,
                home: StudentProfileScreen(
                  studentId: lowAttendanceStudent.id,
                  totalDays: 250,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('40.0%'), findsOneWidget);
        expect(find.text('Needs Attention'), findsOneWidget);
      },
    );

    testWidgets(
      '5. StudentLibraryScreen displays book loans, status badges, and empty/error states',
      (tester) async {
        final libController = FakeStudentLibraryController(
          initialItems: mockLibraryItems,
        );
        final dashController = MockStudentDashboardController();

        await tester.pumpWidget(
          legacy_provider.MultiProvider(
            providers: [
              legacy_provider.ChangeNotifierProvider<
                StudentDashboardController
              >.value(value: dashController),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: StudentLibraryScreen(
                id: 'student-001',
                filterByUserId: false,
                controller: libController,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Title and count
        expect(find.text('Library History'), findsOneWidget);
        expect(find.text('3 Books Record'), findsOneWidget);

        // 2. Book titles & authors
        expect(find.text('Clean Architecture in Practice'), findsOneWidget);
        expect(find.text('by Robert C. Martin'), findsOneWidget);
        expect(find.text('Returned'), findsOneWidget);

        expect(
          find.text(
            'Design Patterns: Elements of Reusable Object-Oriented Software',
          ),
          findsOneWidget,
        );
        expect(find.text('Overdue'), findsOneWidget);

        expect(find.text('Flutter Apprentice'), findsOneWidget);
        expect(find.text('Currently Borrowed'), findsOneWidget);

        // 3. Logout action
        final logoutBtn = find.byTooltip('Logout');
        expect(logoutBtn, findsOneWidget);
        await tester.tap(logoutBtn);
        await tester.pump();
        expect(dashController.logoutCalled, isTrue);

        // 4. Empty state testing
        final emptyController = FakeStudentLibraryController(initialItems: []);
        await tester.pumpWidget(
          legacy_provider.MultiProvider(
            providers: [
              legacy_provider.ChangeNotifierProvider<
                StudentDashboardController
              >.value(value: dashController),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: StudentLibraryScreen(
                id: 'student-001',
                filterByUserId: false,
                controller: emptyController,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(EmptyStateView), findsOneWidget);
        expect(find.text('No Borrowed Books'), findsOneWidget);

        // 5. Error state testing
        final errorController = FakeStudentLibraryController(
          initialError: 'Network connection failed',
        );
        await tester.pumpWidget(
          legacy_provider.MultiProvider(
            providers: [
              legacy_provider.ChangeNotifierProvider<
                StudentDashboardController
              >.value(value: dashController),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: StudentLibraryScreen(
                id: 'student-001',
                filterByUserId: false,
                controller: errorController,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(ErrorView), findsOneWidget);
        expect(find.text('Error: Network connection failed'), findsOneWidget);
      },
    );

    testWidgets(
      '6. StudentFeesScreen calculates aggregate financial KPIs and displays read-only records',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              studentFeeRecordsProvider(
                'student-001',
              ).overrideWith((ref) => mockFeeRecords),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const StudentFeesScreen(studentId: 'student-001'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Verify Aggregate KPIs
        // Total = 45000 + 45000 + 5000 = 95000
        // Paid = 45000 + 20000 + 0 = 65000
        // Due = 0 + 25000 + 5000 = 30000
        expect(find.text('Fee Summary'), findsOneWidget);
        expect(find.text('₹95000'), findsOneWidget);
        expect(find.text('₹65000'), findsOneWidget);
        expect(find.text('₹30000'), findsOneWidget);

        // 2. Verify Fee Records & Badges
        expect(find.text('Term 1 Tuition Fee'), findsOneWidget);
        expect(find.text('PAID'), findsOneWidget);

        expect(find.text('Term 2 Tuition Fee'), findsOneWidget);
        expect(find.text('PENDING'), findsOneWidget);
        expect(find.text('Due: ₹25000'), findsOneWidget);

        expect(find.text('Annual Library Fee'), findsOneWidget);
        expect(find.text('OVERDUE'), findsOneWidget);

        // 3. Confirm strictly read-only: no Pay/Checkout button
        expect(find.text('Pay Now'), findsNothing);
        expect(find.text('Checkout'), findsNothing);
      },
    );

    testWidgets('7. StudentFeesScreen renders empty and error states cleanly', (
      tester,
    ) async {
      // 1. Empty state
      await tester.pumpWidget(
        ProviderScope(
          key: const ValueKey('empty_fees_scope'),
          overrides: [
            studentFeeRecordsProvider(
              'student-001',
            ).overrideWith((ref) => <FeeRecord>[]),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const StudentFeesScreen(studentId: 'student-001'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(EmptyStateView), findsOneWidget);
      expect(find.text('No fee dues found'), findsOneWidget);

      // 2. Error state
      await tester.pumpWidget(
        ProviderScope(
          key: const ValueKey('error_fees_scope'),
          overrides: [
            feesRepositoryProvider.overrideWithValue(FakeFeesRepoForError()),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const StudentFeesScreen(studentId: 'student-001'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ErrorView), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
    });

    testWidgets(
      '8. StudentPortal mobile landscape (800x400) and Dark Mode render with zero overflow',
      (tester) async {
        // Landscape mobile (800x400)
        tester.view.physicalSize = const Size(800.0, 400.0);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          buildTestableShell(
            width: 800.0,
            height: 400.0,
            themeMode: ThemeMode.dark,
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(StudentTabsShell), findsOneWidget);
        expect(find.text('Alex Johnson'), findsNWidgets(2));
      },
    );
  });
}
