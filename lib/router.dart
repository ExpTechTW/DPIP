import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:talker_flutter/talker_flutter.dart';

import 'package:dpip/app/changelog/page.dart';
import 'package:dpip/app/debug/logs/page.dart';
import 'package:dpip/app/home/page.dart';
import 'package:dpip/app/layout.dart';
import 'package:dpip/app/map/_lib/utils.dart';
import 'package:dpip/app/map/page.dart';
import 'package:dpip/app/settings/donate/page.dart';
import 'package:dpip/app/settings/layout.dart';
import 'package:dpip/app/settings/locale/page.dart';
import 'package:dpip/app/settings/locale/select/page.dart';
import 'package:dpip/app/settings/location/page.dart';
import 'package:dpip/app/settings/location/select/%5Bcity%5D/page.dart';
import 'package:dpip/app/settings/location/select/page.dart';
import 'package:dpip/app/settings/map/page.dart';
import 'package:dpip/app/settings/notify/(1.eew)/eew/page.dart';
import 'package:dpip/app/settings/notify/(2.earthquake)/intensity/page.dart';
import 'package:dpip/app/settings/notify/(2.earthquake)/monitor/page.dart';
import 'package:dpip/app/settings/notify/(2.earthquake)/report/page.dart';
import 'package:dpip/app/settings/notify/(3.weather)/advisory/page.dart';
import 'package:dpip/app/settings/notify/(3.weather)/evacuation/page.dart';
import 'package:dpip/app/settings/notify/(3.weather)/thunderstorm/page.dart';
import 'package:dpip/app/settings/notify/(4.tsunami)/tsunami/page.dart';
import 'package:dpip/app/settings/notify/(5.basic)/announcement/page.dart';
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
          pageBuilder:
              (context, state) => ForwardBackTransitionPage(key: state.pageKey, child: const WelcomeAboutPage()),
        ),
        GoRoute(
          path: WelcomeExpTechPage.route,
          pageBuilder:
              (context, state) => ForwardBackTransitionPage(key: state.pageKey, child: const WelcomeExpTechPage()),
        ),
        GoRoute(
          path: WelcomeNoticePage.route,
          pageBuilder:
              (context, state) => ForwardBackTransitionPage(key: state.pageKey, child: const WelcomeNoticePage()),
        ),
        GoRoute(
          path: WelcomePermissionPage.route,
          pageBuilder:
              (context, state) => ForwardBackTransitionPage(key: state.pageKey, child: const WelcomePermissionPage()),
        ),
      ],
    ),
    StatefulShellRoute.indexedStack(
      branches: [
        StatefulShellBranch(
          routes: [GoRoute(path: '/home', pageBuilder: (context, state) => const NoTransitionPage(child: HomePage()))],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/history', pageBuilder: (context, state) => const NoTransitionPage(child: HistoryPage())),
          ],
        ),
        StatefulShellBranch(
          routes: [GoRoute(path: '/more', pageBuilder: (context, state) => const NoTransitionPage(child: MorePage()))],
        ),
        StatefulShellBranch(
          routes: [GoRoute(path: '/me', pageBuilder: (context, state) => const NoTransitionPage(child: MePage()))],
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
          SettingsNotifyEewPage.route => context.i18n.notify_eew,
          SettingsNotifyMonitorPage.route => context.i18n.notify_monitor,
          SettingsNotifyReportPage.route => context.i18n.notify_report,
          SettingsNotifyIntensityPage.route => context.i18n.notify_intensity,
          SettingsNotifyThunderstormPage.route => context.i18n.notify_thunderstorm,
          SettingsNotifyAdvisoryPage.route => context.i18n.notify_advisory,
          SettingsNotifyEvacuationPage.route => context.i18n.notify_evacuation,
          SettingsNotifyTsunamiPage.route => context.i18n.notify_tsunami,
          SettingsNotifyAnnouncementPage.route => context.i18n.announcement,

          SettingsDonatePage.route => context.i18n.donate,
          _ => context.i18n.settings,
        };
        return SettingsLayout(title: title, child: child);
      },
      routes: [
        GoRoute(
          path: SettingsIndexPage.route,
          pageBuilder:
              (context, state) => ForwardBackTransitionPage(key: state.pageKey, child: const SettingsIndexPage()),
        ),
        GoRoute(
          path: SettingsLocationPage.route,
          pageBuilder:
              (context, state) => ForwardBackTransitionPage(key: state.pageKey, child: const SettingsLocationPage()),
        ),
        GoRoute(
          path: SettingsLocationSelectPage.route,
          pageBuilder:
              (context, state) =>
                  ForwardBackTransitionPage(key: state.pageKey, child: const SettingsLocationSelectPage()),
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
          pageBuilder:
              (context, state) => ForwardBackTransitionPage(key: state.pageKey, child: const SettingsThemePage()),
        ),
        GoRoute(
          path: SettingsThemeSelectPage.route,
          pageBuilder:
              (context, state) => ForwardBackTransitionPage(key: state.pageKey, child: const SettingsThemeSelectPage()),
        ),
        GoRoute(
          path: SettingsLocalePage.route,
          pageBuilder:
              (context, state) => ForwardBackTransitionPage(key: state.pageKey, child: const SettingsLocalePage()),
        ),
        GoRoute(
          path: SettingsLocaleSelectPage.route,
          pageBuilder:
              (context, state) =>
                  ForwardBackTransitionPage(key: state.pageKey, child: const SettingsLocaleSelectPage()),
        ),
        GoRoute(
          path: SettingsUnitPage.route,
          pageBuilder:
              (context, state) => ForwardBackTransitionPage(key: state.pageKey, child: const SettingsUnitPage()),
        ),
        GoRoute(
          path: SettingsMapPage.route,
          pageBuilder:
              (context, state) => ForwardBackTransitionPage(key: state.pageKey, child: const SettingsMapPage()),
        ),
        GoRoute(
          path: SettingsNotifyPage.route,
          pageBuilder:
              (context, state) => ForwardBackTransitionPage(key: state.pageKey, child: const SettingsNotifyPage()),
          routes: [
            GoRoute(
              path: SettingsNotifyEewPage.name,
              pageBuilder:
                  (context, state) =>
                      ForwardBackTransitionPage(key: state.pageKey, child: const SettingsNotifyEewPage()),
            ),
            GoRoute(
              path: SettingsNotifyMonitorPage.name,
              pageBuilder:
                  (context, state) =>
                      ForwardBackTransitionPage(key: state.pageKey, child: const SettingsNotifyMonitorPage()),
            ),
            GoRoute(
              path: SettingsNotifyReportPage.name,
              pageBuilder:
                  (context, state) =>
                      ForwardBackTransitionPage(key: state.pageKey, child: const SettingsNotifyReportPage()),
            ),
            GoRoute(
              path: SettingsNotifyIntensityPage.name,
              pageBuilder:
                  (context, state) =>
                      ForwardBackTransitionPage(key: state.pageKey, child: const SettingsNotifyIntensityPage()),
            ),
            GoRoute(
              path: SettingsNotifyThunderstormPage.name,
              pageBuilder:
                  (context, state) =>
                      ForwardBackTransitionPage(key: state.pageKey, child: const SettingsNotifyThunderstormPage()),
            ),
            GoRoute(
              path: SettingsNotifyAdvisoryPage.name,
              pageBuilder:
                  (context, state) =>
                      ForwardBackTransitionPage(key: state.pageKey, child: const SettingsNotifyAdvisoryPage()),
            ),
            GoRoute(
              path: SettingsNotifyEvacuationPage.name,
              pageBuilder:
                  (context, state) =>
                      ForwardBackTransitionPage(key: state.pageKey, child: const SettingsNotifyEvacuationPage()),
            ),
            GoRoute(
              path: SettingsNotifyTsunamiPage.name,
              pageBuilder:
                  (context, state) =>
                      ForwardBackTransitionPage(key: state.pageKey, child: const SettingsNotifyTsunamiPage()),
            ),
            GoRoute(
              path: SettingsNotifyAnnouncementPage.name,
              pageBuilder:
                  (context, state) =>
                      ForwardBackTransitionPage(key: state.pageKey, child: const SettingsNotifyAnnouncementPage()),
            ),
          ],
        ),
        GoRoute(
          path: SettingsDonatePage.route,
          pageBuilder:
              (context, state) => ForwardBackTransitionPage(key: state.pageKey, child: const SettingsDonatePage()),
        ),
      ],
    ),
    GoRoute(
      path: MapPage.route(),
      builder: (context, state) {
        final layerString = state.uri.queryParameters['layer'];
        final initialLayer = layerString != null ? MapLayer.values.byName(layerString) : null;

        return MapPage(initialLayer: initialLayer);
      },
    ),
    GoRoute(path: '/announcement', builder: (context, state) => const AnnouncementPage()),
    GoRoute(path: ChangelogPage.route, builder: (context, state) => const ChangelogPage()),
    GoRoute(path: '/license', builder: (context, state) => const LicensePage()),
    GoRoute(path: AppDebugLogsPage.route, builder: (context, state) => const AppDebugLogsPage()),
    // GoRoute(path: MapMonitorPage.route, builder: (context, state) => const MapMonitorPage()),
  ],
  observers: [TalkerRouteObserver(TalkerManager.instance)],
  debugLogDiagnostics: true,
);
