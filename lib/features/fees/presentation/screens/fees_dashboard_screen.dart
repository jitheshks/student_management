import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:student_management/core/constants/app_radius.dart';
import 'package:student_management/core/constants/app_spacing.dart';
import 'package:student_management/core/theme/app_colors.dart';
import 'package:student_management/core/theme/app_typography.dart';
import 'package:student_management/features/fees/presentation/providers/fees_providers.dart';
import 'package:student_management/shared/models/fee_record.dart';
import 'package:student_management/shared/widgets/app_card.dart';
import 'package:student_management/shared/widgets/app_search_bar.dart';
import 'package:student_management/shared/widgets/app_status_badge.dart';
import 'package:student_management/shared/widgets/empty_state_view.dart';
import 'package:student_management/shared/widgets/error_view.dart';

class FeesDashboardScreen extends ConsumerStatefulWidget {
  const FeesDashboardScreen({super.key});

  @override
  ConsumerState<FeesDashboardScreen> createState() =>
      _FeesDashboardScreenState();
}

class _FeesDashboardScreenState extends ConsumerState<FeesDashboardScreen> {
  String _selectedFilter = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _fmtAmount(double amount) {
    final isInt = amount % 1 == 0;
    final formatter = NumberFormat.currency(
      symbol: '₹',
      decimalDigits: isInt ? 0 : 2,
    );
    return formatter.format(amount);
  }

