import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Services & Navigation
import 'package:student_management/services/nav_service.dart';

// Controllers
import 'package:student_management/controller/admin_dashboard_controller.dart';
import 'package:student_management/controller/staff_profile_controller.dart';
import 'package:student_management/controller/student_dashboard_controller.dart';
import 'package:student_management/controller/student_form_page_controller.dart';
import 'package:student_management/controller/staff_form_page_controller.dart';

// Domain Models
import 'package:student_management/shared/models/student.dart';
import 'package:student_management/shared/models/staff.dart';

// Features - Screens
import 'package:student_management/features/students/presentation/screens/student_list_screen.dart';
import 'package:student_management/features/students/presentation/screens/student_form_screen.dart';
import 'package:student_management/features/staff/presentation/screens/staff_list_screen.dart';
import 'package:student_management/features/staff/presentation/screens/staff_form_screen.dart';
import 'package:student_management/features/library/presentation/screens/library_management_screen.dart';
import 'package:student_management/features/library/presentation/screens/borrow_book_screen.dart';
import 'package:student_management/features/library/presentation/screens/return_book_screen.dart';
import 'package:student_management/features/library/presentation/screens/library_history_screen.dart';
import 'package:student_management/features/fees/presentation/screens/fees_dashboard_screen.dart';

// View - Auth & Dashboards
import 'package:student_management/view/screens/splash_screen/splash_screen.dart';
import 'package:student_management/view/screens/login_screen/login_screen.dart';
import 'package:student_management/view/screens/admin_dashboard/user_dashboard_screen.dart';
import 'package:student_management/view/screens/forgot_password_screen/forgot_password_screen.dart';
import 'package:student_management/view/screens/otp_verification_screen/otp_verification_screen.dart';
import 'package:student_management/view/screens/create_new_password_screen/create_new_password_screen.dart';
import 'package:student_management/view/screens/student_tab_screen/student_tab_screen.dart';
import 'package:student_management/view/screens/user_form_page/user_form_page_screen.dart';

/// Strongly typed identity object ensuring strict separation between
/// the authenticated Supabase auth UUID and the student profile record ID.
class StudentSessionIdentity {
  final String authUserId;
  final String? studentProfileId;

  const StudentSessionIdentity({
    required this.authUserId,
    this.studentProfileId,
  });
}

/// Authoritative session and role resolution.
/// Ensures role is established strictly from PostgreSQL public.users.
/// If the database profile record is missing, deleted, or unprovisioned,
/// access fails closed immediately. Stale JWT claims and local storage
/// are never permitted to grant privileges.
/// Fails closed (returns nulls) if unauthenticated, expired, missing profile, or on database error.
Future<({String? role, String? userId})> resolveAuthSession({
  SupabaseClient? clientOverride,
  SharedPreferences? prefsOverride,
}) async {
  try {
    SupabaseClient? client = clientOverride;
    if (client == null) {
      try {
        client = Supabase.instance.client;
      } catch (_) {
        client = null;
      }
    }

    if (client == null) {
      return (role: null, userId: null);
    }

    final session = client.auth.currentSession;
    if (session == null || session.isExpired) {
      return (role: null, userId: null);
    }

    final userId = session.user.id;
    if (userId.isEmpty) {
      return (role: null, userId: null);
    }

    String? authoritativeRole;

    // 1. Authoritative PostgreSQL public.users record scoped strictly to session.user.id
    try {
      final response =
          await client
              .from('users')
              .select('role')
              .eq('id', userId)
              .maybeSingle();

      // If the user profile record does not exist in the database,
      // fail closed immediately. A missing or deleted profile MUST NOT receive
      // privileges from stale JWT claims or local storage.
      if (response == null || response['role'] == null) {
        return (role: null, userId: null);
      }

      final dbRole = response['role'].toString().trim().toLowerCase();
      if (dbRole.isEmpty) {
        return (role: null, userId: null);
      }

      authoritativeRole = dbRole;
    } catch (e) {
      debugPrint('[resolveAuthSession] Database role query failed: $e');
      // Fail closed: if database query fails or times out, safely deny access.
      return (role: null, userId: null);
    }

    // 2. Sync verified authoritative role to SharedPreferences for client-side cache consistency
    try {
      final prefs = prefsOverride ?? await SharedPreferences.getInstance();
      await prefs.setString('userRole', authoritativeRole);
      await prefs.setString('user_id', userId);
    } catch (_) {}

    return (role: authoritativeRole, userId: userId);
  } catch (e) {
    debugPrint('[resolveAuthSession] Error: $e');
    return (role: null, userId: null);
  }
}

/// Route guard for Admin-only routes.
/// (/adminDashboard, /staffManagement, /staffList, /staffForm)
Future<String?> adminGuard(
  BuildContext? context,
  GoRouterState state, {
  SupabaseClient? clientOverride,
  SharedPreferences? prefsOverride,
}) async {
  final auth = await resolveAuthSession(
    clientOverride: clientOverride,
    prefsOverride: prefsOverride,
  );

  if (auth.userId == null || auth.role == null) {
    return '/loginScreen';
  }

  switch (auth.role) {
    case 'admin':
      return null;
    case 'staff':
      return '/staffDashboard';
    case 'student':
      return '/studentDashboard?studentId=${auth.userId}';
    default:
      return '/loginScreen';
  }
}

