import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:student_management/controller/student_bottom_navigation_controller.dart';
import 'package:student_management/core/theme/app_colors.dart';

/// A modern, responsive bottom navigation bar for the Student Portal.
///
/// Features theme-aware palette, touch-friendly tap targets, and safe area constraints.
class StudentBottomNavigation extends StatelessWidget {
  const StudentBottomNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<StudentBottomNavController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final primary = isDark ? AppColors.primaryLight : AppColors.primary;
    final unselected =
        isDark ? AppColors.textMutedDark : AppColors.textSecondary;
    final bg = isDark ? AppColors.cardSurfaceDark : AppColors.cardSurface;
    final borderColor =
        isDark ? AppColors.cardBorderDark : AppColors.cardBorder;
    final tabBg = primary.withValues(alpha: 0.12);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        border: Border(top: BorderSide(color: borderColor, width: 1.0)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: GNav(
                  gap: 8,
                  selectedIndex: nav.currentIndex,
                  onTabChange:
                      (i) => context
                          .read<StudentBottomNavController>()
                          .setIndex(i),
                  rippleColor: primary.withValues(alpha: 0.15),
                  hoverColor: primary.withValues(alpha: 0.08),
                  haptic: true,
                  curve: Curves.easeOutExpo,
                  duration: const Duration(milliseconds: 250),
                  tabBorderRadius: 14,
                  color: unselected,
                  activeColor: primary,
                  tabBackgroundColor: tabBg,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  tabs: const [
                    GButton(icon: Icons.person_rounded, text: 'Profile'),
                    GButton(icon: Icons.menu_book_rounded, text: 'Library'),
                    GButton(icon: Icons.receipt_long_rounded, text: 'Fees'),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
