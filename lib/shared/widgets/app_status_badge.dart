import 'package:material_ui/material_ui.dart';
import 'package:student_management/core/constants/app_radius.dart';
import 'package:student_management/core/theme/app_colors.dart';
import 'package:student_management/core/theme/app_typography.dart';

/// Semantic status categories for [AppStatusBadge].
enum BadgeStatus {
  paid,
  pending,
  overdue,
  active,
  inactive,
  returned,
  info,
  custom,
}

/// A reusable, accessible status badge for entities such as fee records,
/// borrowing loans, and student statuses.
class AppStatusBadge extends StatelessWidget {
  final String label;
  final BadgeStatus status;
  final IconData? icon;
  final Color? customTextColor;
  final Color? customBackgroundColor;
  final Color? customBorderColor;
  final bool showDot;

  const AppStatusBadge({
    super.key,
    required this.label,
    this.status = BadgeStatus.info,
    this.icon,
    this.customTextColor,
    this.customBackgroundColor,
    this.customBorderColor,
    this.showDot = false,
  });

  /// Factory constructors for standard semantic states
  const AppStatusBadge.paid({
    super.key,
    this.label = 'Paid',
    this.icon,
    this.showDot = true,
  }) : status = BadgeStatus.paid,
       customTextColor = null,
       customBackgroundColor = null,
       customBorderColor = null;

  const AppStatusBadge.pending({
    super.key,
    this.label = 'Pending',
    this.icon,
    this.showDot = true,
  }) : status = BadgeStatus.pending,
       customTextColor = null,
       customBackgroundColor = null,
       customBorderColor = null;

  const AppStatusBadge.overdue({
    super.key,
    this.label = 'Overdue',
    this.icon,
    this.showDot = true,
  }) : status = BadgeStatus.overdue,
       customTextColor = null,
       customBackgroundColor = null,
       customBorderColor = null;

  const AppStatusBadge.active({
    super.key,
    this.label = 'Active',
    this.icon,
    this.showDot = true,
  }) : status = BadgeStatus.active,
       customTextColor = null,
       customBackgroundColor = null,
       customBorderColor = null;

  const AppStatusBadge.inactive({
    super.key,
    this.label = 'Inactive',
    this.icon,
    this.showDot = true,
  }) : status = BadgeStatus.inactive,
       customTextColor = null,
       customBackgroundColor = null,
       customBorderColor = null;

  const AppStatusBadge.returned({
    super.key,
    this.label = 'Returned',
    this.icon,
    this.showDot = true,
  }) : status = BadgeStatus.returned,
       customTextColor = null,
       customBackgroundColor = null,
       customBorderColor = null;

  /// Helper factory that maps string database values to an appropriate badge.
  factory AppStatusBadge.fromString(String rawStatus, {String? customLabel}) {
    final normalized = rawStatus.toLowerCase().trim();
    switch (normalized) {
      case 'paid':
        return AppStatusBadge.paid(label: customLabel ?? 'Paid');
      case 'pending':
      case 'partially_paid':
        return AppStatusBadge.pending(label: customLabel ?? 'Pending');
      case 'overdue':
        return AppStatusBadge.overdue(label: customLabel ?? 'Overdue');
      case 'active':
      case 'borrowed':
        return AppStatusBadge.active(label: customLabel ?? 'Active');
      case 'returned':
        return AppStatusBadge.returned(label: customLabel ?? 'Returned');
      case 'inactive':
      case 'archived':
        return AppStatusBadge.inactive(label: customLabel ?? 'Inactive');
      default:
        return AppStatusBadge(
          label: customLabel ?? rawStatus,
          status: BadgeStatus.info,
          showDot: true,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color textColor;
    final Color bgColor;
    final Color borderColor;

    if (customTextColor != null && customBackgroundColor != null) {
      textColor = customTextColor!;
      bgColor = customBackgroundColor!;
      borderColor =
          customBorderColor ?? customTextColor!.withValues(alpha: 0.3);
    } else {
      switch (status) {
        case BadgeStatus.paid:
          textColor = isDark ? const Color(0xFF34D399) : AppColors.statusPaid;
          bgColor = isDark ? const Color(0xFF064E3B) : AppColors.statusPaidBg;
          borderColor =
              isDark ? const Color(0xFF059669) : const Color(0xFFA7F3D0);
          break;
        case BadgeStatus.pending:
          textColor =
              isDark ? const Color(0xFFFBBF24) : AppColors.statusPending;
          bgColor =
              isDark ? const Color(0xFF78350F) : AppColors.statusPendingBg;
          borderColor =
              isDark ? const Color(0xFFD97706) : const Color(0xFFFDE68A);
          break;
        case BadgeStatus.overdue:
          textColor =
              isDark ? const Color(0xFFF87171) : AppColors.statusOverdue;
          bgColor =
              isDark ? const Color(0xFF7F1D1D) : AppColors.statusOverdueBg;
          borderColor =
              isDark ? const Color(0xFFDC2626) : const Color(0xFFFECACA);
          break;
        case BadgeStatus.active:
          textColor = isDark ? const Color(0xFF60A5FA) : AppColors.statusActive;
          bgColor = isDark ? const Color(0xFF1E3A8A) : AppColors.statusActiveBg;
          borderColor =
              isDark ? const Color(0xFF2563EB) : const Color(0xFFBFDBFE);
          break;
        case BadgeStatus.returned:
        case BadgeStatus.inactive:
          textColor = isDark ? AppColors.slate300 : AppColors.statusReturned;
          bgColor = isDark ? AppColors.slate800 : AppColors.statusReturnedBg;
          borderColor = isDark ? AppColors.slate600 : AppColors.slate300;
          break;
        case BadgeStatus.info:
        case BadgeStatus.custom:
          textColor = isDark ? AppColors.primaryLight : AppColors.primary;
          bgColor = isDark ? AppColors.primaryDark : AppColors.primaryContainer;
          borderColor =
              isDark
                  ? AppColors.primaryLight.withValues(alpha: 0.4)
                  : const Color(0xFFC7D2FE);
          break;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppRadius.badge,
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (showDot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: textColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
          ] else if (icon != null) ...[
            Icon(icon, size: 12, color: textColor),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: textColor,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
