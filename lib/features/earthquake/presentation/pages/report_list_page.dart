/// Earthquake report catalogue — paginated list from Core `GET /api/v2/eq/report`.
library;

import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/realtime/app_time.dart';
import 'package:dpip/core/settings/locale_config.dart';
import 'package:dpip/shared/seismic/intensity.dart';
import 'package:dpip/features/earthquake/domain/partial_earthquake_report.dart';
import 'package:dpip/features/earthquake/domain/report_repository.dart';
import 'package:dpip/features/earthquake/presentation/report_list_controller.dart';
import 'package:dpip/features/earthquake/presentation/widgets/report_filter_sheet.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/navigation/app_routes.dart';
import 'package:dpip/shared/seismic/intensity_colors.dart';
import 'package:dpip/shared/seismic/report_colors.dart';
import 'package:dpip/shared/widgets/empty_view.dart';
import 'package:dpip/shared/widgets/error_view.dart';
import 'package:dpip/shared/widgets/intensity_badge.dart';
import 'package:dpip/shared/widgets/loading_view.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// Scrollable report list under the Data tab — infinite scroll + filter sheet.
///
/// Filter edits are remembered in [ReportListController.draft] until this page
/// is popped. Opening the filter does not hit the API — only the sheet's
/// search button (and enter / resume reload) does. Pull-to-refresh is disabled;
/// the catalogue refreshes on every entry and when the app returns from
/// background.
///
/// Rows are grouped by Taipei calendar day into section cards.
class ReportListPage extends StatefulWidget {
  const ReportListPage({super.key});

  /// Data hub branch index in [MainShell] (must match `DataPage.tabIndex`).
  static const int tabIndex = 3;

  @override
  State<ReportListPage> createState() => _ReportListPageState();
}

