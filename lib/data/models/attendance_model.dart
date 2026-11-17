import 'package:attendence/domain/entities/attendance.dart';

/// Attendance Model for JSON serialization/deserialization
/// Maps FastAPI responses to domain entities
class AttendanceModel {
  final String id;
  final String profileId;
  final String? profileName;
  final String? profilePictureUrl;
  final DateTime checkIn;
  final DateTime? checkOut;
  final AttendanceStatus status;
  final GeoCoordinates? checkInGps;
  final GeoCoordinates? checkOutGps;
  final bool? isWfh;
  final VerificationMethod? verificationMethod;
  final String? checkInPhotoUrl;
  final String? checkOutPhotoUrl;
  final double? faceMatchConfidence;
  final String? deviceId;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AttendanceModel({
    required this.id,
    required this.profileId,
    this.profileName,
    this.profilePictureUrl,
    required this.checkIn,
    this.checkOut,
    required this.status,
    this.checkInGps,
    this.checkOutGps,
    this.isWfh,
    this.verificationMethod,
    this.checkInPhotoUrl,
    this.checkOutPhotoUrl,
    this.faceMatchConfidence,
    this.deviceId,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  /// Convert to domain entity
  Attendance toEntity() {
    return Attendance(
      id: id,
      profileId: profileId,
      profileName: profileName,
      profilePictureUrl: profilePictureUrl,
      checkIn: checkIn,
      checkOut: checkOut,
      status: status,
      checkInGps: checkInGps,
      checkOutGps: checkOutGps,
      isWfh: isWfh,
      verificationMethod: verificationMethod,
      checkInPhotoUrl: checkInPhotoUrl,
      checkOutPhotoUrl: checkOutPhotoUrl,
      faceMatchConfidence: faceMatchConfidence,
      deviceId: deviceId,
      notes: notes,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Create from JSON
  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: json['id'] as String,
      profileId: json['profile_id'] as String,
      profileName: json['profile_name'] as String?,
      profilePictureUrl: json['profile_picture_url'] as String?,
      checkIn: DateTime.parse(json['check_in'] as String),
      checkOut: json['check_out'] != null
          ? DateTime.parse(json['check_out'] as String)
          : null,
      status: _parseStatus(json['status'] as String?),
      checkInGps: json['check_in_gps'] != null
          ? GeoCoordinates.fromJson(json['check_in_gps'] as Map<String, dynamic>)
          : null,
      checkOutGps: json['check_out_gps'] != null
          ? GeoCoordinates.fromJson(json['check_out_gps'] as Map<String, dynamic>)
          : null,
      isWfh: json['is_wfh'] as bool?,
      verificationMethod: json['verification_method'] != null
          ? _parseVerificationMethod(json['verification_method'] as String)
          : null,
      checkInPhotoUrl: json['check_in_photo_url'] as String?,
      checkOutPhotoUrl: json['check_out_photo_url'] as String?,
      faceMatchConfidence: json['face_match_confidence'] != null
          ? (json['face_match_confidence'] as num).toDouble()
          : null,
      deviceId: json['device_id'] as String?,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'profile_id': profileId,
      if (profileName != null) 'profile_name': profileName,
      if (profilePictureUrl != null) 'profile_picture_url': profilePictureUrl,
      'check_in': checkIn.toIso8601String(),
      if (checkOut != null) 'check_out': checkOut!.toIso8601String(),
      'status': status.name,
      if (checkInGps != null) 'check_in_gps': checkInGps!.toJson(),
      if (checkOutGps != null) 'check_out_gps': checkOutGps!.toJson(),
      if (isWfh != null) 'is_wfh': isWfh,
      if (verificationMethod != null)
        'verification_method': verificationMethod!.name,
      if (checkInPhotoUrl != null) 'check_in_photo_url': checkInPhotoUrl,
      if (checkOutPhotoUrl != null) 'check_out_photo_url': checkOutPhotoUrl,
      if (faceMatchConfidence != null)
        'face_match_confidence': faceMatchConfidence,
      if (deviceId != null) 'device_id': deviceId,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  /// Parse status from string
  static AttendanceStatus _parseStatus(String? status) {
    if (status == null) return AttendanceStatus.present;
    
    switch (status.toLowerCase()) {
      case 'present':
        return AttendanceStatus.present;
      case 'absent':
        return AttendanceStatus.absent;
      case 'late':
        return AttendanceStatus.late;
      case 'half_day':
        return AttendanceStatus.halfDay;
      default:
        return AttendanceStatus.present;
    }
  }

  /// Parse verification method from string
  static VerificationMethod _parseVerificationMethod(String method) {
    switch (method.toLowerCase()) {
      case 'biometric':
        return VerificationMethod.biometric;
      case 'face':
        return VerificationMethod.face;
      case 'hybrid':
        return VerificationMethod.hybrid;
      default:
        return VerificationMethod.hybrid;
    }
  }
}
