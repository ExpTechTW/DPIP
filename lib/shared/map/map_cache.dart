/// Sizes MapLibre's own **ambient tile database** (iOS `MLNOfflineStorage` /
/// Android `OfflineManager`) — which this app keeps switched off.
library;

import 'package:dpip/core/logging/log.dart';
import 'package:flutter/services.dart';

/// Native ambient-cache bridge.
///
/// MapLibre keeps its own on-disk cache of everything it downloads. This app
/// **disables it** ([disabledBytes]) and serves those bytes from
/// [EtagCacheStore] through the Dart bridge instead, because two disk caches of
/// the same tiles meant ~214 MB for one copy's worth of content and only one of
/// them was visible to the app's eviction policy and traffic accounting. The
/// native default (~50 MB) applies if this is never called, so it must be.
///
/// Nothing is lost by turning it off: glyphs are in the app's store too, and
/// the in-process mirror in front of the bridge is what actually keeps IPC off
/// the hot path — the ambient database was only ever a second copy behind it.
class MapCache {
  const MapCache();

  static const MethodChannel _channel = MethodChannel(
    'com.exptech.dpip/map_cache',
  );

  /// A zero ceiling disables ambient caching outright on both platforms.
  static const int disabledBytes = 0;

  /// Caps the shared ambient cache at [bytes], trimming (LRU) if already larger.
  Future<void> setMaximumSize([int bytes = disabledBytes]) async {
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
