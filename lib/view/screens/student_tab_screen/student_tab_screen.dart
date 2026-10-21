import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:student_management/common/widgets/student_bottom_navigation.dart';
import 'package:student_management/controller/student_bottom_navigation_controller.dart';
import 'package:student_management/controller/student_library_controller.dart';
import 'package:student_management/core/theme/app_colors.dart';
import 'package:student_management/view/screens/student_fees_screen/student_fees_screen.dart';
import 'package:student_management/view/screens/student_library_screen/student_library_screen.dart';
import 'package:student_management/view/screens/student_profile_screen/student_profile_screen.dart';

/// A modern, fully responsive navigation shell for the Student Portal.
///
/// Adapts between a bottom navigation bar on mobile viewports (< 768px)
/// and a side navigation rail on tablet, laptop, and desktop viewports (>= 768px).
class StudentTabsShell extends StatelessWidget {
  final String id; // student’s id or auth uid
  final String? authUserId; // explicit authenticated Supabase user UUID
  final String? studentProfileId; // explicit student profile primary key (students.id)
  final bool filterByUserId; // true if using auth uid for Library
  final StudentLibraryController? libraryController;

  const StudentTabsShell({
    super.key,
    required this.id,
    this.authUserId,
    this.studentProfileId,
    this.filterByUserId = true,
    this.libraryController,
  });

  @override
  Widget build(BuildContext context) {
    StudentBottomNavController? existingNav;
    try {
      existingNav = Provider.of<StudentBottomNavController>(
        context,
        listen: false,
      );
    } catch (_) {
      existingNav = null;
    }

    if (existingNav == null) {
      return ChangeNotifierProvider(
        create: (_) => StudentBottomNavController(),
        child: _StudentTabsContent(
          id: id,
          authUserId: authUserId,
          studentProfileId: studentProfileId,
          filterByUserId: filterByUserId,
          libraryController: libraryController,
        ),
      );
    }

    return _StudentTabsContent(
      id: id,
      authUserId: authUserId,
      studentProfileId: studentProfileId,
      filterByUserId: filterByUserId,
      libraryController: libraryController,
    );
  }
}

class _StudentTabsContent extends StatelessWidget {
  final String id;
  final String? authUserId;
  final String? studentProfileId;
  final bool filterByUserId;
  final StudentLibraryController? libraryController;

  const _StudentTabsContent({
    required this.id,
    this.authUserId,
    this.studentProfileId,
    required this.filterByUserId,
    this.libraryController,
  });

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<StudentBottomNavController>();
    final index = nav.currentIndex;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    StudentLibraryController? libCtrl = libraryController;
    if (libCtrl == null) {
      try {
        libCtrl = context.read<StudentLibraryController>();
      } catch (_) {
        libCtrl = null;
      }
    }

    final resolvedAuthId = authUserId ?? id;
    final resolvedProfileId = studentProfileId ?? id;

    final pages = <Widget>[
      StudentProfileScreen(studentId: resolvedProfileId),
      StudentLibraryScreen(
        id: resolvedAuthId,
        filterByUserId: filterByUserId,
        controller: libCtrl,
      ),
      StudentFeesScreen(studentId: resolvedProfileId),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 768;

        if (isWide) {
          final railBg =
              isDark ? AppColors.cardSurfaceDark : AppColors.cardSurface;
          final borderColor =
              isDark ? AppColors.cardBorderDark : AppColors.cardBorder;

          return Scaffold(
            backgroundColor:
                isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
            body: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: railBg,
                    border: Border(
                      right: BorderSide(color: borderColor, width: 1.0),
                    ),
                  ),
                  child: NavigationRail(
                    selectedIndex: index,
                    onDestinationSelected: (i) => nav.setIndex(i),
                    labelType: NavigationRailLabelType.all,
                    backgroundColor: railBg,
                    leading: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24.0),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.school_rounded,
                          color: AppColors.primary,
                          size: 28,
                        ),
                      ),
                    ),
                    destinations: const [
                      NavigationRailDestination(
                        icon: Icon(Icons.person_outline_rounded),
                        selectedIcon: Icon(Icons.person_rounded),
                        label: Text('Profile'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.menu_book_outlined),
                        selectedIcon: Icon(Icons.menu_book_rounded),
                        label: Text('Library'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.receipt_long_outlined),
                        selectedIcon: Icon(Icons.receipt_long_rounded),
                        label: Text('Fees'),
                      ),
                    ],
                  ),
                ),
                Expanded(child: IndexedStack(index: index, children: pages)),
              ],
            ),
          );
        }

        return Scaffold(
          body: IndexedStack(index: index, children: pages),
          bottomNavigationBar: const StudentBottomNavigation(),
        );
      },
    );
  }
}
