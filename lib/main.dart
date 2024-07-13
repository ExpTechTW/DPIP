import 'package:dpip/api/exptech.dart';
import 'package:dpip/app/dpip.dart';
import 'package:dpip/core/fcm.dart';
import 'package:dpip/core/location.dart';
import 'package:dpip/core/notify.dart';
import 'package:dpip/core/service.dart';
import 'package:dpip/global.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await fcmInit();
  await notifyInit();
  await Global.init();
  String thisVersion = Global.preference.getString("this-version") ?? "";
  print('初始: $thisVersion');
  if (thisVersion == "") {
    thisVersion = Global.packageInfo.version;
    Global.preference.setString("this-version", thisVersion);
    print('更新: $thisVersion');
  }
  messaging.getToken().then((value) async {
    print('初始: $value');
    if (value == null) return;
    String fcmToken = Global.preference.getString("fcm-token") ?? "";
    print('提取: $fcmToken');
    if (fcmToken != "" && thisVersion != Global.packageInfo.version) {
      thisVersion = Global.packageInfo.version;
      Global.preference.setString("this-version", thisVersion);
      print('版本更新: $thisVersion');
      final position = await getLocation();
      String lat = position.position.latitude.toStringAsFixed(4);
      String lon = position.position.longitude.toStringAsFixed(4);
      final body = await ExpTech().getNotifyLocation(fcmToken, lat, lon);
      print(body);
    } else if (fcmToken == "") {
      Global.preference.setString("fcm-token", value);
      print('更新: $value');
    }
  });
  bool isAutoLocatingEnabled = Global.preference.getBool("auto-location") ?? false;
  if (isAutoLocatingEnabled) {
    final isNotificationEnabled = await Permission.notification.status;
    final isLocationAlwaysEnabled = await Permission.locationAlways.status;
    if (isLocationAlwaysEnabled.isGranted && isNotificationEnabled.isGranted) {
      await startBackgroundService();
    } else {
      await stopBackgroundService();
    }
  }
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
