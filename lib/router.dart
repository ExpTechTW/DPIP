import 'package:dpip/app/changelog/page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:talker_flutter/talker_flutter.dart';

import 'package:dpip/app/debug/logs/page.dart';
import 'package:dpip/app/home/page.dart';
import 'package:dpip/app/layout.dart';
import 'package:dpip/app/settings/layout.dart';
import 'package:dpip/app/settings/locale/page.dart';
import 'package:dpip/app/settings/locale/select/page.dart';
import 'package:dpip/app/settings/location/page.dart';
import 'package:dpip/app/settings/location/select/%5Bcity%5D/page.dart';
import 'package:dpip/app/settings/location/select/page.dart';
import 'package:dpip/app/settings/notify/page.dart';
import 'package:dpip/app/settings/page.dart';
import 'package:dpip/app/settings/theme/page.dart';
import 'package:dpip/app/settings/theme/select/page.dart';
import 'package:dpip/app/settings/unit/page.dart';
import 'package:dpip/app/welcome/1-about/page.dart';
import 'package:dpip/app/welcome/2-exptech/page.dart';
import 'package:dpip/app/welcome/3-notice/page.dart';
import 'package:dpip/app/welcome/4-permissions/page.dart';
import 'package:dpip/app/welcome/layout.dart';
import 'package:dpip/app_old/page/history/history.dart';
import 'package:dpip/app_old/page/map/map.dart';
import 'package:dpip/app_old/page/me/me.dart';
import 'package:dpip/app_old/page/more/more.dart';
import 'package:dpip/core/preference.dart';
import 'package:dpip/route/announcement/announcement.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/utils/log.dart';
import 'package:dpip/widgets/transitions/forward_back.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _welcomeNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _settingsNavigatorKey = GlobalKey<NavigatorState>();

final router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: Preference.isFirstLaunch ? WelcomeAboutPage.route : HomePage.route,
  routes: [
    ShellRoute(
      navigatorKey: _welcomeNavigatorKey,
      builder: (context, state, child) => WelcomeLayout(child: child),
      routes: [
        GoRoute(
          path: WelcomeAboutPage.route,
          pageBuilder: (context, state) => ForwardBackTransitionPage(key: state.pageKey, child: WelcomeAboutPage()),
        ),
        GoRoute(
          path: WelcomeExpTechPage.route,
          pageBuilder: (context, state) => ForwardBackTransitionPage(key: state.pageKey, child: WelcomeExpTechPage()),
        ),
        GoRoute(
          path: WelcomeNoticePage.route,
          pageBuilder: (context, state) => ForwardBackTransitionPage(key: state.pageKey, child: WelcomeNoticePage()),
        ),
        GoRoute(
          path: WelcomePermissionPage.route,
          pageBuilder:
              (context, state) => ForwardBackTransitionPage(key: state.pageKey, child: WelcomePermissionPage()),
        ),
      ],
    ),
    StatefulShellRoute.indexedStack(
      branches: [
        StatefulShellBranch(
          routes: [GoRoute(path: '/home', pageBuilder: (context, state) => NoTransitionPage(child: HomePage()))],
        ),
        StatefulShellBranch(
          routes: [GoRoute(path: '/history', pageBuilder: (context, state) => NoTransitionPage(child: HistoryPage()))],
        ),
        StatefulShellBranch(
          routes: [GoRoute(path: '/map', pageBuilder: (context, state) => NoTransitionPage(child: MapPage()))],
        ),
        StatefulShellBranch(
          routes: [GoRoute(path: '/more', pageBuilder: (context, state) => NoTransitionPage(child: MorePage()))],
        ),
        StatefulShellBranch(
          routes: [GoRoute(path: '/me', pageBuilder: (context, state) => NoTransitionPage(child: MePage()))],
        ),
      ],

      builder: (context, state, navigationShell) {
        return AppLayout(location: state.matchedLocation, navigationShell: navigationShell);
      },
    ),
    ShellRoute(
      navigatorKey: _settingsNavigatorKey,
      builder: (context, state, child) {
        final title = switch (state.fullPath) {
          SettingsLocationPage.route => context.i18n.settings_location,
          SettingsLocationSelectPage.route => context.i18n.settings_location,
          final p when p == SettingsLocationSelectCityPage.route() => context.i18n.settings_location,
          SettingsThemePage.route => context.i18n.settings_theme,
          SettingsThemeSelectPage.route => context.i18n.settings_theme,
          SettingsLocalePage.route => context.i18n.settings_locale,
          SettingsLocaleSelectPage.route => context.i18n.settings_locale,
          SettingsUnitPage.route => '單位',
          SettingsNotifyPage.route => '通知',
          _ => context.i18n.settings,
        };
        return SettingsLayout(title: title, child: child);
      },
      routes: [
        GoRoute(
          path: SettingsIndexPage.route,
          pageBuilder: (context, state) => ForwardBackTransitionPage(key: state.pageKey, child: SettingsIndexPage()),
        ),
        GoRoute(
          path: SettingsLocationPage.route,
          pageBuilder: (context, state) => ForwardBackTransitionPage(key: state.pageKey, child: SettingsLocationPage()),
        ),
        GoRoute(
          path: SettingsLocationSelectPage.route,
          pageBuilder:
              (context, state) => ForwardBackTransitionPage(key: state.pageKey, child: SettingsLocationSelectPage()),
        ),
        GoRoute(
          path: SettingsLocationSelectCityPage.route(),
          pageBuilder:
              (context, state) => ForwardBackTransitionPage(
                key: state.pageKey,
                child: SettingsLocationSelectCityPage(city: state.pathParameters['city']!),
              ),
        ),
        GoRoute(
          path: SettingsThemePage.route,
          pageBuilder: (context, state) => ForwardBackTransitionPage(key: state.pageKey, child: SettingsThemePage()),
        ),
        GoRoute(
          path: SettingsThemeSelectPage.route,
          pageBuilder:
              (context, state) => ForwardBackTransitionPage(key: state.pageKey, child: SettingsThemeSelectPage()),
        ),
        GoRoute(
          path: SettingsLocalePage.route,
          pageBuilder: (context, state) => ForwardBackTransitionPage(key: state.pageKey, child: SettingsLocalePage()),
        ),
        GoRoute(
          path: SettingsLocaleSelectPage.route,
          pageBuilder:
              (context, state) => ForwardBackTransitionPage(key: state.pageKey, child: SettingsLocaleSelectPage()),
        ),
        GoRoute(
          path: SettingsUnitPage.route,
          pageBuilder: (context, state) => ForwardBackTransitionPage(key: state.pageKey, child: SettingsUnitPage()),
        ),
        GoRoute(
          path: SettingsNotifyPage.route,
          pageBuilder: (context, state) => ForwardBackTransitionPage(key: state.pageKey, child: SettingsNotifyPage()),
        ),
      ],
    ),
    GoRoute(path: '/announcement', builder: (context, state) => AnnouncementPage()),
    GoRoute(path: ChangelogPage.route, builder: (context, state) => ChangelogPage()),
    GoRoute(path: '/license', builder: (context, state) => LicensePage()),
    if (kDebugMode) GoRoute(path: AppDebugLogsPage.route, builder: (context, state) => AppDebugLogsPage()),
  ],
  observers: [TalkerRouteObserver(TalkerManager.instance)],
  debugLogDiagnostics: true,
);
