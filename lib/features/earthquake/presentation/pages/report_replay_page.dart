/// 地震重播 — replays the RTS (強震監測) + EEW feeds at real-time (1x) speed
/// from a fixed point in the past, opened from a report's "重播" chip.
///
/// Unlike the legacy app (which toggled its one global data singleton into a
/// "replay mode" that changed what every consumer's `currentTime` meant),
/// this page owns one page-scoped [ReplaySession] — never touching the shared
/// live `rtsChannel`/`eewChannel` other features watch, so replaying history
/// can never leak into the live monitor. A standalone map (own [BaseMap], no
/// layer switcher or sheet) mirrors [ReportDetailPage]'s `_ReportMapDetail`,
/// since the layering gate forbids importing `features/map`'s layer widgets
/// from here.
library;

import 'dart:async';

import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/network/api_client.dart';
import 'package:dpip/core/realtime/realtime_service.dart';
import 'package:dpip/core/realtime/realtime_state.dart';
import 'package:dpip/core/realtime/replay_clock.dart';
import 'package:dpip/features/earthquake/domain/rts_box_grid.dart';
import 'package:dpip/features/earthquake/domain/seismic_station.dart';
import 'package:dpip/features/earthquake/domain/seismic_travel_time.dart';
import 'package:dpip/features/earthquake/domain/trem_station_repository.dart';
import 'package:dpip/features/earthquake/presentation/eew_realtime_controller.dart';
import 'package:dpip/features/earthquake/presentation/rts_realtime_controller.dart';
import 'package:dpip/features/earthquake/presentation/widgets/eew_card.dart';
import 'package:dpip/features/earthquake/replay_session.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/map/base_map.dart';
import 'package:dpip/shared/map/camera_fit.dart';
import 'package:dpip/shared/map/geo_circle.dart';
import 'package:dpip/shared/map/map_station_labels.dart';
import 'package:dpip/shared/map/map_style.dart' show landLayerId;
import 'package:dpip/shared/seismic/intensity_colors.dart';
import 'package:dpip/shared/widgets/frosted_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:provider/provider.dart';

const Map<String, dynamic> _emptyCollection = {
  'type': 'FeatureCollection',
  'features': <dynamic>[],
};

/// Replays RTS + EEW starting at [replayTimestamp] (Unix ms).
class ReportReplayPage extends StatefulWidget {
  const ReportReplayPage({super.key, required this.replayTimestamp});

  final int replayTimestamp;

  @override
  State<ReportReplayPage> createState() => _ReportReplayPageState();
}

class _ReportReplayPageState extends State<ReportReplayPage> {
  late final ReplaySession _session;

