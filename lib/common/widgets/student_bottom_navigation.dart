import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:provider/provider.dart';
import 'package:student_management/controller/student_bottom_navigation_controller.dart';

class StudentBottomNavigation extends StatelessWidget {
  const StudentBottomNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<StudentBottomNavController>();

    // Theme-driven palette
    final scheme = Theme.of(context).colorScheme;
    final primary = scheme.primary; // brand color
    final onSurface = scheme.onSurface; // base neutral for unselected

    // Replacements for deprecated withOpacity:
    final unselected = onSurface.withValues(alpha: 0.65); // ~65% opacity
    final tabBg = primary.withValues(
      alpha: 0.12,
    ); // 12% tint for selected tab bg
    final ripple = onSurface.withValues(alpha: 0.24); // 24% ripple
    final hover = onSurface.withValues(alpha: 0.16); // 16% hover

    return SafeArea(
      top: false,
      child: SizedBox(
        height: 56,
        child: GNav(
          gap: 8,
          selectedIndex: nav.currentIndex,
          onTabChange:
              (i) => context.read<StudentBottomNavController>().setIndex(i),
          // Interactions
          rippleColor: ripple,
          hoverColor: hover,
          haptic: true,
          curve: Curves.easeOutExpo,
          duration: const Duration(milliseconds: 250),
          // Visuals aligned with the library blue theme
          tabBorderRadius: 14,
          color: unselected, // unselected icon/text
          activeColor: primary, // selected icon/text
          tabBackgroundColor: tabBg, // selected tab background
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          tabs: const [
            GButton(icon: Icons.person, text: 'Profile'),
            GButton(icon: Icons.menu_book, text: 'Library'),
            GButton(icon: Icons.receipt_long, text: 'Fees'),
          ],
        ),
      ),
    );
  }
}
