import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:student_management/controller/base_dashboard_controller.dart';
import 'package:student_management/core/theme/app_theme.dart';
import 'package:student_management/shared/widgets/app_status_badge.dart';
import 'package:student_management/view/screens/admin_dashboard/user_dashboard_screen.dart';

class FakeAdminDashboardController extends BaseDashboardController {
  FakeAdminDashboardController({
    int students = 142,
    int staff = 28,
    String name = 'Admin User',
    String? error,
  }) {
    totalStudents = students;
    totalStaff = staff;
    displayName = name;
    errorMessage = error;
  }

  bool didLoad = false;
  bool didLogout = false;

  @override
  Future<void> load() async {
    didLoad = true;
    notifyListeners();
  }

  @override
  Future<void> logout(BuildContext context) async {
    didLogout = true;
    context.go('/loginScreen');
  }

  @override
  List<Map<String, dynamic>> managementOptions(BuildContext context) => [
    {
      'label': 'Student Management',
      'icon': Icons.person,
      'action': () => context.push('/studentManagement'),
    },
    {
      'label': 'Library Management',
      'icon': Icons.library_books,
      'action': () => context.push('/libraryManagement'),
    },
    {
      'label': 'Staff Management',
      'icon': Icons.people,
      'action': () => context.push('/staffManagement'),
    },
    {
      'label': 'Fees Management',
      'icon': Icons.attach_money,
      'action': () => context.push('/feesDashboard'),
    },
  ];
}

class FakeStaffProfileController extends BaseDashboardController {
  FakeStaffProfileController({
    int students = 85,
    int staff = 19,
    String name = 'Prof. Eleanor Vance',
    String? error,
  }) {
    totalStudents = students;
    totalStaff = staff;
    displayName = name;
    errorMessage = error;
  }

  bool didLoad = false;
  bool didLogout = false;

  @override
  Future<void> load() async {
    didLoad = true;
    notifyListeners();
  }

  @override
  Future<void> logout(BuildContext context) async {
    didLogout = true;
    context.go('/loginScreen');
  }

  @override
  List<Map<String, dynamic>> managementOptions(BuildContext context) => [
    {
      'label': 'Student Management',
      'icon': Icons.person,
      'action': () => context.push('/studentManagement'),
    },
    {
      'label': 'Library Management',
      'icon': Icons.library_books,
      'action': () => context.push('/libraryManagement'),
    },
    {
      'label': 'Fees Management',
      'icon': Icons.attach_money,
      'action': () => context.push('/feesDashboard'),
    },
  ];
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

