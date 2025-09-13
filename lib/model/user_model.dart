class UserModel {
  /// UUID from Supabase Auth (auth.users.id) or your profile table's user_id
  final String id;
  final String email;
  /// Role in the app. If not present in auth.users, default to 'student'
  final String role;
  final DateTime? createdAt;

  UserModel({
    required this.id,
    required this.email,
    required this.role,
    this.createdAt,
  });

  /// Parse from JSON returned by Supabase
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      // Handles both 'user_id' (profile table) and 'id' (auth.users)
      id: json['user_id'] ?? json['id'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'student',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  /// Convert back to JSON for API calls/inserts
  Map<String, dynamic> toJson() {
    return {
      // Always send back as 'id' unless your endpoint expects 'user_id'
      'id': id,
      'email': email,
      'role': role,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
