import 'package:dpip/app/shell/main_shell.dart';
import 'package:dpip/features/earthquake/presentation/pages/earthquake_page.dart';
import 'package:dpip/features/events/presentation/pages/events_page.dart';
import 'package:dpip/features/home/presentation/pages/home_page.dart';
import 'package:dpip/features/log/presentation/pages/log_page.dart';
import 'package:dpip/features/map/presentation/pages/map_page.dart';
import 'package:dpip/features/more/presentation/pages/more_page.dart';
import 'package:dpip/features/settings/presentation/pages/experimental_page.dart';
import 'package:dpip/shared/navigation/app_routes.dart';
import 'package:go_router/go_router.dart';

/// The application's route table.
///
/// A [StatefulShellRoute] hosts the five bottom-navigation branches, in the
/// same order as `MainShell`'s destinations; each branch keeps its own state.
/// Route names/paths come from [AppRoutes] so features never import each other's
/// page widgets to navigate.
final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.homePath,
  routes: [
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