  /// Bumped on a fixed cadence so the wave-front circles and the displayed
  /// clock keep advancing every frame, independent of whether a poll actually
  /// changed the underlying feed data (a realtime channel only emits on a
  /// real transition — the wavefront still grows every tick in between).
  final ValueNotifier<int> _tick = ValueNotifier(0);
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _session = ReplaySession(
      context.read<ApiClient>(),
      context.read<RealtimeService>().clock,
      widget.replayTimestamp,
    )..start();
    _ticker = Timer.periodic(
      const Duration(milliseconds: 200),
      (_) => _tick.value++,
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _tick.dispose();
    _session.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: _ReplayMap(
              stationRepository: context.read<TremStationRepository>(),
              travelTimeTable: context.read<Future<SeismicTravelTimeTable>>(),
              boxGrid: context.read<Future<RtsBoxGrid>>(),
              rts: _session.rts,
              eew: _session.eew,
              tick: _tick,
              clock: _session.clock,
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
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
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ListenableBuilder(
                      listenable: _session.eew,
                      builder: (context, _) {
                        final alert = _session.eew.primaryAlert;
                        if (alert == null) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: EewCard(eew: alert),
                        );
                      },
                    ),
                    _ReplayStatusBar(
                      clock: _session.clock,
                      tick: _tick,
                      rts: _session.rts,
                      eew: _session.eew,
                    ),
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

/// The map surface: RTS station dots + EEW epicentre/P-S wave circles, on the
/// app's shared [BaseMap]. Own MapLibre source/layer setup — a slimmed port of
/// `RtsMapLayer`'s station rendering plus new wave-circle rendering, since
/// that layer lives in `features/map` and can't be imported here.
class _ReplayMap extends StatefulWidget {
  const _ReplayMap({
    required this.stationRepository,
    required this.travelTimeTable,
    required this.boxGrid,
    required this.rts,
    required this.eew,
    required this.tick,
    required this.clock,
  });

  final TremStationRepository stationRepository;

  /// The bundled CWA P/S travel-time table (asset load) — resolved once and
  /// cached in state; wave circles don't render until it's ready.
  final Future<SeismicTravelTimeTable> travelTimeTable;

  /// The bundled RTS box grid (asset load) — resolved once and cached in
  /// state; the box overlay doesn't render until it's ready.
  final Future<RtsBoxGrid> boxGrid;
  final RtsRealtimeController rts;
  final EewRealtimeController eew;
  final ValueNotifier<int> tick;
  final ReplayClock clock;

  @override
  State<_ReplayMap> createState() => _ReplayMapState();
}

class _ReplayMapState extends State<_ReplayMap> {
  static const String _crossIcon = 'replay-cross';
  static const String _rtsSourceId = 'replay-rts-src';
  static const String _rtsCircleId = 'replay-rts-circle';
  static const String _rtsLabelId = 'replay-rts-label';
  static const String _boxSourceId = 'replay-box-src';
  static const String _boxLineLayerId = 'replay-box-line';
  static const String _eewSourceId = 'replay-eew-src';
  static const String _pWaveLayerId = 'replay-eew-p';
  static const String _sWaveFillLayerId = 'replay-eew-s-fill';
  static const String _sWaveLayerId = 'replay-eew-s';
  static const String _epicenterLayerId = 'replay-eew-epicenter';

  /// Box-grid border colour by intensity `i`: red ≥4, yellow 2–3, green below
  /// — ported from the legacy monitor's box colour scheme. Border only (no
  /// fill) so the boxes don't obscure the map underneath.
  static const List<Object> _boxColorExpression = [
    'case',
    [
      '>=',
      ['get', 'i'],
      4,
    ],
    '#FF0000',
    [
      '>=',
      ['get', 'i'],
      2,
    ],
    '#EAC100',
    '#00DB00',
  ];

  /// Dot radius by zoom — same scale [RtsMapLayer] uses (2px at z4 → 8px z12).
  static const List<Object> _rtsRadiusExpression = [
    'interpolate',
    ['linear'],
    ['zoom'],
    4,
    2.0,
    12,
    8.0,
  ];

  MapLibreMapController? _controller;
  Map<String, SeismicStation> _stations = const {};
  bool _stationsFetching = false;
  bool _ready = false;
  String? _framedEewId;
  SeismicTravelTimeTable? _travelTimeTable;
  RtsBoxGrid? _boxGrid;
  bool _boxActive = false;

  @override
  void initState() {
    super.initState();
    widget.rts.addListener(_onRts);
    widget.tick.addListener(_onTick);
    widget.travelTimeTable.then((table) {
      if (!mounted) return;
      _travelTimeTable = table;
      unawaited(_updateEew());
    });
    widget.boxGrid.then((grid) {
      if (!mounted) return;
      _boxGrid = grid;
      unawaited(_updateBox());
    });
  }

  @override
  void dispose() {
    widget.rts.removeListener(_onRts);
    widget.tick.removeListener(_onTick);
    super.dispose();
  }

  void _onMapCreated(MapLibreMapController controller) {
    _controller = controller;
  }

  Future<void> _onStyleLoaded() async {
    final controller = _controller;
    if (controller == null) return;
    try {
      final data = await rootBundle.load('assets/map/icons/cross.png');
      await controller.addImage(_crossIcon, data.buffer.asUint8List());

      await controller.addSource(
        _rtsSourceId,
        GeojsonSourceProperties(data: _emptyCollection),
      );
      await controller.addCircleLayer(
        _rtsSourceId,
        _rtsCircleId,
        CircleLayerProperties(
          circleColor: InstrumentalIntensityColors.mapLibreInterpolate,
          circleRadius: _rtsRadiusExpression,
          circleStrokeColor: '#9E9E9E',
          circleStrokeWidth: 1,
        ),
      );
      await controller.addSymbolLayer(
        _rtsSourceId,
        _rtsLabelId,
        stationLabelProps(
          textField: const <Object>['get', 'label'],
          textSize: 10,
        ),
        minzoom: 10,
      );

      await controller.addSource(
        _eewSourceId,
        GeojsonSourceProperties(data: _emptyCollection),
      );
      // The S wave's translucent disc ("inner circle") — the damaging,
      // already-shaking zone. Anchored below [landLayerId] (below the whole
      // land/county/town area, not just its borders) so the wash only shows
      // over open sea, never over Taiwan itself. The P wave is a heads-up
      // leading edge only, no fill. Both outline rings are added with no
      // `belowLayerId`, so they stack on top of the map as normal.
      await controller.addFillLayer(
        _eewSourceId,
        _sWaveFillLayerId,
        const FillLayerProperties(fillColor: '#FF3B30', fillOpacity: 0.16),
        belowLayerId: landLayerId,
        filter: const [
          '==',
          ['get', 'type'],
          's-fill',
        ],
      );
      await controller.addLineLayer(
        _eewSourceId,
        _pWaveLayerId,
        const LineLayerProperties(lineColor: '#00E5FF', lineWidth: 2),
        filter: const [
          '==',
          ['get', 'type'],
          'p-line',
        ],
      );
      await controller.addLineLayer(
        _eewSourceId,
        _sWaveLayerId,
        const LineLayerProperties(lineColor: '#FF3B30', lineWidth: 2),
        filter: const [
          '==',
          ['get', 'type'],
          's-line',
        ],
      );
      await controller.addSymbolLayer(
        _eewSourceId,
        _epicenterLayerId,
        const SymbolLayerProperties(
          iconImage: _crossIcon,
          iconSize: 1.0,
          iconAllowOverlap: true,
          iconIgnorePlacement: true,
        ),
        filter: const [
          '==',
          ['get', 'type'],
          'x',
        ],
      );
    } catch (e, st) {
      Log.handle(e, st, 'replay map render failed');
    }
    // RTS box grid, in its own try/catch after the rest of the map is up:
    // replaces the station dots for a large event the feed reports at
    // box-grid resolution instead of per-station (hidden until that data
    // arrives — see [_updateBox]). Isolated so a failure here can never take
    // down the station dots / EEW wave circles set up above.
    try {
      await controller.addSource(
        _boxSourceId,
        GeojsonSourceProperties(data: _emptyCollection),
      );
      await controller.addLineLayer(
        _boxSourceId,
        _boxLineLayerId,
        const LineLayerProperties(
          lineColor: _boxColorExpression,
          lineWidth: 2,
          visibility: 'none',
        ),
      );
    } catch (e, st) {
      Log.handle(e, st, 'replay box layer render failed');
    }
    _ready = true;
    await _ensureStations();
    unawaited(_updateRts());
    unawaited(_updateBox());
    unawaited(_updateEew());
    _frameTaiwan();
  }

  /// Loads the station directory once; the RTS feed carries only per-id
  /// intensities, so dots can't be placed until this resolves.
  Future<void> _ensureStations() async {
    if (_stations.isNotEmpty || _stationsFetching) return;
    _stationsFetching = true;
    try {
      final directory = (await widget.stationRepository.stations()).valueOrNull;
      if (directory != null && directory.isNotEmpty) _stations = directory;
    } finally {
      _stationsFetching = false;
    }
  }

  void _onRts() {
    unawaited(_updateRts());
    unawaited(_updateBox());
  }

  void _onTick() => unawaited(_updateEew());

  Future<void> _updateRts() async {
    final controller = _controller;
    if (controller == null || !_ready) return;
    if (_stations.isEmpty) await _ensureStations();
    try {
      await controller.setGeoJsonSource(_rtsSourceId, _rtsGeoJson());
    } catch (_) {
      // Source not on the map yet (mid style-reload) — the next update retries.
    }
  }

  /// Updates the box-grid overlay: a large event the feed reports at
  /// box-grid resolution (`rts.box` non-empty) draws the coloured grid cells
  /// *alongside* the per-station dots (not a replacement) — the box only
  /// covers the areas the event actually triggered, so stations outside it
  /// still carry live detail.
  Future<void> _updateBox() async {
    final controller = _controller;
    final grid = _boxGrid;
    if (controller == null || !_ready || grid == null) return;
    final hasBox = widget.rts.box.isNotEmpty;
    try {
      if (hasBox) {
        await controller.setGeoJsonSource(_boxSourceId, _boxGeoJson(grid));
      }
      if (hasBox != _boxActive) {
        _boxActive = hasBox;
        await controller.setLayerVisibility(_boxLineLayerId, hasBox);
      }
    } catch (_) {
      // Source/layer not on the map yet (mid style-reload) — the next update retries.
    }
  }

  Future<void> _updateEew() async {
    final controller = _controller;
    if (controller == null || !_ready) return;
    try {
      await controller.setGeoJsonSource(_eewSourceId, _eewGeoJson());
    } catch (_) {
      // Source not on the map yet (mid style-reload) — the next update retries.
    }
    _maybeFrameEpicenter();
  }

  Map<String, dynamic> _rtsGeoJson() {
    final features = <Map<String, dynamic>>[];
    for (final entry in widget.rts.stations.entries) {
      final station = _stations[entry.key];
      if (station == null) continue;
      features.add({
        'type': 'Feature',
        'geometry': {
          'type': 'Point',
          'coordinates': [station.longitude, station.latitude],
        },
        'properties': {
          'i': entry.value.intensityRaw,
          'label':
              '${entry.key}\n${entry.value.intensityRaw.toStringAsFixed(1)}',
        },
      });
    }
    return {'type': 'FeatureCollection', 'features': features};
  }

  /// One polygon per box id present in the live feed's `rts.box`, joined
  /// against the static [grid] for its geometry.
  Map<String, dynamic> _boxGeoJson(RtsBoxGrid grid) {
    final features = <Map<String, dynamic>>[];
    for (final entry in widget.rts.box.entries) {
      final id = int.tryParse(entry.key);
      final ring = id == null ? null : grid.rings[id];
      if (ring == null) continue;
      features.add({
        'type': 'Feature',
        'geometry': {
          'type': 'Polygon',
          'coordinates': [ring],
        },
        'properties': {'i': entry.value},
      });
    }
    return {'type': 'FeatureCollection', 'features': features};
  }

  /// Epicentre cross + P/S wave-front rings, radii from the bundled CWA
  /// travel-time table (same source the legacy app's `calcWaveRadius` used) —
  /// recomputed every tick so the rings keep expanding even between polls.
  /// No rings render until [_travelTimeTable] resolves (near-instant, but
  /// async since it's an asset load).
  Map<String, dynamic> _eewGeoJson() {
    final table = _travelTimeTable;
    final now = widget.clock.now();
    final features = <Map<String, dynamic>>[];
    for (final eew in widget.eew.alerts) {
      final info = eew.info;
      final center = info.latlng;
      final elapsed = now.difference(
        DateTime.fromMillisecondsSinceEpoch(info.time, isUtc: true),
      );

      if (table != null && !elapsed.isNegative) {
        final radius = table.waveRadius(info.depth, elapsed);
        if (radius.p > 0) {
          features.add(
            circleFeature(
              center,
              radius.p * 1000,
              properties: const {'type': 'p-line'},
            ),
          );
        }
        if (radius.s > 0) {
          final metres = radius.s * 1000;
          features.add(
            circleFillFeature(
              center,
              metres,
              properties: const {'type': 's-fill'},
            ),
          );
          features.add(
            circleFeature(center, metres, properties: const {'type': 's-line'}),
          );
        }
      }
      features.add({
        'type': 'Feature',
        'geometry': {
          'type': 'Point',
          'coordinates': [info.longitude, info.latitude],
        },
        'properties': {'type': 'x'},
      });
    }
    return {'type': 'FeatureCollection', 'features': features};
  }

  void _frameTaiwan() {
    _frameBounds(BaseMap.taiwanBounds);
  }

  /// Reframes on a new EEW's epicentre once (tracked by [_framedEewId]) so the
  /// camera doesn't fight the user's own pan/zoom on every subsequent tick.
  void _maybeFrameEpicenter() {
    final primary = widget.eew.primaryAlert;
    if (primary == null || primary.id == _framedEewId) return;
    _framedEewId = primary.id;
    const span = 1.5;
    final info = primary.info;
    _frameBounds(
      LatLngBounds(
        southwest: LatLng(info.latitude - span, info.longitude - span),
        northeast: LatLng(info.latitude + span, info.longitude + span),
      ),
    );
  }

  void _frameBounds(LatLngBounds targetBounds) {
    final controller = _controller;
    if (controller == null || !mounted) return;
    final bounds = safeFitBounds(targetBounds);
    if (bounds == null) return;
    final size = MediaQuery.sizeOf(context);
    final fit = boundsFitCamera(
      bounds,
      viewport: size,
      topInset: MediaQuery.paddingOf(context).top,
      bottomInset: 96,
    );
    if (fit == null) return;
    controller.moveCamera(CameraUpdate.newLatLngZoom(fit.target, fit.zoom));
  }

  @override
  Widget build(BuildContext context) {
    return BaseMap(
      showUserLocation: false,
      onMapCreated: _onMapCreated,
      onStyleLoaded: () => unawaited(_onStyleLoaded()),
    );
  }
}

/// Bottom status card: a freshness dot, the replay clock (tinted orange, the
/// legacy "this is replay, not live" signal), the RTS feed's status word when
/// not healthy, and an EEW alert count when one is active.
class _ReplayStatusBar extends StatelessWidget {
  const _ReplayStatusBar({
    required this.clock,
    required this.tick,
    required this.rts,
    required this.eew,
  });

  final ReplayClock clock;
  final ValueNotifier<int> tick;
  final RtsRealtimeController rts;
  final EewRealtimeController eew;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: tick,
      builder: (context, _, _) => ListenableBuilder(
        listenable: Listenable.merge([rts, eew]),
        builder: (context, _) => _buildContent(context),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final taipeiTime = clock.now().add(const Duration(hours: 8));
    final timeText = DateFormat('HH:mm:ss').format(taipeiTime);

    final (Color dot, String? statusWord) = switch (rts.status) {
      RealtimeStatus.live => (Colors.green, null),
      RealtimeStatus.stale => (Colors.amber, l10n.feedStale),
      RealtimeStatus.offline => (Colors.red, l10n.feedOffline),
      RealtimeStatus.connecting => (Colors.grey, l10n.feedConnecting),
    };

    final alertCount = eew.alerts.length;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.94),
        borderRadius: AppRadius.medium,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              l10n.mapLayerMonitor,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (alertCount > 0) ...[
            const SizedBox(width: AppSpacing.sm),
            Icon(Icons.warning_amber, size: 16, color: colors.error),
            const SizedBox(width: 2),
            Text(
              '$alertCount',
              style: theme.textTheme.labelMedium?.copyWith(
                color: colors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(width: AppSpacing.sm),
          Text(
            timeText,
            maxLines: 1,
            style: theme.textTheme.labelMedium?.copyWith(
              color: Colors.orange,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          if (statusWord != null) ...[
            const SizedBox(width: AppSpacing.sm),
            Text(
              statusWord,
              maxLines: 1,
              style: theme.textTheme.labelMedium?.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
