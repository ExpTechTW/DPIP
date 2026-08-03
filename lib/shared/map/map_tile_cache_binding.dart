/// Binds MapLibre's native HTTPS intercept to Dart [EtagCacheStore] + usage.
library;

import 'dart:async';

import 'package:dpip/core/network/etag_cache_store.dart';
import 'package:dpip/core/network/etag_interceptor.dart';
import 'package:dpip/core/network/network_usage_store.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

/// Installs the Dart tile-cache handler MapLibre calls on every tile URL.
///
/// Flow: native `get` → SQLite hit; miss → native fetch once → `put` (URL-hash
/// etag). [AmbientPrefetcher] is disabled so Dio does not race the same URLs.
Future<void> installMapLibreTileCache({
  required EtagCacheStore store,
  NetworkUsageStore? usage,
}) {
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
    put: (url, data, {String? contentType, String? etag}) async {
      final uri = Uri.tryParse(url);
      if (uri == null || !EtagInterceptor.isImmutableTile(uri)) return;
      final tag = EtagInterceptor.etagFromUrl(uri);
      await store.writeBytes(
        url,
        etag: tag,
        bytes: data,
        contentType: contentType,
        size: data.length,
      );
      unawaited(usage?.record(down: data.length, hit: false, saved: 0));
    },
  );
}
