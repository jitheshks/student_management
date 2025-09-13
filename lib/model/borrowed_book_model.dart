class BorrowedBook {
  final String id;
  final String bookId;
  final String isbn;
  final DateTime? borrowedAt;
  final DateTime? dueDate;
  final String title;
  final String? author;
  final String? coverUrl; // <--- This field is present

  BorrowedBook({
    required this.id,
    required this.bookId,
    required this.isbn,
    required this.borrowedAt,
    required this.dueDate,
    required this.title,
    required this.author,
    this.coverUrl, // <--- This is present
  });

  factory BorrowedBook.fromServiceMap(Map<String, dynamic> map) {
    final books = map['books'];
    final borrowedAtStr = map['borrowed_at'];
    final dueDateStr = map['due_date'];
    return BorrowedBook(
      id: map['id'] ?? '',
      bookId: map['book_id'] ?? '',
      isbn: map['isbn'] ?? '',
      borrowedAt:
          borrowedAtStr != null ? DateTime.tryParse(borrowedAtStr) : null,
      dueDate: dueDateStr != null ? DateTime.tryParse(dueDateStr) : null,
      title:
          books != null ? books['title'] ?? 'Unknown Title' : 'Unknown Title',
      author: books != null ? books['author'] : null,
      coverUrl:
          books != null ? books['cover_url'] : null, // <--- This is present
    );
  }
}
