/// A chart of the sky above you, right now.
///
/// Stereographic from the zenith: the projection every planisphere uses,
/// because it keeps shapes locally true — a constellation near the horizon is
/// stretched but still recognisable, which a plain equal-area or orthographic
/// projection cannot manage.
///
/// The whole chart is one repaint of one painter. 5,000 stars, 150
/// constellation strokes, the planets and the Moon are all drawn from data
/// already in memory, so the only cost is the projection arithmetic.
///
/// North is at the top and **east is on the left**, which looks backwards on
/// paper and is correct on the sky: you are looking up at it, not down at a
/// map.
library;

import 'dart:math' as math;

import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/astro/deep_sky.dart';
import 'package:dpip/core/astro/moon_ephemeris.dart';
import 'package:dpip/core/astro/planet_ephemeris.dart';
import 'package:dpip/core/astro/sky_position.dart';
import 'package:dpip/core/astro/star_catalog.dart';
import 'package:dpip/core/realtime/app_time.dart';
import 'package:dpip/features/data/presentation/observer_place.dart';
import 'package:dpip/features/data/presentation/pages/planets_page.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';

class SkyChartPage extends StatefulWidget {
  const SkyChartPage({super.key});

  @override
  State<SkyChartPage> createState() => _SkyChartPageState();
}

class _SkyChartPageState extends State<SkyChartPage> {
  StarCatalog? _catalog;
  Object? _error;

