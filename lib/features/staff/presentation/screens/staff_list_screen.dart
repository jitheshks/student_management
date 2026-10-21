import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:student_management/core/constants/app_constants.dart';
import 'package:student_management/core/constants/app_radius.dart';
import 'package:student_management/core/constants/app_spacing.dart';
import 'package:student_management/core/theme/app_colors.dart';
import 'package:student_management/core/theme/app_typography.dart';
import 'package:student_management/features/staff/presentation/controllers/staff_list_controller.dart';
import 'package:student_management/features/staff/presentation/providers/staff_providers.dart';
import 'package:student_management/features/staff/presentation/screens/staff_form_screen.dart';
import 'package:student_management/shared/models/staff.dart';
import 'package:student_management/shared/widgets/app_card.dart';
import 'package:student_management/shared/widgets/app_search_bar.dart';
import 'package:student_management/shared/widgets/app_status_badge.dart';
import 'package:student_management/shared/widgets/empty_state_view.dart';
import 'package:student_management/shared/widgets/error_view.dart';

class StaffListScreen extends ConsumerStatefulWidget {
  const StaffListScreen({super.key});

  @override
  ConsumerState<StaffListScreen> createState() => _StaffListScreenState();
}

class _StaffListScreenState extends ConsumerState<StaffListScreen> {
  static const List<String> _sortOptions = ['A-Z', 'Z-A'];

  static const List<String> _designations = [
    'All',
    ...AppConstants.designations,
  ];

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
              count == 1 ? 'Delete Staff' : 'Delete Staff Members',
              style: AppTypography.titleLarge.copyWith(
                color:
                    isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
              ),
            ),
            content: Text(
              count == 1
                  ? 'Are you sure you want to delete the selected staff member?'
                  : 'Are you sure you want to delete $count selected staff members?',
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
                          .read(staffListControllerProvider.notifier)
                          .deleteSelectedStaff();

                  if (!mounted) return;
                  final success = results['success'] ?? 0;
                  final fail = results['fail'] ?? 0;

                  if (success > 0) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          'Deleted $success staff member(s) successfully.',
                        ),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                  if (fail > 0) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          'Failed to delete $fail staff member(s).',
                        ),
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
    final state = ref.watch(staffListControllerProvider);
    final controller = ref.read(staffListControllerProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Staff Management',
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
                          onTap: controller.clearSelection,
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

            // Main Content Body
            Expanded(child: _buildBody(context, state, controller)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const StaffFormScreen()),
          );
          if (result == true && mounted) {
            ref.read(staffListControllerProvider.notifier).loadStaff();
          }
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add),
        label: const Text('Add Staff'),
      ),
    );
  }

  Widget _buildSearchAndFilters(
    BuildContext context,
    StaffListState state,
    StaffListController controller,
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

          final designationWidget = Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space12),
            decoration: BoxDecoration(
              color: surfaceColor,
              border: Border.all(color: borderColor),
              borderRadius: AppRadius.roundedSm,
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: state.selectedDesignationFilter,
                isExpanded: true,
                icon: const Icon(Icons.filter_list, size: 18),
                hint: const Text('Designation'),
                items:
                    _designations.map((designation) {
                      return DropdownMenuItem<String>(
                        value: designation,
                        child: Text(
                          designation == 'All'
                              ? 'All Designations'
                              : designation,
                          style: AppTypography.bodySmall.copyWith(
                            color: textColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                onChanged: (val) {
                  if (val != null) controller.setDesignationFilter(val);
                },
              ),
            ),
          );

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
                    _sortOptions.map((sort) {
                      return DropdownMenuItem<String>(
                        value: sort,
                        child: Text(
                          sort,
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

          if (isNarrow) {
            // Stack Search on Top and 2 side-by-side dropdowns below
            return Column(
              children: [
                AppSearchBar(
                  hintText: 'Search by name, designation, or email...',
                  onChanged: controller.setSearchQuery,
                ),
                AppSpacing.gapH8,
                Row(
                  children: [
                    Expanded(child: designationWidget),
                    AppSpacing.gapW8,
                    Expanded(child: sortWidget),
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
                    hintText: 'Search by name, designation, or email...',
                    onChanged: controller.setSearchQuery,
                  ),
                ),
                AppSpacing.gapW8,
                Expanded(flex: 2, child: designationWidget),
                AppSpacing.gapW8,
                Expanded(flex: 2, child: sortWidget),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    StaffListState state,
    StaffListController controller,
  ) {
    if (state.isLoading && state.staffList.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage != null && state.staffList.isEmpty) {
      return ErrorView(
        message: state.errorMessage!,
        onRetry: controller.loadStaff,
      );
    }

    final staffMembers = state.filteredStaffList;
    if (staffMembers.isEmpty) {
      return EmptyStateView(
        title: 'No staff members found',
        subtitle:
            state.searchQuery.isNotEmpty ||
                    state.selectedDesignationFilter != 'All'
                ? 'Try adjusting your search or filter settings.'
                : 'Get started by adding your first staff member.',
        actionLabel: 'Refresh',
        onAction: controller.loadStaff,
      );
    }

    return RefreshIndicator(
      onRefresh: controller.loadStaff,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;

          if (w < 480) {
            // Narrow mobile: 1-column list cards
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.space12,
                AppSpacing.space12,
                AppSpacing.space12,
                80,
              ),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: staffMembers.length,
              separatorBuilder: (context, index) => AppSpacing.gapH8,
              itemBuilder: (context, index) {
                final staff = staffMembers[index];
                final isSelected = state.selectedIds.contains(staff.id);

                return _StaffListTileCard(
                  staff: staff,
                  isSelected: isSelected,
                  onTap: () => _handleStaffTap(staff, state, controller),
                  onLongPress: () => controller.toggleSelection(staff.id),
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
            itemCount: staffMembers.length,
            itemBuilder: (context, index) {
              final staff = staffMembers[index];
              final isSelected = state.selectedIds.contains(staff.id);

              return _StaffGridCard(
                staff: staff,
                isSelected: isSelected,
                onTap: () => _handleStaffTap(staff, state, controller),
                onLongPress: () => controller.toggleSelection(staff.id),
              );
            },
          );
        },
      ),
    );
  }

  void _handleStaffTap(
    Staff staff,
    StaffListState state,
    StaffListController controller,
  ) async {
    if (state.hasSelection) {
      controller.toggleSelection(staff.id);
    } else {
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => StaffFormScreen(initialStaff: staff)),
      );
      if (result == true && mounted) {
        controller.loadStaff();
      }
    }
  }
}

/// Compact, horizontal card layout for narrow mobile screens
class _StaffListTileCard extends StatelessWidget {
  final Staff staff;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _StaffListTileCard({
    required this.staff,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasImage =
        staff.profileImageUrl != null &&
        staff.profileImageUrl!.trim().isNotEmpty;

    final displayName =
        staff.firstName.isNotEmpty
            ? '${staff.firstName} ${staff.lastName}'.trim()
            : (staff.name.isNotEmpty ? staff.name : 'Staff');

    final initials =
        (staff.firstName.isNotEmpty ? staff.firstName[0] : '') +
        (staff.lastName.isNotEmpty ? staff.lastName[0] : '');

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
                      : AppColors.accentContainer,
              backgroundImage:
                  hasImage ? NetworkImage(staff.profileImageUrl!) : null,
              child:
                  !hasImage
                      ? Text(
                        initials.isNotEmpty ? initials : 'S',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color:
                              isSelected
                                  ? AppColors.error
                                  : AppColors.accentDark,
                        ),
                      )
                      : null,
            ),
            AppSpacing.gapW12,

            // Staff Info
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
                  if (staff.email != null && staff.email!.isNotEmpty)
                    Text(
                      staff.email!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall.copyWith(
                        color:
                            isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                      ),
                    ),
                  if (staff.phone != null && staff.phone!.isNotEmpty)
                    Text(
                      staff.phone!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall.copyWith(
                        color:
                            isDark
                                ? AppColors.textMutedDark
                                : AppColors.textMutedLight,
                      ),
                    ),
                ],
              ),
            ),
            AppSpacing.gapW8,

            // Designation Badge
            AppStatusBadge(
              label: staff.designation.isNotEmpty ? staff.designation : 'Staff',
              status: BadgeStatus.info,
            ),
          ],
        ),
      ),
    );
  }
}

