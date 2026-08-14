/// Tonight — what is observable, and when.
///
/// The dark window comes first because it gates everything else: a list of
/// targets is useless if the Moon is up all night. Then the showers that are
/// running, then the satellites, then the deep-sky objects high enough to be
/// worth pointing at.
///
/// Every section states its empty case rather than disappearing. "No visible
/// passes for two days" is a real and common answer — the station spends whole
/// stretches passing only inside the Earth's shadow — and a section that
/// simply vanishes cannot be told apart from one that is broken.
///
/// The work happens in `TonightReport`, off the UI thread: the satellite
/// search alone is tens of thousands of SGP4 evaluations and would freeze a
/// build.
library;

import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/astro/astro_time.dart';
import 'package:dpip/core/astro/deep_sky.dart';
import 'package:dpip/core/astro/meteor_showers.dart';
import 'package:dpip/core/astro/tonight_report.dart';
import 'package:dpip/core/geo/town.dart';
import 'package:dpip/core/realtime/app_time.dart';
import 'package:dpip/features/data/presentation/observer_place.dart';
import 'package:dpip/features/data/presentation/widgets/astro_card.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/widgets/loading_view.dart';
import 'package:dpip/shared/widgets/section_header.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

const Duration _taiwanOffset = Duration(hours: 8);

class TonightPage extends StatefulWidget {
  const TonightPage({super.key});

  @override
  State<TonightPage> createState() => _TonightPageState();
}

class _TonightPageState extends State<TonightPage> {
  static final DateFormat _clock = DateFormat('HH:mm');
  static final DateFormat _dayMonth = DateFormat('M/d');

  Future<TonightReport>? _report;
  String? _resolvedFor;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final town = observerTown(context);
    // Recompute only when the place changes — the report is expensive and the
    // page rebuilds for unrelated reasons.
    if (town == null || town.code == _resolvedFor) return;
    _resolvedFor = town.code;
    _report = _buildReport(town);
  }

  Future<TonightReport> _buildReport(Town town) {
    final now = AppTime.utc;
    final today = AppTime.taipei(now);
    return TonightReport.build(
      DateTime.utc(today.year, today.month, today.day).subtract(_taiwanOffset),
      now: now,
      latitude: town.lat,
      longitude: town.lng,
      // Cache-backed, so wiring a feed later only has to fill in `fetch`.
      // With none wired it resolves to the bundled snapshot, which is what
      // ships today.
      source: CachedTleSource(prefs: context.read<Prefs>(), now: () => now),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final town = observerTown(context);
    final report = _report;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.tonightTitle)),
      body: town == null || report == null
          ? const LoadingView()
          : FutureBuilder<TonightReport>(
              future: report,
              builder: (context, snapshot) {
                final data = snapshot.data;
                if (data == null) return const LoadingView();
                return _Report(report: data, place: town.fullName);
              },
            ),
    );
  }

  static String _at(AppLocalizations l10n, DateTime? utc) =>
      utc == null ? l10n.moonNoEvent : _clock.format(AppTime.taipei(utc));

  static String _day(DateTime utc) => _dayMonth.format(AppTime.taipei(utc));
}

class _Report extends StatelessWidget {
  const _Report({required this.report, required this.place});

  final TonightReport report;
  final String place;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final night = report.night;

    Widget trailing(String text) => Text(
      text,
      style: theme.textTheme.labelMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );

