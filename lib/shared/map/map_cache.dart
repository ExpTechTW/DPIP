/// Configures MapLibre's shared **ambient tile cache** — size ceiling + preload
/// of bytes fetched by the Flutter HTTP stack (ETag / SQLite) under the same
/// HTTPS URL MapLibre will request.
library;

import 'dart:io';

import 'package:dpip/core/logging/log.dart';
import 'package:flutter/services.dart';

/// Native ambient-cache bridge (iOS `MLNOfflineStorage` / Android `OfflineManager`).
class MapCache {
  const MapCache();

  static const MethodChannel _channel = MethodChannel(
    'com.exptech.dpip/map_cache',
  );

  static final GZipCodec _gzip = GZipCodec();

  /// Caps the shared ambient cache at [bytes], trimming (LRU) if already larger.
  Future<void> setMaximumSize(int bytes) async {
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

  /// Inserts [data] into ambient under [url] — same key MapLibre uses for HTTPS
  /// tile requests. [data] must be uncompressed (gzip magic is inflated here).
  Future<void> preload({
    required String url,
    required Uint8List data,
    String? etag,
    int modified = 0,
    int expires = 0,
    bool mustRevalidate = false,
  }) async {
    try {
      await _channel.invokeMethod<void>('preload', {
        'url': url,
        'data': _uncompressed(data),
        'etag': etag,
        'modified': modified,
        'expires': expires,
        'mustRevalidate': mustRevalidate,
      });
    } on MissingPluginException {
      // Platform without the handler.
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'MapCache.preload');
    }
  }

  static Uint8List _uncompressed(Uint8List data) {
    if (data.length >= 2 && data[0] == 0x1f && data[1] == 0x8b) {
      return Uint8List.fromList(_gzip.decode(data));
    }
    return data;
  }
}
