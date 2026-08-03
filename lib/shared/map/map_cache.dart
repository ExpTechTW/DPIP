/// Sizes MapLibre's own **ambient tile database** (iOS `MLNOfflineStorage` /
/// Android `OfflineManager`).
library;

import 'package:dpip/core/logging/log.dart';
import 'package:flutter/services.dart';

/// Native ambient-cache bridge.
///
/// This is the *hot* tier and it is MapLibre's, not the app's: responses it has
/// already downloaded are answered from here without a request ever reaching
/// the app. Tiles are served with an immutable `Cache-Control` (their URLs are
/// content-addressed), so this tier does real work — before that they were
/// treated as expired and re-requested on every reveal.
///
/// The durable tier is the app's own [EtagCacheStore] (~150 MB, metered, swept
/// on the app's policy), which is what [MapTileCache] warms from. So this one
/// is deliberately smaller: it only has to hold the frames of the session in
/// progress, and sizing both at 150 MB just spent 300 MB storing each tile
/// twice.
class MapCache {
  const MapCache();

  static const MethodChannel _channel = MethodChannel(
    'com.exptech.dpip/map_cache',
  );

  /// Ambient ceiling shared by every map surface. Native's own default (~50 MB)
  /// is too small to hold a scrubbed radar loop.
  static const int defaultAmbientBytes = 64 * 1024 * 1024;

  /// Caps the shared ambient cache at [bytes], trimming (LRU) if already larger.
  Future<void> setMaximumSize([int bytes = defaultAmbientBytes]) async {
    try {
      await _channel.invokeMethod<void>('setMaximumAmbientCacheSize', {
        'bytes': bytes,
      });
    } on MissingPluginException {
      // Platform without the handler.
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'setMaximumAmbientCacheSize');
    }
  }
}
