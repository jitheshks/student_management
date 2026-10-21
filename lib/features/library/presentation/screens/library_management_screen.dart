import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:student_management/core/constants/app_radius.dart';
import 'package:student_management/core/constants/app_spacing.dart';
import 'package:student_management/core/theme/app_colors.dart';
import 'package:student_management/core/theme/app_typography.dart';
import 'package:student_management/features/library/presentation/screens/borrow_book_screen.dart';
import 'package:student_management/features/library/presentation/screens/library_history_screen.dart';
import 'package:student_management/features/library/presentation/screens/return_book_screen.dart';
import 'package:student_management/shared/widgets/app_card.dart';
import 'package:student_management/shared/widgets/responsive_content.dart';

class LibraryManagementScreen extends ConsumerWidget {
  const LibraryManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final List<Map<String, dynamic>> options = [
      {
        'label': 'Borrow Book',
        'subtitle':
            'Issue a new book to a verified student with custom due dates.',
        'icon': Icons.menu_book,
        'screen': const BorrowBookScreen(),
        'color': AppColors.success,
        'containerColor':
            isDark ? const Color(0xFF064E3B) : AppColors.successContainer,
      },
      {
        'label': 'Return Book',
        'subtitle': 'Search active loans by student ID and process returns.',
        'icon': Icons.assignment_returned,
        'screen': const ReturnBookScreen(),
        'color': AppColors.info,
        'containerColor':
            isDark ? const Color(0xFF1E3A8A) : AppColors.infoContainer,
      },
      {
        'label': 'Library History Page',
        'subtitle':
            'Review, search, and filter global library borrowing records.',
        'icon': Icons.history,
        'screen': const LibraryHistoryScreen(),
        'color': AppColors.warning,
        'containerColor':
            isDark ? const Color(0xFF78350F) : AppColors.warningContainer,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Library Management',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.primaryDark],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: ResponsiveContent(
          maxContentWidth: 1000,
          padding: const EdgeInsets.all(AppSpacing.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Overview Header Card
              AppCard(
                padding: const EdgeInsets.all(AppSpacing.space16),
                backgroundColor:
                    isDark
                        ? AppColors.primary.withValues(alpha: 0.15)
                        : AppColors.primaryContainer,
                borderColor:
                    isDark
                        ? AppColors.primaryLight.withValues(alpha: 0.3)
                        : AppColors.primaryLight.withValues(alpha: 0.4),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: AppRadius.roundedSm,
                      ),
                      child: const Icon(
                        Icons.local_library,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    AppSpacing.gapW16,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Library Portal',
                            style: AppTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              color:
                                  isDark
                                      ? AppColors.textPrimaryDark
                                      : AppColors.textPrimaryLight,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Select an operation below to manage loans, process returns, or review records.',
                            style: AppTypography.bodySmall.copyWith(
                              color:
                                  isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              AppSpacing.gapH20,

              // Action Options Grid / List
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;

                    if (width < 500) {
                      // Narrow mobile: Vertical list of full-width action cards
                      return ListView.separated(
                        itemCount: options.length,
                        separatorBuilder: (context, index) => AppSpacing.gapH12,
                        itemBuilder: (context, index) {
                          final opt = options[index];
                          return _LibraryActionListCard(
                            label: opt['label'] as String,
                            subtitle: opt['subtitle'] as String,
                            icon: opt['icon'] as IconData,
                            iconColor: opt['color'] as Color,
                            containerColor: opt['containerColor'] as Color,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => opt['screen'] as Widget,
                                ),
                              );
                            },
                          );
                        },
                      );
                    } else {
                      // Tablet & Desktop: Responsive multi-column grid
                      final crossAxisCount = width < 850 ? 2 : 3;
                      final childAspectRatio = width < 850 ? 1.05 : 0.95;

                      return GridView.builder(
                        itemCount: options.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          mainAxisSpacing: AppSpacing.space16,
                          crossAxisSpacing: AppSpacing.space16,
                          childAspectRatio: childAspectRatio,
                        ),
                        itemBuilder: (context, index) {
                          final opt = options[index];
                          return _LibraryActionGridCard(
                            label: opt['label'] as String,
                            subtitle: opt['subtitle'] as String,
                            icon: opt['icon'] as IconData,
                            iconColor: opt['color'] as Color,
                            containerColor: opt['containerColor'] as Color,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => opt['screen'] as Widget,
                                ),
                              );
                            },
                          );
                        },
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Horizontal list card for narrow mobile screens
class _LibraryActionListCard extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color containerColor;
  final VoidCallback onTap;

  const _LibraryActionListCard({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.containerColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.space16),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: containerColor,
              borderRadius: AppRadius.roundedMd,
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          AppSpacing.gapW16,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color:
                        isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall.copyWith(
                    color:
                        isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          AppSpacing.gapW8,
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: isDark ? AppColors.slate500 : AppColors.slate400,
          ),
        ],
      ),
    );
  }
}

/// Card layout for tablet and desktop grid
class _LibraryActionGridCard extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color containerColor;
  final VoidCallback onTap;

  const _LibraryActionGridCard({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.containerColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.space20),
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: containerColor,
              borderRadius: AppRadius.roundedLg,
            ),
            child: Icon(icon, color: iconColor, size: 32),
          ),
          AppSpacing.gapH16,
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w700,
              color:
                  isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
            ),
          ),
          AppSpacing.gapH8,
          Text(
            subtitle,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall.copyWith(
              color:
                  isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
            ),
          ),
          AppSpacing.gapH12,
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Open',
                style: AppTypography.labelMedium.copyWith(
                  color: iconColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.arrow_forward, size: 14, color: iconColor),
            ],
          ),
        ],
      ),
    );
  }
}
