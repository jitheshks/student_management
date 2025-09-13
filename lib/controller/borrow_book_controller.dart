import 'package:flutter/material.dart';
import 'package:student_management/model/student_model.dart';
import 'package:student_management/services/borrow_book_services.dart';
import 'package:student_management/services/student_services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class BorrowBookController with ChangeNotifier {
  final SupabaseClient supabase = Supabase.instance.client;
  final StudentService studentService;
  final BorrowBookService borrowBookService;

  BorrowBookController(this.studentService, this.borrowBookService);

  List<Map<String, dynamic>> books = [];

  // MAIN CHANGE: Use StudentModel? here!
  StudentModel? _studentDetails;
  StudentModel? get studentDetails => _studentDetails;

  bool isLoading = true;
  bool _isFetchingStudent = false;
  bool _disposed = false;
  Timer? _debounceTimer;

  String? _selectedBookTitle;
  String? _selectedBookISBN;

  bool get isFetchingStudent => _isFetchingStudent;
  String? get selectedBookTitle => _selectedBookTitle;
  String? get selectedBookISBN => _selectedBookISBN;

  List<String> _borrowedISBNs = [];
  List<String> get borrowedISBNs => _borrowedISBNs;

  // Set selected book from UI
  void setSelectedBook(Map<String, dynamic> book) {
    _selectedBookTitle = book['title'];
    _selectedBookISBN = book['isbn'];
    safeNotify();
  }

  void setSelectedISBN(String isbn) {
    _selectedBookISBN = isbn;
    notifyListeners();
  }

  void clearSelectedBook() {
    _selectedBookTitle = null;
    _selectedBookISBN = null;
    safeNotify();
  }

  void debounceStudentFetch(String registerNumber) {
    if (registerNumber.length < 3) return;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 2), () {
      fetchStudentDetails(registerNumber);
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _disposed = true;
    super.dispose();
  }

  void safeNotify() {
    if (!_disposed) notifyListeners();
  }

  void clearBooks() {
    books = [];
    safeNotify();
  }

  Future<void> fetchBorrowedISBNs(String? registerNumber) async {
    if (registerNumber == null || registerNumber.isEmpty) {
      _borrowedISBNs = [];
      safeNotify();
      return;
    }
    final response = await supabase
        .from('borrow_records')
        .select('isbn')
        .eq('register_number', registerNumber)
        .filter('returned_at', 'is', null);
    _borrowedISBNs =
        response.map<String>((record) => record['isbn'] as String).toList();
    safeNotify();
  }

  Future<void> fetchBooks(String query) async {
    isLoading = true;
    safeNotify();
    final isISBN = RegExp(r'^\d{10,13}$').hasMatch(query);
    final url =
        isISBN
            ? Uri.parse(
              'https://openlibrary.org/api/books?bibkeys=ISBN:$query&format=json&jscmd=data',
            )
            : Uri.parse(
              'https://openlibrary.org/search.json?q=$query&limit=10',
            );

    final response = await http.get(url);
    List<Map<String, dynamic>> bookList = [];

    if (response.statusCode == 200) {
      if (isISBN) {
        final data = json.decode(response.body);
        final bookData = data['ISBN:$query'];

        if (bookData != null) {
          bookList.add({
            'title': bookData['title'] ?? 'Unknown Title',
            'author': bookData['authors']?[0]['name'] ?? 'Unknown Author',
            'isbn': query,
            'coverImage':
                bookData['cover']?['medium'] ??
                'https://via.placeholder.com/150',
            'availableCopies': await getAvailableCopies(query),
          });
        }
      } else {
        final data = json.decode(response.body);
        List booksData = data['docs'];
        for (var book in booksData) {
          String title = book['title'] ?? 'Unknown Title';
          String author = book['author_name']?.first ?? 'Unknown Author';
          String isbn =
              (book['isbn'] != null && book['isbn'].isNotEmpty)
                  ? book['isbn'][0]
                  : 'N/A';
          String coverImage =
              book['cover_i'] != null
                  ? 'https://covers.openlibrary.org/b/id/${book['cover_i']}-M.jpg'
                  : 'https://via.placeholder.com/150';
          int availableCopies = await getAvailableCopies(isbn);
          bookList.add({
            'title': title,
            'author': author,
            'isbn': isbn,
            'coverImage': coverImage,
            'availableCopies': availableCopies,
          });
        }
      }

      // Mark already borrowed books
      for (var book in bookList) {
        book['isAlreadyBorrowed'] = _borrowedISBNs.contains(book['isbn']);
      }
      books = bookList;
    }

    isLoading = false;
    safeNotify();
  }

  /// Fetch Student Details by Register Number
  Future<void> fetchStudentDetails(String registerNumber) async {
    _isFetchingStudent = true;
    safeNotify();
    final student = await studentService.fetchStudentByRegister(registerNumber);
    if (student != null) {
      _studentDetails = student;
      print("✅ Found student: $_studentDetails");
    } else {
      _studentDetails = null; // MAIN FIX: Don't use {}
      print("❌ No student found for register number: $registerNumber");
    }
    _isFetchingStudent = false;
    safeNotify();
  }

  Future<int> getAvailableCopies(String isbn) async {
    final totalCopies = 4;
    final borrowedCount = await getBorrowedCount(isbn);
    return totalCopies - borrowedCount;
  }

  Future<void> borrowBook(String title, String isbn) async {
    // 🔐 Get student register number and current user ID
    final registerNumber = await getRegisterNumber();
    final userId = supabase.auth.currentUser?.id;

    if (registerNumber == null || userId == null) {
      print('⚠️ Cannot borrow book. Register number or user not found.');
      return;
    }

    // 🧠 Find selected book from the books list using ISBN
    final selectedBook = books.firstWhere(
      (book) => book['isbn'] == isbn,
      orElse: () => {},
    );

    // ℹ️ Optional: Warn if book was not found (fallback data will be used)
    if (selectedBook.isEmpty) {
      print("ℹ️ Book with ISBN $isbn not found in list. Using fallback data.");
    }

    // ✅ Prepare safe values using helper
    final safeTitle = safeString(
      selectedBook['title'],
      title,
    ); // fallback: title from param
    final safeAuthor = safeString(selectedBook['author']); // fallback: 'N/A'
    final safeCover = safeString(
      selectedBook['coverImage'],
      'https://via.placeholder.com/150',
    );
    final safeIsbn = isbn.isNotEmpty ? isbn : 'N/A';

    // 🚀 Call the service with safe values
    await borrowBookService.borrowBook(
      // id: userId,
      userId: userId,
      registerNumber: registerNumber,
      bookTitle: safeTitle,
      isbn: safeIsbn,
      bookAuthor: safeAuthor,
      bookCoverUrl: safeCover,
    );

    // 🔄 Notify listeners for any state update
    safeNotify();
  }

  Future<int> getBorrowedCount(String isbn) async {
    final response = await supabase
        .from('borrow_records')
        .select('id')
        .eq('isbn', isbn)
        .filter('returned_at', 'is', null);
    return response.length;
  }

  Future<String?> getRegisterNumber() async {
    final user = supabase.auth.currentUser;
    if (user == null) return null;
    final response =
        await supabase
            .from('students')
            .select('register_number')
            .eq('id', user.id)
            .maybeSingle();
    return response?['register_number'];
  }
}

// 🔧 Helper function for fallback-safe values
String safeString(dynamic value, [String fallback = 'N/A']) {
  final result = value as String?;
  return (result != null && result.isNotEmpty) ? result : fallback;
}
