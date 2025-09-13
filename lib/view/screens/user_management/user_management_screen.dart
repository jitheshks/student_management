import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:student_management/common/widgets/sort_filter_widget.dart';
import 'package:student_management/controller/staff_management_controller.dart';
import 'package:student_management/controller/student_management_controller.dart';
import 'package:student_management/model/staff_model.dart';
import 'package:student_management/model/student_model.dart';

class UserManagementScreen<T extends ChangeNotifier> extends StatelessWidget {
  final String userType; // 'student' or 'staff'
  final String title;
  final bool showSort;
  final String formRoute;

  const UserManagementScreen({
    super.key,
    required this.userType,
    required this.title,
    required this.showSort,
    required this.formRoute,
  });

  void _showDeleteDialog(BuildContext context) {
    final safeContext = context;
    final controller = Provider.of<T>(context, listen: false);

    showDialog(
      context: context,
      useRootNavigator: false,
      builder: (dialogCtx) => ChangeNotifierProvider<T>.value(
        value: controller,
        child: Consumer<T>(
          builder: (_, ctrl, __) {
            final dynamic c = ctrl;
            final bool isDeleting = (c.isDeleting == true);
            final bool busy = (c.isLoading == true) || isDeleting;
            final Iterable<String> selectedIds =
                ((c.selectedItems ?? c.selectedUsers ?? <String>[]) as Iterable)
                    .cast<String>();

            // Auto-close if nothing is selected
            if (selectedIds.isEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (dialogCtx.mounted && Navigator.canPop(dialogCtx)) {
                  Navigator.pop(dialogCtx);
                }
              });
            }

            return AlertDialog(
              title: Text('Delete $userType'),
              content: Text(
                  'Are you sure you want to delete the selected $userType(s)?'),
              actions: [
                TextButton(
                  onPressed: busy ? null : () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel'),
                ),
                TextButton(
  onPressed: busy
      ? null
      : () async {
          Navigator.pop(dialogCtx);

          final list = c.items ?? [];
          int success = 0, fail = 0;

          // Debugging: print list type
          debugPrint('>>> Bulk delete called for $userType, list type: ${list.runtimeType}');

          if (c.bulkDeleteSelected != null) {
            if (T == StaffManagementController) {
              debugPrint('>>> Detected StaffManagementController, casting list to List<StaffModel>');
              final res = await c.bulkDeleteSelected(
                sourceList: List<StaffModel>.from(list), // ✅ type-safe cast
              );
              success = res['success'] ?? 0;
              fail = res['fail'] ?? 0;
              debugPrint('>>> Bulk delete results: success=$success, fail=$fail');
            } else if (T == StudentManagementController) {
              debugPrint('>>> Detected StudentManagementController, casting list to List<StudentModel>');
              final res = await c.bulkDeleteSelected(
                sourceList: List<StudentModel>.from(list), // ✅ type-safe cast
              );
              success = res['success'] ?? 0;
              fail = res['fail'] ?? 0;
              debugPrint('>>> Bulk delete results: success=$success, fail=$fail');
            }
          } else {
            // Manual fallback for safety
            debugPrint('>>> bulkDeleteSelected is null, using manual deletion');
            for (final String id in List<String>.from(selectedIds)) {
              final dynamic user = list.cast<dynamic>().firstWhere(
                    (u) => (u.id as String) == id,
                    orElse: () => null,
                  );
              if (user == null) {
                fail++;
                continue;
              }
              try {
                if (user is StaffModel && (user.authId?.isNotEmpty ?? false)) {
                  debugPrint('>>> Deleting staff: ${user.id}');
                  await c.deleteUser(user.id, user.authId);
                  success++;
                } else if (user is StudentModel && (user.userId?.isNotEmpty ?? false)) {
                  debugPrint('>>> Deleting student: ${user.id}');
                  await c.deleteUser(user.id, user.userId);
                  success++;
                } else {
                  fail++;
                }
              } catch (e) {
                debugPrint('❌ Deletion failed for ${user.id}: $e');
                fail++;
              }
            }
          }

          // Clear selection
          if (c.clearSelectedUsers != null) {
            debugPrint('>>> Clearing selected users using clearSelectedUsers()');
            c.clearSelectedUsers();
          } else if (c.clearSelections != null) {
            debugPrint('>>> Clearing selected users using clearSelections()');
            c.clearSelections();
          } else {
            debugPrint('>>> Clearing selectedItems directly');
            try {
              c.selectedItems.clear();
            } catch (_) {}
          }

          // Refresh list
          try {
            debugPrint('>>> Refreshing list by calling fetchUsers()');
            await c.fetchUsers();
          } catch (_) {}

          // Feedback
          if (safeContext.mounted) {
            final sm = ScaffoldMessenger.of(safeContext);
            if (success > 0) {
              sm.showSnackBar(
                SnackBar(content: Text('Deleted $success $userType(s) successfully')),
              );
            }
            if (fail > 0) {
              sm.showSnackBar(
                SnackBar(content: Text('Failed to delete $fail $userType(s)')),
              );
            }
          }
        },
  child: busy
      ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        )
      : const Text('Delete'),
)

              ],
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewportHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: Text(title,style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
            ),
          ),
        ),
        actions: [
          Consumer<T>(
            builder: (_, ctrl, __) {
              final dynamic controller = ctrl;
              final Iterable<String> selected =
                  ((controller.selectedItems ??
                              controller.selectedUsers ??
                              <String>[]) as Iterable)
                      .cast<String>();
              final bool hasSelection = selected.isNotEmpty;
              final bool busy = (controller.isLoading == true) ||
                  (controller.isDeleting == true);
              return hasSelection
                  ? IconButton(
                      onPressed:
                          busy ? null : () => _showDeleteDialog(context),
                      icon: const Icon(Icons.delete),
                      tooltip: 'Delete Selected',
                    )
                  : const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(8),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              if (showSort) const SortFilterWidget(),
              Consumer<T>(
                builder: (context, ctrl, _) {
                  final dynamic controller = ctrl;

                  if (controller.isLoading == true) {
                    return const Center(
                        child: CircularProgressIndicator());
                  }

                  if (controller.errorMessage != null) {
                    return Center(
                      child: Text(
                        controller.errorMessage!,
                        style: const TextStyle(
                            color: Colors.red, fontSize: 16),
                      ),
                    );
                  }

                  final list =
                      controller.filteredItems ?? controller.items ?? [];

                  // Empty state
                  if (list.isEmpty) {
                    return ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: viewportHeight -
                            kToolbarHeight -
                            MediaQuery.of(context).padding.top,
                      ),
                      child: Center(
                        child: Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'No $userType(s) available. Add using "+" button.',
                            style: const TextStyle(color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    );
                  }

                  final Iterable<String> selectedSet =
                      ((controller.selectedItems ??
                                  controller.selectedUsers ??
                                  <String>{}) as Iterable)
                          .cast<String>();

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final w = constraints.maxWidth;
                      int crossAxisCount = 2;
                      if (w >= 1200) crossAxisCount = 4;
                      else if (w >= 800) crossAxisCount = 3;

                      final aspectRatio = w < 360 ? 0.65 : 0.75;

                      return GridView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.only(bottom: 72),
                        physics:
                            const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          mainAxisSpacing: 15,
                          crossAxisSpacing: 15,
                          childAspectRatio: aspectRatio,
                        ),
                        itemCount: list.length,
                        itemBuilder: (context, index) {
                          final dynamic user = list[index];
                          final bool isSelected =
                              selectedSet.contains(user.id);

                          return InkWell(
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                formRoute,
                                arguments: {
                                  'data': user.toJson(),
                                  'role': userType
                                },
                              ).then((value) {
                                if (value == true && context.mounted) {
                                  controller.fetchUsers();
                                }
                              });
                            },
                            onLongPress: () {
                              if (controller.toggleUserSelection !=
                                  null) {
                                controller.toggleUserSelection(user.id);
                              } else if (controller.toggleSelection !=
                                  null) {
                                controller.toggleSelection(user.id);
                              } else {
                                try {
                                  if (isSelected) {
                                    controller.selectedItems
                                        .remove(user.id);
                                  } else {
                                    controller.selectedItems
                                        .add(user.id);
                                  }
                                } catch (_) {}
                              }
                            },
                            child: Card(
                              color: isSelected
                                  ? Colors.red.shade50
                                  : null,
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(12)),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    CircleAvatar(
                                      radius: 40,
                                      backgroundImage:
                                          user.profileImageUrl
                                                      ?.isNotEmpty ==
                                                  true
                                              ? NetworkImage(
                                                  user.profileImageUrl!)
                                              : null,
                                      backgroundColor:
                                          Colors.grey.shade200,
                                      child: user.profileImageUrl
                                                  ?.isEmpty ??
                                              true
                                          ? const Icon(Icons.person,
                                              size: 40,
                                              color: Colors.grey)
                                          : null,
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      '${user.firstName} ${user.lastName}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    if (user is StudentModel) ...[
                                      Text(
                                        'Reg: ${user.registerNumber}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey),
                                      ),
                                      Text(
                                        'Attendance: ${user.attendance}%',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey),
                                      ),
                                    ] else if (user is StaffModel) ...[
                                      Text(
                                        'Designation: ${user.designation}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
     floatingActionButton: Consumer<T>(
  builder: (context, ctrl, _) {
    final dynamic controller = ctrl;
    final bool busy = (controller.isLoading == true) || (controller.isDeleting == true);

    return FloatingActionButton(
      onPressed: busy
          ? null
          : () async {
              final result = await Navigator.pushNamed(
                context,
                formRoute,
                arguments: {'data': null, 'role': userType},
              );
              if (result == true && context.mounted) {
                controller.fetchUsers();
              }
            },
      tooltip: 'Add $userType',
      backgroundColor: const Color(0xFF667EEA), // solid purple to match AppBar gradient
      foregroundColor: Colors.white,            // icon color
      elevation: 6,
      child: const Icon(Icons.add),
    );
  },
),

    );
  }
}
