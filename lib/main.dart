import 'dart:async';
import 'dart:io';

import 'package:dpip/app/dpip.dart';
import 'package:dpip/core/fcm.dart';
import 'package:dpip/core/notify.dart';
import 'package:dpip/core/service.dart';
import 'package:dpip/global.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart';

import 'api/exptech.dart';
import 'core/location.dart';

LocationService locationService = LocationService();
StreamSubscription<Position>? positionStreamSubscription;
Timer? restartTimer;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Global.init();
  initializeTimeZones();
  runApp(
    const ProviderScope(
      child: DpipApp(),
    ),
  );
}

class DpipApp extends StatefulWidget {
  const DpipApp({super.key});

  @override
  State<DpipApp> createState() => DpipAppState();

  static DpipAppState? of(BuildContext context) => context.findAncestorStateOfType<DpipAppState>();
}

class DpipAppState extends State<DpipApp> {
  ThemeMode _themeMode = {
        "light": ThemeMode.light,
        "dark": ThemeMode.dark,
        "system": ThemeMode.system
      }[Global.preference.getString('theme')] ??
      ThemeMode.system;

  void changeTheme(String themeMode) {
    setState(() {
      switch (themeMode) {
        case "light":
          _themeMode = ThemeMode.light;
          break;
        case "dark":
          _themeMode = ThemeMode.dark;
          break;
        case "system":
          _themeMode = ThemeMode.system;
          break;
        default:
          break;
      }
    });
  }

  void initBackgroundService() async {
    bool isAutoLocatingEnabled = Global.preference.getBool("auto-location") ?? false;
    if (isAutoLocatingEnabled) {
      final isNotificationEnabled = await Permission.notification.status;
      final isLocationAlwaysEnabled = await Permission.locationAlways.status;
      if (isLocationAlwaysEnabled.isGranted && isNotificationEnabled.isGranted) {
        if (Platform.isAndroid) {
          androidForegroundService();
        }
        startBackgroundService(true);
      }
    }
  }

  void startBackgroundService(bool init) async {
    if (Platform.isIOS) {
      iosStartPositionStream();
    } else if (Platform.isAndroid) {
      if (!androidServiceInit) {
        androidForegroundService();
      }
      var isRunning = await service.isRunning();
      if (!isRunning) {
        service.startService();
      } else if (!init) {
        stopBackgroundService();
        service.startService();
      }
    }
  }

  void stopBackgroundService() async {
    if (Platform.isIOS) {
      iosStopPositionStream();
    } else if (Platform.isAndroid) {
      if (await service.isRunning()) {
        service.invoke("stopService");
      }
    }
  }

  void iosStartPositionStream() async {
    if (positionStreamSubscription != null) return;
    final positionStream = Geolocator.getPositionStream(
      locationSettings: AppleSettings(
        accuracy: LocationAccuracy.medium,
        activityType: ActivityType.other,
        distanceFilter: 250,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: false,
        allowBackgroundLocationUpdates: true,
      ),
    );
    positionStreamSubscription = positionStream.handleError((error) async {
      print('位置流錯誤: $error');
      iosStopPositionStream();
      restartTimer = Timer(const Duration(minutes: 2), iosStartPositionStream);
    }).listen((Position? position) async {
      if (position != null) {
        final positionlattemp = Global.preference.getDouble("loc-position-lat") ?? 0.0;
        final positionlontemp = Global.preference.getDouble("loc-position-lon") ?? 0.0;
        double distance =
            Geolocator.distanceBetween(positionlattemp, positionlontemp, position.latitude, position.longitude);
        if (distance >= 250) {
          Global.preference.setDouble("loc-position-lat", position.latitude);
          Global.preference.setDouble("loc-position-lon", position.longitude);
          LocationResult locationResult =
              await locationService.getLatLngLocation(position.latitude, position.longitude);
          print('新位置: ${position}');
          print('城市和鄉鎮: ${locationResult.cityTown}');

          String lat = position.latitude.toStringAsFixed(4);
          String lon = position.longitude.toStringAsFixed(4);
          String? fcmToken = Global.preference.getString("fcm-token");
          if (fcmToken != null) {
            final body = await ExpTech().getNotifyLocation(fcmToken, lat, lon);
            print(body);
          }
          print('距離: $distance 更新位置');
        } else {
          print('距離: $distance 不更新位置');
        }
      }
      iosStopPositionStream();
      restartTimer = Timer(const Duration(minutes: 2), iosStartPositionStream);
    });
    print('位置流已開啟');
  }

