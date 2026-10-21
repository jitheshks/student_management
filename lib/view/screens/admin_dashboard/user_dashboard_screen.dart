import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:student_management/common/widgets/management_grid.dart';
import 'package:student_management/controller/base_dashboard_controller.dart';
import 'package:student_management/core/constants/app_radius.dart';
import 'package:student_management/core/constants/app_spacing.dart';
import 'package:student_management/core/theme/app_colors.dart';
import 'package:student_management/shared/widgets/app_card.dart';
import 'package:student_management/shared/widgets/app_status_badge.dart';
import 'package:student_management/shared/widgets/responsive_content.dart';

class UserDashboard<T extends BaseDashboardController> extends StatelessWidget {
  final String title;
  final T Function(BuildContext) createController;

  const UserDashboard({
    super.key,
    required this.title,
    required this.createController,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<T>(
      create: (ctx) => createController(ctx)..load(),
      child: _UserDashboardView<T>(title: title),
    );
  }
}

class _UserDashboardView<T extends BaseDashboardController>
    extends StatelessWidget {
  final String title;
  const _UserDashboardView({required this.title});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<T>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAdmin = title.toLowerCase().contains('admin');

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1.0,
        backgroundColor:
            isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        leading: Padding(
          padding: const EdgeInsets.only(left: AppSpacing.s12),
          child: Center(
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color:
                    isDark
                        ? AppColors.primaryLight.withValues(alpha: 0.15)
                        : AppColors.primarySurface,
                borderRadius: BorderRadius.circular(AppRadius.r8),
                border: Border.all(
                  color:
                      isDark
                          ? AppColors.primaryLight.withValues(alpha: 0.3)
                          : AppColors.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Icon(
                isAdmin
                    ? Icons.admin_panel_settings_rounded
                    : Icons.school_rounded,
                size: 20,
                color: isDark ? AppColors.primaryLight : AppColors.primary,
              ),
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color:
                    isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              'Institutional Management System',
              style: TextStyle(
                fontSize: 11,
                color:
                    isDark
                        ? AppColors.textTertiaryDark
                        : AppColors.textTertiary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Metrics',
            color:
                isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
            onPressed: () => ctrl.load(),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign Out',
            color: AppColors.error,
            onPressed: () => ctrl.logout(context),
          ),
          AppSpacing.gapW8,
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: isDark ? AppColors.cardBorderDark : AppColors.cardBorder,
            height: 1.0,
          ),
        ),
      ),
      body: SafeArea(
        child: ResponsiveContent(
          padding: EdgeInsets.zero,
          maxContentWidth: 1200,
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s16,
              vertical: AppSpacing.s20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Executive Header Card
                _HeaderCard(
                  name: ctrl.displayName,
                  isAdmin: isAdmin,
                  isDark: isDark,
                ),
                if (ctrl.errorMessage != null) ...[
                  AppSpacing.gapH16,
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s16,
                      vertical: AppSpacing.s12,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isDark
                              ? AppColors.error.withValues(alpha: 0.15)
                              : AppColors.errorSurface,
                      borderRadius: BorderRadius.circular(AppRadius.r12),
                      border: Border.all(
                        color:
                            isDark
                                ? AppColors.error.withValues(alpha: 0.3)
                                : AppColors.errorBorder,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: AppColors.error,
                          size: 20,
                        ),
                        AppSpacing.gapW12,
                        Expanded(
                          child: Text(
                            ctrl.errorMessage!,
                            style: const TextStyle(
                              color: AppColors.error,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => ctrl.load(),
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ],
                AppSpacing.gapH24,
                // Overview Section
                _SectionTitle(
                  icon: Icons.insights_rounded,
                  title: 'Institutional Overview',
                  subtitle: 'Real-time student and staff metrics',
                  isDark: isDark,
                ),
                AppSpacing.gapH12,
                _OverviewRow(
                  students: ctrl.totalStudents,
                  staff: ctrl.totalStaff,
                  isDark: isDark,
                ),
                AppSpacing.gapH24,
                // Management Section
                _SectionTitle(
                  icon: Icons.grid_view_rounded,
                  title: 'Management Hub',
                  subtitle: 'Direct access to administrative modules',
                  isDark: isDark,
                ),
                AppSpacing.gapH12,
                // Responsive Management Grid
                ManagementGrid(
                  padding: EdgeInsets.zero,
                  options:
                      ctrl.managementOptions(context).map((m) {
                        final label = m['label'] as String;
                        return ManagementOption(
                          label: label,
                          icon: m['icon'] as IconData,
                          onTap: m['action'] as VoidCallback,
                          gradient: _gradientFor(label),
                          subtitle: _subtitleFor(label),
                        );
                      }).toList(),
                ),
                AppSpacing.gapH24,
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _subtitleFor(String label) {
    switch (label) {
      case 'Student Management':
        return 'Enrollment & directories';
      case 'Library Management':
        return 'Catalog, loans & returns';
      case 'Staff Management':
        return 'Faculty & personnel registry';
      case 'Fees Management':
        return 'Fee ledger & receipts';
      default:
        return 'Tap to view module';
    }
  }

  List<Color> _gradientFor(String label) {
    switch (label) {
      case 'Student Management':
        return const [Color(0xFF10B981), Color(0xFF059669)]; // Emerald
      case 'Library Management':
        return const [Color(0xFFF59E0B), Color(0xFFD97706)]; // Amber
      case 'Staff Management':
        return const [Color(0xFF3B82F6), Color(0xFF1D4ED8)]; // Blue
      case 'Fees Management':
      default:
        return const [Color(0xFF8B5CF6), Color(0xFF6D28D9)]; // Purple
    }
  }
}

class _HeaderCard extends StatelessWidget {
  final String name;
  final bool isAdmin;
  final bool isDark;

  const _HeaderCard({
    required this.name,
    required this.isAdmin,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final displayName =
        name.isNotEmpty ? name : (isAdmin ? 'Administrator' : 'Staff Member');

    return AppCard(
      padding: EdgeInsets.zero,
      borderRadius: AppRadius.r16,
      elevation: isDark ? 0.0 : 1.5,
      child: Stack(
        children: [
          // Top subtle primary gradient line
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 3.5,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    isAdmin ? AppColors.primaryLight : AppColors.info,
                  ],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.r16),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s16,
              vertical: AppSpacing.s16,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar badge
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color:
                        isDark
                            ? AppColors.primaryLight.withValues(alpha: 0.15)
                            : AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(AppRadius.r12),
                    border: Border.all(
                      color:
                          isDark
                              ? AppColors.primaryLight.withValues(alpha: 0.3)
                              : AppColors.primary.withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    isAdmin
                        ? Icons.admin_panel_settings_rounded
                        : Icons.badge_rounded,
                    color: isDark ? AppColors.primaryLight : AppColors.primary,
                    size: 26,
                  ),
                ),
                AppSpacing.gapW12,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: AppSpacing.s8,
                        runSpacing: AppSpacing.s4,
                        children: [
                          Text(
                            'Welcome back,',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color:
                                  isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondary,
                            ),
                          ),
                          AppStatusBadge(
                            label: isAdmin ? 'Administrator' : 'Staff Member',
                            status:
                                isAdmin ? BadgeStatus.active : BadgeStatus.info,
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        displayName,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color:
                              isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isAdmin
                            ? 'Full administrative access granted'
                            : 'Academic staff management portal',
                        style: TextStyle(
                          fontSize: 11.5,
                          color:
                              isDark
                                  ? AppColors.textTertiaryDark
                                  : AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool isDark;

  const _SectionTitle({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color:
                isDark
                    ? AppColors.primaryLight.withValues(alpha: 0.15)
                    : AppColors.primarySurface,
            borderRadius: BorderRadius.circular(AppRadius.r8),
            border: Border.all(
              color:
                  isDark
                      ? AppColors.primaryLight.withValues(alpha: 0.3)
                      : AppColors.primary.withValues(alpha: 0.2),
            ),
          ),
          child: Icon(
            icon,
            color: isDark ? AppColors.primaryLight : AppColors.primary,
            size: 16,
          ),
        ),
        AppSpacing.gapW8,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color:
                      isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 1),
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: 11.5,
                    color:
                        isDark
                            ? AppColors.textTertiaryDark
                            : AppColors.textTertiary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _OverviewRow extends StatelessWidget {
  final int students;
  final int staff;
  final bool isDark;

  const _OverviewRow({
    required this.students,
    required this.staff,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isCompact = width < 360;
        final spacing = isCompact ? AppSpacing.s8 : AppSpacing.s12;

        final double childAspectRatio;
        if (width >= 900) {
          childAspectRatio = 2.4;
        } else if (width >= 600) {
          childAspectRatio = 2.0;
        } else if (isCompact) {
          childAspectRatio = 1.35;
        } else {
          childAspectRatio = 1.55;
        }

        return GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: spacing,
            crossAxisSpacing: spacing,
            childAspectRatio: childAspectRatio,
          ),
          children: [
            _buildKpiCard(
              title: 'Total Students',
              subtitle: 'Enrolled learners',
              value: students,
              icon: Icons.school_rounded,
              color: AppColors.primary,
              isWide: width >= 600,
              isCompact: isCompact,
            ),
            _buildKpiCard(
              title: 'Staff Members',
              subtitle: 'Active faculty',
              value: staff,
              icon: Icons.people_alt_rounded,
              color: AppColors.info,
              isWide: width >= 600,
              isCompact: isCompact,
            ),
          ],
        );
      },
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String subtitle,
    required int value,
    required IconData icon,
    required Color color,
    required bool isWide,
    required bool isCompact,
  }) {
    return AppCard(
      padding: EdgeInsets.zero,
      borderRadius: AppRadius.r16,
      elevation: isDark ? 0.0 : 1.5,
      child: Stack(
        children: [
          // Top accent line
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 3.5,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.r16),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(isCompact ? AppSpacing.s8 : AppSpacing.s12),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: value.toDouble()),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (_, v, child) {
                if (isWide) {
                  // Tablet / Desktop row layout
                  return Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: isDark ? 0.2 : 0.1),
                          borderRadius: BorderRadius.circular(AppRadius.r12),
                        ),
                        child: Icon(icon, color: color, size: 24),
                      ),
                      AppSpacing.gapW12,
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              v.toInt().toString(),
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: color,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color:
                                    isDark
                                        ? AppColors.textPrimaryDark
                                        : AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color:
                                    isDark
                                        ? AppColors.textTertiaryDark
                                        : AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }

                // Mobile column layout
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: isCompact ? 30 : 34,
                          height: isCompact ? 30 : 34,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: isDark ? 0.2 : 0.1),
                            borderRadius: BorderRadius.circular(AppRadius.r8),
                          ),
                          child: Icon(
                            icon,
                            color: color,
                            size: isCompact ? 16 : 18,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          v.toInt().toString(),
                          style: TextStyle(
                            fontSize: isCompact ? 20 : 24,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isCompact ? 4 : 8),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: isCompact ? 12 : 13,
                        fontWeight: FontWeight.w600,
                        color:
                            isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimary,
                      ),
                    ),
                    if (!isCompact) ...[
                      const SizedBox(height: 1),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10.5,
                          color:
                              isDark
                                  ? AppColors.textTertiaryDark
                                  : AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
