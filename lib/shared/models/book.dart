class Book {
  final String id;
  final String title;
  final String author;
  final String isbn;
  final String coverUrl;
  final int copies;
  final DateTime? createdAt;

  const Book({
    required this.id,
    required this.title,
    required this.author,
    required this.isbn,
    required this.coverUrl,
    this.copies = 4,
    this.createdAt,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? 'Unknown Title').toString(),
      author: (json['author'] ?? json['author_name'] ?? 'Unknown Author').toString(),
      isbn: (json['isbn'] ?? '').toString(),
      coverUrl: (json['cover_url'] ?? json['cover_image_url'] ?? '').toString(),
      copies: (json['copies'] as num?)?.toInt() ?? 4,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'isbn': isbn,
      'cover_url': coverUrl,
      'copies': copies,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  Book copyWith({
    String? id,
    String? title,
    String? author,
    String? isbn,
    String? coverUrl,
    int? copies,
    DateTime? createdAt,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      isbn: isbn ?? this.isbn,
      coverUrl: coverUrl ?? this.coverUrl,
      copies: copies ?? this.copies,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Book && other.id == id && other.isbn == isbn;
  }

  @override
  int get hashCode => Object.hash(id, isbn);
}
