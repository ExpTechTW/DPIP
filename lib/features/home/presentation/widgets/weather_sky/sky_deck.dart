import 'dart:async';
import 'dart:ui' as ui;

import 'package:dpip/core/logging/log.dart';
import 'package:dpip/features/home/presentation/widgets/weather_sky/sky_clouds.dart';
import 'package:flutter/material.dart';

/// Fraction of the on-screen widget the cloud deck is rasterized at.
///
/// The rest of the sky is 0.75 (0.6 on the low tier). Clouds are a handful of
/// sprites, each wider than the sheet and each an 8-tap shader, and they only
/// drift a few percent of the screen per second, so a softer deck is the
/// expensive part to shrink. 0.4 is where the upscale stays a soft edge
/// rather than a block: the pixel check against a same-time full-resolution
/// deck lives with the sky-deck test.
const double kSkyDeckScale = 0.4;

/// How often the deck is re-rasterized. 12 fps is inside the 10–15 fps band.
/// Between rasters the last image is translated by the drift, so the motion
/// on screen is still the 60 fps clock.
const double kSkyDeckPeriod = 1 / 12;

/// Extra width, as a fraction of the view, painted on each side of the deck.
///
/// The cached image is slid sideways until the next raster. The margin is the
/// fastest cloud's travel over two periods (one period of drift, plus a
/// raster that is still in flight), so the slide never shows the buffer edge.
/// Rain in a storm is the fast end: about 0.10 screen-widths per second, and
/// two periods of that is under 0.02.
const double kSkyDeckMargin = 0.03;

/// A lightning flash jumps, it does not drift. A change this large rebakes
/// the deck on the next frame so the clouds light with the bolt instead of a
/// twelfth of a second late. Smaller flicker stays on the 12 fps clock.
const double kSkyDeckFlashStep = 0.2;

/// Rasters of the cloud deck started since [debugResetSkyDeckRenders].
@visibleForTesting
int debugSkyDeckRenders = 0;

/// Zeroes [debugSkyDeckRenders].
@visibleForTesting
void debugResetSkyDeckRenders() {
  debugSkyDeckRenders = 0;
}

/// Whether the deck should be rasterized again at [time].
///
/// [inFlight] holds the decision off: a second picture would queue another
/// GPU raster for a deck that has not moved enough to need one. A NaN
/// [bakedTime] is "never", and [contentChanged] is a resize, a new cloud
/// layout, or a lightning step.
bool skyDeckDue({
  required double time,
  required double bakedTime,
  required bool inFlight,
  required bool contentChanged,
}) {
  if (inFlight) return false;
  if (bakedTime.isNaN || contentChanged) return true;
  return time - bakedTime >= kSkyDeckPeriod;
}

/// Mean horizontal drift of [layout], in screen-widths per second.
///
/// Each cloud has its own parallax (`windSpeed * (1.6 - depth)` in
/// [placeClouds]). One translation cannot follow all of them; the mean is
/// the slide applied to the cached image, and the leftover per cloud over
/// one period is a couple of pixels even in a storm.
double skyDeckDrift(CloudLayout layout, double wind) {
  final clouds = layout.clouds;
  if (clouds.isEmpty) return 0;
  final windSpeed = layout.speed * (1.0 + wind * 2.0);
  var sum = 0.0;
  for (final cloud in clouds) {
    sum += windSpeed * (1.6 - cloud.depth);
  }
  return sum / clouds.length;
}

/// The cloud deck, rasterized at [kSkyDeckScale] and [kSkyDeckPeriod].
///
/// The painter composites [image] every frame and translates it by the drift
/// since [bakedTime]. The picture is recorded only when [skyDeckDue] says so,
/// and the raster runs off the UI thread. The image one generation back stays
/// alive so the frame still on the GPU can finish sampling it.
class SkyDeck {
  ui.Image? _image;
  ui.Image? _retired;
  double _bakedTime = double.nan;
  double _bakedFlash = 0;
  double _bakedCoverage = -1;
  double _bakedViewWidth = 0;
  double _bakedViewHeight = 0;
  double _bakedDpr = 0;
  CloudLayout? _bakedLayout;
  double _margin = 0;
  double _deckViewWidth = 0;
  double _deckViewHeight = 0;
  bool _inFlight = false;
  bool _closed = false;
  int _generation = 0;

  static final Paint _blit = Paint()..filterQuality = FilterQuality.low;

  /// Whether a deck image is ready to composite. The resolution check waits
  /// on this rather than racing the raster.
  @visibleForTesting
  bool get debugHasImage => _image != null;

