import 'package:freezed_annotation/freezed_annotation.dart';

part 'attendance.freezed.dart';
part 'attendance.g.dart';

/// Attendance status enumeration
enum AttendanceStatus {
  @JsonValue('present')
  present,
  @JsonValue('absent')
  absent,
  @JsonValue('late')
  late,
  @JsonValue('half_day')
  halfDay,
}

/// Verification method enumeration
enum VerificationMethod {
  @JsonValue('biometric')
  biometric,
  @JsonValue('face')
  face,
  @JsonValue('hybrid')
  hybrid,
}

/// Geographic coordinates
@freezed
class GeoCoordinates with _$GeoCoordinates {
  const factory GeoCoordinates({
    required double latitude,
    required double longitude,
  }) = _GeoCoordinates;

  factory GeoCoordinates.fromJson(Map<String, dynamic> json) =>
      _$GeoCoordinatesFromJson(json);
}

/// Attendance entity representing a check-in/check-out record
@freezed
class Attendance with _$Attendance {
  const factory Attendance({
    required String id,
    required String profileId,
    String? profileName,
    String? profilePictureUrl,
    required DateTime checkIn,
    DateTime? checkOut,
    required AttendanceStatus status,
    GeoCoordinates? checkInGps,
    GeoCoordinates? checkOutGps,
    bool? isWfh,
    VerificationMethod? verificationMethod,
    String? checkInPhotoUrl,
    String? checkOutPhotoUrl,
    double? faceMatchConfidence,
    String? deviceId,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _Attendance;

  factory Attendance.fromJson(Map<String, dynamic> json) =>
      _$AttendanceFromJson(json);
}

/// Extension for business logic
extension AttendanceX on Attendance {
  /// Calculate total worked hours
  Duration? get workedHours {
    if (checkOut == null) return null;
    return checkOut!.difference(checkIn);
  }

  /// Check if attendance is for today
  bool get isToday {
    final now = DateTime.now();
    return checkIn.year == now.year &&
        checkIn.month == now.month &&
        checkIn.day == now.day;
  }

  /// Get formatted worked hours (e.g., "8h 30m")
  String get formattedWorkedHours {
    final hours = workedHours;
    if (hours == null) return 'In Progress';
    
    final h = hours.inHours;
    final m = hours.inMinutes.remainder(60);
    return '${h}h ${m}m';
  }
}
