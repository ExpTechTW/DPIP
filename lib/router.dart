import 'package:dpip/utils/constants.dart';
import 'package:dpip/utils/extensions/build_context.dart';
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
import 'package:dpip/app/settings/layout/page.dart';
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
import 'package:dpip/app/settings/proxy/page.dart';
import 'package:dpip/app/settings/unit/page.dart';
import 'package:dpip/app/welcome/1-about/page.dart';
import 'package:dpip/app/welcome/2-exptech/page.dart';
import 'package:dpip/app/welcome/3-notice/page.dart';
import 'package:dpip/app/welcome/4-permissions/page.dart';
import 'package:dpip/core/i18n.dart';
import 'package:dpip/core/preference.dart';
import 'package:dpip/route/announcement/announcement.dart';
import 'package:dpip/utils/log.dart';
import 'package:dpip/widgets/shell_wrapper.dart';

part 'router.g.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _settingsNavigatorKey = GlobalKey<NavigatorState>();

// TypedGoRoute definitions

/// Welcome route - displays the welcome/onboarding page.
@TypedGoRoute<WelcomeRoute>(path: '/welcome')
class WelcomeRoute extends GoRouteData with $WelcomeRoute {
  /// Creates a [WelcomeRoute].
  const WelcomeRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const WelcomeAboutPage();
  }
}

/// Welcome ExpTech route - displays ExpTech introduction page.
@TypedGoRoute<WelcomeExptechRoute>(path: '/welcome/exptech')
class WelcomeExptechRoute extends GoRouteData with $WelcomeExptechRoute {
  /// Creates a [WelcomeExptechRoute].
  const WelcomeExptechRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const WelcomeExpTechPage();
  }
}

/// Welcome Notice route - displays notice/disclaimer page.
@TypedGoRoute<WelcomeNoticeRoute>(path: '/welcome/notice')
class WelcomeNoticeRoute extends GoRouteData with $WelcomeNoticeRoute {
  /// Creates a [WelcomeNoticeRoute].
  const WelcomeNoticeRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const WelcomeNoticePage();
  }
}

/// Welcome Permissions route - displays permissions request page.
@TypedGoRoute<WelcomePermissionsRoute>(path: '/welcome/permissions')
class WelcomePermissionsRoute extends GoRouteData with $WelcomePermissionsRoute {
  /// Creates a [WelcomePermissionsRoute].
  const WelcomePermissionsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const WelcomePermissionPage();
  }
}

/// Home route - displays the main application home page.
@TypedGoRoute<HomeRoute>(path: '/home')
class HomeRoute extends GoRouteData with $HomeRoute {
  /// Creates a [HomeRoute].
  const HomeRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const AppLayout(child: HomePage());
  }
}

// Settings Shell Route and Children
@TypedShellRoute<SettingsShellRoute>(
  routes: <TypedGoRoute<GoRouteData>>[
    TypedGoRoute<SettingsIndexRoute>(path: '/settings'),
    TypedGoRoute<SettingsLayoutRoute>(path: '/settings/layout'),
    TypedGoRoute<SettingsLocationRoute>(path: '/settings/location'),
    TypedGoRoute<SettingsLocationSelectRoute>(path: '/settings/location/select'),
    TypedGoRoute<SettingsLocationSelectCityRoute>(path: '/settings/location/select/:city'),
    TypedGoRoute<SettingsThemeRoute>(path: '/settings/theme'),
    TypedGoRoute<SettingsThemeSelectRoute>(path: '/settings/theme/select'),
    TypedGoRoute<SettingsLocaleRoute>(path: '/settings/locale'),
    TypedGoRoute<SettingsLocaleSelectRoute>(path: '/settings/locale/select'),
    TypedGoRoute<SettingsUnitRoute>(path: '/settings/unit'),
    TypedGoRoute<SettingsMapRoute>(path: '/settings/map'),
    TypedGoRoute<SettingsProxyRoute>(path: '/settings/proxy'),
    TypedGoRoute<SettingsNotifyRoute>(
      path: '/settings/notify',
      routes: <TypedGoRoute<GoRouteData>>[
        TypedGoRoute<SettingsNotifyEewRoute>(path: 'eew'),
        TypedGoRoute<SettingsNotifyMonitorRoute>(path: 'monitor'),
        TypedGoRoute<SettingsNotifyReportRoute>(path: 'report'),
        TypedGoRoute<SettingsNotifyIntensityRoute>(path: 'intensity'),
        TypedGoRoute<SettingsNotifyThunderstormRoute>(path: 'thunderstorm'),
        TypedGoRoute<SettingsNotifyAdvisoryRoute>(path: 'advisory'),
        TypedGoRoute<SettingsNotifyEvacuationRoute>(path: 'evacuation'),
        TypedGoRoute<SettingsNotifyTsunamiRoute>(path: 'tsunami'),
        TypedGoRoute<SettingsNotifyAnnouncementRoute>(path: 'announcement'),
      ],
    ),
    TypedGoRoute<SettingsDonateRoute>(path: '/settings/donate'),
  ],
)
/// Settings shell route - wraps all settings pages with a common layout.
class SettingsShellRoute extends ShellRouteData {
  /// Creates a [SettingsShellRoute].
  const SettingsShellRoute();

