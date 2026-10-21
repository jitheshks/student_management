import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:student_management/core/constants/app_radius.dart';
import 'package:student_management/core/constants/app_spacing.dart';
import 'package:student_management/core/theme/app_colors.dart';
import 'package:student_management/core/theme/app_typography.dart';
import 'package:student_management/features/library/presentation/providers/library_providers.dart';
import 'package:student_management/features/library/presentation/screens/book_search_dialog.dart';
import 'package:student_management/shared/models/book.dart';
import 'package:student_management/shared/widgets/app_button.dart';
import 'package:student_management/shared/widgets/app_card.dart';
import 'package:student_management/shared/widgets/responsive_content.dart';

class BorrowBookScreen extends ConsumerStatefulWidget {
  const BorrowBookScreen({super.key});

  @override
  ConsumerState<BorrowBookScreen> createState() => _BorrowBookScreenState();
}

class _BorrowBookScreenState extends ConsumerState<BorrowBookScreen> {
  final TextEditingController _registerController = TextEditingController();

  @override
  void dispose() {
    _registerController.dispose();
    super.dispose();
  }

  String _fmt(DateTime d) => DateFormat('dd/MM/yyyy').format(d);

  Future<void> _pickDueDate(DateTime currentDue) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: currentDue,
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
    );
    if (picked != null) {
      ref.read(borrowBookControllerProvider.notifier).setDueDate(picked);
    }
  }

  Future<void> _submitBorrow() async {
    final controller = ref.read(borrowBookControllerProvider.notifier);
    final success = await controller.borrowBook();

    if (!mounted) return;
    final state = ref.read(borrowBookControllerProvider);

    if (success) {
      _registerController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.successMessage ?? 'Book borrowed successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context, true);
    } else if (state.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.errorMessage!),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(borrowBookControllerProvider);
    final controller = ref.read(borrowBookControllerProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final canSubmit =
        state.selectedBook != null &&
        state.verifiedStudent != null &&
        !state.isSubmitting;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Borrow a Book',
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
        child: ResponsiveContent.form(
          maxContentWidth: 760,
          padding: const EdgeInsets.all(AppSpacing.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Select Book Section
              Text(
                '1. Select Book',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color:
                      isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                ),
              ),
              AppSpacing.gapH8,
              AppCard(
                padding: const EdgeInsets.all(AppSpacing.space12),
                onTap: () async {
                  final Book? selected = await Navigator.push<Book>(
                    context,
                    MaterialPageRoute(builder: (_) => const BookSearchDialog()),
                  );
                  if (selected != null) {
                    controller.setSelectedBook(selected);
                  }
                },
                child:
                    state.selectedBook != null
                        ? Row(
                          children: [
                            Container(
                              width: 48,
                              height: 64,
                              decoration: BoxDecoration(
                                borderRadius: AppRadius.roundedSm,
                                color:
                                    isDark
                                        ? AppColors.slate800
                                        : AppColors.slate200,
                              ),
                              clipBehavior: Clip.antiAlias,
                              child:
                                  state.selectedBook!.coverUrl.isNotEmpty
                                      ? Image.network(
                                        state.selectedBook!.coverUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (_, _, _) => Icon(
                                              Icons.book,
                                              size: 24,
                                              color:
                                                  isDark
                                                      ? AppColors.slate500
                                                      : AppColors.slate400,
                                            ),
                                      )
                                      : Icon(
                                        Icons.book,
                                        size: 24,
                                        color:
                                            isDark
                                                ? AppColors.slate500
                                                : AppColors.slate400,
                                      ),
                            ),
                            AppSpacing.gapW12,
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    state.selectedBook!.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
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
                                    'by ${state.selectedBook!.author}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.bodySmall.copyWith(
                                      color:
                                          isDark
                                              ? AppColors.textSecondaryDark
                                              : AppColors.textSecondaryLight,
                                    ),
                                  ),
                                  Text(
                                    'ISBN: ${state.selectedBook!.isbn}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.labelSmall.copyWith(
                                      color:
                                          isDark
                                              ? AppColors.slate400
                                              : AppColors.slate500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: AppColors.error,
                              ),
                              tooltip: 'Remove book',
                              onPressed: controller.clearSelectedBook,
                            ),
                          ],
                        )
                        : Row(
                          children: [
                            Icon(
                              Icons.search,
                              color:
                                  isDark
                                      ? AppColors.slate400
                                      : AppColors.slate600,
                            ),
                            AppSpacing.gapW12,
                            Expanded(
                              child: Text(
                                'Tap to search and select a book',
                                style: AppTypography.bodyMedium.copyWith(
                                  color:
                                      isDark
                                          ? AppColors.textSecondaryDark
                                          : AppColors.textSecondaryLight,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 14,
                              color:
                                  isDark
                                      ? AppColors.slate500
                                      : AppColors.slate400,
                            ),
                          ],
                        ),
              ),
              AppSpacing.gapH24,

              // 2. Student Verification Section
              Text(
                '2. Student Verification',
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
                        hintText: 'e.g. 10800001',
                        prefixIcon: const Icon(Icons.badge_outlined),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.space12,
                          vertical: 14,
                        ),
                      ),
                      onFieldSubmitted:
                          (val) => controller.verifyStudentByRegister(val),
                    ),
                  ),
                  AppSpacing.gapW8,
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed:
                          state.isSearchingStudent
                              ? null
                              : () => controller.verifyStudentByRegister(
                                _registerController.text,
                              ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.roundedSm,
                        ),
                      ),
                      child:
                          state.isSearchingStudent
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                              : const Text('Verify'),
                    ),
                  ),
                ],
              ),
              AppSpacing.gapH12,

              // Verified Student Display Card
              if (state.verifiedStudent != null)
                AppCard(
                  padding: const EdgeInsets.all(AppSpacing.space12),
                  backgroundColor:
                      isDark
                          ? AppColors.success.withValues(alpha: 0.15)
                          : AppColors.successContainer,
                  borderColor:
                      isDark
                          ? AppColors.success.withValues(alpha: 0.4)
                          : const Color(0xFFA7F3D0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.success,
                        radius: 18,
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      AppSpacing.gapW12,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${state.verifiedStudent!.firstName} ${state.verifiedStudent!.lastName}',
                              style: AppTypography.titleSmall.copyWith(
                                fontWeight: FontWeight.w700,
                                color:
                                    isDark
                                        ? AppColors.textPrimaryDark
                                        : AppColors.textPrimaryLight,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Class: ${state.verifiedStudent!.standard}  •  Reg: ${state.verifiedStudent!.registerNumber}',
                              style: AppTypography.bodySmall.copyWith(
                                color:
                                    isDark
                                        ? const Color(0xFF6EE7B7)
                                        : AppColors.onSuccessContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              AppSpacing.gapH24,

              // 3. Loan Due Date Section
              Text(
                '3. Loan Due Date',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color:
                      isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                ),
              ),
              AppSpacing.gapH8,
              AppCard(
                padding: const EdgeInsets.all(AppSpacing.space12),
                onTap: () => _pickDueDate(state.dueDate),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color:
                            isDark
                                ? AppColors.primaryDark.withValues(alpha: 0.3)
                                : AppColors.primaryContainer,
                        borderRadius: AppRadius.roundedSm,
                      ),
                      child: const Icon(
                        Icons.calendar_today,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    AppSpacing.gapW12,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Return Due Date',
                            style: AppTypography.labelSmall.copyWith(
                              color:
                                  isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondaryLight,
                            ),
                          ),
                          Text(
                            _fmt(state.dueDate),
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
                    ),
                    Text(
                      'Change',
                      style: AppTypography.labelMedium.copyWith(
                        color:
                            isDark ? AppColors.primaryLight : AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              AppSpacing.gapH32,

              // Submit Button
              AppButton(
                text: 'Borrow Book',
                onPressed: canSubmit ? _submitBorrow : null,
                isLoading: state.isSubmitting,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
