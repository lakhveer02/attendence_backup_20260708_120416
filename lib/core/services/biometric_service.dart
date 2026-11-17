import 'dart:io';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/local_auth_darwin.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:logger/logger.dart';

/// Comprehensive Biometric Authentication Service
/// Supports: Fingerprint, Face ID, Face Recognition, Iris Scan
class BiometricService {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  final Logger _logger = Logger();

  // Cache for device capabilities
  BiometricCapabilities? _cachedCapabilities;
  
  /// Check if device has biometric hardware
  Future<bool> hasBiometricHardware() async {
    try {
      return await _localAuth.canCheckBiometrics || 
             await _localAuth.isDeviceSupported();
    } catch (e) {
      _logger.e('Error checking biometric hardware: $e');
      return false;
    }
  }

  /// Get detailed biometric capabilities of the device
  Future<BiometricCapabilities> getDeviceCapabilities() async {
    // Return cached if available
    if (_cachedCapabilities != null) {
      return _cachedCapabilities!;
    }

    try {
      final hasHardware = await hasBiometricHardware();
      if (!hasHardware) {
        _cachedCapabilities = BiometricCapabilities(
          hasBiometrics: false,
          availableTypes: [],
          deviceInfo: await _getDeviceInfo(),
        );
        return _cachedCapabilities!;
      }

      // Get available biometric types
      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      
      // Get detailed device info
      final deviceInfo = await _getDeviceInfo();

      _cachedCapabilities = BiometricCapabilities(
        hasBiometrics: true,
        availableTypes: availableBiometrics,
        hasFingerprint: availableBiometrics.contains(BiometricType.fingerprint),
        hasFaceRecognition: availableBiometrics.contains(BiometricType.face),
        hasIris: availableBiometrics.contains(BiometricType.iris),
        hasStrongBiometrics: availableBiometrics.contains(BiometricType.strong),
        hasWeakBiometrics: availableBiometrics.contains(BiometricType.weak),
        deviceInfo: deviceInfo,
      );

      _logger.i('Device Biometric Capabilities: $_cachedCapabilities');
      return _cachedCapabilities!;
    } catch (e) {
      _logger.e('Error getting device capabilities: $e');
      return BiometricCapabilities(
        hasBiometrics: false,
        availableTypes: [],
        deviceInfo: await _getDeviceInfo(),
      );
    }
  }

  /// Authenticate using biometrics with detailed options
  Future<BiometricAuthResult> authenticate({
    String reason = 'Verify your identity',
    bool useErrorDialogs = true,
    bool stickyAuth = true,
    BiometricType? preferredType,
  }) async {
    try {
      // Check if biometrics are available
      final capabilities = await getDeviceCapabilities();
      
      if (!capabilities.hasBiometrics) {
        return BiometricAuthResult(
          success: false,
          errorMessage: 'No biometric authentication available',
          errorCode: BiometricErrorCode.notAvailable,
        );
      }

      // Check if enrolled
      final hasEnrolled = capabilities.availableTypes.isNotEmpty;
      if (!hasEnrolled) {
        return BiometricAuthResult(
          success: false,
          errorMessage: 'No biometrics enrolled. Please set up biometric authentication in device settings.',
          errorCode: BiometricErrorCode.notEnrolled,
        );
      }

      // Build authentication options based on platform
      final authenticated = await _localAuth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          useErrorDialogs: useErrorDialogs,
          stickyAuth: stickyAuth,
          biometricOnly: true,
          sensitiveTransaction: true,
        ),
        authMessages: _getAuthMessages(capabilities, preferredType),
      );

