import 'package:material_ui/material_ui.dart';

/// Centralized semantic color palette for the Academic Administration design system.
class AppColors {
  AppColors._();

  // Primary Brand Colors (Academic Indigo)
  static const Color primary = Color(0xFF4338CA); // Indigo 700
  static const Color primaryDark = Color(0xFF3730A3); // Indigo 800
  static const Color primaryLight = Color(0xFF6366F1); // Indigo 500
  static const Color primaryContainer = Color(0xFFEEF2FF); // Indigo 50
  static const Color onPrimary = Colors.white;
  static const Color onPrimaryContainer = Color(0xFF312E81); // Indigo 900

  // Secondary & Accent Colors (Sky Blue)
  static const Color accent = Color(0xFF0EA5E9); // Sky 500
  static const Color accentDark = Color(0xFF0284C7); // Sky 600
  static const Color accentLight = Color(0xFF38BDF8); // Sky 400
  static const Color accentContainer = Color(0xFFE0F2FE); // Sky 50
  static const Color onAccent = Colors.white;
  static const Color onAccentContainer = Color(0xFF0C4A6E); // Sky 900

  // Semantic Feedback Colors (Material 3 standard accessible tones)
  static const Color success = Color(0xFF059669); // Emerald 600
  static const Color successContainer = Color(0xFFECFDF5); // Emerald 50
  static const Color onSuccess = Colors.white;
  static const Color onSuccessContainer = Color(0xFF065F46); // Emerald 800

  static const Color warning = Color(0xFFD97706); // Amber 600
  static const Color warningContainer = Color(0xFFFFFBEB); // Amber 50
  static const Color onWarning = Colors.white;
  static const Color onWarningContainer = Color(0xFF92400E); // Amber 800

  static const Color error = Color(0xFFDC2626); // Red 600
  static const Color errorContainer = Color(0xFFFEF2F2); // Red 50
  static const Color onError = Colors.white;
  static const Color onErrorContainer = Color(0xFF991B1B); // Red 800

  static const Color info = Color(0xFF2563EB); // Blue 600
  static const Color infoContainer = Color(0xFFEFF6FF); // Blue 50
  static const Color onInfo = Colors.white;
  static const Color onInfoContainer = Color(0xFF1E40AF); // Blue 800

  // Neutral Colors (Slate Palette)
  static const Color slate50 = Color(0xFFF8FAFC);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate900 = Color(0xFF0F172A);

  // Background & Surfaces - Light
  static const Color backgroundLight = slate50;
  static const Color surfaceLight = Colors.white;
  static const Color cardSurfaceLight = Colors.white;
  static const Color dialogSurfaceLight = Colors.white;

  // Background & Surfaces - Dark
  static const Color backgroundDark = slate900;
  static const Color surfaceDark = slate800;
  static const Color cardSurfaceDark = slate800;
  static const Color dialogSurfaceDark = Color(0xFF1E293B);

  // Typography Colors - Light
  static const Color textPrimaryLight = slate900;
  static const Color textSecondaryLight = slate600;
  static const Color textMutedLight = slate400;

  // Typography Colors - Dark
  static const Color textPrimaryDark = slate100;
  static const Color textSecondaryDark = slate300;
  static const Color textMutedDark = slate500;

  // Borders & Dividers
  static const Color borderLight = slate200;
  static const Color borderDark = slate700;
  static const Color dividerLight = slate200;
  static const Color dividerDark = slate700;

  // Interactive & State Overlays
  static const Color disabled = slate300;
  static const Color disabledDark = slate600;
  static const Color disabledText = slate400;
  static const Color overlay = Color(0x33000000);
  static const Color transparent = Colors.transparent;

  // Academic Badges & Status
  static const Color statusPaid = success;
  static const Color statusPaidBg = successContainer;
  static const Color statusPending = warning;
  static const Color statusPendingBg = warningContainer;
  static const Color statusOverdue = error;
  static const Color statusOverdueBg = errorContainer;
  static const Color statusActive = info;
  static const Color statusActiveBg = infoContainer;
  static const Color statusReturned = slate600;
  static const Color statusReturnedBg = slate100;

  // Canonical semantic aliases
  static const Color textPrimary = textPrimaryLight;
  static const Color textSecondary = textSecondaryLight;
  static const Color textMuted = textMutedLight;
  static const Color textTertiary = textMutedLight;
  static const Color textTertiaryDark = textMutedDark;

  static const Color cardSurface = cardSurfaceLight;
  static const Color cardBorder = borderLight;
  static const Color cardBorderDark = borderDark;
  static const Color primarySurface = primaryContainer;
  static const Color errorSurface = errorContainer;
  static const Color errorBorder = error;
  static const Color warningSurface = warningContainer;
  static const Color successSurface = successContainer;
  static const Color infoSurface = infoContainer;
  static const Color surfaceVariant = slate100;
  static const Color surfaceVariantDark = slate800;
}
