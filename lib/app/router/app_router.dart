import 'package:dpip/app/shell/main_shell.dart';
import 'package:dpip/app/router/route_params.dart';
import 'package:dpip/app/router/widget_location_routes.dart';
import 'package:dpip/core/settings/onboarding_store.dart';
import 'package:dpip/features/data/presentation/pages/data_page.dart';
import 'package:dpip/features/earthquake/presentation/pages/earthquake_page.dart';
import 'package:dpip/features/earthquake/presentation/pages/report_detail_page.dart';
import 'package:dpip/features/earthquake/presentation/pages/report_list_page.dart';
import 'package:dpip/features/earthquake/presentation/pages/report_replay_page.dart';
import 'package:dpip/features/events/presentation/pages/events_page.dart';
import 'package:dpip/features/home/presentation/pages/home_page.dart';
import 'package:dpip/features/location/presentation/pages/region_city_page.dart';
import 'package:dpip/features/location/presentation/pages/region_manage_page.dart';
import 'package:dpip/features/location/presentation/pages/region_select_page.dart';
import 'package:dpip/features/changelog/presentation/pages/changelog_page.dart';
import 'package:dpip/features/changelog/presentation/pages/version_notes_page.dart';
import 'package:dpip/features/release_highlights/presentation/pages/release_highlights_page.dart';
import 'package:dpip/features/log/presentation/pages/log_page.dart';
import 'package:dpip/features/map/presentation/pages/map_page.dart';
import 'package:dpip/features/data/presentation/pages/moon_page.dart';
import 'package:dpip/features/data/presentation/pages/almanac_page.dart';
import 'package:dpip/features/data/presentation/pages/planets_page.dart';
import 'package:dpip/features/data/presentation/pages/sky_chart_page.dart';
import 'package:dpip/features/data/presentation/pages/tide_page.dart';
import 'package:dpip/features/data/presentation/pages/tonight_page.dart';
import 'package:dpip/features/data/presentation/pages/sun_page.dart';
import 'package:dpip/features/meshtastic/presentation/pages/meshtastic_page.dart';
import 'package:dpip/features/more/presentation/pages/more_page.dart';
import 'package:dpip/features/notification/presentation/pages/notification_test_page.dart';
import 'package:dpip/features/notification/presentation/pages/notify_page.dart';
import 'package:dpip/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:dpip/features/settings/presentation/pages/developer_page.dart';
import 'package:dpip/features/settings/presentation/pages/display_page.dart';
import 'package:dpip/features/settings/presentation/pages/experimental_page.dart';
import 'package:dpip/features/settings/presentation/pages/default_map_layer_page.dart';
import 'package:dpip/features/settings/presentation/pages/eew_source_page.dart';
import 'package:dpip/features/settings/presentation/pages/spoken_intensity_page.dart';
import 'package:dpip/features/settings/presentation/pages/language_page.dart';
import 'package:dpip/features/settings/presentation/pages/permissions_page.dart';
import 'package:dpip/features/sponsor/presentation/pages/sponsor_page.dart';
import 'package:dpip/features/bug_tracker/presentation/pages/bug_list_page.dart';
import 'package:dpip/features/bug_tracker/presentation/pages/bug_thread_page.dart';
import 'package:dpip/features/status/presentation/pages/server_status_page.dart';
import 'package:dpip/features/weather/domain/weather_ranking.dart';
import 'package:dpip/features/weather/presentation/pages/weather_ranking_page.dart';
import 'package:dpip/shared/navigation/app_routes.dart';
import 'package:dpip/shared/navigation/refresh_on_appear.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

/// Fires when a redirect *input* changes outside any navigation — today only
/// the background durable-database recovery adopting settings rows this
/// session launched without seeing ([bootstrap] calls [fire]). Without it,
/// GoRouter re-runs [redirect] on navigation events alone, so a returning
/// user held on the welcome page by a failed launch would stay there all
/// session even after the completion flag came back.
final OnboardingRefreshSignal onboardingRefresh = OnboardingRefreshSignal();
final WidgetLocationRoutes _widgetLocationRoutes = WidgetLocationRoutes();

final class OnboardingRefreshSignal extends ChangeNotifier {
  void fire() => notifyListeners();
}

