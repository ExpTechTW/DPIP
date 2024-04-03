import 'package:flutter/material.dart';

extension CommonContext on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colors => Theme.of(this).colorScheme;
  ScaffoldMessengerState get scaffoldMessenger => ScaffoldMessenger.of(this);
}
