class StaffModel {
  final String id;              // Row ID in the staff table
  final String? authId;         // Supabase Auth UID (from user_id column)
  final String firstName;
  final String lastName;
  final String? profileImageUrl;
  final String designation;
  final String email;
  final String? address;
  final String? phone;
  final DateTime? dob;

  StaffModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.profileImageUrl,
    required this.designation,
    required this.email,
    this.address,
    this.phone,
    this.dob,
    this.authId,
  });

  /// Factory constructor mapping user_id/auth_id from JSON
  factory StaffModel.fromJson(Map<String, dynamic> json) {
    return StaffModel(
      id: json['id'] ?? '',
      authId: json['user_id'] ?? json['auth_id'] ?? '', // ✅ Map Auth UID
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      profileImageUrl: json['profile_image_url'],
      designation: json['designation'] ?? '',
      email: json['email'] ?? '',
      address: json['address'],
      phone: json['phone'],
      dob: json['dob'] != null ? DateTime.tryParse(json['dob']) : null,
    );
  }

  /// Convert this model to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': authId, // ✅ include Auth UID if needed for inserts
      'first_name': firstName,
      'last_name': lastName,
      'profile_image_url': profileImageUrl,
      'designation': designation,
      'email': email,
      'address': address,
      'phone': phone,
      if (dob != null) 'dob': dob!.toIso8601String().split('T').first,
    };
  }
}
