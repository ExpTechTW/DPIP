/// 潮汐 — the astronomical part of the tide.
///
/// Deliberately not a tide table. A real prediction needs a harbour's harmonic
/// constants, which are the ocean's response and cannot be derived from the
/// sky; the CWA publishes those and this page says so. What it *does* give is
/// the forcing, which is purely astronomical and therefore works offline: when
/// the pull peaks, whether this is a spring or a neap, and whether a perigean
/// spring — the highest water of the season, and the one to check a storm
/// surge against — is coming.
library;

import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/astro/tidal_forcing.dart';
import 'package:dpip/core/realtime/app_time.dart';
import 'package:dpip/features/data/presentation/observer_place.dart';
import 'package:dpip/features/data/presentation/widgets/astro_card.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/widgets/section_header.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

const Duration _taiwanOffset = Duration(hours: 8);

class TidePage extends StatelessWidget {
  const TidePage({super.key});

  static final DateFormat _clock = DateFormat('HH:mm');
  static final DateFormat _date = DateFormat('yyyy/MM/dd');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final town = observerTown(context);
    final now = AppTime.utc;
    final today = AppTime.taipei(now);
    final dayStart = DateTime.utc(
      today.year,
      today.month,
      today.day,
    ).subtract(_taiwanOffset);

    if (town == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.tideTitle)),
        body: const SizedBox.shrink(),
      );
    }

    final forcing = TidalForcing.at(
      now,
      latitude: town.lat,
      longitude: town.lng,
    );
    final extremes = TidalForcing.extremes(
      dayStart,
      latitude: town.lat,
      longitude: town.lng,
    );
    final perigean = TidalForcing.nextPerigeanSpring(now);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.tideTitle)),
      body: ListView(
        padding: EdgeInsets.only(
          bottom: AppSpacing.xl + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              0,
            ),
            child: Text(
              l10n.tideDisclaimer,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          SectionHeader(
            l10n.tideSectionNow,
            trailing: Text(
              town.fullName,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          AstroReadings(
            rows: [
              (
                Icons.waves_outlined,
                l10n.tidePhase,
                switch (forcing.phase) {
                  TidePhase.spring => l10n.tideSpring,
                  TidePhase.neap => l10n.tideNeap,
                  TidePhase.middling => l10n.tideMiddling,
                },
              ),
              (
                Icons.straighten_outlined,
                l10n.tideLunarDistanceFactor,
                // l10n-ignore: a multiplier
                '${forcing.distanceFactor.toStringAsFixed(2)}×',
              ),
              (
                Icons.trending_up_outlined,
                l10n.tideEquilibrium,
                // l10n-ignore: metres, with the unit localised beside it
                '${forcing.equilibriumMetres.toStringAsFixed(2)} ${l10n.tideMetres}',
              ),
              if (perigean != null)
                (
                  Icons.warning_amber_outlined,
                  l10n.tidePerigeanSpring,
                  _date.format(AppTime.taipei(perigean)),
                ),
            ],
          ),
          SectionHeader(l10n.tideSectionTurningPoints),
          AstroReadings(
            rows: [
              for (final extreme in extremes)
                (
                  extreme.isHigh ? Icons.arrow_upward : Icons.arrow_downward,
                  extreme.isHigh ? l10n.tideHigh : l10n.tideLow,
                  _clock.format(AppTime.taipei(extreme.at)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
