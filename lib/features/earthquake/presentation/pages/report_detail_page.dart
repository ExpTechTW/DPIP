/// Full report detail — the app's own map (epicentre + per-town intensity
/// dots) with a swipe-up sheet for 詳細資訊 + 各地震度, opened from a
/// [ReportListPage] catalogue row.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:dpip/app/theme/app_motion.dart';
import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/features/earthquake/domain/earthquake_report.dart';
import 'package:dpip/features/earthquake/domain/intensity.dart';
import 'package:dpip/features/earthquake/domain/report_repository.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/map/base_map.dart';
import 'package:dpip/shared/map/camera_fit.dart';
import 'package:dpip/shared/seismic/intensity_colors.dart';
import 'package:dpip/shared/seismic/report_colors.dart';
import 'package:dpip/shared/widgets/async_view.dart';
import 'package:dpip/shared/widgets/frosted_surface.dart';
import 'package:dpip/shared/widgets/intensity_badge.dart';
import 'package:dpip/shared/widgets/section_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// Fetches and shows the full report for [reportId] — epicentre, magnitude,
/// depth, and the per-area/town felt-intensity breakdown.
///
/// No persistent app bar: the map fills the whole page behind a floating back
/// button (peek state); a pinned "地震報告" header — with its own back button —
/// only appears once the sheet is dragged up to its expanded content (see
/// [_ExpandedHeader]) and stays fixed while that content scrolls, matching
/// the legacy app, where that title bar was part of the sheet's full state,
/// not the page chrome. Exactly one back button is ever on screen:
/// [_sheetExpanded] toggles which one, so expanding the sheet hides the
/// floating button instead of stacking both.
class ReportDetailPage extends StatefulWidget {
  const ReportDetailPage({super.key, required this.reportId});

  /// The report id (e.g. `115053-2026-0731-005836`), from the route's `:id`.
  final String reportId;

  @override
  State<ReportDetailPage> createState() => _ReportDetailPageState();
}

class _ReportDetailPageState extends State<ReportDetailPage> {
  final ValueNotifier<bool> _sheetExpanded = ValueNotifier(false);

