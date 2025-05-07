import 'package:flutter/material.dart';

class ExtendedColors {
  late Color blue;
  late Color onBlue;
  late Color blueContainer;
  late Color onBlueContainer;
  late Color green;
  late Color onGreen;
  late Color greenContainer;
  late Color onGreenContainer;
  late Color amber;
  late Color onAmber;
  late Color amberContainer;
  late Color onAmberContainer;
  late Color grey;
  late Color onGrey;
  late Color greyContainer;
  late Color onGreyContainer;
  late Color brown;
  late Color onBrown;
  late Color brownContainer;
  late Color onBrownContainer;

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

    final amberScheme = ColorScheme.fromSeed(seedColor: Colors.amber, brightness: brightness);

    amber = amberScheme.primary;
    onAmber = amberScheme.onPrimary;
    amberContainer = amberScheme.primaryContainer;
    onAmberContainer = amberScheme.onPrimaryContainer;

    final greyScheme = ColorScheme.fromSeed(
      seedColor: Colors.grey,
      brightness: brightness,
      dynamicSchemeVariant: DynamicSchemeVariant.neutral,
    );

    grey = greyScheme.primary;
    onGrey = greyScheme.onPrimary;
    greyContainer = greyScheme.primaryContainer;
    onGreyContainer = greyScheme.onPrimaryContainer;

    final brownScheme = ColorScheme.fromSeed(seedColor: Colors.brown, brightness: brightness);

    brown = brownScheme.primary;
    onBrown = brownScheme.onPrimary;
    brownContainer = brownScheme.primaryContainer;
    onBrownContainer = brownScheme.onPrimaryContainer;
  }
}

extension CustomColors on ThemeData {
  ExtendedColors get extendedColors => ExtendedColors(brightness);
}
