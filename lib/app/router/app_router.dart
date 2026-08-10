import 'package:dpip/app/shell/main_shell.dart';
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
import 'package:dpip/features/log/presentation/pages/log_page.dart';
import 'package:dpip/features/map/presentation/pages/map_page.dart';
import 'package:dpip/features/more/presentation/pages/more_page.dart';
import 'package:dpip/features/notification/presentation/pages/notify_page.dart';
import 'package:dpip/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:dpip/features/settings/presentation/pages/developer_page.dart';
import 'package:dpip/features/settings/presentation/pages/display_page.dart';
import 'package:dpip/features/settings/presentation/pages/experimental_page.dart';
import 'package:dpip/features/settings/presentation/pages/default_map_layer_page.dart';
import 'package:dpip/features/settings/presentation/pages/language_page.dart';
import 'package:dpip/features/sponsor/presentation/pages/sponsor_page.dart';
import 'package:dpip/features/weather/presentation/pages/weather_ranking_page.dart';
import 'package:dpip/shared/navigation/app_routes.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// The application's route table.
///
/// A [StatefulShellRoute] hosts the five bottom-navigation branches, in the
/// same order as `MainShell`'s destinations; each branch keeps its own state.
/// Route names/paths come from [AppRoutes] so features never import each other's
/// page widgets to navigate.
final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.homePath,
  // First launch: hold everything behind onboarding until it's completed. The
  // redirect reads the app-wide OnboardingStore (mounted above the router), so
  // finishing onboarding (which flips the flag) lets a goNamed(home) through.
  redirect: (context, state) {
    final complete = context.read<OnboardingStore>().isComplete;
    final atOnboarding = state.matchedLocation == AppRoutes.onboardingPath;
    if (!complete && !atOnboarding) return AppRoutes.onboardingPath;
    if (complete && atOnboarding) return AppRoutes.homePath;
    return null;
  },
  routes: [
    GoRoute(
      path: AppRoutes.onboardingPath,
      name: AppRoutes.onboarding,
      builder: (_, _) => const OnboardingPage(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          MainShell(navigationShell: navigationShell),
      branches: [
        _branch(AppRoutes.homePath, AppRoutes.home, (_, _) => const HomePage()),
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
              builder: (_, _) => const DataPage(),
              routes: [
                GoRoute(
                  path: AppRoutes.earthquakePath,
                  name: AppRoutes.earthquake,
                  builder: (_, _) => const ReportListPage(),
                  routes: [
                    GoRoute(
                      path: AppRoutes.earthquakeReportPath,
                      name: AppRoutes.earthquakeReport,
                      builder: (_, state) => ReportDetailPage(
                        reportId: state.pathParameters['id']!,
                      ),
                      routes: [
                        GoRoute(
                          path: AppRoutes.earthquakeReplayPath,
                          name: AppRoutes.earthquakeReplay,
                          builder: (_, state) => ReportReplayPage(
                            replayTimestamp: int.parse(
                              state.uri.queryParameters['t']!,
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
                  builder: (_, _) => const EarthquakePage(),
                ),
                GoRoute(
                  path: AppRoutes.weatherRankingPath,
                  name: AppRoutes.weatherRanking,
                  builder: (_, state) => WeatherRankingPage(
                    initialTab: WeatherRankingTab.parse(
                      state.uri.queryParameters['tab'],
                    ),
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
      builder: (_, _) => const ExperimentalPage(),
    ),
    GoRoute(
      path: AppRoutes.logPath,
      name: AppRoutes.log,
      builder: (_, _) => const LogPage(),
    ),
    GoRoute(
      path: AppRoutes.changelogPath,
      name: AppRoutes.changelog,
      builder: (_, _) => const ChangelogPage(),
    ),
    GoRoute(
      path: AppRoutes.developerPath,
      name: AppRoutes.developer,
      builder: (_, _) => const DeveloperPage(),
    ),
    GoRoute(
      path: AppRoutes.displayPath,
      name: AppRoutes.display,
      builder: (_, _) => const DisplayPage(),
    ),
    GoRoute(
      path: AppRoutes.languagePath,
      name: AppRoutes.language,
      builder: (_, _) => const LanguagePage(),
    ),
    GoRoute(
      path: AppRoutes.defaultMapLayerPath,
      name: AppRoutes.defaultMapLayer,
      builder: (_, _) => const DefaultMapLayerPage(),
    ),
    GoRoute(
      path: AppRoutes.regionManagePath,
      name: AppRoutes.regionManage,
      builder: (_, _) => const RegionManagePage(),
    ),
    GoRoute(
      path: AppRoutes.regionSelectPath,
      name: AppRoutes.regionSelect,
      builder: (_, state) => RegionSelectPage(
        replaceCode: state.uri.queryParameters['replace'],
        returnToMore: state.uri.queryParameters['returnToMore'] == '1',
      ),
      routes: [
        GoRoute(
          path: AppRoutes.regionSelectCityPath,
          name: AppRoutes.regionSelectCity,
          builder: (_, state) => RegionCityPage(
            city: state.pathParameters['city']!,
            replaceCode: state.uri.queryParameters['replace'],
            returnToMore: state.uri.queryParameters['returnToMore'] == '1',
          ),
        ),
      ],
    ),
    GoRoute(
      path: AppRoutes.notifySettingsPath,
      name: AppRoutes.notifySettings,
      builder: (_, _) => const NotifyPage(),
    ),
    GoRoute(
      path: AppRoutes.sponsorPath,
      name: AppRoutes.sponsor,
      builder: (_, _) => const SponsorPage(),
    ),
  ],
);

/// Builds a single-route branch for the bottom-navigation shell.
StatefulShellBranch _branch(
  String path,
  String name,
  GoRouterWidgetBuilder builder,
) => StatefulShellBranch(
  routes: [GoRoute(path: path, name: name, builder: builder)],
);
