import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:student_management/common/widgets/custom_app_bar.dart';
import 'package:student_management/controller/student_dashboard_controller.dart';
import 'package:student_management/controller/student_library_controller.dart';
import 'package:student_management/core/constants/app_spacing.dart';
import 'package:student_management/core/theme/app_colors.dart';
import 'package:student_management/core/theme/app_typography.dart';
import 'package:student_management/shared/widgets/app_card.dart';
import 'package:student_management/shared/widgets/app_status_badge.dart';
import 'package:student_management/shared/widgets/empty_state_view.dart';
import 'package:student_management/shared/widgets/error_view.dart';
import 'package:student_management/shared/widgets/responsive_content.dart';

/// A modern, responsive library history screen for students.
///
/// Displays student borrowing records, active loans, returned items, and overdue statuses.
class StudentLibraryScreen extends StatelessWidget {
  final String id; // auth uid if filterByUserId=true, else students.id
  final bool filterByUserId;
  final StudentLibraryController? controller;

  const StudentLibraryScreen({
    super.key,
    required this.id,
    this.filterByUserId = true,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    if (controller != null) {
      return ChangeNotifierProvider<StudentLibraryController>.value(
        value: controller!,
        child: _LibraryView(id: id, filterByUserId: filterByUserId),
      );
    }

    return ChangeNotifierProvider(
      create:
          (_) =>
              StudentLibraryController()
                ..load(id, filterByUserId: filterByUserId),
      child: _LibraryView(id: id, filterByUserId: filterByUserId),
    );
  }
}

class _LibraryView extends StatelessWidget {
  final String id;
  final bool filterByUserId;

  const _LibraryView({required this.id, required this.filterByUserId});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<StudentLibraryController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Header with CustomSliverHeader and logout control
          CustomSliverHeader(
            icon: const Icon(Icons.menu_book_rounded, color: AppColors.primary),
            title: const Text('Library History'),
            subtitle: Builder(
              builder: (context) {
                final c = context.watch<StudentLibraryController>();
                return Text('${c.items.length} Books Record');
              },
            ),
            actions: [
              Builder(
                builder:
                    (context) => IconButton(
                      icon: const Icon(Icons.logout, color: Colors.white),
                      tooltip: 'Logout',
                      onPressed: () {
                        try {
                          context.read<StudentDashboardController>().logout(
                            context,
                          );
                        } catch (_) {}
                      },
                    ),
              ),
            ],
          ),

          if (c.loading)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          else if (c.error != null)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: ErrorView(
                  message: 'Error: ${c.error}',
                  onRetry: () => c.load(id, filterByUserId: filterByUserId),
                ),
              ),
            )
          else if (c.items.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyStateView(
                title: 'No Borrowed Books',
                subtitle:
                    'You have not borrowed any books from the library yet.',
                icon: Icons.menu_book_outlined,
              ),
            )
          else
            SliverToBoxAdapter(
              child: ResponsiveContent(
                maxContentWidth: 900,
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.space16,
                  AppSpacing.space16,
                  AppSpacing.space16,
                  AppSpacing.space32,
                ),
                child: Column(
                  children:
                      c.items
                          .map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.space12,
                              ),
                              child: _BookCard(item: item),
                            ),
                          )
                          .toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BookCard extends StatelessWidget {
  final StudentLibraryItem item;
  const _BookCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover Thumbnail
          Container(
            width: 68,
            height: 94,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: isDark ? AppColors.surfaceVariantDark : AppColors.slate100,
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child:
                item.coverUrl.isNotEmpty
                    ? Image.network(
                      item.coverUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _coverFallback(),
                    )
                    : _coverFallback(),
          ),
          const SizedBox(width: AppSpacing.space16),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color:
                        isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'by ${item.author}',
                  style: AppTypography.bodySmall.copyWith(
                    color:
                        isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.space8),
                _buildStatusBadge(item.status),
                const SizedBox(height: AppSpacing.space8),
                _dateRow(
                  context,
                  Icons.calendar_today_rounded,
                  'Borrowed: ${_fmt(item.borrowedAt)}',
                ),
                if (item.returnedAt != null)
                  _dateRow(
                    context,
                    Icons.reply_rounded,
                    'Returned: ${_fmt(item.returnedAt!)}',
                  )
                else if (item.dueDate != null)
                  _dateRow(
                    context,
                    Icons.event_outlined,
                    'Due: ${_fmt(item.dueDate!)}',
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _fmt(DateTime d) => DateFormat('d/M/yyyy').format(d);

  Widget _coverFallback() => const Center(
    child: Icon(Icons.menu_book, color: AppColors.slate400, size: 30),
  );

  Widget _buildStatusBadge(String status) {
    switch (status) {
      case 'returned':
        return const AppStatusBadge.returned(label: 'Returned');
      case 'overdue':
        return const AppStatusBadge.overdue(label: 'Overdue');
      default:
        return AppStatusBadge(
          label: 'Currently Borrowed',
          status: BadgeStatus.info,
          icon: Icons.bookmark_outline,
          customBackgroundColor: AppColors.primary.withValues(alpha: 0.1),
          customTextColor: AppColors.primary,
          customBorderColor: AppColors.primary.withValues(alpha: 0.3),
        );
    }
  }

  Widget _dateRow(BuildContext context, IconData icon, String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: AppSpacing.space8),
          Flexible(
            child: Text(
              text,
              style: AppTypography.bodySmall.copyWith(
                fontSize: 12,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
