import "package:dpip/core/preference.dart";
import "package:dpip/global.dart";
import 'package:dpip/l10n/app_localizations.dart';
import "package:dpip/models/settings/location.dart";
import "package:dpip/models/settings/notify.dart";
import "package:dpip/models/settings/ui.dart";
import "package:dpip/router.dart";
import "package:dpip/utils/log.dart";
import "package:dynamic_system_colors/dynamic_system_colors.dart";
import "package:flutter/material.dart";
import "package:flutter_localizations/flutter_localizations.dart";
import "package:flutter_localized_locales/flutter_localized_locales.dart";
import "package:provider/provider.dart";
import "package:timezone/data/latest.dart";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final talker = TalkerManager.instance;
  talker.log("start");
  FlutterError.onError = (details) => talker.handle(details.exception, details.stack);
  await Global.init();
  await Preference.init();

  TalkerManager.instance.info('global init');
  initializeTimeZones();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => SettingsLocationModel()),
        ChangeNotifierProvider(create: (context) => SettingsNotificationModel()),
        ChangeNotifierProvider(create: (context) => SettingsUserInterfaceModel()),
      ],
      child: const DpipApp(),
    ),
  );
}

class DpipApp extends StatelessWidget {
  const DpipApp({super.key});

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        return Consumer<SettingsUserInterfaceModel>(
          builder: (context, model, child) {
            final lightTheme = ThemeData(
              colorSchemeSeed: model.themeColor,
              colorScheme: model.themeColor == null ? lightDynamic : null,
              brightness: Brightness.light,
            );
            final darkTheme = ThemeData(
              colorSchemeSeed: model.themeColor,
              colorScheme: model.themeColor == null ? darkDynamic : null,
              brightness: Brightness.dark,
            );

            return MaterialApp.router(
              builder: (context, child) {
                final mediaQueryData = MediaQuery.of(context);
                final scale = mediaQueryData.textScaler.clamp(minScaleFactor: 0.5, maxScaleFactor: 1.2);
                return MediaQuery(data: MediaQuery.of(context).copyWith(textScaler: scale), child: child!);
              },
              title: "DPIP",
              theme: lightTheme,
              darkTheme: darkTheme,
              themeMode: model.themeMode,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                LocaleNamesLocalizationsDelegate(),
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              locale: model.locale,
              routerConfig: router,
            );
          },
        );
      },
    );
  }
}
