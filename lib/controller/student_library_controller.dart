// lib/controller/student_library_controller.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StudentLibraryItem {
  final String id;
  final String coverUrl;
  final String title;
  final String author;
  final DateTime borrowedAt;
  final DateTime? returnedAt;
  final DateTime? dueDate;
  final String status; // 'returned' | 'borrowed' | 'overdue'

  const StudentLibraryItem({
    required this.id,
    required this.coverUrl,
    required this.title,
    required this.author,
    required this.borrowedAt,
    required this.returnedAt,
    required this.dueDate,
    required this.status,
  });
}

class StudentLibraryController with ChangeNotifier {
  final SupabaseClient supabase = Supabase.instance.client;

  bool loading = false;
  String? error;
  List<StudentLibraryItem> items = const [];

  Future<void> load(String id, {required bool filterByUserId}) async {
    loading = true;
    error = null;
    items = const [];
    notifyListeners();

    try {
      // ✅ Select borrow_records + embed books(title, author, cover_url)
      const cols = '''
        id,
        borrowed_at,
        returned_at,
        due_date,
        books:book_id (
          title,
          author,
          cover_url
        )
      ''';

      final PostgrestFilterBuilder base =
          supabase.from('borrow_records').select(cols);

      final PostgrestFilterBuilder filtered = filterByUserId
          ? base.eq('user_id', id)
          : base.eq('student_id', id);

      final data = await filtered.order('borrowed_at', ascending: false);

      final now = DateTime.now();
      items = (data as List).map((r) {
        final borrowedAt =
            DateTime.tryParse(r['borrowed_at']?.toString() ?? '') ?? now;
        final returnedAt = r['returned_at'] != null
            ? DateTime.tryParse(r['returned_at'].toString())
            : null;
        final dueDate = r['due_date'] != null
            ? DateTime.tryParse(r['due_date'].toString())
            : null;

        final status = returnedAt != null
            ? 'returned'
            : (dueDate != null && dueDate.isBefore(now))
                ? 'overdue'
                : 'borrowed';

        // ✅ Book details come from embedded "books"
        final books = (r['books'] as Map?) ?? const {};

        return StudentLibraryItem(
          id: r['id'].toString(),
          coverUrl: (books['cover_url'] as String?)?.trim() ?? '',
          title: (books['title'] as String?)?.trim() ?? '',
          author: (books['author'] as String?)?.trim() ?? '',
          borrowedAt: borrowedAt,
          returnedAt: returnedAt,
          dueDate: dueDate,
          status: status,
        );
      }).toList();
    } on PostgrestException catch (e) {
      error = e.message;
    } catch (e) {
      error = 'Failed to load library history';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  // Optional client-side filter
  void filterByStatus(String? status) {
    if (status == null) return;
    items = items.where((e) => e.status == status).toList();
    notifyListeners();
  }
}