  void iosStopPositionStream() {
    positionStreamSubscription?.cancel();
    positionStreamSubscription = null;
    print('位置流已停止');
    restartTimer?.cancel();
  }

  @override
  void initState() {
    super.initState();
    fcmInit();
    notifyInit();
    initBackgroundService();
  }

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (lightColorScheme, darkColorScheme) => MaterialApp(
        builder: (context, child) {
          final mediaQueryData = MediaQuery.of(context);
          final scale = mediaQueryData.textScaler.clamp(minScaleFactor: 0, maxScaleFactor: 1.5);
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: scale),
            child: child!,
          );
        },
        title: "DPIP",
        theme: ThemeData(
          colorScheme: lightColorScheme,
          brightness: Brightness.light,
        ),
        darkTheme: ThemeData(
          colorScheme: darkColorScheme,
          brightness: Brightness.dark,
        ),
        themeMode: _themeMode,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Dpip(),
      ),
    );
  }
}

void initBackgroundService() async {
  bool isAutoLocatingEnabled = Global.preference.getBool("auto-location") ?? false;
  if (isAutoLocatingEnabled) {
    final isNotificationEnabled = await Permission.notification.status;
    final isLocationAlwaysEnabled = await Permission.locationAlways.status;
    if (isLocationAlwaysEnabled.isGranted && isNotificationEnabled.isGranted) {
      if (Platform.isAndroid) {
        androidForegroundService();
      }
      startBackgroundService(true);
    }
  }
}

void startBackgroundService(bool init) async {
  if (Platform.isIOS) {
    iosStartPositionStream();
  } else if (Platform.isAndroid) {
    if (!androidServiceInit) {
      androidForegroundService();
    }
    var isRunning = await service.isRunning();
    if (!isRunning) {
      service.startService();
    } else if (!init) {
      stopBackgroundService();
      service.startService();
    }
  }
}

void stopBackgroundService() async {
  if (Platform.isIOS) {
    iosStopPositionStream();
  } else if (Platform.isAndroid) {
    if (await service.isRunning()) {
      service.invoke("stopService");
    }
  }
}

void iosStartPositionStream() async {
  if (positionStreamSubscription != null) return;
  final positionStream = Geolocator.getPositionStream(
    locationSettings: AppleSettings(
      accuracy: LocationAccuracy.medium,
      activityType: ActivityType.other,
      distanceFilter: 250,
      pauseLocationUpdatesAutomatically: false,
      showBackgroundLocationIndicator: false,
      allowBackgroundLocationUpdates: true,
    ),
  );
  positionStreamSubscription = positionStream.handleError((error) async {
    print('位置流錯誤: $error');
    iosStopPositionStream();
    restartTimer = Timer(const Duration(minutes: 2), iosStartPositionStream);
  }).listen((Position? position) async {
    if (position != null) {
      final positionlattemp = Global.preference.getDouble("loc-position-lat") ?? 0.0;
      final positionlontemp = Global.preference.getDouble("loc-position-lon") ?? 0.0;
      double distance =
      Geolocator.distanceBetween(positionlattemp, positionlontemp, position.latitude, position.longitude);
      if (distance >= 250) {
        Global.preference.setDouble("loc-position-lat", position.latitude);
        Global.preference.setDouble("loc-position-lon", position.longitude);
        LocationResult locationResult =
        await locationService.getLatLngLocation(position.latitude, position.longitude);
        print('新位置: ${position}');
        print('城市和鄉鎮: ${locationResult.cityTown}');

        String lat = position.latitude.toStringAsFixed(4);
        String lon = position.longitude.toStringAsFixed(4);
        String? fcmToken = Global.preference.getString("fcm-token");
        if (fcmToken != null) {
          final body = await ExpTech().getNotifyLocation(fcmToken, lat, lon);
          print(body);
        }
        print('距離: $distance 更新位置');
      } else {
        print('距離: $distance 不更新位置');
      }
    }
    iosStopPositionStream();
    restartTimer = Timer(const Duration(minutes: 2), iosStartPositionStream);
  });
  print('位置流已開啟');
}

void iosStopPositionStream() {
  positionStreamSubscription?.cancel();
  positionStreamSubscription = null;
  print('位置流已停止');
  restartTimer?.cancel();
}