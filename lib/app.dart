import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import 'package:dynamic_system_colors/dynamic_system_colors.dart';
import 'package:i18n_extension/i18n_extension.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:provider/provider.dart';

import 'package:dpip/core/providers.dart';
import 'package:dpip/models/settings/ui.dart';
import 'package:dpip/router.dart';
import 'package:dpip/utils/log.dart';

class DpipApp extends StatefulWidget {
  const DpipApp({super.key});

  @override
  State<DpipApp> createState() => _DpipAppState();
}

class _DpipAppState extends State<DpipApp> with WidgetsBindingObserver {
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
    GlobalProviders.data.onAppLifecycleStateChanged(state);
  }

  @override
  void initState() {
    super.initState();
    _checkUpdate();
    WidgetsBinding.instance.addObserver(this);
    GlobalProviders.data.startFetching();
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
              localizationsDelegates: I18n.localizationsDelegates,
              supportedLocales: I18n.supportedLocales,
              locale: I18n.locale,
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
    super.dispose();
  }
}
