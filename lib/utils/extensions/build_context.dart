import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';

import 'package:dpip/l10n/app_localizations.dart';
import 'package:dpip/utils/extensions/go_router.dart';

extension CommonContext on BuildContext {
  AppLocalizations get i18n => AppLocalizations.of(this)!;
  ThemeData get theme => Theme.of(this);
  NavigatorState get navigator => Navigator.of(this);
  ColorScheme get colors => Theme.of(this).colorScheme;
  ScaffoldMessengerState get scaffoldMessenger => ScaffoldMessenger.of(this);
  Size get dimension => MediaQuery.sizeOf(this);
  EdgeInsets get padding => MediaQuery.paddingOf(this);
  TextTheme get textTheme => theme.textTheme;
  Size get screen => MediaQuery.sizeOf(this);
}

extension BuildContextExtension on BuildContext {
  /// Pops the navigation stack until reaching the specified path
  /// Returns true if successfully popped to the path, false if path not found
  void popUntil(String path) => GoRouter.of(this).popUntil(path);

  /// The height and width constraints for the bottom sheet in Material 3
  BoxConstraints get bottomSheetConstraints => BoxConstraints(maxHeight: screen.height - 72, maxWidth: 640);
}