    return ListView(
      padding: EdgeInsets.only(
        bottom: AppSpacing.xl + MediaQuery.paddingOf(context).bottom,
      ),
      children: [
        SectionHeader(l10n.tonightSectionDark, trailing: trailing(place)),
        AstroReadings(
          rows: [
            (
              Icons.dark_mode_outlined,
              l10n.tonightAstronomicalNight,
              night.astronomicalNight == null
                  ? l10n.tonightNeverDark
                  : '${_TonightPageState._at(l10n, night.astronomicalNight!.$1)}'
                        ' – '
                        '${_TonightPageState._at(l10n, night.astronomicalNight!.$2)}',
            ),
            (
              Icons.visibility_outlined,
              l10n.tonightDarkWindow,
              night.best == null
                  ? l10n.tonightMoonAllNight
                  : '${_TonightPageState._at(l10n, night.best!.from)} – '
                        '${_TonightPageState._at(l10n, night.best!.to)}',
            ),
            (
              Icons.hourglass_bottom_outlined,
              l10n.tonightDarkTotal,
              // l10n-ignore: digits and a colon
              '${night.totalDark.inHours}:'
                  '${(night.totalDark.inMinutes % 60).toString().padLeft(2, '0')}',
            ),
            (
              Icons.brightness_2_outlined,
              l10n.tonightMoonlight,
              // l10n-ignore: percentage readout
              '${(night.moonIllumination * 100).round()}%',
            ),
          ],
        ),

        SectionHeader(l10n.tonightSectionShowers),
        AstroReadings(
          rows: report.showers.isEmpty
              ? [
                  (
                    Icons.auto_awesome_outlined,
                    l10n.tonightNoShowers,
                    l10n.moonNoEvent,
                  ),
                ]
              : [
                  for (final conditions in report.showers)
                    (
                      conditions.isFavourable
                          ? Icons.auto_awesome
                          : Icons.auto_awesome_outlined,
                      '${meteorShowerName(l10n, conditions.shower)} · '
                          '${_TonightPageState._day(conditions.peak)}',
                      conditions.bestAltitude <= 0
                          ? l10n.tonightRadiantDown
                          // l10n-ignore: a rate; the unit word is localised
                          : '~${conditions.visibleRate.round()}'
                                ' ${l10n.tonightPerHour}',
                    ),
                ],
        ),

        SectionHeader(
          l10n.tonightSectionSatellites,
          trailing: report.elementAge == null
              ? null
              : trailing(l10n.tonightElementAge(report.elementAge!.inDays)),
        ),
        AstroReadings(
          rows: switch (report) {
            TonightReport(satellitesFailed: true) => [
              (
                Icons.error_outline,
                l10n.tonightSatellitesUnavailable,
                l10n.moonNoEvent,
              ),
            ],
            TonightReport(passes: final passes) when passes.isEmpty => [
              (
                Icons.satellite_alt_outlined,
                l10n.tonightNoPasses,
                l10n.moonNoEvent,
              ),
            ],
            TonightReport(passes: final passes) => [
              for (final entry in passes.take(6))
                (
                  Icons.satellite_alt_outlined,
                  '${entry.name} · ${_TonightPageState._day(entry.pass.rises)}',
                  // l10n-ignore: a time and a degree readout
                  '${_TonightPageState._at(l10n, entry.pass.peaks)}  '
                      '${(entry.pass.peakAltitude / degrees).round()}°',
                ),
            ],
          },
        ),

        SectionHeader(l10n.tonightSectionTargets),
        AstroReadings(
          rows: report.targets.isEmpty
              ? [
                  (
                    Icons.blur_on_outlined,
                    l10n.tonightNoTargets,
                    l10n.moonNoEvent,
                  ),
                ]
              : [
                  for (final sighting in report.targets.take(8))
                    (
                      Icons.blur_on_outlined,
                      sighting.object.commonName.isEmpty
                          ? '${sighting.object.label} · '
                                '${deepSkyTypeName(l10n, sighting.object.type)}'
                          : '${sighting.object.label} · '
                                '${sighting.object.commonName}',
                      // l10n-ignore: magnitude and a degree readout
                      '${sighting.object.magnitude.toStringAsFixed(1)}  '
                          '${(sighting.altitude / degrees).round()}°',
                    ),
                ],
        ),
      ],
    );
  }
}

/// The localised name of a shower.
String meteorShowerName(AppLocalizations l10n, MeteorShower shower) =>
    switch (shower.id) {
      'quadrantids' => l10n.showerQuadrantids,
      'lyrids' => l10n.showerLyrids,
      'etaAquariids' => l10n.showerEtaAquariids,
      'deltaAquariids' => l10n.showerDeltaAquariids,
      'perseids' => l10n.showerPerseids,
      'orionids' => l10n.showerOrionids,
      'southernTaurids' => l10n.showerSouthernTaurids,
      'leonids' => l10n.showerLeonids,
      'geminids' => l10n.showerGeminids,
      _ => l10n.showerUrsids,
    };

/// The localised name of a deep-sky object type.
String deepSkyTypeName(AppLocalizations l10n, DeepSkyType type) =>
    switch (type) {
      DeepSkyType.oc => l10n.deepSkyOpenCluster,
      DeepSkyType.gc => l10n.deepSkyGlobularCluster,
      DeepSkyType.s => l10n.deepSkySpiralGalaxy,
      DeepSkyType.e => l10n.deepSkyEllipticalGalaxy,
      DeepSkyType.i => l10n.deepSkyIrregularGalaxy,
      DeepSkyType.pn => l10n.deepSkyPlanetaryNebula,
      DeepSkyType.snr => l10n.deepSkySupernovaRemnant,
      DeepSkyType.sfr => l10n.deepSkyEmissionNebula,
      DeepSkyType.rn => l10n.deepSkyReflectionNebula,
      DeepSkyType.pos => l10n.deepSkyAsterism,
    };
