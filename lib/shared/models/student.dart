class Student {
  final String id;
  final String userId;
  final String firstName;
  final String lastName;
  final String name;
  final String registerNumber;
  final String standard;
  final String? email;
  final String? phone;
  final String? address;
  final String? profileImageUrl;
  final int attendance;
  final double attendancePercentage;
  final int totalWorkingDays;
  final int daysPresent;
  final DateTime? dob;
  final DateTime? createdAt;

  Student({
    required this.id,
    required this.userId,
    String? firstName,
    String? lastName,
    String? name,
    required this.registerNumber,
    required this.standard,
    this.email,
    this.phone,
    this.address,
    this.profileImageUrl,
    this.attendance = 0,
    double? attendancePercentage,
    this.totalWorkingDays = 0,
    this.daysPresent = 0,
    this.dob,
    this.createdAt,
  })  : firstName = firstName ?? (name != null && name.trim().isNotEmpty ? name.trim().split(' ').first : ''),
        lastName = lastName ?? (name != null && name.trim().split(' ').length > 1 ? name.trim().split(' ').sublist(1).join(' ') : ''),
        name = name ?? (firstName != null || lastName != null ? '${firstName ?? ''} ${lastName ?? ''}'.trim() : ''),
        attendancePercentage = attendancePercentage ??
            ((totalWorkingDays > 0 && daysPresent > 0)
                ? ((daysPresent / totalWorkingDays) * 100)
                : attendance.toDouble());

  factory Student.fromJson(Map<String, dynamic> json) {
    final fName = (json['first_name'] ?? '').toString();
    final lName = (json['last_name'] ?? '').toString();
    final combinedName = (json['name'] ?? (fName.isNotEmpty || lName.isNotEmpty ? '$fName $lName'.trim() : '')).toString();
    final att = (json['attendance'] as num?)?.toInt() ?? (json['days_present'] as num?)?.toInt() ?? 0;
    final totalDays = (json['total_working_days'] as num?)?.toInt() ?? 0;
    final presentDays = (json['days_present'] as num?)?.toInt() ?? att;

    DateTime? parsedDob;
    if (json['dob'] != null && json['dob'].toString().isNotEmpty) {
      parsedDob = DateTime.tryParse(json['dob'].toString());
    }

    DateTime? parsedCreatedAt;
    if (json['created_at'] != null && json['created_at'].toString().isNotEmpty) {
      parsedCreatedAt = DateTime.tryParse(json['created_at'].toString());
    }

    final double calculatedPercentage = (json['attendance_percentage'] as num?)?.toDouble() ??
        (totalDays > 0 ? ((presentDays / totalDays) * 100) : att.toDouble());

    return Student(
      id: (json['id'] ?? json['user_id'] ?? '').toString(),
      userId: (json['user_id'] ?? json['id'] ?? '').toString(),
      firstName: fName.isNotEmpty ? fName : (combinedName.isNotEmpty ? combinedName.split(' ').first : ''),
      lastName: lName.isNotEmpty ? lName : (combinedName.isNotEmpty && combinedName.split(' ').length > 1 ? combinedName.split(' ').sublist(1).join(' ') : ''),
      name: combinedName,
      registerNumber: (json['register_number'] ?? json['reg_no'] ?? '').toString(),
      standard: (json['standard'] ?? json['class'] ?? '').toString(),
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      address: json['address']?.toString(),
      profileImageUrl: json['profile_image_url']?.toString() ?? json['image_url']?.toString(),
      attendance: att,
      attendancePercentage: calculatedPercentage,
      totalWorkingDays: totalDays,
      daysPresent: presentDays,
      dob: parsedDob,
      createdAt: parsedCreatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'first_name': firstName,
      'last_name': lastName,
      'name': name.isNotEmpty ? name : '$firstName $lastName'.trim(),
      'register_number': registerNumber,
      'standard': standard,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      if (address != null) 'address': address,
      if (profileImageUrl != null) 'profile_image_url': profileImageUrl,
      'attendance': attendance,
      'attendance_percentage': attendancePercentage,
      'total_working_days': totalWorkingDays,
      'days_present': daysPresent,
      if (dob != null) 'dob': dob!.toIso8601String().split('T').first,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  Student copyWith({
    String? id,
    String? userId,
    String? firstName,
    String? lastName,
    String? name,
    String? registerNumber,
    String? standard,
    String? email,
    String? phone,
    String? address,
    String? profileImageUrl,
    int? attendance,
    double? attendancePercentage,
    int? totalWorkingDays,
    int? daysPresent,
    DateTime? dob,
    DateTime? createdAt,
  }) {
    return Student(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      name: name ?? this.name,
      registerNumber: registerNumber ?? this.registerNumber,
      standard: standard ?? this.standard,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      attendance: attendance ?? this.attendance,
      attendancePercentage: attendancePercentage ?? this.attendancePercentage,
      totalWorkingDays: totalWorkingDays ?? this.totalWorkingDays,
      daysPresent: daysPresent ?? this.daysPresent,
      dob: dob ?? this.dob,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get initials {
    final first = firstName.isNotEmpty ? firstName[0] : (name.isNotEmpty ? name[0] : '');
    final last = lastName.isNotEmpty ? lastName[0] : '';
    return '$first$last'.toUpperCase();
  }

  String get displayName => name.isNotEmpty ? name : '$firstName $lastName'.trim();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Student && other.id == id && other.registerNumber == registerNumber;
  }

  @override
  int get hashCode => Object.hash(id, registerNumber);
}
