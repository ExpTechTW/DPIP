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

import 'package:dpip/core/a11y/color_vision.dart';
import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/models/lat_lng.dart' as geo;
import 'package:dpip/core/network/api_client.dart';
import 'package:dpip/core/realtime/app_time.dart';
import 'package:dpip/core/realtime/realtime_service.dart';
import 'package:dpip/core/realtime/realtime_state.dart';
import 'package:dpip/core/realtime/replay_clock.dart';
import 'package:dpip/features/earthquake/domain/eew.dart';
import 'package:dpip/features/earthquake/domain/eew_estimator.dart';
import 'package:dpip/features/earthquake/domain/intensity.dart';
import 'package:dpip/features/earthquake/domain/rts_box_grid.dart';
import 'package:dpip/features/earthquake/domain/seismic_station.dart';
import 'package:dpip/features/earthquake/domain/seismic_travel_time.dart';
import 'package:dpip/features/earthquake/domain/trem_station_repository.dart';
import 'package:dpip/features/earthquake/presentation/eew_realtime_controller.dart';
import 'package:dpip/features/earthquake/presentation/rts_realtime_controller.dart';
import 'package:dpip/features/earthquake/presentation/widgets/eew_card.dart';
import 'package:dpip/features/earthquake/presentation/widgets/intensity_icon_renderer.dart';
import 'package:dpip/features/earthquake/replay_session.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/color_hex.dart';
import 'package:dpip/shared/map/base_map.dart';
import 'package:dpip/shared/map/camera_fit.dart';
import 'package:dpip/shared/map/geo_circle.dart';
import 'package:dpip/shared/map/map_compass.dart';
import 'package:dpip/shared/map/map_station_labels.dart';
import 'package:dpip/shared/map/map_style.dart'
    show
        MapColors,
        countyFillLayerId,
        landLayerId,
        townFillLayerId,
        townLabelLayerId;