      if (authenticated) {
        _logger.i('Biometric authentication successful');
        return BiometricAuthResult(
          success: true,
          biometricType: _getUsedBiometricType(capabilities, preferredType),
        );
      } else {
        return BiometricAuthResult(
          success: false,
          errorMessage: 'Authentication failed or cancelled',
          errorCode: BiometricErrorCode.authFailed,
        );
      }
    } on PlatformException catch (e) {
      _logger.e('Biometric authentication error: ${e.code} - ${e.message}');
      return BiometricAuthResult(
        success: false,
        errorMessage: _parseErrorMessage(e),
        errorCode: _parseErrorCode(e.code),
        platformException: e,
      );
    } catch (e) {
      _logger.e('Unexpected biometric error: $e');
      return BiometricAuthResult(
        success: false,
        errorMessage: 'An unexpected error occurred',
        errorCode: BiometricErrorCode.unknown,
      );
    }
  }

  /// Authenticate with fingerprint specifically (if available)
  Future<BiometricAuthResult> authenticateWithFingerprint({
    String reason = 'Scan your fingerprint',
  }) async {
    final capabilities = await getDeviceCapabilities();
    
    if (!capabilities.hasFingerprint) {
      return BiometricAuthResult(
        success: false,
        errorMessage: 'Fingerprint authentication not available',
        errorCode: BiometricErrorCode.notAvailable,
      );
    }

    return authenticate(
      reason: reason,
      preferredType: BiometricType.fingerprint,
    );
  }

  /// Authenticate with face recognition specifically (if available)
  Future<BiometricAuthResult> authenticateWithFace({
    String reason = 'Scan your face',
  }) async {
    final capabilities = await getDeviceCapabilities();
    
    if (!capabilities.hasFaceRecognition) {
      return BiometricAuthResult(
        success: false,
        errorMessage: 'Face recognition not available',
        errorCode: BiometricErrorCode.notAvailable,
      );
    }

    return authenticate(
      reason: reason,
      preferredType: BiometricType.face,
    );
  }

  /// Stop biometric authentication
  Future<void> stopAuthentication() async {
    try {
      await _localAuth.stopAuthentication();
    } catch (e) {
      _logger.e('Error stopping authentication: $e');
    }
  }

  /// Clear cached capabilities (call when device settings might have changed)
  void clearCache() {
    _cachedCapabilities = null;
  }

  // Helper methods

  Future<DeviceInfo> _getDeviceInfo() async {
    if (Platform.isAndroid) {
      final androidInfo = await _deviceInfo.androidInfo;
      return DeviceInfo(
        platform: 'Android',
        model: androidInfo.model,
        brand: androidInfo.brand,
        device: androidInfo.device,
        osVersion: androidInfo.version.release,
        sdkVersion: androidInfo.version.sdkInt.toString(),
        manufacturer: androidInfo.manufacturer,
      );
    } else if (Platform.isIOS) {
      final iosInfo = await _deviceInfo.iosInfo;
      return DeviceInfo(
        platform: 'iOS',
        model: iosInfo.model,
        brand: 'Apple',
        device: iosInfo.name,
        osVersion: iosInfo.systemVersion,
        manufacturer: 'Apple',
      );
    }
    return DeviceInfo(platform: 'Unknown');
  }

  List<AuthMessages> _getAuthMessages(
    BiometricCapabilities capabilities,
    BiometricType? preferredType,
  ) {
    if (Platform.isAndroid) {
      return [
        AndroidAuthMessages(
          signInTitle: _getAndroidTitle(capabilities, preferredType),
          cancelButton: 'Cancel',
          biometricHint: _getAndroidHint(capabilities, preferredType),
          biometricNotRecognized: 'Not recognized. Try again.',
          biometricRequiredTitle: 'Biometric required',
          biometricSuccess: 'Success!',
          deviceCredentialsRequiredTitle: 'Device credentials required',
          deviceCredentialsSetupDescription: 'Please set up device security',
          goToSettingsButton: 'Go to Settings',
          goToSettingsDescription: 'Set up biometric authentication',
        ),
      ];
    } else if (Platform.isIOS) {
      return [
        const IOSAuthMessages(
          cancelButton: 'Cancel',
        ),
      ];
    }
    return [];
  }

  String _getAndroidTitle(BiometricCapabilities capabilities, BiometricType? preferredType) {
    if (preferredType == BiometricType.fingerprint || capabilities.hasFingerprint) {
      return 'Fingerprint Authentication';
    } else if (preferredType == BiometricType.face || capabilities.hasFaceRecognition) {
      return 'Face Authentication';
    }
    return 'Biometric Authentication';
  }

  String _getAndroidHint(BiometricCapabilities capabilities, BiometricType? preferredType) {
    if (preferredType == BiometricType.fingerprint || capabilities.hasFingerprint) {
      return 'Touch the fingerprint sensor';
    } else if (preferredType == BiometricType.face || capabilities.hasFaceRecognition) {
      return 'Look at the camera';
    }
    return 'Use your biometric';
  }

  BiometricType? _getUsedBiometricType(
    BiometricCapabilities capabilities,
    BiometricType? preferredType,
  ) {
    if (preferredType != null && capabilities.availableTypes.contains(preferredType)) {
      return preferredType;
    }
    return capabilities.availableTypes.firstOrNull;
  }

  String _parseErrorMessage(PlatformException e) {
    switch (e.code) {
      case 'NotAvailable':
        return 'Biometric authentication is not available';
      case 'NotEnrolled':
        return 'No biometrics enrolled. Please set up biometric authentication.';
      case 'LockedOut':
        return 'Too many failed attempts. Please try again later.';
      case 'PermanentlyLockedOut':
        return 'Biometric authentication is permanently locked. Use device password.';
      case 'PasscodeNotSet':
        return 'No device passcode set. Please set up device security.';
      case 'OtherOperatingSystem':
        return 'Biometric authentication not supported on this platform';
      default:
        return e.message ?? 'Authentication failed';
    }
  }

  BiometricErrorCode _parseErrorCode(String code) {
    switch (code) {
      case 'NotAvailable':
        return BiometricErrorCode.notAvailable;
      case 'NotEnrolled':
        return BiometricErrorCode.notEnrolled;
      case 'LockedOut':
      case 'PermanentlyLockedOut':
        return BiometricErrorCode.lockedOut;
      case 'PasscodeNotSet':
        return BiometricErrorCode.passcodeNotSet;
      default:
        return BiometricErrorCode.authFailed;
    }
  }
}

