import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:student_management/core/constants/app_radius.dart';
import 'package:student_management/core/constants/app_spacing.dart';
import 'package:student_management/core/theme/app_colors.dart';
import 'package:student_management/core/utils/input_validators.dart';
import 'package:student_management/features/auth/presentation/controllers/forgot_password_controller.dart';
import 'package:student_management/shared/widgets/app_button.dart';
import 'package:student_management/shared/widgets/app_card.dart';
import 'package:student_management/shared/widgets/app_text_field.dart';
import 'package:student_management/shared/widgets/responsive_content.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleRequestOtp() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final email = _emailController.text.trim();
    final success = await ref
        .read(forgotPasswordControllerProvider.notifier)
        .sendResetOtp(email);

    if (success && mounted) {
      context.push('/verifyOtp', extra: {'email': email});
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(forgotPasswordControllerProvider);
    final isLoading = state.isLoading;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isWide =
        AppBreakpoints.isTablet(context) || AppBreakpoints.isDesktop(context);

    ref.listen<AsyncValue<void>>(forgotPasswordControllerProvider, (
      prev,
      next,
    ) {
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
          Center(
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color:
                    isDark
                        ? AppColors.warning.withValues(alpha: 0.2)
                        : AppColors.warningContainer,
                borderRadius: BorderRadius.circular(AppRadius.r14),
                border: Border.all(
                  color:
                      isDark
                          ? AppColors.warning.withValues(alpha: 0.4)
                          : AppColors.warning.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Icon(
                Icons.lock_reset_rounded,
                size: 30,
                color: isDark ? AppColors.warning : AppColors.warning,
              ),
            ),
          ),
          AppSpacing.gapH20,
          Text(
            'Forgot Password',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          AppSpacing.gapH8,
          Text(
            'Enter the email address associated with your account to receive a 6-digit recovery code.',
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
          AppSpacing.gapH24,
          AppButton(
            text: 'Send Verification Code',
            isLoading: isLoading,
            onPressed: isLoading ? null : _handleRequestOtp,
            icon: Icons.send_rounded,
          ),
          AppSpacing.gapH16,
          Center(
            child: TextButton.icon(
              onPressed: () {
                context.pop();
              },
              icon: Icon(
                Icons.arrow_back_rounded,
                size: 16,
                color: isDark ? AppColors.primaryLight : AppColors.primary,
              ),
              label: Text(
                'Back to Login',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.primaryLight : AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
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
