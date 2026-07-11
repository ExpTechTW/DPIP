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

/// The host family and redundancy a request targets.
///
/// Only concrete, region-pinned hosts are ever used; the DNS-balanced bare
/// hosts (`api.lb.exptech.dev`, `api.core.exptech.dev`) are deliberately never
/// requested so region selection and failover stay under app control.
enum ApiTier {
  /// LB API — multi-active across [LbRegion]s.
  lbApi,

  /// LB static assets — multi-active across [LbRegion]s.
  lbStatic,

  /// Core API — multi-active across [CoreRegion]s.
  coreApi,

  /// Core static assets — multi-active across [CoreRegion]s.
  coreStatic,

  /// Core API available **only** in [CoreRegion.tnn1]. No failover.
  coreExclusiveApi;

  /// Whether this tier has multi-active redundancy (failover across regions).
  bool get isRedundant => this != coreExclusiveApi;
}
