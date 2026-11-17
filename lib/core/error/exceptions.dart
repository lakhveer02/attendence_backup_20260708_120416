/// Base exception for server-related errors
class ServerException implements Exception {
  final String message;
  final int? statusCode;

  ServerException(this.message, {this.statusCode});

  @override
  String toString() => 'ServerException: $message${statusCode != null ? " (Status: $statusCode)" : ""}';
}

/// Network connectivity exceptions
class NetworkException implements Exception {
  final String message;

  NetworkException(this.message);

  @override
  String toString() => 'NetworkException: $message';
}

/// Authentication related exceptions
class AuthenticationException implements Exception {
  final String message;

  AuthenticationException(this.message);

  @override
  String toString() => 'AuthenticationException: $message';
}

/// Authorization/permission exceptions
class AuthorizationException implements Exception {
  final String message;

  AuthorizationException(this.message);

  @override
  String toString() => 'AuthorizationException: $message';
}

/// Permission exceptions
class PermissionException implements Exception {
  final String message;

  PermissionException(this.message);

  @override
  String toString() => 'PermissionException: $message';
}

/// Data validation exceptions
class ValidationException implements Exception {
  final String message;
  final Map<String, String>? fieldErrors;

  ValidationException(this.message, {this.fieldErrors});

  @override
  String toString() => 'ValidationException: $message';
}

/// Resource not found exceptions
class NotFoundException implements Exception {
  final String message;

  NotFoundException(this.message);

  @override
  String toString() => 'NotFoundException: $message';
}

/// Local cache/storage exceptions
class CacheException implements Exception {
  final String message;

  CacheException(this.message);

  @override
  String toString() => 'CacheException: $message';
}

/// Location service exceptions
class LocationException implements Exception {
  final String message;

  LocationException(this.message);

  @override
  String toString() => 'LocationException: $message';
}

/// Biometric authentication exceptions
class BiometricException implements Exception {
  final String message;

  BiometricException(this.message);

  @override
  String toString() => 'BiometricException: $message';
}

/// Face recognition exceptions
class FaceRecognitionException implements Exception {
  final String message;
  final double? confidence;

  FaceRecognitionException(this.message, {this.confidence});

  @override
  String toString() => 'FaceRecognitionException: $message${confidence != null ? " (Confidence: $confidence)" : ""}';
}

/// Device security validation exceptions
class DeviceSecurityException implements Exception {
  final String message;
  final List<String>? violations;

  DeviceSecurityException(this.message, {this.violations});

  @override
  String toString() => 'DeviceSecurityException: $message${violations != null ? " - Violations: ${violations?.join(", ")}" : ""}';
}

/// Geofencing exceptions
class GeofenceException implements Exception {
  final String message;
  final double? distanceFromOffice;

  GeofenceException(this.message, {this.distanceFromOffice});

  @override
  String toString() => 'GeofenceException: $message${distanceFromOffice != null ? " (Distance: ${distanceFromOffice}m)" : ""}';
}
