import 'package:permission_handler/permission_handler.dart' as permission_handler;

class PermissionsHelper {
  // Request camera permission for QR scanning
  static Future<bool> requestCameraPermission() async {
    final status = await permission_handler.Permission.camera.request();
    return status == permission_handler.PermissionStatus.granted;
  }

  // Check if camera permission is granted
  static Future<bool> isCameraPermissionGranted() async {
    final status = await permission_handler.Permission.camera.status;
    return status == permission_handler.PermissionStatus.granted;
  }

  // Request notification permission
  static Future<bool> requestNotificationPermission() async {
    final status = await permission_handler.Permission.notification.request();
    return status == permission_handler.PermissionStatus.granted;
  }

  // Check if notification permission is granted
  static Future<bool> isNotificationPermissionGranted() async {
    final status = await permission_handler.Permission.notification.status;
    return status == permission_handler.PermissionStatus.granted;
  }

  // Request location permission (for future GPS tracking feature)
  static Future<bool> requestLocationPermission() async {
    final status = await permission_handler.Permission.location.request();
    return status == permission_handler.PermissionStatus.granted;
  }

  // Check if location permission is granted
  static Future<bool> isLocationPermissionGranted() async {
    final status = await permission_handler.Permission.location.status;
    return status == permission_handler.PermissionStatus.granted;
  }

  // Request storage permission (for saving QR codes or reports)
  static Future<bool> requestStoragePermission() async {
    final status = await permission_handler.Permission.storage.request();
    return status == permission_handler.PermissionStatus.granted;
  }

  // Check if storage permission is granted
  static Future<bool> isStoragePermissionGranted() async {
    final status = await permission_handler.Permission.storage.status;
    return status == permission_handler.PermissionStatus.granted;
  }

  // Request all necessary permissions at once
  static Future<Map<permission_handler.Permission, permission_handler.PermissionStatus>> requestAllPermissions() async {
    return await [
      permission_handler.Permission.camera,
      permission_handler.Permission.notification,
      permission_handler.Permission.location,
      permission_handler.Permission.storage,
    ].request();
  }

  // Check if all necessary permissions are granted
  static Future<bool> areAllPermissionsGranted() async {
    final cameraGranted = await isCameraPermissionGranted();
    final notificationGranted = await isNotificationPermissionGranted();
    final locationGranted = await isLocationPermissionGranted();
    final storageGranted = await isStoragePermissionGranted();

    return cameraGranted && notificationGranted && locationGranted && storageGranted;
  }

  // Open app settings if permissions are denied
  static Future<bool> openAppSettings() async {
    return await permission_handler.openAppSettings();
  }

  // Get permission status message in Arabic
  static String getPermissionStatusMessage(permission_handler.PermissionStatus status) {
    switch (status) {
      case permission_handler.PermissionStatus.granted:
        return 'تم منح الإذن';
      case permission_handler.PermissionStatus.denied:
        return 'تم رفض الإذن';
      case permission_handler.PermissionStatus.restricted:
        return 'الإذن مقيد';
      case permission_handler.PermissionStatus.limited:
        return 'الإذن محدود';
      case permission_handler.PermissionStatus.permanentlyDenied:
        return 'تم رفض الإذن نهائياً';
      default:
        return 'حالة الإذن غير معروفة';
    }
  }

  // Get permission name in Arabic
  static String getPermissionName(permission_handler.Permission permission) {
    switch (permission) {
      case permission_handler.Permission.camera:
        return 'الكاميرا';
      case permission_handler.Permission.notification:
        return 'الإشعارات';
      case permission_handler.Permission.location:
        return 'الموقع';
      case permission_handler.Permission.storage:
        return 'التخزين';
      default:
        return 'إذن غير معروف';
    }
  }

  // Show permission rationale dialog
  static Future<bool> showPermissionRationale({
    required String title,
    required String message,
    required Function() onConfirm,
    required Function() onCancel,
  }) async {
    // This would typically show a dialog explaining why the permission is needed
    // For now, we'll just return true to proceed with the permission request
    return true;
  }

  // Handle permission denied scenario
  static Future<void> handlePermissionDenied({
    required permission_handler.Permission permission,
    required Function() onRetry,
    required Function() onCancel,
  }) async {
    final status = await permission.status;

    if (status == permission_handler.PermissionStatus.permanentlyDenied) {
      // Show dialog to open app settings
      await openAppSettings();
    } else {
      // Show dialog to retry permission request
      onRetry();
    }
  }
}
