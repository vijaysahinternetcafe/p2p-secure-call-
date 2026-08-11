import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<bool> requestAllPermissions() async {
    final permissions = [
      Permission.camera,
      Permission.microphone,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.notification,
    ];

    if (await Permission.systemAlertWindow.isDenied) {
      await Permission.systemAlertWindow.request();
    }

    final statuses = await permissions.request();
    final allGranted = statuses.values.every((status) =>
      status.isGranted || status.isLimited
    );
    return allGranted;
  }
}
