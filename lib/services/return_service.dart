// import 'package:supabase_flutter/supabase_flutter.dart';

// /// ✅ Return Book Service
// class ReturnBookService {
//   final SupabaseClient supabase = Supabase.instance.client;

//   /// ✅ Return a borrowed book
//   Future<void> returnBook(String borrowId) async {
//     await supabase.from('borrow_records').update({
//       'returned_at': DateTime.now().toIso8601String(),
//     }).match({'id': borrowId});

//     print('✅ Book returned successfully.');
//   }
// }
