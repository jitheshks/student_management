import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:student_management/core/constants/app_constants.dart';
import 'package:student_management/core/constants/app_radius.dart';
import 'package:student_management/core/constants/app_spacing.dart';
import 'package:student_management/core/theme/app_colors.dart';
import 'package:student_management/core/theme/app_typography.dart';
import 'package:student_management/features/students/presentation/controllers/student_list_controller.dart';
import 'package:student_management/features/students/presentation/providers/student_providers.dart';
import 'package:student_management/features/students/presentation/screens/student_form_screen.dart';
import 'package:student_management/shared/models/student.dart';
import 'package:student_management/shared/widgets/app_card.dart';
import 'package:student_management/shared/widgets/app_search_bar.dart';
import 'package:student_management/shared/widgets/app_status_badge.dart';
import 'package:student_management/shared/widgets/empty_state_view.dart';
import 'package:student_management/shared/widgets/error_view.dart';

class StudentListScreen extends ConsumerStatefulWidget {
  const StudentListScreen({super.key});

  @override
  ConsumerState<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends ConsumerState<StudentListScreen> {
  static const List<String> _sortOptions = [
    'A-Z',
    'Z-A',
    'Register Number ↑',
    'Register Number ↓',
  ];

  static const List<String> _standards = ['All', ...AppConstants.standards];

  void _showDeleteDialog(BuildContext context, int count) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder:
          (dialogCtx) => AlertDialog(
            backgroundColor:
                isDark
                    ? AppColors.dialogSurfaceDark
                    : AppColors.dialogSurfaceLight,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.dialog),
            title: Text(
              count == 1 ? 'Delete Student' : 'Delete Students',
              style: AppTypography.titleLarge.copyWith(
                color:
                    isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
              ),
            ),
            content: Text(
              count == 1
                  ? 'Are you sure you want to delete the selected student?'
                  : 'Are you sure you want to delete $count selected students?',
              style: AppTypography.bodyMedium.copyWith(
                color:
                    isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: isDark ? AppColors.slate300 : AppColors.slate600,
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.roundedSm,
                  ),
                ),
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  Navigator.pop(dialogCtx);
                  final results =
                      await ref
                          .read(studentListControllerProvider.notifier)
                          .bulkDeleteSelected();

                  if (!mounted) return;
                  final success = results['success'] ?? 0;
                  final fail = results['fail'] ?? 0;

                  if (success > 0) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          'Deleted $success student(s) successfully.',
                        ),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                  if (fail > 0) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('Failed to delete $fail student(s).'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                },
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(studentListControllerProvider);
    final controller = ref.read(studentListControllerProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Student Management',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        foregroundColor: Colors.white,
        backgroundColor: Colors.transparent,
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
          if (state.hasSelection)
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: 'Delete Selected (${state.selectedCount})',
              onPressed:
                  state.isDeleting
                      ? null
                      : () => _showDeleteDialog(context, state.selectedCount),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Responsive Search and Filters Header
            _buildSearchAndFilters(context, state, controller, isDark),

            // Selection Toolbar
            if (state.hasSelection)
              Container(
                width: double.infinity,
                color:
                    isDark
                        ? AppColors.error.withValues(alpha: 0.15)
                        : AppColors.errorContainer,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space12,
                  vertical: AppSpacing.space4,
                ),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: AppSpacing.space8,
                  runSpacing: AppSpacing.space4,
                  children: [
                    Text(
                      '${state.selectedCount} selected',
                      style: AppTypography.labelMedium.copyWith(
                        color:
                            isDark ? const Color(0xFFFCA5A5) : AppColors.error,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          onTap: controller.selectAll,
                          borderRadius: AppRadius.roundedXs,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            child: Text(
                              'Select All',
                              style: AppTypography.labelMedium.copyWith(
                                color:
                                    isDark
                                        ? AppColors.primaryLight
                                        : AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        AppSpacing.gapW8,
                        InkWell(
                          onTap: controller.clearSelections,
                          borderRadius: AppRadius.roundedXs,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            child: Text(
                              'Clear',
                              style: AppTypography.labelMedium.copyWith(
                                color:
                                    isDark
                                        ? AppColors.slate300
                                        : AppColors.slate600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            const Divider(height: 1, thickness: 1),

            // Body: Loading, Error, Empty, or Responsive Student Grid/List
            Expanded(child: _buildBody(context, state, controller)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        tooltip: 'Add Student',
        onPressed: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const StudentFormScreen()),
          );
          if (result == true && mounted) {
            controller.loadStudents();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSearchAndFilters(
    BuildContext context,
    StudentListState state,
    StudentListController controller,
    bool isDark,
  ) {
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : Colors.white;
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space12,
        AppSpacing.space12,
        AppSpacing.space12,
        AppSpacing.space8,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 450;

          final sortWidget = Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space12),
            decoration: BoxDecoration(
              color: surfaceColor,
              border: Border.all(color: borderColor),
              borderRadius: AppRadius.roundedSm,
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: state.selectedSort,
                isExpanded: true,
                icon: const Icon(Icons.sort, size: 18),
                items:
                    _sortOptions.map((opt) {
                      return DropdownMenuItem(
                        value: opt,
                        child: Text(
                          opt,
                          style: AppTypography.bodySmall.copyWith(
                            color: textColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                onChanged: (val) {
                  if (val != null) controller.setSort(val);
                },
              ),
            ),
          );

          final standardWidget = Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space12),
            decoration: BoxDecoration(
              color: surfaceColor,
              border: Border.all(color: borderColor),
              borderRadius: AppRadius.roundedSm,
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: state.selectedStandard,
                isExpanded: true,
                icon: const Icon(Icons.filter_list, size: 18),
                items:
                    _standards.map((std) {
                      return DropdownMenuItem(
                        value: std,
                        child: Text(
                          std == 'All' ? 'All Classes' : std,
                          style: AppTypography.bodySmall.copyWith(
                            color: textColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                onChanged: (val) {
                  if (val != null) controller.setStandard(val);
                },
              ),
            ),
          );

          if (isNarrow) {
            // Stack Search on Top and 2 side-by-side dropdowns below
            return Column(
              children: [
                AppSearchBar(
                  hintText: 'Search by name, reg no, or email...',
                  onChanged: controller.setSearchQuery,
                ),
                AppSpacing.gapH8,
                Row(
                  children: [
                    Expanded(child: sortWidget),
                    AppSpacing.gapW8,
                    Expanded(child: standardWidget),
                  ],
                ),
              ],
            );
          } else {
            // Horizontal row with search taking flexible space and dropdowns on right
            return Row(
              children: [
                Expanded(
                  flex: 3,
                  child: AppSearchBar(
                    hintText: 'Search by name, reg no, or email...',
                    onChanged: controller.setSearchQuery,
                  ),
                ),
                AppSpacing.gapW8,
                Expanded(flex: 2, child: sortWidget),
                AppSpacing.gapW8,
                Expanded(flex: 2, child: standardWidget),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    StudentListState state,
    StudentListController controller,
  ) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage != null && state.students.isEmpty) {
      return ErrorView(
        message: state.errorMessage!,
        onRetry: controller.loadStudents,
      );
    }

    final students = state.filteredStudents;

    if (students.isEmpty) {
      return RefreshIndicator(
        onRefresh: controller.loadStudents,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: EmptyStateView(
              title: 'No students found',
              subtitle:
                  state.students.isEmpty
                      ? 'No students registered yet. Add one using the "+" button below.'
                      : 'No students match the current filters.',
              actionLabel: 'Refresh',
              onAction: controller.loadStudents,
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: controller.loadStudents,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;

          if (w < 480) {
            // Narrow mobile: clean, readable 1-column list cards
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.space12,
                AppSpacing.space12,
                AppSpacing.space12,
                80,
              ),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: students.length,
              separatorBuilder: (context, index) => AppSpacing.gapH8,
              itemBuilder: (context, index) {
                final student = students[index];
                final isSelected = state.selectedIds.contains(student.id);

                return _StudentListTileCard(
                  student: student,
                  isSelected: isSelected,
                  onTap: () => _handleStudentTap(student, state, controller),
                  onLongPress: () => controller.toggleSelection(student.id),
                );
              },
            );
          }

          // Tablet and Desktop: Responsive multi-column grid
          int crossAxisCount = 2;
          double aspectRatio = 1.15;

          if (w >= 1250) {
            crossAxisCount = 4;
            aspectRatio = 1.1;
          } else if (w >= 850) {
            crossAxisCount = 3;
            aspectRatio = 1.1;
          } else if (w >= 650) {
            crossAxisCount = 2;
            aspectRatio = 1.25;
          } else {
            crossAxisCount = 2;
            aspectRatio = 1.05;
          }

          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.space12,
              AppSpacing.space12,
              AppSpacing.space12,
              80,
            ),
            physics: const AlwaysScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: AppSpacing.space12,
              crossAxisSpacing: AppSpacing.space12,
              childAspectRatio: aspectRatio,
            ),
            itemCount: students.length,
            itemBuilder: (context, index) {
              final student = students[index];
              final isSelected = state.selectedIds.contains(student.id);

              return _StudentGridCard(
                student: student,
                isSelected: isSelected,
                onTap: () => _handleStudentTap(student, state, controller),
                onLongPress: () => controller.toggleSelection(student.id),
              );
            },
          );
        },
      ),
    );
  }

  void _handleStudentTap(
    Student student,
    StudentListState state,
    StudentListController controller,
  ) async {
    if (state.hasSelection) {
      controller.toggleSelection(student.id);
    } else {
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => StudentFormScreen(initialStudent: student),
        ),
      );
      if (result == true && mounted) {
        controller.loadStudents();
      }
    }
  }
}

/// Compact, horizontal card layout for narrow mobile screens
class _StudentListTileCard extends StatelessWidget {
  final Student student;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _StudentListTileCard({
    required this.student,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasImage =
        student.profileImageUrl != null &&
        student.profileImageUrl!.trim().isNotEmpty;

    final displayName =
        student.displayName.isNotEmpty
            ? student.displayName
            : '${student.firstName} ${student.lastName}'.trim();

    final selectedBg =
        isDark ? const Color(0xFF451A1A) : AppColors.errorContainer;
    final selectedBorder =
        isDark ? const Color(0xFFB91C1C) : const Color(0xFFFCA5A5);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.space12),
      backgroundColor: isSelected ? selectedBg : null,
      borderColor: isSelected ? selectedBorder : null,
      elevation: isSelected ? 3 : 1,
      onTap: onTap,
      child: InkWell(
        onLongPress: onLongPress,
        borderRadius: AppRadius.card,
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 26,
              backgroundColor:
                  isSelected
                      ? (isDark
                          ? const Color(0xFF7F1D1D)
                          : const Color(0xFFFEE2E2))
                      : AppColors.primaryContainer,
              backgroundImage:
                  hasImage ? NetworkImage(student.profileImageUrl!) : null,
              child:
                  !hasImage
                      ? Text(
                        student.initials.isNotEmpty ? student.initials : 'S',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color:
                              isSelected ? AppColors.error : AppColors.primary,
                        ),
                      )
                      : null,
            ),
            AppSpacing.gapW12,

            // Student Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Reg: ${student.registerNumber}',
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
                    'Class: ${student.standard}',
                    maxLines: 1,
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

            // Attendance Status Badge
            _buildAttendanceBadge(student.attendance),
          ],
        ),
      ),
    );
  }
}

/// Grid card layout for tablet and desktop viewports
class _StudentGridCard extends StatelessWidget {
  final Student student;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _StudentGridCard({
    required this.student,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasImage =
        student.profileImageUrl != null &&
        student.profileImageUrl!.trim().isNotEmpty;

    final displayName =
        student.displayName.isNotEmpty
            ? student.displayName
            : '${student.firstName} ${student.lastName}'.trim();

    final selectedBg =
        isDark ? const Color(0xFF451A1A) : AppColors.errorContainer;
    final selectedBorder =
        isDark ? const Color(0xFFB91C1C) : const Color(0xFFFCA5A5);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.space12),
      backgroundColor: isSelected ? selectedBg : null,
      borderColor: isSelected ? selectedBorder : null,
      elevation: isSelected ? 3 : 1,
      onTap: onTap,
      child: InkWell(
        onLongPress: onLongPress,
        borderRadius: AppRadius.card,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Avatar
            CircleAvatar(
              radius: 30,
              backgroundColor:
                  isSelected
                      ? (isDark
                          ? const Color(0xFF7F1D1D)
                          : const Color(0xFFFEE2E2))
                      : AppColors.primaryContainer,
              backgroundImage:
                  hasImage ? NetworkImage(student.profileImageUrl!) : null,
              child:
                  !hasImage
                      ? Text(
                        student.initials.isNotEmpty ? student.initials : 'S',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color:
                              isSelected ? AppColors.error : AppColors.primary,
                        ),
                      )
                      : null,
            ),
            const SizedBox(height: 8),

            // Full Name
            Text(
              displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 2),

            // Register Number
            Text(
              'Reg: ${student.registerNumber}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySmall.copyWith(
                color:
                    isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
              ),
            ),

            // Standard
            Text(
              'Class: ${student.standard}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySmall.copyWith(
                color:
                    isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 6),

            // Attendance Badge
            _buildAttendanceBadge(student.attendance),
          ],
        ),
      ),
    );
  }
}

Widget _buildAttendanceBadge(int attendance) {
  if (attendance >= 75) {
    return AppStatusBadge.active(
      label: '$attendance%',
      icon: Icons.check_circle_outline,
    );
  } else if (attendance >= 50) {
    return AppStatusBadge.pending(label: '$attendance%', icon: Icons.schedule);
  } else {
    return AppStatusBadge.overdue(
      label: '$attendance%',
      icon: Icons.warning_amber_rounded,
    );
  }
}
