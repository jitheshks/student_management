import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:student_management/core/constants/app_spacing.dart';
import 'package:student_management/core/theme/app_colors.dart';
import 'package:student_management/core/theme/app_typography.dart';
import 'package:student_management/features/fees/presentation/providers/fees_providers.dart';
import 'package:student_management/shared/models/fee_record.dart';
import 'package:student_management/shared/widgets/app_card.dart';
import 'package:student_management/shared/widgets/app_status_badge.dart';
import 'package:student_management/shared/widgets/empty_state_view.dart';
import 'package:student_management/shared/widgets/error_view.dart';
import 'package:student_management/shared/widgets/responsive_content.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// A modern, fully responsive fees screen for students.
///
/// Strictly read-only financial tracking displaying aggregate KPIs (Total, Paid, Due)
/// alongside detailed invoice cards and payment status indicators.
class StudentFeesScreen extends ConsumerWidget {
  final String? studentId;

  const StudentFeesScreen({super.key, this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    String effectiveId = studentId ?? '';
    if (effectiveId.isEmpty) {
      try {
        effectiveId = Supabase.instance.client.auth.currentUser?.id ?? '';
      } catch (_) {
        effectiveId = '';
      }
    }

    if (effectiveId.isEmpty) {
      return Scaffold(
        backgroundColor:
            isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        body: Center(
          child: Text(
            'Student ID not found.',
            style: AppTypography.bodyMedium.copyWith(
              color:
                  isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    final feesAsync = ref.watch(studentFeeRecordsProvider(effectiveId));

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'My Fees',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.primaryDark],
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              ref.invalidate(studentFeeRecordsProvider(effectiveId));
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(studentFeeRecordsProvider(effectiveId));
        },
        child: feesAsync.when(
          loading:
              () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
          error:
              (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.space24),
                  child: ErrorView(
                    message: 'Failed to load fee records: $err',
                    onRetry:
                        () => ref.invalidate(
                          studentFeeRecordsProvider(effectiveId),
                        ),
                  ),
                ),
              ),
          data: (records) {
            if (records.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.space32),
                  child: EmptyStateView(
                    title: 'No fee dues found',
                    subtitle: 'You have no pending or past fee records.',
                    icon: Icons.check_circle_outline,
                  ),
                ),
              );
            }

            final totalAmount = records.fold<double>(
              0.0,
              (sum, r) => sum + r.amount,
            );
            final totalPaid = records.fold<double>(
              0.0,
              (sum, r) => sum + r.paidAmount,
            );
            final totalDue = records.fold<double>(
              0.0,
              (sum, r) => sum + r.dueAmount,
            );

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.all(AppSpacing.space16),
              children: [
                ResponsiveContent(
                  maxContentWidth: 900,
                  padding: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Summary Overview Card
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.space20,
                          vertical: AppSpacing.space16,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, AppColors.primaryDark],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Fee Summary',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.space12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Expanded(
                                  child: _buildSummaryItem(
                                    'Total Fee',
                                    '₹${totalAmount.toStringAsFixed(0)}',
                                  ),
                                ),
                                _buildDivider(),
                                Expanded(
                                  child: _buildSummaryItem(
                                    'Paid',
                                    '₹${totalPaid.toStringAsFixed(0)}',
                                  ),
                                ),
                                _buildDivider(),
                                Expanded(
                                  child: _buildSummaryItem(
                                    'Due',
                                    '₹${totalDue.toStringAsFixed(0)}',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.space20),
                      Text(
                        'Installments & Invoices',
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color:
                              isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.space12),
                      ...records.map(
                        (record) => _buildRecordCard(context, record),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.white70),
        ),
        const SizedBox(height: AppSpacing.space4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(height: 28, width: 1, color: Colors.white24);
  }

  Widget _buildRecordCard(BuildContext context, FeeRecord record) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space12),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    record.title,
                    style: AppTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.bold,
                      color:
                          isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.space8),
                _buildStatusBadge(record.status),
              ],
            ),
            const SizedBox(height: AppSpacing.space12),
            Wrap(
              spacing: AppSpacing.space16,
              runSpacing: AppSpacing.space8,
              children: [
                Text(
                  'Amount: ₹${record.amount.toStringAsFixed(0)}',
                  style: AppTypography.bodySmall.copyWith(
                    color:
                        isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                  ),
                ),
                Text(
                  'Paid: ₹${record.paidAmount.toStringAsFixed(0)}',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (record.dueAmount > 0)
                  Text(
                    'Due: ₹${record.dueAmount.toStringAsFixed(0)}',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.space8),
            Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 13,
                  color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
                ),
                const SizedBox(width: AppSpacing.space4),
                Text(
                  record.paidDate != null
                      ? 'Paid Date: ${record.paidDate!.toLocal().toString().split(' ')[0]}'
                      : 'Due Date: ${record.dueDate.toLocal().toString().split(' ')[0]}',
                  style: AppTypography.bodySmall.copyWith(
                    fontSize: 11,
                    color:
                        isDark ? AppColors.textMutedDark : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(FeeStatus status) {
    switch (status) {
      case FeeStatus.paid:
        return const AppStatusBadge.paid(label: 'PAID');
      case FeeStatus.overdue:
        return const AppStatusBadge.overdue(label: 'OVERDUE');
      case FeeStatus.pending:
        return const AppStatusBadge.pending(label: 'PENDING');
    }
  }
}
