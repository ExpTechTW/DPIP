import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/features/events/domain/event_addition.dart';
import 'package:dpip/features/events/domain/event_card.dart';
import 'package:dpip/features/events/presentation/detail/event_detail_blocks.dart';
import 'package:dpip/features/events/presentation/detail/event_type_detail.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/seismic/intensity.dart';
import 'package:dpip/shared/seismic/intensity_colors.dart';
import 'package:dpip/shared/widgets/intensity_badge.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

/// The detail of earthquake, tsunami_note and intensity.
///
/// An `intensity` card (TREM's 震度速報) summarises its latest report's
/// intensity by township, strongest first. `earthquake` and `tsunami_note`
/// add no summary: their `addition.id` is the CWA report number alone
/// (`114201`), while the app's earthquake report page is addressed by the full
/// report id (`115058-2026-0827-054720`), which these cards do not carry.
/// Every report keeps the default headline facts.
final class EarthquakeReportDetail extends EventTypeDetail {
  const EarthquakeReportDetail();

  @override
  Widget? summary(BuildContext context, EventCardDetail detail) {
    final latest = detail.latest;
    if (latest.type != 'intensity') return null;
    // Nullable, so a tree without the directory reads null instead of
    // throwing; the app provides it at the root.
    final directory = context.read<TownDirectory?>();
    if (directory == null) return null;
    final areas = _intensityByTown(latest.addition, directory);
    if (areas.isEmpty) return null;
    return EventDetailSection(
      title: AppLocalizations.of(context).eventDetailIntensityByArea,
      child: EventDetailRows(
        rows: [
          for (final (name, level) in areas)
            EventDetailRow(
              leading: IntensityBadge(
                label: Intensity.label(level),
                color: IntensityColors.discrete(level),
                size: 24,
              ),
              label: name,
              value: Intensity.label(level),
            ),
        ],
      ),
    );
  }
}

/// A CWA 0–9 intensity key of `addition.area`.
final RegExp _levelKey = RegExp(r'^[0-9]$');

/// The townships of an `intensity` report's `addition.area`, shaped
/// `{"<level>": [code, …]}`, as (full name, level): by level descending, then
/// by name.
///
/// A township listed under two levels keeps the higher one. A key that is not
/// a 0–9 level, a code that is not a whole number and a code [directory] does
/// not know are left out.
List<(String, int)> _intensityByTown(
  Map<String, dynamic>? addition,
  TownDirectory directory,
) {
  final area = addition?['area'];
  if (area is! Map<Object?, Object?>) return const [];
  final levels = <String, int>{};
  for (final MapEntry(:key, :value) in area.entries) {
    if (key is! String || !_levelKey.hasMatch(key)) continue;
    if (value is! List<Object?>) continue;
    final level = int.parse(key);
    for (final element in value) {
      final number = additionInt(element);
      if (number == null) continue;
      final code = '$number';
      final previous = levels[code];
      if (previous == null || level > previous) levels[code] = level;
    }
  }
  return [
    for (final MapEntry(:key, :value) in levels.entries)
      if (directory.byCode(key) case final town?) (town.fullName, value),
  ]..sort((a, b) {
    final byLevel = b.$2.compareTo(a.$2);
    return byLevel != 0 ? byLevel : a.$1.compareTo(b.$1);
  });
}
