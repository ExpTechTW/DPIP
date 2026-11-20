/// Region-host arithmetic for the map tiles MapLibre fetches by absolute URL:
/// the key a tile is cached under, and the route a Dart-side fetch of it
/// fails over along.
///
/// A tile URL names one region host because MapLibre needs one template per
/// source. The tile itself does not belong to that host: every region of a
/// family carries the same bytes at the same path. Both functions here undo
/// the host so the rest of the app never has to.
library;

import 'package:dpip/core/network/api_paths.dart';
import 'package:dpip/core/network/api_region.dart';

/// The tier and path a tile is fetched along when its host fails, and whether
/// a 404 moves on to the next region too (`ApiClient.request`'s
/// `notFoundFailsOver`) — see [tileRoute].
typedef TileRoute = ({ApiTier tier, String path, bool notFoundFailsOver});

/// Region hosts that serve the same tiles.
final class _TileFamily {
  const _TileFamily({
    required this.origins,
    required this.keyOrigin,
    required this.tier,
    required this.replicatedPaths,
    required this.notFoundFailsOver,
  });

  /// Every region origin of the family — the hosts `ApiClient.hostsFor(tier)`
  /// returns, in any order.
  final List<String> origins;

  /// The origin a tile of this family is cached under.
  final String keyOrigin;

  /// The tier `ApiClient` fails over along for this family.
  final ApiTier tier;

  /// Path prefixes every origin carries. A path outside them exists on one
  /// region only, so it has nowhere to fail over to.
  final List<String> replicatedPaths;

  /// Whether one region can lack a tile the other holds, so a 404 is worth
  /// asking the next region about rather than the answer.
  final bool notFoundFailsOver;

  bool replicates(String path) {
    for (final prefix in replicatedPaths) {
      if (path.startsWith(prefix)) return true;
    }
    return false;
  }
}

/// Core static: radar, QPESUMS and DPM are copied to both core regions;
/// satellite and wind (same hosts) exist on `core-tnn1` only.
///
/// Each frame is an immutable item per timestamp, and each core region keeps
/// its own history, so an outage can leave a gap in one of them. The backend
/// answers a frame a region lacks with **500**, not 404 (both regions,
/// 2026-11-28), so a gap fails over as the retryable error it is.
/// `notFoundFailsOver` is set all the same: a missing frame is still worth
/// asking the other region about should the backend start saying 404.
///
/// Cached under `static.core-tnn1`. Before radar, QPESUMS and DPM tiles came
/// from both regions they came from tnn1 alone, so every row an installed app
/// already holds is a tnn1 URL — keying both regions on tnn1 keeps those rows
/// answering after the update, whichever region is selected. Satellite and
/// wind live on tnn1 as well, so the whole family keys on the one name.
final _TileFamily _coreStatic = _TileFamily(
  origins: [
    for (final region in CoreRegion.values)
      'https://static.core-${region.code}.exptech.dev',
  ],
  keyOrigin: 'https://static.core-${CoreRegion.tnn1.code}.exptech.dev',
  tier: ApiTier.coreStatic,
  replicatedPaths: const [
    '${ApiPaths.tiles}/radar/',
    '${ApiPaths.tiles}/qpesums/',
    '${ApiPaths.dpm}/',
  ],
  notFoundFailsOver: true,
);

final List<_TileFamily> _families = [_coreStatic];

/// The origin of [family] that [url] is under, or null.
String? _originOf(_TileFamily family, String url) {
  for (final origin in family.origins) {
    // `/` after the origin, so `static.core-tnn1.exptech.dev.evil` is not it.
    if (url.length > origin.length &&
        url.startsWith(origin) &&
        url.codeUnitAt(origin.length) == 0x2F) {
      return origin;
    }
  }
  return null;
}

/// The URL [url] is cached under.
///
/// A tile on any region host of a family maps to one key, so the copy one
/// region served is the copy every region's URL reads back: switching region
/// does not re-download the map, and a tile fetched from the other region
/// during a failover is found under the URL MapLibre asked for. Anything else
/// is its own key.
///
/// Only for content-addressed tiles — the URL pins the bytes, so any host's
/// copy is the same copy. A response revalidated by ETag must keep its own
/// URL: each region's server mints its own validators.
String tileCacheKey(String url) {
  for (final family in _families) {
    final origin = _originOf(family, url);
    if (origin == null) continue;
    if (origin == family.keyOrigin) return url;
    return '${family.keyOrigin}${url.substring(origin.length)}';
  }
  return url;
}

/// The tier and path to fetch [url] along so a failed host fails over to the
/// same path on the family's other region, or null when [url] has no second
/// copy — not a region host, or a path only one region carries.
TileRoute? tileRoute(String url) {
  for (final family in _families) {
    final origin = _originOf(family, url);
    if (origin == null) continue;
    final path = url.substring(origin.length);
    return family.replicates(path)
        ? (
            tier: family.tier,
            path: path,
            notFoundFailsOver: family.notFoundFailsOver,
          )
        : null;
  }
  return null;
}
