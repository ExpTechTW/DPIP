import 'package:dpip/core/api.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Global {
  static late ExpTechApi api;
  static late SharedPreferences preference;
  static late PackageInfo packageInfo;

  static Future init() async {
    api = ExpTechApi();
    preference = await SharedPreferences.getInstance();
    packageInfo = await PackageInfo.fromPlatform();
  }
}
