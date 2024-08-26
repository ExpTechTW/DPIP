import "package:flutter/material.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";

extension CommonContext on BuildContext {
  AppLocalizations get i18n => AppLocalizations.of(this)!;
  ThemeData get theme => Theme.of(this);
  NavigatorState get navigator => Navigator.of(this);
  ColorScheme get colors => Theme.of(this).colorScheme;
  ScaffoldMessengerState get scaffoldMessenger => ScaffoldMessenger.of(this);
  Size get dimension => MediaQuery.sizeOf(this);
  EdgeInsets get padding => MediaQuery.paddingOf(this);
}