/// Grid card layout for tablet and desktop viewports
class _StaffGridCard extends StatelessWidget {
  final Staff staff;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _StaffGridCard({
    required this.staff,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasImage =
        staff.profileImageUrl != null &&
        staff.profileImageUrl!.trim().isNotEmpty;

    final displayName =
        staff.firstName.isNotEmpty
            ? '${staff.firstName} ${staff.lastName}'.trim()
            : (staff.name.isNotEmpty ? staff.name : 'Staff');

    final initials =
        (staff.firstName.isNotEmpty ? staff.firstName[0] : '') +
        (staff.lastName.isNotEmpty ? staff.lastName[0] : '');

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
                      : AppColors.accentContainer,
              backgroundImage:
                  hasImage ? NetworkImage(staff.profileImageUrl!) : null,
              child:
                  !hasImage
                      ? Text(
                        initials.isNotEmpty ? initials : 'S',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color:
                              isSelected
                                  ? AppColors.error
                                  : AppColors.accentDark,
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
            const SizedBox(height: 4),

            // Designation Badge
            AppStatusBadge(
              label: staff.designation.isNotEmpty ? staff.designation : 'Staff',
              status: BadgeStatus.info,
            ),
            const SizedBox(height: 4),

            // Email
            if (staff.email != null && staff.email!.isNotEmpty)
              Text(
                staff.email!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodySmall.copyWith(
                  color:
                      isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                  fontSize: 11,
                ),
              ),

            // Phone
            if (staff.phone != null && staff.phone!.isNotEmpty)
              Text(
                staff.phone!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodySmall.copyWith(
                  color:
                      isDark
                          ? AppColors.textMutedDark
                          : AppColors.textMutedLight,
                  fontSize: 11,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
