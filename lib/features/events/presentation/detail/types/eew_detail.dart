import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/features/events/domain/event_addition.dart';
import 'package:dpip/features/events/domain/event_card.dart';
import 'package:dpip/features/events/domain/event_facts.dart';
import 'package:dpip/features/events/presentation/detail/event_detail_blocks.dart';
import 'package:dpip/features/events/presentation/detail/event_type_detail.dart';
import 'package:dpip/features/events/presentation/widgets/event_fact_chip.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/seismic/intensity_colors.dart';
import 'package:dpip/shared/widgets/intensity_badge.dart';
import 'package:material_ui/material_ui.dart';

/// The detail of earthquake.eew and earthquake.eew.alert.
///
/// The summary is the latest report's estimate: its maximum intensity as a
/// large badge, beside its magnitude, depth, epicentre and origin time. Under
/// it, when at least two reports carry an estimate, each report's magnitude
/// and maximum intensity, oldest first, so the reader sees how the estimate
/// moved. A latest report with no estimate gives no summary, so an estimate
/// the source has withdrawn is never shown as the latest one. Each report
/// keeps the default headline facts.
///
/// Not earthquake.detection: that is where shaking was detected, with no
/// estimate to show (see `eventTypeDetailFor`).
final class EewDetail extends EventTypeDetail {
  const EewDetail();

  @override
  Widget? summary(BuildContext context, EventCardDetail detail) {
    final l10n = AppLocalizations.of(context);
    final latest = _latestEstimate(detail.latest, l10n);
    if (latest == null) return null;
    final history = _history(detail.reports, l10n);
    return EventDetailSection(
      title: l10n.eventDetailEewLatest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          latest,
          if (history != null) ...[
            const SizedBox(height: AppSpacing.md),
            history,
          ],
        ],
      ),
    );
  }
}

/// The badge and the facts of [report]'s estimate; null when it has none.
Widget? _latestEstimate(EventReport report, AppLocalizations l10n) {
  final facts = eventFactsOfReport(report);
  EventFact? of(EventFactKind kind) =>
      facts.where((fact) => fact.kind == kind).firstOrNull;

  final badge = switch (of(EventFactKind.maxIntensity)) {
    EventFact(:final display, intensityLevel: final level?) => IntensityBadge(
      label: display,
      color: IntensityColors.discrete(level),
      size: 56,
    ),
    _ => null,
  };
  final originTime = _originTime(report);
  final rows = [
    for (final kind in const [
      EventFactKind.magnitude,
      EventFactKind.depth,
      EventFactKind.epicenter,
    ])
      if (of(kind) case final fact?)
        EventDetailRow(
          label: eventFactKindLabel(kind, l10n),
          value: fact.display,
        ),
    if (originTime != null)
      EventDetailRow(
        label: eventFactKindLabel(EventFactKind.originTime, l10n),
        value: originTime,
      ),
  ];
  if (badge == null && rows.isEmpty) return null;

  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ?badge,
      if (rows.isNotEmpty) ...[
        if (badge != null) const SizedBox(width: AppSpacing.lg),
        Expanded(child: EventDetailRows(rows: rows)),
      ],
    ],
  );
}

/// Each report's magnitude and maximum intensity, by serial ascending, as
/// `M 6.4 · 5⁻`. Reports with neither are left out; null when fewer than two
/// remain, since one line would only repeat the estimate above it.
Widget? _history(List<EventReport> reports, AppLocalizations l10n) {
  final rows = <EventDetailRow>[];
  for (final report in reports) {
    final facts = eventFactsOfReport(report);
    final value = [
      for (final kind in const [
        EventFactKind.magnitude,
        EventFactKind.maxIntensity,
      ])
        ?facts.where((fact) => fact.kind == kind).firstOrNull?.display,
    ].join(' · ');
    if (value.isEmpty) continue;
    rows.add(
      EventDetailRow(
        label: l10n.eventReportSerial(report.serial),
        value: value,
      ),
    );
  }
  return rows.length < 2 ? null : EventDetailRows(rows: rows);
}

/// Taipei `HH:mm` of a CWA EEW's origin time, `addition.eq.time` in Unix ms;
/// null when the time is absent or not a positive whole number.
String? _originTime(EventReport report) {
  final ms = additionEpochMs(additionMap(report.addition?['eq'])?['time']);
  return ms == null ? null : eventClock(ms);
}