  String _fmtDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(institutionalFeesSummaryProvider);
    final recordsAsync = ref.watch(allFeeRecordsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 768;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Fees Management',
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              ref.invalidate(institutionalFeesSummaryProvider);
              ref.invalidate(allFeeRecordsProvider);
            },
          ),
        ],
      ),
      body: SafeArea(
        bottom: true,
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(institutionalFeesSummaryProvider);
            ref.invalidate(allFeeRecordsProvider);
          },
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            behavior: HitTestBehavior.opaque,
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: CustomScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    // KPI Financial Overview Section
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.space16,
                          AppSpacing.space16,
                          AppSpacing.space16,
                          AppSpacing.space8,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Financial Overview',
                              style: AppTypography.titleMedium.copyWith(
                                fontWeight: FontWeight.w700,
                                color:
                                    isDark
                                        ? AppColors.textPrimaryDark
                                        : AppColors.textPrimaryLight,
                              ),
                            ),
                            AppSpacing.gapH12,
                            summaryAsync.when(
                              data: (summary) => _buildKpiGrid(summary, isDark),
                              loading:
                                  () => const SizedBox(
                                    height: 140,
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  ),
                              error:
                                  (e, _) => AppCard(
                                    padding: const EdgeInsets.all(
                                      AppSpacing.space16,
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.error_outline,
                                          color: AppColors.error,
                                        ),
                                        AppSpacing.gapW12,
                                        Expanded(
                                          child: Text(
                                            'Failed to load fee summary: $e',
                                            style: AppTypography.bodySmall
                                                .copyWith(
                                                  color: AppColors.error,
                                                ),
                                          ),
                                        ),
                                        TextButton(
                                          onPressed:
                                              () => ref.invalidate(
                                                institutionalFeesSummaryProvider,
                                              ),
                                          child: const Text('Retry'),
                                        ),
                                      ],
                                    ),
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Search & Filter Bar Section
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.space16,
                          vertical: AppSpacing.space8,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    'Fee Records',
                                    style: AppTypography.titleMedium.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color:
                                          isDark
                                              ? AppColors.textPrimaryDark
                                              : AppColors.textPrimaryLight,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                recordsAsync.maybeWhen(
                                  data: (records) {
                                    final count =
                                        _filterRecords(records).length;
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            isDark
                                                ? AppColors.slate800
                                                : AppColors.slate200,
                                        borderRadius: AppRadius.roundedFull,
                                      ),
                                      child: Text(
                                        '$count records',
                                        style: AppTypography.labelSmall
                                            .copyWith(
                                              color:
                                                  isDark
                                                      ? AppColors
                                                          .textSecondaryDark
                                                      : AppColors
                                                          .textSecondaryLight,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    );
                                  },
                                  orElse: () => const SizedBox.shrink(),
                                ),
                              ],
                            ),
                            AppSpacing.gapH8,
                            AppSearchBar(
                              controller: _searchController,
                              hintText:
                                  'Search by student ID, fee title, receipt...',
                              onChanged: (query) {
                                setState(() {
                                  _searchQuery = query.trim();
                                });
                              },
                              onClear: () {
                                setState(() {
                                  _searchQuery = '';
                                  _searchController.clear();
                                });
                              },
                            ),
                            AppSpacing.gapH8,
                            Wrap(
                              spacing: AppSpacing.space8,
                              runSpacing: 6,
                              children:
                                  ['All', 'Paid', 'Pending', 'Overdue'].map((
                                    filter,
                                  ) {
                                    final isSelected =
                                        _selectedFilter == filter;
                                    return FilterChip(
                                      label: Text(filter),
                                      selected: isSelected,
                                      visualDensity: VisualDensity.compact,
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      onSelected: (_) {
                                        setState(() {
                                          _selectedFilter = filter;
                                        });
                                      },
                                      selectedColor: AppColors.primary,
                                      checkmarkColor: Colors.white,
                                      backgroundColor:
                                          isDark
                                              ? AppColors.slate800
                                              : AppColors.slate100,
                                      labelStyle: AppTypography.labelMedium
                                          .copyWith(
                                            color:
                                                isSelected
                                                    ? Colors.white
                                                    : (isDark
                                                        ? AppColors
                                                            .textSecondaryDark
                                                        : AppColors.slate700),
                                            fontWeight:
                                                isSelected
                                                    ? FontWeight.w700
                                                    : FontWeight.w500,
                                          ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: AppRadius.roundedFull,
                                        side: BorderSide(
                                          color:
                                              isSelected
                                                  ? AppColors.primary
                                                  : (isDark
                                                      ? AppColors.slate700
                                                      : AppColors.slate300),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Fee Records List / Grid Area
                    recordsAsync.when(
                      data: (records) {
                        final filtered = _filterRecords(records);

                        if (filtered.isEmpty) {
                          return SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.space16,
                                vertical: AppSpacing.space32,
                              ),
                              child: Center(
                                child: EmptyStateView(
                                  title: 'No fee records found',
                                  subtitle:
                                      _searchQuery.isNotEmpty ||
                                              _selectedFilter != 'All'
                                          ? 'No records match the active search or status filter.'
                                          : 'There are currently no fee records on file.',
                                  icon: Icons.receipt_long_outlined,
                                ),
                              ),
                            ),
                          );
                        }

                        if (isWide) {
                          return SliverPadding(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.space16,
                              AppSpacing.space8,
                              AppSpacing.space16,
                              AppSpacing.space32,
                            ),
                            sliver: SliverToBoxAdapter(
                              child: LayoutBuilder(
                                builder: (context, boxConstraints) {
                                  final colWidth =
                                      (boxConstraints.maxWidth -
                                          AppSpacing.space12) /
                                      2;
                                  return Wrap(
                                    spacing: AppSpacing.space12,
                                    runSpacing: AppSpacing.space12,
                                    children:
                                        filtered
                                            .map(
                                              (r) => SizedBox(
                                                width: colWidth,
                                                child: _buildFeeCard(r, isDark),
                                              ),
                                            )
                                            .toList(),
                                  );
                                },
                              ),
                            ),
                          );
                        }

                        // Mobile: Native card list with clean spacing
                        return SliverPadding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.space16,
                            AppSpacing.space8,
                            AppSpacing.space16,
                            AppSpacing.space32,
                          ),
                          sliver: SliverToBoxAdapter(
                            child: Column(
                              children:
                                  filtered
                                      .map(
                                        (r) => Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: AppSpacing.space12,
                                          ),
                                          child: _buildFeeCard(r, isDark),
                                        ),
                                      )
                                      .toList(),
                            ),
                          ),
                        );
                      },
                      loading:
                          () => const SliverToBoxAdapter(
                            child: SizedBox(
                              height: 180,
                              child: Center(child: CircularProgressIndicator()),
                            ),
                          ),
                      error:
                          (e, _) => SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.space16,
                                vertical: AppSpacing.space32,
                              ),
                              child: Center(
                                child: ErrorView(
                                  message: 'Error loading fee records: $e',
                                  onRetry:
                                      () =>
                                          ref.invalidate(allFeeRecordsProvider),
                                ),
                              ),
                            ),
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<FeeRecord> _filterRecords(List<FeeRecord> records) {
    return records.where((r) {
      if (_selectedFilter == 'Paid' && r.status != FeeStatus.paid) return false;
      if (_selectedFilter == 'Pending' && r.status != FeeStatus.pending) {
        return false;
      }
      if (_selectedFilter == 'Overdue' && r.status != FeeStatus.overdue) {
        return false;
      }

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesTitle = r.title.toLowerCase().contains(q);
        final matchesStudent = r.studentId.toLowerCase().contains(q);
        final matchesReceipt =
            r.receiptNumber?.toLowerCase().contains(q) ?? false;
        final matchesYear = r.academicYear?.toLowerCase().contains(q) ?? false;
        if (!matchesTitle &&
            !matchesStudent &&
            !matchesReceipt &&
            !matchesYear) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  Widget _buildKpiGrid(FeesSummary summary, bool isDark) {
    final totalBilled = summary.totalCollected + summary.totalPending;

    final cards = [
      _KpiData(
        title: 'Billed',
        amount: totalBilled,
        subtitle: 'Gross institutional billing',
        icon: Icons.receipt_long,
        color: AppColors.primary,
        lightBg: const Color(0xFFEEF2FF),
        darkBg: const Color(0xFF1E1E38),
      ),
      _KpiData(
        title: 'Collected',
        amount: summary.totalCollected,
        subtitle:
            '${summary.paidStudentsCount} of ${summary.totalStudents} students paid',
        icon: Icons.check_circle_outline,
        color: AppColors.success,
        lightBg: const Color(0xFFECFDF5),
        darkBg: const Color(0xFF064E3B).withValues(alpha: 0.3),
      ),
      _KpiData(
        title: 'Outstanding',
        amount: summary.totalPending,
        subtitle: 'Pending balance collection',
        icon: Icons.pending_outlined,
        color: AppColors.warning,
        lightBg: const Color(0xFFFFFBEB),
        darkBg: const Color(0xFF78350F).withValues(alpha: 0.3),
      ),
      _KpiData(
        title: 'Overdue',
        amount: summary.totalOverdue,
        subtitle: 'Past scheduled due date',
        icon: Icons.error_outline,
        color: AppColors.error,
        lightBg: const Color(0xFFFEF2F2),
        darkBg: const Color(0xFF7F1D1D).withValues(alpha: 0.3),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isCompact = width < 360;
        final spacing = isCompact ? AppSpacing.space8 : AppSpacing.space12;

        if (width >= 900) {
          // Large tablet / Desktop: 4 columns in one row
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _buildKpiCard(cards[0], isDark, isCompact: false),
                ),
                SizedBox(width: spacing),
                Expanded(
                  child: _buildKpiCard(cards[1], isDark, isCompact: false),
                ),
                SizedBox(width: spacing),
                Expanded(
                  child: _buildKpiCard(cards[2], isDark, isCompact: false),
                ),
                SizedBox(width: spacing),
                Expanded(
                  child: _buildKpiCard(cards[3], isDark, isCompact: false),
                ),
              ],
            ),
          );
        } else {
          // Mobile & medium screens: 2x2 grid
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _buildKpiCard(
                        cards[0],
                        isDark,
                        isCompact: isCompact,
                      ),
                    ),
                    SizedBox(width: spacing),
                    Expanded(
                      child: _buildKpiCard(
                        cards[1],
                        isDark,
                        isCompact: isCompact,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: spacing),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _buildKpiCard(
                        cards[2],
                        isDark,
                        isCompact: isCompact,
                      ),
                    ),
                    SizedBox(width: spacing),
                    Expanded(
                      child: _buildKpiCard(
                        cards[3],
                        isDark,
                        isCompact: isCompact,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildKpiCard(_KpiData data, bool isDark, {bool isCompact = false}) {
    final padding = isCompact ? AppSpacing.space8 : AppSpacing.space12;
    return AppCard(
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  data.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: (isCompact
                          ? AppTypography.labelMedium
                          : AppTypography.labelLarge)
                      .copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.slate400 : AppColors.slate600,
                      ),
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: EdgeInsets.all(isCompact ? AppSpacing.space4 : AppSpacing.space8),
                decoration: BoxDecoration(
                  color: isDark ? data.darkBg : data.lightBg,
                  borderRadius: AppRadius.roundedSm,
                ),
                child: Icon(
                  data.icon,
                  color: data.color,
                  size: isCompact ? 16 : 18,
                ),
              ),
            ],
          ),
          SizedBox(height: isCompact ? 4 : AppSpacing.space8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              _fmtAmount(data.amount),
              style: (isCompact
                      ? AppTypography.titleLarge
                      : AppTypography.headlineSmall)
                  .copyWith(
                    fontWeight: FontWeight.w800,
                    color:
                        isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                  ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            data.subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.labelSmall.copyWith(
              fontSize: isCompact ? 10 : 11,
              color:
                  isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeeCard(FeeRecord record, bool isDark) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.space12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Title + Academic Year + Status Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.title,
                      style: AppTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color:
                            isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (record.academicYear != null &&
                        record.academicYear!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Academic Year: ${record.academicYear}',
                        style: AppTypography.labelSmall.copyWith(
                          color:
                              isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildStatusBadge(record.status),
            ],
          ),
          AppSpacing.gapH12,

          // Amounts Breakdown Box with subtle dividers
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space12,
              vertical: AppSpacing.space8,
            ),
            decoration: BoxDecoration(
              color: isDark ? AppColors.slate800 : AppColors.slate100,
              borderRadius: AppRadius.roundedSm,
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            child: Row(
              children: [
                _buildAmountItem(
                  label: 'Billed',
                  value: _fmtAmount(record.amount),
                  color:
                      isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                  isDark: isDark,
                ),
                Container(
                  width: 1,
                  height: 28,
                  color: isDark ? AppColors.slate700 : AppColors.slate200,
                ),
                _buildAmountItem(
                  label: 'Paid',
                  value: _fmtAmount(record.paidAmount),
                  color: AppColors.success,
                  isDark: isDark,
                ),
                Container(
                  width: 1,
                  height: 28,
                  color: isDark ? AppColors.slate700 : AppColors.slate200,
                ),
                _buildAmountItem(
                  label: 'Due',
                  value: _fmtAmount(record.dueAmount),
                  color:
                      record.status == FeeStatus.overdue
                          ? AppColors.error
                          : (record.dueAmount > 0
                              ? AppColors.warning
                              : (isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight)),
                  isDark: isDark,
                ),
              ],
            ),
          ),
          AppSpacing.gapH12,

          // Metadata Footer (Student ID, Date, Receipt)
          Wrap(
            spacing: 12,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.badge_outlined,
                    size: 13,
                    color: isDark ? AppColors.slate400 : AppColors.slate500,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Student ID: ${record.studentId}',
                    style: AppTypography.labelSmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.slate300 : AppColors.slate700,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 13,
                    color:
                        record.status == FeeStatus.overdue
                            ? AppColors.error
                            : (record.paidDate != null
                                ? AppColors.success
                                : (isDark
                                    ? AppColors.slate400
                                    : AppColors.slate500)),
                  ),
                  const SizedBox(width: 4),
                  if (record.paidDate != null)
                    Text(
                      'Paid on: ${_fmtDate(record.paidDate!)}',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  else
                    Text(
                      'Due: ${_fmtDate(record.dueDate)}',
                      style: AppTypography.labelSmall.copyWith(
                        color:
                            record.status == FeeStatus.overdue
                                ? AppColors.error
                                : (isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight),
                        fontWeight:
                            record.status == FeeStatus.overdue
                                ? FontWeight.w700
                                : FontWeight.normal,
                      ),
                    ),
                ],
              ),
              if (record.receiptNumber != null &&
                  record.receiptNumber!.isNotEmpty)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.receipt_outlined,
                      size: 13,
                      color: isDark ? AppColors.slate400 : AppColors.slate500,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Receipt: #${record.receiptNumber}',
                      style: AppTypography.labelSmall.copyWith(
                        color:
                            isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAmountItem({
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color:
                    isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: AppTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(FeeStatus status) {
    switch (status) {
      case FeeStatus.paid:
        return const AppStatusBadge.paid();
      case FeeStatus.overdue:
        return const AppStatusBadge.overdue();
      case FeeStatus.pending:
        return const AppStatusBadge.pending();
    }
  }
}

class _KpiData {
  final String title;
  final double amount;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color lightBg;
  final Color darkBg;

  const _KpiData({
    required this.title,
    required this.amount,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.lightBg,
    required this.darkBg,
  });
}
