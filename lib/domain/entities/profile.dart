import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile.freezed.dart';
part 'profile.g.dart';

/// User role enumeration - Must match backend API roles exactly
/// 
/// Definitive Role Hierarchy per Architecture Blueprint:
/// - Company Admin → HR Manager, Manager
/// - HR Manager → Employee, Manager
/// - Manager → Employee only
enum UserRole {
  @JsonValue('super_admin')
  superAdmin,
  @JsonValue('company_admin')
  companyAdmin,
  @JsonValue('hr_manager')
  hrManager,
  @JsonValue('team_manager')
  teamManager,
  @JsonValue('employee')
  employee,
}

/// Profile entity representing a user in the system
@freezed
class Profile with _$Profile {
  const Profile._();

  const factory Profile({
    required String id,
    required String fullName,
    required String email,
    required UserRole role,
    String? companyId,
    String? companyName,
    String? phoneNumber,
    String? deviceId,
    String? departmentId,
    String? departmentName,
    String? profilePictureUrl,
    String? faceEmbeddingUrl,
    bool? isActive,
    bool? isFirstLogin,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _Profile;

  factory Profile.fromJson(Map<String, dynamic> json) => _$ProfileFromJson(_normalizeRoleJson(json));

  static Map<String, dynamic> _normalizeRoleJson(Map<String, dynamic> json) {
    final roleValue = json['role'];
    if (roleValue == 'manager') {
      return {
        ...json,
        'role': 'team_manager',
      };
    }
    return json;
  }

  /// Check if user is super admin
  bool get isSuperAdmin => role == UserRole.superAdmin;

  /// Check if user is company admin
  bool get isCompanyAdmin => role == UserRole.companyAdmin;

  /// Check if user is HR Manager
  bool get isHRManager => role == UserRole.hrManager;

  /// Check if user is team manager
  bool get isTeamManager => role == UserRole.teamManager;

  /// Check if user is any type of admin
  bool get isAdmin => role == UserRole.hrManager || role == UserRole.companyAdmin || role == UserRole.superAdmin;

  /// Check if user is employee
  bool get isEmployee => role == UserRole.employee;

  /// Get display name for role
  String get roleDisplayName {
    switch (role) {
      case UserRole.superAdmin:
        return 'Super Admin';
      case UserRole.companyAdmin:
        return 'Company Admin';
      case UserRole.hrManager:
        return 'HR Manager';
      case UserRole.teamManager:
        return 'Team Manager';
      case UserRole.employee:
        return 'Employee';
    }
  }
  
  /// Get roles this user can create based on hierarchy
  List<UserRole> get canCreateRoles {
    switch (role) {
      case UserRole.superAdmin:
        return [UserRole.superAdmin, UserRole.companyAdmin, UserRole.hrManager, UserRole.teamManager, UserRole.employee];
      case UserRole.companyAdmin:
        return [UserRole.hrManager, UserRole.teamManager];
      case UserRole.hrManager:
        return [UserRole.employee, UserRole.teamManager];
      case UserRole.teamManager:
        return [UserRole.employee];
      case UserRole.employee:
        return [];
    }
  }
}
