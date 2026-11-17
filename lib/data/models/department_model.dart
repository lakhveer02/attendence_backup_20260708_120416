import 'package:freezed_annotation/freezed_annotation.dart';

part 'department_model.freezed.dart';
part 'department_model.g.dart';

/// Department model
@freezed
class DepartmentModel with _$DepartmentModel {
  const DepartmentModel._();

  const factory DepartmentModel({
    required String id,
    required String companyId,
    required String name,
    String? code,
    String? description,
    String? managerId,
    String? managerName,
    @Default(0) int employeeCount,
    @Default(true) bool isActive,
    DateTime? createdAt,
  }) = _DepartmentModel;

  factory DepartmentModel.fromJson(Map<String, dynamic> json) =>
      _$DepartmentModelFromJson(json);
}

/// Department create/update request
@freezed
class DepartmentRequest with _$DepartmentRequest {
  const factory DepartmentRequest({
    required String companyId,
    required String name,
    String? code,
    String? description,
    String? managerId,
    String? parentDepartmentId,
    String? location,
  }) = _DepartmentRequest;

  factory DepartmentRequest.fromJson(Map<String, dynamic> json) =>
      _$DepartmentRequestFromJson(json);
}
