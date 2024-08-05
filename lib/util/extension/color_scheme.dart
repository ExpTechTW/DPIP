import "package:flutter/material.dart";

class ExtendedColors {
  late Color blue;
  late Color onBlue;
  late Color blueContainer;
  late Color onBlueContainer;
  late Color green;
  late Color onGreen;
  late Color greenContainer;
  late Color onGreenContainer;

  ExtendedColors(Brightness brightness) {
    final blueScheme = ColorScheme.fromSeed(seedColor: Colors.blueAccent, brightness: brightness);

    blue = blueScheme.primary;
    onBlue = blueScheme.onPrimary;
    blueContainer = blueScheme.primaryContainer;
    onBlueContainer = blueScheme.onPrimaryContainer;

    final greenScheme = ColorScheme.fromSeed(seedColor: Colors.green, brightness: brightness);

    green = greenScheme.primary;
    onGreen = greenScheme.onPrimary;
    greenContainer = greenScheme.primaryContainer;
    onGreenContainer = greenScheme.onPrimaryContainer;
  }
}

extension CustomColors on ThemeData {
  ExtendedColors get extendedColors => ExtendedColors(brightness);
}
