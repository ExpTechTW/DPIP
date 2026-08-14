/// Where element sets come from.
///
/// Split from the propagator on purpose. `satellite.dart` is pure Dart with no
/// Flutter dependency — it can be unit-tested against the published SGP4
/// vectors and run in an isolate — while the question of *which* elements to
/// use is a data-freshness problem, and belongs here.
///
/// The bundled file is a snapshot taken at build time. That is the honest
/// default for an app whose premise is working without a network, but it is
/// also the one part of `astro/` that decays: element sets are good for days.
/// [TleSource.bundled] therefore reports the snapshot's epoch, so a caller can
/// show the age rather than present a month-old prediction as a fact. Swapping
/// in a fresher source is a matter of implementing [TleSource].
library;

import 'package:dpip/core/astro/satellite.dart';
import 'package:flutter/services.dart' show rootBundle;

/// A supply of two-line element sets.
abstract interface class TleSource {
  Future<List<TleSet>> load();
}

/// The snapshot shipped with the app.
class BundledTleSource implements TleSource {
  const BundledTleSource();

  @override
  Future<List<TleSet>> load() async => TleSet.parseAll(
    await rootBundle.loadString('assets/astro/satellites.tle'),
  );
}
