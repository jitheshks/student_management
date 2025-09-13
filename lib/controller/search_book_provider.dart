import 'package:flutter/material.dart';
import 'package:student_management/controller/borrow_book_controller.dart';

class SearchBookProvider with ChangeNotifier {
  final TextEditingController searchController = TextEditingController();
  bool hasSearched = false;

  void initListener(BorrowBookController libraryProvider) {
    searchController.addListener(() {
      final query = searchController.text.trim();
      if (query.isNotEmpty) {
        hasSearched = true;
        libraryProvider.fetchBooks(query);
      } else {
        hasSearched = false;
      }
      notifyListeners();
    });
  }

  void clearSearch() {
    searchController.clear();
    hasSearched = false;
    notifyListeners();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}
