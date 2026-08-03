/// Earthquake report catalogue — paginated list from Core `GET /api/v2/eq/report`.
library;

import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/features/earthquake/domain/intensity.dart';
import 'package:dpip/features/earthquake/domain/partial_earthquake_report.dart';
import 'package:dpip/features/earthquake/domain/report_repository.dart';
import 'package:dpip/features/earthquake/presentation/report_list_controller.dart';
import 'package:dpip/features/earthquake/presentation/widgets/report_filter_sheet.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/navigation/refresh_on_appear.dart';
import 'package:dpip/shared/seismic/intensity_colors.dart';
import 'package:dpip/shared/widgets/empty_view.dart';
import 'package:dpip/shared/widgets/error_view.dart';
import 'package:dpip/shared/widgets/loading_view.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// Scrollable report list under the Data tab — infinite scroll + filter sheet.
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

  @override
  void initState() {
    super.initState();
    _controller = ReportListController(context.read<ReportRepository>());
    _scroll.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.reload();
    });
  }

  @override
  void dispose() {
    _scroll
      ..removeListener(_onScroll)
      ..dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final pos = _scroll.position;
    if (pos.pixels >= pos.maxScrollExtent - 480) {
      _controller.loadMore();
    }
  }

  Future<void> _openFilter() async {
    final next = await showReportFilterSheet(
      context,
      initial: _controller.query,
    );
    if (next == null || !mounted) return;
    if (next == _controller.query) return;
    await _controller.reload(query: next);
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
              final active = !_controller.query.isEmpty;
              return IconButton(
                tooltip: l10n.reportFilterTitle,
                onPressed: _openFilter,
                icon: Badge(
                  isLabelVisible: active,
                  child: Icon(
                    active ? Icons.filter_alt : Icons.filter_alt_outlined,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshOnAppear(
        tabIndex: ReportListPage.tabIndex,
        onAppear: () => _controller.reload(),
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) => _body(context),
        ),
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
        message: l10n.reportListEmpty,
      );
    }

    final bottomPad = AppSpacing.xl + MediaQuery.paddingOf(context).bottom;
    final extra = c.loadingMore || !c.hasMore ? 1 : 0;

    return RefreshIndicator(
      onRefresh: () => c.reload(),
      child: ListView.separated(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          bottomPad,
        ),
        itemCount: c.items.length + extra,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          if (index >= c.items.length) {
            if (c.loadingMore) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
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
          return _ReportTile(report: c.items[index]);
        },
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