import 'package:dpip/shared/seismic/intensity_colors.dart';
import 'package:dpip/shared/widgets/frosted_surface.dart';
import 'package:dpip/shared/widgets/intensity_legend.dart';
import 'package:dpip/shared/widgets/map_color_legend.dart';
import 'package:flutter/material.dart';
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

  /// Which active alert the single EEW card currently shows — tapping the card
  /// advances it through the alert set (modulo the count in the builder).
  int _eewIndex = 0;

  @override
  void initState() {
    super.initState();
    _session = ReplaySession(
      context.read<ApiClient>(),
      context.read<RealtimeService>().clock,
      widget.replayTimestamp,
    )..start();
    _startTicker();
    // The session's channels live outside RealtimeService (a replay must not
    // look like a live feed), so its lifecycle pause never reaches them —
    // this page pauses its own polling and its 5 Hz UI tick itself, or a
    // backgrounded replay keeps two polls a second running indefinitely.
    _lifecycle = AppLifecycleListener(
      onPause: () {
        _ticker?.cancel();
        _ticker = null;
        _session.pause();
      },
      onResume: () {
        _startTicker();
        _session.resume();
      },
    );
  }

  void _startTicker() {
    _ticker ??= Timer.periodic(
      const Duration(milliseconds: 200),
      (_) => _tick.value++,
    );
  }

  late final AppLifecycleListener _lifecycle;

  @override
  void dispose() {
    _lifecycle.dispose();
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FrostedSurface(
                      borderRadius: AppRadius.large,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => context.pop(),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    // The replay surface is the 強震監視器 frozen in time —
                    // the same intensity legend the live monitor carries,
                    // switching to the EEW felt-scale while an alert is up
                    // (the legacy monitor did exactly this on active EEW).
                    ListenableBuilder(
                      listenable: _session.eew,
                      builder: (context, _) {
                        final hasEew = _session.eew.alerts.isNotEmpty;
                        return MapLegendCard(
                          child: IntensityLegend(
                            mode: hasEew
                                ? IntensityLegendMode.eew
                                : IntensityLegendMode.rts,
                          ),
                        );
                      },
                    ),
                  ],
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
                        final alerts = _session.eew.alerts;
                        if (alerts.isEmpty) return const SizedBox.shrink();
                        // One card at a time — tapping cycles through the
                        // active alerts (parallel earthquakes, overlapping
                        // reports) instead of stacking every one on screen.
                        // The index is clamped by modulo, so a report leaving
                        // the active set mid-replay can't point past the list.
                        final index = _eewIndex % alerts.length;
                        final eew = alerts[index];
                        return _EewAlertCard(
                          eew: eew,
                          clock: () => _session.clock.now(),
                          position: index + 1,
                          count: alerts.length,
                          onTap: alerts.length > 1
                              ? () => setState(
                                  () => _eewIndex =
                                      (_eewIndex + 1) % alerts.length,
                                )
                              : null,
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

  /// Per-station discrete-intensity marker layer — the legacy monitor's
  /// `intensity` layer. While a large event's detection boxes are up, the
  /// station dots give way to these icons (`intensity-1`…`intensity-9`, same
  /// PNGs the report map uses), one numeral per station over its estimated
  /// shaking.
  static const String _rtsIntensityId = 'replay-rts-intensity';

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

  /// The intensity icon for scale index 1–9, dark or light artwork — the same
  /// assets the report detail map registers.
  static String _intensityIcon(int level, {required bool dark}) =>
      dark ? 'intensity-$level-dark' : 'intensity-$level';

  MapLibreMapController? _controller;
  Map<String, SeismicStation> _stations = const {};
  bool _stationsFetching = false;
  bool _ready = false;
  SeismicTravelTimeTable? _travelTimeTable;
  RtsBoxGrid? _boxGrid;

  /// The township directory, for the whole-island estimated-shaking tint.
  late final TownDirectory _directory = context.read<TownDirectory>();

  /// The EEW id/serial combo the town/county fill is currently tinted for —
  /// recomputing the 368-town estimate every tick is wasteful when nothing
  /// changed, so the fill only updates when this key does.
  String? _fillEewKey;

  /// Brightness at the last style load — the intensity icons come in light and
  /// dark artwork ([IntensityIcon.light] / [.dark]) and the layer is rebuilt
  /// on style reload, so the choice is made once per load.
  bool _dark = false;

  /// Whether the station layer is currently showing intensity icons (big-quake
  /// box mode) instead of dots — the legacy monitor's `_lastIntensityLayersVisible`.
  bool? _lastIconMode;

  /// Legacy-style blink: while a large event's detection boxes are on the map
  /// they (and the EEW epicentre cross) toggle visibility on a 1 s cadence so
  /// they stand out from the static replay surface — ported from the legacy
  /// monitor's `_setupBlinkTimer`.
  Timer? _blinkTimer;
  bool _boxVisible = true;
  bool _epicenterVisible = true;

  /// Feeds the Flutter [MapCompass] needle — camera heading, ° clockwise from
  /// north, kept in sync from [BaseMap.onCameraMove].
  final ValueNotifier<double> _bearing = ValueNotifier(0);

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

  /// Pauses the 1 Hz blink while the app is backgrounded — its platform
  /// visibility writes would keep running under the lock screen otherwise.
  /// Restarting on resume just resets the blink phase, which is invisible.
  late final AppLifecycleListener _blinkLifecycle = AppLifecycleListener(
    onPause: () {
      _blinkTimer?.cancel();
      _blinkTimer = null;
    },
    onResume: () {
      if (_ready) _setupBlink();
    },
  );

  @override
  void dispose() {
    _blinkLifecycle.dispose();
    widget.rts.removeListener(_onRts);
    widget.tick.removeListener(_onTick);
    _blinkTimer?.cancel();
    _bearing.dispose();
    super.dispose();
  }

  /// Toggles the detection boxes and the epicentre cross every second while
  /// their data is present, and hides them the moment it is gone. Visibility
  /// lives entirely here — [_updateBox]/[_updateEew] only push geometry.
  void _setupBlink() {
    _blinkTimer?.cancel();
    _blinkTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      final controller = _controller;
      if (controller == null || !_ready) return;
      try {
        final hasBox = widget.rts.box.isNotEmpty;
        if (hasBox) {
          _boxVisible = !_boxVisible;
          await controller.setLayerVisibility(_boxLineLayerId, _boxVisible);
        } else if (_boxVisible) {
          _boxVisible = false;
          await controller.setLayerVisibility(_boxLineLayerId, false);
        }

        final hasEew = widget.eew.alerts.isNotEmpty;
        if (hasEew) {
          _epicenterVisible = !_epicenterVisible;
          await controller.setLayerVisibility(
            _epicenterLayerId,
            _epicenterVisible,
          );
        } else if (_epicenterVisible) {
          _epicenterVisible = false;
          await controller.setLayerVisibility(_epicenterLayerId, false);
        }
      } catch (_) {
        // Layers gone mid style-reload — the next blink retries.
      }
    });
  }

  void _onMapCreated(MapLibreMapController controller) {
    _controller = controller;
  }

  /// Re-points the camera north, keeping centre / zoom. Mirrors
  /// [MapScaffold._resetNorth]: the needle is settled directly because a
  /// programmatic move may not emit a final north-up camera event.
  void _resetNorth() {
    final controller = _controller;
    if (controller == null) return;
    final position = controller.cameraPosition;
    if (position == null) return;
    _bearing.value = 0;
    unawaited(
      controller.moveCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: position.target,
            zoom: position.zoom,
            bearing: 0,
            tilt: 0,
          ),
        ),
      ),
    );
  }

  Future<void> _onStyleLoaded() async {
    final controller = _controller;
    if (controller == null) return;
    _dark = Theme.of(context).brightness == Brightness.dark;
    try {
      final data = await IntensityIconRenderer.render('cross');
      await controller.addImage(_crossIcon, data);
      await _loadIntensityIcons(controller);

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
        // Station dots under the township names — the wavefront must never
        // hide where you are.
        belowLayerId: townLabelLayerId,
      );
      await controller.addSymbolLayer(
        _rtsSourceId,
        _rtsLabelId,
        stationLabelProps(
          textField: const <Object>['get', 'label'],
          textSize: 10,
        ),
        minzoom: 10,
        // Township names stay the top-most text; station labels give way on
        // collision (the layer order decides who wins placement).
        belowLayerId: townLabelLayerId,
      );

      // The discrete-intensity markers — hidden until a big event's detection
      // boxes arrive ([_syncStationMode] flips them on and drops the dots),
      // ported from the legacy monitor's `intensity` layer: an icon per station
      // picked from its discrete intensity, overlap allowed so the whole island
      // reads at once. Icons, not text — the same artwork the report map uses.
      await controller.addSymbolLayer(
        _rtsSourceId,
        _rtsIntensityId,
        const SymbolLayerProperties(
          iconImage: <Object>['get', 'icon'],
          iconAllowOverlap: true,
          iconIgnorePlacement: true,
          symbolZOrder: 'source',
          visibility: 'none',
        ),
        belowLayerId: townLabelLayerId,
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
        FillLayerProperties(fillColor: '#FF3B30'.vision, fillOpacity: 0.16),
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
        LineLayerProperties(lineColor: '#00E5FF'.vision, lineWidth: 2),
        belowLayerId: townLabelLayerId,
        filter: const [
          '==',
          ['get', 'type'],
          'p-line',
        ],
      );
      await controller.addLineLayer(
        _eewSourceId,
        _sWaveLayerId,
        LineLayerProperties(lineColor: '#FF3B30'.vision, lineWidth: 2),
        belowLayerId: townLabelLayerId,
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
        belowLayerId: townLabelLayerId,
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
        // Detection-box borders stay under the township names.
        belowLayerId: townLabelLayerId,
      );
    } catch (e, st) {
      Log.handle(e, st, 'replay box layer render failed');
    }
    _ready = true;
    await _ensureStations();
    unawaited(_updateRts());
    unawaited(_updateBox());
    unawaited(_updateEew());
    _setupBlink();
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
  /// still carry live detail. Only geometry is pushed here; the visibility
  /// blink is [_setupBlink]'s job.
  Future<void> _updateBox() async {
    final controller = _controller;
    final grid = _boxGrid;
    if (controller == null || !_ready || grid == null) return;
    final hasBox = widget.rts.box.isNotEmpty;
    try {
      if (hasBox) {
        await controller.setGeoJsonSource(_boxSourceId, _boxGeoJson(grid));
      }
    } catch (_) {
      // Source/layer not on the map yet (mid style-reload) — the next update retries.
    }
    // Boxes and intensity icons are the same big-quake mode (legacy's
    // `rtsVisible = hasRtsData && !hasBox`) — flip the station layer with the
    // box state rather than on every EEW tick.
    await _syncStationMode();
  }

  /// Whether [_eewSourceId] currently holds the empty collection — mirrors
  /// the live monitor's flag. The old blanket `alerts.isEmpty` skip made the
  /// one *clearing* write unreachable: once the replayed alert expired, the
  /// last P/S wavefront rings and the county shaking fill stayed frozen on
  /// the map for the rest of the replay.
  bool _eewSourceEmpty = true;

  Future<void> _updateEew() async {
    final controller = _controller;
    if (controller == null || !_ready) return;
    final empty = widget.eew.alerts.isEmpty;
    // Nothing to draw and nothing drawn — skip the per-tick round trip.
    if (empty && _eewSourceEmpty) return;
    try {
      await controller.setGeoJsonSource(
        _eewSourceId,
        empty ? _emptyCollection : _eewGeoJson(),
      );
      _eewSourceEmpty = empty;
    } catch (_) {
      // Source not on the map yet (mid style-reload) — the next update
      // retries; the flag is untouched because the write never landed.
    }
    await _updateAreaFill(controller);
  }

  /// Tints the whole island by estimated shaking while an EEW alert is up —
  /// the legacy monitor's county/town fill behaviour, driven by the same
  /// [`EewEstimator.areaPga`] math. The base style's own `town` fill layer is
  /// recoloured with a `match` on each township's `CODE` (hidden counties
  /// beneath), so the felt-intensity wash reads over the base map without a
  /// second geometry source; when the alerts clear the fills are restored.
  ///
  /// Recomputed only when the alert set's id/serial combos change — the 368-
  /// town estimate is cheap but the platform churn isn't.
  Future<void> _updateAreaFill(MapLibreMapController controller) async {
    final alerts = widget.eew.alerts;
    final key = alerts.isEmpty
        ? null
        : alerts.map((e) => '${e.id}:${e.serial}').join(',');
    if (key == _fillEewKey) return;
    _fillEewKey = key;

    final baseFill = MapColors.of(Theme.of(context).brightness).fill;
    try {
      if (alerts.isEmpty) {
        await controller.setLayerProperties(
          countyFillLayerId,
          FillLayerProperties(fillColor: baseFill, fillOpacity: 1),
        );
        await controller.setLayerProperties(
          townFillLayerId,
          FillLayerProperties(fillColor: baseFill, fillOpacity: 1),
        );
        return;
      }

      final eew = alerts.first;
      final estimate = EewEstimator.areaPga(
        epicenter: eew.info.latlng,
        depth: eew.info.depth,
        mag: eew.info.magnitude,
        regionCentroids: {
          for (final town in _directory.all)
            town.code: geo.LatLng(town.lat, town.lng),
        },
      );
      final entries = <Object>[];
      estimate.regions.forEach((code, region) {
        final level = Intensity.toScale(region.i);
        if (level > 0) {
          entries.add(int.parse(code));
          entries.add(IntensityColors.discrete(level).toHexRgb());
        }
      });
      if (entries.isEmpty) return;

      await controller.setLayerProperties(
        countyFillLayerId,
        const FillLayerProperties(fillColor: '#00000000', fillOpacity: 0),
      );
      await controller.setLayerProperties(
        townFillLayerId,
        FillLayerProperties(
          fillColor: <Object>[
            'match',
            ['get', 'CODE'],
            ...entries,
            baseFill,
          ],
          fillOpacity: 1,
        ),
      );
    } catch (_) {
      // Layers gone mid style-reload — the next update re-applies.
    }
  }

  Map<String, dynamic> _rtsGeoJson() {
    final features = <Map<String, dynamic>>[];
    for (final entry in widget.rts.stations.entries) {
      final station = _stations[entry.key];
      if (station == null) continue;
      final data = entry.value;
      final level = Intensity.toScale(
        data.alert ? data.intensity : data.intensityRaw,
      );
      features.add({
        'type': 'Feature',
        'geometry': {
          'type': 'Point',
          'coordinates': [station.longitude, station.latitude],
        },
        'properties': {
          'i': data.intensityRaw,
          'icon': level > 0 ? _intensityIcon(level, dark: _dark) : '',
          'label': '${entry.key}\n${data.intensityRaw.toStringAsFixed(1)}',
        },
      });
    }
    return {'type': 'FeatureCollection', 'features': features};
  }

  /// Registers the 18 intensity icons (1–9 light + dark) plus the epicentre
  /// cross — drawn in code (see [IntensityIconRenderer]), loaded once per style
  /// load, mirroring the report detail map.
  Future<void> _loadIntensityIcons(MapLibreMapController controller) async {
    final icons = await IntensityIconRenderer.renderAll();
    for (final entry in icons.entries) {
      await controller.addImage(entry.key, entry.value);
    }
  }

  /// Switches the station layer between dots and intensity icons, exactly as
  /// the legacy monitor's `_updateRtsFromCache` did: while a large event's
  /// detection boxes are on the map, the per-station intensity icons replace
  /// the coloured dots and their id/reading labels; the moment the boxes are
  /// gone the dots come back.
  Future<void> _syncStationMode() async {
    final controller = _controller;
    if (controller == null || !_ready) return;
    final iconMode = widget.rts.box.isNotEmpty;
    if (iconMode == _lastIconMode) return;
    _lastIconMode = iconMode;
    try {
      await Future.wait([
        controller.setLayerVisibility(_rtsCircleId, !iconMode),
        controller.setLayerVisibility(_rtsLabelId, !iconMode),
        controller.setLayerVisibility(_rtsIntensityId, iconMode),
      ]);
    } catch (_) {
      // Layers gone mid style-reload — the next update retries.
    }
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
    return Stack(
      children: [
        Positioned.fill(
          child: BaseMap(
            // GPS on: the map shows the user's position, and the EEW cards'
            // local-intensity tiles resolve against the current location the
            // same way the legacy monitor's did.
            showUserLocation: true,
            compassEnabled: false,
            onMapCreated: _onMapCreated,
            onStyleLoaded: () => unawaited(_onStyleLoaded()),
            onCameraMove: (position) => _bearing.value = position.bearing,
          ),
        ),
        // North indicator, matching the map tab's Flutter [MapCompass] —
        // parked at top-right, level with the page's back button.
        Positioned(
          top: 0,
          right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: MapCompass(bearing: _bearing, onPressed: _resetNorth),
            ),
          ),
        ),
      ],
    );
  }
}

