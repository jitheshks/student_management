import 'package:material_ui/material_ui.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
import 'package:supabase_flutter/supabase_flutter.dart';

// Routing
import 'package:student_management/core/routing/app_router.dart';
import 'package:student_management/core/theme/app_theme.dart';
import 'package:student_management/shared/widgets/global_connectivity_banner.dart';

// Controllers
import 'package:student_management/controller/borrow_book_controller.dart';
import 'package:student_management/controller/library_history_controller.dart';
import 'package:student_management/controller/login_screen_controller.dart';
import 'package:student_management/controller/return_book_controller.dart';
import 'package:student_management/controller/search_book_provider.dart';
import 'package:student_management/controller/splash_screen_controller.dart';
import 'package:student_management/controller/staff_form_page_controller.dart';
import 'package:student_management/controller/student_form_page_controller.dart';
import 'package:student_management/controller/student_bottom_navigation_controller.dart';

// Services
import 'package:student_management/services/borrow_book_services.dart';
import 'package:student_management/services/staff_service.dart';
import 'package:student_management/services/student_services.dart';
import 'package:student_management/services/user_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  final supabaseKey =
      dotenv.env['SUPABASE_ANON_KEY'] ??
      dotenv.env['SUPABASE_PUBLISHABLE_KEY'] ??
      dotenv.env['SUPABASE_ANONKEY'] ??
      '';

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseKey,
    authOptions: const FlutterAuthClientOptions(detectSessionInUri: false),
  );

  runApp(const ProviderScope(child: MyApp()));
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
      child: MaterialApp.router(
        routerConfig: appRouter,
        title: 'Student Management System',
        builder:
            (context, child) => GlobalConnectivityBanner(
              child: child ?? const SizedBox.shrink(),
            ),
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
      ),
    );
  }
}