/// Route guard for Staff-only routes.
/// (/staffDashboard)
Future<String?> staffGuard(
  BuildContext? context,
  GoRouterState state, {
  SupabaseClient? clientOverride,
  SharedPreferences? prefsOverride,
}) async {
  final auth = await resolveAuthSession(
    clientOverride: clientOverride,
    prefsOverride: prefsOverride,
  );

  if (auth.userId == null || auth.role == null) {
    return '/loginScreen';
  }

  switch (auth.role) {
    case 'staff':
      return null;
    case 'admin':
      return '/adminDashboard';
    case 'student':
      return '/studentDashboard?studentId=${auth.userId}';
    default:
      return '/loginScreen';
  }
}

/// Route guard for shared Admin and Staff routes.
/// (/studentManagement, /studentList, /studentForm, /userForm,
///  /libraryManagement, /borrowBook, /returnBook, /libraryHistory, /feesDashboard)
Future<String?> staffOrAdminGuard(
  BuildContext? context,
  GoRouterState state, {
  SupabaseClient? clientOverride,
  SharedPreferences? prefsOverride,
}) async {
  final auth = await resolveAuthSession(
    clientOverride: clientOverride,
    prefsOverride: prefsOverride,
  );

  if (auth.userId == null || auth.role == null) {
    return '/loginScreen';
  }

  switch (auth.role) {
    case 'admin':
    case 'staff':
      return null;
    case 'student':
      return '/studentDashboard?studentId=${auth.userId}';
    default:
      return '/loginScreen';
  }
}

/// Route guard for Student-only portal route.
/// (/studentDashboard)
Future<String?> studentPortalGuard(
  BuildContext? context,
  GoRouterState state, {
  SupabaseClient? clientOverride,
  SharedPreferences? prefsOverride,
}) async {
  final auth = await resolveAuthSession(
    clientOverride: clientOverride,
    prefsOverride: prefsOverride,
  );

  if (auth.userId == null || auth.role == null) {
    return '/loginScreen';
  }

  switch (auth.role) {
    case 'student':
      return null;
    case 'admin':
      return '/adminDashboard';
    case 'staff':
      return '/staffDashboard';
    default:
      return '/loginScreen';
  }
}

/// Route-level authorization guard for Staff Management routes.
/// Retained for backwards compatibility with existing tests and references.
Future<String?> staffManagementGuard(
  BuildContext? context,
  GoRouterState state, {
  SupabaseClient? clientOverride,
  SharedPreferences? prefsOverride,
}) => adminGuard(
  context,
  state,
  clientOverride: clientOverride,
  prefsOverride: prefsOverride,
);

