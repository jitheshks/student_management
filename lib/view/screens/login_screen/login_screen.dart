import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:student_management/core/constants/app_radius.dart';
import 'package:student_management/core/constants/app_spacing.dart';
import 'package:student_management/core/theme/app_colors.dart';
import 'package:student_management/core/utils/input_validators.dart';
import 'package:student_management/features/auth/presentation/controllers/login_controller.dart';
import 'package:student_management/shared/models/user_entity.dart';
import 'package:student_management/shared/widgets/app_button.dart';
import 'package:student_management/shared/widgets/app_card.dart';
import 'package:student_management/shared/widgets/app_text_field.dart';
import 'package:student_management/shared/widgets/responsive_content.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final userEntity = await ref
        .read(loginControllerProvider.notifier)
        .login(
          email: _emailController.text,
          password: _passwordController.text,
        );

    if (userEntity != null && mounted) {
      switch (userEntity.role) {
        case UserRole.admin:
          context.go('/adminDashboard');
          break;
        case UserRole.staff:
          context.go('/staffDashboard');
          break;
        case UserRole.student:
          context.go('/studentDashboard', extra: {'studentId': userEntity.id});
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loginState = ref.watch(loginControllerProvider);
    final isLoading = loginState.isLoading;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isWide =
        AppBreakpoints.isTablet(context) || AppBreakpoints.isDesktop(context);

    ref.listen<AsyncValue<void>>(loginControllerProvider, (prev, next) {
      if (next.hasError && !next.isLoading) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error.toString()),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    Widget formContent = Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Institutional Logo / Badge
          Center(
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color:
                    isDark
                        ? AppColors.primaryDark.withValues(alpha: 0.2)
                        : AppColors.primarySurface,
                borderRadius: BorderRadius.circular(AppRadius.r14),
                border: Border.all(
                  color:
                      isDark
                          ? AppColors.primaryLight.withValues(alpha: 0.3)
                          : AppColors.primaryLight.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
              child: Icon(
                Icons.school_rounded,
                size: 30,
                color: isDark ? AppColors.primaryLight : AppColors.primary,
              ),
            ),
          ),
          AppSpacing.gapH20,
          Text(
            'Welcome Back',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          AppSpacing.gapH8,
          Text(
            'Sign in to access your academic portal',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color:
                  isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          AppSpacing.gapH32,
          AppTextField(
            controller: _emailController,
            label: 'Email Address',
            hintText: 'name@institution.edu',
            prefixIcon: Icon(
              Icons.email_outlined,
              size: 20,
              color: isDark ? AppColors.slate400 : AppColors.slate500,
            ),
            keyboardType: TextInputType.emailAddress,
            validator: InputValidators.validateEmail,
          ),
          AppSpacing.gapH16,
          AppTextField(
            controller: _passwordController,
            label: 'Password',
            hintText: 'Enter your password',
            prefixIcon: Icon(
              Icons.lock_outline_rounded,
              size: 20,
              color: isDark ? AppColors.slate400 : AppColors.slate500,
            ),
            isPassword: true,
            validator:
                (val) => InputValidators.validatePassword(val, minLength: 6),
          ),
          AppSpacing.gapH8,
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                context.push('/resetPassword');
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s8,
                  vertical: AppSpacing.s4,
                ),
                visualDensity: VisualDensity.compact,
              ),
              child: Text(
                'Forgot Password?',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.primaryLight : AppColors.primary,
                ),
              ),
            ),
          ),
          AppSpacing.gapH20,
          AppButton(
            text: 'Sign In',
            isLoading: isLoading,
            onPressed: isLoading ? null : _handleLogin,
            icon: Icons.login_rounded,
          ),
          AppSpacing.gapH16,
          Center(
            child: Text(
              'Secure Academic Management System',
              style: TextStyle(
                fontSize: 12,
                color:
                    isDark
                        ? AppColors.textTertiaryDark
                        : AppColors.textTertiary,
              ),
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s16,
              vertical: AppSpacing.s24,
            ),
            child: ResponsiveContent.form(
              padding: EdgeInsets.zero,
              child:
                  isWide
                      ? AppCard(
                        padding: AppSpacing.paddingA32,
                        borderRadius: AppRadius.r20,
                        elevation: 2.0,
                        child: formContent,
                      )
                      : formContent,
            ),
          ),
        ),
      ),
    );
  }
}
