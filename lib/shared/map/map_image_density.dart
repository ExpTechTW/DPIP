/// How MapLibre turns an added image's pixels into points, and the one place
/// that difference is cancelled out.
///
/// `addImage` has no pixel-ratio argument in this fork, so every icon's
/// on-screen size is fixed by the density recorded on the bitmap. MapLibre
/// Android turns that into a pixel ratio with `bitmap.getDensity() / 160`
/// (`Style.toImage`). The two platforms record the density differently:
///
/// - **iOS** decodes at `UIScreen.main.scale` (`MapLibreMapController.swift`,
///   `style#addImage`), so a 64px badge is 64/3 ≈ 21pt on a 3x phone and 64pt
///   on a 1x display.
/// - **Android** decodes with `inScaled = false`, `inDensity = 0` and
///   `inTargetDensity = 0` (`MapLibreMapController.java`, `style#addImage`)
///   so the pixels are not resampled. The icon-size curve used to multiply by
///   a fixed `1/3`, which cancels the divisor only when that pixel ratio is 1
///   — an mdpi panel, and the 540×960 emulator this was tuned on. On a denser
///   phone the bitmap density follows the display, so the same `1/3` shrinks
///   the badge by the screen scale a second time. That is the report map on a
///   1080×2340 device: the town digits are still there, and too small to read.
///
/// [mapIconDensityFactor] cancels the platform divisor against the size the
/// design was drawn at: a 3x iPhone. On both phones the divisor is the screen
/// scale. Multiply every pixel-based icon-size curve by the factor and the
/// curve's numbers mean dp/pt at every density.
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
/// `artworkPixels × curve / referenceScale` points everywhere — the 3x
/// iPhone size.
///
/// On both phones the divisor is the screen scale: iOS records
/// `UIScreen.main.scale` on the image, Android records the display density
/// and MapLibre divides it by 160. Pass [devicePixelRatio] from the widget
/// tree when there is one; production otherwise reads the dispatcher. The
/// report map already passes the ratio it measured.
///
/// The arguments exist to test the selection: `dart:io` `Platform` answers for
/// the machine the test runs on, and `PlatformDispatcher` in a widget test is
/// not a phone's. Production passes neither, except the report map, which
/// passes the ratio.
double mapIconDensityFactor({
  double? devicePixelRatio,
  bool? isIOS,
  bool? isAndroid,
}) {
  final ios = isIOS ?? Platform.isIOS;
  final android = isAndroid ?? Platform.isAndroid;
  if (!ios && !android) return 1;
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
