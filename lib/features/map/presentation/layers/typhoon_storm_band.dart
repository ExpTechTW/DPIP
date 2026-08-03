/// Which storm-wind band combo is drawn — L7 and L10 are mutually exclusive.
library;

/// Purple fill + purple dashed avg (L7), or yellow fill + yellow dashed avg (L10).
enum TyphoonStormBand {
  /// `c15` four-quarter fill + `c15.avg` dashed ring.
  level7,

  /// `c25` four-quarter fill + `c25.avg` dashed ring.
  level10,
}
