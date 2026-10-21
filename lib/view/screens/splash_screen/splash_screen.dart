import 'dart:math' as math;
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:student_management/core/constants/app_spacing.dart';
import 'package:student_management/core/constants/asset_constants.dart';
import 'package:student_management/core/theme/app_colors.dart';
import 'package:student_management/features/auth/presentation/controllers/splash_controller.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen to canonical splash navigation state
    ref.listen<AsyncValue<SplashNavigationTarget>>(splashNavigationProvider, (
      previous,
      next,
    ) {
      next.whenData((target) {
        if (!context.mounted) return;
        context.go(target.routeName, extra: target.arguments);
      });
    });

    final size = MediaQuery.sizeOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Bounded animation size avoiding overflow on 320px width and landscape mode
    final animSize = math.min(
      math.min(size.width * 0.6, size.height * 0.35),
      260.0,
    );

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: AppSpacing.paddingA24,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: animSize,
                  height: animSize,
                  child: Lottie.asset(
                    AssetConstants.splashAnimation,
                    fit: BoxFit.contain,
                  ),
                ),
                AppSpacing.gapH20,
                Text(
                  'Student Management System',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color:
                        isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                AppSpacing.gapH8,
                Text(
                  'Academic Administration Portal',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color:
                        isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                AppSpacing.gapH32,
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isDark ? AppColors.primaryLight : AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