class _ReportListPageState extends State<ReportListPage> {
  late final ReportListController _controller;
  final ScrollController _scroll = ScrollController();
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _controller = ReportListController(context.read<ReportRepository>());
    _scroll.addListener(_onScroll);
    _lifecycle = AppLifecycleListener(onResume: _refresh);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _scroll
      ..removeListener(_onScroll)
      ..dispose();
    _controller.dispose();
    super.dispose();
  }

  void _refresh() {
    if (!mounted) return;
    _controller.reload();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final pos = _scroll.position;
    if (pos.pixels >= pos.maxScrollExtent - 480) {
      _controller.loadMore();
    }
  }

  Future<void> _openFilter() async {
    final result = await showReportFilterSheet(
      context,
      initial: _controller.draft,
    );
    if (result == null || !mounted) return;
    // Always keep edits — dismiss without 查詢 must not wipe dates/sliders.
    _controller.setDraft(result.query);
    if (!result.search) return;
    await _controller.search();
    if (!mounted) return;
    if (_scroll.hasClients) {
      _scroll.jumpTo(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navEarthquake),
        actions: [
          ListenableBuilder(
            listenable: _controller,
            builder: (context, _) {
              final draftActive = !_controller.draft.isEmpty;
              return IconButton(
                tooltip: l10n.reportFilterTitle,
                onPressed: _openFilter,
                icon: Badge(
                  isLabelVisible: draftActive,
                  child: Icon(
                    draftActive ? Icons.filter_alt : Icons.filter_alt_outlined,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) => _body(context),
      ),
    );
  }

  Widget _body(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = _controller;

    if (c.loading && c.items.isEmpty) {
      return const LoadingView();
    }
    if (c.failure != null && c.items.isEmpty) {
      return ErrorView(detail: c.failure!.message, onRetry: c.reload);
    }
    if (c.isEmpty) {
      return EmptyView(
        icon: Icons.monitor_heart_outlined,
        message: c.query.isEmpty
            ? l10n.reportListEmpty
            : l10n.reportListEmptyFiltered,
      );
    }

    final bottomPad = AppSpacing.xl + MediaQuery.paddingOf(context).bottom;
    final sections = groupReportsByTaipeiDay(c.items);
    final extra = c.loadingMore || !c.hasMore ? 1 : 0;

    return ListView.builder(
      controller: _scroll,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        bottomPad,
      ),
      itemCount: sections.length + extra,
      itemBuilder: (context, index) {
        if (index >= sections.length) {
          if (c.loadingMore) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Center(child: InlineLoading()),
            );
          }
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Center(
              child: Text(
                l10n.reportListEnd,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          );
        }
        final section = sections[index];
        return Padding(
          padding: EdgeInsets.only(
            bottom: index == sections.length - 1 && extra == 0
                ? 0
                : AppSpacing.lg,
          ),
          child: _DaySection(day: section.day, reports: section.reports),
        );
      },
    );
  }
}

/// One Taipei calendar day and its reports (newest-first within the day).
@visibleForTesting
class ReportDaySection {
  const ReportDaySection({required this.day, required this.reports});

  /// Calendar day at midnight Taipei (date components only).
  final DateTime day;
  final List<PartialEarthquakeReport> reports;
}

/// Groups [items] into consecutive Taipei-day buckets (list order preserved).
@visibleForTesting
List<ReportDaySection> groupReportsByTaipeiDay(
  List<PartialEarthquakeReport> items,
) {
  final sections = <ReportDaySection>[];
  for (final report in items) {
    final day = taipeiCalendarDay(report.originTimeUtc);
    if (sections.isEmpty || sections.last.day != day) {
      sections.add(ReportDaySection(day: day, reports: [report]));
    } else {
      sections.last.reports.add(report);
    }
  }
  return sections;
}

/// Taipei calendar date of a UTC instant (date-only, comparable with `==`).
@visibleForTesting
DateTime taipeiCalendarDay(DateTime utc) {
  final t = AppTime.taipei(utc);
  return DateTime(t.year, t.month, t.day);
}

class _DaySection extends StatelessWidget {
  const _DaySection({required this.day, required this.reports});

  final DateTime day;
  final List<PartialEarthquakeReport> reports;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ReportDayHeader(day: day, count: reports.length),
        Material(
          color: colors.surfaceContainer,
          borderRadius: AppRadius.medium,
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < reports.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    thickness: 1,
                    indent: AppSpacing.md + 48 + AppSpacing.md,
                    color: colors.outlineVariant.withValues(alpha: 0.4),
                  ),
                _ReportTile(report: reports[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// One day's heading: the date on the left, the report count on the right, and
/// a rule filling whatever is left between them.
///
/// Test-visible so the geometry can be pinned without standing up the page's
/// repository — the flex arithmetic below is the whole reason this is a widget
/// of its own.
@visibleForTesting
class ReportDayHeader extends StatelessWidget {
  const ReportDayHeader({required this.day, required this.count, super.key});

  /// Calendar day at midnight Taipei, as [taipeiCalendarDay] returns it.
  final DateTime day;

  /// How many reports this day holds.
  final int count;

  /// Width held back from the date for everything to its right: the two gaps, a
  /// stub of rule so the row never reads as a bare date, and room for a
  /// three-digit count.
  ///
  /// Past this the date scales down rather than pushing the count off the row.
  /// Deliberately a reserve and not a fraction of the row: a half-the-row cap
  /// shrinks a Taipei date with its weekday on any phone, which is the same
  /// disease as the flex layout it replaced. At phone width this leaves the date
  /// well over what it needs.
  static const double _trailingReserve = AppSpacing.sm * 3 + 32;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final locale = intlDateLocale(Localizations.localeOf(context));

    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.xs,
        bottom: AppSpacing.sm,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) => Row(
          children: [
            // Bounded, but *not* flexible. An Expanded here would hand the
            // date a tight half of the row: a short date then sits in a hole
            // with the rule starting at the midpoint, and a long one gets
            // scaled down to half width with empty space beside it. A
            // Flexible has the mirror flaw — Row splits the free space evenly
            // between flex children and never gives a tight child what a
            // loose sibling left over, so the rule would stop at the midpoint
            // and the count would drift in from the right edge. Keeping the
            // date rigid leaves the rule as the only flex child, which is
            // what makes it fill the real remainder.
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: (constraints.maxWidth - _trailingReserve).clamp(
                  0.0,
                  double.infinity,
                ),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  reportDayLabel(
                    day,
                    todayTaipei: taipeiCalendarDay(AppTime.utc),
                    l10n: l10n,
                    locale: locale,
                  ),
                  softWrap: false,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Divider(
                height: 1,
                thickness: 1,
                color: colors.outlineVariant.withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              l10n.reportListDayCount(count),
              style: theme.textTheme.labelMedium?.copyWith(
                color: colors.onSurfaceVariant,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The heading's date text: the localized date, with a relative hint appended
/// in parentheses when [day] is [todayTaipei] or the day before it.
///
/// The date always leads and is always the same format — `今天` alone answers
/// "which day is this" only for someone who already knows today's date, and a
/// relative-only heading changes meaning overnight while the list is open.
///
/// [todayTaipei] is a parameter rather than a read of [AppTime] so this stays a
/// pure function of its inputs: "today" is the part worth testing, and a
/// process-wide clock cannot be wound forward for one test without leaking into
/// the next.
@visibleForTesting
String reportDayLabel(
  DateTime day, {
  required DateTime todayTaipei,
  required AppLocalizations l10n,
  required String locale,
}) {
  String? relative;
  if (day == todayTaipei) {
    relative = l10n.reportListToday;
  } else if (day == todayTaipei.subtract(const Duration(days: 1))) {
    relative = l10n.reportListYesterday;
  }
  final date = _dayFormats
      .putIfAbsent(locale, () => DateFormat.yMMMEd(locale))
      .format(day);
  return relative == null ? date : '$date ($relative)';
}

/// One [DateFormat] per locale — building one is not cheap and a scrolling list
/// rebuilds these headings constantly.
final Map<String, DateFormat> _dayFormats = {};

class _ReportTile extends StatelessWidget {
  const _ReportTile({required this.report});

  final PartialEarthquakeReport report;

  static final DateFormat _stampFormat = DateFormat('HH:mm:ss');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final taipei = AppTime.taipei(report.originTimeUtc);
    final stamp = _stampFormat.format(taipei);
    final intensity = Intensity.displayForReport(
      report.intensity,
      report.originTimeUtc,
    );
    final intensityColor = IntensityColors.discrete(intensity.colorLevel);
    final mag = report.magnitude.toStringAsFixed(1);

    return InkWell(
      onTap: () => context.pushNamed(
        AppRoutes.earthquakeReport,
        pathParameters: {'id': report.id},
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            IntensityBadge(
              label: intensity.label,
              color: intensityColor,
              outlined: !report.hasNumber,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    report.shortLocation,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    stamp,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              l10n.reportListMagnitude(mag),
              style: theme.textTheme.headlineSmall?.copyWith(
                color: report.hasNumber
                    ? ReportColors.numberedMagnitude
                    : colors.onSurface,
                fontWeight: FontWeight.w800,
                height: 1,
                letterSpacing: -0.5,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
