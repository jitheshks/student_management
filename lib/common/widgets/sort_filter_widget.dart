import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:student_management/controller/student_management_controller.dart';

class SortFilterWidget extends StatelessWidget {
  const SortFilterWidget({super.key});

  final List<String> sortOptions = const ['A-Z', 'Z-A', 'Register Number ↑', 'Register Number ↓'];
  final List<String> standards = const ['All', '1st', '2nd', '3rd', '4th', '5th', '6th', '7th', '8th', '9th', '10th'];

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<StudentManagementController>(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // **Sorting Dropdown**
          DropdownButton<String>(
            value: controller.selectedSort,
            items: sortOptions.map((sort) {
              return DropdownMenuItem(value: sort, child: Text(sort));
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                controller.updateSort(value);
              }
            },
          ),

          // **Filtering Dropdown**
          DropdownButton<String>(
            value: controller.selectedStandard,
            items: standards.map((std) {
              return DropdownMenuItem(value: std, child: Text(std));
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                controller.updateFilter(value);
              }
            },
          ),
        ],
      ),
    );
  }
}
