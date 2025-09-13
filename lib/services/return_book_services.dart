import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReturnBookService {
  final SupabaseClient supabase = Supabase.instance.client;

  /// Fetch all currently borrowed books (not yet returned) for a given register number
  
  Future<List<Map<String, dynamic>>> fetchBorrowedBooks(
    String registerNumber,
  ) async {
    try {
      final response = await supabase
          .from('borrow_records')
          .select('''
            id,
            book_id,
            isbn,
            borrowed_at,
            due_date,
            books(
              title,
              author,
              cover_url
            )
          ''')
          
           // include book_id and isbn for correct mapping


          .eq('register_number', registerNumber)
          .filter('returned_at', 'is', null)
          .order('borrowed_at', ascending: false);

      print('🔥 Supabase response for $registerNumber: $response');
      if (response.isEmpty) {
        print('No borrowed books found for $registerNumber');
      } else {
        print('Sample record: ${response[0]}');
      }

      return List<Map<String, dynamic>>.from(response);
    } catch (e, st) {
      debugPrint('❌ Error fetching borrowed books: $e');
      debugPrint('Stacktrace: $st');
      return [];
    }
  }

  /// Return a book by updating the returned_at field and increasing copies
  
  Future<bool> returnBook(String borrowRecordId, String bookId) async {
    try {

      // Defensive check for empty IDs to avoid invalid UUID errors
      
      if (borrowRecordId.isEmpty || bookId.isEmpty) {
        debugPrint(
          '❌ Invalid IDs. borrowRecordId="$borrowRecordId", bookId="$bookId"',
        );
        return false;
      }

      final now = DateTime.now().toIso8601String();

      // 1. Mark borrow record as returned

      final updateResponse = await supabase
          .from('borrow_records')
          .update({'returned_at': now})
          .eq('id', borrowRecordId)
          .select('id');

      print('borrow_records update: $updateResponse');

      if (updateResponse is List && updateResponse.isEmpty) {
        debugPrint('❌ No borrow record updated for id $borrowRecordId');
        return false;
      } else if (updateResponse == null) {
        debugPrint('❌ Null response from Supabase update (unexpected)');
        return false;
      }

      // 2. Get book current copies

      final bookRecord =
          await supabase
              .from('books')
              .select('copies')
              .eq('id', bookId)
              .maybeSingle();

      print('book record: $bookRecord');

      if (bookRecord == null) {
        debugPrint('❌ Book record not found for ID $bookId');
        return false;
      }

      final currentCopies = bookRecord['copies'] as int;
      final newCopies = currentCopies + 1;

      // 3. Update copies count

      final updateCopiesResponse = await supabase
          .from('books')
          .update({'copies': newCopies})
          .eq('id', bookId)
          .select('id');

      print('update books response: $updateCopiesResponse');

      if (updateCopiesResponse is List && updateCopiesResponse.isEmpty) {
        debugPrint('❌ No book copies updated for book ID $bookId');
        return false;
      } else if (updateCopiesResponse == null) {
        debugPrint('❌ Null response from Supabase book update (unexpected)');
        return false;
      }

      debugPrint('✅ Book returned and copies incremented to $newCopies');
      return true;
    } catch (e, stacktrace) {
      debugPrint('❌ Error in returnBook: $e');
      debugPrint('$stacktrace');
      return false;
    }
  }
}
