/// How MapLibre turns an added image's pixels into points, and the one place
/// that difference is cancelled out.
///
/// `addImage` has no pixel-ratio argument in this fork, so every icon's
/// on-screen size is fixed by the density the platform records **with the
/// image**, and the two platforms disagree:
///
/// - **iOS** decodes at `UIScreen.main.scale` (`MapLibreMapController.swift`,
///   `style#addImage`), so a 64px badge is 64/3 ≈ 21pt on a 3x phone and 64pt
///   on a 1x display.
/// - **Android** decodes with `inDensity = 0`, which leaves the bitmap at
///   Android's default density (160dpi) and makes MapLibre's
///   `bitmap.getDensity() / 160` a pixel ratio of **1.0** on every device
///   (`MapLibreMapController.java`, `style#addImage`). A 64px badge therefore
///   lands at 64dp — three times the iPhone's.
///
/// So the same `icon-size` curve renders at three different physical sizes.
/// [mapIconDensityFactor] is the multiplier that cancels the platform's own
/// divisor, expressed against the size the design was drawn at: a 3x iPhone.
/// Multiply every pixel-based icon-size curve by it and the curve's numbers
/// mean dp/pt on both platforms, at every density.
library;

import 'dart:io';

import 'package:flutter/widgets.dart';

/// The image scale the icon-size curves were tuned against — a 3x iPhone.
///
/// Not a platform fact but a design decision: the badge sizes on a 3x iPhone
/// are the ones that shipped and looked right, so they are what every other
/// platform is brought to.
const double _referenceImageScale = 3;

/// The multiplier that turns a pixel-based `icon-size` curve into one expressed
/// in dp/pt.
///
/// `renderedPoints = artworkPixels × iconSize / platformDivisor`, so
/// `iconSize = curve × platformDivisor / referenceScale` renders
/// `artworkPixels × curve / referenceScale` **points** everywhere — the 3x
/// iPhone size — instead of on Android three times that.
///
/// The arguments exist to test the selection: `dart:io` `Platform` answers for
/// the machine the test runs on, and `PlatformDispatcher` in a widget test is
/// not a phone's. Production passes neither.
double mapIconDensityFactor({
  double? devicePixelRatio,
  bool? isIOS,
  bool? isAndroid,
}) {
  final ios = isIOS ?? Platform.isIOS;
  final android = isAndroid ?? Platform.isAndroid;
  if (!ios && !android) return 1;
  if (!ios) return 1 / _referenceImageScale; // Android's divisor is a fixed 1.
  final ratio = devicePixelRatio ?? _dispatcherPixelRatio();
  return ratio / _referenceImageScale;
}

double _dispatcherPixelRatio() {
  final views = WidgetsBinding.instance.platformDispatcher.views;
  return views.isEmpty ? _referenceImageScale : views.first.devicePixelRatio;
}

/// The zoom curve for the 64px intensity artwork — the 強震監視器's station
/// badges and the report map's town/epicentre markers, which were always drawn
/// at the same scale.
///
/// The numbers are a fraction of the artwork's pixels: 0.75 of 64px at zoom 5,
/// 1.7 at zoom 15. Multiply by [mapIconDensityFactor] to make them dp/pt.
List<Object> intensityIconSizeCurve(double densityFactor) => [
  'interpolate',
  ['linear'],
  ['zoom'],
  5,
  0.75 * densityFactor,
  15,
  1.7 * densityFactor,
];
