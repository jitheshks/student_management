class Staff {
  final String id;
  final String userId;
  final String firstName;
  final String lastName;
  final String name;
  final String designation;
  final String? email;
  final String? phone;
  final String? subject;
  final String? address;
  final String? profileImageUrl;
  final DateTime? dob;
  final DateTime? createdAt;

  Staff({
    required this.id,
    required this.userId,
    String? firstName,
    String? lastName,
    String? name,
    required this.designation,
    this.email,
    this.phone,
    this.subject,
    this.address,
    this.profileImageUrl,
    this.dob,
    this.createdAt,
  })  : firstName = firstName ??
            (name != null && name.trim().isNotEmpty ? name.trim().split(' ').first : ''),
        lastName = lastName ??
            (name != null && name.trim().split(' ').length > 1
                ? name.trim().split(' ').sublist(1).join(' ')
                : ''),
        name = name ??
            (firstName != null || lastName != null
                ? '${firstName ?? ''} ${lastName ?? ''}'.trim()
                : '');

  /// Backward-compatible alias for Auth UID
  String get authId => userId;

  factory Staff.fromJson(Map<String, dynamic> json) {
    final fName = (json['first_name'] ?? '').toString();
    final lName = (json['last_name'] ?? '').toString();
    final combinedName = (json['name'] ??
            (fName.isNotEmpty || lName.isNotEmpty ? '$fName $lName'.trim() : ''))
        .toString();

    DateTime? parsedDob;
    if (json['dob'] != null && json['dob'].toString().isNotEmpty) {
      parsedDob = DateTime.tryParse(json['dob'].toString());
    }

    DateTime? parsedCreatedAt;
    if (json['created_at'] != null && json['created_at'].toString().isNotEmpty) {
      parsedCreatedAt = DateTime.tryParse(json['created_at'].toString());
    }

    return Staff(
      id: (json['id'] ?? json['user_id'] ?? '').toString(),
      userId: (json['user_id'] ?? json['id'] ?? '').toString(),
      firstName: fName.isNotEmpty
          ? fName
          : (combinedName.isNotEmpty ? combinedName.split(' ').first : ''),
      lastName: lName.isNotEmpty
          ? lName
          : (combinedName.isNotEmpty && combinedName.split(' ').length > 1
              ? combinedName.split(' ').sublist(1).join(' ')
              : ''),
      name: combinedName,
      designation: (json['designation'] ?? json['role'] ?? 'Staff').toString(),
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      subject: json['subject']?.toString(),
      address: json['address']?.toString(),
      profileImageUrl:
          json['profile_image_url']?.toString() ?? json['image_url']?.toString(),
      dob: parsedDob,
      createdAt: parsedCreatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    final effectiveName = name.isNotEmpty ? name : '$firstName $lastName'.trim();
    return {
      'id': id,
      'user_id': userId,
      'first_name': firstName,
      'last_name': lastName,
      'name': effectiveName,
      'designation': designation,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      if (subject != null) 'subject': subject,
      if (address != null) 'address': address,
      if (profileImageUrl != null) 'profile_image_url': profileImageUrl,
      if (dob != null) 'dob': dob!.toIso8601String().split('T').first,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  Staff copyWith({
    String? id,
    String? userId,
    String? firstName,
    String? lastName,
    String? name,
    String? designation,
    String? email,
    String? phone,
    String? subject,
    String? address,
    String? profileImageUrl,
    DateTime? dob,
    DateTime? createdAt,
  }) {
    return Staff(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      name: name ?? this.name,
      designation: designation ?? this.designation,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      subject: subject ?? this.subject,
      address: address ?? this.address,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      dob: dob ?? this.dob,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Staff && other.id == id && other.userId == userId;
  }

  @override
  int get hashCode => Object.hash(id, userId);
}
