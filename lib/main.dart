import "package:dpip/app/dpip.dart";
import "package:dpip/dialog/welcome/announcement.dart";
import "package:dpip/dialog/welcome/changelog.dart";
import "package:dpip/global.dart";
import "package:dpip/route/welcome/welcome.dart";
import "package:dpip/util/extension/string.dart";
import "package:dynamic_color/dynamic_color.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:flutter_localizations/flutter_localizations.dart";
import "package:flutter_localized_locales/flutter_localized_locales.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:timezone/data/latest.dart";

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
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  const DpipApp({super.key});

  @override
  State<DpipApp> createState() => DpipAppState();

  static DpipAppState? of(BuildContext context) => context.findAncestorStateOfType<DpipAppState>();
}

class DpipAppState extends State<DpipApp> {
  ThemeMode _themeMode = {
        "light": ThemeMode.light,
        "dark": ThemeMode.dark,
        "system": ThemeMode.system,
      }[Global.preference.getString("theme")] ??
      ThemeMode.system;
  Locale? _locale = Global.preference.getString("locale")?.asLocale;
  bool showWelcomeScreen = false;

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

  void changeLocale(Locale? locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  void initState() {
    super.initState();
    if (Global.preference.getBool("welcome-1.0.0") == null) {
      Global.preference.setString("changelog", Global.packageInfo.version);

      showWelcomeScreen = true;
    } else {
      if (Global.preference.getString("changelog") != Global.packageInfo.version) {
        showDialog(context: context, builder: (context) => const WelcomeChangelogDialog());
      } else {
        showDialog(context: context, builder: (context) => const WelcomeAnnouncementDialog());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (lightColorScheme, darkColorScheme) {
        final lightTheme = lightColorScheme != null ? ColorScheme.fromSeed(seedColor: lightColorScheme.primary) : null;
        final darkTheme = darkColorScheme != null
            ? ColorScheme.fromSeed(brightness: Brightness.dark, seedColor: darkColorScheme.primary)
            : null;

        return MaterialApp(
          navigatorKey: DpipApp.navigatorKey,
          builder: (context, child) {
            final mediaQueryData = MediaQuery.of(context);
            final scale = mediaQueryData.textScaler.clamp(minScaleFactor: 0.5, maxScaleFactor: 1.3);
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: scale),
              child: child!,
            );
          },
          title: "DPIP",
          theme: ThemeData(
            colorScheme: lightTheme,
            brightness: Brightness.light,
          ),
          darkTheme: ThemeData(
            colorScheme: darkTheme,
            brightness: Brightness.dark,
          ),
          themeMode: _themeMode,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            LocaleNamesLocalizationsDelegate(),
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: _locale,
          home: showWelcomeScreen ? const WelcomeRoute() : const Dpip(),
        );
      },
    );
  }
}