  /// Draws the current deck and, when it is due, records the next one.
  ///
  /// [view] is the painter's canvas (the 0.75 / 0.6 buffer), in logical
  /// pixels. [renderScale] is that buffer's fraction of the widget.
  /// [devicePixelRatio] is applied when the picture is recorded: the canvas
  /// is later rasterized at that ratio, and [ui.Picture.toImage] is not, so
  /// without it the deck would be 0.4 of the logical size and about 0.15 of
  /// a 2.6× screen. [paintClouds] is the live cloud pass. It is called with
  /// the deck's own pixel size, and until the first image arrives it is also
  /// called with [view] so the opening frame is not a hole.
  void present({
    required Canvas canvas,
    required Size view,
    required double renderScale,
    required double devicePixelRatio,
    required double time,
    required CloudLayout layout,
    required double wind,
    required double coverage,
    required double flash,
    required void Function(Canvas canvas, Size size) paintClouds,
  }) {
    if (coverage < 0.02 || view.isEmpty || renderScale <= 0) return;
    final dpr = devicePixelRatio < 1 ? 1.0 : devicePixelRatio;
    final image = _image;
    if (image != null) {
      _blitDeck(canvas, view, time, layout, wind);
    } else {
      paintClouds(canvas, view);
    }
    if (!skyDeckDue(
      time: time,
      bakedTime: _bakedTime,
      inFlight: _inFlight,
      contentChanged: _contentChanged(view, layout, coverage, flash, dpr),
    )) {
      return;
    }
    _start(
      view,
      renderScale,
      dpr,
      time,
      layout,
      wind,
      coverage,
      flash,
      paintClouds,
    );
  }

  bool _contentChanged(
    Size view,
    CloudLayout layout,
    double coverage,
    double flash,
    double devicePixelRatio,
  ) {
    if (!identical(layout, _bakedLayout)) return true;
    if ((coverage - _bakedCoverage).abs() > 0.001) return true;
    if ((flash - _bakedFlash).abs() > kSkyDeckFlashStep) return true;
    if ((devicePixelRatio - _bakedDpr).abs() > 0.01) return true;
    if ((view.width - _bakedViewWidth).abs() > 2) return true;
    if ((view.height - _bakedViewHeight).abs() > 2) return true;
    return false;
  }

  void _blitDeck(
    Canvas canvas,
    Size view,
    double time,
    CloudLayout layout,
    double wind,
  ) {
    final image = _image;
    if (image == null || _deckViewWidth <= 0 || _deckViewHeight <= 0) return;
    final dt = _bakedTime.isNaN
        ? 0.0
        : (time - _bakedTime).clamp(0.0, kSkyDeckPeriod * 2);
    final shift = (skyDeckDrift(layout, wind) * dt * _deckViewWidth).clamp(
      -_margin,
      _margin,
    );
    var srcLeft = _margin - shift;
    final srcWidth = _deckViewWidth;
    final srcHeight = _deckViewHeight;
    if (srcLeft < 0) srcLeft = 0;
    final limit = image.width - srcWidth;
    if (limit > 0 && srcLeft > limit) srcLeft = limit;
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(srcLeft, 0, srcWidth, srcHeight),
      Offset.zero & view,
      _blit,
    );
  }

  void _start(
    Size view,
    double renderScale,
    double devicePixelRatio,
    double time,
    CloudLayout layout,
    double wind,
    double coverage,
    double flash,
    void Function(Canvas canvas, Size size) paintClouds,
  ) {
    // view is `widget * renderScale` logical pixels. Multiply by the device
    // pixel ratio so the image is [kSkyDeckScale] of the physical screen,
    // then drawImageRect maps it back onto the logical canvas. The outer
    // transform scales that canvas up to the widget; this ratio cancels.
    final pixelScale = kSkyDeckScale / renderScale * devicePixelRatio;
    final deckView = Size(view.width * pixelScale, view.height * pixelScale);
    if (deckView.width < 1 || deckView.height < 1) return;
    final margin = deckView.width * kSkyDeckMargin;
    final width = (deckView.width + 2 * margin).ceil();
    final height = deckView.height.ceil();
    final recorder = ui.PictureRecorder();
    final recording = Canvas(recorder);
    recording.translate(margin, 0);
    paintClouds(recording, deckView);
    final picture = recorder.endRecording();
    _inFlight = true;
    debugSkyDeckRenders++;
    final generation = ++_generation;
    final future = picture.toImage(width, height);
    picture.dispose();
    unawaited(
      _finish(
        future,
        generation,
        time: time,
        flash: flash,
        coverage: coverage,
        layout: layout,
        view: view,
        margin: margin,
        deckView: deckView,
        devicePixelRatio: devicePixelRatio,
      ),
    );
  }

  Future<void> _finish(
    Future<ui.Image> future,
    int generation, {
    required double time,
    required double flash,
    required double coverage,
    required CloudLayout layout,
    required Size view,
    required double margin,
    required Size deckView,
    required double devicePixelRatio,
  }) async {
    ui.Image? image;
    try {
      image = await future;
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'sky deck raster failed');
    }
    _inFlight = false;
    if (_closed || generation != _generation || image == null) {
      image?.dispose();
      return;
    }
    _retired?.dispose();
    _retired = _image;
    _image = image;
    _bakedTime = time;
    _bakedFlash = flash;
    _bakedCoverage = coverage;
    _bakedLayout = layout;
    _bakedViewWidth = view.width;
    _bakedViewHeight = view.height;
    _bakedDpr = devicePixelRatio;
    _margin = margin;
    _deckViewWidth = deckView.width;
    _deckViewHeight = deckView.height;
  }

  /// Drops both images. An in-flight raster is discarded when it lands.
  void dispose() {
    _closed = true;
    _generation++;
    _image?.dispose();
    _retired?.dispose();
    _image = null;
    _retired = null;
  }
}
