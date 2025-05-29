import 'package:flutter/material.dart';

import 'package:maplibre_gl/maplibre_gl.dart';

const kEmphasizedAnimationStyle = AnimationStyle(
  curve: Easing.emphasizedDecelerate,
  duration: Durations.medium4,
  reverseCurve: Easing.emphasizedDecelerate,
  reverseDuration: Durations.short4,
);

const kPersistSnackBar = Duration(days: 365);

const kSymbolIconSize = [
  Expressions.interpolate,
  ['linear'],
  [Expressions.zoom],
  5,
  0.1,
  10,
  0.6,
];
