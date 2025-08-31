import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:talker_flutter/talker_flutter.dart';

import 'package:dpip/app/changelog/page.dart';
import 'package:dpip/app/debug/logs/page.dart';
import 'package:dpip/app/home/page.dart';
import 'package:dpip/app/layout.dart';
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
import 'package:dpip/core/i18n.dart';
import 'package:dpip/core/preference.dart';
import 'package:dpip/route/announcement/announcement.dart';
import 'package:dpip/utils/constants.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/utils/log.dart';
import 'package:dpip/widgets/shell_wrapper.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _welcomeNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _settingsNavigatorKey = GlobalKey<NavigatorState>();

final router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: Preference.isFirstLaunch ? WelcomeAboutPage.route : HomePage.route,
  routes: [
    ShellRoute(
      navigatorKey: _welcomeNavigatorKey,
      builder: (context, state, child) => ShellWrapper(WelcomeLayout(child: child)),
      routes: [
        GoRoute(path: WelcomeAboutPage.route, builder: (context, state) => const Material(child: WelcomeAboutPage())),
        GoRoute(
          path: WelcomeExpTechPage.route,
          builder: (context, state) => const Material(child: WelcomeExpTechPage()),
        ),
        GoRoute(path: WelcomeNoticePage.route, builder: (context, state) => const Material(child: WelcomeNoticePage())),
        GoRoute(
          path: WelcomePermissionPage.route,
          builder: (context, state) => const Material(child: WelcomePermissionPage()),
        ),
      ],
    ),
    GoRoute(path: HomePage.route, builder: (context, state) => const AppLayout(child: HomePage())),
    ShellRoute(
      navigatorKey: _settingsNavigatorKey,
      builder: (context, state, child) {
        final title = switch (state.fullPath) {
          SettingsLocationPage.route => '所在地'.i18n,
          SettingsLocationSelectPage.route => '新增地點'.i18n,
          final p when p == SettingsLocationSelectCityPage.route() => '新增地點'.i18n,
          SettingsThemePage.route => '主題'.i18n,
          SettingsThemeSelectPage.route => '主題'.i18n,
          SettingsLocalePage.route => '語言'.i18n,
          SettingsLocaleSelectPage.route => '語言'.i18n,
          SettingsUnitPage.route => '單位'.i18n,
          SettingsMapPage.route => '地圖'.i18n,

          SettingsNotifyPage.route => '通知'.i18n,
          SettingsNotifyEewPage.route => '緊急地震速報'.i18n,
          SettingsNotifyMonitorPage.route => '強震監視器'.i18n,
          SettingsNotifyReportPage.route => '地震報告'.i18n,
          SettingsNotifyIntensityPage.route => '震度速報'.i18n,
          SettingsNotifyThunderstormPage.route => '雷雨即時訊息'.i18n,
          SettingsNotifyAdvisoryPage.route => '天氣警特報'.i18n,
          SettingsNotifyEvacuationPage.route => '防災資訊'.i18n,
          SettingsNotifyTsunamiPage.route => '海嘯資訊'.i18n,
          SettingsNotifyAnnouncementPage.route => '公告'.i18n,

          SettingsDonatePage.route => '贊助我們'.i18n,
          _ => '設定'.i18n,
        };

        return ShellWrapper(
          SettingsLayout(
            title: title,
            child: Theme(
              data: context.theme.copyWith(pageTransitionsTheme: kFadeForwardPageTransitionsTheme),
              child: child,
            ),
          ),
        );
      },
      routes: [
        GoRoute(path: SettingsIndexPage.route, builder: (context, state) => const Material(child: SettingsIndexPage())),
        GoRoute(
          path: SettingsLocationPage.route,
          builder: (context, state) => const Material(child: SettingsLocationPage()),
        ),
        GoRoute(
          path: SettingsLocationSelectPage.route,
          builder: (context, state) => const Material(child: SettingsLocationSelectPage()),
        ),
        GoRoute(
          path: SettingsLocationSelectCityPage.route(),
          builder:
              (context, state) => Material(child: SettingsLocationSelectCityPage(city: state.pathParameters['city']!)),
        ),
        GoRoute(path: SettingsThemePage.route, builder: (context, state) => const Material(child: SettingsThemePage())),
        GoRoute(
          path: SettingsThemeSelectPage.route,
          builder: (context, state) => const Material(child: SettingsThemeSelectPage()),
        ),
        GoRoute(
          path: SettingsLocalePage.route,
          builder: (context, state) => const Material(child: SettingsLocalePage()),
        ),
        GoRoute(
          path: SettingsLocaleSelectPage.route,
          builder: (context, state) => const Material(child: SettingsLocaleSelectPage()),
        ),
        GoRoute(path: SettingsUnitPage.route, builder: (context, state) => const Material(child: SettingsUnitPage())),
        GoRoute(path: SettingsMapPage.route, builder: (context, state) => const Material(child: SettingsMapPage())),
        GoRoute(
          path: SettingsNotifyPage.route,
          builder: (context, state) => const Material(child: SettingsNotifyPage()),
          routes: [
            GoRoute(
              path: SettingsNotifyEewPage.name,
              builder: (context, state) => const Material(child: SettingsNotifyEewPage()),
            ),
            GoRoute(
              path: SettingsNotifyMonitorPage.name,
              builder: (context, state) => const Material(child: SettingsNotifyMonitorPage()),
            ),
            GoRoute(
              path: SettingsNotifyReportPage.name,
              builder: (context, state) => const Material(child: SettingsNotifyReportPage()),
            ),
            GoRoute(
              path: SettingsNotifyIntensityPage.name,
              builder: (context, state) => const Material(child: SettingsNotifyIntensityPage()),
            ),
            GoRoute(
              path: SettingsNotifyThunderstormPage.name,
              builder: (context, state) => const Material(child: SettingsNotifyThunderstormPage()),
            ),
            GoRoute(
              path: SettingsNotifyAdvisoryPage.name,
              builder: (context, state) => const Material(child: SettingsNotifyAdvisoryPage()),
            ),
            GoRoute(
              path: SettingsNotifyEvacuationPage.name,
              builder: (context, state) => const Material(child: SettingsNotifyEvacuationPage()),
            ),
            GoRoute(
              path: SettingsNotifyTsunamiPage.name,
              builder: (context, state) => const Material(child: SettingsNotifyTsunamiPage()),
            ),
            GoRoute(
              path: SettingsNotifyAnnouncementPage.name,
              builder: (context, state) => const Material(child: SettingsNotifyAnnouncementPage()),
            ),
          ],
        ),
        GoRoute(
          path: SettingsDonatePage.route,
          builder: (context, state) => const Material(child: SettingsDonatePage()),
        ),
      ],
    ),
    GoRoute(
      path: MapPage.route(),
      builder: (context, state) => MapPage(options: MapPageOptions.fromQueryParameters(state.uri.queryParameters)),
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
