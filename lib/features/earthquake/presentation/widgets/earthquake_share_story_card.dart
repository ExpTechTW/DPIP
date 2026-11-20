import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/realtime/app_time.dart';
import 'package:dpip/features/earthquake/domain/earthquake_report.dart';
import 'package:dpip/features/earthquake/presentation/story_camera_fit.dart';
import 'package:dpip/features/earthquake/presentation/story_map_snapshot.dart';
import 'package:dpip/features/earthquake/presentation/story_marker_layout.dart';
import 'package:dpip/features/earthquake/presentation/story_observation_clustering.dart';
import 'package:dpip/features/earthquake/presentation/widgets/earthquake_share_icon.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/seismic/intensity.dart';
import 'package:dpip/shared/seismic/intensity_colors.dart';
import 'package:dpip/shared/seismic/intensity_icon_renderer.dart';
import 'package:dpip/shared/seismic/spoken_intensity.dart';
import 'package:dpip/shared/widgets/intensity_badge.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:intl/intl.dart';

/// 9:16 earthquake report card for social stories.
///
/// Uses a fixed 360x640 logical canvas, intended for
/// rendering at 3x resolution (1080x1920).
class EarthquakeShareStoryCard extends StatefulWidget {
  const EarthquakeShareStoryCard({
    super.key,
    required this.report,
    this.mapPng,
    this.markerIcons = const {},
    this.stationMarkers = const [],
    this.epicenterPosition,
    this.showSafeAreaGuides = false,
    this.useD75Compact = const bool.fromEnvironment('DPIP_STORY_D75_COMPACT'),
    this.onMapLayout,
    this.onLayoutUnavailable,
    this.compositionKey,
  });

  final EarthquakeReport report;
  final Uint8List? mapPng;
  final Map<String, Uint8List> markerIcons;
  final List<StoryStationMarker> stationMarkers;
  final Offset? epicenterPosition;
  final bool showSafeAreaGuides;

  /// Opt-in while the 75 km validation threshold awaits product approval.
  final bool useD75Compact;
  final ValueChanged<StoryCameraLayout>? onMapLayout;
  final VoidCallback? onLayoutUnavailable;

  /// The rasterized content excludes the preview-only safe-area guides.
  final GlobalKey? compositionKey;

  static const brandImage = EarthquakeShareIcon.image;

  @override
  State<EarthquakeShareStoryCard> createState() =>
      _EarthquakeShareStoryCardState();

  // Instagram Story (9:16) safe-area test configuration.
  //
  // Logical canvas: 360x640
  // Planned export: 1080x1920 at 3x
  //
  // Instagram Story Template v2.
  // Experimental safe-area values based on real-device testing.
  static const double _safeTop = 56;
  static const double _safeBottom = 40;
  static const double _safeGap = 8;
  static const double _horizontalInset = AppSpacing.lg;
}

class _EarthquakeShareStoryCardState extends State<EarthquakeShareStoryCard> {
  final _debugCanvasKey = GlobalKey();
  final _debugLogoKey = GlobalKey();
  final _debugHudKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final EarthquakeShareStoryCard(
      :report,
      :mapPng,
      :markerIcons,
      :stationMarkers,
      :epicenterPosition,
      :onMapLayout,
      :onLayoutUnavailable,
      :useD75Compact,
      :showSafeAreaGuides,
      :compositionKey,
    ) = widget;
    final l10n = AppLocalizations.of(context);
    // The exported card always uses the light DPIP palette.
    final colors = ColorScheme.fromSeed(
      seedColor: const Color(0xFF00696D),
      brightness: Brightness.light,
    );

    final originTime = DateFormat('yyyy/MM/dd HH:mm:ss')
        .format(AppTime.taipei(report.originTimeUtc));

    final intensity = Intensity.displayForReport(
      report.maxIntensity,
      report.originTimeUtc,
    );

