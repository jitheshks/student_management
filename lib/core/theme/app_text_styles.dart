import 'package:material_ui/material_ui.dart';
import 'app_colors.dart';
import 'app_typography.dart';

/// Semantic text style presets with pre-configured weights and colors
/// for common administrative UI components.
class AppTextStyles {
  AppTextStyles._();

  // Screen & Header Titles
  static const TextStyle pageTitle = AppTypography.headlineLarge;
  static const TextStyle screenHeader = AppTypography.headlineMedium;
  static const TextStyle sectionHeader = AppTypography.titleLarge;
  static const TextStyle cardHeader = AppTypography.titleMedium;

  // Metric & Statistic Numbers
  static const TextStyle kpiValue = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    height: 1.2,
  );

  static const TextStyle kpiLabel = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.slate500,
    letterSpacing: 0.2,
  );

  // Form Fields & Inputs
  static const TextStyle formLabel = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.slate700,
  );

  static const TextStyle formHint = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.slate400,
  );

  static const TextStyle formError = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.error,
  );

  // Buttons & Badges
  static const TextStyle buttonText = AppTypography.labelLarge;

  static const TextStyle badgeText = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
  );

  static const TextStyle caption = AppTypography.bodySmall;
}
