import "dart:async";
import "dart:io";
import "dart:ui";

import "package:awesome_notifications/awesome_notifications.dart";
import "package:dpip/api/exptech.dart";
import "package:dpip/app/page/home/home.dart";
import "package:dpip/app/page/map/monitor/monitor.dart";
import "package:dpip/app/page/map/radar/radar.dart";
import "package:dpip/core/location.dart";
import "package:dpip/global.dart";
import "package:dpip/route/settings/content/location.dart";
import "package:dpip/util/location_to_code.dart";
import "package:dpip/util/log.dart";
import "package:flutter/cupertino.dart";
import "package:flutter_background_service/flutter_background_service.dart";
import "package:intl/intl.dart";
import "package:permission_handler/permission_handler.dart";

Timer? timer;
FlutterBackgroundService service = FlutterBackgroundService();
bool androidServiceInit = false;

void initBackgroundService() async {
  bool isAutoLocatingEnabled = Global.preference.getBool("auto-location") ?? false;
  if (isAutoLocatingEnabled) {
    final isNotificationEnabled = await Permission.notification.status;
    final isLocationAlwaysEnabled = await Permission.locationAlways.status;
    if (isLocationAlwaysEnabled.isGranted && isNotificationEnabled.isGranted) {
      if (Platform.isAndroid) {
        androidForegroundService();
        androidSendPositionlisten();
        androidStartBackgroundService(true);
      }
    }
  }
}

void androidStartBackgroundService(bool init) async {
  if (!androidServiceInit) {
    androidForegroundService();
    androidSendPositionlisten();
  }
  var isRunning = await service.isRunning();
  if (!isRunning) {
    service.startService();
  } else if (!init) {
    androidstopBackgroundService(false);
    service.startService();
  }
}

void androidstopBackgroundService(bool isAutoLocatingEnabled) async {
  if (await service.isRunning()) {
    if (isAutoLocatingEnabled) {
      service.invoke("removeposition");
    }
    service.invoke("stopService");
  }
}

void androidSendPositionlisten() {
  service.on("sendposition").listen((event) {
    if (event != null) {
      double lat = event.values.first["lat"] ?? 0;
      double lng = event.values.first["lng"] ?? 0;

      GeoJsonProperties? location = GeoJsonHelper.checkPointInPolygons(lat, lng);

      if (location != null) {
        Global.preference.setInt("user-code", location.code);
      } else {
        Global.preference.remove("user-code");
      }

      Global.preference.setDouble("user-lat", lat);
      Global.preference.setDouble("user-lon", lng);
      const MonitorPage(data: 0).createState();
      SettingsLocationView.updatePosition();
      HomePage.updatePosition();
      RadarMap.updatePosition();
      MonitorPage.updatePosition();
    }
  });
  service.on("senddebug").listen((event) {
    if (event != null) {
      var notifyBody = event["notifyBody"];
      TalkerManager.instance.debug("自動定位: $notifyBody");
    }
  });
}

Future<void> androidForegroundService() async {
  androidServiceInit = true;

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
      foregroundServiceTypes: [AndroidForegroundType.location],
      notificationChannelId: "my_foreground",
      initialNotificationTitle: "DPIP",
      initialNotificationContent: "前景服務啟動中...",
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );
}

@pragma("vm:entry-point")
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}

@pragma("vm:entry-point")
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  await Global.init();

  LocationService locationService = LocationService();

  service.on("stopService").listen((event) {
    timer?.cancel();
    if (service is AndroidServiceInstance) {
      service.setAutoStartOnBootMode(false);
    }
    service.stopSelf();
    TalkerManager.instance.warning("background process is now stopped");
  });

  if (service is AndroidServiceInstance) {
    await service.setAsForegroundService();

    AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 0,
        channelKey: "foreground-general",
        title: "DPIP",
        body: "前景服務啟動中...",
        notificationLayout: NotificationLayout.BigText,
      ),
    );

    service.setAutoStartOnBootMode(true);

    service.on("setAsForeground").listen((event) {
      service.setAsForegroundService();
    });

    service.on("setAsBackground").listen((event) {
      service.setAsBackgroundService();
    });

    service.on("removeposition").listen((event) {
      Global.preference.remove("user-lat");
      Global.preference.remove("user-lon");
      Global.preference.remove("user-code");
    });

    void task() async {
      if (await service.isForegroundService()) {
        final position = await locationService.androidGetLocation();
        service.invoke("sendposition", {"position": position.toJson()});
        String lat = position.lat.toString();
        String lon = position.lng.toString();
        String location = position.code == null
            ? "服務區域外"
            : "${Global.location[position.code.toString()]?.city}${Global.location[position.code.toString()]?.town}";
        String? fcmToken = Global.preference.getString("fcm-token");
        if (position.change && fcmToken != null) {
          final body = await ExpTech().getNotifyLocation(fcmToken, lat, lon);
          TalkerManager.instance.debug(body);
        }

        String notifyTitle = "自動定位中";
        String date = DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now());
        String notifyBody = "$date\n$lat,$lon $location";
        service.invoke("senddebug", {"notifyBody": notifyBody});

        AwesomeNotifications().cancel(0);

        AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: 1,
            channelKey: "background-general",
            title: notifyTitle,
            body: notifyBody,
            notificationLayout: NotificationLayout.BigText,
          ),
        );
      }
    }

    task();
    timer = Timer.periodic(const Duration(minutes: 5), (timer) async {
      task();
    });
  }
}
