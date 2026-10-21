enum BorrowStatus {
  borrowed,
  returned,
  overdue;

  static BorrowStatus fromString(String? status) {
    switch (status?.toLowerCase()) {
      case 'returned':
        return BorrowStatus.returned;
      case 'overdue':
        return BorrowStatus.overdue;
      case 'borrowed':
      default:
        return BorrowStatus.borrowed;
    }
  }

  String get displayName {
    switch (this) {
      case BorrowStatus.borrowed:
        return 'Borrowed';
      case BorrowStatus.returned:
        return 'Returned';
      case BorrowStatus.overdue:
        return 'Overdue';
    }
  }
}

class BorrowRecord {
  final String id;
  final String userId;
  final String studentRegisterNumber;
  final String? studentName;
  final String? standard;
  final String bookId;
  final String bookTitle;
  final String bookAuthor;
  final String coverUrl;
  final String isbn;
  final DateTime borrowedAt;
  final DateTime dueDate;
  final DateTime? returnedAt;

  BorrowStatus get status {
    if (returnedAt != null) return BorrowStatus.returned;
    if (dueDate.isBefore(DateTime.now())) return BorrowStatus.overdue;
    return BorrowStatus.borrowed;
  }

  bool get isReturned => returnedAt != null;
  bool get isOverdue => returnedAt == null && dueDate.isBefore(DateTime.now());

  const BorrowRecord({
    required this.id,
    required this.userId,
    required this.studentRegisterNumber,
    this.studentName,
    this.standard,
    required this.bookId,
    required this.bookTitle,
    required this.bookAuthor,
    required this.coverUrl,
    required this.isbn,
    required this.borrowedAt,
    required this.dueDate,
    this.returnedAt,
  });

  factory BorrowRecord.fromJson(Map<String, dynamic> json) {
    // Books join may be nested as Map or flat
    final bookData = json['books'] is Map<String, dynamic> ? json['books'] as Map<String, dynamic> : null;
    final studentData = json['students'] is Map<String, dynamic> ? json['students'] as Map<String, dynamic> : null;

    final borrowedAtParsed = json['borrowed_at'] != null
        ? DateTime.tryParse(json['borrowed_at'].toString()) ?? DateTime.now()
        : DateTime.now();

    final dueDateParsed = json['due_date'] != null
        ? DateTime.tryParse(json['due_date'].toString()) ?? borrowedAtParsed.add(const Duration(days: 14))
        : borrowedAtParsed.add(const Duration(days: 14));

    final returnedAtParsed = json['returned_at'] != null
        ? DateTime.tryParse(json['returned_at'].toString())
        : null;

    return BorrowRecord(
      id: (json['id'] ?? '').toString(),
      userId: (json['user_id'] ?? json['student_id'] ?? '').toString(),
      studentRegisterNumber: (json['student_register_number'] ??
              json['register_number'] ??
              studentData?['register_number'] ??
              '')
          .toString(),
      studentName: json['student_name']?.toString() ?? studentData?['name']?.toString(),
      standard: json['standard']?.toString() ?? studentData?['standard']?.toString(),
      bookId: (json['book_id'] ?? bookData?['id'] ?? '').toString(),
      bookTitle: (json['book_title'] ?? json['title'] ?? bookData?['title'] ?? 'Unknown Book').toString(),
      bookAuthor: (json['book_author'] ?? json['author'] ?? bookData?['author'] ?? 'Unknown Author').toString(),
      coverUrl: (json['cover_url'] ?? json['cover_image_url'] ?? bookData?['cover_url'] ?? '').toString(),
      isbn: (json['isbn'] ?? bookData?['isbn'] ?? '').toString(),
      borrowedAt: borrowedAtParsed,
      dueDate: dueDateParsed,
      returnedAt: returnedAtParsed,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'student_register_number': studentRegisterNumber,
      if (studentName != null) 'student_name': studentName,
      if (standard != null) 'standard': standard,
      'book_id': bookId,
      'book_title': bookTitle,
      'book_author': bookAuthor,
      'cover_url': coverUrl,
      'isbn': isbn,
      'borrowed_at': borrowedAt.toIso8601String(),
      'due_date': dueDate.toIso8601String(),
      if (returnedAt != null) 'returned_at': returnedAt!.toIso8601String(),
    };
  }

  BorrowRecord copyWith({
    String? id,
    String? userId,
    String? studentRegisterNumber,
    String? studentName,
    String? standard,
    String? bookId,
    String? bookTitle,
    String? bookAuthor,
    String? coverUrl,
    String? isbn,
    DateTime? borrowedAt,
    DateTime? dueDate,
    DateTime? returnedAt,
  }) {
    return BorrowRecord(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      studentRegisterNumber: studentRegisterNumber ?? this.studentRegisterNumber,
      studentName: studentName ?? this.studentName,
      standard: standard ?? this.standard,
      bookId: bookId ?? this.bookId,
      bookTitle: bookTitle ?? this.bookTitle,
      bookAuthor: bookAuthor ?? this.bookAuthor,
      coverUrl: coverUrl ?? this.coverUrl,
      isbn: isbn ?? this.isbn,
      borrowedAt: borrowedAt ?? this.borrowedAt,
      dueDate: dueDate ?? this.dueDate,
      returnedAt: returnedAt ?? this.returnedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BorrowRecord && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
