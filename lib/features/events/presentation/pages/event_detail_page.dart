import 'package:dpip/app/theme/app_caution.dart';
import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/realtime/app_time.dart';
import 'package:dpip/core/settings/locale_config.dart';
import 'package:dpip/features/events/domain/event_card.dart';
import 'package:dpip/features/events/domain/event_repository.dart';
import 'package:dpip/features/events/presentation/detail/event_type_details.dart';
import 'package:dpip/features/events/presentation/event_hazard_style.dart';
import 'package:dpip/features/events/presentation/event_labels.dart';
import 'package:dpip/features/events/presentation/widgets/event_status_chip.dart';
import 'package:dpip/features/events/presentation/widgets/event_untranslated.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/widgets/async_view.dart';
import 'package:dpip/shared/widgets/section_header.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

/// One event card in full: its latest report at the top, then every report it
/// has had, newest first.
///
/// Loaded through [AsyncView], so it has a loading state, an error state with
/// retry, pull-to-refresh, and a saved copy is shown under a freshness
/// banner, never as current. A cancelled card is still a card: its cancellation is the newest
/// report and the header says "cancelled".
///
/// What a card adds beyond that depends on its type: [eventTypeDetailFor]
/// picks a family (`presentation/detail/types/`) that may put a summary under
/// the header and content inside each report. An unknown type gets the
/// generic family, so it still renders.
///
/// A report with `hasPolygon` has an area on the map; this page does not draw
/// it yet and lists the reports only.
class EventDetailPage extends StatelessWidget {
  const EventDetailPage({super.key, required this.id, this.regionCode});

  /// The card id, from the route's `:id`.
  final int id;

  /// The township whose text the reports carry, from the route's `?region=`;
  /// null for the nationwide text.
  final String? regionCode;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final repository = context.read<EventRepository>();
    return Scaffold(
      appBar: AppBar(title: Text(l10n.eventDetailTitle)),
      body: AsyncView<EventCardDetail>(
        future: () => repository.detail(id: id, regionCode: regionCode),
        pullToRefresh: true,
        builder: (context, detail) => _DetailBody(detail: detail),
      ),
    );
  }

  /// [reports] by send time, newest first; reports sent at the same instant
  /// keep the later report (the larger serial) first.
  static List<EventReport> newestFirst(List<EventReport> reports) {
    final sorted = [...reports];
    sorted.sort((a, b) {
      final bySend = b.send.compareTo(a.send);
      return bySend != 0 ? bySend : b.serial.compareTo(a.serial);
    });
    return sorted;
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.detail});

  final EventCardDetail detail;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final reports = EventDetailPage.newestFirst(detail.reports);
    final summary = eventTypeDetailFor(detail.latest.type)
        .summary(context, detail);
    return ListView(
      // A card with one short report must still be pullable.
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg + MediaQuery.paddingOf(context).bottom,
      ),
      children: [
        _Header(latest: detail.latest),
        if (summary != null) ...[
          const SizedBox(height: AppSpacing.xl),
          summary,
        ],
        const SizedBox(height: AppSpacing.xl),
        SectionHeader(l10n.eventDetailReports),
        for (final report in reports) ...[
          _ReportEntry(key: ValueKey(report.serial), report: report),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

/// The card as it stands now: the latest report's hazard, title, subtitle
/// and state.
class _Header extends StatelessWidget {
  const _Header({required this.latest});

  final EventReport latest;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final status = EventCardStatus.ofCard(latest, AppTime.utc);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EventHazardBadge(hazard: latest.hazard, size: 48),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                latest.title.isEmpty ? '—' : latest.title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (latest.subtitle.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  latest.subtitle,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (status != null) EventStatusChip(status: status),
                  Text(
                    latest.hazard.label(l10n),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// One report: which one it is and of what kind, when it was sent, its text,
/// what its type's family adds, and its end time.
///
/// A report shown in translation carries its original text, and a toggle
/// swaps the title, subtitle and description to it and back.
class _ReportEntry extends StatefulWidget {
  const _ReportEntry({super.key, required this.report});

  final EventReport report;

  @override
  State<_ReportEntry> createState() => _ReportEntryState();
}

class _ReportEntryState extends State<_ReportEntry> {
  bool _showOriginal = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final locale = intlDateLocale(Localizations.localeOf(context));
    final report = widget.report;
    final original = report.original;
    final showOriginal = _showOriginal && original != null;
    final title = showOriginal ? original.title : report.title;
    final subtitle = showOriginal ? original.subtitle : report.subtitle;
    final description = showOriginal
        ? original.description
        : report.description;
    final body = eventTypeDetailFor(report.type).reportBody(context, report);
    final ends = !EventCardStatus.showsLifetime(report)
        ? null
        : report.expiresOpen
        ? l10n.eventDetailEndsUndetermined
        : switch (report.expires) {
            final expires? => eventDateTimeLabel(expires, locale: locale),
            null => null,
          };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: AppRadius.medium,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        l10n.eventReportSerial(report.serial),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      _KindChip(kind: report.kind),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  eventTimeLabel(
                    report.send,
                    nowUtc: AppTime.utc,
                    locale: locale,
                  ),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            if (report.untranslated) ...[
              const SizedBox(height: AppSpacing.md),
              const EventUntranslatedNotice(),
            ],
            const SizedBox(height: AppSpacing.md),
            Text(
              title.isEmpty ? '—' : title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
            if (description != null && description.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(description, style: theme.textTheme.bodyMedium),
            ],
            if (body != null) ...[const SizedBox(height: AppSpacing.md), body],
            if (ends != null) ...[
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Icon(
                    Icons.schedule_outlined,
                    size: 16,
                    color: colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      l10n.eventDetailEnds(ends),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (original != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  onPressed: () =>
                      setState(() => _showOriginal = !_showOriginal),
                  icon: const Icon(Icons.translate_outlined, size: 18),
                  label: Text(
                    showOriginal
                        ? l10n.eventDetailShowTranslation
                        : l10n.eventDetailShowOriginal,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The kind of a report as a small pill. A cancellation is drawn in the
/// error tone so it is not mistaken for another update; a correction — the
/// report was changed after it was issued, by its source or by hand, and
/// shows the corrected content — in the caution tone, so it reads as
/// "corrected" rather than as one more update. What it said before is not
/// shown, nor who corrected it.
class _KindChip extends StatelessWidget {
  const _KindChip({required this.kind});

  final EventReportKind kind;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final (fill, ink) = switch (kind) {
      EventReportKind.cancel => (
        colors.errorContainer,
        colors.onErrorContainer,
      ),
      EventReportKind.correct => (
        AppCaution.container(context),
        AppCaution.onContainer(context),
      ),
      _ => (colors.secondaryContainer, colors.onSecondaryContainer),
    };
    return DecoratedBox(
      decoration: BoxDecoration(color: fill, borderRadius: AppRadius.small),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs / 2,
        ),
        child: Text(
          eventReportKindLabel(kind, AppLocalizations.of(context)),
          style: theme.textTheme.labelSmall?.copyWith(
            color: ink,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
