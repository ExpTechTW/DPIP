import "package:flutter/material.dart";

class ExtendedColors {
  late Color blue;
  late Color onBlue;
  late Color blueContainer;
  late Color onBlueContainer;

  ExtendedColors(Brightness brightness) {
    final blueScheme = ColorScheme.fromSeed(seedColor: Colors.blueAccent, brightness: brightness);

    blue = blueScheme.primary;
    onBlue = blueScheme.onPrimary;
    blueContainer = blueScheme.primaryContainer;
    onBlueContainer = blueScheme.onPrimaryContainer;
  }
}

extension CustomColors on ThemeData {
  ExtendedColors get extendedColors => ExtendedColors(brightness);
}