/// The replay's EEW alert card — one alert at a time, tapping cycles through
/// the active set (see the count chip). Wraps the same [EewCardContent] the
/// earthquake monitor's [EewCard] uses (same feature, so no layering issue)
/// in its own bordered, tappable frame, so the header/tiles can't drift
/// between the two; the countdown ticks against the replay's own clock so a
/// historical alert counts down from its timeline, not real now.
class _EewAlertCard extends StatelessWidget {
  const _EewAlertCard({
    required this.eew,
    required this.clock,
    required this.position,
    required this.count,
    this.onTap,
  });

  final Eew eew;

  /// The instant the S-wave countdown is measured against — the replay clock.
  final DateTime Function() clock;

  /// This alert's 1-based position within [count]; the chip only shows when
  /// there is more than one alert to cycle through.
  final int position;

  /// The number of currently-active alerts.
  final int count;

  /// Advances to the next alert; null when it is the only one.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.2),
      color: colors.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.medium,
        side: BorderSide(color: colors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: EewCardContent(
            eew: eew,
            clock: clock,
            trailing: count > 1
                ? _AlertCountChip(position: position, count: count)
                : null,
          ),
        ),
      ),
    );
  }
}

/// A small "n/total" pill signalling that tapping the card cycles the alert.
class _AlertCountChip extends StatelessWidget {
  const _AlertCountChip({required this.position, required this.count});

  final int position;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.swap_horiz, size: 14, color: colors.onSurfaceVariant),
          const SizedBox(width: 2),
          Text(
            '$position/$count',
            style: theme.textTheme.labelMedium?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
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

  static final DateFormat _clockFormat = DateFormat('HH:mm:ss');

  Widget _buildContent(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final taipeiTime = AppTime.taipei(clock.now());
    final timeText = _clockFormat.format(taipeiTime);

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
          LegendDot(color: dot),
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
