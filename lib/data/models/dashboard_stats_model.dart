import 'package:freezed_annotation/freezed_annotation.dart';

part 'dashboard_stats_model.freezed.dart';
part 'dashboard_stats_model.g.dart';

/// Dashboard statistics model
@freezed
class DashboardStats with _$DashboardStats {
  const DashboardStats._();

  const factory DashboardStats({
    @Default(0) int totalEmployees,
    @Default(0) int presentToday,
    @Default(0) int absentToday,
    @Default(0) int onLeave,
    @Default(0) int lateToday,
    @Default(0) int pendingLeaveRequests,
    @Default(0.0) double attendanceRateToday,
    @Default(0.0) double attendanceRateMonth,
    @Default([]) List<DepartmentSummary> departments,
    @Default([]) List<RecentActivity> recentCheckIns,
  }) = _DashboardStats;

  factory DashboardStats.fromJson(Map<String, dynamic> json) =>
      _$DashboardStatsFromJson(json);

  /// Get attendance percentage for today
  String get attendancePercentageToday {
    if (totalEmployees == 0) return '0';
    return attendanceRateToday.toStringAsFixed(1);
  }

  /// Get attendance percentage for month
  String get attendancePercentageMonth {
    if (totalEmployees == 0) return '0';
    return attendanceRateMonth.toStringAsFixed(1);
  }
}

/// Department summary
@freezed
class DepartmentSummary with _$DepartmentSummary {
  const factory DepartmentSummary({
    required String id,
    required String name,
    @Default(0) int employeeCount,
    @Default(0) int presentToday,
    @Default(0) int absentToday,
  }) = _DepartmentSummary;

  factory DepartmentSummary.fromJson(Map<String, dynamic> json) =>
      _$DepartmentSummaryFromJson(json);
}

/// Recent activity item
@freezed
class RecentActivity with _$RecentActivity {
  const factory RecentActivity({
    required String profileId,
    required String profileName,
    required DateTime checkIn,
    required String status,
    String? profilePictureUrl,
  }) = _RecentActivity;

  factory RecentActivity.fromJson(Map<String, dynamic> json) =>
      _$RecentActivityFromJson(json);
}

/// Super Admin dashboard statistics
@freezed
class SuperAdminDashboardStats with _$SuperAdminDashboardStats {
  const factory SuperAdminDashboardStats({
    @Default(0) int totalCompanies,
    @Default(0) int totalUsers,
    @Default(0) int activeUsersToday,
    @Default(0) int activeCompanies,
    @Default(0) int trialCompanies,
    @Default(0) int suspendedCompanies,
    @Default(0.0) double totalRevenue,
    @Default(0.0) double monthlyRevenue,
    @Default([]) List<CompanySummary> topCompanies,
    @Default([]) List<SystemActivity> recentActivity,
  }) = _SuperAdminDashboardStats;

  factory SuperAdminDashboardStats.fromJson(Map<String, dynamic> json) =>
      _$SuperAdminDashboardStatsFromJson(json);
}

/// Company summary
@freezed
class CompanySummary with _$CompanySummary {
  const factory CompanySummary({
    required String id,
    required String name,
    @Default(0) int employeeCount,
    required String status,
    String? logoUrl,
  }) = _CompanySummary;

  factory CompanySummary.fromJson(Map<String, dynamic> json) =>
      _$CompanySummaryFromJson(json);
}

/// System activity
@freezed
class SystemActivity with _$SystemActivity {
  const factory SystemActivity({
    required String id,
    required String action,
    required String description,
    required DateTime timestamp,
    String? actorName,
    String? entityType,
    String? entityId,
  }) = _SystemActivity;

  factory SystemActivity.fromJson(Map<String, dynamic> json) =>
      _$SystemActivityFromJson(json);
}

/// Attendance summary
@freezed
class AttendanceSummary with _$AttendanceSummary {
  const AttendanceSummary._();

  const factory AttendanceSummary({
    @Default(0) int totalDays,
    @Default(0) int presentDays,
    @Default(0) int absentDays,
    @Default(0) int lateDays,
    @Default(0) int halfDays,
    @Default(0.0) double attendancePercentage,
    @Default(0.0) double totalHoursWorked,
    @Default(0.0) double avgHoursWorked,
  }) = _AttendanceSummary;

  factory AttendanceSummary.fromJson(Map<String, dynamic> json) =>
      _$AttendanceSummaryFromJson(json);

  /// Get formatted attendance percentage
  String get formattedPercentage => '${attendancePercentage.toStringAsFixed(1)}%';

  /// Get formatted total hours
  String get formattedTotalHours => '${totalHoursWorked.toStringAsFixed(1)}h';

  /// Get formatted average hours
  String get formattedAvgHours => '${avgHoursWorked.toStringAsFixed(1)}h';
}
