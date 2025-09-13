class LibraryHistoryModel {
  final String studentName;
  final String standard;
  final String bookTitle;
  final String bookAuthor;
  final String coverUrl;
  final DateTime borrowedAt;
  final DateTime? returnedAt;
  final DateTime dueDate;

  LibraryHistoryModel({
    required this.studentName,
    required this.standard,
    required this.bookTitle,
    required this.bookAuthor,
    required this.coverUrl,
    required this.borrowedAt,
    required this.dueDate,
    this.returnedAt,
  });

  factory LibraryHistoryModel.fromJson(Map<String, dynamic> json) {
    return LibraryHistoryModel(
      studentName: json['users']['name'] ?? 'Unknown',
      standard: json['users']['standard'] ?? 'Unknown',
      bookTitle: json['books']['title'] ?? 'Untitled',
      bookAuthor: json['books']['author'] ?? 'Unknown',
      coverUrl: json['books']['cover_url'] ?? '',
      borrowedAt: DateTime.parse(json['borrowed_at']),
      dueDate: DateTime.parse(json['due_date']),
      returnedAt: json['returned_at'] != null ? DateTime.parse(json['returned_at']) : null,
    );
  }
}
