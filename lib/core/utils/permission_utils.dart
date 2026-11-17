import 'package:permission_handler/permission_handler.dart';

/// Utility for requesting and checking runtime permissions.
class PermissionUtils {
  static Future<bool> requestLocationPermission() async {
    final status = await Permission.locationWhenInUse.status;
    if (status.isGranted) return true;

    final result = await Permission.locationWhenInUse.request();
    if (result.isGranted) return true;

    if (result.isPermanentlyDenied) {
      await openAppSettings();
    }

    return false;
  }

  static Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.status;
    if (status.isGranted) return true;

    final result = await Permission.camera.request();
    if (result.isGranted) return true;

    if (result.isPermanentlyDenied) {
      await openAppSettings();
    }

    return false;
  }
}
