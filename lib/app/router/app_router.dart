import 'package:dpip/app/shell/main_shell.dart';
import 'package:dpip/core/settings/onboarding_store.dart';
import 'package:dpip/features/earthquake/presentation/pages/earthquake_page.dart';
import 'package:dpip/features/events/presentation/pages/events_page.dart';
import 'package:dpip/features/home/presentation/pages/home_page.dart';
import 'package:dpip/features/location/presentation/pages/region_city_page.dart';
import 'package:dpip/features/location/presentation/pages/region_select_page.dart';
import 'package:dpip/features/log/presentation/pages/log_page.dart';
import 'package:dpip/features/map/presentation/pages/map_page.dart';
import 'package:dpip/features/more/presentation/pages/more_page.dart';
import 'package:dpip/features/notification/presentation/pages/notify_page.dart';
import 'package:dpip/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:dpip/features/settings/presentation/pages/developer_page.dart';
import 'package:dpip/features/settings/presentation/pages/experimental_page.dart';
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
        _branch(
          AppRoutes.earthquakePath,
          AppRoutes.earthquake,
          (_, _) => const EarthquakePage(),
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
      path: AppRoutes.developerPath,
      name: AppRoutes.developer,
      builder: (_, _) => const DeveloperPage(),
    ),
    GoRoute(
      path: AppRoutes.regionSelectPath,
      name: AppRoutes.regionSelect,
      builder: (_, _) => const RegionSelectPage(),
      routes: [
        GoRoute(
          path: AppRoutes.regionSelectCityPath,
          name: AppRoutes.regionSelectCity,
          builder: (_, state) =>
              RegionCityPage(city: state.pathParameters['city']!),
        ),
      ],
    ),
    GoRoute(
      path: AppRoutes.notifySettingsPath,
      name: AppRoutes.notifySettings,
      builder: (_, _) => const NotifyPage(),
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
