// lib/model/student_model.dart

class StudentModel {
  final String id; // Unique student record ID (students.id)
  final String firstName;
  final String lastName;
  final String? profileImageUrl;
  final String registerNumber;
  final int attendance;
  /// Supabase Auth user id — now correctly mapped from students.user_id
  final String userId; 
  final String? address;
  final String? phone;
  final String email;
  final DateTime? dob;
  final String standard;

  StudentModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.profileImageUrl,
    required this.registerNumber,
    required this.attendance,
    required this.userId,
    this.address,
    this.phone,
    required this.email,
    this.dob,
    required this.standard,
  });

  /// Creates a StudentModel from Supabase/JSON map
  factory StudentModel.fromJson(Map<String, dynamic> json) {
    return StudentModel(
      id: json['id'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      profileImageUrl: json['profile_image_url'] as String?,
      registerNumber: json['register_number'] ?? '',
      attendance: json['attendance'] is int
          ? json['attendance']
          : int.tryParse(json['attendance']?.toString() ?? '0') ?? 0,
      // More resilient mapping: tries user_id, then auth_id, then uid
      userId: json['user_id'] ?? json['auth_id'] ?? json['uid'] ?? '',
      address: json['address'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] ?? '',
      dob: json['dob'] != null ? DateTime.tryParse(json['dob']) : null,
      standard: json['standard'] ?? '',
    );
  }

  /// Converts this StudentModel to a map for inserts/updates
  Map<String, dynamic> toJson() {
    final map = {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'profile_image_url': profileImageUrl,
      'register_number': registerNumber,
      'attendance': attendance,
      'user_id': userId,
      'address': address,
      'phone': phone,
      'email': email,
      if (dob != null) 'dob': dob!.toIso8601String().split('T').first,
      'standard': standard,
    };
    return map;
  }
}
