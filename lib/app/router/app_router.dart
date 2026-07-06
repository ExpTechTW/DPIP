import 'package:dpip/features/home/presentation/pages/home_page.dart';
import 'package:go_router/go_router.dart';

/// The application's route table.
///
/// Each feature exposes its route metadata (path/name) from its own page
/// classes; this file aggregates them so navigation stays declarative and
/// discoverable in one place.
final GoRouter appRouter = GoRouter(
  initialLocation: HomePage.path,
  routes: [
    GoRoute(
      path: HomePage.path,
      name: HomePage.name,
      builder: (context, state) => const HomePage(),
    ),
  ],
);
