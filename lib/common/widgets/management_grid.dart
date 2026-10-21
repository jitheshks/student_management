import 'package:material_ui/material_ui.dart';
import 'package:student_management/core/constants/app_radius.dart';
import 'package:student_management/core/constants/app_spacing.dart';
import 'package:student_management/core/theme/app_colors.dart';
import 'package:student_management/shared/widgets/app_card.dart';

/// Model for a single management option tile
class ManagementOption {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final List<Color> gradient;
  final String? subtitle;

  const ManagementOption({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.gradient,
    this.subtitle,
  });
}

/// Reusable responsive Grid that arranges ManagementCards
class ManagementGrid extends StatelessWidget {
  final List<ManagementOption> options;
  final EdgeInsetsGeometry padding;

  const ManagementGrid({
    super.key,
    required this.options,
    this.padding = const EdgeInsets.all(AppSpacing.s16),
  });

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: padding,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;

          // Responsive columns based on available container width
          final int crossAxisCount;
          final double childAspectRatio;

          if (width >= 960) {
            // Desktop layout: show all 4 (or 3) options in a single row
            crossAxisCount = options.length >= 4 ? 4 : options.length;
            childAspectRatio = 1.05;
          } else if (width >= 600) {
            // Tablet layout
            crossAxisCount = options.length == 3 ? 3 : 2;
            childAspectRatio = 1.0;
          } else if (width < 340) {
            // Narrow mobile (320px viewport)
            crossAxisCount = 2;
            childAspectRatio = 0.78;
          } else {
            // Standard mobile (360px - 599px)
            crossAxisCount = 2;
            childAspectRatio = 0.85;
          }

          final spacing = width < 360 ? AppSpacing.s8 : AppSpacing.s16;

          return GridView.builder(
            shrinkWrap: true,
            itemCount: options.length,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: spacing,
              crossAxisSpacing: spacing,
              childAspectRatio: childAspectRatio,
            ),
            itemBuilder: (context, index) {
              final o = options[index];
              return ManagementCard(
                label: o.label,
                icon: o.icon,
                onTap: o.onTap,
                gradient: o.gradient,
                subtitle: o.subtitle,
              );
            },
          );
        },
      ),
    );
  }
}

/// Reusable gradient card for each management option
class ManagementCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final List<Color> gradient;
  final String? subtitle;

  const ManagementCard({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    required this.gradient,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth;
        final isCompact = cardWidth < 150;

        final iconBoxSize = isCompact ? 42.0 : 48.0;
        final iconSize = isCompact ? 22.0 : 26.0;
        final paddingH = isCompact ? AppSpacing.s8 : AppSpacing.s12;
        final paddingV = isCompact ? AppSpacing.s8 : AppSpacing.s12;

        return AppCard(
          padding: EdgeInsets.zero,
          borderRadius: AppRadius.r16,
          elevation: isDark ? 0.0 : 1.5,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.r16),
            onTap: onTap,
            child: Semantics(
              button: true,
              label: '$label. Tap to open module',
              child: Stack(
                children: [
                  // Top gradient indicator bar
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 3.5,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: gradient),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(AppRadius.r16),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: paddingH,
                      vertical: paddingV,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 4),
                        // Gradient Icon Container
                        Container(
                          width: iconBoxSize,
                          height: iconBoxSize,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: gradient,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(AppRadius.r12),
                            boxShadow: [
                              BoxShadow(
                                color: gradient.first.withValues(alpha: 0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            icon,
                            color: Colors.white,
                            size: iconSize,
                          ),
                        ),
                        SizedBox(
                          height: isCompact ? AppSpacing.s8 : AppSpacing.s12,
                        ),
                        // Module Title
                        Text(
                          label,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: isCompact ? 13.0 : 14.5,
                            fontWeight: FontWeight.w600,
                            color:
                                isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimary,
                            height: 1.2,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 3),
                        // Subtitle / Prompt
                        Text(
                          subtitle ?? 'Tap to view',
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: isCompact ? 11.0 : 11.5,
                            color:
                                isDark
                                    ? AppColors.textTertiaryDark
                                    : AppColors.textTertiary,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