    assert(() {
      if (mapPng == null) return true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        final canvasObject = _debugCanvasKey.currentContext?.findRenderObject();

        if (canvasObject is! RenderBox || !canvasObject.attached) {
          return;
        }

        Rect? measureRect(GlobalKey key) {
          final object = key.currentContext?.findRenderObject();

          if (object is! RenderBox || !object.attached) {
            return null;
          }

          final origin = object.localToGlobal(
            Offset.zero,
            ancestor: canvasObject,
          );

          return origin & object.size;
        }

        final logoRect = measureRect(_debugLogoKey);
        final hudRect = measureRect(_debugHudKey);

        if (logoRect == null || hudRect == null) {
          debugPrint('[StoryChrome] measurement unavailable');
          return;
        }

        const markerSize = 22.0;
        const crossSize = 36.0;

        var logoCovered = 0;
        var hudCovered = 0;
        var eitherCovered = 0;
        var maxIntensityCovered = 0;
        var maxIntensityTotal = 0;

        for (final marker in stationMarkers) {
          final position = marker.position;

          if (!position.dx.isFinite || !position.dy.isFinite) {
            continue;
          }

          final markerRect = Rect.fromCenter(
            center: position,
            width: markerSize,
            height: markerSize,
          );

          final coversLogo = logoRect.overlaps(markerRect);
          final coversHud = hudRect.overlaps(markerRect);

          if (coversLogo) logoCovered++;
          if (coversHud) hudCovered++;

          if (coversLogo || coversHud) {
            eitherCovered++;
          }

          if (marker.intensity == report.maxIntensity) {
            maxIntensityTotal++;

            if (coversLogo || coversHud) {
              maxIntensityCovered++;
            }
          }
        }

        final epicenter = epicenterPosition;

        final epicenterCovered =
            epicenter != null &&
            (logoRect.overlaps(
                  Rect.fromCenter(
                    center: epicenter,
                    width: crossSize,
                    height: crossSize,
                  ),
                ) ||
                hudRect.overlaps(
                  Rect.fromCenter(
                    center: epicenter,
                    width: crossSize,
                    height: crossSize,
                  ),
                ));

        debugPrint(
          '[StoryChrome] '
          'canvas=${canvasObject.size} '
          'logo=$logoRect '
          'hud=$hudRect',
        );

        debugPrint(
          '[StoryOcclusion] '
          'total=${stationMarkers.length} '
          'logoCovered=$logoCovered '
          'hudCovered=$hudCovered '
          'eitherCovered=$eitherCovered',
        );

        debugPrint(
          '[StoryOcclusion] '
          'maxIntensityCovered='
          '$maxIntensityCovered/$maxIntensityTotal '
          'epicenterCovered=$epicenterCovered',
        );
      });

