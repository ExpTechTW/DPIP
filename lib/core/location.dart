import 'package:permission_handler/permission_handler.dart';

Future<bool> requestLocationAlwaysPermission() async {
  PermissionStatus status = await Permission.location.request();

  if (status.isGranted) {
    print('位置權限已授予');

    status = await Permission.locationAlways.request();
    if (status.isGranted) {
      print('背景位置權限已授予');
      return true;
    }
  } else if (status.isDenied) {
    print('位置權限被拒絕');

    status = await Permission.locationAlways.request();
    if (status.isGranted) {
      print('背景位置權限已授予');
      return true;
    }
  } else if (status.isPermanentlyDenied) {
    status = await Permission.locationAlways.request();
    if (status.isGranted) {
      print('背景位置權限已授予');
      return true;
    } else if (status.isPermanentlyDenied) {
      print('位置權限被永久拒絕');
      await openAppSettings();
    }
  }

  return false;
}