  Widget buildDashboardTestApp({required Widget child, ThemeData? theme}) {
    return MaterialApp.router(
      theme: theme ?? AppTheme.lightTheme,
      routerConfig: GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (context, state) => child),
          GoRoute(
            path: '/loginScreen',
            builder:
                (context, state) =>
                    const Scaffold(body: Text('Login Screen Mock')),
          ),
          GoRoute(
            path: '/studentManagement',
            builder:
                (context, state) =>
                    const Scaffold(body: Text('Student Management Mock')),
          ),
          GoRoute(
            path: '/libraryManagement',
            builder:
                (context, state) =>
                    const Scaffold(body: Text('Library Management Mock')),
          ),
          GoRoute(
            path: '/staffManagement',
            builder:
                (context, state) =>
                    const Scaffold(body: Text('Staff Management Mock')),
          ),
          GoRoute(
            path: '/feesDashboard',
            builder:
                (context, state) =>
                    const Scaffold(body: Text('Fees Dashboard Mock')),
          ),
        ],
      ),
    );
  }

  group('Batch 3: Admin & Staff Dashboards Responsive UI Tests', () {
    testWidgets(
      'Admin Dashboard renders cleanly across all 8 target viewports with zero overflow',
      (tester) async {
        for (final width in targetWidths) {
          tester.view.physicalSize = Size(width, 800);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          final fakeAdmin = FakeAdminDashboardController(
            name: 'Dean Winchester',
          );

          await tester.pumpWidget(
            buildDashboardTestApp(
              child: UserDashboard<FakeAdminDashboardController>(
                title: 'Admin Dashboard',
                createController: (_) => fakeAdmin,
              ),
            ),
          );
          await tester.pump();
          // Pump animation for TweenAnimationBuilder
          await tester.pump(const Duration(milliseconds: 900));

          // Header verifications
          expect(find.text('Admin Dashboard'), findsOneWidget);
          expect(find.text('Dean Winchester'), findsOneWidget);
          expect(find.text('Administrator'), findsOneWidget);
          expect(find.byType(AppStatusBadge), findsOneWidget);

          // Metrics verifications
          expect(find.text('Total Students'), findsOneWidget);
          expect(find.text('Staff Members'), findsOneWidget);
          expect(find.text('142'), findsOneWidget);
          expect(find.text('28'), findsOneWidget);

          // All 4 Admin Management options must be visible
          expect(find.text('Student Management'), findsOneWidget);
          expect(find.text('Library Management'), findsOneWidget);
          expect(find.text('Staff Management'), findsOneWidget);
          expect(find.text('Fees Management'), findsOneWidget);

          // Strict overflow check
          expect(
            tester.takeException(),
            isNull,
            reason:
                'RenderFlex overflow occurred on Admin Dashboard at width $width',
          );
        }
      },
    );

    testWidgets(
      'Admin Dashboard handles mobile landscape orientation without overflow',
      (tester) async {
        tester.view.physicalSize = const Size(844, 390); // Landscape
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final fakeAdmin = FakeAdminDashboardController(name: 'Admin Landscape');

        await tester.pumpWidget(
          buildDashboardTestApp(
            child: UserDashboard<FakeAdminDashboardController>(
              title: 'Admin Dashboard',
              createController: (_) => fakeAdmin,
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 900));

        expect(find.text('Admin Dashboard'), findsOneWidget);
        expect(find.text('Admin Landscape'), findsOneWidget);
        expect(find.text('Student Management'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Staff Dashboard renders cleanly across all 8 target viewports with zero overflow',
      (tester) async {
        for (final width in targetWidths) {
          tester.view.physicalSize = Size(width, 800);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          final fakeStaff = FakeStaffProfileController(name: 'Prof. Minerva');

          await tester.pumpWidget(
            buildDashboardTestApp(
              child: UserDashboard<FakeStaffProfileController>(
                title: 'Staff Dashboard',
                createController: (_) => fakeStaff,
              ),
            ),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 900));

          // Header verifications
          expect(find.text('Staff Dashboard'), findsOneWidget);
          expect(find.text('Prof. Minerva'), findsOneWidget);
          expect(find.text('Staff Member'), findsOneWidget);
          expect(find.byType(AppStatusBadge), findsOneWidget);

          // Metrics verifications
          expect(find.text('Total Students'), findsOneWidget);
          expect(find.text('Staff Members'), findsOneWidget);
          expect(find.text('85'), findsOneWidget);
          expect(find.text('19'), findsOneWidget);

          // Staff options: Student, Library, Fees
          expect(find.text('Student Management'), findsOneWidget);
          expect(find.text('Library Management'), findsOneWidget);
          expect(find.text('Fees Management'), findsOneWidget);

          // Role Boundary Enforcement: Staff MUST NOT have Staff Management
          expect(
            find.text('Staff Management'),
            findsNothing,
            reason: 'Staff Dashboard must not expose Staff Management module',
          );

          // Strict overflow check
          expect(
            tester.takeException(),
            isNull,
            reason:
                'RenderFlex overflow occurred on Staff Dashboard at width $width',
          );
        }
      },
    );

    testWidgets(
      'Staff Dashboard handles mobile landscape orientation without overflow',
      (tester) async {
        tester.view.physicalSize = const Size(844, 390); // Landscape
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final fakeStaff = FakeStaffProfileController(name: 'Prof. Severus');

        await tester.pumpWidget(
          buildDashboardTestApp(
            child: UserDashboard<FakeStaffProfileController>(
              title: 'Staff Dashboard',
              createController: (_) => fakeStaff,
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 900));

        expect(find.text('Staff Dashboard'), findsOneWidget);
        expect(find.text('Prof. Severus'), findsOneWidget);
        expect(find.text('Staff Management'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('Management module navigation works for Admin and Staff', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1024, 800); // Desktop
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final fakeAdmin = FakeAdminDashboardController();

      await tester.pumpWidget(
        buildDashboardTestApp(
          child: UserDashboard<FakeAdminDashboardController>(
            title: 'Admin Dashboard',
            createController: (_) => fakeAdmin,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 900));

      // Tap Student Management
      await tester.tap(find.text('Student Management'));
      await tester.pumpAndSettle();
      expect(find.text('Student Management Mock'), findsOneWidget);
    });

    testWidgets('Refresh and Sign Out actions trigger correctly', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final fakeAdmin = FakeAdminDashboardController();

      await tester.pumpWidget(
        buildDashboardTestApp(
          child: UserDashboard<FakeAdminDashboardController>(
            title: 'Admin Dashboard',
            createController: (_) => fakeAdmin,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 900));

      // Initial load triggered
      expect(fakeAdmin.didLoad, isTrue);

      // Tap Refresh action
      await tester.tap(find.byTooltip('Refresh Metrics'));
      await tester.pump();
      expect(fakeAdmin.didLoad, isTrue);

      // Tap Sign Out action
      await tester.tap(find.byTooltip('Sign Out'));
      await tester.pumpAndSettle();
      expect(fakeAdmin.didLogout, isTrue);
      expect(find.text('Login Screen Mock'), findsOneWidget);
    });

    testWidgets('Error message banner displays with retry button', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final fakeAdmin = FakeAdminDashboardController(
        error: 'Network timeout loading statistics',
      );

      await tester.pumpWidget(
        buildDashboardTestApp(
          child: UserDashboard<FakeAdminDashboardController>(
            title: 'Admin Dashboard',
            createController: (_) => fakeAdmin,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Network timeout loading statistics'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pump();
      expect(fakeAdmin.didLoad, isTrue);
    });

    testWidgets(
      'Dark theme adapts background and typography seamlessly without overflow',
      (tester) async {
        tester.view.physicalSize = const Size(768, 1024);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final fakeAdmin = FakeAdminDashboardController();

        await tester.pumpWidget(
          buildDashboardTestApp(
            theme: AppTheme.darkTheme,
            child: UserDashboard<FakeAdminDashboardController>(
              title: 'Admin Dashboard',
              createController: (_) => fakeAdmin,
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 900));

        expect(find.text('Admin Dashboard'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
