import 'package:freezed_annotation/freezed_annotation.dart';

part 'failures.freezed.dart';

/// Base failure class using Freezed for immutable error states
@freezed
class Failure with _$Failure {
  const factory Failure.server({
    required String message,
    int? statusCode,
  }) = ServerFailure;

  const factory Failure.network({
    required String message,
  }) = NetworkFailure;

  const factory Failure.authentication({
    required String message,
  }) = AuthenticationFailure;

  const factory Failure.authorization({
    required String message,
  }) = AuthorizationFailure;

  const factory Failure.validation({
    required String message,
    Map<String, String>? fieldErrors,
  }) = ValidationFailure;

  const factory Failure.notFound({
    required String message,
  }) = NotFoundFailure;

  const factory Failure.cache({
    required String message,
  }) = CacheFailure;

  const factory Failure.location({
    required String message,
  }) = LocationFailure;

  const factory Failure.biometric({
    required String message,
  }) = BiometricFailure;

  const factory Failure.faceRecognition({
    required String message,
    double? confidence,
  }) = FaceRecognitionFailure;

  const factory Failure.deviceSecurity({
    required String message,
    List<String>? violations,
  }) = DeviceSecurityFailure;

  const factory Failure.geofence({
    required String message,
    double? distanceFromOffice,
  }) = GeofenceFailure;

  const factory Failure.unknown({
    required String message,
  }) = UnknownFailure;
}

/// Extension to get user-friendly error messages
extension FailureX on Failure {
  String get userMessage {
    return when(
      server: (message, _) => 'Server error: $message',
      network: (message) => 'Network error: Please check your internet connection',
      authentication: (message) => 'Authentication failed: $message',
      authorization: (message) => 'Access denied: $message',
      validation: (message, _) => message,
      notFound: (message) => 'Not found: $message',
      cache: (message) => 'Local storage error: $message',
      location: (message) => 'Location error: $message',
      biometric: (message) => 'Biometric verification failed: $message',
      faceRecognition: (message, confidence) => 
          'Face recognition failed: $message${confidence != null ? " (Confidence: ${(confidence * 100).toStringAsFixed(1)}%)" : ""}',
      deviceSecurity: (message, violations) =>
          'Device security check failed: $message${violations != null && violations.isNotEmpty ? "\nViolations: ${violations.join(", ")}" : ""}',
      geofence: (message, distance) =>
          'Location check failed: $message${distance != null ? " (Distance: ${distance.toStringAsFixed(0)}m from office)" : ""}',
      unknown: (message) => 'An unexpected error occurred: $message',
    );
  }
}
