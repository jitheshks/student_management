import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:student_management/core/constants/app_constants.dart';
import 'package:student_management/core/constants/app_radius.dart';
import 'package:student_management/core/constants/app_spacing.dart';
import 'package:student_management/core/theme/app_colors.dart';
import 'package:student_management/core/theme/app_typography.dart';
import 'package:student_management/features/library/presentation/controllers/library_history_controller.dart';
import 'package:student_management/features/library/presentation/providers/library_providers.dart';
import 'package:student_management/shared/models/borrow_record.dart';
import 'package:student_management/shared/widgets/app_card.dart';
import 'package:student_management/shared/widgets/app_search_bar.dart';
import 'package:student_management/shared/widgets/app_status_badge.dart';
import 'package:student_management/shared/widgets/empty_state_view.dart';
import 'package:student_management/shared/widgets/error_view.dart';
import 'package:student_management/shared/widgets/responsive_content.dart';

class LibraryHistoryScreen extends ConsumerStatefulWidget {
  const LibraryHistoryScreen({super.key});

  @override
  ConsumerState<LibraryHistoryScreen> createState() =>
      _LibraryHistoryScreenState();
}

class _LibraryHistoryScreenState extends ConsumerState<LibraryHistoryScreen> {
  final List<String> _sortOptions = const [
    'A-Z',
    'Z-A',
    'Register Number ↑',
    'Register Number ↓',
    'Due Date ↑',
    'Due Date ↓',
  ];

  final List<String> _statusOptions = const [
    'All',
    'Borrowed',
    'Returned',
    'Overdue',
  ];