  /// Navigator key for the settings shell route.
  static final GlobalKey<NavigatorState> $navigatorKey = _settingsNavigatorKey;

  @override
  Widget builder(BuildContext context, GoRouterState state, Widget navigator) {
    final title = _getSettingsTitle(state.fullPath);
    return ShellWrapper(
      SettingsLayout(
        title: title,
        child: Theme(
          data: context.theme.copyWith(pageTransitionsTheme: kFadeForwardPageTransitionsTheme),
          child: navigator,
        ),
      ),
    );
  }

  static String _getSettingsTitle(String? path) {
    return switch (path) {
      '/settings/location' => '所在地'.i18n,
      '/settings/location/select' => '新增地點'.i18n,
      final p when p?.startsWith('/settings/location/select/') == true => '新增地點'.i18n,
      '/settings/layout' => '佈局'.i18n,
      '/settings/theme' => '主題'.i18n,
      '/settings/theme/select' => '主題'.i18n,
      '/settings/locale' => '語言'.i18n,
      '/settings/locale/select' => '語言'.i18n,
      '/settings/unit' => '單位'.i18n,
      '/settings/map' => '地圖'.i18n,
      '/settings/proxy' => 'HTTP 代理'.i18n,
      '/settings/notify' => '通知'.i18n,
      '/settings/notify/eew' => '緊急地震速報'.i18n,
      '/settings/notify/monitor' => '強震監視器'.i18n,
      '/settings/notify/report' => '地震報告'.i18n,
      '/settings/notify/intensity' => '震度速報'.i18n,
      '/settings/notify/thunderstorm' => '雷雨即時訊息'.i18n,
      '/settings/notify/advisory' => '天氣警特報'.i18n,
      '/settings/notify/evacuation' => '防災資訊'.i18n,
      '/settings/notify/tsunami' => '海嘯資訊'.i18n,
      '/settings/notify/announcement' => '公告'.i18n,
      '/settings/donate' => '贊助我們'.i18n,
      _ => '設定'.i18n,
    };
  }
}

/// Settings index route - displays the main settings page.
class SettingsIndexRoute extends GoRouteData with $SettingsIndexRoute {
  /// Creates a [SettingsIndexRoute].
  const SettingsIndexRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const Material(child: SettingsIndexPage());
  }
}

/// Settings location route - displays location settings.
class SettingsLocationRoute extends GoRouteData with $SettingsLocationRoute {
  /// Creates a [SettingsLocationRoute].
  const SettingsLocationRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const Material(child: SettingsLocationPage());
  }
}

/// Settings location select route - displays location selection page.
class SettingsLocationSelectRoute extends GoRouteData with $SettingsLocationSelectRoute {
  /// Creates a [SettingsLocationSelectRoute].
  const SettingsLocationSelectRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const Material(child: SettingsLocationSelectPage());
  }
}

/// Settings location select city route - displays city selection page.
class SettingsLocationSelectCityRoute extends GoRouteData with $SettingsLocationSelectCityRoute {
  /// Creates a [SettingsLocationSelectCityRoute].
  const SettingsLocationSelectCityRoute({required this.city});

