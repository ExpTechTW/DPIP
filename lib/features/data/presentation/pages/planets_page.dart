/// The planets, tonight.
///
/// Ordered by what actually decides whether you can see one: how high it gets,
/// not how far out it orbits. A planet below the horizon or inside the Sun's
/// glare is listed as such rather than given a magnitude that implies it is
/// there to be seen — magnitude answers "how bright", never "is it visible".
///
/// Computed on the device from JPL's Keplerian elements (`core/astro/
/// planet_ephemeris.dart`), pinned against JPL Horizons.
library;

import 'dart:math' as math;

import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/astro/planet_ephemeris.dart';
import 'package:dpip/core/astro/sky_position.dart';
import 'package:dpip/core/realtime/app_time.dart';
import 'package:dpip/features/data/presentation/observer_place.dart';
import 'package:dpip/features/data/presentation/widgets/astro_card.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/widgets/section_header.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

const Duration _taiwanOffset = Duration(hours: 8);

/// Below this elongation a planet is lost in twilight whatever its magnitude.
const double _glareElongation = 15;

class PlanetsPage extends StatelessWidget {
  const PlanetsPage({super.key});

  static final DateFormat _clock = DateFormat('HH:mm');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final town = observerTown(context);
    final now = AppTime.utc;
    final today = AppTime.taipei(now);
    final dayStart = DateTime.utc(
      today.year,
      today.month,
      today.day,
    ).subtract(_taiwanOffset);

    final observer = town == null
        ? null
        : Observer(latitude: town.lat, longitude: town.lng);

    final entries = [
      for (final planet in Planet.values)
        _Entry(
          planet: planet,
          body: PlanetEphemeris.at(planet, now),
          now: observer?.lookAt(
            PlanetEphemeris.at(planet, now).equatorial,
            now,
          ),
          events: observer == null
              ? null
              : RiseSet.solve(
                  from: dayStart,
                  observer: observer,
                  track: PlanetEphemeris.trackOf(planet),
                  horizon: (_) => pointHorizon,
                ),
        ),
    ]..sort((a, b) => b.rank.compareTo(a.rank));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.planetsTitle)),
      body: ListView(
        padding: EdgeInsets.only(
          bottom: AppSpacing.xl + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          SectionHeader(
            l10n.planetsSectionTonight,
            trailing: town == null
                ? null
                : Text(
                    town.fullName,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
          ),
          for (final entry in entries)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: AstroCard(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: _PlanetTile(entry: entry, clock: _clock),
              ),
            ),
        ],
      ),
    );
  }
}

/// A planet with everything the tile needs, resolved once.
class _Entry {
  _Entry({
    required this.planet,
    required this.body,
    required this.now,
    required this.events,
  });

  final Planet planet;
  final PlanetEphemeris body;
  final Horizontal? now;
  final RiseSet? events;

  bool get isUp => (now?.altitude ?? -1) > 0;
  bool get isInGlare => body.elongation * 180 / math.pi < _glareElongation;

  /// Sort key: up and clear of the Sun first, then by brightness. A dim planet
  /// you can actually see beats a bright one that has set.
  double get rank {
    if (isInGlare) return -100;
    if (!isUp) return -50 - body.magnitude;
    return 10 - body.magnitude;
  }
}

class _PlanetTile extends StatelessWidget {
  const _PlanetTile({required this.entry, required this.clock});

  final _Entry entry;
  final DateFormat clock;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final body = entry.body;

    final status = entry.isInGlare
        ? l10n.planetInGlare
        : entry.isUp
        ? l10n.planetUp
        : l10n.planetDown;
    final statusColor = entry.isInGlare
        ? colors.onSurfaceVariant
        : entry.isUp
        ? colors.primary
        : colors.onSurfaceVariant;

    String time(DateTime? at) =>
        at == null ? l10n.moonNoEvent : clock.format(AppTime.taipei(at));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                planetName(l10n, entry.planet),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.14),
                borderRadius: AppRadius.small,
              ),
              child: Text(
                status,
                style: theme.textTheme.labelSmall?.copyWith(color: statusColor),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.xs,
          children: [
            _Fact(
              label: l10n.planetMagnitude,
              // l10n-ignore: a signed number
              value: body.magnitude.toStringAsFixed(1),
            ),
            _Fact(
              label: l10n.planetElongation,
              // l10n-ignore: degree symbol
              value: '${(body.elongation * 180 / math.pi).round()}°',
            ),
            _Fact(
              label: l10n.planetSky,
              value: body.isEvening ? l10n.planetEvening : l10n.planetMorning,
            ),
            _Fact(
              label: l10n.planetDistance,
              // l10n-ignore: the unit word is localised beside it
              value: '${body.distanceAu.toStringAsFixed(2)} ${l10n.planetAu}',
            ),
            if (entry.now != null && entry.isUp)
              _Fact(
                label: l10n.planetAltitude,
                // l10n-ignore: degree symbol
                value: '${(entry.now!.altitude * 180 / math.pi).round()}°',
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Icon(Icons.arrow_upward, size: 14, color: colors.onSurfaceVariant),
            const SizedBox(width: AppSpacing.xs),
            Text(time(entry.events?.rise), style: theme.textTheme.bodySmall),
            const SizedBox(width: AppSpacing.md),
            Icon(
              Icons.vertical_align_top,
              size: 14,
              color: colors.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(time(entry.events?.transit), style: theme.textTheme.bodySmall),
            const SizedBox(width: AppSpacing.md),
            Icon(
              Icons.arrow_downward,
              size: 14,
              color: colors.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(time(entry.events?.set), style: theme.textTheme.bodySmall),
          ],
        ),
      ],
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

/// The localised name of a planet.
String planetName(AppLocalizations l10n, Planet planet) => switch (planet) {
  Planet.mercury => l10n.planetMercury,
  Planet.venus => l10n.planetVenus,
  Planet.mars => l10n.planetMars,
  Planet.jupiter => l10n.planetJupiter,
  Planet.saturn => l10n.planetSaturn,
  Planet.uranus => l10n.planetUranus,
  Planet.neptune => l10n.planetNeptune,
};
