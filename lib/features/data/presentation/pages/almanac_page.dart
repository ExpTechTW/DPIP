/// 曆法 — the lunisolar date, and the eclipses ahead.
///
/// Both are derived, not tabulated: the calendar from the new moons and the
/// solar terms this package computes, the eclipses from the same positions
/// asked a different question. So the page works for any year, not for the
/// span someone once pasted in.
library;

import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/astro/eclipse.dart';
import 'package:dpip/core/astro/lunisolar_calendar.dart';
import 'package:dpip/core/realtime/app_time.dart';
import 'package:dpip/features/data/presentation/observer_place.dart';
import 'package:dpip/features/data/presentation/widgets/astro_card.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/widgets/section_header.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AlmanacPage extends StatefulWidget {
  const AlmanacPage({super.key});

  @override
  State<AlmanacPage> createState() => _AlmanacPageState();
}

class _AlmanacPageState extends State<AlmanacPage> {
  static final DateFormat _date = DateFormat('yyyy/MM/dd');
  static final DateFormat _stamp = DateFormat('yyyy/MM/dd HH:mm');

  /// The eclipse lists stay valid only while [AppTime.utc] is still before
  /// the first eclipse begins. Past that instant the search cursor moves
  /// and the next frame can name a different eclipse, so the cache stops
  /// rather than painting the old one. An empty search is not held: the
  /// window slides forward with the clock and a later instant can find one.
  List<Eclipse>? _lunar;
  DateTime? _lunarFrom;
  DateTime? _lunarUntil;
  List<Eclipse>? _solar;
  double? _solarLat;
  double? _solarLng;
  DateTime? _solarFrom;
  DateTime? _solarUntil;

  List<Eclipse> _lunarEclipses(DateTime now) {
    final cached = _lunar;
    final from = _lunarFrom;
    final until = _lunarUntil;
    if (cached != null &&
        from != null &&
        until != null &&
        !now.isBefore(from) &&
        now.isBefore(until)) {
      return cached;
    }
    final list = <Eclipse>[];
    var cursor = now;
    for (var i = 0; i < 3; i++) {
      final eclipse = Eclipses.nextLunar(cursor, withinDays: 800);
      if (eclipse == null) break;
      list.add(eclipse);
      cursor = eclipse.peak.add(const Duration(days: 20));
    }
    _lunar = list;
    _lunarFrom = now;
    _lunarUntil = list.isEmpty ? now : (list.first.begins ?? now);
    return list;
  }

  List<Eclipse> _solarEclipses(
    DateTime now,
    double latitude,
    double longitude,
  ) {
    final cached = _solar;
    final from = _solarFrom;
    final until = _solarUntil;
    if (cached != null &&
        _solarLat == latitude &&
        _solarLng == longitude &&
        from != null &&
        until != null &&
        !now.isBefore(from) &&
        now.isBefore(until)) {
      return cached;
    }
    final list = <Eclipse>[];
    var cursor = now;
    for (var i = 0; i < 2; i++) {
      final eclipse = Eclipses.nextSolar(
        cursor,
        latitude: latitude,
        longitude: longitude,
        withinDays: 4000,
      );
      if (eclipse == null) break;
      list.add(eclipse);
      cursor = eclipse.peak.add(const Duration(days: 20));
    }
    _solar = list;
    _solarLat = latitude;
    _solarLng = longitude;
    _solarFrom = now;
    _solarUntil = list.isEmpty ? now : (list.first.begins ?? now);
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final town = observerTown(context);
    final now = AppTime.utc;
    final lunar = LunisolarCalendar.of(now);
    final lunarEclipses = _lunarEclipses(now);
    final solarEclipses = town == null
        ? const <Eclipse>[]
        : _solarEclipses(now, town.lat, town.lng);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.almanacTitle)),
      body: ListView(
        padding: EdgeInsets.only(
          bottom: AppSpacing.xl + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          SectionHeader(l10n.almanacSectionToday),
          AstroReadings(
            rows: [
              (
                Icons.today_outlined,
                l10n.almanacGregorian,
                _date.format(AppTime.utc8),
              ),
              (
                Icons.brightness_3_outlined,
                l10n.almanacLunar,
                _lunarLabel(l10n, lunar),
              ),
              (
                Icons.filter_vintage_outlined,
                l10n.almanacYear,
                // l10n-ignore: the sexagenary pair is a proper name in Chinese
                '${lunar.sexagenaryYear} · ${_zodiac(l10n, lunar.zodiacIndex)}',
              ),
              (
                Icons.event_outlined,
                l10n.almanacMonthLength,
                lunar.monthLength == 30
                    ? l10n.almanacLongMonth
                    : l10n.almanacShortMonth,
              ),
            ],
          ),
          SectionHeader(l10n.almanacSectionLunarEclipses),
          AstroReadings(
            rows: [
              for (final eclipse in lunarEclipses)
                (
                  Icons.brightness_1_outlined,
                  '${_eclipseKind(l10n, eclipse.kind)} · '
                      '${_stamp.format(AppTime.taipei(eclipse.peak))}',
                  // l10n-ignore: a magnitude
                  eclipse.magnitude.toStringAsFixed(2),
                ),
            ],
          ),
          SectionHeader(
            l10n.almanacSectionSolarEclipses,
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
            rows: solarEclipses.isEmpty
                ? [
                    (
                      Icons.wb_sunny_outlined,
                      l10n.almanacNoSolarEclipse,
                      l10n.moonNoEvent,
                    ),
                  ]
                : [
                    for (final eclipse in solarEclipses)
                      (
                        Icons.wb_sunny_outlined,
                        '${_eclipseKind(l10n, eclipse.kind)} · '
                            '${_stamp.format(AppTime.taipei(eclipse.peak))}',
                        // l10n-ignore: a magnitude
                        eclipse.magnitude.toStringAsFixed(2),
                      ),
                  ],
          ),
        ],
      ),
    );
  }

  static String _lunarLabel(AppLocalizations l10n, LunisolarDate date) =>
      l10n.almanacLunarDate(
        date.isLeapMonth ? l10n.almanacLeapPrefix : '',
        date.month,
        date.day,
      );

  static String _zodiac(AppLocalizations l10n, int index) => switch (index) {
    0 => l10n.zodiacRat,
    1 => l10n.zodiacOx,
    2 => l10n.zodiacTiger,
    3 => l10n.zodiacRabbit,
    4 => l10n.zodiacDragon,
    5 => l10n.zodiacSnake,
    6 => l10n.zodiacHorse,
    7 => l10n.zodiacGoat,
    8 => l10n.zodiacMonkey,
    9 => l10n.zodiacRooster,
    10 => l10n.zodiacDog,
    _ => l10n.zodiacPig,
  };

  static String _eclipseKind(AppLocalizations l10n, EclipseKind kind) =>
      switch (kind) {
        EclipseKind.total => l10n.eclipseTotal,
        EclipseKind.partial => l10n.eclipsePartial,
        EclipseKind.annular => l10n.eclipseAnnular,
        EclipseKind.penumbral => l10n.eclipsePenumbral,
        EclipseKind.none => l10n.moonNoEvent,
      };
}
