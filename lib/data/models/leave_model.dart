import 'package:freezed_annotation/freezed_annotation.dart';

part 'leave_model.freezed.dart';
part 'leave_model.g.dart';

/// Leave type enumeration
enum LeaveType {
  @JsonValue('sick')
  sick,
  @JsonValue('casual')
  casual,
  @JsonValue('earned')
  earned,
  @JsonValue('unpaid')
  unpaid,
  @JsonValue('maternity')
  maternity,
  @JsonValue('paternity')
  paternity,
  @JsonValue('compensatory')
  compensatory,
  @JsonValue('bereavement')
  bereavement,
}

/// Leave status enumeration
enum LeaveStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('approved')
  approved,
  @JsonValue('rejected')
  rejected,
  @JsonValue('cancelled')
  cancelled,
}

/// Leave model
@freezed
class LeaveModel with _$LeaveModel {
  const LeaveModel._();

  const factory LeaveModel({
    required String id,
    required String companyId,
    required String profileId,
    String? profileName,
    required LeaveType leaveType,
    required DateTime startDate,
    required DateTime endDate,
    required double totalDays,
    @Default(false) bool halfDay,
    required String reason,
    @Default(LeaveStatus.pending) LeaveStatus status,
    String? approvedBy,
    DateTime? approvedAt,
    String? rejectionReason,
    DateTime? createdAt,
  }) = _LeaveModel;

  factory LeaveModel.fromJson(Map<String, dynamic> json) =>
      _$LeaveModelFromJson(json);

  /// Get display name for leave type
  String get leaveTypeDisplayName {
    switch (leaveType) {
      case LeaveType.sick:
        return 'Sick Leave';
      case LeaveType.casual:
        return 'Casual Leave';
      case LeaveType.earned:
        return 'Earned Leave';
      case LeaveType.unpaid:
        return 'Unpaid Leave';
      case LeaveType.maternity:
        return 'Maternity Leave';
      case LeaveType.paternity:
        return 'Paternity Leave';
      case LeaveType.compensatory:
        return 'Compensatory Off';
      case LeaveType.bereavement:
        return 'Bereavement Leave';
    }
  }

  /// Get display name for status
  String get statusDisplayName {
    switch (status) {
      case LeaveStatus.pending:
        return 'Pending';
      case LeaveStatus.approved:
        return 'Approved';
      case LeaveStatus.rejected:
        return 'Rejected';
      case LeaveStatus.cancelled:
        return 'Cancelled';
    }
  }

  /// Check if leave is pending
  bool get isPending => status == LeaveStatus.pending;

  /// Check if leave is approved
  bool get isApproved => status == LeaveStatus.approved;

  /// Check if leave is rejected
  bool get isRejected => status == LeaveStatus.rejected;
}

/// Leave request
@freezed
class LeaveRequest with _$LeaveRequest {
  const factory LeaveRequest({
    required String profileId,
    required LeaveType leaveType,
    required DateTime startDate,
    required DateTime endDate,
    @Default(false) bool halfDay,
    required String reason,
    String? attachmentUrl,
    String? replacementProfileId,
    String? emergencyContact,
  }) = _LeaveRequest;

  factory LeaveRequest.fromJson(Map<String, dynamic> json) =>
      _$LeaveRequestFromJson(json);
}

/// Leave balance model
@freezed
class LeaveBalance with _$LeaveBalance {
  const LeaveBalance._();

  const factory LeaveBalance({
    required String profileId,
    required LeaveType leaveType,
    required int year,
    required double totalAllocated,
    required double used,
    required double balance,
    @Default(0.0) double carriedForward,
  }) = _LeaveBalance;

  factory LeaveBalance.fromJson(Map<String, dynamic> json) =>
      _$LeaveBalanceFromJson(json);

  /// Get display name for leave type
  String get leaveTypeDisplayName {
    switch (leaveType) {
      case LeaveType.sick:
        return 'Sick Leave';
      case LeaveType.casual:
        return 'Casual Leave';
      case LeaveType.earned:
        return 'Earned Leave';
      case LeaveType.unpaid:
        return 'Unpaid Leave';
      case LeaveType.maternity:
        return 'Maternity Leave';
      case LeaveType.paternity:
        return 'Paternity Leave';
      case LeaveType.compensatory:
        return 'Compensatory Off';
      case LeaveType.bereavement:
        return 'Bereavement Leave';
    }
  }
}
