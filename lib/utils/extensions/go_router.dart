import 'package:go_router/go_router.dart';

extension GoRouterExtension on GoRouter {
  /// Pop until the route with the given [path] is reached.
  /// Example
  /// ``` dart
  ///  GoRouter.of(context).popUntil(SettingsPage.route);
  /// ```
  void popUntil(String routePath) {
    final routerDelegate = this.routerDelegate;
    final routeStacks = routerDelegate.currentConfiguration.routes.toList();

    for (int i = routeStacks.length - 1; i >= 0; i--) {
      final route = routeStacks[i];

      if (route is! GoRoute) continue;
      if (route.path.endsWith(routePath)) break;

      if (i != 0 && routeStacks[i - 1] is ShellRoute) {
        final matchList = routerDelegate.currentConfiguration;
        restore(matchList.remove(matchList.matches.last));
      } else {
        pop();
      }
    }
  }
}
