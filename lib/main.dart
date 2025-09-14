import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:student_management/controller/create_new_password_controller.dart';
import 'package:student_management/services/nav_service.dart';
import 'package:student_management/view/screens/create_new_password_screen/create_new_password_screen.dart';


import 'package:supabase_flutter/supabase_flutter.dart';

// Controllers
import 'package:student_management/controller/borrow_book_controller.dart';
import 'package:student_management/controller/library_history_controller.dart';
import 'package:student_management/controller/login_screen_controller.dart';
import 'package:student_management/controller/return_book_controller.dart';
import 'package:student_management/controller/search_book_provider.dart';
import 'package:student_management/controller/splash_screen_controller.dart';
import 'package:student_management/controller/staff_form_page_controller.dart';
import 'package:student_management/controller/staff_management_controller.dart';
import 'package:student_management/controller/student_form_page_controller.dart';
import 'package:student_management/controller/student_management_controller.dart';
import 'package:student_management/controller/admin_dashboard_controller.dart';
import 'package:student_management/controller/staff_profile_controller.dart';
import 'package:student_management/controller/forgot_password_screen_controller.dart';
import 'package:student_management/controller/otp_verification_controller.dart';
import 'package:student_management/controller/student_bottom_navigation_controller.dart';
import 'package:student_management/controller/student_dashboard_controller.dart';

// Services
import 'package:student_management/services/borrow_book_services.dart';
import 'package:student_management/services/staff_service.dart';
import 'package:student_management/services/student_services.dart';
import 'package:student_management/services/user_service.dart';

// Screens
import 'package:student_management/view/screens/admin_dashboard/user_dashboard_screen.dart';
import 'package:student_management/view/screens/borrow_screen/borrow_book_screen.dart';
import 'package:student_management/view/screens/library_dashboard/library_management_screen.dart';
import 'package:student_management/view/screens/library_history_screen/library_history_screen.dart';
import 'package:student_management/view/screens/login_screen/login_screen.dart';
import 'package:student_management/view/screens/return_book_screen/return_book_screen.dart';
import 'package:student_management/view/screens/splash_screen/splash_screen.dart';
import 'package:student_management/view/screens/user_form_page/user_form_page_screen.dart';
import 'package:student_management/view/screens/user_management/user_management_screen.dart';
import 'package:student_management/view/screens/forgot_password_screen/forgot_password_screen.dart';
import 'package:student_management/view/screens/student_tab_screen/student_tab_screen.dart';
import 'package:student_management/view/screens/otp_verification_screen/otp_verification_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANONKEY']!,
   authOptions: FlutterAuthClientOptions(detectSessionInUri: false),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Base services
        Provider<UserService>(create: (_) => UserService()),
        Provider<StudentService>(
          create: (ctx) => StudentService(userService: ctx.read<UserService>()),
        ),
        Provider<StaffService>(
          create: (ctx) => StaffService(userService: ctx.read<UserService>()),
        ),
        Provider<BorrowBookService>(create: (_) => BorrowBookService()),

        // App-wide controllers
        ChangeNotifierProvider(create: (_) => SplashScreenController()),
        ChangeNotifierProvider(
          create:
              (ctx) =>
                  LoginScreenController(userService: ctx.read<UserService>()),
        ),
        ChangeNotifierProvider(create: (_) => StudentFormPageController()),
        ChangeNotifierProvider(create: (_) => StaffFormPageController()),
        ChangeNotifierProvider(create: (_) => LibraryHistoryController()),
        ChangeNotifierProvider(create: (_) => ReturnBookController()),
        ChangeNotifierProvider(create: (_) => StudentBottomNavController()),
        ChangeNotifierProvider<BorrowBookController>(
          create:
              (ctx) => BorrowBookController(
                ctx.read<StudentService>(),
                ctx.read<BorrowBookService>(),
              ),
        ),
        ChangeNotifierProxyProvider<BorrowBookController, SearchBookProvider>(
          create: (_) => SearchBookProvider(),
          lazy: false,
          update: (_, borrowController, searchProvider) {
            searchProvider!.initListener(borrowController);
            return searchProvider;
          },
        ),
      ],
      child: MaterialApp(
        navigatorKey: NavService.navigatorKey,
        title: 'Student Management System',
        theme:ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF667EEA)),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF667EEA), // purple fill
        foregroundColor: Colors.white,            // text/spinner/icon color
        textStyle: const TextStyle(
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 2,
      ),
    ),
  ),
  
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/loginScreen': (context) => const LoginScreen(),
          '/adminDashboard': (context) => UserDashboard<AdminDashboardController>(
  title: 'Admin Dashboard',
  createController: (_) => AdminDashboardController(),
),


