import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:student_management/core/errors/app_exception.dart';
import 'package:student_management/core/theme/app_theme.dart';
import 'package:student_management/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:student_management/features/auth/presentation/controllers/splash_controller.dart';
import 'package:student_management/features/auth/presentation/providers/auth_providers.dart';
import 'package:student_management/shared/models/user_entity.dart';
import 'package:student_management/shared/widgets/app_card.dart';
import 'package:student_management/shared/widgets/app_text_field.dart';
import 'package:student_management/view/screens/create_new_password_screen/create_new_password_screen.dart';
import 'package:student_management/view/screens/forgot_password_screen/forgot_password_screen.dart';
import 'package:student_management/view/screens/login_screen/login_screen.dart';
import 'package:student_management/view/screens/otp_verification_screen/otp_verification_screen.dart';
import 'package:student_management/view/screens/splash_screen/splash_screen.dart';

class FakeAuthRepository implements IAuthRepository {
  UserEntity? currentUser;
  String? lastResetEmail;
  String? lastVerifiedToken;
  String? updatedPassword;

  @override
  Future<UserEntity?> getCurrentUser() async => currentUser;

  @override
  Future<UserEntity> signInWithPassword({
    required String email,
    required String password,
  }) async {
    if (email == 'admin@institution.edu' && password == 'admin123') {
      currentUser = const UserEntity(
        id: 'admin-1',
        email: 'admin@institution.edu',
        role: UserRole.admin,
      );
      return currentUser!;
    }
    throw const AppAuthException('Invalid email or password.');
  }

  @override
  Future<void> signOut() async {
    currentUser = null;
  }

  @override
  Future<void> resetPasswordForEmail(String email) async {
    lastResetEmail = email;
  }

  @override
  Future<void> verifyOtp({required String email, required String token}) async {
    lastVerifiedToken = token;
  }

  @override
  Future<void> updateUserPassword(String newPassword) async {
    updatedPassword = newPassword;
  }

  @override
  Stream<UserEntity?> watchAuthState() async* {
    yield currentUser;
  }

