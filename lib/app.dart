import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import 'package:dynamic_system_colors/dynamic_system_colors.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:provider/provider.dart';

import 'package:dpip/api/exptech.dart';
import 'package:dpip/core/providers.dart';
import 'package:dpip/l10n/app_localizations.dart';
import 'package:dpip/models/settings/ui.dart';
import 'package:dpip/router.dart';
import 'package:dpip/utils/log.dart';

class DpipApp extends StatefulWidget {
  const DpipApp({super.key});

  @override
  State<DpipApp> createState() => _DpipAppState();
}

class _DpipAppState extends State<DpipApp> with WidgetsBindingObserver {
  AppLifecycleState? _lifecycleState;
  late Timer _timer;
  late Timer _timer2;

  Future<void> _checkUpdate() async {
    try {
      if (Platform.isAndroid) {
        final info = await InAppUpdate.checkForUpdate();

        if (info.updateAvailability != UpdateAvailability.updateAvailable) return;

        if (info.immediateUpdateAllowed) {
          InAppUpdate.performImmediateUpdate();
        } else if (info.flexibleUpdateAllowed) {
          final updateResult = await InAppUpdate.startFlexibleUpdate();

          if (updateResult != AppUpdateResult.success) return;

          InAppUpdate.completeFlexibleUpdate();
        }
      }
    } catch (e, s) {
      TalkerManager.instance.error('_DpipState._checkUpdate', e, s);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(() => _lifecycleState = state);
  }

  @override
  void initState() {
    super.initState();
    _checkUpdate();
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (_lifecycleState != AppLifecycleState.resumed) return;

      final eew = await ExpTech().getEew();
      GlobalProviders.data.setEew(eew);
    });
    _timer2 = Timer.periodic(const Duration(minutes: 1), (timer) async {
      if (_lifecycleState != AppLifecycleState.resumed) return;

      final data = await ExpTech().getNtp();
      GlobalProviders.data.setTimeOffset(DateTime.now().millisecondsSinceEpoch - data);
    });
  }

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
              snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
            );
            final darkTheme = ThemeData(
              colorSchemeSeed: model.themeColor,
              colorScheme: model.themeColor == null ? darkDynamic : null,
              brightness: Brightness.dark,
              snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
            );

            return MaterialApp.router(
              builder: (context, child) {
                final mediaQueryData = MediaQuery.of(context);
                final scale = mediaQueryData.textScaler.clamp(minScaleFactor: 0.5, maxScaleFactor: 1.2);
                return MediaQuery(data: MediaQuery.of(context).copyWith(textScaler: scale), child: child!);
              },
              title: 'DPIP',
              theme: lightTheme,
              darkTheme: darkTheme,
              themeMode: model.themeMode,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
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

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer.cancel();
    _timer2.cancel();
    super.dispose();
  }
}
