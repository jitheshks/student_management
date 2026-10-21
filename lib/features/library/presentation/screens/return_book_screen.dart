import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:student_management/core/constants/app_radius.dart';
import 'package:student_management/core/constants/app_spacing.dart';
import 'package:student_management/core/theme/app_colors.dart';
import 'package:student_management/core/theme/app_typography.dart';
import 'package:student_management/features/library/presentation/controllers/return_book_controller.dart';
import 'package:student_management/features/library/presentation/providers/library_providers.dart';
import 'package:student_management/shared/models/borrow_record.dart';
import 'package:student_management/shared/widgets/app_card.dart';
import 'package:student_management/shared/widgets/app_status_badge.dart';
import 'package:student_management/shared/widgets/responsive_content.dart';

class ReturnBookScreen extends ConsumerStatefulWidget {
  const ReturnBookScreen({super.key});

  @override
  ConsumerState<ReturnBookScreen> createState() => _ReturnBookScreenState();
}

class _ReturnBookScreenState extends ConsumerState<ReturnBookScreen> {
  final TextEditingController _registerController = TextEditingController();

  @override
  void dispose() {
    _registerController.dispose();
    super.dispose();
  }

  String _fmt(DateTime d) => DateFormat('dd/MM/yyyy').format(d);

  Future<void> _handleReturn(BorrowRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Confirm Book Return'),
            content: Text(
              'Are you sure you want to mark "${record.bookTitle}" as returned?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Return Book'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      final controller = ref.read(returnBookControllerProvider.notifier);
      final success = await controller.returnBook(record);

      if (!mounted) return;
      final state = ref.read(returnBookControllerProvider);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              state.successMessage ?? 'Book returned successfully!',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      } else if (state.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.errorMessage!),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(returnBookControllerProvider);
    final controller = ref.read(returnBookControllerProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Return Books',
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
        child: Column(
          children: [
            // Search Header
            Container(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              padding: const EdgeInsets.all(AppSpacing.space16),
              child: ResponsiveContent(
                maxContentWidth: 900,
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Enter Registration Number',
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color:
                            isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                      ),
                    ),
                    AppSpacing.gapH8,
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _registerController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Registration Number',
                              hintText: 'e.g., 10800001',
                              prefixIcon: const Icon(
                                Icons.person_search_outlined,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.space12,
                                vertical: 14,
                              ),
                            ),
                            onFieldSubmitted:
                                (val) => controller.searchLoans(val),
                          ),
                        ),
                        AppSpacing.gapW8,
                        SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed:
                                state.isLoading
                                    ? null
                                    : () => controller.searchLoans(
                                      _registerController.text,
                                    ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: AppRadius.roundedSm,
                              ),
                            ),
                            child:
                                state.isLoading
                                    ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                    : const Text('Search'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1, thickness: 1),

            // Active Loans List Area
            Expanded(
              child: ResponsiveContent(
                maxContentWidth: 900,
                padding: const EdgeInsets.all(AppSpacing.space12),
                child: _buildBody(context, state, isDark),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, ReturnBookState state, bool isDark) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!state.hasSearched) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.menu_book_outlined,
              size: 56,
              color: isDark ? AppColors.slate600 : AppColors.slate400,
            ),
            AppSpacing.gapH12,
            Text(
              'Enter a student registration number\nto view active borrowed books.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
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

    if (state.activeLoans.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 56,
              color: isDark ? AppColors.success : const Color(0xFF10B981),
            ),
            AppSpacing.gapH12,
            Text(
              'No active borrowed books found for student #${state.searchedRegisterNumber}',
              textAlign: TextAlign.center,
              style: AppTypography.titleSmall.copyWith(
                fontWeight: FontWeight.w600,
                color:
                    isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: state.activeLoans.length,
      separatorBuilder: (context, index) => AppSpacing.gapH12,
      itemBuilder: (context, index) {
        final loan = state.activeLoans[index];
        final isReturningThis =
            state.isReturning && state.returningRecordId == loan.id;

        return AppCard(
          padding: const EdgeInsets.all(AppSpacing.space12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Book Cover
              Container(
                width: 52,
                height: 72,
                decoration: BoxDecoration(
                  borderRadius: AppRadius.roundedSm,
                  color: isDark ? AppColors.slate800 : AppColors.slate200,
                ),
                clipBehavior: Clip.antiAlias,
                child:
                    loan.coverUrl.isNotEmpty
                        ? Image.network(
                          loan.coverUrl,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (_, _, _) => Icon(
                                Icons.book,
                                size: 28,
                                color:
                                    isDark
                                        ? AppColors.slate500
                                        : AppColors.slate400,
                              ),
                        )
                        : Icon(
                          Icons.book,
                          size: 28,
                          color:
                              isDark ? AppColors.slate500 : AppColors.slate400,
                        ),
              ),
              AppSpacing.gapW12,

              // Loan Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loan.bookTitle,
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
                    if (loan.bookAuthor.isNotEmpty &&
                        loan.bookAuthor != 'Unknown Author')
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          'by ${loan.bookAuthor}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodySmall.copyWith(
                            color:
                                isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                          ),
                        ),
                      ),
                    AppSpacing.gapH8,
                    Wrap(
                      spacing: AppSpacing.space12,
                      runSpacing: AppSpacing.space4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'Borrowed: ${_fmt(loan.borrowedAt)}',
                          style: AppTypography.labelSmall.copyWith(
                            color:
                                isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                          ),
                        ),
                        Text(
                          'Due: ${_fmt(loan.dueDate)}',
                          style: AppTypography.labelSmall.copyWith(
                            fontWeight:
                                loan.isOverdue
                                    ? FontWeight.w700
                                    : FontWeight.normal,
                            color:
                                loan.isOverdue
                                    ? AppColors.error
                                    : (isDark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondaryLight),
                          ),
                        ),
                        if (loan.isOverdue)
                          const AppStatusBadge.overdue(
                            label: 'OVERDUE',
                            showDot: false,
                          ),
                      ],
                    ),
                    AppSpacing.gapH12,
                    Align(
                      alignment: Alignment.centerRight,
                      child: SizedBox(
                        height: 38,
                        child: ElevatedButton.icon(
                          onPressed:
                              isReturningThis
                                  ? null
                                  : () => _handleReturn(loan),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: AppRadius.roundedSm,
                            ),
                          ),
                          icon:
                              isReturningThis
                                  ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                  : const Icon(
                                    Icons.assignment_turned_in,
                                    size: 16,
                                  ),
                          label: Text(
                            isReturningThis ? 'Returning...' : 'Return Book',
                            style: AppTypography.labelMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
