/// Load-balanced (Taiwan edge) regions.
///
/// Services on the LB tier are **multi-active**: a request may fail over from
/// the selected region to the other.
enum LbRegion {
  /// Taipei.
  tpe1('tpe1', 'Taipei'),

  /// Kaohsiung.
  khh1('khh1', 'Kaohsiung');

  const LbRegion(this.code, this.label);

  /// Region code as used in the host name (`api.lb-<code>.exptech.dev`).
  final String code;

  /// Human-readable label for settings UI.
  final String label;
}

/// Core service regions.
///
/// Most core services run in both regions (multi-active), but some exist
/// **only** in [tnn1] — see [ApiTier.coreExclusiveApi].
enum CoreRegion {
  /// Tainan.
  tnn1('tnn1', 'Tainan'),

  /// Tokyo.
  tyo1('tyo1', 'Tokyo');

  const CoreRegion(this.code, this.label);

  /// Region code as used in the host name (`api.core-<code>.exptech.dev`).
  final String code;

  /// Human-readable label for settings UI.
  final String label;
}

/// The origin for the region-pinned LB static host — `static.lb-<code>`, the
/// host [ApiTier.lbStatic] resolves to for that region.
///
/// For the URLs a MapLibre style names, which need one host per template.
/// Basemap, terrain and OSM used to name the bare `static.lb.exptech.dev`,
/// which balances without regard for the region the rest of the app selected,
/// so a client could draw every tile from the far end while its API traffic
/// came from the near one. Both hosts carry the same dataset; the pin is about
/// one honest selection, not about which copy exists. When the pinned host
/// fails, the app fetches the tile along [ApiTier.lbStatic] instead
/// (`MapTileCache`), and either copy is stored under the bare name
/// (`tileCacheKey`).
String staticLbOrigin(LbRegion region) =>
    'https://static.lb-${region.code}.exptech.dev';

/// The host family and redundancy a request targets.
///
/// Only concrete, region-pinned hosts are ever used; the DNS-balanced bare
/// hosts (`api.lb.exptech.dev`, `api.core.exptech.dev`) are deliberately never
/// requested **for tiered traffic**, so region selection and failover stay
/// under app control.
///
/// The map tiles a MapLibre style names are pinned the same way, without a
/// tier in between: a style needs one host per template, so it names the
/// selected region's ([staticLbOrigin] for the basemap, the first
/// [coreStatic] host for radar and DPM). When that host fails, the app fetches
/// the tile itself along [lbStatic] / [coreStatic]
/// (`ApiClient.getTileBytes`).
///
/// The HTTP time fallback in `core/realtime/http_time_source.dart` is pinned
/// by region too, without being an [ApiTier] request: it builds its hosts from
/// the selected region's order and tries each in turn, but never through
/// `ApiClient`, whose ETag cache must not hold a clock reading.
enum ApiTier {
  /// LB API — multi-active across [LbRegion]s (`api.lb-{tpe1,khh1}`).
  lbApi,

  /// LB static assets — multi-active across [LbRegion]s.
  lbStatic,

  /// Core API — multi-active across [CoreRegion]s (`api.core-{tyo1,tnn1}`).
  coreApi,

  /// Core static assets — multi-active across [CoreRegion]s.
  coreStatic,

  /// Core API available **only** in [CoreRegion.tnn1]. No failover.
  coreExclusiveApi,

  /// Core **static** assets available **only** in [CoreRegion.tnn1]
  /// (`static.core-tnn1`). No failover — e.g. the v2 satellite and wind WebP
  /// tiles.
  coreStaticExclusive,

  /// Legacy single host `api-1.exptech.dev`. No region, no failover — used by
  /// endpoints not yet migrated to the region topology. As the backend
  /// migrates them, move each to [coreExclusiveApi] (or a redundant tier).
  legacyApi;

  /// Whether this tier has multi-active redundancy (failover across regions).
  bool get isRedundant =>
      this == lbApi ||
      this == lbStatic ||
      this == coreApi ||
      this == coreStatic;
}