// Data classes

class BiometricCapabilities {
  final bool hasBiometrics;
  final List<BiometricType> availableTypes;
  final bool hasFingerprint;
  final bool hasFaceRecognition;
  final bool hasIris;
  final bool hasStrongBiometrics;
  final bool hasWeakBiometrics;
  final DeviceInfo deviceInfo;

  BiometricCapabilities({
    required this.hasBiometrics,
    required this.availableTypes,
    this.hasFingerprint = false,
    this.hasFaceRecognition = false,
    this.hasIris = false,
    this.hasStrongBiometrics = false,
    this.hasWeakBiometrics = false,
    required this.deviceInfo,
  });

  String get primaryBiometricName {
    if (hasFingerprint) return 'Fingerprint';
    if (hasFaceRecognition) return 'Face Recognition';
    if (hasIris) return 'Iris Scanner';
    if (hasStrongBiometrics) return 'Strong Biometric';
    return 'Biometric';
  }

  @override
  String toString() {
    return 'BiometricCapabilities(hasBiometrics: $hasBiometrics, '
        'fingerprint: $hasFingerprint, face: $hasFaceRecognition, '
        'iris: $hasIris, device: ${deviceInfo.model})';
  }
}

class DeviceInfo {
  final String platform;
  final String? model;
  final String? brand;
  final String? device;
  final String? osVersion;
  final String? sdkVersion;
  final String? manufacturer;

  DeviceInfo({
    required this.platform,
    this.model,
    this.brand,
    this.device,
    this.osVersion,
    this.sdkVersion,
    this.manufacturer,
  });

  @override
  String toString() {
    return '$manufacturer $brand $model ($platform $osVersion)';
  }
}

class BiometricAuthResult {
  final bool success;
  final String? errorMessage;
  final BiometricErrorCode? errorCode;
  final BiometricType? biometricType;
  final PlatformException? platformException;

  BiometricAuthResult({
    required this.success,
    this.errorMessage,
    this.errorCode,
    this.biometricType,
    this.platformException,
  });

  @override
  String toString() {
    if (success) {
      return 'BiometricAuthResult(success: true, type: $biometricType)';
    }
    return 'BiometricAuthResult(success: false, error: $errorMessage, code: $errorCode)';
  }
}

enum BiometricErrorCode {
  notAvailable,
  notEnrolled,
  authFailed,
  lockedOut,
  passcodeNotSet,
  userCancelled,
  unknown,
}
