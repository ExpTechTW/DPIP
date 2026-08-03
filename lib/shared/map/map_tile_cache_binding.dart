/// Binds MapLibre's native HTTPS intercept to Dart [EtagCacheStore].
library;

import 'package:dpip/core/network/etag_cache_store.dart';
import 'package:dpip/core/network/etag_interceptor.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

/// Installs the Dart tile-cache handler MapLibre calls on every tile URL.
///
/// Native only **gets** from Dart (never fetches ExpTech tiles itself). SQLite
/// (+ pager cache) and binary-hit metering stay in Dart. Channel `put` is a
/// no-op — Dio / AmbientPrefetch owns writes.
Future<void> installMapLibreTileCache({required EtagCacheStore store}) {
  return bindMapLibreTileCache(
    get: (url) async {
      final uri = Uri.tryParse(url);
      if (uri == null || !EtagInterceptor.isImmutableTile(uri)) return null;
      final hit = await store.readBytes(url);
      if (hit == null) return null;
      // Hit metering is inside [EtagCacheStore.readBytes] — do not double-count.
      return <String, Object?>{
        'data': hit.bytes,
        'contentType': hit.contentType,
        'etag': hit.etag,
      };
    },
    put: (url, data, {String? contentType, String? etag}) async {},
  );
}
