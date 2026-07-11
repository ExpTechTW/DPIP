import 'package:dpip/app/shell/main_shell.dart';
import 'package:dpip/features/earthquake/presentation/pages/earthquake_page.dart';
import 'package:dpip/features/events/presentation/pages/events_page.dart';
import 'package:dpip/features/home/presentation/pages/home_page.dart';
import 'package:dpip/features/map/presentation/pages/map_page.dart';
import 'package:dpip/features/more/presentation/pages/more_page.dart';
import 'package:go_router/go_router.dart';

/// The application's route table.
///
/// A [StatefulShellRoute] hosts the five bottom-navigation branches, in the
/// same order as `MainShell`'s destinations; each branch keeps its own state.
final GoRouter appRouter = GoRouter(
  initialLocation: HomePage.path,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          MainShell(navigationShell: navigationShell),
      branches: [
        _branch(HomePage.path, HomePage.name, (_, _) => const HomePage()),
        _branch(EventsPage.path, EventsPage.name, (_, _) => const EventsPage()),
        _branch(MapPage.path, MapPage.name, (_, _) => const MapPage()),
        _branch(
          EarthquakePage.path,
          EarthquakePage.name,
          (_, _) => const EarthquakePage(),
        ),
        _branch(MorePage.path, MorePage.name, (_, _) => const MorePage()),
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
  routes: [GoRoute(path: path, name: name, builder: builder)],
);
