import 'package:dpip/models/settings/location.dart';
import 'package:dpip/models/settings/notify.dart';
import 'package:dpip/models/settings/ui.dart';

class GlobalProviders {
  GlobalProviders._();

  static late SettingsLocationModel location;
  static late SettingsNotificationModel notification;
  static late SettingsUserInterfaceModel ui;

  static void init() {
    location = SettingsLocationModel();
    notification = SettingsNotificationModel();
    ui = SettingsUserInterfaceModel();
  }
}
