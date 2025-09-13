class BorrowHistory {
  final String id;
  final String userId;
  final String bookId;
  final DateTime borrowedAt;
  final DateTime? returnedAt;
  final DateTime dueDate;
  final String title;
  final String? author;
  final String isbn;

  BorrowHistory({
    required this.id,
    required this.userId,
    required this.bookId,
    required this.borrowedAt,
    this.returnedAt,
    required this.dueDate,
    required this.title,
    required this.author,
    required this.isbn,
  });

  factory BorrowHistory.fromJson(Map<String, dynamic> json) {
    final book = json['books'] ?? {};
    return BorrowHistory(
      id: json['id'],
      userId: json['user_id'],
      bookId: json['book_id'],
      borrowedAt: DateTime.parse(json['borrowed_at']),
      returnedAt:
          json['returned_at'] != null
              ? DateTime.parse(json['returned_at'])
              : null,
      dueDate: DateTime.parse(json['due_date']),
      title: book['title'] ?? 'Unknown Title',
      author: book['author'], // Nullable—will be null if absent
      isbn: book['isbn'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'book_id': bookId,
      'borrowed_at': borrowedAt.toIso8601String(),
      'returned_at': returnedAt?.toIso8601String(),
      'due_date': dueDate.toIso8601String(),
      'title': title,
      'author': author,
      'isbn': isbn,
    };
  }
}
