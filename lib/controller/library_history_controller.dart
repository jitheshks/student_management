import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LibraryHistoryController with ChangeNotifier {
  List<LibraryHistoryItem> _libraryHistory = [];
  List<LibraryHistoryItem> _filteredLibraryHistory = [];

  String selectedSort = 'A-Z'; // Default sort
  String selectedStandard = 'All'; // Default filter
  String selectedStatus = 'All'; // Default status filter

  List<LibraryHistoryItem> get filteredLibraryHistory =>
      _filteredLibraryHistory;

  // Fetch library history data from Supabase
  Future<void> fetchLibraryHistory() async {
    try {
      final data = await Supabase.instance.client
          .from('borrow_records')
          .select('''
          id,
          due_date,
          returned_at,
          status,
          students!borrow_records_student_id_fkey (
            first_name,
            last_name,
            standard
          ),
          books:book_id (
            title
          )
        ''')
          .order('due_date', ascending: false);

      _libraryHistory =
          (data as List)
              .map(
                (item) => LibraryHistoryItem(
                  bookTitle: item['books']['title'],
                  studentName:
                      "${item['students']['first_name']} ${item['students']['last_name']}",
                  dueDate: DateTime.parse(item['due_date']),
                  returnDate:
                      item['returned_at'] != null
                          ? DateTime.parse(item['returned_at'])
                          : null,
                  status: item['status'],
                  standard: item['students']['standard'],
                ),
              )
              .toList();

      _applyFiltersAndSort();
      notifyListeners();
    } catch (e) {
      print('❌ Error fetching library history: $e');
    }
  }

  // Update sort
  void updateSort(String sortOption) {
    selectedSort = sortOption;
    _applyFiltersAndSort();
    notifyListeners();
  }

  // Update filter (Standard)
  void updateFilter(String filterOption) {
    selectedStandard = filterOption;

    _applyFiltersAndSort();

    notifyListeners();
  }

  // Update filter (Status)
  void updateStatusFilter(String status) {
    selectedStatus = status;

    _applyFiltersAndSort();

    notifyListeners();
  }

  // Apply filters and sorting logic
  void _applyFiltersAndSort() {
    _filteredLibraryHistory =
        _libraryHistory.where((item) {
          final matchesStandard =
              selectedStandard == 'All' || item.standard == selectedStandard;
          final matchesStatus =
              selectedStatus == 'All' || item.status == selectedStatus;
          return matchesStandard && matchesStatus;
        }).toList();

    // Sorting logic based on selected option
    if (selectedSort == 'A-Z') {
      _filteredLibraryHistory.sort(
        (a, b) => a.bookTitle.compareTo(b.bookTitle),
      );
    } else if (selectedSort == 'Z-A') {
      _filteredLibraryHistory.sort(
        (a, b) => b.bookTitle.compareTo(a.bookTitle),
      );
    } else if (selectedSort == 'Register Number ↑') {
      _filteredLibraryHistory.sort(
        (a, b) => a.studentName.compareTo(b.studentName),
      );
    } else if (selectedSort == 'Register Number ↓') {
      _filteredLibraryHistory.sort(
        (a, b) => b.studentName.compareTo(a.studentName),
      );
    }

    notifyListeners();
  }
}

class LibraryHistoryItem {
  final String bookTitle;
  final String studentName;
  final DateTime dueDate;
  final DateTime? returnDate;
  final String status;
  final String standard;

  LibraryHistoryItem({
    required this.bookTitle,
    required this.studentName,
    required this.dueDate,
    this.returnDate,
    required this.status,
    required this.standard,
  });
}
