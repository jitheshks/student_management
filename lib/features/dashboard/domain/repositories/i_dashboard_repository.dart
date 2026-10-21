class DashboardStats {
  final int totalStudents;
  final int totalStaff;
  final int totalBooks;
  final int activeLoans;

  const DashboardStats({
    this.totalStudents = 0,
    this.totalStaff = 0,
    this.totalBooks = 0,
    this.activeLoans = 0,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalStudents: (json['total_students'] as num?)?.toInt() ?? 0,
      totalStaff: (json['total_staff'] as num?)?.toInt() ?? 0,
      totalBooks: (json['total_books'] as num?)?.toInt() ?? 0,
      activeLoans: (json['active_loans'] as num?)?.toInt() ?? 0,
    );
  }
}

class StaffDashboardData {
  final String staffName;
  final String designation;
  final int assignedStudentsCount;
  final int totalBooks;

  const StaffDashboardData({
    required this.staffName,
    required this.designation,
    this.assignedStudentsCount = 0,
    this.totalBooks = 0,
  });
}

abstract class IDashboardRepository {
  /// Fetches admin dashboard KPI statistics.
  Future<DashboardStats> getAdminDashboardStats();

  /// Fetches staff dashboard data and profile summary.
  Future<StaffDashboardData> getStaffDashboardData(String staffUserId);
}
