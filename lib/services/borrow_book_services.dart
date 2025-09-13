import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// ✅ Borrow Book Service
class BorrowBookService {
  final SupabaseClient supabase = Supabase.instance.client;

  Future<int> getBorrowedCount(String isbn) async {
    final borrowed = await supabase
        .from('borrow_records')
        .select()
        .eq('isbn', isbn)
        .filter('returned_at', 'is', null);

    return borrowed.length;
  }

  Future<void> borrowBook({
    required String userId, // <-- Add this param!

    required String registerNumber,
    required String bookTitle,
    required String isbn,
    required String bookAuthor,
    required String bookCoverUrl,
  }) async {
    try {
      // Defensive check for userId
      if (userId.isEmpty) {
        debugPrint('❌ userId is empty. Cannot borrow.');
        return;
      }

      // 1. Check if already borrowed (not returned)
      final alreadyBorrowed =
          await supabase
              .from('borrow_records')
              .select()
              .eq('register_number', registerNumber)
              .eq('isbn', isbn)
              .filter('returned_at', 'is', null)
              .maybeSingle();

      if (alreadyBorrowed != null) {
        debugPrint('⚠️ You have already borrowed this book.');
        return;
      }

      // 2. Get or insert book
      var book =
          await supabase.from('books').select().eq('isbn', isbn).maybeSingle();

      if (book == null) {
        final inserted =
            await supabase
                .from('books')
                .insert({
                  'title': bookTitle,
                  'isbn': isbn,
                  'author': bookAuthor,
                  'cover_url': bookCoverUrl,
                  'copies': 4, // Default copies
                  'created_at': DateTime.now().toIso8601String(),
                })
                .select()
                .maybeSingle();

        if (inserted == null) {
          debugPrint('❌ Failed to insert book.');
          return;
        }

        book = inserted;
        debugPrint('📚 Book inserted into database.');
      }

      final bookId = book['id'];
      final totalCopies = book['copies'] ?? 4;

      // 3. Count active borrows
      final borrowedCount = await supabase
          .from('borrow_records')
          .select()
          .eq('book_id', bookId)
          .filter('returned_at', 'is', null);

      if (borrowedCount.length >= totalCopies) {
        debugPrint('⚠️ No available copies.');
        return;
      }

      // 4. Set timestamps
      final now = DateTime.now();
      final dueDate = now.add(const Duration(days: 14));

      // 5. Insert borrow record
      await supabase.from('borrow_records').insert({
        'user_id': userId,
        'register_number': registerNumber,
        'book_id': bookId,
        'isbn': isbn,
        'borrowed_at': now.toIso8601String(),
        'due_date': dueDate.toIso8601String(),
        'returned_at': null,
      });

      // 6. Decrease the number of copies by 1 after borrowing
      final bookRecord =
          await supabase
              .from('books')
              .select('copies')
              .eq('id', bookId) // Use PK (id) here
              .maybeSingle();

      if (bookRecord == null) {
        debugPrint('❌ Failed to retrieve the book record for updating copies.');
        return;
      }

      final currentAvailableCopies = bookRecord['copies'] as int;
      final newAvailableCopies = currentAvailableCopies - 1;

      final updateCopiesResult =
          await supabase
              .from('books')
              .update({'copies': newAvailableCopies})
              .eq('id', bookId) // Use PK (id) here too
              .select('id') // Consistent non-null response
              .maybeSingle();

      if (updateCopiesResult == null) {
        debugPrint('❌ Error updating book copies.');
        return;
      }

      debugPrint(
        '✅ Book copies updated successfully. Remaining copies: $newAvailableCopies',
      );
      debugPrint('✅ Book borrowed successfully. Due on ${dueDate.toLocal()}');
    } catch (e) {
      debugPrint('❌ Error borrowing book: $e');
    }
  }
}
