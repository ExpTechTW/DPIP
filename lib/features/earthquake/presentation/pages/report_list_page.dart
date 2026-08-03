/// Earthquake report catalogue — paginated list from Core `GET /api/v2/eq/report`.
library;

import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/features/earthquake/domain/intensity.dart';
import 'package:dpip/features/earthquake/domain/partial_earthquake_report.dart';
import 'package:dpip/features/earthquake/domain/report_repository.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/navigation/refresh_on_appear.dart';
import 'package:dpip/shared/seismic/intensity_colors.dart';
import 'package:dpip/shared/widgets/async_view.dart';
import 'package:dpip/shared/widgets/empty_view.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// Scrollable report list under the Data tab. Re-fetches on tab reappear.
class ReportListPage extends StatefulWidget {
  const ReportListPage({super.key});

  /// Data hub branch index in [MainShell] (must match `DataPage.tabIndex`).
  static const int tabIndex = 3;

  @override
  State<ReportListPage> createState() => _ReportListPageState();
}

class _ReportListPageState extends State<ReportListPage> {
  final RefreshSignal _refresh = RefreshSignal();

  @override
  void dispose() {
    _refresh.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final repository = context.read<ReportRepository>();
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navEarthquake)),
      body: RefreshOnAppear(
        tabIndex: ReportListPage.tabIndex,
        onAppear: _refresh.fire,
        child: AsyncView<List<PartialEarthquakeReport>>(
          future: () => repository.list(limit: 50, page: 1),
          isEmpty: (reports) => reports.isEmpty,
          empty: (_) => EmptyView(
            icon: Icons.monitor_heart_outlined,
            message: l10n.reportListEmpty,
          ),
          refreshSignal: _refresh,
          builder: (context, reports) => ListView.separated(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.xl + MediaQuery.paddingOf(context).bottom,
            ),
            itemCount: reports.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) =>
                _ReportTile(report: reports[index]),
          ),
        ),
      ),
    );
  }
}

class _ReportTile extends StatelessWidget {
  const _ReportTile({required this.report});

  final PartialEarthquakeReport report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final local = report.originTimeUtc.toLocal();
    final stamp = DateFormat('yyyy/MM/dd HH:mm').format(local);
    final intensityColor = IntensityColors.discrete(report.intensity);

    return Material(
      color: colors.surfaceContainer,
      borderRadius: AppRadius.medium,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: null, // Detail route lands next.
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              _IntensityBadge(level: report.intensity, color: intensityColor),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.shortLocation,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      stamp,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      l10n.reportListMeta(
                        report.magnitude.toStringAsFixed(1),
                        report.depth.toStringAsFixed(1),
                      ),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (report.hasNumber)
                Text(
                  report.number!,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.outline,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IntensityBadge extends StatelessWidget {
  const _IntensityBadge({required this.level, required this.color});

  final int level;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final onBadge =
        ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? Colors.white
        : Colors.black87;
    return DecoratedBox(
      decoration: BoxDecoration(color: color, borderRadius: AppRadius.small),
      child: SizedBox(
        width: 44,
        height: 44,
        child: Center(
          child: Text(
            Intensity.label(level),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: onBadge,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ),
    );
  }
}