GoRouter createAppRouter({
  GlobalKey<NavigatorState>? navigatorKey,
  String initialLocation = '/',
  SupabaseClient? clientOverride,
  SharedPreferences? prefsOverride,
}) {
  return GoRouter(
    navigatorKey: navigatorKey ?? NavService.navigatorKey,
    initialLocation: initialLocation,
    routes: <RouteBase>[
      // Splash
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Authentication
      GoRoute(
        path: '/loginScreen',
        name: 'loginScreen',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/resetPassword',
        name: 'resetPassword',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/verifyOtp',
        name: 'verifyOtp',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final email =
              extra?['email'] as String? ??
              state.uri.queryParameters['email'] ??
              '';
          return OtpVerificationScreen(email: email);
        },
      ),
      GoRoute(
        path: '/createNewPassword',
        name: 'createNewPassword',
        builder: (context, state) => const CreateNewPasswordScreen(),
      ),

      // Admin & Staff Dashboards
      GoRoute(
        path: '/adminDashboard',
        name: 'adminDashboard',
        redirect:
            (context, state) => adminGuard(
              context,
              state,
              clientOverride: clientOverride,
              prefsOverride: prefsOverride,
            ),
        builder:
            (context, state) => UserDashboard<AdminDashboardController>(
              title: 'Admin Dashboard',
              createController: (_) => AdminDashboardController(),
            ),
      ),
      GoRoute(
        path: '/staffDashboard',
        name: 'staffDashboard',
        redirect:
            (context, state) => staffGuard(
              context,
              state,
              clientOverride: clientOverride,
              prefsOverride: prefsOverride,
            ),
        builder:
            (context, state) => UserDashboard<StaffProfileController>(
              title: 'Staff Dashboard',
              createController: (_) => StaffProfileController(),
            ),
      ),

      // Student Dashboard
      GoRoute(
        path: '/studentDashboard',
        name: 'studentDashboard',
        redirect:
            (context, state) => studentPortalGuard(
              context,
              state,
              clientOverride: clientOverride,
              prefsOverride: prefsOverride,
            ),
        builder: (context, state) {
          SupabaseClient? client = clientOverride;
          if (client == null) {
            try {
              client = Supabase.instance.client;
            } catch (_) {
              client = null;
            }
          }

          final authUserId = client?.auth.currentUser?.id ?? '';
          if (authUserId.isEmpty) {
            return const Scaffold(
              body: Center(child: Text('Missing authenticated student session')),
            );
          }

          return ChangeNotifierProvider(
            create: (_) => StudentDashboardController()..load(),
            child: StudentTabsShell(
              id: authUserId,
              authUserId: authUserId,
              filterByUserId: true,
            ),
          );
        },
      ),

      // Student Management (resolves to modern Riverpod Student screens)
      GoRoute(
        path: '/studentManagement',
        name: 'studentManagement',
        redirect:
            (context, state) => staffOrAdminGuard(
              context,
              state,
              clientOverride: clientOverride,
              prefsOverride: prefsOverride,
            ),
        builder: (context, state) => const StudentListScreen(),
      ),
      GoRoute(
        path: '/studentList',
        name: 'studentList',
        redirect:
            (context, state) => staffOrAdminGuard(
              context,
              state,
              clientOverride: clientOverride,
              prefsOverride: prefsOverride,
            ),
        builder: (context, state) => const StudentListScreen(),
      ),
      GoRoute(
        path: '/studentForm',
        name: 'studentForm',
        redirect:
            (context, state) => staffOrAdminGuard(
              context,
              state,
              clientOverride: clientOverride,
              prefsOverride: prefsOverride,
            ),
        builder: (context, state) {
          final student = state.extra as Student?;
          return StudentFormScreen(initialStudent: student);
        },
      ),

      // Staff Management (resolves to modern Riverpod Staff screens)
      GoRoute(
        path: '/staffManagement',
        name: 'staffManagement',
        redirect:
            (context, state) => staffManagementGuard(
              context,
              state,
              clientOverride: clientOverride,
              prefsOverride: prefsOverride,
            ),
        builder: (context, state) => const StaffListScreen(),
      ),
      GoRoute(
        path: '/staffList',
        name: 'staffList',
        redirect:
            (context, state) => staffManagementGuard(
              context,
              state,
              clientOverride: clientOverride,
              prefsOverride: prefsOverride,
            ),
        builder: (context, state) => const StaffListScreen(),
      ),
      GoRoute(
        path: '/staffForm',
        name: 'staffForm',
        redirect:
            (context, state) => staffManagementGuard(
              context,
              state,
              clientOverride: clientOverride,
              prefsOverride: prefsOverride,
            ),
        builder: (context, state) {
          final staff = state.extra as Staff?;
          return StaffFormScreen(initialStaff: staff);
        },
      ),

      // Legacy User Form router support (with arguments compatibility)
      GoRoute(
        path: '/userForm',
        name: 'userForm',
        redirect:
            (context, state) => staffOrAdminGuard(
              context,
              state,
              clientOverride: clientOverride,
              prefsOverride: prefsOverride,
            ),
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final String role = extra['role'] as String? ?? 'student';
          final dynamic data = extra['data'];

          if (role == 'student') {
            return ChangeNotifierProvider(
              create: (_) => StudentFormPageController(),
              child: UserFormPageScreen(role: role, data: data),
            );
          } else if (role == 'staff') {
            return ChangeNotifierProvider(
              create: (_) => StaffFormPageController(),
              child: UserFormPageScreen(role: role, data: data),
            );
          } else {
            return const Scaffold(body: Center(child: Text('Invalid role')));
          }
        },
      ),

      // Library Management (resolves to modern Riverpod Library screens)
      GoRoute(
        path: '/libraryManagement',
        name: 'libraryManagement',
        redirect:
            (context, state) => staffOrAdminGuard(
              context,
              state,
              clientOverride: clientOverride,
              prefsOverride: prefsOverride,
            ),
        builder: (context, state) => const LibraryManagementScreen(),
      ),
      GoRoute(
        path: '/borrowBook',
        name: 'borrowBook',
        redirect:
            (context, state) => staffOrAdminGuard(
              context,
              state,
              clientOverride: clientOverride,
              prefsOverride: prefsOverride,
            ),
        builder: (context, state) => const BorrowBookScreen(),
      ),
      GoRoute(
        path: '/returnBook',
        name: 'returnBook',
        redirect:
            (context, state) => staffOrAdminGuard(
              context,
              state,
              clientOverride: clientOverride,
              prefsOverride: prefsOverride,
            ),
        builder: (context, state) => const ReturnBookScreen(),
      ),
      GoRoute(
        path: '/libraryHistory',
        name: 'libraryHistory',
        redirect:
            (context, state) => staffOrAdminGuard(
              context,
              state,
              clientOverride: clientOverride,
              prefsOverride: prefsOverride,
            ),
        builder: (context, state) => const LibraryHistoryScreen(),
      ),

      // Fees Dashboard
      GoRoute(
        path: '/feesDashboard',
        name: 'feesDashboard',
        redirect:
            (context, state) => staffOrAdminGuard(
              context,
              state,
              clientOverride: clientOverride,
              prefsOverride: prefsOverride,
            ),
        builder: (context, state) => const FeesDashboardScreen(),
      ),
    ],
  );
}

final GoRouter appRouter = createAppRouter();