'/staffDashboard': (context) => UserDashboard<StaffProfileController>(
  title: 'Staff Dashboard',
  createController: (_) => StaffProfileController(),
),


          // Student Management: wrap with provider here
          '/studentManagement':
              (context) => ChangeNotifierProvider<StudentManagementController>(
                create: (ctx) {
                  final ctrl = StudentManagementController(
                    studentService: ctx.read<StudentService>(),
                  );
                  ctrl.fetchUsers();
                  return ctrl;
                },
                child: const UserManagementScreen<StudentManagementController>(
                  userType: 'student',
                  title: 'Student Management',
                  showSort: true,
                  formRoute: '/userForm',
                ),
              ),

          // Staff Management: wrap with provider here
          '/staffManagement':
              (context) => ChangeNotifierProvider<StaffManagementController>(
                create: (ctx) {
                  final ctrl = StaffManagementController(
                    staffService: ctx.read<StaffService>(),
                  );
                  ctrl.fetchUsers();
                  return ctrl;
                },
                child: const UserManagementScreen<StaffManagementController>(
                  userType: 'staff',
                  title: 'Staff Management',
                  showSort: false,
                  formRoute: '/userForm',
                ),
              ),

          // Shared user form route (with role and data from args)
          '/userForm': (context) {
            final args =
                ModalRoute.of(context)?.settings.arguments
                    as Map<String, dynamic>? ??
                {};
            final String role = args['role'] ?? 'student';
            final dynamic data = args['data'];

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

          '/libraryManagement': (context) => const LibraryManagement(),
          '/borrowBook': (context) => BorrowBookScreen(),
          '/libraryHistory': (context) => const LibraryHistoryScreen(),
          '/returnBook':
              (context) => ChangeNotifierProvider(
                create: (_) => ReturnBookController(),
                child: const ReturnBookScreen(),
              ),

    '/studentDashboard': (context) {
  final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
  final id = args['studentId'] as String? ?? '';
  if (id.isEmpty) {
    return const Scaffold(body: Center(child: Text('Missing or invalid studentId')));
  }
  // 👇 true if you’re filtering library by auth.uid (most common case)
  return ChangeNotifierProvider(
    create: (_) => StudentDashboardController()..load(),
    child: StudentTabsShell(id: id, filterByUserId: true),
  );
},'/resetPassword': (context) => ChangeNotifierProvider(
    create: (_) => ForgotPasswordScreenController(),
    child: const ForgotPasswordScreen(),
  ),



 '/verifyOtp': (context) {
  final settings = ModalRoute.of(context)?.settings;
  final args = (settings?.arguments as Map?) ?? const {};
  final email = (args['email'] as String?) ?? '';
  debugPrint('/verifyOtp route built for $email');

  return ChangeNotifierProvider(
    create: (_) => OtpVerificationController(email: email, initialCooldown: 60),
    child: const OtpVerificationScreen(),
  );
},

'/createNewPassword': (context) => ChangeNotifierProvider(
  create: (_) => CreateNewPasswordController(),
  child: const CreateNewPasswordScreen(),
),


        },
      ),
    );
  }
}
