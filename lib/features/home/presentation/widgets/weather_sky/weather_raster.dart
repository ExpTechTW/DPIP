/// Picture rasters for the card-water and glass effects.
///
/// The frame path goes through [rasterizePicture] ([Picture.toImage]), which
/// finishes on the raster thread. [rasterizePictureSync] is the one-shot
/// helper the glass field test still uses; a frame that did not step the
/// 20 ms solver must not call it. The counters exist so a widget test can
/// say that per frame.
library;

import 'dart:ui' show Picture, Image;

import 'package:flutter/foundation.dart';

/// Calls to [rasterizePictureSync] since the last [debugResetWeatherRasterCounts].
@visibleForTesting
int debugWeatherToImageSyncCount = 0;

/// Calls to [rasterizePicture] since the last [debugResetWeatherRasterCounts].
@visibleForTesting
int debugWeatherToImageCount = 0;

/// 20 ms solver steps the card-water and glass tickers have observed.
@visibleForTesting
int debugWeatherSolverSteps = 0;

/// Rasters started from a ticker callback that had just stepped. A follow-up
/// bake that only catches up after an in-flight raster does not count, and a
/// frame with no solver step must not either.
@visibleForTesting
int debugWeatherTickRasters = 0;

/// Zeroes the counters. Tests call this after the shaders have loaded.
@visibleForTesting
void debugResetWeatherRasterCounts() {
  debugWeatherToImageSyncCount = 0;
  debugWeatherToImageCount = 0;
  debugWeatherSolverSteps = 0;
  debugWeatherTickRasters = 0;
}

/// Counts [n] solver steps. The widgets call this; the counter itself stays
/// visible to tests only.
void noteWeatherSolverSteps(int n) {
  debugWeatherSolverSteps += n;
}

/// Counts a raster that a ticker started because the solver had just stepped.
/// A follow-up that only catches up after an in-flight raster must not.
void noteWeatherTickRaster() {
  debugWeatherTickRasters++;
}

/// Rasterizes [picture] off the UI thread. The picture may be disposed as
/// soon as this returns: the engine copies the display list into the raster
/// task before the call comes back.
Future<Image> rasterizePicture(Picture picture, int width, int height) {
  debugWeatherToImageCount++;
  return picture.toImage(width, height);
}

/// Synchronous raster. Counts toward [debugWeatherToImageSyncCount].
Image rasterizePictureSync(Picture picture, int width, int height) {
  debugWeatherToImageSyncCount++;
  return picture.toImageSync(width, height);
}
