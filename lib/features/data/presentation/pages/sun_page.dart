/// The Sun: one day's light, and the year's solar terms.
///
/// Computed on the device from `core/astro/` — the same Meeus solar series the
/// moon page reads for the phase, so the two pages can never disagree about
/// where the Sun is.
///
/// The twilights are here for more than stargazing. Civil twilight is the
/// boundary of working outdoors without light, which is what an evacuation
/// window or a night search is planned against — so it is given as a span, not
/// a single time, and sits above the photographers' golden hour rather than
/// among it.
library;

import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/astro/solar_terms.dart';
import 'package:dpip/core/astro/sun_ephemeris.dart';
import 'package:dpip/core/astro/sun_events.dart';
import 'package:dpip/core/realtime/app_time.dart';
import 'package:dpip/features/data/presentation/observer_place.dart';
import 'package:dpip/features/data/presentation/widgets/astro_card.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/widgets/section_header.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Taiwan's fixed offset — the wall clock every time on this page is read in.
const Duration _taiwanOffset = Duration(hours: 8);

class SunPage extends StatelessWidget {
  const SunPage({super.key});

  // Numeric formats only, so no `intl` locale symbol data is needed.
  static final DateFormat _clock = DateFormat('HH:mm');
  static final DateFormat _dayMonth = DateFormat('M/d');

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

    final events = town == null
        ? null
        : SunEvents.of(dayStart, latitude: town.lat, longitude: town.lng);
    final equationOfTime = SunEphemeris.at(now).equationOfTime;
    final (nextTerm, nextTermAt) = SolarTerms.upcoming(now);
    final terms = SolarTerms.ofYear(today.year, offset: _taiwanOffset);

