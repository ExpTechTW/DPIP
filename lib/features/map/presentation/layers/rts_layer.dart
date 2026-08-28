/// The 強震監視器 (real-time seismic monitor) map layer — every reporting station
/// as a dot coloured by its live shaking intensity, refreshed from the RTS feed,
/// plus live EEW (epicentre cross + P/S wave-front circles) while an alert is up.
library;

import 'dart:async';

import 'package:dpip/core/a11y/color_vision.dart';
import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/models/lat_lng.dart' as geo;
import 'package:dpip/core/realtime/app_time.dart';
import 'package:dpip/core/realtime/realtime_notifier.dart';
import 'package:dpip/core/realtime/realtime_state.dart';
import 'package:dpip/features/earthquake/domain/eew.dart';
import 'package:dpip/features/earthquake/domain/eew_estimator.dart';
import 'package:dpip/features/earthquake/domain/rts.dart';
import 'package:dpip/features/earthquake/domain/rts_box_grid.dart';
import 'package:dpip/features/earthquake/domain/seismic_station.dart';
import 'package:dpip/features/earthquake/domain/seismic_travel_time.dart';
import 'package:dpip/features/earthquake/domain/trem_station_repository.dart';
import 'package:dpip/features/map/presentation/widgets/rts_monitor_panel.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/color_hex.dart';
import 'package:dpip/shared/map/geo_circle.dart';
import 'package:dpip/shared/map/map_layer.dart';
import 'package:dpip/shared/map/map_station_labels.dart';
import 'package:dpip/shared/map/map_style.dart'
    show
        MapColors,
        countyFillLayerId,
        landLayerId,
        townFillLayerId,
        townLabelLayerId;
import 'package:dpip/shared/seismic/intensity.dart';
import 'package:dpip/shared/seismic/intensity_circle_renderer.dart';
import 'package:dpip/shared/seismic/intensity_colors.dart';
import 'package:dpip/shared/seismic/intensity_icon_renderer.dart';
import 'package:dpip/shared/widgets/intensity_legend.dart';
import 'package:dpip/shared/widgets/map_color_legend.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

