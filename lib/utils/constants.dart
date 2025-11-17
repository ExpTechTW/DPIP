import 'package:flutter/material.dart';

import 'package:maplibre_gl/maplibre_gl.dart';

/// Page transitions theme that uses zoom transitions with predictive back gesture support on Android.
///
/// This theme provides platform-specific page transitions:
/// - iOS: Uses the standard Cupertino page transitions
/// - Android: Uses predictive back page transitions for better gesture navigation support
const kZoomPageTransitionsTheme = PageTransitionsTheme(
  builders: {
    TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    TargetPlatform.android: PredictiveBackFullscreenPageTransitionsBuilder(),
  },
);

/// Page transitions theme that uses fade-forward transitions with predictive back gesture support on Android.
///
/// This theme provides platform-specific page transitions:
/// - iOS: Uses the standard Cupertino page transitions
/// - Android: Uses predictive back fade-forward page transitions for a smoother fade effect
const kFadeForwardPageTransitionsTheme = PageTransitionsTheme(
  builders: {
    TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
  },
);

/// Animation style that uses emphasized decelerate easing for smooth, natural-feeling animations.
///
/// This animation style uses Material Design 3's emphasized decelerate easing curve with medium duration
/// for forward animations and short duration for reverse animations. The emphasized curve provides a more
/// natural, physics-based animation feel compared to standard easing curves.
const kEmphasizedAnimationStyle = AnimationStyle(
  curve: Easing.emphasizedDecelerate,
  duration: Durations.medium4,
  reverseCurve: Easing.emphasizedDecelerate,
  reverseDuration: Durations.short4,
);

/// Duration for persistent snackbars that should remain visible for an extended period.
///
/// This duration is set to 365 days, effectively making snackbars persist until manually dismissed.
/// This is useful for displaying important information or error messages that users should acknowledge
/// before they disappear.
const kPersistSnackBar = Duration(days: 365);

/// MapLibre expression for symbol icon size that scales with zoom level.
///
/// This expression defines a linear interpolation for icon size based on map zoom level:
/// - At zoom level 5: icon size is 0.2
/// - At zoom level 15: icon size is 0.6
/// - Between zoom levels 5 and 15: size interpolates linearly
///
/// This ensures that symbol icons remain appropriately sized as users zoom in and out of the map.
const kSymbolIconSize = [
  Expressions.interpolate,
  ['linear'],
  [Expressions.zoom],
  5,
  0.2,
  15,
  0.6,
];

/// MapLibre expression for circle icon size that scales with zoom level.
///
/// This expression defines a linear interpolation for circle radius based on map zoom level:
/// - At zoom level 5: circle radius is 2
/// - At zoom level 15: circle radius is 12
/// - Between zoom levels 5 and 15: radius interpolates linearly
///
/// This ensures that circle markers remain appropriately sized as users zoom in and out of the map.
const kCircleIconSize = [
  Expressions.interpolate,
  ['linear'],
  [Expressions.zoom],
  5,
  2,
  15,
  12,
];