  @override
  void initState() {
    super.initState();
    StarCatalog.load()
        .then((catalog) {
          if (mounted) setState(() => _catalog = catalog);
        })
        // A missing asset must not leave a spinner turning forever — that is
        // indistinguishable from slow, and the usual cause is adding an asset
        // without a full rebuild.
        .catchError((Object error) {
          if (mounted) setState(() => _error = error);
        });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final town = observerTown(context);
    final now = AppTime.utc;
    final catalog = _catalog;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.skyChartTitle)),
      body: ListView(
        padding: EdgeInsets.only(
          bottom: AppSpacing.xl + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: AspectRatio(
              aspectRatio: 1,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Color(0xFF10182E), Color(0xFF04060D)],
                  ),
                ),
                child: _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          child: Text(
                            l10n.skyChartUnavailable,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.white70),
                          ),
                        ),
                      )
                    : catalog == null || town == null
                    ? const Center(
                        child: SizedBox.square(
                          dimension: 32,
                          child: CircularProgressIndicator(strokeWidth: 3),
                        ),
                      )
                    : CustomPaint(
                        painter: _SkyPainter(
                          catalog: catalog,
                          observer: Observer(
                            latitude: town.lat,
                            longitude: town.lng,
                          ),
                          at: now,
                          labels: (
                            north: l10n.skyChartNorth,
                            east: l10n.skyChartEast,
                            south: l10n.skyChartSouth,
                            west: l10n.skyChartWest,
                          ),
                          planetLabel: (planet) => planetName(l10n, planet),
                        ),
                      ),
              ),
            ),
          ),
          if (town != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  borderRadius: AppRadius.medium,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Text(
                    town.fullName,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Everything on the chart, drawn from the zenith outward.
class _SkyPainter extends CustomPainter {
  const _SkyPainter({
    required this.catalog,
    required this.observer,
    required this.at,
    required this.labels,
    required this.planetLabel,
  });

  final StarCatalog catalog;
  final Observer observer;
  final DateTime at;
  final ({String north, String east, String south, String west}) labels;
  final String Function(Planet) planetLabel;

  /// Stereographic projection of an apparent place onto the disc, or null if
  /// it is below the horizon.
  Offset? _project(Horizontal position, Size size) {
    if (position.altitude <= 0) return null;
    final radius = size.width / 2;
    // Zenith at the centre, horizon at the rim.
    final r = radius * math.tan((math.pi / 2 - position.altitude) / 2);
    // East to the left, because the chart is held up to the sky.
    return Offset(
      radius - r * math.sin(position.azimuth),
      radius - r * math.cos(position.azimuth),
    );
  }

  Offset? _projectEquatorial(Equatorial position, Size size) =>
      _project(observer.lookAt(position, at), size);

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.width / 2;
    final centre = Offset(radius, radius);

    // Constellation figures first, so the stars sit on top of their own lines.
    final linePaint = Paint()
      ..color = const Color(0x553D6EA8)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    for (final figure in catalog.figures) {
      Offset? previous;
      for (final (ra, dec) in figure.points) {
        final point = _projectEquatorial(
          StarCatalog.precess(ra, dec, at),
          size,
        );
        if (previous != null && point != null) {
          canvas.drawLine(previous, point, linePaint);
        }
        previous = point;
      }
    }

    // Stars, brightest last so they are never overdrawn.
    final starPaint = Paint()..color = Colors.white;
    for (final star in catalog.stars.reversed) {
      final point = _projectEquatorial(
        StarCatalog.precess(star.rightAscension, star.declination, at),
        size,
      );
      if (point == null) continue;
      // Magnitude to radius: each magnitude is 2.5x the flux, and the eye is
      // logarithmic, so a linear map on magnitude reads correctly.
      final scale = ((6.5 - star.magnitude) / 6.5).clamp(0.0, 1.0);
      canvas.drawCircle(
        point,
        0.4 + scale * scale * 2.4,
        starPaint..color = Colors.white.withValues(alpha: 0.35 + scale * 0.65),
      );
    }

    // Messier objects that are up — small rings, so they read as "not a star".
    final objectPaint = Paint()
      ..color = const Color(0x99A5D6A7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final object in messierCatalogue) {
      if (object.magnitude > 7) continue;
      final point = _projectEquatorial(object.positionAt(at), size);
      if (point != null) canvas.drawCircle(point, 3, objectPaint);
    }

    // The Moon and the planets, labelled — the things a reader will look for.
    final moon = MoonEphemeris.at(at);
    final moonPoint = _projectEquatorial(moon.equatorial, size);
    if (moonPoint != null) {
      canvas.drawCircle(moonPoint, 6, Paint()..color = const Color(0xFFE8E3DA));
    }
    for (final planet in Planet.values) {
      final body = PlanetEphemeris.at(planet, at);
      if (body.magnitude > 5.5) continue;
      final point = _projectEquatorial(body.equatorial, size);
      if (point == null) continue;
      canvas.drawCircle(point, 3.5, Paint()..color = const Color(0xFFFFD98A));
      _text(
        canvas,
        planetLabel(planet),
        point + const Offset(6, -6),
        10,
        const Color(0xFFFFD98A),
      );
    }

    // The horizon and the cardinal points.
    canvas.drawCircle(
      centre,
      radius - 1,
      Paint()
        ..color = const Color(0x66FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    const inset = 14.0;
    _text(
      canvas,
      labels.north,
      Offset(radius, inset),
      12,
      Colors.white70,
      centred: true,
    );
    _text(
      canvas,
      labels.south,
      Offset(radius, size.height - inset - 12),
      12,
      Colors.white70,
      centred: true,
    );
    _text(canvas, labels.east, Offset(inset, radius - 6), 12, Colors.white70);
    _text(
      canvas,
      labels.west,
      Offset(size.width - inset - 10, radius - 6),
      12,
      Colors.white70,
    );
  }

  void _text(
    Canvas canvas,
    String value,
    Offset at,
    double size,
    Color color, {
    bool centred = false,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: value,
        style: TextStyle(color: color, fontSize: size),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, centred ? at - Offset(painter.width / 2, 0) : at);
  }

  @override
  bool shouldRepaint(covariant _SkyPainter oldDelegate) =>
      at != oldDelegate.at ||
      !identical(catalog, oldDelegate.catalog) ||
      observer.latitude != oldDelegate.observer.latitude ||
      observer.longitude != oldDelegate.observer.longitude;
}