  /// The city parameter from the route path.
  final String city;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return Material(child: SettingsLocationSelectCityPage(city: city));
  }
}

class SettingsLayoutRoute extends GoRouteData with $SettingsLayoutRoute {
  /// Creates a [SettingsLayoutRoute].
  const SettingsLayoutRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const Material(child: SettingsLayoutPage());
  }
}

/// Settings theme route - displays theme settings.
class SettingsThemeRoute extends GoRouteData with $SettingsThemeRoute {
  /// Creates a [SettingsThemeRoute].
  const SettingsThemeRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const Material(child: SettingsThemePage());
  }
}

/// Settings theme select route - displays theme selection page.
class SettingsThemeSelectRoute extends GoRouteData with $SettingsThemeSelectRoute {
  /// Creates a [SettingsThemeSelectRoute].
  const SettingsThemeSelectRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const Material(child: SettingsThemeSelectPage());
  }
}

/// Settings locale route - displays locale/language settings.
class SettingsLocaleRoute extends GoRouteData with $SettingsLocaleRoute {
  /// Creates a [SettingsLocaleRoute].
  const SettingsLocaleRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const Material(child: SettingsLocalePage());
  }
}

/// Settings locale select route - displays locale selection page.
class SettingsLocaleSelectRoute extends GoRouteData with $SettingsLocaleSelectRoute {
  /// Creates a [SettingsLocaleSelectRoute].
  const SettingsLocaleSelectRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const Material(child: SettingsLocaleSelectPage());
  }
}

/// Settings unit route - displays unit settings.
class SettingsUnitRoute extends GoRouteData with $SettingsUnitRoute {
  /// Creates a [SettingsUnitRoute].
  const SettingsUnitRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const Material(child: SettingsUnitPage());
  }
}

/// Settings map route - displays map settings.
class SettingsMapRoute extends GoRouteData with $SettingsMapRoute {
  /// Creates a [SettingsMapRoute].
  const SettingsMapRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const Material(child: SettingsMapPage());
  }
}

/// Settings proxy route - displays HTTP proxy settings.
class SettingsProxyRoute extends GoRouteData with $SettingsProxyRoute {
  /// Creates a [SettingsProxyRoute].
  const SettingsProxyRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const Material(child: SettingsProxyPage());
  }
}

/// Settings notify route - displays notification settings.
class SettingsNotifyRoute extends GoRouteData with $SettingsNotifyRoute {
  /// Creates a [SettingsNotifyRoute].
  const SettingsNotifyRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const Material(child: SettingsNotifyPage());
  }
}

/// Settings notify EEW route - displays earthquake early warning notification settings.
class SettingsNotifyEewRoute extends GoRouteData with $SettingsNotifyEewRoute {
  /// Creates a [SettingsNotifyEewRoute].
  const SettingsNotifyEewRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const Material(child: SettingsNotifyEewPage());
  }
}

/// Settings notify monitor route - displays seismic monitor notification settings.
class SettingsNotifyMonitorRoute extends GoRouteData with $SettingsNotifyMonitorRoute {
  /// Creates a [SettingsNotifyMonitorRoute].
  const SettingsNotifyMonitorRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const Material(child: SettingsNotifyMonitorPage());
  }
}

/// Settings notify report route - displays earthquake report notification settings.
class SettingsNotifyReportRoute extends GoRouteData with $SettingsNotifyReportRoute {
  /// Creates a [SettingsNotifyReportRoute].
  const SettingsNotifyReportRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const Material(child: SettingsNotifyReportPage());
  }
}

/// Settings notify intensity route - displays intensity notification settings.
class SettingsNotifyIntensityRoute extends GoRouteData with $SettingsNotifyIntensityRoute {
  /// Creates a [SettingsNotifyIntensityRoute].
  const SettingsNotifyIntensityRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const Material(child: SettingsNotifyIntensityPage());
  }
}

