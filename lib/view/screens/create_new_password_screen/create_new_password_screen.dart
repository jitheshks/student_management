import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:student_management/core/constants/app_radius.dart';
import 'package:student_management/core/constants/app_spacing.dart';
import 'package:student_management/core/theme/app_colors.dart';
import 'package:student_management/core/utils/input_validators.dart';
import 'package:student_management/features/auth/presentation/controllers/create_new_password_controller.dart';
import 'package:student_management/shared/widgets/app_button.dart';
import 'package:student_management/shared/widgets/app_card.dart';
import 'package:student_management/shared/widgets/app_text_field.dart';
import 'package:student_management/shared/widgets/responsive_content.dart';

class CreateNewPasswordScreen extends ConsumerStatefulWidget {
  const CreateNewPasswordScreen({super.key});

  @override
  ConsumerState<CreateNewPasswordScreen> createState() =>
      _CreateNewPasswordScreenState();
}

class _CreateNewPasswordScreenState
    extends ConsumerState<CreateNewPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _passwordNode = FocusNode();
  final _confirmNode = FocusNode();

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    _passwordNode.dispose();
    _confirmNode.dispose();
    super.dispose();
  }

  Future<void> _handleChangePassword() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final success = await ref
        .read(createNewPasswordControllerProvider.notifier)
        .resetPassword(
          newPassword: _passwordController.text,
          confirmPassword: _confirmController.text,
        );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password changed successfully. Please log in.'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.go('/loginScreen');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createNewPasswordControllerProvider);
    final isSubmitting = state.isLoading;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isWide =
        AppBreakpoints.isTablet(context) || AppBreakpoints.isDesktop(context);

    ref.listen<AsyncValue<void>>(createNewPasswordControllerProvider, (
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
                        ? AppColors.success.withValues(alpha: 0.2)
                        : AppColors.successContainer,
                borderRadius: BorderRadius.circular(AppRadius.r14),
                border: Border.all(
                  color:
                      isDark
                          ? AppColors.success.withValues(alpha: 0.4)
                          : AppColors.success.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Icon(
                Icons.vpn_key_rounded,
                size: 30,
                color: isDark ? AppColors.success : AppColors.success,
              ),
            ),
          ),
          AppSpacing.gapH20,
          Text(
            'Create New Password',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          AppSpacing.gapH8,
          Text(
            'Your new password must be at least 6 characters and different from previous passwords.',
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
            controller: _passwordController,
            label: 'New Password',
            hintText: 'At least 6 characters',
            prefixIcon: Icon(
              Icons.lock_outline_rounded,
              size: 20,
              color: isDark ? AppColors.slate400 : AppColors.slate500,
            ),
            isPassword: true,
            focusNode: _passwordNode,
            validator: (v) => InputValidators.validatePassword(v, minLength: 6),
          ),
          AppSpacing.gapH16,
          AppTextField(
            controller: _confirmController,
            label: 'Confirm New Password',
            hintText: 'Re-enter your password',
            prefixIcon: Icon(
              Icons.lock_reset_rounded,
              size: 20,
              color: isDark ? AppColors.slate400 : AppColors.slate500,
            ),
            isPassword: true,
            focusNode: _confirmNode,
            validator: (v) {
              final val = v?.trim() ?? '';
              if (val.isEmpty) return 'Please confirm your password';
              if (val != _passwordController.text.trim()) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
          AppSpacing.gapH24,
          AppButton(
            text: 'Change Password',
            isLoading: isSubmitting,
            onPressed: isSubmitting ? null : _handleChangePassword,
            icon: Icons.check_circle_outline_rounded,
          ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Update Password'),
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
