import 'package:flutter/material.dart';
import 'package:student_management/model/borrowed_book_model.dart';
import 'package:student_management/services/return_book_services.dart';

class ReturnBookController with ChangeNotifier {
  final ReturnBookService _service = ReturnBookService();

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController regNumberController = TextEditingController();

  bool isLoading = false;
  bool showBooksList = false;
  List<BorrowedBook> borrowedBooks = [];
  String? errorMessage;

  // Fetch borrowed books for the student
  Future<void> searchBorrowedBooks() async {
    if (isLoading) return; // prevent overlapping calls
    if (!formKey.currentState!.validate()) return;
    final regNo = regNumberController.text.trim();

    isLoading = true;
    showBooksList = false;
    borrowedBooks = [];
    errorMessage = null;
    notifyListeners();

    try {
      final rawBooks = await _service.fetchBorrowedBooks(regNo);
      borrowedBooks =
          rawBooks.map((e) => BorrowedBook.fromServiceMap(e)).toList();
      showBooksList = true;
    } catch (e) {
      errorMessage = 'Failed to fetch borrowed books: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> returnBook({
    required String borrowRecordId,
    required String bookId,
  }) async {
    if (isLoading) return 'Please wait...'; // prevent overlapping calls
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      final result = await _service.returnBook(borrowRecordId, bookId);
      if (result) {
        borrowedBooks.removeWhere((b) => b.id == borrowRecordId);
        // Optionally refresh the list from server here:
        // await searchBorrowedBooks();
        return null;
      } else {
        return 'Failed to return the book.';
      }
    } catch (e) {
      return 'Unexpected error while returning the book: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void clearSearch() {
    regNumberController.clear();
    borrowedBooks = [];
    showBooksList = false;
    errorMessage = null;
    notifyListeners();
  }
}
