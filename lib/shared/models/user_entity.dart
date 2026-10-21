enum UserRole {
  admin,
  staff,
  student;

  static UserRole fromString(String? role) {
    switch (role?.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'staff':
      case 'teacher':
      case 'librarian':
        return UserRole.staff;
      case 'student':
        return UserRole.student;
      default:
        return UserRole.student;
    }
  }

  String toDbString() {
    switch (this) {
      case UserRole.admin:
        return 'admin';
      case UserRole.staff:
        return 'staff';
      case UserRole.student:
        return 'student';
    }
  }
}

class UserEntity {
  final String id;
  final String email;
  final UserRole role;
  final DateTime? createdAt;

  const UserEntity({
    required this.id,
    required this.email,
    required this.role,
    this.createdAt,
  });

  bool get isAdmin => role == UserRole.admin;
  bool get isStaff => role == UserRole.staff;
  bool get isStudent => role == UserRole.student;

  factory UserEntity.fromJson(Map<String, dynamic> json) {
    return UserEntity(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: UserRole.fromString(json['role'] as String?),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'role': role.toDbString(),
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  UserEntity copyWith({
    String? id,
    String? email,
    UserRole? role,
    DateTime? createdAt,
  }) {
    return UserEntity(
      id: id ?? this.id,
      email: email ?? this.email,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserEntity && other.id == id && other.email == email && other.role == role;
  }

  @override
  int get hashCode => Object.hash(id, email, role);
}