/// The application's route table.
///
/// A [StatefulShellRoute] hosts the five bottom-navigation branches, in the
/// same order as `MainShell`'s destinations; each branch keeps its own state.
/// Route names/paths come from [AppRoutes] so features never import each other's
/// page widgets to navigate.
final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.homePath,
  refreshListenable: onboardingRefresh,
  // Lets the shell notice that one of the full-screen routes below has covered
  // it, so the tabs underneath can idle instead of animating at nobody.
  observers: [shellRouteObserver],
  // First launch: hold everything behind onboarding until it's completed. The
  // redirect reads the app-wide OnboardingStore (mounted above the router), so
  // finishing onboarding (which flips the flag) lets a goNamed(home) through.
  redirect: (context, state) {
    final complete = context.read<OnboardingStore>().isComplete;
    return _widgetLocationRoutes.redirect(
      onboardingComplete: complete,
      uri: state.uri,
    );
  },
  routes: [
    GoRoute(
      path: AppRoutes.onboardingPath,
      name: AppRoutes.onboarding,
      pageBuilder: (_, state) =>
          MaterialPage<void>(key: state.pageKey, child: const OnboardingPage()),
    ),
    StatefulShellRoute.indexedStack(
      pageBuilder: (context, state, navigationShell) => MaterialPage<void>(
        key: state.pageKey,
        child: MainShell(navigationShell: navigationShell),
      ),
      branches: [
        _branch(
          AppRoutes.homePath,
          AppRoutes.home,
          (_, _) =>
              HomePage(widgetLocationRequests: _widgetLocationRoutes.requests),
        ),
        _branch(
          AppRoutes.eventsPath,
          AppRoutes.events,
          (_, _) => const EventsPage(),
        ),
        _branch(AppRoutes.mapPath, AppRoutes.map, (_, _) => const MapPage()),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.dataPath,
              name: AppRoutes.data,
              pageBuilder: (_, state) => MaterialPage<void>(
                key: state.pageKey,
                child: const DataPage(),
              ),
              routes: [
                GoRoute(
                  path: AppRoutes.earthquakePath,
                  name: AppRoutes.earthquake,
                  pageBuilder: (_, state) => MaterialPage<void>(
                    key: state.pageKey,
                    child: const ReportListPage(),
                  ),
                  routes: [
                    GoRoute(
                      path: AppRoutes.earthquakeReportPath,
                      name: AppRoutes.earthquakeReport,
                      redirect: reportRedirect,
                      pageBuilder: (_, state) => MaterialPage<void>(
                        key: state.pageKey,
                        child: ReportDetailPage(
                          reportId: state.pathParameters['id'] ?? '',
                        ),
                      ),
                      routes: [
                        GoRoute(
                          path: AppRoutes.earthquakeReplayPath,
                          name: AppRoutes.earthquakeReplay,
                          redirect: replayRedirect,
                          pageBuilder: (_, state) => MaterialPage<void>(
                            key: state.pageKey,
                            child: ReportReplayPage(
                              // [replayRedirect] has already turned a link
                              // without a usable `t` away; this only keeps the
                              // builder total.
                              replayTimestamp: replayTimestampOf(state) ?? 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                GoRoute(
                  path: AppRoutes.eewPath,
                  name: AppRoutes.eew,
                  pageBuilder: (_, state) => MaterialPage<void>(
                    key: state.pageKey,
                    child: const EarthquakePage(),
                  ),
                ),
                GoRoute(
                  path: AppRoutes.weatherRankingPath,
                  name: AppRoutes.weatherRanking,
                  pageBuilder: (_, state) {
                    final rawTab = state.uri.queryParameters['tab'];
                    return MaterialPage<void>(
                      key: state.pageKey,
                      child: WeatherRankingPage(
                        initialTab: WeatherRankingTab.parse(rawTab),
                        initialTempMetric: TempRankMetric.parse(
                          state.uri.queryParameters['metric'] ?? rawTab,
                        ),
                      ),
                    );
                  },
                ),
                GoRoute(
                  path: AppRoutes.moonPath,
                  name: AppRoutes.moon,
                  pageBuilder: (_, state) => MaterialPage<void>(
                    key: state.pageKey,
                    child: const MoonPage(),
                  ),
                ),
                GoRoute(
                  path: AppRoutes.sunPath,
                  name: AppRoutes.sun,
                  pageBuilder: (_, state) => MaterialPage<void>(
                    key: state.pageKey,
                    child: const SunPage(),
                  ),
                ),
                GoRoute(
                  path: AppRoutes.planetsPath,
                  name: AppRoutes.planets,
                  pageBuilder: (_, state) => MaterialPage<void>(
                    key: state.pageKey,
                    child: const PlanetsPage(),
                  ),
                ),
                GoRoute(
                  path: AppRoutes.tonightPath,
                  name: AppRoutes.tonight,
                  pageBuilder: (_, state) => MaterialPage<void>(
                    key: state.pageKey,
                    child: const TonightPage(),
                  ),
                ),
                GoRoute(
                  path: AppRoutes.almanacPath,
                  name: AppRoutes.almanac,
                  pageBuilder: (_, state) => MaterialPage<void>(
                    key: state.pageKey,
                    child: const AlmanacPage(),
                  ),
                ),
                GoRoute(
                  path: AppRoutes.skyChartPath,
                  name: AppRoutes.skyChart,
                  pageBuilder: (_, state) => MaterialPage<void>(
                    key: state.pageKey,
                    child: const SkyChartPage(),
                  ),
                ),
                GoRoute(
                  path: AppRoutes.tidePath,
                  name: AppRoutes.tide,
                  pageBuilder: (_, state) => MaterialPage<void>(
                    key: state.pageKey,
                    child: const TidePage(),
                  ),
                ),
              ],
            ),
          ],
        ),
        _branch(AppRoutes.morePath, AppRoutes.more, (_, _) => const MorePage()),
      ],
    ),
    // Full-screen routes pushed over the shell.
    GoRoute(
      path: AppRoutes.experimentalPath,
      name: AppRoutes.experimental,
      pageBuilder: (_, state) => MaterialPage<void>(
        key: state.pageKey,
        child: const ExperimentalPage(),
      ),
    ),
    GoRoute(
      path: AppRoutes.logPath,
      name: AppRoutes.log,
      pageBuilder: (_, state) =>
          MaterialPage<void>(key: state.pageKey, child: const LogPage()),
    ),
    GoRoute(
      path: AppRoutes.meshtasticPath,
      name: AppRoutes.meshtastic,
      pageBuilder: (_, state) =>
          MaterialPage<void>(key: state.pageKey, child: const MeshtasticPage()),
    ),
    GoRoute(
      path: AppRoutes.changelogPath,
      name: AppRoutes.changelog,
      pageBuilder: (_, state) =>
          MaterialPage<void>(key: state.pageKey, child: const ChangelogPage()),
    ),
    GoRoute(
      path: AppRoutes.versionNotesPath,
      name: AppRoutes.versionNotes,
      pageBuilder: (_, state) => MaterialPage<void>(
        key: state.pageKey,
        child: const VersionNotesPage(),
      ),
    ),
    GoRoute(
      path: AppRoutes.releaseHighlightsPath,
      name: AppRoutes.releaseHighlights,
      pageBuilder: (_, state) => MaterialPage<void>(
        key: state.pageKey,
        child: const ReleaseHighlightsPage(),
      ),
    ),
    GoRoute(
      path: AppRoutes.developerPath,
      name: AppRoutes.developer,
      pageBuilder: (_, state) =>
          MaterialPage<void>(key: state.pageKey, child: const DeveloperPage()),
    ),
    GoRoute(
      path: AppRoutes.displayPath,
      name: AppRoutes.display,
      pageBuilder: (_, state) =>
          MaterialPage<void>(key: state.pageKey, child: const DisplayPage()),
    ),
    GoRoute(
      path: AppRoutes.languagePath,
      name: AppRoutes.language,
      pageBuilder: (_, state) =>
          MaterialPage<void>(key: state.pageKey, child: const LanguagePage()),
    ),
    GoRoute(
      path: AppRoutes.defaultMapLayerPath,
      name: AppRoutes.defaultMapLayer,
      pageBuilder: (_, state) => MaterialPage<void>(
        key: state.pageKey,
        child: const DefaultMapLayerPage(),
      ),
    ),
    GoRoute(
      path: AppRoutes.eewSourcePath,
      name: AppRoutes.eewSource,
      pageBuilder: (_, state) =>
          MaterialPage<void>(key: state.pageKey, child: const EewSourcePage()),
    ),
    GoRoute(
      path: AppRoutes.spokenIntensityPath,
      name: AppRoutes.spokenIntensity,
      pageBuilder: (_, state) => MaterialPage<void>(
        key: state.pageKey,
        child: const SpokenIntensityPage(),
      ),
    ),
    GoRoute(
      path: AppRoutes.regionManagePath,
      name: AppRoutes.regionManage,
      pageBuilder: (_, state) => MaterialPage<void>(
        key: state.pageKey,
        child: const RegionManagePage(),
      ),
    ),
    GoRoute(
      path: AppRoutes.regionSelectPath,
      name: AppRoutes.regionSelect,
      pageBuilder: (_, state) => MaterialPage<void>(
        key: state.pageKey,
        child: RegionSelectPage(
          replaceCode: state.uri.queryParameters['replace'],
          returnToMore: state.uri.queryParameters['returnToMore'] == '1',
        ),
      ),
      routes: [
        GoRoute(
          path: AppRoutes.regionSelectCityPath,
          name: AppRoutes.regionSelectCity,
          redirect: regionCityRedirect,
          pageBuilder: (_, state) => MaterialPage<void>(
            key: state.pageKey,
            child: RegionCityPage(
              city: state.pathParameters['city'] ?? '',
              replaceCode: state.uri.queryParameters['replace'],
              returnToMore: state.uri.queryParameters['returnToMore'] == '1',
            ),
          ),
        ),
      ],
    ),
    GoRoute(
      path: AppRoutes.permissionsPath,
      name: AppRoutes.permissions,
      pageBuilder: (_, state) => MaterialPage<void>(
        key: state.pageKey,
        child: const PermissionsPage(),
      ),
    ),
    GoRoute(
      path: AppRoutes.notifySettingsPath,
      name: AppRoutes.notifySettings,
      pageBuilder: (_, state) =>
          MaterialPage<void>(key: state.pageKey, child: const NotifyPage()),
      routes: [
        GoRoute(
          path: AppRoutes.notifyTestPath,
          name: AppRoutes.notifyTest,
          pageBuilder: (_, state) => MaterialPage<void>(
            key: state.pageKey,
            child: const NotificationTestPage(),
          ),
        ),
      ],
    ),
    GoRoute(
      path: AppRoutes.sponsorPath,
      name: AppRoutes.sponsor,
      pageBuilder: (_, state) =>
          MaterialPage<void>(key: state.pageKey, child: const SponsorPage()),
    ),
    GoRoute(
      path: AppRoutes.serverStatusPath,
      name: AppRoutes.serverStatus,
      pageBuilder: (_, state) => MaterialPage<void>(
        key: state.pageKey,
        child: const ServerStatusPage(),
      ),
    ),
    GoRoute(
      path: AppRoutes.bugTrackerPath,
      name: AppRoutes.bugTracker,
      pageBuilder: (_, state) =>
          MaterialPage<void>(key: state.pageKey, child: const BugListPage()),
      routes: [
        GoRoute(
          path: AppRoutes.bugThreadPath,
          name: AppRoutes.bugThread,
          redirect: bugThreadRedirect,
          pageBuilder: (_, state) => MaterialPage<void>(
            key: state.pageKey,
            child: BugThreadPage(id: bugThreadIdOf(state) ?? 0),
          ),
        ),
      ],
    ),
  ],
);

/// Builds a single-route branch for the bottom-navigation shell.
StatefulShellBranch _branch(
  String path,
  String name,
  GoRouterWidgetBuilder builder,
) => StatefulShellBranch(
  routes: [
    GoRoute(
      path: path,
      name: name,
      pageBuilder: (context, state) => MaterialPage<void>(
        key: state.pageKey,
        child: builder(context, state),
      ),
    ),
  ],
);
