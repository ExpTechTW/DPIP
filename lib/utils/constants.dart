import 'package:flutter/material.dart';

import 'package:maplibre_gl/maplibre_gl.dart';

import 'package:dpip/widgets/transitions/predictive_fade_forward.dart';

const kZoomPageTransitionsTheme = PageTransitionsTheme(
  builders: {
    TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
  },
);

const kFadeForwardPageTransitionsTheme = PageTransitionsTheme(
  builders: {
    TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    TargetPlatform.android: PredictiveBackFadeForwardPageTransitionsBuilder(),
  },
);

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
  0.2,
  15,
  0.6,
];

const kCircleIconSize = [
  Expressions.interpolate,
  ['linear'],
  [Expressions.zoom],
  5,
  2,
  15,
  12,
];
