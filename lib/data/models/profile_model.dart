import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:attendence/domain/entities/profile.dart';

part 'profile_model.freezed.dart';
part 'profile_model.g.dart';

/// Profile data model for Supabase serialization
@freezed
class ProfileModel with _$ProfileModel {
  const ProfileModel._();

  const factory ProfileModel({
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
  }) = _ProfileModel;

  factory ProfileModel.fromJson(Map<String, dynamic> json) =>
      _$ProfileModelFromJson(json);

  /// Convert to domain entity
  Profile toEntity() => Profile(
        id: id,
        fullName: fullName,
        email: email,
        role: role,
        companyId: companyId,
        companyName: companyName,
        phoneNumber: phoneNumber,
        deviceId: deviceId,
        departmentId: departmentId,
        departmentName: departmentName,
        profilePictureUrl: profilePictureUrl,
        faceEmbeddingUrl: faceEmbeddingUrl,
        isActive: isActive,
        isFirstLogin: isFirstLogin,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  /// Create from domain entity
  factory ProfileModel.fromEntity(Profile entity) => ProfileModel(
        id: entity.id,
        fullName: entity.fullName,
        email: entity.email,
        role: entity.role,
        companyId: entity.companyId,
        companyName: entity.companyName,
        phoneNumber: entity.phoneNumber,
        deviceId: entity.deviceId,
        departmentId: entity.departmentId,
        departmentName: entity.departmentName,
        profilePictureUrl: entity.profilePictureUrl,
        faceEmbeddingUrl: entity.faceEmbeddingUrl,
        isActive: entity.isActive,
        createdAt: entity.createdAt,
        updatedAt: entity.updatedAt,
      );
}
