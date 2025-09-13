import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:student_management/controller/library_history_controller.dart';
import 'package:student_management/common/widgets/sort_filter_widget.dart';

class LibraryHistoryScreen extends StatelessWidget {
  const LibraryHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<LibraryHistoryController>(context);

    // Fetch library history data when the screen is first built
    if (controller.filteredLibraryHistory.isEmpty) {
      controller.fetchLibraryHistory();
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Library History')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child:
            controller.filteredLibraryHistory.isEmpty
                ? const Center(
                  child: CircularProgressIndicator(),
                ) // Loading state
                : Column(
                  children: [
                    const SortFilterWidget(),
                    const SizedBox(height: 20),
                    // DataTable
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Book Title')),
                          DataColumn(label: Text('Student Name')),
                          DataColumn(label: Text('Due Date')),
                          DataColumn(label: Text('Return Date')),
                          DataColumn(label: Text('Status')),
                        ],
                        rows:
                            controller.filteredLibraryHistory.map((
                              historyItem,
                            ) {
                              return DataRow(
                                cells: [
                                  DataCell(Text(historyItem.bookTitle)),
                                  DataCell(Text(historyItem.studentName)),
                                  DataCell(
                                    Text(historyItem.dueDate.toString()),
                                  ),
                                  DataCell(
                                    Text(
                                      historyItem.returnDate?.toString() ??
                                          'Not Returned',
                                    ),
                                  ),
                                  DataCell(Text(historyItem.status)),
                                ],
                              );
                            }).toList(),
                      ),
                    ),
                  ],
                ),
      ),
    );
  }
}
