enum FeeStatus {
  paid,
  pending,
  overdue;

  static FeeStatus fromString(String? status) {
    switch (status?.toLowerCase()) {
      case 'paid':
        return FeeStatus.paid;
      case 'overdue':
        return FeeStatus.overdue;
      case 'unpaid':
      case 'pending':
      default:
        return FeeStatus.pending;
    }
  }

  String get displayName {
    switch (this) {
      case FeeStatus.paid:
        return 'Paid';
      case FeeStatus.pending:
        return 'Pending';
      case FeeStatus.overdue:
        return 'Overdue';
    }
  }
}

class FeeRecord {
  final String id;
  final String studentId;
  final String title;
  final double amount;
  final double paidAmount;
  final double dueAmount;
  final int? installmentNo;
  final String? academicYear;
  final DateTime dueDate;
  final DateTime? paidDate;
  final FeeStatus status;
  final String? receiptNumber;

  const FeeRecord({
    required this.id,
    required this.studentId,
    required this.title,
    required this.amount,
    this.paidAmount = 0.0,
    this.dueAmount = 0.0,
    this.installmentNo,
    this.academicYear,
    required this.dueDate,
    this.paidDate,
    this.status = FeeStatus.pending,
    this.receiptNumber,
  });

  factory FeeRecord.fromJson(Map<String, dynamic> json) {
    final rawAmount = (json['amount'] as num?)?.toDouble() ?? 0.0;
    final rawPaidAmount = (json['paid_amount'] as num?)?.toDouble() ??
        (json['status'] == 'paid' ? rawAmount : 0.0);
    final rawDueAmount = (json['due_amount'] as num?)?.toDouble() ??
        ((rawAmount - rawPaidAmount) > 0 ? (rawAmount - rawPaidAmount) : 0.0);
    final instNo = (json['installment_no'] as num?)?.toInt();
    final acadYear = json['academic_year']?.toString();

    final fallbackTitle = instNo != null
        ? 'Fee Installment $instNo${acadYear != null ? " ($acadYear)" : ""}'
        : (json['title'] ?? 'Tuition Fee').toString();

    final rawPaidOn = json['paid_on'] ?? json['paid_date'];

    return FeeRecord(
      id: (json['id'] ?? '').toString(),
      studentId: (json['student_id'] ?? json['user_id'] ?? '').toString(),
      title: fallbackTitle,
      amount: rawAmount,
      paidAmount: rawPaidAmount,
      dueAmount: rawDueAmount,
      installmentNo: instNo,
      academicYear: acadYear,
      dueDate: json['due_date'] != null
          ? DateTime.tryParse(json['due_date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      paidDate: rawPaidOn != null
          ? DateTime.tryParse(rawPaidOn.toString())
          : null,
      status: FeeStatus.fromString(json['status']?.toString()),
      receiptNumber: (json['receipt_number'] ?? json['id'])?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'title': title,
      'amount': amount,
      'paid_amount': paidAmount,
      'due_amount': dueAmount,
      if (installmentNo != null) 'installment_no': installmentNo,
      if (academicYear != null) 'academic_year': academicYear,
      'due_date': dueDate.toIso8601String(),
      if (paidDate != null) 'paid_date': paidDate!.toIso8601String(),
      if (paidDate != null) 'paid_on': paidDate!.toIso8601String(),
      'status': status.name,
      if (receiptNumber != null) 'receipt_number': receiptNumber,
    };
  }
}

class FeesSummary {
  final double totalCollected;
  final double totalPending;
  final double totalOverdue;
  final int totalStudents;
  final int paidStudentsCount;

  const FeesSummary({
    this.totalCollected = 0.0,
    this.totalPending = 0.0,
    this.totalOverdue = 0.0,
    this.totalStudents = 0,
    this.paidStudentsCount = 0,
  });
}
