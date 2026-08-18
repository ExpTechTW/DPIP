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
import 'package:dpip/core/settings/eew_cwa_only_settings.dart';
import 'package:dpip/core/realtime/app_time.dart';
import 'package:dpip/core/realtime/realtime_service.dart';
import 'package:dpip/core/realtime/realtime_state.dart';
import 'package:dpip/core/realtime/replay_clock.dart';
import 'package:dpip/features/earthquake/domain/eew.dart';
import 'package:dpip/features/earthquake/domain/eew_estimator.dart';
import 'package:dpip/shared/seismic/intensity.dart';
import 'package:dpip/shared/seismic/intensity_circle_renderer.dart';
import 'package:dpip/features/earthquake/domain/rts_box_grid.dart';
import 'package:dpip/features/earthquake/domain/seismic_station.dart';
import 'package:dpip/features/earthquake/domain/seismic_travel_time.dart';
import 'package:dpip/features/earthquake/domain/trem_station_repository.dart';
import 'package:dpip/features/earthquake/presentation/eew_realtime_controller.dart';
import 'package:dpip/features/earthquake/presentation/rts_realtime_controller.dart';
import 'package:dpip/features/earthquake/presentation/widgets/eew_card.dart';
import 'package:dpip/shared/seismic/intensity_icon_renderer.dart';
import 'package:dpip/features/earthquake/replay_session.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/color_hex.dart';
import 'package:dpip/shared/widgets/alert_cycle_chip.dart';
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

  /// Bumped on a fixed cadence so the displayed clock, the EEW countdown, and
  /// the box-coverage check keep advancing independent of whether a poll
  /// actually changed the underlying feed data (a realtime channel only emits
  /// on a real transition). The wave-front rings redraw on their own, faster
  /// cadence instead — see `_ReplayMapState._wavefrontTicker`.
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
      cwaOnly: () => context.read<EewCwaOnlySettings>().enabled,
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
                    const SizedBox(height: AppSpacing.sm),
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

  /// Per-station discrete-reading badge — a circular version of the legacy
  /// monitor's square `intensity` layer (see [IntensityCircleRenderer]):
  /// while a large event's detection boxes are up, each shaking station gets
  /// a numbered badge over its dot instead of the plain colour, but the
  /// shape stays a circle. `icon` is empty for a station with nothing to
  /// badge, so a plain dot underneath just keeps showing through.
  static const String _rtsIntensityCircleId = 'replay-rts-intensity-circle';

  /// Shared by the dot layer's `circleSortKey` and the badge layer's
  /// `symbolSortKey`: higher effective intensity draws on top in both, so a
  /// calmer, overlapping station never hides a hotter one. Reads `sort` (see
  /// [_rtsGeoJson]), the alert-aware value the badge is actually drawn from,
  /// not the raw `i` — a sort key stuck on `i` let a lower badge draw over a
  /// higher one the moment an alert's discrete reading diverged from the
  /// station's own raw sensor value.
  static const List<Object> _rtsSortKey = [
    'coalesce',
    ['get', 'sort'],
    -5,
  ];

  /// The discrete-reading badge's on-map scale of its 64px artwork. The
  /// legacy monitor's own badge layer used 0.2 at z5 → 0.8 at z10, but that
  /// assumed native-resolution PNG assets — applied to a baked canvas here it
  /// renders at only device-pixel size, ~13px on a 3x display and effectively
  /// invisible. [ReportDetailPage] already solved this for the same 64px
  /// canvas class ([IntensityIconRenderer]); reusing its scale here.
  static const List<Object> _badgeIconSize = [
    'interpolate',
    ['linear'],
    ['zoom'],
    5,
    0.75,
    15,
    1.7,
  ];

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
  SeismicTravelTimeTable? _travelTimeTable;
  RtsBoxGrid? _boxGrid;

  /// The township directory, for the whole-island estimated-shaking tint.
  late final TownDirectory _directory = context.read<TownDirectory>();

  /// The EEW id/serial combo the town/county fill is currently tinted for —
  /// recomputing the 368-town estimate every tick is wasteful when nothing
  /// changed, so the fill only updates when this key does.
  String? _fillEewKey;

  /// Legacy-style blink: while a large event's detection boxes are on the map
  /// they (and the EEW epicentre cross) toggle visibility on a 1 s cadence so
  /// they stand out from the static replay surface — ported from the legacy
  /// monitor's `_setupBlinkTimer`.
  Timer? _blinkTimer;
  bool _boxVisible = true;
  bool _epicenterVisible = true;

  /// Redraws the EEW wave-front rings at close to display-refresh rate —
  /// independent of the page's own slower [_ReportReplayPageState._tick]
  /// (which only needs to be fast enough for the status clock, the EEW
  /// countdown, and the box-coverage check). The ring is real polygon
  /// geometry ([circleFeature]), not a `circle-radius` paint property MapLibre
  /// can tween on its own, so this is what stands between a silky-smooth
  /// expansion and a visibly stepped one. Cheap to run unconditionally: a calm
  /// [_updateEew] is a same-run early return, same as [_setupBlink]'s tick.
  Timer? _wavefrontTicker;

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

  /// Pauses the 1 Hz blink and the wave-front ticker while the app is
  /// backgrounded — their platform writes would keep running under the lock
  /// screen otherwise. Restarting on resume just resets the blink phase,
  /// which is invisible.
  late final AppLifecycleListener _blinkLifecycle = AppLifecycleListener(
    onPause: () {
      _blinkTimer?.cancel();
      _blinkTimer = null;
      _wavefrontTicker?.cancel();
      _wavefrontTicker = null;
    },
    onResume: () {
      if (_ready) {
        _setupBlink();
        _startWavefrontTicker();
      }
    },
  );

  @override
  void dispose() {
    _blinkLifecycle.dispose();
    widget.rts.removeListener(_onRts);
    widget.tick.removeListener(_onTick);
    _blinkTimer?.cancel();
    _wavefrontTicker?.cancel();
    _bearing.dispose();
    super.dispose();
  }

  void _startWavefrontTicker() {
    _wavefrontTicker?.cancel();
    _wavefrontTicker = Timer.periodic(
      const Duration(milliseconds: 16),
      (_) => unawaited(_updateEew()),
    );
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
    try {
      final data = await IntensityIconRenderer.render('cross');
      await controller.addImage(_crossIcon, data);

      await controller.addSource(
        _rtsSourceId,
        GeojsonSourceProperties(data: _emptyCollection),
      );
      await controller.addCircleLayer(
        _rtsSourceId,
        _rtsCircleId,
        CircleLayerProperties(
          // A `grey`-flagged feature (see [_rtsGeoJson]) paints the discrete
          // scale's own 0-grey instead of the continuous ramp: a station on
          // a large event's alert list reading a flat 0 stays visibly part
          // of the network rather than fading into whatever pale colour the
          // ramp gives a near-zero reading — ported from the legacy
          // monitor's separate `intensity0` grey layer.
          circleColor: <Object>[
            'case',
            [
              '==',
              ['get', 'grey'],
              1,
            ],
            IntensityColors.discrete(0).toHexRgb(),
            InstrumentalIntensityColors.mapLibreInterpolate,
          ],
          circleRadius: _rtsRadiusExpression,
          circleStrokeColor: '#9E9E9E',
          circleStrokeWidth: 1,
          // Higher intensity draws on top of a calmer, overlapping dot —
          // ported from the legacy monitor's `circleSortKey: coalesce(get('i'),
          // -5)`; missing this let station dots stack in whatever order the
          // feed happened to list them, same class of bug as the box layer's
          // missing sort key.
          circleSortKey: _rtsSortKey,
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
      await _loadIntensityCircleIcons(controller);
      // The discrete-reading badge — always on top of the plain dot (added
      // after the circle/label above, same anchor); `icon` is empty for
      // most stations most of the time, so this is a no-op render for them.
      await controller.addSymbolLayer(
        _rtsSourceId,
        _rtsIntensityCircleId,
        const SymbolLayerProperties(
          iconImage: <Object>['get', 'icon'],
          // The baked artwork is a fixed 64px canvas — left at the default
          // 1.0 it drew full-size at every zoom, badge circles swallowing
          // whole townships. Scales with zoom instead, same stops as the
          // legacy monitor's own badge layer.
          iconSize: _badgeIconSize,
          iconAllowOverlap: true,
          iconIgnorePlacement: true,
          // Same "stronger wins" rule as the dot layer's circleSortKey above
          // — two badges can overlap just like two dots can, and a low
          // reading must never paint over a high one. (`symbol-z-order`
          // defaults to `auto`, which honours the sort key; naming it
          // `source` here would silently drop back to feed-iteration order.)
          symbolSortKey: _rtsSortKey,
        ),
        belowLayerId: townLabelLayerId,
      );
    } catch (e, st) {
      Log.handle(e, st, 'replay map render failed');
    }
    // RTS box grid, in its own try/catch — before the EEW wave/epicentre
    // setup below, so it stacks *below* the epicentre cross and the P/S wave
    // rings once both are anchored at the same [townLabelLayerId] (each
    // insertion goes directly below its anchor, so the later one ends up on
    // top) — matching the legacy monitor's insertion order: box, then wave
    // rings, then epicentre last/topmost. Isolated so a failure here can
    // never take down the station dots / EEW wave circles.
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
          // Draw order for overlapping boxes — red (`i` highest) always on
          // top, then yellow, then green, matching the legacy monitor's box
          // layer (`lineSortKey: [Expressions.get, 'i']`). Without this,
          // overlapping boxes stack in whatever order the feed happened to
          // list them, so a low-intensity box could paint over a red one.
          lineSortKey: <Object>['get', 'i'],
        ),
        // Detection-box borders stay under the township names.
        belowLayerId: townLabelLayerId,
      );
    } catch (e, st) {
      Log.handle(e, st, 'replay box layer render failed');
    }
    // EEW epicentre + P/S wave rings, isolated so a failure here can never
    // take down the station dots / box grid set up above.
    try {
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
    _ready = true;
    await _ensureStations();
    unawaited(_updateRts());
    unawaited(_updateBox());
    unawaited(_updateEew());
    _setupBlink();
    _startWavefrontTicker();
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

  void _onTick() {
    // A box's S-wave coverage (see [_isBoxFullyCovered]) grows continuously,
    // so it has to be re-evaluated here too — not just on [_onRts] — or a box
    // stops blinking only whenever the next poll happens to land, well after
    // the wavefront actually crossed it. The wavefront itself redraws on its
    // own, faster ticker ([_wavefrontTicker]) — this cadence is plenty for a
    // coverage check nobody times to the millisecond.
    unawaited(_updateBox());
  }

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

  /// Registers the 18 circular discrete-reading badges (1–9 light + dark) —
  /// drawn in code (see [IntensityCircleRenderer]), loaded once per style load.
  Future<void> _loadIntensityCircleIcons(
    MapLibreMapController controller,
  ) async {
    final icons = await IntensityCircleRenderer.renderAll();
    for (final entry in icons.entries) {
      await controller.addImage(entry.key, entry.value);
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
    // Large event: the feed also carries box-grid data. The legacy monitor
    // decluttered to just the stations that registered something and badged
    // each with its discrete reading — ported here as a circular badge (see
    // [_rtsIntensityCircleId]), never a shape swap: the dot underneath is
    // still the same circle, the badge is just a fuller circle drawn over it.
    final hasBox = widget.rts.box.isNotEmpty;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final features = <Map<String, dynamic>>[];
    for (final entry in widget.rts.stations.entries) {
      final station = _stations[entry.key];
      if (station == null) continue;
      final data = entry.value;
      // The value actually shown — an alerting station's badge/colour come
      // from the broadcast discrete reading, not its own raw sensor value,
      // exactly like the legacy monitor's `alert ? I : i` split.
      final effective = data.alert ? data.intensity : data.intensityRaw;
      final level = Intensity.toScale(effective);
      // A calm, non-alerting 0 would otherwise paper the whole island in
      // identical dots while the shaking area gets lost in the crowd.
      if (hasBox && level == 0 && !data.alert) continue;
      features.add({
        'type': 'Feature',
        'geometry': {
          'type': 'Point',
          'coordinates': [station.longitude, station.latitude],
        },
        'properties': {
          'i': data.intensityRaw,
          // Sort key for both the dot and the badge layer — see
          // [_rtsSortKey] for why this must be [effective], not the raw `i`.
          'sort': effective,
          'label': '${entry.key}\n${data.intensityRaw.toStringAsFixed(1)}',
          'icon': hasBox && level > 0
              ? _intensityCircleIcon(level, dark: dark)
              : '',
          // Only reachable when `alert` is true (the filter above already
          // dropped a calm zero) — an alerting station reading a flat 0
          // stays grey rather than a badge, matching the legacy monitor's
          // separate `intensity0` layer.
          'grey': hasBox && level == 0 ? 1 : 0,
        },
      });
    }
    return {'type': 'FeatureCollection', 'features': features};
  }

  /// The circular badge icon for scale index 1–9, dark or light artwork.
  static String _intensityCircleIcon(int level, {required bool dark}) =>
      dark ? 'circle-$level-dark' : 'circle-$level';

  /// One polygon per box id present in the live feed's `rts.box`, joined
  /// against the static [grid] for its geometry — dropping any box the
  /// S-wave has already fully swept past (see [_isBoxFullyCovered]) so it
  /// stops blinking instead of blinking forever once it's no longer live
  /// information.
  Map<String, dynamic> _boxGeoJson(RtsBoxGrid grid) {
    final table = _travelTimeTable;
    final now = widget.clock.now();
    final features = <Map<String, dynamic>>[];
    for (final entry in widget.rts.box.entries) {
      final id = int.tryParse(entry.key);
      final ring = id == null ? null : grid.rings[id];
      if (ring == null) continue;
      if (table != null && _isBoxFullyCovered(ring, table, now)) continue;
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

  /// Whether every corner of [ring] is already within some active alert's
  /// S-wave radius — ported from the legacy monitor's `checkBoxSkip`, which
  /// dropped a detection box from the map (not just its blink) the instant
  /// the wavefront had fully swept past it, since by then it's a stale
  /// reading rather than live shaking data.
  bool _isBoxFullyCovered(
    List<List<double>> ring,
    SeismicTravelTimeTable table,
    DateTime now,
  ) {
    for (final eew in widget.eew.alerts) {
      final info = eew.info;
      final elapsed = now.difference(
        DateTime.fromMillisecondsSinceEpoch(info.time, isUtc: true),
      );
      if (elapsed.isNegative) continue;
      final radiusKm = table.waveRadius(info.depth, elapsed).s;
      if (radiusKm <= 0) continue;
      final epicenter = info.latlng;
      final allCornersCovered = ring
          .take(4)
          .every(
            (point) =>
                epicenter.distanceTo(geo.LatLng(point[1], point[0])) / 1000 <=
                radiusKm,
          );
      if (allCornersCovered) return true;
    }
    return false;
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
    final originUtc = DateTime.fromMillisecondsSinceEpoch(eew.info.time);
    final maxIntensity = Intensity.displayForReport(eew.info.max, originUtc);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.2),
      color: colors.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.medium,
        // The border reads off the same discrete scale as the badge — a
        // calm/low reading stays close to the neutral outline it replaces,
        // a severe one is unmistakable before you even read the number.
        side: BorderSide(
          color: IntensityColors.discrete(maxIntensity.colorLevel),
          width: 2,
        ),
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
                ? AlertCycleChip(position: position, count: count)
                : null,
          ),
        ),
      ),
    );
  }
}

/// Bottom status card: a freshness dot, the replay clock (tinted orange, the
/// legacy "this is replay, not live" signal), the RTS feed's status word when
/// not healthy, and an EEW alert count when one is active. While an alert is
/// active the whole strip turns red-on-`errorContainer` — the legacy
/// monitor's `MorphingSheet` did the same (`borderColor`/`backgroundColor` on
/// `activeEew.isNotEmpty`, binary rather than scaled by severity) — so it
/// reads as urgent even collapsed, not just the card above it.
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
    final hasActiveEew = alertCount > 0;
    final onTint = hasActiveEew ? colors.onErrorContainer : null;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: hasActiveEew
            ? colors.errorContainer.withValues(alpha: 0.94)
            : colors.surface.withValues(alpha: 0.94),
        borderRadius: AppRadius.medium,
        border: hasActiveEew ? Border.all(color: colors.error, width: 2) : null,
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
                color: onTint,
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
              color: onTint ?? Colors.orange,
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
                color: onTint ?? colors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