      return true;
    }());

    final hud = Positioned(
      left: EarthquakeShareStoryCard._horizontalInset,
      right: EarthquakeShareStoryCard._horizontalInset,
      bottom:
          EarthquakeShareStoryCard._safeBottom +
          EarthquakeShareStoryCard._safeGap,
      child: Semantics(
        container: true,
        explicitChildNodes: true,
        sortKey: const OrdinalSortKey(0),
        child: ClipRRect(
          key: _debugHudKey,
          borderRadius: AppRadius.large,
          child: ColoredBox(
            color: Colors.white.withValues(alpha: 0.91),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Earthquake report identifier.
                      Expanded(
                        child: Text(
                          report.hasNumber
                              ? l10n.reportDetailNumbered(report.number!)
                              : l10n.reportDetailLocalFelt,
                          style: TextStyle(
                            color: colors.onSurfaceVariant,
                            fontSize: 10,
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Compact DPIP branding.
                      Row(
                        key: _debugLogoKey,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const EarthquakeShareIcon(
                            size: 18,
                            excludeFromSemantics: true,
                          ),
                          const SizedBox(width: 4),
                          // Keep the icon anchored when system fonts give the
                          // wordmark different widths.
                          const SizedBox(
                            width: 28,
                            child: FittedBox(
                              alignment: AlignmentDirectional.centerStart,
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'DPIP',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF172B2D),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),

                  Text(
                    report.shortLocation,
                    style: TextStyle(
                      color: colors.onSurface,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),

                  Text(
                    originTime,
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  Row(
                    children: [
                      Expanded(
                        child: _StoryMetric(
                          label: l10n.reportDetailMagnitude,
                          value: 'M${report.magnitude.toStringAsFixed(1)}',
                        ),
                      ),
                      Expanded(
                        child: _StoryMetric(
                          label: l10n.reportDetailMaximumIntensityLabel,
                          badge: IntensityBadge(
                            label: intensity.label,
                            color: IntensityColors.discrete(
                              intensity.colorLevel,
                            ),
                            size: 28,
                          ),
                        ),
                      ),
                      Expanded(
                        child: _StoryMetric(
                          label: l10n.reportDetailDepth,
                          value: report.depth.toStringAsFixed(1),
                          suffix: 'km',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.md),
                  Divider(color: colors.outlineVariant, height: 1),
                  const SizedBox(height: AppSpacing.sm),

                  LayoutBuilder(
                    builder: (context, viewport) => ConstrainedBox(
                      // Reserve the same single-line space across system
                      // fonts. Longer credits still have a two-line budget.
                      constraints: const BoxConstraints(
                        minHeight: 17,
                        maxHeight: 32,
                      ),
                      child: FittedBox(
                        alignment: AlignmentDirectional.centerStart,
                        fit: BoxFit.scaleDown,
                        child: SizedBox(
                          width: viewport.maxWidth,
                          child: Text(
                            l10n.reportDetailStoryAttribution(
                              l10n.reportDetailShareSource,
                            ),
                            style: TextStyle(
                              fontSize: 11,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    final content = Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: mapPng == null
              ? ColoredBox(color: colors.surfaceContainerHigh)
              : Image.memory(
                  mapPng,
                  width: StoryMapSnapshot.canvas.width,
                  height: StoryMapSnapshot.canvas.height,
                  fit: BoxFit.cover,
                  excludeFromSemantics: true,
                ),
        ),
        Positioned.fill(
          child: Semantics(
            container: true,
            explicitChildNodes: true,
            child: _StoryMapMarkers(
              markers: mapPng == null ? const [] : stationMarkers,
              icons: mapPng == null ? const {} : markerIcons,
              epicenterPosition: epicenterPosition,
              originTimeUtc: report.originTimeUtc,
              hud: hud,
              useD75Compact: useD75Compact && mapPng != null,
              locations: {
                if (mapPng != null)
                  for (final area in report.list.entries)
                    for (final name in area.value.town.keys)
                      jsonEncode([area.key, name]): name == area.key
                          ? name
                          : '${area.key}$name',
              },
              observationCount: report.list.values.fold(
                0,
                (count, area) => count + area.town.length,
              ),
              onMapLayout: onMapLayout,
              onLayoutUnavailable: onLayoutUnavailable,
            ),
          ),
        ),
      ],
    );
    return SizedBox(
      key: _debugCanvasKey,
      width: StoryMapSnapshot.canvas.width,
      height: StoryMapSnapshot.canvas.height,
      // The preview and PNG share a single composition. Scale the dialog's
      // controls and report text independently of the original artwork sizes.
      child: MediaQuery.withNoTextScaling(
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (compositionKey != null)
              RepaintBoundary(key: compositionKey, child: content)
            else
              content,

            // Temporary Instagram Story safe-area guides.
            // Preview only — never include in exported images.
            if (showSafeAreaGuides) ...[
              // Upper safe-area boundary.
              Positioned(
                top: EarthquakeShareStoryCard._safeTop,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: Container(height: 2, color: Colors.red),
                ),
              ),

              // Lower safe-area boundary.
              Positioned(
                bottom: EarthquakeShareStoryCard._safeBottom,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: Container(height: 2, color: Colors.red),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StoryMetric extends StatelessWidget {
  const _StoryMetric({
    required this.label,
    this.value,
    this.suffix,
    this.badge,
  });

  final String label;
  final String? value;
  final String? suffix;
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF607477)),
          ),
          const SizedBox(height: AppSpacing.xs),
          SizedBox(
            height: 28,
            child: Align(
              alignment: Alignment.centerLeft,
              child:
                  badge ??
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          value ?? '—',
                          style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF172B2D),
                          ),
                        ),
                        if (suffix != null) ...[
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            suffix!,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF607477),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StoryMapMarkers extends StatelessWidget {
  const _StoryMapMarkers({
    required this.markers,
    required this.icons,
    required this.epicenterPosition,
    required this.originTimeUtc,
    required this.hud,
    required this.useD75Compact,
    required this.locations,
    required this.observationCount,
    required this.onMapLayout,
    required this.onLayoutUnavailable,
  });

  static const _stationSize = 22.0;
  static const _crossSize = 36.0;
  static const _countStyle = TextStyle(
    color: Colors.white,
    fontSize: 9,
    height: 1,
    fontWeight: FontWeight.w700,
    fontFeatures: [FontFeature.tabularFigures()],
  );
  static const _countPadding = EdgeInsets.symmetric(horizontal: 3, vertical: 1);
  static final _countDecoration = BoxDecoration(
    color: const Color(0xFF213D47),
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: Colors.white),
  );

  final List<StoryStationMarker> markers;
  final Map<String, Uint8List> icons;
  final Offset? epicenterPosition;
  final DateTime originTimeUtc;
  final Widget hud;
  final bool useD75Compact;
  final Map<String, String> locations;
  final int observationCount;
  final ValueChanged<StoryCameraLayout>? onMapLayout;
  final VoidCallback? onLayoutUnavailable;

  Rect _fitFootprint(BuildContext context) {
    const cross = Rect.fromLTWH(
      -_crossSize / 2,
      -_crossSize / 2,
      _crossSize,
      _crossSize,
    );
    if (observationCount < 2) return cross;

    // A badge cannot have more digits than the report's observation count.
    // Use the largest digit footprint at that length before clusters exist.
    final defaults = DefaultTextStyle.of(context);
    var style = defaults.style.merge(_countStyle);
    if (MediaQuery.boldTextOf(context)) {
      style = style.merge(const TextStyle(fontWeight: FontWeight.bold));
    }
    final painter = TextPainter(
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      textHeightBehavior: defaults.textHeightBehavior,
      locale: Localizations.maybeLocaleOf(context),
    );
    final digits = observationCount.toString().length;
    var textBox = Rect.zero;
    for (var digit = 0; digit <= 9; digit++) {
      painter.text = TextSpan(text: '$digit' * digits, style: style);
      painter.layout();
      textBox = textBox.expandToInclude(Offset.zero & painter.size);
    }
    painter.dispose();
    final badgeSize = _countPadding
        .add(_countDecoration.padding)
        .inflateSize(textBox.size);
    return cross.expandToInclude(
      StoryMarkerFootprint(
        icon: const Size.square(_stationSize),
        badge: badgeSize,
      ).envelope,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final clusters =
        clusterStoryObservations(
          markers,
          maxDiameterMetres: useD75Compact ? storyD75MaxDiameterMetres : null,
        ).indexed.toList()..sort((a, b) {
          final intensity = a.$2.maxIntensity.compareTo(b.$2.maxIntensity);
          // Paint the earlier canonical anchor above later equal-intensity
          // anchors, and give it first choice when laying out in reverse order.
          return intensity != 0 ? intensity : b.$1.compareTo(a.$1);
        });
    final cross = epicenterPosition;
    final crossBytes = icons['cross'];
    final showCross = cross != null && cross.isFinite && crossBytes != null;
    return _StoryMarkerStack(
      markers: [
        for (final (_, cluster) in clusters)
          (anchor: cluster.anchor.position, hasBadge: cluster.count > 1),
      ],
      hasEpicenter: showCross,
      legendObservations: useD75Compact ? markers : null,
      fitFootprint: onMapLayout == null ? null : _fitFootprint(context),
      onMapLayout: onMapLayout,
      onLayoutUnavailable: onLayoutUnavailable,
      children: [
        for (final (_, cluster) in clusters) ...[
          Positioned(
            left: 0,
            top: 0,
            width: _stationSize,
            height: _stationSize,
            child: Semantics(
              container: true,
              sortKey: const OrdinalSortKey(3),
              excludeSemantics: true,
              label: _observationLabel(l10n, cluster),
              child: _icon(cluster),
            ),
          ),
          if (cluster.count > 1)
            Positioned(
              left: 0,
              top: 0,
              child: Container(
                padding: _countPadding,
                decoration: _countDecoration,
                child: ExcludeSemantics(
                  child: Text('${cluster.count}', style: _countStyle),
                ),
              ),
            ),
        ],
        if (showCross)
          Positioned(
            left: cross.dx - _crossSize / 2,
            top: cross.dy - _crossSize / 2,
            child: Semantics(
              container: true,
              sortKey: const OrdinalSortKey(1),
              child: Image.memory(
                crossBytes,
                width: _crossSize,
                height: _crossSize,
                fit: BoxFit.contain,
                gaplessPlayback: true,
                semanticLabel: l10n.reportDetailEpicenter,
              ),
            ),
          ),
        if (useD75Compact)
          Positioned(left: 0, top: 0, child: _StoryLegend(l10n: l10n)),
        hud,
      ],
    );
  }

  String _observationLabel(AppLocalizations l10n, StoryMarkerCluster cluster) {
    final level = cluster.maxIntensity;
    // A screen reader may skip the superscript sign on a split-scale icon.
    final intensity =
        level >= 5 && level <= 8 && !Intensity.usesLegacyScale(originTimeUtc)
        ? spokenIntensityLabel(level, l10n.localeName)
        : Intensity.displayForReport(level, originTimeUtc).label;
    final location = locations[cluster.anchor.sourceId];
    if (location == null) {
      return l10n.reportDetailStoryObservations(cluster.count, intensity);
    }
    return cluster.count == 1
        ? l10n.reportDetailStorySingleObservation(location, intensity)
        : l10n.reportDetailStoryObservationGroup(
            cluster.count,
            intensity,
            location,
          );
  }

  Widget _icon(StoryMarkerCluster cluster) {
    final presentation = Intensity.displayForReport(
      cluster.maxIntensity,
      originTimeUtc,
    );
    final name = IntensityIconRenderer.nameFor(
      presentation,
      useDarkSuffix: true,
    );
    final bytes = icons[name];
    if (bytes != null) {
      return Image.memory(
        bytes,
        width: _stationSize,
        height: _stationSize,
        fit: BoxFit.contain,
        gaplessPlayback: true,
      );
    }
    return IntensityBadge(
      label: presentation.label,
      color: IntensityColors.discrete(presentation.colorLevel),
      size: _stationSize,
    );
  }
}

class _StoryLegend extends StatelessWidget {
  const _StoryLegend({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(fontSize: 10, height: 1, color: Color(0xFF263B45));
    final count = l10n.reportDetailStoryLegendCount;
    final intensity = l10n.reportDetailStoryLegendIntensity;
    return Semantics(
      container: true,
      sortKey: const OrdinalSortKey(2),
      excludeSemantics: true,
      label: '$count\n$intensity',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(count, style: style, softWrap: false, maxLines: 1),
            Text(intensity, style: style, softWrap: false, maxLines: 1),
          ],
        ),
      ),
    );
  }
}

typedef _MarkerChildren = ({Offset anchor, bool hasBadge});

class _StoryMarkerStack extends Stack {
  const _StoryMarkerStack({
    required this.markers,
    required this.hasEpicenter,
    required this.legendObservations,
    required this.fitFootprint,
    required this.onMapLayout,
    required this.onLayoutUnavailable,
    required super.children,
  }) : super(alignment: Alignment.topLeft);

  final List<_MarkerChildren> markers;
  final bool hasEpicenter;
  final List<StoryStationMarker>? legendObservations;
  final Rect? fitFootprint;
  final ValueChanged<StoryCameraLayout>? onMapLayout;
  final VoidCallback? onLayoutUnavailable;

  @override
  _RenderStoryMarkerStack createRenderObject(BuildContext context) =>
      _RenderStoryMarkerStack(markers, hasEpicenter)
        ..updateMapLayout(fitFootprint, onMapLayout)
        ..updateLegend(legendObservations, onLayoutUnavailable);

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _RenderStoryMarkerStack renderObject,
  ) {
    renderObject.updateMarkers(markers, hasEpicenter);
    renderObject.updateMapLayout(fitFootprint, onMapLayout);
    renderObject.updateLegend(legendObservations, onLayoutUnavailable);
  }
}

class _RenderStoryMarkerStack extends RenderStack {
  _RenderStoryMarkerStack(this._markers, this._hasEpicenter)
    : super(alignment: Alignment.topLeft);

  List<_MarkerChildren> _markers;
  bool _hasEpicenter;
  List<StoryConnector> _connectors = [];
  Rect? _fitFootprint;
  ValueChanged<StoryCameraLayout>? _onMapLayout;
  StoryCameraLayout? _lastLayout;
  List<StoryStationMarker>? _legendObservations;
  VoidCallback? _onLayoutUnavailable;
  bool _legendUnavailable = false;

  void updateLegend(
    List<StoryStationMarker>? observations,
    VoidCallback? onLayoutUnavailable,
  ) {
    _onLayoutUnavailable = onLayoutUnavailable;
    if (identical(_legendObservations, observations)) return;
    _legendObservations = observations;
    markNeedsLayout();
  }

  void updateMapLayout(
    Rect? footprint,
    ValueChanged<StoryCameraLayout>? onMapLayout,
  ) {
    _onMapLayout = onMapLayout;
    if (_fitFootprint == footprint) return;
    _fitFootprint = footprint;
    markNeedsLayout();
  }

  void updateMarkers(List<_MarkerChildren> markers, bool hasEpicenter) {
    if (_hasEpicenter == hasEpicenter && listEquals(_markers, markers)) return;
    _markers = markers;
    _hasEpicenter = hasEpicenter;
    markNeedsLayout();
  }

  @override
  void performLayout() {
    // Stack lays out the original HUD and the unconstrained count labels in
    // this pass. Use those actual sizes before assigning marker offsets, so
    // font changes are reflected in the same frame and in offscreen exports.
    super.performLayout();
    var child = firstChild;
    final boxes = <({RenderBox icon, RenderBox? badge})>[];
    final footprints = <StoryMarkerAnchor>[];
    for (final marker in _markers) {
      final icon = child!;
      final badge = marker.hasBadge ? childAfter(icon)! : null;
      boxes.add((icon: icon, badge: badge));
      footprints.add((
        anchor: marker.anchor,
        footprint: StoryMarkerFootprint(icon: icon.size, badge: badge?.size),
      ));
      child = childAfter(badge ?? icon);
    }
    Rect bounds(RenderBox box) =>
        (box.parentData! as StackParentData).offset & box.size;

    // Reserve the full cross image (including its white outline) and HUD box.
    final epicenter = _hasEpicenter ? bounds(child!) : null;
    final hud = bounds(lastChild!);
    final canvas = Offset.zero & size;
    if (_fitFootprint case final footprint?) {
      final layout = storyCameraLayout(
        canvas: size,
        safeTop: EarthquakeShareStoryCard._safeTop,
        safeBottom: EarthquakeShareStoryCard._safeBottom,
        hud: hud,
        footprint: footprint,
        gap: EarthquakeShareStoryCard._safeGap,
      );
      if (layout != _lastLayout) {
        _lastLayout = layout;
        // Start the capture outside layout, using the most recent measured
        // geometry. A later layout can supersede this callback.
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (attached && _lastLayout == layout) _onMapLayout?.call(layout);
        });
      }
    } else {
      _lastLayout = null;
    }
    final centers = layoutStoryMarkers(
      markers: footprints.reversed.toList(),
      canvas: canvas,
      epicenter: epicenter,
      hud: hud,
    ).reversed.toList();

    final connectors = <StoryConnector>[];
    for (final (index, position) in centers.indexed) {
      final anchor = footprints[index];
      final components = anchor.footprint.at(position);
      final box = boxes[index];
      (box.icon.parentData! as StackParentData).offset =
          components.first.topLeft;
      final badge = box.badge;
      if (badge != null) {
        (badge.parentData! as StackParentData).offset = components.last.topLeft;
      }
      if (position != anchor.anchor) {
        connectors.add(StoryConnector(anchor.anchor, position));
      }
    }
    _connectors = connectors;

    _legendUnavailable = false;
    if (_legendObservations case final observations?) {
      final legend = childBefore(lastChild!)!;
      final placement = layoutStoryLegend(
        legend: legend.size,
        safeRegion: Rect.fromLTRB(
          EarthquakeShareStoryCard._horizontalInset,
          EarthquakeShareStoryCard._safeTop + 1,
          size.width - EarthquakeShareStoryCard._horizontalInset,
          math.min(
            size.height - EarthquakeShareStoryCard._safeBottom,
            hud.top - EarthquakeShareStoryCard._safeGap,
          ),
        ),
        occupied: [
          hud,
          ?epicenter,
          for (final box in boxes) ...[
            bounds(box.icon),
            if (box.badge case final badge?) bounds(badge),
          ],
        ],
        observations: observations.map((marker) => marker.position),
        connectors: connectors,
      );
      if (placement == null) {
        _legendUnavailable = true;
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (attached && _legendUnavailable) _onLayoutUnavailable?.call();
        });
      } else {
        (legend.parentData! as StackParentData).offset = placement.topLeft;
      }
    }

    assert(() {
      final components = [
        for (final box in boxes)
          [bounds(box.icon), if (box.badge != null) bounds(box.badge!)],
      ];
      var overlapPairs = 0;
      for (final (index, group) in components.indexed) {
        overlapPairs += components
            .skip(index + 1)
            .where((other) => group.any((box) => other.any(box.overlaps)))
            .length;
      }
      final all = components.expand((group) => group);
      final epicenterOverlaps = epicenter == null
          ? 0
          : all.where(epicenter.overlaps).length;
      final hudOverlaps = all.where(hud.overlaps).length;
      final outside = all.where((box) => canvas.intersect(box) != box).length;
      if (overlapPairs + epicenterOverlaps + hudOverlaps + outside > 0) {
        debugPrint(
          '[StoryClusterLayout] unresolved '
          'overlapPairs=$overlapPairs epicenterOverlaps=$epicenterOverlaps '
          'hudOverlaps=$hudOverlaps outsideCanvas=$outside',
        );
      }
      return true;
    }());
  }

  @override
  void paintStack(PaintingContext context, Offset offset) {
    if (_legendUnavailable) return;
    if (_connectors.isNotEmpty) {
      final paint = Paint()
        ..color = const Color(0xB3263B45)
        ..strokeWidth = StoryConnector.strokeWidth
        ..style = PaintingStyle.stroke;
      for (final line in _connectors) {
        context.canvas.drawLine(line.from + offset, line.to + offset, paint);
      }
    }
    super.paintStack(context, offset);
  }
}
