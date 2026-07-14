/// The four typhoon datasets that carry per-report history.
library;

/// A typhoon history dataset — the `/{kind}/…` path segment shared by the
/// `/{kind}/list` (available times) and `/{kind}/:time` (snapshot) endpoints.
enum TyphoonKind {
  /// Track (dataset 005).
  track,

  /// Track potential (dataset 002).
  potential,

  /// Strike probability (dataset 003).
  probability,

  /// Warning bulletin (dataset 001).
  warning;

  /// The URL path segment for this kind (identical to the enum name).
  String get path => name;
}
