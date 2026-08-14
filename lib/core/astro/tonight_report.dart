/// Everything the tonight page shows, computed off the UI thread.
///
/// The satellite search is the reason this exists. Finding passes means
/// propagating SGP4 every thirty seconds across two days, twice over for the
/// sunlit test — tens of thousands of evaluations. Done inside `build()` that
/// is a visible freeze, and it would run again on every rebuild. `satellite.dart`
/// was deliberately kept free of Flutter so this can hand the whole search to
/// an isolate.
///
/// The result carries its own failure mode. A page that renders nothing is
/// ambiguous — no passes tonight, still loading, and the asset failed to load
/// all look the same — so [TonightReport] distinguishes them and the page says
/// which one it is.
library;

import 'dart:isolate';

import 'package:dpip/core/astro/astro_time.dart';
import 'package:dpip/core/astro/deep_sky.dart';
import 'package:dpip/core/astro/meteor_showers.dart';
import 'package:dpip/core/astro/night_window.dart';
import 'package:dpip/core/astro/satellite.dart';
import 'package:dpip/core/astro/sky_position.dart';
import 'package:dpip/core/astro/tle_source.dart';

/// Below this a deep-sky object is in the haze and the rooftops.
const double usableAltitude = 30 * degrees;

/// One pass, flattened for the UI.
class NamedPass {
  const NamedPass({required this.name, required this.pass});

  final String name;
  final SatellitePass pass;
}

/// A deep-sky object and how high it is at the reference time.
class TargetSighting {
  const TargetSighting({required this.object, required this.altitude});

  final DeepSkyObject object;
  final double altitude;
}

/// Tonight, resolved.
class TonightReport {
  const TonightReport({
    required this.night,
    required this.showers,
    required this.targets,
    required this.passes,
    required this.elementAge,
    required this.satellitesFailed,
  });

  final NightConditions night;
  final List<ShowerConditions> showers;
  final List<TargetSighting> targets;

  /// Visible passes, soonest first. Empty is a real answer: the station can
  /// spend days passing only in the Earth's shadow.
  final List<NamedPass> passes;

  /// How stale the bundled element set is. Null when it could not be read.
  final Duration? elementAge;

  /// The element set could not be loaded at all — almost always a missing
  /// asset after adding one without a full rebuild, which is worth saying out
  /// loud rather than rendering as "no passes".
  final bool satellitesFailed;

  /// Builds the whole report for [dayStart] (the UTC instant the local day
  /// begins) at one place.
  static Future<TonightReport> build(
    DateTime dayStart, {
    required DateTime now,
    required double latitude,
    required double longitude,
    TleSource source = const BundledTleSource(),
  }) async {
    final night = NightConditions.of(
      dayStart,
      latitude: latitude,
      longitude: longitude,
    );
    final observer = Observer(latitude: latitude, longitude: longitude);
    final reference =
        night.best?.from ?? dayStart.add(const Duration(hours: 22));

    final showers =
        MeteorShowerConditions.activeOn(now)
            .map(
              (shower) => MeteorShowerConditions.of(
                shower,
                now.year,
                latitude: latitude,
                longitude: longitude,
              ),
            )
            .toList()
          ..sort((a, b) => b.visibleRate.compareTo(a.visibleRate));

    final targets =
        messierCatalogue
            .map(
              (object) => TargetSighting(
                object: object,
                altitude: observer
                    .lookAt(object.positionAt(reference), reference)
                    .altitude,
              ),
            )
            .where((sighting) => sighting.altitude > usableAltitude)
            .toList()
          ..sort((a, b) => a.object.magnitude.compareTo(b.object.magnitude));

    List<TleSet> elements;
    try {
      elements = await source.load();
    } on Object {
      return TonightReport(
        night: night,
        showers: showers,
        targets: targets,
        passes: const [],
        elementAge: null,
        satellitesFailed: true,
      );
    }

    // The heavy part, and the only part that needs an isolate.
    final found = await Isolate.run(
      () => _search(elements, now, latitude, longitude),
    );

    return TonightReport(
      night: night,
      showers: showers,
      targets: targets,
      passes: found,
      elementAge: elements.isEmpty ? null : elements.first.ageAt(now),
      satellitesFailed: false,
    );
  }

  static List<NamedPass> _search(
    List<TleSet> elements,
    DateTime now,
    double latitude,
    double longitude,
  ) => [
    for (final tle in elements)
      for (final pass in SatellitePasses.find(
        Sgp4(tle),
        from: now,
        latitude: latitude,
        longitude: longitude,
        window: const Duration(hours: 48),
      ))
        NamedPass(name: tle.name, pass: pass),
  ]..sort((a, b) => a.pass.rises.compareTo(b.pass.rises));
}
