import 'package:dpip/models/data.dart';
import 'package:dpip/models/settings/location.dart';
import 'package:dpip/models/settings/map.dart';
import 'package:dpip/models/settings/notify.dart';
import 'package:dpip/models/settings/ui.dart';

class GlobalProviders {
  GlobalProviders._();

  static late DpipDataModel data;
  static late SettingsLocationModel location;
  static late SettingsMapModel map;
  static late SettingsNotificationModel notification;
  static late SettingsUserInterfaceModel ui;

  static void init() {
    data = DpipDataModel();
    location = SettingsLocationModel();
    map = SettingsMapModel();
    notification = SettingsNotificationModel();
    ui = SettingsUserInterfaceModel();
  }
}