/// Settings notify thunderstorm route - displays thunderstorm notification settings.
class SettingsNotifyThunderstormRoute extends GoRouteData with $SettingsNotifyThunderstormRoute {
  /// Creates a [SettingsNotifyThunderstormRoute].
  const SettingsNotifyThunderstormRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const Material(child: SettingsNotifyThunderstormPage());
  }
}

/// Settings notify advisory route - displays weather advisory notification settings.
class SettingsNotifyAdvisoryRoute extends GoRouteData with $SettingsNotifyAdvisoryRoute {
  /// Creates a [SettingsNotifyAdvisoryRoute].
  const SettingsNotifyAdvisoryRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const Material(child: SettingsNotifyAdvisoryPage());
  }
}

/// Settings notify evacuation route - displays evacuation notification settings.
class SettingsNotifyEvacuationRoute extends GoRouteData with $SettingsNotifyEvacuationRoute {
  /// Creates a [SettingsNotifyEvacuationRoute].
  const SettingsNotifyEvacuationRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const Material(child: SettingsNotifyEvacuationPage());
  }
}

/// Settings notify tsunami route - displays tsunami notification settings.
class SettingsNotifyTsunamiRoute extends GoRouteData with $SettingsNotifyTsunamiRoute {
  /// Creates a [SettingsNotifyTsunamiRoute].
  const SettingsNotifyTsunamiRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const Material(child: SettingsNotifyTsunamiPage());
  }
}

/// Settings notify announcement route - displays announcement notification settings.
class SettingsNotifyAnnouncementRoute extends GoRouteData with $SettingsNotifyAnnouncementRoute {
  /// Creates a [SettingsNotifyAnnouncementRoute].
  const SettingsNotifyAnnouncementRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const Material(child: SettingsNotifyAnnouncementPage());
  }
}

/// Settings donate route - displays donation/support page.
class SettingsDonateRoute extends GoRouteData with $SettingsDonateRoute {
  /// Creates a [SettingsDonateRoute].
  const SettingsDonateRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const Material(child: SettingsDonatePage());
  }
}

/// Map route - displays the map page with optional layers and report.
@TypedGoRoute<MapRoute>(path: '/map')
class MapRoute extends GoRouteData with $MapRoute {
  /// Creates a [MapRoute].
  const MapRoute({this.layers, this.report});

  /// Optional comma-separated list of map layers to display.
  final String? layers;

  /// Optional report ID to display on the map.
  final String? report;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return MapPage(
      options: MapPageOptions.fromQueryParameters({
        if (layers != null) 'layers': layers!,
        if (report != null) 'report': report!,
      }),
    );
  }
}

/// Announcement route - displays announcements page.
@TypedGoRoute<AnnouncementRoute>(path: '/announcement')
class AnnouncementRoute extends GoRouteData with $AnnouncementRoute {
  /// Creates an [AnnouncementRoute].
  const AnnouncementRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const AnnouncementPage();
  }
}

/// Changelog route - displays app changelog.
@TypedGoRoute<ChangelogRoute>(path: '/changelog')
class ChangelogRoute extends GoRouteData with $ChangelogRoute {
  /// Creates a [ChangelogRoute].
  const ChangelogRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const ChangelogPage();
  }
}

/// License route - displays open source licenses.
@TypedGoRoute<LicenseRoute>(path: '/license')
class LicenseRoute extends GoRouteData with $LicenseRoute {
  /// Creates a [LicenseRoute].
  const LicenseRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const LicensePage();
  }
}

/// Debug logs route - displays application debug logs.
@TypedGoRoute<AppDebugLogsRoute>(path: '/debug/logs')
class AppDebugLogsRoute extends GoRouteData with $AppDebugLogsRoute {
  /// Creates an [AppDebugLogsRoute].
  const AppDebugLogsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const AppDebugLogsPage();
  }
}

/// The main application router configured with all typed routes.
final router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  redirect: (context, state) {
    // Handle initial location logic
    if (state.matchedLocation == '/' || state.matchedLocation.isEmpty) {
      return Preference.isFirstLaunch ? const WelcomeRoute().location : const HomeRoute().location;
    }
    return null;
  },
  routes: $appRoutes,
  observers: [TalkerRouteObserver(TalkerManager.instance)],
  debugLogDiagnostics: true,
);
