import 'package:dpip/app/dpip.dart';
import 'package:dpip/core/fcm.dart';
import 'package:dpip/core/notify.dart';
import 'package:dpip/global.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:timezone/data/latest.dart';

import 'core/service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
    ),
  );
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
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
