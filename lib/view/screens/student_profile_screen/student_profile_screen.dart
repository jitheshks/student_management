import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart' as legacy_provider;
import 'package:student_management/controller/student_dashboard_controller.dart';
import 'package:student_management/core/constants/app_radius.dart';
import 'package:student_management/core/constants/app_spacing.dart';
import 'package:student_management/core/theme/app_colors.dart';
import 'package:student_management/core/theme/app_typography.dart';
import 'package:student_management/features/students/presentation/providers/student_providers.dart';
import 'package:student_management/shared/models/student.dart';
import 'package:student_management/shared/widgets/app_card.dart';
import 'package:student_management/shared/widgets/app_status_badge.dart';
import 'package:student_management/shared/widgets/error_view.dart';
import 'package:student_management/shared/widgets/responsive_content.dart';

/// A modern, fully responsive profile screen for students.
///
/// Features identity presentation, personal details, address information,
/// dynamic attendance visualization, and session logout controls.
class StudentProfileScreen extends ConsumerWidget {
  final String studentId;
  final int totalDays;

  const StudentProfileScreen({
    super.key,
    required this.studentId,
    this.totalDays = 250,
  });

  String _formatDate(DateTime? date) =>
      date == null ? 'N/A' : DateFormat('d/M/yyyy').format(date);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentAsync = ref.watch(studentProfileProvider(studentId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return studentAsync.when(
      loading:
          () => Scaffold(
            backgroundColor:
                isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
            body: const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          ),
      error:
          (error, _) => Scaffold(
            backgroundColor:
                isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
            body: Center(
              child: ErrorView(
                message: 'Failed to load student profile: $error',
                onRetry:
                    () => ref.invalidate(studentProfileProvider(studentId)),
              ),
            ),
          ),
      data: (student) => _buildProfileContent(context, ref, student),
    );
  }

  Widget _buildProfileContent(
    BuildContext context,
    WidgetRef ref,
    Student student,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Attendance calculation
    final int daysPresent = student.attendance;
    final double attendancePercent =
        (daysPresent / (totalDays == 0 ? 1 : totalDays)) * 100;

    Color attendanceColor;
    BadgeStatus badgeStatus;
    String statusText;
    if (attendancePercent < 50) {
      attendanceColor = AppColors.error;
      badgeStatus = BadgeStatus.custom;
      statusText = 'Needs Attention';
    } else if (attendancePercent <= 75) {
      attendanceColor = AppColors.warning;
      badgeStatus = BadgeStatus.custom;
      statusText = 'Average';
    } else {
      attendanceColor = AppColors.success;
      badgeStatus = BadgeStatus.paid;
      statusText = 'Excellent';
    }

    final hasImage =
        student.profileImageUrl != null &&
        student.profileImageUrl!.trim().isNotEmpty;

    final displayName =
        '${student.firstName} ${student.lastName}'.trim().isNotEmpty
            ? '${student.firstName} ${student.lastName}'.trim()
            : student.displayName;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Header with gradient and identity presentation
          SliverAppBar(
            pinned: true,
            expandedHeight: 200,
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            elevation: 0,
            actions: [
              Builder(
                builder:
                    (ctx) => IconButton(
                      icon: const Icon(Icons.logout, color: Colors.white),
                      tooltip: 'Logout',
                      onPressed: () {
                        try {
                          legacy_provider
                              .Provider.of<StudentDashboardController>(
                            ctx,
                            listen: false,
                          ).logout(ctx);
                        } catch (_) {}
                      },
                    ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              titlePadding: const EdgeInsets.only(bottom: 16),
              title: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    displayName,
                    style: AppTypography.titleMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Standard ${student.standard}',
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(24),
                  ),
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 48),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x33000000),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 34,
                        backgroundColor: AppColors.primary.withValues(
                          alpha: 0.1,
                        ),
                        backgroundImage:
                            hasImage
                                ? NetworkImage(student.profileImageUrl!)
                                : null,
                        child:
                            !hasImage
                                ? Text(
                                  student.initials.isNotEmpty
                                      ? student.initials
                                      : 'S',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                )
                                : null,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Main Profile Details Content
          SliverToBoxAdapter(
            child: ResponsiveContent(
              maxContentWidth: 900,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space16,
                vertical: AppSpacing.space20,
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 720;

                  final personalCard = _buildPersonalCard(
                    context,
                    student,
                    displayName,
                  );
                  final addressCard = _buildAddressCard(context, student);
                  final attendanceCard = _buildAttendanceCard(
                    context,
                    daysPresent,
                    attendancePercent,
                    attendanceColor,
                    badgeStatus,
                    statusText,
                  );

                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: personalCard),
                        const SizedBox(width: AppSpacing.space16),
                        Expanded(
                          child: Column(
                            children: [
                              attendanceCard,
                              const SizedBox(height: AppSpacing.space16),
                              addressCard,
                            ],
                          ),
                        ),
                      ],
                    );
                  }

                  return Column(
                    children: [
                      attendanceCard,
                      const SizedBox(height: AppSpacing.space16),
                      personalCard,
                      const SizedBox(height: AppSpacing.space16),
                      addressCard,
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalCard(
    BuildContext context,
    Student student,
    String displayName,
  ) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.space8),
              const Expanded(
                child: Text(
                  'Personal Information',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          _infoRow(context, 'Full Name', displayName),
          _infoRow(context, 'Register Number', student.registerNumber),
          _infoRow(context, 'Date of Birth', _formatDate(student.dob)),
          _infoRow(context, 'Phone Number', student.phone ?? ''),
          _infoRow(context, 'Email', student.email ?? ''),
        ],
      ),
    );
  }

  Widget _buildAddressCard(BuildContext context, Student student) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final addressText =
        (student.address != null && student.address!.isNotEmpty)
            ? student.address!
            : 'No address provided';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: AppColors.error,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.space8),
              const Expanded(
                child: Text(
                  'Address Details',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Text(
            addressText,
            style: AppTypography.bodyMedium.copyWith(
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceCard(
    BuildContext context,
    int daysPresent,
    double attendancePercent,
    Color attendanceColor,
    BadgeStatus badgeStatus,
    String statusText,
  ) {
    return AppCard(
      borderColor: attendanceColor.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: attendanceColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Icon(
                        Icons.calendar_month_rounded,
                        color: attendanceColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.space8),
                    Flexible(
                      child: Text(
                        'Attendance',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: attendanceColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.space8),
              AppStatusBadge(
                label: statusText,
                customTextColor: attendanceColor,
                customBackgroundColor: attendanceColor.withValues(alpha: 0.12),
                customBorderColor: attendanceColor.withValues(alpha: 0.3),
                showDot: true,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space16),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.space12,
            runSpacing: AppSpacing.space8,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '${attendancePercent.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 32,
                    color: attendanceColor,
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$daysPresent days present',
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'of $totalDays total days',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space12),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.radiusFull),
            child: LinearProgressIndicator(
              value: daysPresent / (totalDays == 0 ? 1 : totalDays),
              backgroundColor: attendanceColor.withValues(alpha: 0.18),
              color: attendanceColor,
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(BuildContext context, String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color:
                    isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.space8),
          Expanded(
            child: Text(
              value.isEmpty ? 'Not provided' : value,
              style: AppTypography.bodyMedium.copyWith(
                color:
                    isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
