import 'package:dpip/core/logging/log.dart';
import 'package:flutter/services.dart';

/// Configures MapLibre's shared **ambient tile cache** — the on-disk store the
/// live map and the home snapshot both read.
///
/// `maplibre_gl` 0.25.0 wraps `clearAmbientCache` but not a size bound, and the
/// native default ceiling is only ~50 MB, so this drives the native
/// `MLNOfflineStorage` (iOS) / `OfflineManager` (Android)
/// `setMaximumAmbientCacheSize` directly to raise it — more radar frames stay
/// cached, so scrubbing the timeline re-fetches far less. Call once the map
/// exists (MapLibre is then initialised on both platforms). A missing native
/// handler degrades to a no-op: caching still works at the default size.
class MapCache {
  const MapCache();

  static const MethodChannel _channel = MethodChannel(
    'com.exptech.dpip/map_cache',
  );

  /// Caps the shared ambient cache at [bytes], trimming (LRU) if it is already
  /// larger. Best-effort — a failure just leaves the default ceiling in place.
  Future<void> setMaximumSize(int bytes) async {
    try {
      await _channel.invokeMethod<void>('setMaximumAmbientCacheSize', {
        'bytes': bytes,
      });
    } on MissingPluginException {
      // Platform without the handler — cache stays at its native default size.
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'setMaximumAmbientCacheSize');
    }
  }
}