  @override
  void dispose() {
    _sheetExpanded.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repository = context.read<ReportRepository>();
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: AsyncView<EarthquakeReport>(
              future: () => repository.get(widget.reportId),
              builder: (context, report) => _ReportMapDetail(
                report: report,
                sheetExpanded: _sheetExpanded,
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: ValueListenableBuilder<bool>(
                  valueListenable: _sheetExpanded,
                  builder: (context, expanded, child) =>
                      expanded ? const SizedBox.shrink() : child!,
                  child: FrostedSurface(
                    borderRadius: AppRadius.large,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => context.pop(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The report's epicentre + station bounds, in the map library's coordinate
/// type — computed here (not on the domain model) so the domain layer stays
/// free of a `maplibre_gl` dependency.
LatLngBounds _reportBounds(EarthquakeReport report) {
  var minLat = report.latitude, maxLat = report.latitude;
  var minLon = report.longitude, maxLon = report.longitude;
  for (final area in report.list.values) {
    for (final town in area.town.values) {
      minLat = math.min(minLat, town.latitude);
      maxLat = math.max(maxLat, town.latitude);
      minLon = math.min(minLon, town.longitude);
      maxLon = math.max(maxLon, town.longitude);
    }
  }
  return LatLngBounds(
    southwest: LatLng(minLat, minLon),
    northeast: LatLng(maxLat, maxLon),
  );
}

/// One 震度 level's counties (縣市) and, per county, the felt area/town names —
/// grouping by intensity first (highest first), not by county, mirrors the
/// reference report layout: the level is stated once per group instead of
/// once per chip.
class _IntensityGroup {
  const _IntensityGroup({required this.intensity, required this.counties});

  final int intensity;
  final List<_CountyAreas> counties;
}

/// One county's felt area/town names at its parent [_IntensityGroup]'s level.
class _CountyAreas {
  const _CountyAreas({required this.countyName, required this.areaNames});

  final String countyName;
  final List<String> areaNames;
}

/// Regroups the report's county→town map by intensity level (highest first),
/// then by county, preserving each county's/town's original (API) order
/// within that.
List<_IntensityGroup> _buildIntensityGroups(EarthquakeReport report) {
  final byIntensity = <int, Map<String, List<String>>>{};
  for (final MapEntry(key: countyName, value: area) in report.list.entries) {
    for (final MapEntry(key: townName, value: town) in area.town.entries) {
      byIntensity
          .putIfAbsent(town.intensity, () => {})
          .putIfAbsent(countyName, () => [])
          .add(townName);
    }
  }
  final levels = byIntensity.keys.toList()..sort((a, b) => b.compareTo(a));
  return [
    for (final intensity in levels)
      _IntensityGroup(
        intensity: intensity,
        counties: [
          for (final MapEntry(key: countyName, value: areaNames)
              in byIntensity[intensity]!.entries)
            _CountyAreas(countyName: countyName, areaNames: areaNames),
        ],
      ),
  ];
}

/// The map surface: epicentre + per-town intensity dots, framed to the
/// report's extent, with [_ReportSheet] docked at the bottom.
class _ReportMapDetail extends StatefulWidget {
  const _ReportMapDetail({required this.report, required this.sheetExpanded});

  final EarthquakeReport report;

  /// Set by [_ReportSheet] as it's dragged — drives the page's floating back
  /// button's visibility (see [ReportDetailPage]).
  final ValueNotifier<bool> sheetExpanded;

  @override
  State<_ReportMapDetail> createState() => _ReportMapDetailState();
}

class _ReportMapDetailState extends State<_ReportMapDetail> {
  static const String _sourceId = 'report-detail-src';
  static const String _symbolLayerId = 'report-detail-symbol';

  /// Icon size by zoom — far past the legacy app's `kSymbolIconSize` (5 →
  /// 0.2, 15 → 0.6): those source PNGs render at native (device-pixel) size,
  /// so on a modern 3x display that old scale is only ~20 logical px — this
  /// page needs the marker legible at a glance, so it's sized up accordingly.
  static const List<Object> _iconSizeExpression = [
    'interpolate',
    ['linear'],
    ['zoom'],
    5,
    0.75,
    15,
    1.7,
  ];

  /// `intensity-1`…`intensity-9` (+ `-dark`) and `cross` — the legacy app's
  /// own map-marker artwork, ported verbatim (same PNGs) so the report map
  /// looks exactly as it did before, not a new icon style.
  static final List<String> _iconNames = [
    'cross',
    for (var i = 1; i <= 9; i++) 'intensity-$i',
    for (var i = 1; i <= 9; i++) 'intensity-$i-dark',
  ];

  MapLibreMapController? _controller;
  bool _iconsLoaded = false;

  void _onMapCreated(MapLibreMapController controller) {
    _controller = controller;
  }

  Future<void> _onStyleLoaded() async {
    final controller = _controller;
    if (controller == null) return;
    final dark = Theme.of(context).brightness == Brightness.dark;
    try {
      if (!_iconsLoaded) {
        await _loadIcons(controller);
        _iconsLoaded = true;
      }
      await controller.addSource(
        _sourceId,
        GeojsonSourceProperties(data: _geoJson(dark: dark)),
      );
      await controller.addSymbolLayer(
        _sourceId,
        _symbolLayerId,
        const SymbolLayerProperties(
          iconImage: ['get', 'icon'],
          iconSize: _iconSizeExpression,
          iconAllowOverlap: true,
          iconIgnorePlacement: true,
          symbolZOrder: 'source',
        ),
      );
    } catch (e, st) {
      Log.handle(e, st, 'report detail map render failed');
    }
    _frame();
  }

  /// Registers every marker icon once — cheap enough (19 small PNGs) to load
  /// eagerly rather than lazily per feature.
  Future<void> _loadIcons(MapLibreMapController controller) async {
    for (final name in _iconNames) {
      final data = await rootBundle.load('assets/map/icons/$name.png');
      await controller.addImage(name, data.buffer.asUint8List());
    }
  }

  /// Fits the camera once, leaving room for the sheet at its resting height —
  /// not re-run on drag (the sheet's resting fraction is a fixed chrome
  /// allowance, matching [MapScaffold]'s per-layer `bottomChromeFraction`).
  void _frame() {
    final controller = _controller;
    if (controller == null || !mounted) return;
    final bounds = safeFitBounds(_reportBounds(widget.report));
    if (bounds == null) return;
    final size = MediaQuery.sizeOf(context);
    final fit = boundsFitCamera(
      bounds,
      viewport: size,
      topInset: MediaQuery.paddingOf(context).top,
      bottomInset: size.height * _ReportSheet.rest,
    );
    if (fit == null) return;
    controller.moveCamera(CameraUpdate.newLatLngZoom(fit.target, fit.zoom));
  }

  /// Every town marker (sorted low→high intensity, so a hot reading draws on
  /// top of a calm one) plus the epicentre cross last — same draw order as
  /// the legacy app's `EarthquakeReport.toGeoJson()`.
  Map<String, dynamic> _geoJson({required bool dark}) {
    final report = widget.report;
    final towns = <StationIntensity>[
      for (final area in report.list.values) ...area.town.values,
    ]..sort((a, b) => a.intensity.compareTo(b.intensity));

    final features = <Map<String, dynamic>>[
      for (final town in towns)
        {
          'type': 'Feature',
          'geometry': {
            'type': 'Point',
            'coordinates': [town.longitude, town.latitude],
          },
          'properties': {
            'icon': 'intensity-${town.intensity}${dark ? '' : '-dark'}',
          },
        },
      {
        'type': 'Feature',
        'geometry': {
          'type': 'Point',
          'coordinates': [report.longitude, report.latitude],
        },
        'properties': {'icon': 'cross'},
      },
    ];
    return {'type': 'FeatureCollection', 'features': features};
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: BaseMap(
            showUserLocation: false,
            onMapCreated: _onMapCreated,
            onStyleLoaded: () => unawaited(_onStyleLoaded()),
          ),
        ),
        Positioned.fill(
          child: _ReportSheet(
            report: widget.report,
            expandedNotifier: widget.sheetExpanded,
          ),
        ),
      ],
    );
  }
}

/// The draggable bottom sheet — mirrors the legacy `MorphingSheet`'s two
/// distinct layouts (not one continuously-revealed list): [peek] shows a
/// compact summary card, dragged past the midpoint swaps to the full
/// 詳細資訊 + 各地震度 + report-image content under a pinned "地震報告" header
/// that stays fixed while that content scrolls.
class _ReportSheet extends StatefulWidget {
  const _ReportSheet({required this.report, required this.expandedNotifier});

  final EarthquakeReport report;

  /// Mirrors this sheet's collapsed/expanded state up to the page, so it can
  /// hide its floating back button while the sheet's own header has one.
  final ValueNotifier<bool> expandedNotifier;

  /// Collapsed height — sized to the compact summary card.
  static const double peek = 0.32;

  /// Alias kept for the map's bottom-inset framing (see [_ReportMapDetailState._frame]).
  static const double rest = peek;

  static const double _expanded = 1.0;
  static const double _switchThreshold = (peek + _expanded) / 2;

  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  final ValueNotifier<double> _extent = ValueNotifier(_ReportSheet.peek);

  /// Programmatically collapses the sheet back to its [peek] state — used by
  /// the expanded header's back button, which folds the sheet down to the map
  /// rather than popping the page.
  final DraggableScrollableController _dragController =
      DraggableScrollableController();

  @override
  void dispose() {
    _extent.dispose();
    _dragController.dispose();
    super.dispose();
  }

  void _collapse() {
    _dragController.animateTo(
      _ReportSheet.peek,
      duration: AppMotion.medium,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final report = widget.report;

    return Align(
      alignment: Alignment.bottomCenter,
      child: NotificationListener<DraggableScrollableNotification>(
        onNotification: (notification) {
          _extent.value = notification.extent;
          // Runs from the scroll-notification dispatch, not mid-build, so
          // it's safe to update the page-level notifier the floating back
          // button listens to.
          widget.expandedNotifier.value =
              notification.extent >= _ReportSheet._switchThreshold;
          return false;
        },
        child: DraggableScrollableSheet(
          controller: _dragController,
          initialChildSize: _ReportSheet.peek,
          minChildSize: _ReportSheet.peek,
          maxChildSize: _ReportSheet._expanded,
          snap: true,
          builder: (context, scrollController) {
            return DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: AppRadius.topSheet,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 16,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: AppRadius.topSheet,
                child: ValueListenableBuilder<double>(
                  valueListenable: _extent,
                  builder: (context, extent, _) {
                    final expanded = extent >= _ReportSheet._switchThreshold;
                    // Flush with the screen top at full extent — the status
                    // bar/notch inset has to come back as padding on the
                    // expanded header, or it renders underneath it.
                    final atTop = extent >= _ReportSheet._expanded - 0.02;
                    return Column(
                      children: [
                        // Pinned above the scroll body, not a scrolling item:
                        // the "地震報告" bar (back button + title) stays while
                        // the 詳細資訊 content scrolls underneath it. Keep the
                        // ListView's horizontal inset on the header too, so it
                        // sits where it did when it was the list's first child.
                        if (expanded)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg,
                            ),
                            child: _ExpandedHeader(
                              atTop: atTop,
                              onBack: _collapse,
                            ),
                          ),
                        Expanded(
                          child: ListView(
                            controller: scrollController,
                            padding: EdgeInsets.fromLTRB(
                              AppSpacing.lg,
                              expanded ? 0 : AppSpacing.md,
                              AppSpacing.lg,
                              AppSpacing.xl +
                                  MediaQuery.paddingOf(context).bottom,
                            ),
                            children: expanded
                                ? _expandedContent(context, report)
                                : _peekContent(context, report),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _peekContent(BuildContext context, EarthquakeReport report) => [
    _ReportPeekSummary(report: report),
  ];

  List<Widget> _expandedContent(BuildContext context, EarthquakeReport report) {
    final l10n = AppLocalizations.of(context);
    final groups = _buildIntensityGroups(report);
    return [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ReportHeader(report: report),
            const SizedBox(height: AppSpacing.lg),
            SectionHeader(l10n.reportDetailInfo),
            _ReportInfoCard(report: report),
            if (groups.isNotEmpty) ...[
              SectionHeader(l10n.reportDetailAreaIntensity),
              _AreaIntensityCard(groups: groups),
            ],
            SectionHeader(l10n.reportDetailImage),
            _ReportImageCard(report: report),
          ],
        ),
      ),
    ];
  }
}

/// The expanded sheet's pinned header — appears only once dragged up (matches
/// the legacy `MorphingSheet.fullBuilder`'s `SliverAppBar`) and then stays
/// fixed above the scroll body while the 詳細資訊 content scrolls underneath:
/// a back button at the left and the "地震報告" title, flush at the top when
/// the sheet is fully extended. The page's floating back button hides itself
/// whenever this is showing (see [ReportDetailPage]), so there's never more
/// than one on screen.
///
/// Its back button **collapses** the sheet back to the map ([onBack]), not
/// pops the page — the floating button is what leaves (and only it is visible
/// in the collapsed state), so each state has exactly one sensible action.
class _ExpandedHeader extends StatelessWidget {
  const _ExpandedHeader({required this.atTop, required this.onBack});

  /// Whether the sheet is flush with the screen top — adds the status-bar
  /// inset back as padding so the row doesn't render underneath it.
  final bool atTop;

  /// Collapses the sheet to its peek state (showing the epicentre-intensity
  /// map), replacing the page-pop the floating back button does.
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final topInset = atTop ? MediaQuery.paddingOf(context).top : 0.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.sm,
        topInset + AppSpacing.xs,
        AppSpacing.sm,
        AppSpacing.xs,
      ),
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.arrow_back), onPressed: onBack),
          Expanded(
            child: Text(
              l10n.reportDetailTitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // Balances the leading back button so the title stays centred.
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

/// The collapsed sheet's compact summary — eyebrow/location/time to the left,
/// a large intensity badge to the right, then a magnitude/depth stat row.
/// Mirrors the legacy `MorphingSheet.partialBuilder` layout exactly.
class _ReportPeekSummary extends StatelessWidget {
  const _ReportPeekSummary({required this.report});

  final EarthquakeReport report;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final presentation = Intensity.displayForReport(
      report.maxIntensity,
      report.originTimeUtc,
    );
    final taipei = report.originTimeUtc.add(const Duration(hours: 8));
    final time = DateFormat('yyyy/MM/dd HH:mm:ss').format(taipei);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    report.hasNumber
                        ? l10n.reportDetailNumbered(report.number!)
                        : l10n.reportDetailLocalFelt,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colors.outline,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    report.shortLocation,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    time,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            IntensityBadge(
              label: presentation.label,
              color: IntensityColors.discrete(presentation.colorLevel),
              size: 56,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _PeekStat(
                label: l10n.reportDetailMagnitude,
                value: l10n.reportListMagnitude(
                  report.magnitude.toStringAsFixed(1),
                ),
              ),
            ),
            Expanded(
              child: _PeekStat(
                label: l10n.reportDetailDepth,
                value: l10n.reportFilterDepthKm(
                  report.depth.toStringAsFixed(1),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PeekStat extends StatelessWidget {
  const _PeekStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

/// Intensity badge + numbered/local-felt eyebrow + location — the expanded
/// sheet's header, with a filled chip opening the official CWA report page.
class _ReportHeader extends StatelessWidget {
  const _ReportHeader({required this.report});

  final EarthquakeReport report;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final presentation = Intensity.displayForReport(
      report.maxIntensity,
      report.originTimeUtc,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IntensityBadge(
              label: presentation.label,
              color: IntensityColors.discrete(presentation.colorLevel),
              size: 56,
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    report.hasNumber
                        ? l10n.reportDetailNumbered(report.number!)
                        : l10n.reportDetailLocalFelt,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colors.outline,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    report.shortLocation,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        ActionChip(
          avatar: Icon(Icons.open_in_new, size: 16, color: colors.onPrimary),
          label: Text(l10n.reportDetailOpenReport),
          backgroundColor: colors.primary,
          labelStyle: TextStyle(color: colors.onPrimary),
          side: BorderSide(color: colors.primary),
          onPressed: () => _openReportPage(context),
        ),
      ],
    );
  }

  Future<void> _openReportPage(BuildContext context) async {
    try {
      await launchUrl(report.reportUrl, mode: LaunchMode.externalApplication);
    } catch (e, st) {
      Log.handle(e, st, 'open report page failed: ${report.reportUrl}');
    }
  }
}

/// 發震時間 / 震央座標 / 地震規模 / 震源深度 as a bordered info card.
class _ReportInfoCard extends StatelessWidget {
  const _ReportInfoCard({required this.report});

  final EarthquakeReport report;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final taipei = report.originTimeUtc.add(const Duration(hours: 8));
    final originTime = DateFormat('yyyy/MM/dd HH:mm:ss').format(taipei);
    final coordinates =
        '${report.latitude.toStringAsFixed(2)}°N・'
        '${report.longitude.toStringAsFixed(2)}°E';

    return Material(
      color: colors.surfaceContainer,
      borderRadius: AppRadius.medium,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _InfoRow(label: l10n.reportDetailOriginTime, value: originTime),
          const Divider(height: 1),
          _InfoRow(label: l10n.reportDetailEpicenter, value: coordinates),
          const Divider(height: 1),
          _InfoRow(
            label: l10n.reportDetailMagnitude,
            value: l10n.reportListMagnitude(
              report.magnitude.toStringAsFixed(1),
            ),
            dotColor: MagnitudeColors.of(report.magnitude),
          ),
          const Divider(height: 1),
          _InfoRow(
            label: l10n.reportDetailDepth,
            value: l10n.reportFilterDepthKm(report.depth.toStringAsFixed(1)),
            dotColor: DepthColors.of(report.depth),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.dotColor});

  final String label;
  final String value;
  final Color? dotColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          if (dotColor != null) ...[
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Text(
            value,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// 各地震度 — grouped by felt intensity (highest first), not by county: each
/// [_IntensityGroup] states its level once in a left-hand column via
/// [IntensityBadge], with every county (bold) and its felt areas listed to
/// the right, left-to-right/top-to-bottom.
class _AreaIntensityCard extends StatelessWidget {
  const _AreaIntensityCard({required this.groups});

  final List<_IntensityGroup> groups;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surfaceContainer,
      borderRadius: AppRadius.medium,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < groups.length; i++)
            _IntensityGroupRow(group: groups[i]),
        ],
      ),
    );
  }
}

/// One 震度 level's band — a background wash of its palette [IntensityColors]
/// colour (strongest at the top, fading as intensity drops down the card)
/// stands in for the vertical divider line a plain list would need, reading
/// as a single severity gradient at a glance (the broadcast-graphic
/// convention this section's reference design followed).
class _IntensityGroupRow extends StatelessWidget {
  const _IntensityGroupRow({required this.group});

  final _IntensityGroup group;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    // Raw wire intensity, not [Intensity.displayForReport] — per-town/group
    // readings have always been on the fine 0–9 scale (only the top-level
    // report max needed the pre-2020 legacy-scale remap).
    final label = Intensity.label(group.intensity);
    final color = IntensityColors.discrete(group.intensity);

    return DecoratedBox(
      decoration: BoxDecoration(color: color.withValues(alpha: 0.14)),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: IntensityBadge(label: label, color: color, size: 40),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < group.counties.length; i++) ...[
                    if (i > 0)
                      Divider(
                        height: 1,
                        indent: AppSpacing.md,
                        endIndent: AppSpacing.md,
                        color: colors.outlineVariant.withValues(alpha: 0.4),
                      ),
                    _CountyAreasRow(county: group.counties[i]),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountyAreasRow extends StatelessWidget {
  const _CountyAreasRow({required this.county});

  final _CountyAreas county;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.xs,
        children: [
          Text(
            county.countyName,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            // l10n-ignore: CJK enumeration comma (頓號) joining names, not display text itself.
            county.areaNames.join('、'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// 地震報告圖 — CWA's rendered report image; falls back to a plain message when
/// it hasn't been generated yet or fails to load.
class _ReportImageCard extends StatefulWidget {
  const _ReportImageCard({required this.report});

  final EarthquakeReport report;

  @override
  State<_ReportImageCard> createState() => _ReportImageCardState();
}

class _ReportImageCardState extends State<_ReportImageCard> {
  bool _failed = false;

  /// Placeholder height while loading / on failure — a guess, not the real
  /// aspect ratio (that varies per event), so it's only a skeleton size; the
  /// image itself sizes to its own natural proportions once loaded.
  static const double _placeholderHeight = 200;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;

    if (_failed) {
      return ClipRRect(
        borderRadius: AppRadius.medium,
        child: Container(
          height: _placeholderHeight,
          width: double.infinity,
          color: colors.surfaceContainer,
          alignment: Alignment.center,
          child: Text(
            l10n.reportDetailImageUnavailable,
            style: TextStyle(color: colors.onSurfaceVariant),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: AppRadius.medium,
      child: Image.network(
        widget.report.reportImageUrl.toString(),
        // No forced aspect ratio / BoxFit.cover — the report image's real
        // proportions vary per event, so this sizes to the image's own
        // natural aspect ratio at full width instead of cropping or padding.
        width: double.infinity,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            height: _placeholderHeight,
            width: double.infinity,
            color: colors.surfaceContainer,
            alignment: Alignment.center,
            child: const CircularProgressIndicator(),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _failed = true);
          });
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
