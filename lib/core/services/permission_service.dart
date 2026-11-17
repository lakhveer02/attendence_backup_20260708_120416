import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:logger/logger.dart';
import 'package:device_info_plus/device_info_plus.dart';

/// Comprehensive Permission Management Service
/// Handles all app permissions with user-friendly flows
class PermissionService {
  final Logger _logger = Logger();
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  // Singleton
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  /// Check if a permission is granted
  Future<bool> isGranted(Permission permission) async {
    final status = await permission.status;
    return status.isGranted;
  }

  /// Check if a permission is permanently denied
  Future<bool> isPermanentlyDenied(Permission permission) async {
    final status = await permission.status;
    return status.isPermanentlyDenied;
  }

  /// Request a single permission with rationale
  Future<PermissionResult> request(
    Permission permission, {
    String? title,
    String? message,
    BuildContext? context,
  }) async {
    try {
      final status = await permission.status;

      // Already granted
      if (status.isGranted) {
        return PermissionResult(
          permission: permission,
          status: PermissionStatus.granted,
          isGranted: true,
        );
      }

      // Show rationale before requesting (if context provided)
      if (context != null && status.isDenied) {
        final shouldRequest = await _showPermissionRationale(
          context,
          title ?? _getPermissionTitle(permission),
          message ?? _getPermissionMessage(permission),
        );

        if (!shouldRequest) {
          return PermissionResult(
            permission: permission,
            status: PermissionStatus.denied,
            isGranted: false,
            userCancelled: true,
          );
        }
      }

      // Permanently denied - must open settings
      if (status.isPermanentlyDenied) {
        if (context != null) {
          final openSettings = await _showOpenSettingsDialog(
            context,
            title ?? _getPermissionTitle(permission),
            'This permission was previously denied. Please enable it in settings.',
          );

          if (openSettings) {
            await openAppSettings();
          }
        }

        return PermissionResult(
          permission: permission,
          status: PermissionStatus.permanentlyDenied,
          isGranted: false,
          isPermanentlyDenied: true,
        );
      }

      // Request permission
      final newStatus = await permission.request();

      return PermissionResult(
        permission: permission,
        status: newStatus,
        isGranted: newStatus.isGranted,
        isPermanentlyDenied: newStatus.isPermanentlyDenied,
      );
    } catch (e) {
      _logger.e('Error requesting permission $permission: $e');
      return PermissionResult(
        permission: permission,
        status: PermissionStatus.denied,
        isGranted: false,
        error: e.toString(),
      );
    }
  }

  /// Request multiple permissions at once
  Future<Map<Permission, PermissionResult>> requestMultiple(
    List<Permission> permissions, {
    BuildContext? context,
  }) async {
    final results = <Permission, PermissionResult>{};

    for (final permission in permissions) {
      results[permission] = await request(permission, context: context);
    }

    return results;
  }

  /// Request all required app permissions
  Future<AppPermissionsResult> requestAppPermissions({
    BuildContext? context,
    bool includeOptional = true,
  }) async {
    final required = await _requestRequiredPermissions(context);
    final optional = includeOptional 
        ? await _requestOptionalPermissions(context)
        : <Permission, PermissionResult>{};

    return AppPermissionsResult(
      required: required,
      optional: optional,
      allGranted: required.values.every((r) => r.isGranted),
      requiredGranted: required.values.every((r) => r.isGranted),
    );
  }

  /// Request biometric-related permissions
  Future<BiometricPermissionsResult> requestBiometricPermissions({
    BuildContext? context,
  }) async {
    // Biometric permissions are handled by local_auth, not permission_handler
    return BiometricPermissionsResult(
      isGranted: true,
      permissions: {},
      message: 'Biometric permissions are handled by the system',
    );
  }

  /// Request location permissions (for attendance check-in)
  Future<LocationPermissionsResult> requestLocationPermissions({
    BuildContext? context,
    bool precise = true,
  }) async {
    final androidInfo = Platform.isAndroid
        ? await _deviceInfo.androidInfo
        : null;

    final permissions = <Permission>[];

    if (Platform.isAndroid) {
      // Android 12+ requires both permissions for precise location
      if (androidInfo != null && androidInfo.version.sdkInt >= 31 && precise) {
        permissions.addAll([
          Permission.location,
          Permission.locationWhenInUse,
        ]);
      } else {
        permissions.add(Permission.location);
      }
    } else if (Platform.isIOS) {
      permissions.add(Permission.locationWhenInUse);
    }

    final results = await requestMultiple(permissions, context: context);
    final allGranted = results.values.every((r) => r.isGranted);

    return LocationPermissionsResult(
      isGranted: allGranted,
      permissions: results,
      isPrecise: precise && allGranted,
      message: allGranted
          ? 'Location permissions granted'
          : 'Location permissions denied',
    );
  }

  /// Request camera permissions (for face recognition)
  Future<PermissionResult> requestCameraPermission({
    BuildContext? context,
  }) async {
    return request(
      Permission.camera,
      title: 'Camera Access',
      message: 'Camera is needed for face recognition during attendance check-in.',
      context: context,
    );
  }