    String at(DateTime? utc) =>
        utc == null ? l10n.moonNoEvent : _clock.format(AppTime.taipei(utc));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.sunTitle)),
      body: ListView(
        padding: EdgeInsets.only(
          bottom: AppSpacing.xl + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          SectionHeader(
            l10n.sunSectionDaylight,
            trailing: town == null
                ? null
                : Text(
                    town.fullName,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
          ),
          AstroReadings(
            rows: [
              (Icons.wb_twilight_outlined, l10n.sunRise, at(events?.rise)),
              (Icons.wb_sunny_outlined, l10n.sunNoon, at(events?.noon)),
              (Icons.nights_stay_outlined, l10n.sunSet, at(events?.set)),
              (
                Icons.hourglass_bottom_outlined,
                l10n.sunDayLength,
                events == null ? l10n.moonNoEvent : _span(events.dayLength),
              ),
            ],
          ),
          SectionHeader(l10n.sunSectionTwilight),
          AstroCard(
            child: Column(
              children: [
                AstroSpan(
                  icon: Icons.brightness_5_outlined,
                  label: l10n.sunTwilightCivil,
                  from: at(events?.civilDawn),
                  to: at(events?.civilDusk),
                ),
                const Divider(
                  height: 1,
                  indent: AppSpacing.xxl + AppSpacing.md,
                ),
                AstroSpan(
                  icon: Icons.brightness_4_outlined,
                  label: l10n.sunTwilightNautical,
                  from: at(events?.nauticalDawn),
                  to: at(events?.nauticalDusk),
                ),
                const Divider(
                  height: 1,
                  indent: AppSpacing.xxl + AppSpacing.md,
                ),
                AstroSpan(
                  icon: Icons.brightness_2_outlined,
                  label: l10n.sunTwilightAstronomical,
                  from: at(events?.astronomicalDawn),
                  to: at(events?.astronomicalDusk),
                ),
              ],
            ),
          ),
          SectionHeader(l10n.sunSectionLight),
          AstroCard(
            child: Column(
              children: [
                AstroSpan(
                  icon: Icons.wb_iridescent_outlined,
                  label: l10n.sunGoldenHourMorning,
                  from: at(events?.blueMorningStart),
                  to: at(events?.goldenMorningEnd),
                ),
                const Divider(
                  height: 1,
                  indent: AppSpacing.xxl + AppSpacing.md,
                ),
                AstroSpan(
                  icon: Icons.wb_incandescent_outlined,
                  label: l10n.sunGoldenHourEvening,
                  from: at(events?.goldenEveningStart),
                  to: at(events?.blueEveningEnd),
                ),
                const Divider(
                  height: 1,
                  indent: AppSpacing.xxl + AppSpacing.md,
                ),
                AstroSpan(
                  icon: Icons.water_outlined,
                  label: l10n.sunBlueHour,
                  from: at(events?.blueEveningEnd),
                  to: at(events?.nauticalDusk),
                ),
              ],
            ),
          ),
          SectionHeader(l10n.sunSectionSundial),
          AstroReadings(
            rows: [
              (
                Icons.schedule_outlined,
                l10n.sunEquationOfTime,
                _signedMinutes(equationOfTime, l10n),
              ),
              (
                Icons.eco_outlined,
                l10n.solarTermNext,
                '${solarTermName(l10n, nextTerm)} '
                    '${_dayMonth.format(AppTime.taipei(nextTermAt))}',
              ),
            ],
          ),
          SectionHeader(l10n.sunSectionTerms),
          AstroCard(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Column(
              children: [
                for (final (term, instant) in terms)
                  _TermRow(
                    name: solarTermName(l10n, term),
                    stamp:
                        '${_dayMonth.format(AppTime.taipei(instant))} '
                        '${_clock.format(AppTime.taipei(instant))}',
                    isMajor: term.isMajor,
                    isNext: term == nextTerm,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// `H hr M min`, using the localised unit words.
  static String _span(Duration duration) =>
      // l10n-ignore: digits and a colon
      '${duration.inHours}:'
      '${(duration.inMinutes % 60).toString().padLeft(2, '0')}';

  static String _signedMinutes(Duration value, AppLocalizations l10n) {
    final minutes = value.inSeconds / 60;
    // l10n-ignore: a signed number; the unit word is localised beside it
    final text = '${minutes >= 0 ? '+' : ''}${minutes.toStringAsFixed(1)}';
    return '$text ${l10n.sunMinutes}';
  }
}

class _TermRow extends StatelessWidget {
  const _TermRow({
    required this.name,
    required this.stamp,
    required this.isMajor,
    required this.isNext,
  });

  final String name;
  final String stamp;

  /// 中氣 — the twelve that anchor the lunisolar calendar. Emphasised because
  /// the distinction is real and invisible otherwise.
  final bool isMajor;
  final bool isNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      color: isNext ? colors.primaryContainer.withValues(alpha: 0.5) : null,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 8,
            child: isMajor
                ? Icon(Icons.circle, size: 6, color: colors.primary)
                : null,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              name,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: isMajor ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
          Text(
            stamp,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// The localised name of a solar term.
String solarTermName(AppLocalizations l10n, SolarTerm term) => switch (term) {
  SolarTerm.vernalEquinox => l10n.solarTermVernalEquinox,
  SolarTerm.pureBrightness => l10n.solarTermPureBrightness,
  SolarTerm.grainRain => l10n.solarTermGrainRain,
  SolarTerm.startOfSummer => l10n.solarTermStartOfSummer,
  SolarTerm.grainFull => l10n.solarTermGrainFull,
  SolarTerm.grainInEar => l10n.solarTermGrainInEar,
  SolarTerm.summerSolstice => l10n.solarTermSummerSolstice,
  SolarTerm.minorHeat => l10n.solarTermMinorHeat,
  SolarTerm.majorHeat => l10n.solarTermMajorHeat,
  SolarTerm.startOfAutumn => l10n.solarTermStartOfAutumn,
  SolarTerm.endOfHeat => l10n.solarTermEndOfHeat,
  SolarTerm.whiteDew => l10n.solarTermWhiteDew,
  SolarTerm.autumnalEquinox => l10n.solarTermAutumnalEquinox,
  SolarTerm.coldDew => l10n.solarTermColdDew,
  SolarTerm.frostDescent => l10n.solarTermFrostDescent,
  SolarTerm.startOfWinter => l10n.solarTermStartOfWinter,
  SolarTerm.minorSnow => l10n.solarTermMinorSnow,
  SolarTerm.majorSnow => l10n.solarTermMajorSnow,
  SolarTerm.winterSolstice => l10n.solarTermWinterSolstice,
  SolarTerm.minorCold => l10n.solarTermMinorCold,
  SolarTerm.majorCold => l10n.solarTermMajorCold,
  SolarTerm.startOfSpring => l10n.solarTermStartOfSpring,
  SolarTerm.rainWater => l10n.solarTermRainWater,
  SolarTerm.awakeningOfInsects => l10n.solarTermAwakeningOfInsects,
};
