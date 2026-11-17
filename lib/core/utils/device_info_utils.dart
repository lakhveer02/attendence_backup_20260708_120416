import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

/// Helper for generating and persisting a stable device identifier,
/// and collecting device metadata for login/device tracking.
class DeviceInfoUtils {
  static const String _deviceIdKey = 'device_id';
  static final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  static final Uuid _uuid = Uuid();

  /// Returns a persistent device ID for this app install.
  static Future<String> getDeviceId() async {
    final existing = await _secureStorage.read(key: _deviceIdKey);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    final newDeviceId = 'flutter-${_uuid.v4()}';
    await _secureStorage.write(key: _deviceIdKey, value: newDeviceId);
    return newDeviceId;
  }

  /// Returns metadata used for login and device tracking.
  static Future<Map<String, String>> getDeviceInfo() async {
    final deviceId = await getDeviceId();
    final deviceModel = await _getDeviceModel();
    final deviceName = await _getDeviceName();
    final deviceOs = _getDeviceOs();

    return {
      'device_id': deviceId,
      'device_name': deviceName,
      'device_os': deviceOs,
      'device_model': deviceModel,
    };
  }

  static Future<String> _getDeviceModel() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (kIsWeb) {
        final webInfo = await deviceInfo.webBrowserInfo;
        return webInfo.userAgent ?? 'Web Browser';
      }

      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          final androidInfo = await deviceInfo.androidInfo;
          return androidInfo.model;
        case TargetPlatform.iOS:
          final iosInfo = await deviceInfo.iosInfo;
          return iosInfo.utsname.machine;
        case TargetPlatform.macOS:
          final macInfo = await deviceInfo.macOsInfo;
          return macInfo.model;
        case TargetPlatform.windows:
          final windowsInfo = await deviceInfo.windowsInfo;
          return windowsInfo.computerName;
        case TargetPlatform.linux:
          final linuxInfo = await deviceInfo.linuxInfo;
          return linuxInfo.name;
        case TargetPlatform.fuchsia:
          return 'Fuchsia Device';
      }
    } catch (_) {
      return 'Unknown Device';
    }
  }

  static Future<String> _getDeviceName() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (kIsWeb) {
        return 'Web Browser';
      }

      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          final androidInfo = await deviceInfo.androidInfo;
          final manufacturer = androidInfo.manufacturer;
          final model = androidInfo.model;
          return '$manufacturer $model';
        case TargetPlatform.iOS:
          final iosInfo = await deviceInfo.iosInfo;
          return iosInfo.name;
        case TargetPlatform.macOS:
          final macInfo = await deviceInfo.macOsInfo;
          return macInfo.computerName;
        case TargetPlatform.windows:
          final windowsInfo = await deviceInfo.windowsInfo;
          return windowsInfo.computerName;
        case TargetPlatform.linux:
          final linuxInfo = await deviceInfo.linuxInfo;
          return linuxInfo.prettyName;
        case TargetPlatform.fuchsia:
          return 'Fuchsia Device';
      }
    } catch (_) {
      return _getDeviceOs();
    }
  }

  static String _getDeviceOs() {
    if (kIsWeb) {
      return 'web';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.linux:
        return 'linux';
      case TargetPlatform.fuchsia:
        return 'fuchsia';
    }
  }
}