  /// Request notification permissions
  Future<PermissionResult> requestNotificationPermission({
    BuildContext? context,
  }) async {
    return request(
      Permission.notification,
      title: 'Notifications',
      message: 'Enable notifications to receive attendance reminders and updates.',
      context: context,
    );
  }

  /// Check all app permissions status
  Future<AppPermissionsStatus> checkAppPermissionsStatus() async {
    final required = await _checkRequiredPermissions();
    final optional = await _checkOptionalPermissions();

    return AppPermissionsStatus(
      required: required,
      optional: optional,
      allGranted: required.values.every((granted) => granted),
      requiredGranted: required.values.every((granted) => granted),
    );
  }

  /// Open app settings
  Future<bool> openSettings() async {
    try {
      return await openAppSettings();
    } catch (e) {
      _logger.e('Error opening settings: $e');
      return false;
    }
  }

  // Private helper methods

  Future<Map<Permission, PermissionResult>> _requestRequiredPermissions(
    BuildContext? context,
  ) async {
    final permissions = <Permission>[
      Permission.location,
      Permission.camera,
    ];

    return requestMultiple(permissions, context: context);
  }

  Future<Map<Permission, PermissionResult>> _requestOptionalPermissions(
    BuildContext? context,
  ) async {
    final permissions = <Permission>[
      Permission.notification,
      Permission.storage,
    ];

    return requestMultiple(permissions, context: context);
  }

  Future<Map<Permission, bool>> _checkRequiredPermissions() async {
    return {
      Permission.location: await isGranted(Permission.location),
      Permission.camera: await isGranted(Permission.camera),
    };
  }

  Future<Map<Permission, bool>> _checkOptionalPermissions() async {
    return {
      Permission.notification: await isGranted(Permission.notification),
      Permission.storage: await isGranted(Permission.storage),
    };
  }

  String _getPermissionTitle(Permission permission) {
    switch (permission) {
      case Permission.location:
      case Permission.locationWhenInUse:
      case Permission.locationAlways:
        return 'Location Access';
      case Permission.camera:
        return 'Camera Access';
      case Permission.notification:
        return 'Notifications';
      case Permission.storage:
        return 'Storage Access';
      default:
        return 'Permission Required';
    }
  }

  String _getPermissionMessage(Permission permission) {
    switch (permission) {
      case Permission.location:
      case Permission.locationWhenInUse:
        return 'Location is required to verify your attendance check-in location.';
      case Permission.locationAlways:
        return 'Always-on location is needed for geofencing features.';
      case Permission.camera:
        return 'Camera access is needed for face recognition during attendance.';
      case Permission.notification:
        return 'Notifications help you stay updated with attendance reminders.';
      case Permission.storage:
        return 'Storage access is needed to save attendance reports and documents.';
      default:
        return 'This permission is required for the app to function properly.';
    }
  }

  Future<bool> _showPermissionRationale(
    BuildContext context,
    String title,
    String message,
  ) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Not Now'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Continue'),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<bool> _showOpenSettingsDialog(
    BuildContext context,
    String title,
    String message,
  ) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    ) ?? false;
  }
}

// Result classes

class PermissionResult {
  final Permission permission;
  final PermissionStatus status;
  final bool isGranted;
  final bool isPermanentlyDenied;
  final bool userCancelled;
  final String? error;

  PermissionResult({
    required this.permission,
    required this.status,
    required this.isGranted,
    this.isPermanentlyDenied = false,
    this.userCancelled = false,
    this.error,
  });

  @override
  String toString() {
    return 'PermissionResult($permission: ${isGranted ? "granted" : "denied"})';
  }
}

class AppPermissionsResult {
  final Map<Permission, PermissionResult> required;
  final Map<Permission, PermissionResult> optional;
  final bool allGranted;
  final bool requiredGranted;

  AppPermissionsResult({
    required this.required,
    required this.optional,
    required this.allGranted,
    required this.requiredGranted,
  });

  List<Permission> get deniedPermissions {
    final denied = <Permission>[];
    required.forEach((permission, result) {
      if (!result.isGranted) denied.add(permission);
    });
    optional.forEach((permission, result) {
      if (!result.isGranted) denied.add(permission);
    });
    return denied;
  }

  List<Permission> get permanentlyDeniedPermissions {
    final denied = <Permission>[];
    required.forEach((permission, result) {
      if (result.isPermanentlyDenied) denied.add(permission);
    });
    optional.forEach((permission, result) {
      if (result.isPermanentlyDenied) denied.add(permission);
    });
    return denied;
  }
}

class AppPermissionsStatus {
  final Map<Permission, bool> required;
  final Map<Permission, bool> optional;
  final bool allGranted;
  final bool requiredGranted;

  AppPermissionsStatus({
    required this.required,
    required this.optional,
    required this.allGranted,
    required this.requiredGranted,
  });
}

class BiometricPermissionsResult {
  final bool isGranted;
  final Map<Permission, PermissionResult> permissions;
  final String message;

  BiometricPermissionsResult({
    required this.isGranted,
    required this.permissions,
    required this.message,
  });
}

class LocationPermissionsResult {
  final bool isGranted;
  final Map<Permission, PermissionResult> permissions;
  final bool isPrecise;
  final String message;

  LocationPermissionsResult({
    required this.isGranted,
    required this.permissions,
    required this.isPrecise,
    required this.message,
  });
}