  late final List<String> _standards = ['All', ...AppConstants.standards];

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(libraryHistoryControllerProvider);
    final controller = ref.read(libraryHistoryControllerProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Library History',
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
            onPressed: state.isLoading ? null : controller.loadHistory,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Input
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.space12,
                AppSpacing.space12,
                AppSpacing.space12,
                AppSpacing.space4,
              ),
              child: AppSearchBar(
                hintText: 'Search by title, student, or reg no...',
                onChanged: controller.setSearchQuery,
              ),
            ),

            // Horizontal Filter & Sort Bar
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space12,
                vertical: AppSpacing.space4,
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    // Sort Dropdown
                    _buildFilterDropdown(
                      icon: Icons.sort,
                      value: state.selectedSort,
                      items: _sortOptions,
                      onChanged: (val) {
                        if (val != null) controller.setSort(val);
                      },
                      isDark: isDark,
                    ),
                    AppSpacing.gapW8,

                    // Standard Filter
                    _buildFilterDropdown(
                      icon: Icons.school_outlined,
                      value: state.selectedStandard,
                      items: _standards,
                      onChanged: (val) {
                        if (val != null) controller.setStandard(val);
                      },
                      isDark: isDark,
                    ),
                    AppSpacing.gapW8,

                    // Status Filter
                    _buildFilterDropdown(
                      icon: Icons.filter_list,
                      value: state.selectedStatus,
                      items: _statusOptions,
                      onChanged: (val) {
                        if (val != null) controller.setStatus(val);
                      },
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1, thickness: 1),

            // Main Content Area
            Expanded(child: _buildContent(context, state, controller, isDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterDropdown({
    required IconData icon,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required bool isDark,
  }) {
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : Colors.white;
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space8),
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border.all(color: borderColor),
        borderRadius: AppRadius.roundedSm,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          icon: Icon(
            Icons.arrow_drop_down,
            size: 18,
            color: isDark ? AppColors.slate400 : AppColors.slate500,
          ),
          items:
              items.map((opt) {
                return DropdownMenuItem<String>(
                  value: opt,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icon,
                        size: 14,
                        color: isDark ? AppColors.slate400 : AppColors.slate500,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        opt,
                        style: AppTypography.labelMedium.copyWith(
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    LibraryHistoryState state,
    LibraryHistoryController controller,
    bool isDark,
  ) {
    if (state.isLoading && state.history.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage != null && state.history.isEmpty) {
      return ErrorView(
        message: state.errorMessage!,
        onRetry: controller.loadHistory,
      );
    }

    final records = state.filteredHistory;

    if (records.isEmpty) {
      return RefreshIndicator(
        onRefresh: controller.loadHistory,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            child: EmptyStateView(
              title: 'No library records found',
              subtitle:
                  state.history.isEmpty
                      ? 'No book loans have been recorded yet.'
                      : 'No records match the current filters.',
              actionLabel: 'Refresh',
              onAction: controller.loadHistory,
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: controller.loadHistory,
      child: ResponsiveContent(
        maxContentWidth: 1000,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.space12,
          AppSpacing.space8,
          AppSpacing.space12,
          AppSpacing.space24,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;

            if (width < 700) {
              // Narrow mobile & small tablets: 1-column list of responsive cards
              return ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: records.length,
                separatorBuilder: (context, index) => AppSpacing.gapH8,
                itemBuilder: (context, index) {
                  return _BorrowRecordCard(record: records[index]);
                },
              );
            } else {
              // Wide tablets & desktops: 2-column grid of history cards
              return GridView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: records.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: AppSpacing.space12,
                  crossAxisSpacing: AppSpacing.space12,
                  childAspectRatio: 2.2,
                ),
                itemBuilder: (context, index) {
                  return _BorrowRecordCard(record: records[index]);
                },
              );
            }
          },
        ),
      ),
    );
  }
}

class _BorrowRecordCard extends StatelessWidget {
  final BorrowRecord record;

  const _BorrowRecordCard({required this.record});

  String _fmt(DateTime d) => DateFormat('dd/MM/yyyy').format(d);

  Widget _buildStatusBadge(BorrowStatus status) {
    switch (status) {
      case BorrowStatus.returned:
        return const AppStatusBadge.returned(label: 'Returned');
      case BorrowStatus.overdue:
        return const AppStatusBadge.overdue(label: 'Overdue');
      case BorrowStatus.borrowed:
        return const AppStatusBadge.active(label: 'Borrowed');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.space12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Book cover / icon
          Container(
            width: 48,
            height: 68,
            decoration: BoxDecoration(
              borderRadius: AppRadius.roundedSm,
              color: isDark ? AppColors.slate800 : AppColors.slate200,
            ),
            clipBehavior: Clip.antiAlias,
            child:
                record.coverUrl.isNotEmpty
                    ? Image.network(
                      record.coverUrl,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (_, _, _) => Icon(
                            Icons.book,
                            size: 26,
                            color:
                                isDark
                                    ? AppColors.slate500
                                    : AppColors.slate400,
                          ),
                    )
                    : Icon(
                      Icons.book,
                      size: 26,
                      color: isDark ? AppColors.slate500 : AppColors.slate400,
                    ),
          ),
          AppSpacing.gapW12,

          // Book & Student Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        record.bookTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color:
                              isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimaryLight,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildStatusBadge(record.status),
                  ],
                ),
                if (record.bookAuthor.isNotEmpty &&
                    record.bookAuthor != 'Unknown Author')
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'by ${record.bookAuthor}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall.copyWith(
                        color:
                            isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                AppSpacing.gapH8,

                // Student details
                Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 13,
                      color: isDark ? AppColors.slate400 : AppColors.slate500,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${record.studentName ?? "Student"} (${record.studentRegisterNumber})',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: AppTypography.labelSmall.copyWith(
                          fontWeight: FontWeight.w600,
                          color:
                              isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.slate700,
                        ),
                      ),
                    ),
                    if (record.standard != null &&
                        record.standard != 'N/A') ...[
                      const SizedBox(width: 6),
                      Text(
                        'Class: ${record.standard}',
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
                AppSpacing.gapH4,

                // Dates
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    Text(
                      'Due: ${_fmt(record.dueDate)}',
                      style: AppTypography.labelSmall.copyWith(
                        fontWeight:
                            record.isOverdue
                                ? FontWeight.w700
                                : FontWeight.normal,
                        color:
                            record.isOverdue
                                ? AppColors.error
                                : (isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight),
                      ),
                    ),
                    if (record.returnedAt != null)
                      Text(
                        'Returned: ${_fmt(record.returnedAt!)}',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
