import 'package:dpip/utils/extensions/go_router.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Extension on [BuildContext] that provides convenient access to commonly used Flutter framework objects and
/// utilities.
///
/// This extension simplifies access to theme data, media query information, navigation, and other frequently used
/// context-dependent objects, reducing boilerplate code throughout the application.
///
/// Example usage:
/// ```dart
/// // Instead of: Theme.of(context)
/// context.theme
///
/// // Instead of: MediaQuery.sizeOf(context)
/// context.dimension
///
/// // Instead of: Navigator.of(context)
/// context.navigator
/// ```
extension BuildContextExtension on BuildContext {
  /// Returns the [ThemeData] from the nearest [Theme] ancestor.
  ThemeData get theme => Theme.of(this);

  /// Returns the [ColorScheme] from the current theme.
  ColorScheme get colors => theme.colorScheme;

  /// Returns the [TextTheme] from the current theme.
  TextTheme get texts => theme.textTheme;

  /// Returns the size of the current media (screen/window).
  Size get dimension => MediaQuery.sizeOf(this);

  /// Returns the padding insets of the current media (e.g., system UI insets).
  EdgeInsets get padding => MediaQuery.paddingOf(this);

  /// Returns the brightness of the current platform
  Brightness get brightness => MediaQuery.platformBrightnessOf(this);

  /// Returns the [NavigatorState] from the nearest [Navigator] ancestor.
  NavigatorState get navigator => Navigator.of(this);

  /// Returns the [ScaffoldMessengerState] from the nearest [ScaffoldMessenger] ancestor.
  ScaffoldMessengerState get scaffoldMessenger => ScaffoldMessenger.of(this);

  /// Returns the [GoRouter] instance from the current context.
  ///
  /// Example:
  /// ```dart
  /// // Navigate to a new route
  /// context.router.push('/settings');
  ///
  /// // Get the current route location
  /// final location = context.router.routerDelegate.currentConfiguration.uri.toString();
  /// ```
  GoRouter get router => GoRouter.of(this);

  /// Pops the navigation stack until reaching the route matching [path].
  ///
  /// This method uses [GoRouter] to pop routes from the navigation stack until it finds a route matching [path]. If the
  /// path is not found in the current navigation stack, the method will stop at the root route.
  ///
  /// The [path] should match the route path defined in your router configuration.
  ///
  /// Example:
  /// ```dart
  /// // Pop until reaching the settings page
  /// context.popUntil('/settings');
  /// ```
  void popUntil(String path) => router.popUntil(path);

  /// Returns the height and width constraints for bottom sheets in Material 3.
  ///
  /// These constraints follow Material Design 3 guidelines for bottom sheets:
  /// - Maximum height: the dimension's height minus 72 logical pixels (to account for system UI and spacing)
  /// - Maximum width: 640 logical pixels (standard maximum width for bottom sheets)
  ///
  /// Example:
  /// ```dart
  /// showModalBottomSheet(
  ///   context: context,
  ///   constraints: context.bottomSheetConstraints,
  ///   builder: (context) => MyBottomSheet(),
  /// );
  /// ```
  BoxConstraints get bottomSheetConstraints =>
      BoxConstraints(maxHeight: dimension.height - 72, maxWidth: 640);
}
