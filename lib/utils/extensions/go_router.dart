import 'package:go_router/go_router.dart';

/// Extension on [GoRouter] that provides convenient utilities for navigation operations.
///
/// This extension adds helpful methods to simplify common navigation patterns and route management operations that are
/// not directly available in the standard GoRouter API.
extension GoRouterExtension on GoRouter {
  /// Pops routes from the navigation stack until a route matching [routePath] is reached.
  ///
  /// This method traverses the current route stack from top to bottom, removing routes until it finds a route whose
  /// path ends with [routePath]. If the target route is found, navigation stops at that route. If the route is not
  /// found in the stack, the method will continue popping until the root route is reached.
  ///
  /// The method handles [ShellRoute] instances specially by using the `restore` method to properly manage nested
  /// navigation stacks, ensuring that shell routes are correctly handled during the pop operation.
  ///
  /// The [routePath] parameter is a path suffix to match against route paths. The method uses `endsWith` to match
  /// routes, so partial paths are supported (e.g., '/settings' will match '/app/settings').
  ///
  /// This method only processes [GoRoute] instances and skips other route types in the stack.
  ///
  /// Example:
  /// ```dart
  /// // Pop until reaching the settings page
  /// GoRouter.of(context).popUntil('/settings');
  ///
  /// // Or using the BuildContext extension
  /// context.popUntil('/settings');
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
