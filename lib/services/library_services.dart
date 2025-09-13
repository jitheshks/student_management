import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class LibraryService {
  final SupabaseClient supabase = Supabase.instance.client;

  /// Fetch books from Open Library API using ISBN, Title, or Author
  Future<void> fetchBookFromOpenLibrary({
    String? isbn,
    String? title,
    String? author,
  }) async {
    String apiUrl;

    if (isbn != null && isbn.isNotEmpty) {
      apiUrl =
          'https://openlibrary.org/api/books?bibkeys=ISBN:$isbn&format=json&jscmd=data';
    } else if (title != null && title.isNotEmpty) {
      apiUrl = 'https://openlibrary.org/search.json?title=$title&limit=1';
    } else if (author != null && author.isNotEmpty) {
      apiUrl = 'https://openlibrary.org/search.json?author=$author&limit=1';
    } else {
      print('❌ No search parameters provided.');
      return;
    }

    try {
      final url = Uri.parse(apiUrl);
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (isbn != null && isbn.isNotEmpty) {
          // ISBN endpoint shape: {"ISBN:xxxx": {...}}
          final bookData = data['ISBN:$isbn'];
          if (bookData != null) {
            await _addBookToSupabase(bookData, isbn);
          } else {
            print('❌ Book not found in Open Library API (ISBN).');
          }
        } else {
          // search.json shape
          final docs = data['docs'] as List<dynamic>?;
          if (docs != null && docs.isNotEmpty) {
            final bookData = docs.first;

            final bookIsbn =
                (bookData['isbn'] != null &&
                        (bookData['isbn'] as List).isNotEmpty)
                    ? bookData['isbn'][0]
                    : '';

            if (bookIsbn.isEmpty) {
              print('❌ No ISBN found for the given query.');
              return;
            }
            await _addBookToSupabase(bookData, bookIsbn);
          } else {
            print('❌ No books found for the given query.');
          }
        }
      } else {
        print('❌ Failed to fetch book data: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching book: $e');
    }
  }

  /// ✅ Check if the book exists before inserting into Supabase
  Future<bool> _isBookExists(String isbn) async {
    final response =
        await supabase
            .from('books')
            .select('id')
            .eq('isbn', isbn) // FIXED: check by isbn column, not id
            .maybeSingle();
    return response != null;
  }

  /// Save book to Supabase (only if it doesn’t exist)
  Future<void> _addBookToSupabase(
    Map<String, dynamic> bookData,
    String isbn,
  ) async {
    if (isbn.isEmpty) {
      print('❌ Cannot insert without ISBN.');
      return;
    }
    if (await _isBookExists(isbn)) {
      print('⚠️ Book already exists in Supabase.');
      return;
    }

    // Defensive title normalization
    final titleVal = bookData['title'];
    final title = titleVal is String ? titleVal : 'Unknown Title';

    // Defensive cast for author_name (search.json)
    String author = 'Unknown Author';
    final authorNames =
        (bookData['author_name'] as List?)?.cast<dynamic>() ?? [];
    if (authorNames.isNotEmpty && authorNames.first is String) {
      author = authorNames.first as String;
    } else {
      // Defensive cast for authors (api/books)
      final authors = (bookData['authors'] as List?)?.cast<dynamic>() ?? [];
      if (authors.isNotEmpty &&
          authors.first is Map &&
          (authors.first as Map).containsKey('name')) {
        author = (authors.first as Map)['name'] as String;
      }
    }

    // Defensive cast for cover.medium (api/books)
    String coverUrl = '';
    if (bookData['cover_i'] != null) {
      coverUrl =
          'https://covers.openlibrary.org/b/id/${bookData['cover_i']}-M.jpg';
    } else {
      final cover = bookData['cover'] as Map<String, dynamic>?;
      if (cover != null && cover['medium'] is String) {
        coverUrl = cover['medium'] as String;
      }
    }

    try {
      // Insert without id, letting DB generate UUID.
      // If your DB has default for created_at and copies, you can omit those fields.
      final inserted =
          await supabase
              .from('books')
              .insert({
                'title': title,
                'author': author,
                'isbn': isbn,
                'cover_url': coverUrl,
                'copies': 4, // Optional if DB default exists
                'created_at':
                    DateTime.now()
                        .toIso8601String(), // Optional if DB default exists
              })
              .select(
                'id, title, author, isbn, cover_url, copies',
              ) // To get inserted row back
              .maybeSingle();

      if (inserted == null) {
        print('❌ Insert failed: No data returned');
        return;
      }

      print('✅ Book added to Supabase: $title');
    } catch (e) {
      print('❌ Insert failed: $e');
    }
  }

  /// Get all borrow history with proper joins using book_id
  Future<List<Map<String, dynamic>>> getAllBorrowHistory() async {
    try {
      final response = await supabase
          .from('borrow_records')
          .select('''
            id,
            borrowed_at,
            returned_at,
            due_date,
            isbn,
            book_id,
            books (
              title,
              author,
              cover_url
            )
          ''')
          .order('borrowed_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error fetching borrow history: $e');
      return [];
    }
  }
}