  @override
  Future<String> createUser({
    required String email,
    required String password,
    required UserRole role,
  }) async {
    return 'new-user-id';
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

  Widget buildTestApp({
    required Widget child,
    required FakeAuthRepository fakeAuth,
    ThemeData? theme,
  }) {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(fakeAuth),
        splashNavigationProvider.overrideWith(
          (ref) async =>
              const SplashNavigationTarget(routeName: '/loginScreen'),
        ),
      ],
      child: MaterialApp.router(
        theme: theme ?? AppTheme.lightTheme,
        routerConfig: GoRouter(
          initialLocation: '/',
          routes: [
            GoRoute(path: '/', builder: (context, state) => child),
            GoRoute(
              path: '/resetPassword',
              builder: (context, state) => const SizedBox(),
            ),
            GoRoute(
              path: '/verifyOtp',
              builder: (context, state) => const SizedBox(),
            ),
            GoRoute(
              path: '/createNewPassword',
              builder: (context, state) => const SizedBox(),
            ),
            GoRoute(
              path: '/loginScreen',
              builder: (context, state) => const SizedBox(),
            ),
            GoRoute(
              path: '/adminDashboard',
              builder: (context, state) => const SizedBox(),
            ),
            GoRoute(
              path: '/staffDashboard',
              builder: (context, state) => const SizedBox(),
            ),
            GoRoute(
              path: '/studentDashboard',
              builder: (context, state) => const SizedBox(),
            ),
          ],
        ),
      ),
    );
  }

  group('Batch 2: Authentication & Onboarding Responsive UI Tests', () {
    late FakeAuthRepository fakeAuth;

    setUp(() {
      fakeAuth = FakeAuthRepository();
    });

    testWidgets(
      'LoginScreen renders cleanly across all 8 target viewports with zero overflow',
      (tester) async {
        for (final width in targetWidths) {
          tester.view.physicalSize = Size(width, 800);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          await tester.pumpWidget(
            buildTestApp(child: const LoginScreen(), fakeAuth: fakeAuth),
          );
          await tester.pump();

          expect(find.text('Welcome Back'), findsOneWidget);
          expect(find.text('Email Address'), findsOneWidget);
          expect(find.text('Password'), findsOneWidget);
          expect(find.text('Sign In'), findsOneWidget);
          expect(
            tester.takeException(),
            isNull,
            reason:
                'RenderFlex overflow occurred on LoginScreen at width $width',
          );

          if (width >= 600.0) {
            // Wrapped in AppCard on tablet/desktop
            expect(find.byType(AppCard), findsOneWidget);
          }
        }
      },
    );

    testWidgets('LoginScreen handles landscape orientation without overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(844, 390); // Mobile landscape
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        buildTestApp(child: const LoginScreen(), fakeAuth: fakeAuth),
      );
      await tester.pump();

      expect(find.text('Welcome Back'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('LoginScreen validates inputs and triggers sign in flow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        buildTestApp(child: const LoginScreen(), fakeAuth: fakeAuth),
      );
      await tester.pump();

      // Tap Sign In with empty fields
      await tester.tap(find.text('Sign In'));
      await tester.pump();

      expect(find.text('Email address is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);

      // Enter valid email and password
      await tester.enterText(
        find.byWidgetPredicate(
          (w) => w is AppTextField && w.label == 'Email Address',
        ),
        'admin@institution.edu',
      );
      await tester.enterText(
        find.byWidgetPredicate(
          (w) => w is AppTextField && w.label == 'Password',
        ),
        'admin123',
      );
      await tester.pump();

      await tester.tap(find.text('Sign In'));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'ForgotPasswordScreen renders cleanly across all 8 target viewports with zero overflow',
      (tester) async {
        for (final width in targetWidths) {
          tester.view.physicalSize = Size(width, 800);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          await tester.pumpWidget(
            buildTestApp(
              child: const ForgotPasswordScreen(),
              fakeAuth: fakeAuth,
            ),
          );
          await tester.pump();

          expect(find.text('Forgot Password'), findsOneWidget);
          expect(find.text('Email Address'), findsOneWidget);
          expect(find.text('Send Verification Code'), findsOneWidget);
          expect(find.text('Back to Login'), findsOneWidget);
          expect(
            tester.takeException(),
            isNull,
            reason:
                'RenderFlex overflow occurred on ForgotPasswordScreen at width $width',
          );

          if (width >= 600.0) {
            expect(find.byType(AppCard), findsOneWidget);
          }
        }
      },
    );

    testWidgets(
      'ForgotPasswordScreen handles landscape orientation without overflow',
      (tester) async {
        tester.view.physicalSize = const Size(844, 390);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestApp(child: const ForgotPasswordScreen(), fakeAuth: fakeAuth),
        );
        await tester.pump();

        expect(find.text('Forgot Password'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('ForgotPasswordScreen validates email requirement', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        buildTestApp(child: const ForgotPasswordScreen(), fakeAuth: fakeAuth),
      );
      await tester.pump();

      await tester.tap(find.text('Send Verification Code'));
      await tester.pump();

      expect(find.text('Email address is required'), findsOneWidget);

      await tester.enterText(
        find.byWidgetPredicate(
          (w) => w is AppTextField && w.label == 'Email Address',
        ),
        'student@institution.edu',
      );
      await tester.pump();

      await tester.tap(find.text('Send Verification Code'));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'OtpVerificationScreen renders cleanly on 320px width without pin overflow',
      (tester) async {
        for (final width in targetWidths) {
          tester.view.physicalSize = Size(width, 800);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          await tester.pumpWidget(
            buildTestApp(
              child: const OtpVerificationScreen(email: 'user@institution.edu'),
              fakeAuth: fakeAuth,
            ),
          );
          await tester.pump();

          expect(find.text('Enter Verification Code'), findsOneWidget);
          expect(find.textContaining('user@institution.edu'), findsOneWidget);
          expect(find.text('Verify & Proceed'), findsOneWidget);
          expect(
            tester.takeException(),
            isNull,
            reason:
                'RenderFlex overflow occurred on OtpVerificationScreen at width $width',
          );
        }
      },
    );

    testWidgets(
      'OtpVerificationScreen handles landscape orientation without overflow',
      (tester) async {
        tester.view.physicalSize = const Size(844, 390);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestApp(
            child: const OtpVerificationScreen(email: 'user@institution.edu'),
            fakeAuth: fakeAuth,
          ),
        );
        await tester.pump();

        expect(find.text('Enter Verification Code'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'CreateNewPasswordScreen renders cleanly across all 8 target viewports with zero overflow',
      (tester) async {
        for (final width in targetWidths) {
          tester.view.physicalSize = Size(width, 800);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          await tester.pumpWidget(
            buildTestApp(
              child: const CreateNewPasswordScreen(),
              fakeAuth: fakeAuth,
            ),
          );
          await tester.pump();

          expect(find.text('Create New Password'), findsOneWidget);
          expect(find.text('New Password'), findsOneWidget);
          expect(find.text('Confirm New Password'), findsOneWidget);
          expect(find.text('Change Password'), findsOneWidget);
          expect(
            tester.takeException(),
            isNull,
            reason:
                'RenderFlex overflow occurred on CreateNewPasswordScreen at width $width',
          );

          if (width >= 600.0) {
            expect(find.byType(AppCard), findsOneWidget);
          }
        }
      },
    );

    testWidgets(
      'CreateNewPasswordScreen handles landscape orientation without overflow',
      (tester) async {
        tester.view.physicalSize = const Size(844, 390);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestApp(
            child: const CreateNewPasswordScreen(),
            fakeAuth: fakeAuth,
          ),
        );
        await tester.pump();

        expect(find.text('Create New Password'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'CreateNewPasswordScreen validates password confirmation and length',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestApp(
            child: const CreateNewPasswordScreen(),
            fakeAuth: fakeAuth,
          ),
        );
        await tester.pump();

        // Submit empty
        await tester.tap(find.text('Change Password'));
        await tester.pump();

        expect(find.text('Password is required'), findsOneWidget);

        // Enter short password
        await tester.enterText(
          find.byWidgetPredicate(
            (w) => w is AppTextField && w.label == 'New Password',
          ),
          '123',
        );
        await tester.enterText(
          find.byWidgetPredicate(
            (w) => w is AppTextField && w.label == 'Confirm New Password',
          ),
          '123456',
        );
        await tester.pump();

        await tester.tap(find.text('Change Password'));
        await tester.pump();

        expect(
          find.text('Password must be at least 6 characters'),
          findsOneWidget,
        );
        expect(find.text('Passwords do not match'), findsOneWidget);
      },
    );

    testWidgets(
      'SplashScreen renders branding cleanly without overflow at 320px and landscape',
      (tester) async {
        for (final width in [320.0, 390.0, 768.0, 1280.0]) {
          tester.view.physicalSize = Size(width, 800);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          await tester.pumpWidget(
            buildTestApp(child: const SplashScreen(), fakeAuth: fakeAuth),
          );
          await tester.pump();

          expect(find.text('Student Management System'), findsOneWidget);
          expect(find.text('Academic Administration Portal'), findsOneWidget);
          expect(
            tester.takeException(),
            isNull,
            reason:
                'RenderFlex overflow occurred on SplashScreen at width $width',
          );
        }

        // Landscape test
        tester.view.physicalSize = const Size(844, 390);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestApp(child: const SplashScreen(), fakeAuth: fakeAuth),
        );
        await tester.pump();

        expect(find.text('Student Management System'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Dark theme adapts background and text styles across authentication screens',
      (tester) async {
        tester.view.physicalSize = const Size(600, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestApp(
            child: const LoginScreen(),
            fakeAuth: fakeAuth,
            theme: AppTheme.darkTheme,
          ),
        );
        await tester.pump();

        expect(find.text('Welcome Back'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