/// The EEW map overlay as GeoJSON: per active alert an epicentre cross plus the
/// expanding P/S wave-front rings, radii from the CWA travel-time table and
/// measured against [now] — the same geometry the replay page draws for its own
/// alerts. Pure (no controller) so the shape is unit-testable.
///
/// [table] may be null while the bundled asset is still loading: the cross
/// still renders, the rings wait for the table. A report whose origin is in the
/// future (a clock skew or a just-published event) renders the cross only —
/// never a wavefront that hasn't started.
Map<String, dynamic> eewWaveGeoJson(
  List<Eew> alerts,
  SeismicTravelTimeTable? table,
  DateTime now,
) {
  final features = <Map<String, dynamic>>[];
  for (final eew in alerts) {
    final info = eew.info;
    final elapsed = now.difference(
      DateTime.fromMillisecondsSinceEpoch(info.time, isUtc: true),
    );
    if (table != null && !elapsed.isNegative) {
      final radius = table.waveRadius(info.depth, elapsed);
      if (radius.p > 0) {
        features.add(
          circleFeature(
            info.latlng,
            radius.p * 1000,
            properties: const {'type': 'p-line'},
          ),
        );
      }
      if (radius.s > 0) {
        final metres = radius.s * 1000;
        features.add(
          circleFillFeature(
            info.latlng,
            metres,
            properties: const {'type': 's-fill'},
          ),
        );
        features.add(
          circleFeature(
            info.latlng,
            metres,
            properties: const {'type': 's-line'},
          ),
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

/// A realtime [MapLayer]: subscribes to the live RTS feed and repaints the
/// station dots (coloured by raw intensity `i`) on every ~1 Hz snapshot, and to
/// the live EEW feed for the epicentre cross + P/S wave-front rings while an
/// alert is active (the same geometry the replay map draws). A large event's
/// detection boxes (see [_pushBox]) mirror the legacy monitor and the replay
/// page. Station dots stay circles always: while a large event's box grid is
/// up, a shaking station gets a circular discrete-reading badge (see
/// [_intensityCircleId]/[IntensityCircleRenderer]) drawn over its dot, but
/// that badge is still a circle — the discrete-intensity *square* badges
/// ([IntensityIconRenderer]) are 震度速報/地震報告 artwork, a different data
/// product from this feed's live instrumental reading, and this layer never
/// reaches for those instead. Not tap- or timeline-driven; its "sheet" is a
/// compact monitor panel showing the feed's freshness and the active EEW
/// cards, and [buildLegend] shows the intensity scale.
class RtsMapLayer with MapLayerDefaults implements MapLayer {
  RtsMapLayer(
    this._feed,
    this._stationRepository, {
    required RealtimeNotifier<List<Eew>> eew,
    required Future<SeismicTravelTimeTable> travelTimeTable,
    required Future<RtsBoxGrid> boxGrid,
    required TownDirectory townDirectory,
    // Not initializing formals: Dart has no private *named* parameter, and
    // these fields must stay private.
    // ignore: prefer_initializing_formals
  }) : _eew = eew,
       // ignore: prefer_initializing_formals
       _travelTimeTable = travelTimeTable,
       // ignore: prefer_initializing_formals
       _boxGridFuture = boxGrid,
       // ignore: prefer_initializing_formals
       _townDirectory = townDirectory;

  final RealtimeNotifier<Rts> _feed;
  final TremStationRepository _stationRepository;
  final RealtimeNotifier<List<Eew>> _eew;
  final Future<SeismicTravelTimeTable> _travelTimeTable;
  final Future<RtsBoxGrid> _boxGridFuture;
  final TownDirectory _townDirectory;

  /// Township centroids, keyed by code — built once from the bundled
  /// directory, which does not change while the app runs. Rebuilding it per
  /// alert serial meant 368 map entries and 368 `LatLng`s allocated on the
  /// frame an alert arrives, which is the frame with the least to spare.
  Map<String, geo.LatLng>? _centroids;

  Map<String, SeismicStation> _stations = const {};
  MapLibreMapController? _controller;
  bool _listening = false;
  bool _eewListening = false;
  bool _added = false;
  RealtimeStatus? _appliedStatus;
  RtsBoxGrid? _boxGrid;

  /// Brightness captured from the last context-bearing call ([buildLegend] /
  /// [buildSheet]) — the render/data-push methods get no `BuildContext`, but
  /// the intensity icons come in light/dark artwork and the area fill needs
  /// the base style's fill colour to reset to, so this is the only way to
  /// track a user-forced theme (not just system brightness) without one.
  bool _dark = false;

  /// The EEW id/serial combo the town/county fill is currently tinted for —
  /// recomputing the estimate for every township is cheap but the platform
  /// churn of re-applying it every tick isn't, so it's skipped when nothing
  /// changed.
  String? _fillEewKey;

  /// Which active alert the monitor panel's card currently shows — tapping it
  /// cycles through the set (see `RtsMonitorPanel`). Owned here, not by the
  /// panel widget, because the area fill ([_updateAreaFill]) has to track the
  /// same selection: with two simultaneous quakes, the ground tint must
  /// follow whichever one the card is actually showing, not always the
  /// newest — the panel and the map are two views of one choice.
  final ValueNotifier<int> eewIndex = ValueNotifier(0);

  /// Legacy-style blink: while a large event's detection boxes are on the map
  /// they (and the EEW epicentre cross) toggle visibility on a 1 s cadence so
  /// they stand out from the calm station dots — ported from the legacy
  /// monitor's `_setupBlinkTimer`.
  Timer? _blinkTimer;
  bool _boxVisible = true;
  bool _epicenterVisible = true;

  /// Whether the EEW source on the map currently holds [_emptyCollection].
  ///
  /// [_pushUpdate] ends with an unconditional [_pushEew], and the RTS feed
  /// notifies about once a second, so a **calm** feed was re-uploading the same
  /// empty collection — a platform-channel round trip and a native GeoJSON
  /// source replacement — once per second for as long as the layer was
  /// attached, which includes while the map tab is hidden (pausing the render
  /// loop does not stop the Dart listener). Tracking what is actually on the
  /// map turns that into a boolean test.
  ///
  /// Only the *empty* case is guarded. While an alert is live the wavefront
  /// geometry is a function of the calibrated clock, so every 200 ms tick
  /// genuinely differs and must still be sent.
  bool _eewSourceEmpty = true;
  bool _stationsFetching = false;
  int _stationRetries = 0;
  SeismicTravelTimeTable? _travelTime;
  Timer? _eewTicker;

  /// Identity of the last payload pushed to the source: `null` when offline
  /// (empty collection was sent), else the feed's data object — skips the
  /// per-tick round trip when a status change re-notifies without new data.
  Object? _lastSent;

  static const String _sourceId = 'rts-src';
  static const String _circleId = 'rts-circle';
  static const String _labelId = 'rts-label';

  /// Per-station discrete-reading badge — a circular version of the legacy
  /// monitor's square `intensity` layer (see [IntensityCircleRenderer]):
  /// while a large event's detection boxes are up, each shaking station gets
  /// a numbered badge over its dot instead of the plain colour, but the
  /// shape stays a circle — this is still live instrumental data, never the
  /// report/rapid-report square. `icon` is empty for a station with nothing
  /// to badge, so a plain dot underneath just keeps showing through.
  static const String _intensityCircleId = 'rts-intensity-circle';
  static const String _eewSourceId = 'rts-eew-src';
  static const String _eewPWaveId = 'rts-eew-p';
  static const String _eewSWaveId = 'rts-eew-s';
  static const String _eewSWaveFillId = 'rts-eew-s-fill';
  static const String _eewEpicenterId = 'rts-eew-epicenter';
  static const String _eewCrossIcon = 'rts-eew-cross';

  static const String _boxSourceId = 'rts-box-src';
  static const String _boxLineId = 'rts-box-line';

  /// Box-grid border colour by intensity `i`: red ≥4, yellow 2–3, green
  /// below — ported from the legacy monitor's box colour scheme.
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

  /// Wave-front rings keep expanding between RTS polls (a realtime channel only
  /// emits on a real transition) — a fixed cadence redraws them against the
  /// calibrated clock so the circles grow every frame regardless. Close to
  /// display-refresh rate (~60 Hz), not the RTS feed's own ~1 Hz: the ring is
  /// real polygon geometry ([circleFeature]), not a `circle-radius` paint
  /// property MapLibre can tween on its own, so *this* is what stands between
  /// a silky-smooth expansion and a visibly stepped one. Each push is small
  /// (two ~64-point rings), so the extra platform-channel traffic is cheap —
  /// and it only runs at all while an alert is actually live.
  static const Duration _eewTick = Duration(milliseconds: 16);
  static const int _maxStationRetries = 8;
  static const double _liveOpacity = 1.0;
  static const double _staleOpacity = 0.35;

  /// A neutral hairline separating overlapping dots — legacy uses the theme's
  /// outlineVariant, but render() has no BuildContext, so a mid-grey that reads
  /// on both light and dark tiles stands in.
  ///
  /// A getter, not a `const`: the colour-vision transform runs at the
  /// definition and isn't a compile-time constant. (It is the identity on a
  /// pure grey — routing it anyway keeps the rule uniform for whoever tints
  /// this later.)
  static String get _strokeColor => '#9E9E9E'.vision;
  static const Map<String, dynamic> _emptyCollection = {
    'type': 'FeatureCollection',
    'features': <dynamic>[],
  };

  /// This layer's `MapLayer.id` — 強震監視器.
  ///
  /// A constant as well as the getter because a caller outside the map needs
  /// it without an instance: an EEW notification tap names this overlay when
  /// it opens the map tab (`notificationChannelMapLayers`).
  static const String layerId = 'monitor';

  @override
  String get id => layerId;

  @override
  IconData get icon => Icons.sensors_outlined;

  @override
  String label(BuildContext context) =>
      AppLocalizations.of(context).mapLayerMonitor;

  @override
  bool get usesTimeline => false;

  @override
  double get bottomChromeFraction {
    // A live alert raises the sheet: the EEW cards sit above the status strip,
    // so a deliberate framing must leave room for the whole stack.
    final live =
        _eew.state.status == RealtimeStatus.live &&
        (_eew.state.data?.isNotEmpty ?? false);
    return live
        ? RtsMonitorPanel.expandedBottomFraction
        : RtsMonitorPanel.bottomStripFraction;
  }

  @override
  Future<void> render(MapLibreMapController controller) async {
    _controller = controller;
    await _ensureStations();
    await _removeFromMap(controller);
    await controller.addSource(
      _sourceId,
      GeojsonSourceProperties(data: _geoJson()),
    );
    await controller.addCircleLayer(
      _sourceId,
      _circleId,
      _circleProps(_liveOpacity),
      // Station dots under the township names — a live reading must never
      // hide where you are.
      belowLayerId: townLabelLayerId,
    );
    // Station id over its raw intensity, pinned under the dot; the sort key
    // lets hot stations win placement (see [stationLabelProps]).
    await controller.addSymbolLayer(
      _sourceId,
      _labelId,
      _labelProps(_liveOpacity),
      minzoom: 10,
      // Township names stay the top-most text — station labels give way to
      // them on collision (the layer order decides who wins placement).
      belowLayerId: townLabelLayerId,
    );
    await _loadIntensityCircleIcons(controller);
    // The discrete-reading badge — always on top of the plain dot (added
    // after [_circleId]/[_labelId], same anchor); `icon` is empty for most
    // stations most of the time, so this is a no-op render for them.
    await controller.addSymbolLayer(
      _sourceId,
      _intensityCircleId,
      const SymbolLayerProperties(
        iconImage: <Object>['get', 'icon'],
        // The baked artwork is a fixed 64px canvas — left at the default
        // 1.0 it drew full-size at every zoom, badge circles swallowing
        // whole townships. Scales with zoom instead, same stops as the
        // legacy monitor's own badge layer.
        iconSize: _badgeIconSize,
        iconAllowOverlap: true,
        iconIgnorePlacement: true,
        // Same "stronger wins" rule as the dot layer's circleSortKey below —
        // two badges can overlap just like two dots can, and a low reading
        // must never paint over a high one. (`symbol-z-order` defaults to
        // `auto`, which honours the sort key; naming it `source` here would
        // silently drop back to feed-iteration order.)
        symbolSortKey: _sortKey,
      ),
      belowLayerId: townLabelLayerId,
    );
    // RTS box grid, in its own try/catch — before the EEW wave/epicentre
    // setup below, so it stacks *below* the epicentre cross and the P/S wave
    // rings once both are anchored at the same [townLabelLayerId] (each
    // insertion goes directly below its anchor, so the later one ends up on
    // top) — matching the legacy monitor's insertion order: box, then wave
    // rings, then epicentre last/topmost. Isolated so a failure here can
    // never take down the station dots / EEW layers.
    try {
      await controller.addSource(
        _boxSourceId,
        GeojsonSourceProperties(data: _emptyCollection),
      );
      await controller.addLineLayer(
        _boxSourceId,
        _boxLineId,
        const LineLayerProperties(
          lineColor: _boxColorExpression,
          lineWidth: 2,
          visibility: 'none',
          // Red always draws over yellow/green — ported from the legacy
          // monitor's box layer (`lineSortKey: [Expressions.get, 'i']`).
          lineSortKey: <Object>['get', 'i'],
        ),
        belowLayerId: townLabelLayerId,
      );
    } catch (e, st) {
      Log.handle(e, st, 'rts box layer render failed');
    }
    await _setupEew(controller);
    _added = true;
    _appliedStatus = null;
    // [_setupEew] has just seeded the source with [_emptyCollection].
    _eewSourceEmpty = true;
    await _pushUpdate();
    if (!_listening) {
      _feed.addListener(_onFeed);
      _listening = true;
    }
    if (!_eewListening) {
      _eew.addListener(_onEew);
      _eewListening = true;
    }
    _startEewTicker();
    _setupBlink();
    _travelTimeTable.then((table) {
      _travelTime = table;
      unawaited(_pushEew());
    });
    _boxGridFuture.then((grid) {
      _boxGrid = grid;
      unawaited(_pushBox());
    });
  }

  void _startEewTicker() {
    _eewTicker?.cancel();
    _eewTicker = Timer.periodic(_eewTick, (_) {
      // Only repaint while an alert is actually up — a calm feed needs no
      // platform churn, and the `_onEew` listener already clears the source
      // the moment an alert leaves.
      final live =
          _eew.state.status == RealtimeStatus.live &&
          (_eew.state.data?.isNotEmpty ?? false);
      if (live) {
        unawaited(_pushEew());
        // A box's S-wave coverage (see [_isBoxFullyCovered]) grows every
        // tick even between RTS polls, so it has to be re-evaluated here
        // too — not just on [_onFeed] — or a box stops blinking only
        // whenever the next poll happens to land, well after the wavefront
        // actually crossed it.
        unawaited(_pushBox());
      }
    });
  }

  void _onFeed() => unawaited(_pushUpdate());

  void _onEew() => unawaited(_pushEew());

  /// Whether the hosting surface can currently be seen. The feeds keep
  /// polling either way — they are safety feeds and the monitor panel's
  /// freshness depends on them — but re-uploading a full station GeoJSON at
  /// 1 Hz (and the EEW wavefront at 5 Hz) to a map that sits behind another
  /// tab is a platform-channel serialisation nobody can see.
  bool _surfaceVisible = true;

  @override
  void onSurfaceVisibility(bool visible) {
    _surfaceVisible = visible;
    if (visible) {
      // One catch-up on the visible edge: the skipped uploads left the map at
      // whatever second it was hidden on.
      _lastSent = null;
      _appliedStatus = null;
      if (_added) {
        _startEewTicker();
        _setupBlink();
        unawaited(_pushUpdate());
      }
    } else {
      // The 5 Hz wavefront ticker stops outright — during a live alert in
      // the background it was five timer wakeups a second for uploads the
      // gate above was already discarding.
      _eewTicker?.cancel();
      _eewTicker = null;
      _blinkTimer?.cancel();
      _blinkTimer = null;
    }
  }

  Future<void> _pushUpdate() async {
    final controller = _controller;
    if (controller == null || !_added || !_surfaceVisible) return;
    if (_stations.isEmpty) await _ensureStations();
    final status = _feed.state.status;
    // Never present aged shaking as current: hide the dots when the feed is
    // offline, and dim them while stale (the monitor panel flags the status too).
    final offline = status == RealtimeStatus.offline;
    // A status-only change (stale→live etc.) re-notifies without new data —
    // don't re-send the same payload, just re-apply the opacity below.
    final data = _feed.state.data;
    final payloadKey = offline ? null : data;
    try {
      if (!identical(payloadKey, _lastSent)) {
        _lastSent = payloadKey;
        await controller.setGeoJsonSource(
          _sourceId,
          offline ? _emptyCollection : _geoJson(),
        );
      }
      if (status != _appliedStatus) {
        _appliedStatus = status;
        final opacity = status == RealtimeStatus.live
            ? _liveOpacity
            : _staleOpacity;
        await controller.setLayerProperties(_circleId, _circleProps(opacity));
        await controller.setLayerProperties(_labelId, _labelProps(opacity));
      }
    } catch (_) {
      // Source not on the map (mid style-reload); the next render re-adds it.
    }
    await _pushBox();
    await _pushEew();
  }

  /// Repaints the EEW overlay. An alert is only current while its feed is live;
  /// a stale/offline EEW feed's last snapshot must never be presented as an
  /// expanding wavefront, so anything not live renders nothing.
  Future<void> _pushEew() async {
    final controller = _controller;
    if (controller == null || !_added || !_surfaceVisible) return;
    final live =
        _eew.state.status == RealtimeStatus.live &&
        (_eew.state.data?.isNotEmpty ?? false);
    await _updateAreaFill(controller, live ? _eew.state.data! : const []);
    // Nothing to draw and nothing drawn — the overwhelmingly common case.
    if (!live && _eewSourceEmpty) return;
    try {
      await controller.setGeoJsonSource(
        _eewSourceId,
        live ? _eewGeoJson() : _emptyCollection,
      );
      _eewSourceEmpty = !live;
    } catch (_) {
      // Source not on the map (mid style-reload); the next render re-adds it.
      // The flag is left alone: the write never landed, so whatever was on the
      // map before still is.
    }
  }

  Map<String, dynamic> _eewGeoJson() =>
      eewWaveGeoJson(_eew.state.data ?? const [], _travelTime, AppTime.utc);

  /// Adds the EEW source + layers: the S wave's translucent disc ("inner
  /// circle") — the damaging, already-shaking zone — anchored below the land
  /// layer so the wash only shows over open sea, never over Taiwan itself. The
  /// P wave is a heads-up leading edge only, no fill; the epicentre cross sits
  /// on top. The cross artwork is drawn in code, like every other map icon —
  /// the legacy PNG `assets/map/icons/cross.png` does not exist and must not
  /// be loaded. Isolated in its own try/catch so a failure here can never take
  /// down the station dots set up above.
  Future<void> _setupEew(MapLibreMapController controller) async {
    try {
      final data = await IntensityIconRenderer.render('cross');
      await controller.addImage(_eewCrossIcon, data.buffer.asUint8List());
      await controller.addSource(
        _eewSourceId,
        GeojsonSourceProperties(data: _emptyCollection),
      );
      await controller.addFillLayer(
        _eewSourceId,
        _eewSWaveFillId,
        // Vector geometry we draw ourselves, so it recolours with the app.
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
        _eewPWaveId,
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
        _eewSWaveId,
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
        _eewEpicenterId,
        const SymbolLayerProperties(
          iconImage: _eewCrossIcon,
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
      Log.handle(e, st, 'rts EEW layer render failed');
    }
  }

  /// Registers the 18 circular discrete-reading badges (1–9 light + dark) —
  /// drawn in code (see [IntensityCircleRenderer]), loaded once per render.
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
  /// still carry live detail.
  Future<void> _pushBox() async {
    final controller = _controller;
    final grid = _boxGrid;
    if (controller == null || !_added || !_surfaceVisible || grid == null) {
      return;
    }
    final hasBox = (_feed.state.data?.box.isNotEmpty) ?? false;
    try {
      if (hasBox) {
        await controller.setGeoJsonSource(_boxSourceId, _boxGeoJson(grid));
      }
      if (hasBox != _boxVisible) {
        _boxVisible = hasBox;
        await controller.setLayerVisibility(_boxLineId, hasBox);
      }
    } catch (_) {
      // Source/layer not on the map yet (mid style-reload) — the next update retries.
    }
  }

  /// One polygon per box id present in the live feed's `rts.box`, joined
  /// against the static [grid] for its geometry — dropping any box the
  /// S-wave has already fully swept past (see [_isBoxFullyCovered]) so it
  /// stops blinking instead of blinking forever once it's no longer live
  /// information.
  Map<String, dynamic> _boxGeoJson(RtsBoxGrid grid) {
    final box = _feed.state.data?.box ?? const {};
    final alerts = _eew.state.data ?? const <Eew>[];
    final now = AppTime.utc;
    final features = <Map<String, dynamic>>[];
    for (final entry in box.entries) {
      final id = int.tryParse(entry.key);
      final ring = id == null ? null : grid.rings[id];
      if (ring == null) continue;
      if (_travelTime != null &&
          _isBoxFullyCovered(ring, alerts, _travelTime!, now)) {
        continue;
      }
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
    List<Eew> alerts,
    SeismicTravelTimeTable table,
    DateTime now,
  ) {
    for (final eew in alerts) {
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

  /// Legacy-style blink: while a large event's detection boxes are on the
  /// map they (and the EEW epicentre cross) toggle visibility on a 1 s
  /// cadence so they stand out from the calm station dots — ported from the
  /// legacy monitor's `_setupBlinkTimer`. Only geometry/visibility gating
  /// lives in [_pushBox]/[_pushEew]; this only flips the two layers on/off.
  void _setupBlink() {
    _blinkTimer?.cancel();
    _blinkTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      final controller = _controller;
      if (controller == null || !_added) return;
      try {
        final hasBox = (_feed.state.data?.box.isNotEmpty) ?? false;
        if (hasBox) {
          _boxVisible = !_boxVisible;
          await controller.setLayerVisibility(_boxLineId, _boxVisible);
        } else if (_boxVisible) {
          _boxVisible = false;
          await controller.setLayerVisibility(_boxLineId, false);
        }

        final hasEew =
            _eew.state.status == RealtimeStatus.live &&
            (_eew.state.data?.isNotEmpty ?? false);
        if (hasEew) {
          _epicenterVisible = !_epicenterVisible;
          await controller.setLayerVisibility(
            _eewEpicenterId,
            _epicenterVisible,
          );
        } else if (!_epicenterVisible) {
          _epicenterVisible = true;
          await controller.setLayerVisibility(_eewEpicenterId, true);
        }
      } catch (_) {
        // Layers gone mid style-reload — the next blink retries.
      }
    });
  }

  /// Tints the whole island by estimated shaking while [alerts] is non-empty
  /// — the legacy monitor's county/town fill behaviour, driven by the same
  /// [EewEstimator.areaPga] math the replay page uses. The base style's own
  /// `town` fill layer is recoloured with a `match` on each township's
  /// `CODE` (hidden counties beneath), so the felt-intensity wash reads over
  /// the base map without a second geometry source; when the alerts clear
  /// the fills are restored.
  ///
  /// With two simultaneous quakes this must use whichever alert [eewIndex]
  /// currently selects (the same one the monitor card is showing), not just
  /// the newest — the ground tint and the card are one choice, not two.
  /// Recomputed only when *that* alert's id/serial changes — cheap to check,
  /// but the 368-town estimate + platform write isn't, so a repeat is
  /// skipped. Keying on the selected alert alone (not the whole set) means
  /// tapping to cycle, with the set otherwise unchanged, still invalidates
  /// the cache.
  Future<void> _updateAreaFill(
    MapLibreMapController controller,
    List<Eew> alerts,
  ) async {
    final selected = alerts.isEmpty
        ? null
        : alerts[eewIndex.value % alerts.length];
    final key = selected == null ? null : '${selected.id}:${selected.serial}';
    if (key == _fillEewKey) return;
    _fillEewKey = key;

    final baseFill = MapColors.of(_dark ? Brightness.dark : Brightness.light)
        .fill;
    try {
      if (selected == null) {
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

      final eew = selected;
      final estimate = EewEstimator.areaPga(
        epicenter: eew.info.latlng,
        depth: eew.info.depth,
        mag: eew.info.magnitude,
        regionCentroids: _centroids ??= {
          for (final town in _townDirectory.all)
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

  /// The full circle style at [opacity] — passed whole (not a partial update),
  /// since setLayerProperties resets any property left null. Colour comes from
  /// the shared instrumental-intensity palette, so the dots and the legend can
  /// never drift — except a `grey`-flagged feature (see [_geoJson]), which
  /// paints the discrete scale's own 0-grey instead: a station on a large
  /// event's alert list reading a flat 0 stays visibly part of the network
  /// rather than fading into whatever pale colour the continuous ramp gives
  /// a near-zero reading — ported from the legacy monitor's separate
  /// `intensity0` grey layer.
  CircleLayerProperties _circleProps(double opacity) => CircleLayerProperties(
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
    circleRadius: _radiusExpression,
    circleStrokeColor: _strokeColor,
    circleStrokeWidth: 1,
    circleOpacity: opacity,
    // Stronger stations sort above weaker ones so a hot dot is never hidden.
    circleSortKey: _sortKey,
  );

  /// The full label style at [opacity] — station id over its raw intensity.
  /// Passed whole (setLayerProperties nulls anything omitted); the sort key
  /// places the strongest stations first so a hot reading never loses.
  SymbolLayerProperties _labelProps(double opacity) => stationLabelProps(
    textField: const <Object>['get', 'label'],
    textSize: 10,
    opacity: opacity,
    sortKey: _labelSortKey,
  );

  @override
  Widget buildSheet(BuildContext context) {
    _captureBrightness(context);
    return RtsMonitorPanel(feed: _feed, eew: _eew, eewIndex: eewIndex);
  }

  @override
  Widget buildLegend(BuildContext context) {
    _captureBrightness(context);
    return const MapLegendCard(
      child: IntensityLegend(mode: IntensityLegendMode.rts),
    );
  }

  /// [render]/the data-push methods get no `BuildContext`, but the intensity
  /// icons come in light/dark artwork and the area fill needs the base
  /// style's fill colour to reset to — this is the only place a user-forced
  /// theme (not just system brightness) is visible, so it's cached here for
  /// them to read.
  void _captureBrightness(BuildContext context) {
    _dark = Theme.of(context).brightness == Brightness.dark;
  }

  @override
  Future<void> clear(MapLibreMapController controller) async {
    if (_listening) {
      _feed.removeListener(_onFeed);
      _listening = false;
    }
    if (_eewListening) {
      _eew.removeListener(_onEew);
      _eewListening = false;
    }
    _eewTicker?.cancel();
    _eewTicker = null;
    _blinkTimer?.cancel();
    _blinkTimer = null;
    // The area fill tints the *base style's* county/town layers, not one of
    // this layer's own — leaving it tinted would bleed into whichever layer
    // becomes active next. [_updateAreaFill] no-ops if nothing was applied.
    await _updateAreaFill(controller, const []);
    await _removeFromMap(controller);
    _controller = null;
  }

  @override
  void onStyleReset() {
    _added = false;
    // The style reload wipes the base style's county/town fill back to
    // default — this cache would otherwise think a still-active alert's
    // tint is already applied and skip re-painting it.
    _fillEewKey = null;
  }

  /// Loads the station directory, retrying (bounded) on failure — a transient
  /// fault would otherwise leave every dot dropped (blank monitor) for the whole
  /// activation, since the feed carries only per-id intensities, not positions.
  Future<void> _ensureStations() async {
    if (_stations.isNotEmpty ||
        _stationsFetching ||
        _stationRetries >= _maxStationRetries) {
      return;
    }
    _stationsFetching = true;
    _stationRetries++;
    try {
      final directory = (await _stationRepository.stations()).valueOrNull;
      if (directory != null && directory.isNotEmpty) {
        _stations = directory;
        _stationRetries = 0;
      }
    } finally {
      _stationsFetching = false;
    }
  }

  Map<String, dynamic> _geoJson() {
    final live = _feed.state.data?.station ?? const <String, RtsStation>{};
    // Large event: the feed also carries box-grid data. The legacy monitor
    // decluttered to just the stations that registered something and badged
    // each with its discrete reading — ported here as a circular badge (see
    // [_intensityCircleId]), never a shape swap: the dot underneath is still
    // the same circle, the badge is just a fuller circle drawn over it.
    final hasBox = (_feed.state.data?.box.isNotEmpty) ?? false;
    final features = <Map<String, dynamic>>[];
    for (final entry in live.entries) {
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
          // Sort key for both the dot and the badge layer — must track
          // [effective], not the raw sensor value: an alerting station's
          // badge can show a discrete reading well above (or below) its own
          // instantaneous `i`, and a sort key stuck on `i` let a lower badge
          // draw over a higher one the moment the two diverged on a refresh.
          'sort': effective,
          'label': '${entry.key}\n${data.intensityRaw.toStringAsFixed(1)}',
          'icon': hasBox && level > 0
              ? _intensityCircleIcon(level, dark: _dark)
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

  Future<void> _removeFromMap(MapLibreMapController controller) async {
    // Layers before their sources; tolerate any not currently on the map.
    for (final layerId in [
      _circleId,
      _labelId,
      _intensityCircleId,
      _boxLineId,
      _eewEpicenterId,
      _eewSWaveId,
      _eewPWaveId,
      _eewSWaveFillId,
    ]) {
      try {
        await controller.removeLayer(layerId);
      } catch (_) {
        // Expected when the layer isn't on the map yet.
      }
    }
    for (final sourceId in [_sourceId, _eewSourceId, _boxSourceId]) {
      try {
        await controller.removeSource(sourceId);
      } catch (_) {
        // Expected when the source isn't on the map yet.
      }
    }
  }

  /// Dots scale with zoom so they stay legible zoomed in (legacy: 2px at z4 →
  /// 8px at z12).
  static const List<Object> _radiusExpression = [
    'interpolate',
    ['linear'],
    ['zoom'],
    4,
    2.0,
    12,
    8.0,
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

  /// Higher effective intensity draws on top (dot, badge, and label all key off
  /// this) — reads `sort` (see [_geoJson]), the alert-aware value the badge is
  /// actually drawn from, not the raw `i`. Stations without a `sort` sink.
  static const List<Object> _sortKey = [
    'coalesce',
    ['get', 'sort'],
    -5,
  ];

  /// Labels place strongest-first: a symbol's *lower* sort key wins a collision,
  /// so negate the intensity — a hot station's reading never loses to a calm one.
  static const List<Object> _labelSortKey = [
    '-',
    0,
    [
      'coalesce',
      ['get', 'sort'],
      -5,
    ],
  ];
}
