import 'package:dpip/l10n/app_localizations.dart';
import "package:flutter/material.dart";

extension CommonContext on BuildContext {
  AppLocalizations get i18n => AppLocalizations.of(this)!;
  ThemeData get theme => Theme.of(this);
  NavigatorState get navigator => Navigator.of(this);
  ColorScheme get colors => Theme.of(this).colorScheme;
  ScaffoldMessengerState get scaffoldMessenger => ScaffoldMessenger.of(this);
  Size get dimension => MediaQuery.sizeOf(this);
  EdgeInsets get padding => MediaQuery.paddingOf(this);
}
