import 'package:dpip/app/debug/logs/page.dart';
import 'package:dpip/app/layout.dart';
import 'package:dpip/app/settings/locale/page.dart';
import 'package:dpip/app/settings/layout.dart';
import 'package:dpip/app/settings/locale/select/page.dart';
import 'package:dpip/app/settings/location/page.dart';
import 'package:dpip/app/settings/location/select/%5Bcity%5D/page.dart';
import 'package:dpip/app/settings/location/select/page.dart';
import 'package:dpip/app/settings/notify/page.dart';
import 'package:dpip/app/settings/page.dart';
import 'package:dpip/app/settings/theme/page.dart';
import 'package:dpip/app/settings/theme/select/page.dart';
import 'package:dpip/app/welcome/1-about/page.dart';
import 'package:dpip/app/welcome/2-exptech/page.dart';
import 'package:dpip/app/welcome/3-notice/page.dart';
import 'package:dpip/app/welcome/4-permissions/page.dart';
import 'package:dpip/app/welcome/layout.dart';
import 'package:dpip/app_old/page/history/history.dart';
import 'package:dpip/app_old/page/home/home.dart';
import 'package:dpip/app_old/page/map/map.dart';
import 'package:dpip/app_old/page/me/me.dart';
import 'package:dpip/app_old/page/more/more.dart';
import 'package:dpip/route/announcement/announcement.dart';
import 'package:dpip/route/changelog/changelog.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/utils/log.dart';
import 'package:dpip/widgets/transitions/forward_back.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dpip/core/preference.dart';
import 'package:talker_flutter/talker_flutter.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _welcomeNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _settingsNavigatorKey = GlobalKey<NavigatorState>();

final router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: Preference.isFirstLaunch ? '/welcome' : '/home',
  routes: [
    ShellRoute(
      navigatorKey: _welcomeNavigatorKey,
      builder: (context, state, child) => WelcomeLayout(child: child),
      routes: [
        GoRoute(
          path: '/welcome',
          pageBuilder: (context, state) => ForwardBackTransitionPage(key: state.pageKey, child: WelcomeAboutPage()),
        ),
        GoRoute(
          path: '/welcome/exptech',
          pageBuilder: (context, state) => ForwardBackTransitionPage(key: state.pageKey, child: WelcomeExpTechPage()),
        ),
        GoRoute(
          path: '/welcome/notice',
          pageBuilder: (context, state) => ForwardBackTransitionPage(key: state.pageKey, child: WelcomeNoticePage()),
        ),
        GoRoute(
          path: '/welcome/permissions',
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
          '/settings/location' => context.i18n.settings_location,
          '/settings/location/select' => context.i18n.settings_location,
          '/settings/location/select/:city' => context.i18n.settings_location,
          '/settings/theme' => context.i18n.settings_theme,
          '/settings/theme/select' => context.i18n.settings_theme,
          '/settings/locale' => context.i18n.settings_locale,
          '/settings/locale/select' => context.i18n.settings_locale,
          '/settings/notify' => '通知',
          _ => context.i18n.settings,
        };
        return SettingsLayout(title: title, child: child);
      },
      routes: [
        GoRoute(
          path: '/settings',
          pageBuilder: (context, state) => ForwardBackTransitionPage(key: state.pageKey, child: SettingsIndexPage()),
        ),
        GoRoute(
          path: '/settings/location',
          pageBuilder: (context, state) => ForwardBackTransitionPage(key: state.pageKey, child: SettingsLocationPage()),
          routes: [
            GoRoute(
              path: 'select',
              pageBuilder:
                  (context, state) =>
                      ForwardBackTransitionPage(key: state.pageKey, child: SettingsLocationSelectPage()),
              routes: [
                GoRoute(
                  path: ':city',
                  pageBuilder:
                      (context, state) => ForwardBackTransitionPage(
                        key: state.pageKey,
                        child: SettingsLocationSelectCityPage(city: state.pathParameters['city']!),
                      ),
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: '/settings/theme',
          pageBuilder: (context, state) => ForwardBackTransitionPage(key: state.pageKey, child: SettingsThemePage()),
          routes: [
            GoRoute(
              path: 'select',
              pageBuilder:
                  (context, state) => ForwardBackTransitionPage(key: state.pageKey, child: SettingsThemeSelectPage()),
            ),
          ],
        ),
        GoRoute(
          path: '/settings/locale',
          pageBuilder: (context, state) => ForwardBackTransitionPage(key: state.pageKey, child: SettingsLocalePage()),
          routes: [
            GoRoute(
              path: 'select',
              pageBuilder:
                  (context, state) => ForwardBackTransitionPage(key: state.pageKey, child: SettingsLocaleSelectPage()),
            ),
          ],
        ),
        GoRoute(
          path: '/settings/notify',
          pageBuilder: (context, state) => ForwardBackTransitionPage(key: state.pageKey, child: SettingsNotifyPage()),
        ),
      ],
    ),
    GoRoute(path: '/announcement', builder: (context, state) => AnnouncementPage()),
    GoRoute(path: '/changelog', builder: (context, state) => ChangelogPage()),
    GoRoute(path: '/license', builder: (context, state) => LicensePage()),
    if (kDebugMode) GoRoute(path: '/debug/logs', builder: (context, state) => AppDebugLogsPage()),
  ],
  observers: [TalkerRouteObserver(TalkerManager.instance)],
  debugLogDiagnostics: true,
);
