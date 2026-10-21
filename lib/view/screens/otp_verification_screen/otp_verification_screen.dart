import 'dart:math' as math;
import 'package:flutter/material.dart' as flutter_mat;
import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pinput/pinput.dart';
import 'package:student_management/core/constants/app_radius.dart';
import 'package:student_management/core/constants/app_spacing.dart';
import 'package:student_management/core/theme/app_colors.dart';
import 'package:student_management/features/auth/presentation/controllers/otp_verification_controller.dart';
import 'package:student_management/shared/widgets/app_button.dart';
import 'package:student_management/shared/widgets/app_card.dart';
import 'package:student_management/shared/widgets/responsive_content.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  final String? email;

  const OtpVerificationScreen({super.key, this.email});

  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  final _pinController = TextEditingController();

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  String _formatCooldown(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(1, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return seconds >= 60 ? '$m:$s' : s;
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    final email = widget.email ?? ((args?['email'] as String?) ?? '');

    final otpState = ref.watch(otpVerificationControllerProvider(email));
    final controller = ref.read(
      otpVerificationControllerProvider(email).notifier,
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isWide =
        AppBreakpoints.isTablet(context) || AppBreakpoints.isDesktop(context);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Security Verification'),
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
              child: Material(
                color: Colors.transparent,
                child:
                    isWide
                        ? AppCard(
                          padding: AppSpacing.paddingA32,
                          borderRadius: AppRadius.r20,
                          elevation: 2.0,
                          child: _buildBody(
                            context,
                            email,
                            otpState,
                            controller,
                            isDark,
                          ),
                        )
                        : _buildBody(
                          context,
                          email,
                          otpState,
                          controller,
                          isDark,
                        ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    String email,
    OtpState otpState,
    OtpVerificationController controller,
    bool isDark,
  ) {
    return Column(
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
                      ? AppColors.info.withValues(alpha: 0.2)
                      : AppColors.infoContainer,
              borderRadius: BorderRadius.circular(AppRadius.r14),
              border: Border.all(
                color:
                    isDark
                        ? AppColors.info.withValues(alpha: 0.4)
                        : AppColors.info.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Icon(
              Icons.mark_email_read_rounded,
              size: 30,
              color: isDark ? AppColors.info : AppColors.info,
            ),
          ),
        ),
        AppSpacing.gapH20,
        Text(
          'Enter Verification Code',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
          textAlign: TextAlign.center,
        ),
        AppSpacing.gapH8,
        Text(
          email.isNotEmpty
              ? 'We have sent a 6-digit verification code to:\n$email'
              : 'Please enter the 6-digit code sent to your email address.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color:
                isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
          ),
        ),
        AppSpacing.gapH24,
        // Responsive Pinput width calculator ensuring zero overflow on 320px
        LayoutBuilder(
          builder: (context, constraints) {
            final availableWidth = constraints.maxWidth;
            // 6 cells with 5 gaps. Min gap is 4, preferred gap is 8.
            final pinWidth = math.min(
              48.0,
              math.max(38.0, (availableWidth - 50) / 6),
            );
            final pinHeight = pinWidth * 1.15;

            final defaultPinTheme = PinTheme(
              width: pinWidth,
              height: pinHeight,
              textStyle: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color:
                    isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
              decoration: BoxDecoration(
                color:
                    isDark
                        ? AppColors.surfaceVariantDark
                        : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppRadius.r8),
                border: Border.all(
                  color:
                      isDark ? AppColors.cardBorderDark : AppColors.cardBorder,
                  width: 1.5,
                ),
              ),
            );

            final focusedPinTheme = defaultPinTheme.copyWith(
              decoration: defaultPinTheme.decoration!.copyWith(
                border: Border.all(
                  color: isDark ? AppColors.primaryLight : AppColors.primary,
                  width: 2.0,
                ),
                color:
                    isDark
                        ? AppColors.primaryDark.withValues(alpha: 0.15)
                        : AppColors.primarySurface,
              ),
            );

            final errorPinTheme = defaultPinTheme.copyWith(
              decoration: defaultPinTheme.decoration!.copyWith(
                border: Border.all(color: AppColors.error, width: 1.5),
                color:
                    isDark
                        ? AppColors.error.withValues(alpha: 0.15)
                        : AppColors.errorSurface,
              ),
            );

            return Center(
              child: flutter_mat.Material(
                type: flutter_mat.MaterialType.transparency,
                child: flutter_mat.Localizations(
                  locale: const Locale('en', 'US'),
                  delegates: const [
                    flutter_mat.DefaultMaterialLocalizations.delegate,
                    flutter_mat.DefaultWidgetsLocalizations.delegate,
                  ],
                  child: Pinput(
                    length: 6,
                    controller: _pinController,
                    defaultPinTheme: defaultPinTheme,
                    focusedPinTheme: focusedPinTheme,
                    errorPinTheme: errorPinTheme,
                    keyboardType: TextInputType.number,
                    autofocus: true,
                    onCompleted: (pin) async {
                      final success = await controller.verifyOtp(pin);
                      if (success && context.mounted) {
                        context.go('/createNewPassword');
                      }
                    },
                  ),
                ),
              ),
            );
          },
        ),
        if (otpState.errorMessage != null) ...[
          AppSpacing.gapH12,
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s12,
              vertical: AppSpacing.s8,
            ),
            decoration: BoxDecoration(
              color:
                  isDark
                      ? AppColors.error.withValues(alpha: 0.15)
                      : AppColors.errorSurface,
              borderRadius: BorderRadius.circular(AppRadius.r8),
              border: Border.all(
                color:
                    isDark
                        ? AppColors.error.withValues(alpha: 0.3)
                        : AppColors.errorBorder,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 16,
                  color: AppColors.error,
                ),
                AppSpacing.gapW8,
                Flexible(
                  child: Text(
                    otpState.errorMessage!,
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
        AppSpacing.gapH20,
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              "Didn't receive the code? ",
              style: TextStyle(
                fontSize: 13,
                color:
                    isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
              ),
            ),
            if (!otpState.canResend)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color:
                      isDark
                          ? AppColors.surfaceVariantDark
                          : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppRadius.r6),
                ),
                child: Text(
                  'Resend in ${_formatCooldown(otpState.cooldown)}',
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        isDark
                            ? AppColors.textTertiaryDark
                            : AppColors.textTertiary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            else
              TextButton(
                onPressed:
                    otpState.isResending
                        ? null
                        : () async {
                          final resent = await controller.resendOtp();
                          if (context.mounted && resent) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'A new code has been sent to your email.',
                                ),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                ),
                child:
                    otpState.isResending
                        ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : Text(
                          'Resend Code',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color:
                                isDark
                                    ? AppColors.primaryLight
                                    : AppColors.primary,
                          ),
                        ),
              ),
          ],
        ),
        AppSpacing.gapH24,
        AppButton(
          text: 'Verify & Proceed',
          isLoading: otpState.isVerifying,
          icon: Icons.check_circle_outline_rounded,
          onPressed:
              otpState.isVerifying
                  ? null
                  : () async {
                    final success = await controller.verifyOtp(
                      _pinController.text,
                    );
                    if (success && context.mounted) {
                      context.go('/createNewPassword');
                    }
                  },
        ),
      ],
    );
  }
}
