/// The 強震監視器 (real-time seismic monitor) map layer — every reporting station
/// as a dot coloured by its live shaking intensity, refreshed from the RTS feed,
/// plus live EEW (epicentre cross + P/S wave-front circles) while an alert is up.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/core/models/lat_lng.dart' as geo;
import 'package:dpip/core/platform/render_tier.dart';
import 'package:dpip/core/realtime/app_time.dart';
import 'package:dpip/core/realtime/realtime_notifier.dart';
import 'package:dpip/core/realtime/realtime_state.dart';
import 'package:dpip/features/earthquake/domain/eew.dart';
import 'package:dpip/features/earthquake/domain/eew_town_levels.dart';
import 'package:dpip/features/earthquake/domain/rts.dart';
import 'package:dpip/features/earthquake/domain/rts_alert_tracker.dart';
import 'package:dpip/features/earthquake/domain/rts_box_grid.dart';
import 'package:dpip/features/earthquake/domain/rts_live_demand.dart';
import 'package:dpip/features/earthquake/domain/rts_station_encoder.dart';
import 'package:dpip/features/earthquake/domain/rts_station_geojson.dart';
import 'package:dpip/features/earthquake/domain/seismic_station.dart';
import 'package:dpip/features/earthquake/domain/seismic_travel_time.dart';
import 'package:dpip/features/earthquake/domain/trem_station_repository.dart';
import 'package:dpip/features/map/presentation/widgets/rts_monitor_panel.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/color_hex.dart';
import 'package:dpip/shared/map/geo_circle.dart';
import 'package:dpip/shared/map/wavefront_cadence.dart';
import 'package:dpip/shared/map/map_layer.dart';
import 'package:dpip/shared/map/map_style.dart'
    show MapColors, countyFillLayerId, townFillLayerId;
import 'package:dpip/shared/map/monitor_map_stack.dart';
import 'package:dpip/shared/seismic/intensity_circle_renderer.dart';
import 'package:dpip/shared/seismic/intensity_colors.dart';
import 'package:dpip/shared/seismic/intensity_icon_renderer.dart';
import 'package:dpip/shared/widgets/intensity_legend.dart';
import 'package:dpip/shared/widgets/intensity_ranking_card.dart';
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
/// never a wavefront that hasn't started. A cancelled alert renders nothing at
/// all: its rings would show a wave the agency has just said is not coming.
Map<String, dynamic> eewWaveGeoJson(
  List<Eew> alerts,
  SeismicTravelTimeTable? table,
  DateTime now,
) {
  final features = <Map<String, dynamic>>[];
  for (final eew in alerts) {
    if (eew.isCancelled) continue;
    final info = eew.info;
    final elapsed = now.difference(
      DateTime.fromMillisecondsSinceEpoch(info.time, isUtc: true),
    );
    if (table != null && !elapsed.isNegative) {
      final radius = table.waveRadius(info.depth, elapsed);
      if (radius.p > 0) {
        addCircleFeatures(
          features,
          info.latlng,
          radius.p * 1000,
          lineProperties: const {'type': 'p-line'},
        );
      }
      if (radius.s > 0) {
        addCircleFeatures(
          features,
          info.latlng,
          radius.s * 1000,
          fillProperties: const {'type': 's-fill'},
          lineProperties: const {'type': 's-line'},
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

typedef _SWaveCover = ({double metres, geo.DistanceWithin reach});

/// A realtime [MapLayer]: subscribes to the live RTS feed and repaints the
/// station dots (coloured by raw intensity `i`) on every ~1 Hz snapshot, and to
/// the live EEW feed for the epicentre cross + P/S wave-front rings while an
/// alert is active (the same geometry the replay map draws). A large event's
/// detection boxes (see [_pushBox]) mirror the legacy monitor and the replay
/// page. Station dots stay circles always: while a large event's box grid is
/// up, a shaking station gets a circular discrete-reading badge (see
/// [MonitorLayerIds.stationBadge]/[IntensityCircleRenderer]) drawn over its
/// dot, but that badge is still a circle — the discrete-intensity *square* badges
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
    RtsLiveDemand? liveDemand,
    MlIntensityEstimator? mlIntensity,
    RtsStationEncoder? stationEncoder,
    Future<RenderTier>? renderTier,
    // Not initializing formals: Dart has no private *named* parameter, and
    // these fields must stay private.
    // ignore: prefer_initializing_formals
  }) : _eew = eew,
       // ignore: prefer_initializing_formals
       _travelTimeTable = travelTimeTable,
       // ignore: prefer_initializing_formals
       _boxGridFuture = boxGrid,
       // ignore: prefer_initializing_formals
       _liveDemand = liveDemand,
       // ignore: prefer_initializing_formals
       _mlIntensity = mlIntensity,
       // ignore: prefer_initializing_formals
       _stationEncoder = stationEncoder,
       // ignore: prefer_initializing_formals
       _townDirectory = townDirectory {
    // A low-end phone redraws the rings at a lower rate (see
    // [wavefrontTick]). Until the probe answers — and when no probe is
    // given — the rings run at full rate, never degraded on a guess.
    renderTier?.then((tier) {
      final tick = wavefrontTick(tier);
      if (tick == _eewTick) return;
      _eewTick = tick;
      _eewTicker?.cancel();
      _eewTicker = null;
      _syncEewTicker();
    });
  }

  final RealtimeNotifier<Rts> _feed;
  final TremStationRepository _stationRepository;
  final RealtimeNotifier<List<Eew>> _eew;
  final Future<SeismicTravelTimeTable> _travelTimeTable;
  final Future<RtsBoxGrid> _boxGridFuture;
  final TownDirectory _townDirectory;

  /// Held while the monitor is on screen, so the feed sends every frame
  /// rather than only the alerting ones (see [RtsLiveDemand]).
  final RtsLiveDemand? _liveDemand;
  bool _holdingLive = false;

  /// ML v1 township estimates; the formula colours the island until it loads.
  final MlIntensityEstimator? _mlIntensity;

  /// Builds the station layer off the UI isolate for the frames it decoded
  /// (see [_writeStations]); without one, or for any other frame, the layer
  /// builds it here.
  final RtsStationEncoder? _stationEncoder;

  /// Bumped by every station write and every remount, so a write still
  /// waiting on [_stationEncoder] when a newer one is made — or when the
  /// source is mounted afresh under it — is dropped instead of landing late
  /// with an older frame. Without the encoder every write reaches the map in
  /// call order on its own; with it, one write waits on the worker and the
  /// next may not (an offline feed's empty collection, a frame the worker
  /// does not hold), so the later one could otherwise land first.
  int _stationWrite = 0;

  /// Loads the model — downloading it the first time the monitor ever opens —
  /// and repaints the wash from it once it is ready.
  Future<void> _prepareModel() async {
    final model = _mlIntensity;
    if (model == null || model.ready) return;
    if (!await model.prepare()) return;
    final controller = _controller;
    if (controller == null || !_added) return;
    final live =
        _eew.state.status == RealtimeStatus.live &&
        (_eew.state.data?.isNotEmpty ?? false);
    if (live) await _updateAreaFill(controller, _eew.state.data!);
  }

  /// The boxes each frame lights and the minute-long township ranking — shared
  /// logic with the replay page, fed from [_feed] here.
  final RtsAlertTracker _alerts = RtsAlertTracker();

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

  /// Bumped on every feed notification, so the ranking card rebuilds with it.
  final ValueNotifier<int> _rankingTick = ValueNotifier(0);

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

  /// Signature of the box collection currently on the map (see [_pushBox]).
  ///
  /// The wavefront ticker calls [_pushBox] at display rate, but the grid it
  /// draws only changes when the feed's box set changes (~1 Hz) or a box is
  /// swept past by the S wave (once, ever, per box). Every other tick used to
  /// re-serialise the whole grid, ship it across the platform channel and make
  /// MapLibre re-tile it — sixty times a second, during an alert, on the
  /// device's worst minute. `null` means nothing is known to be there, so the
  /// next push always lands.
  String? _boxOnMap;

  /// Whether the EEW source on the map is currently the empty collection.
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
  /// geometry is a function of the calibrated clock, so every wavefront tick
  /// genuinely differs and must still be sent.
  bool _eewSourceEmpty = true;
  bool _stationsFetching = false;
  int _stationRetries = 0;

  /// Whether this activation has asked the server for the current directory.
  bool _stationsRefreshed = false;
  SeismicTravelTimeTable? _travelTime;
  Timer? _eewTicker;

  /// Radii last successfully written to the EEW source, keyed by alert id.
  final Map<String, WavefrontRing> _ringsOnMap = {};

  /// When the ticker last ran the S-wave box coverage test.
  DateTime? _lastBoxCoverage;

  /// Identity of the last payload pushed to the source: `null` when offline
  /// (empty collection was sent), else the feed's data object — skips the
  /// per-tick round trip when a status change re-notifies without new data.
  Object? _lastSent;

  /// Every source/layer/image id this overlay owns — `rts-src`, `rts-circle`,
  /// `rts-eew-epicenter` and the rest, derived from the `rts` prefix. The
  /// stack's shape and paint live in [addMonitorLayers], shared with the report
  /// replay map so a change to one surface can't silently skip the other.
  static const MonitorLayerIds _ids = rtsMonitorIds;

  /// Wave-front rings keep expanding between RTS polls. The ticker wakes at
  /// [wavefrontTick] — display rate on a capable phone, 5 Hz on a low-end
  /// one — but only while an alert is live ([_syncEewTicker]). Waking is not
  /// uploading: [wavefrontUploadDue] holds a step smaller than one screen
  /// pixel, and the upload that does happen draws the radius at that instant.
  Duration _eewTick = wavefrontTick(RenderTier.high);
  static const int _maxStationRetries = 8;
  static const double _liveOpacity = 1.0;
  static const double _staleOpacity = 0.35;

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
    // so a deliberate framing must leave room for the whole stack. A cancelled
    // alert still has its card up, so it counts here too.
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
    _holdLive(_surfaceVisible);
    unawaited(_prepareModel());
    await _ensureStations();
    // The frame already in hand, lit against whatever is placed so far —
    // the feed will not notify again just because the layer attached.
    _alerts.track(_feed.state);
    await removeMonitorLayers(controller, _ids);
    _stationWrite++;
    // The whole stack — sources, layers, badge icons, and the order they mount
    // in — is [addMonitorLayers], shared with the report replay map. The
    // stacking rules it enforces (everything appended above the base style's
    // township names, only the EEW S-wave disc anchored) are documented there,
    // once, so they cannot be changed on one surface and silently missed on
    // the other.
    await addMonitorLayers(
      controller,
      _ids,
      stationData: _geoJson(),
      dotOpacity: _liveOpacity,
      logTag: 'rts',
    );
    _added = true;
    _appliedStatus = null;
    // [addMonitorLayers] has just seeded the EEW source empty.
    _eewSourceEmpty = true;
    _ringsOnMap.clear();
    // The box source was just re-added empty above.
    _boxOnMap = null;
    await _pushUpdate();
    if (!_listening) {
      _feed.addListener(_onFeed);
      _listening = true;
    }
    if (!_eewListening) {
      _eew.addListener(_onEew);
      _eewListening = true;
    }
    _syncEewTicker();
    _setupBlink();
    _travelTimeTable.then((table) {
      _travelTime = table;
      unawaited(_pushEew());
    });
    _boxGridFuture.then((grid) {
      _boxGrid = grid;
      _alerts.place(grid: grid);
      // Placing the grid can light boxes the frame in hand already implied,
      // which also changes how the station dots are drawn (a lit event
      // declutters them) — so the whole update goes again, not just the box.
      _lastSent = null;
      unawaited(_pushUpdate());
    });
  }

  /// Takes or lets go of the feed's live speed. Only while the monitor is the
  /// active layer *and* its surface can be seen: a monitor behind another tab
  /// needs the alerting frames only, which the sleeping stream still sends.
  void _holdLive(bool hold) {
    final demand = _liveDemand;
    if (demand == null || hold == _holdingLive) return;
    _holdingLive = hold;
    hold ? demand.hold() : demand.release();
  }

  /// Runs the wavefront ticker exactly while it has something to draw: the
  /// layer on a visible map with an alert live. Before, it ran at display rate
  /// for as long as the layer was attached and its body returned at once
  /// while calm — sixty idle wakeups a second that kept a phone's CPU from
  /// ever settling. Every change to the alert set or its status arrives
  /// through [_onEew], which re-syncs this, and the clearing write when an
  /// alert leaves is [_onEew]'s own push, never the ticker's.
  void _syncEewTicker() {
    if (!_added || !_surfaceVisible || !_eewActive) {
      _eewTicker?.cancel();
      _eewTicker = null;
      return;
    }
    _eewTicker ??= Timer.periodic(_eewTick, (_) {
      if (!_eewActive) return;
      if (_eewTickInFlight && _eewTicksSkipped < _eewTickMaxSkips) {
        _eewTicksSkipped++;
        return;
      }
      final generation = ++_eewTickGeneration;
      _eewTickInFlight = true;
      _eewTicksSkipped = 0;
      final now = AppTime.utc;
      final coverBoxes = boxCoverageDue(_lastBoxCoverage, now);
      if (coverBoxes) _lastBoxCoverage = now;
      unawaited(
        Future.wait([
          _pushEew(),
          // A box's S-wave coverage grows between RTS polls, but the box is
          // kilometres across. [kBoxCoverageInterval] is the cadence that
          // still drops it as the wave passes; [_onFeed] does not wait.
          if (coverBoxes) _pushBox(),
        ]).whenComplete(() {
          // A write abandoned after [_eewTickMaxSkips] must not clear the flag
          // of the one that replaced it.
          if (generation == _eewTickGeneration) _eewTickInFlight = false;
        }),
      );
    });
  }

  /// Whether the last wavefront tick's writes are still on the platform
  /// channel.
  ///
  /// The ticker does not wait for a write to land, and the map plugin queues
  /// GeoJSON writes per source in call order without ever dropping a stale
  /// one. On a phone that needs longer than a tick to apply a ring set, every
  /// tick used to add another full set behind the last — each one older than
  /// the clock by the time the map drew it, and the backlog growing for as
  /// long as the alert lasted. Skipping the tick instead means the next write
  /// is computed from the clock when it is actually sent, so the newest ring
  /// is always the next one drawn. A phone that keeps up never sees a skip.
  bool _eewTickInFlight = false;

  /// Ticks skipped in a row behind the in-flight write.
  int _eewTicksSkipped = 0;

  /// Bumped per tick that writes, so a late completion is recognised as late.
  int _eewTickGeneration = 0;

  /// About a second of ticks: past this the in-flight write is treated as lost
  /// rather than slow. A platform call that never answers — a map torn down
  /// mid-write — would otherwise hold the flag forever and freeze the rings
  /// for the rest of an alert, which is far worse than the backlog the flag
  /// exists to prevent.
  int get _eewTickMaxSkips =>
      const Duration(seconds: 1).inMicroseconds ~/ _eewTick.inMicroseconds;

  void _onFeed() {
    _alerts.track(_feed.state);
    _rankingTick.value++;
    unawaited(_pushUpdate());
  }

  /// Whether an EEW still in progress is out on a live feed — which decides
  /// which stations the monitor draws (see [rtsStationMark]) and whether the
  /// wavefront ticker runs. A cancelled alert is not one: it has no wavefront.
  bool get _eewActive =>
      _eew.state.status == RealtimeStatus.live &&
      (_eew.state.data?.hasUncancelled ?? false);

  /// The [_eewActive] the station dots on the map were drawn for.
  bool _dotsDrawnForEew = false;

  void _onEew() {
    _syncEewTicker();
    // An alert arriving or leaving changes which stations are drawn, not just
    // the wavefront — the dots go again, and the update ends with the EEW.
    if (_eewActive != _dotsDrawnForEew) {
      _lastSent = null;
      unawaited(_pushUpdate());
    } else {
      unawaited(_pushEew());
    }
  }

  /// Whether the hosting surface can currently be seen. The feeds keep
  /// polling either way — they are safety feeds and the monitor panel's
  /// freshness depends on them — but re-uploading a full station GeoJSON at
  /// 1 Hz (and the EEW wavefront at display rate) to a map that sits behind another
  /// tab is a platform-channel serialisation nobody can see.
  bool _surfaceVisible = true;

  @override
  void onSurfaceVisibility(bool visible) {
    _surfaceVisible = visible;
    if (_controller != null) _holdLive(visible);
    if (visible) {
      // One catch-up on the visible edge: the skipped uploads left the map at
      // whatever second it was hidden on.
      _lastSent = null;
      _appliedStatus = null;
      if (_added) {
        _syncEewTicker();
        _setupBlink();
        unawaited(_pushUpdate());
      }
    } else {
      // The wavefront ticker stops outright — during a live alert in the
      // background it was sixty timer wakeups a second for uploads the gate
      // above was already discarding.
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
        await _writeStations(controller, offline: offline, frame: data);
      }
      if (status != _appliedStatus) {
        _appliedStatus = status;
        final opacity = status == RealtimeStatus.live
            ? _liveOpacity
            : _staleOpacity;
        await controller.setLayerProperties(
          _ids.stationDot,
          monitorDotProps(opacity: opacity),
        );
        await controller.setLayerProperties(
          _ids.stationLabel,
          monitorLabelProps(opacity: opacity),
        );
      }
    } catch (_) {
      // Source not on the map (mid style-reload); the next render re-adds it.
    }
    await _pushBox();
    await _pushEew();
  }

  /// Repaints the EEW overlay. An alert is only current while its feed is live;
  /// a stale/offline EEW feed's last snapshot must never be presented as an
  /// expanding wavefront, so anything not live renders nothing. Nor does a
  /// cancelled alert (see [eewWaveGeoJson]), so a set of only cancelled
  /// alerts clears the overlay the same way calm does.
  Future<void> _pushEew() async {
    final controller = _controller;
    if (controller == null || !_added || !_surfaceVisible) return;
    final listed =
        _eew.state.status == RealtimeStatus.live &&
        (_eew.state.data?.isNotEmpty ?? false);
    await _updateAreaFill(controller, listed ? _eew.state.data! : const []);
    final live = _eewActive;
    // Nothing to draw and nothing drawn — the overwhelmingly common case.
    if (!live && _eewSourceEmpty) return;
    final now = AppTime.utc;
    final alerts = live ? _eew.state.data! : const <Eew>[];
    final rings = _rings(alerts, now);
    if (live &&
        !wavefrontUploadDue(
          next: rings,
          onMap: _ringsOnMap,
          zoom: controller.cameraPosition?.zoom,
        )) {
      return;
    }
    try {
      await controller.setGeoJsonSource(
        _ids.eewSource,
        live
            ? eewWaveGeoJson(alerts, _travelTime, now)
            : monitorEmptyCollection,
      );
      _eewSourceEmpty = !live;
      if (live) {
        _ringsOnMap
          ..clear()
          ..addEntries(rings.map((ring) => MapEntry(ring.id, ring)));
      } else {
        _ringsOnMap.clear();
      }
    } catch (_) {
      // Source not on the map (mid style-reload); the next render re-adds it.
      // The flag is left alone: the write never landed, so whatever was on the
      // map before still is.
    }
  }

  /// P and S radii at [now], in metres. The same instant [eewWaveGeoJson]
  /// uses, so a due upload draws these numbers and not an older sample.
  List<WavefrontRing> _rings(List<Eew> alerts, DateTime now) {
    final table = _travelTime;
    final rings = <WavefrontRing>[];
    for (final eew in alerts) {
      // [eewWaveGeoJson] draws nothing for a cancelled alert, so its radius
      // must not keep the upload gate awake.
      if (eew.isCancelled) continue;
      final info = eew.info;
      var p = 0.0;
      var s = 0.0;
      if (table != null) {
        final elapsed = now.difference(
          DateTime.fromMillisecondsSinceEpoch(info.time, isUtc: true),
        );
        if (!elapsed.isNegative) {
          final radius = table.waveRadius(info.depth, elapsed);
          p = radius.p * 1000;
          s = radius.s * 1000;
        }
      }
      rings.add(
        WavefrontRing(
          id: '${eew.id}:${eew.serial}',
          pMetres: p,
          sMetres: s,
          latitude: info.latitude,
        ),
      );
    }
    return rings;
  }

  /// Updates the box-grid overlay: a frame with alerting stations lights the
  /// boxes they stand in (see [RtsAlertTracker]) and draws those coloured grid
  /// cells *alongside* the per-station dots (not a replacement) — the box only
  /// covers the areas the event actually triggered, so stations outside it
  /// still carry live detail.
  Future<void> _pushBox() async {
    final controller = _controller;
    final grid = _boxGrid;
    if (controller == null || !_added || !_surfaceVisible || grid == null) {
      return;
    }
    final hasBox = _alerts.alerting;
    try {
      if (hasBox) {
        final (boxes, signature) = _survivingBoxes(grid);
        if (signature != _boxOnMap) {
          // Claimed before the await, not after: the wavefront ticker calls
          // this on the coverage cadence, and a tick landing while the write
          // was in flight used to upload the same collection again. Two writes land
          // on the platform channel in call order, so the later call's set is
          // the one the source ends up holding — and it is the one recorded.
          _boxOnMap = signature;
          try {
            await controller.setGeoJsonSource(
              _ids.boxSource,
              _boxCollection(boxes),
            );
          } catch (_) {
            // The write never landed, so nothing is known to be there.
            _boxOnMap = null;
            rethrow;
          }
        }
      }
      if (hasBox != _boxVisible) {
        _boxVisible = hasBox;
        await controller.setLayerVisibility(_ids.boxLine, hasBox);
      }
    } catch (_) {
      // Source/layer not on the map yet (mid style-reload) — the next update retries.
    }
  }

  /// One polygon per box the latest frame lights, joined
  /// against the static [grid] for its geometry — dropping any box the
  /// S-wave has already fully swept past (see [_isBoxFullyCovered]) so it
  /// stops blinking instead of blinking forever once it's no longer live
  /// information.
  ///
  /// Returned with their signature — the surviving ids with their
  /// intensities, in order — which is everything the geometry depends on,
  /// since a ring is a function of its id alone. [_pushBox] compares it
  /// against what the map already holds.
  (List<(int, List<List<double>>)>, String) _survivingBoxes(RtsBoxGrid grid) {
    final box = _alerts.areas.boxes;
    // A cancelled alert's wave sweeps nothing: its boxes stay live readings.
    final alerts = (_eew.state.data ?? const <Eew>[]).uncancelled;
    final now = AppTime.utc;
    final covers = _travelTime == null
        ? const <_SWaveCover>[]
        : _sWaveCovers(alerts, _travelTime!, now);
    final surviving = <(int, List<List<double>>)>[];
    final signature = StringBuffer();
    for (final entry in box.entries) {
      final ring = grid.rings[entry.key];
      if (ring == null) continue;
      if (_isBoxFullyCovered(ring, covers)) continue;
      signature
        ..write(entry.key)
        ..write(':')
        ..write(entry.value)
        ..write(',');
      surviving.add((entry.value, ring));
    }
    return (surviving, signature.toString());
  }

  /// The collection for the boxes [_survivingBoxes] kept — built only when
  /// their signature differs from what the map holds, which during an alert is
  /// a handful of times against sixty checks a second.
  static Map<String, dynamic> _boxCollection(
    List<(int, List<List<double>>)> boxes,
  ) => {
    'type': 'FeatureCollection',
    'features': [
      for (final (level, ring) in boxes)
        {
          'type': 'Feature',
          'geometry': {
            'type': 'Polygon',
            'coordinates': [ring],
          },
          'properties': {'i': level},
        },
    ],
  };

  /// Metres per degree of latitude on the sphere [geo.LatLng.distanceTo]
  /// measures on — the great-circle distance between two points is never less
  /// than their meridional separation, so a corner whose latitude alone puts
  /// it past the radius is outside it without the trig.
  static const double _metresPerLatDegree = 6378137 * math.pi / 180;

  /// One active alert's S-wave disc. Built once per tick and shared by every
  /// box: the radius does not depend on the box, and the haversine test
  /// ([geo.DistanceWithin]) keeps the epicentre's cosine instead of
  /// reallocating a coordinate per corner.
  List<_SWaveCover> _sWaveCovers(
    List<Eew> alerts,
    SeismicTravelTimeTable table,
    DateTime now,
  ) {
    final covers = <_SWaveCover>[];
    for (final eew in alerts) {
      final info = eew.info;
      final elapsed = now.difference(
        DateTime.fromMillisecondsSinceEpoch(info.time, isUtc: true),
      );
      if (elapsed.isNegative) continue;
      final radiusKm = table.waveRadius(info.depth, elapsed).s;
      if (radiusKm <= 0) continue;
      final metres = radiusKm * 1000;
      covers.add((
        metres: metres,
        reach: geo.DistanceWithin(info.latlng, metres),
      ));
    }
    return covers;
  }

  /// Whether every corner of [ring] is already within some active alert's
  /// S-wave radius — ported from the legacy monitor's `checkBoxSkip`, which
  /// dropped a detection box from the map (not just its blink) the instant
  /// the wavefront had fully swept past it, since by then it's a stale
  /// reading rather than live shaking data.
  bool _isBoxFullyCovered(List<List<double>> ring, List<_SWaveCover> covers) {
    // The first four points are the box's corners (the fifth closes the ring).
    // An index loop rather than `take(4).every(…)`: the same short-circuit,
    // without an iterable and a closure per box per alert per frame.
    final corners = ring.length < 4 ? ring.length : 4;
    for (final cover in covers) {
      var allCornersCovered = true;
      for (var k = 0; k < corners; k++) {
        final point = ring[k];
        final lat = point[1];
        // Exact reject: meridional distance is a lower bound on the geodesic.
        if ((lat - cover.reach.latitude).abs() * _metresPerLatDegree >
                cover.metres ||
            !cover.reach.contains(lat, point[0])) {
          allCornersCovered = false;
          break;
        }
      }
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
        final hasBox = _alerts.alerting;
        if (hasBox) {
          _boxVisible = !_boxVisible;
          await controller.setLayerVisibility(_ids.boxLine, _boxVisible);
        } else if (_boxVisible) {
          _boxVisible = false;
          await controller.setLayerVisibility(_ids.boxLine, false);
        }

        if (_eewActive) {
          _epicenterVisible = !_epicenterVisible;
          await controller.setLayerVisibility(
            _ids.eewEpicenter,
            _epicenterVisible,
          );
        } else if (!_epicenterVisible) {
          _epicenterVisible = true;
          await controller.setLayerVisibility(_ids.eewEpicenter, true);
        }
      } catch (_) {
        // Layers gone mid style-reload — the next blink retries.
      }
    });
  }

  /// Tints the whole island by estimated shaking while [alerts] is non-empty
  /// — the legacy monitor's county/town fill behaviour, from the same
  /// township levels the replay page uses ([eewTownLevels]: ML v1 once it is
  /// loaded, the attenuation formula until then). The base style's own
  /// `town` fill layer is recoloured with a `match` on each township's
  /// `CODE`, so the felt-intensity wash reads over the base map without a
  /// second geometry source; when the alerts clear the wash is cleared. The
  /// county fill underneath stays the opaque grey island throughout — the
  /// wash is transparent wherever the estimate reads 0, and something has to
  /// be opaque over Taiwan there.
  ///
  /// With two simultaneous quakes this must use whichever alert [eewIndex]
  /// currently selects (the same one the monitor card is showing), not just
  /// the newest — the ground tint and the card are one choice, not two.
  /// A cancelled selection clears the wash, the same as no alert.
  /// Recomputed only when *that* alert's id/serial changes — cheap to check,
  /// but the 368-town estimate + platform write isn't, so a repeat is
  /// skipped. Keying on the selected alert alone (not the whole set) means
  /// tapping to cycle, with the set otherwise unchanged, still invalidates
  /// the cache.
  Future<void> _updateAreaFill(
    MapLibreMapController controller,
    List<Eew> alerts,
  ) async {
    final shown = alerts.isEmpty
        ? null
        : alerts[eewIndex.value % alerts.length];
    // The card is showing a cancelled alert: there is no shaking to tint.
    final selected = shown == null || shown.isCancelled ? null : shown;
    final model = _mlIntensity;
    // The model arriving mid-alert repaints the same serial from its levels.
    final key = selected == null
        ? null
        : '${selected.id}:${selected.serial}:${model?.ready ?? false}';
    if (key == _fillEewKey) return;
    _fillEewKey = key;
    if (selected != null && !(model?.ready ?? true)) {
      unawaited(_prepareModel());
    }

    final baseFill = MapColors.of(_dark ? Brightness.dark : Brightness.light)
        .fill;
    try {
      // The opaque grey island is this layer's job in *every* state, alert or
      // not, so it is restored before the branch rather than hidden under the
      // wash. Hiding it during an alert left nothing opaque over Taiwan
      // wherever the estimate reads 0 — the wash falls back to transparent
      // there — and the EEW S-wave disc, anchored below [landLayerId] so it
      // washes open sea only, came through the island instead.
      await controller.setLayerProperties(
        countyFillLayerId,
        FillLayerProperties(fillColor: baseFill, fillOpacity: 1),
      );
      if (selected == null) {
        // Back to the baked default. This layer is the wash and nothing else:
        // with no alert up it paints nothing, so the OSM detailed ground —
        // which mounts directly beneath it — keeps showing. The grey island is
        // [countyFillLayerId]'s job, restored just above.
        await controller.setLayerProperties(
          townFillLayerId,
          const FillLayerProperties(fillColor: '#00000000', fillOpacity: 0),
        );
        return;
      }

      final estimate = await eewTownLevels(
        selected.info,
        model: model,
        centroids: _centroids ??= {
          for (final town in _townDirectory.all)
            town.code: geo.LatLng(town.lat, town.lng),
        },
      );
      // A newer alert, serial or the model itself took over while this one
      // was being scored — its own update paints, not this stale one.
      if (key != _fillEewKey) return;
      final entries = <Object>[];
      estimate.levels.forEach((code, level) {
        if (level > 0) {
          entries.add(int.parse(code));
          entries.add(IntensityColors.discrete(level).toHexRgb());
        }
      });
      if (entries.isEmpty) return;

      await controller.setLayerProperties(
        townFillLayerId,
        FillLayerProperties(
          fillColor: <Object>[
            'match',
            ['get', 'CODE'],
            ...entries,
            // Transparent, not the palette grey: a township the estimate puts
            // at 0 has to leave whatever is under it showing — the OSM
            // detailed ground when that layer is on, the county fill's grey
            // when it is not. Falling back to grey painted a flat sheet over
            // the detailed map everywhere the shaking was 0.
            'rgba(0, 0, 0, 0)',
          ],
          fillOpacity: 1,
        ),
      );
    } catch (_) {
      // Layers gone mid style-reload — the next update re-applies.
    }
  }

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

  /// The 震度排行 under the legend — each township's peak over the last
  /// minute (TREM-Lite's bottom-right list), rebuilt with the feed.
  @override
  Widget buildLegendAccessory(BuildContext context) =>
      ValueListenableBuilder<int>(
        valueListenable: _rankingTick,
        builder: (context, _, _) => IntensityRankingCard(
          entries: [
            for (final row in _alerts.ranking(_townDirectory.byCode))
              (name: row.name, level: row.level),
          ],
        ),
      );

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
    _holdLive(false);
    // The next activation asks the server again — "once each time the monitor
    // opens".
    _stationsRefreshed = false;
    _stationRetries = 0;
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
    _stationWrite++;
    // The area fill tints the *base style's* county/town layers, not one of
    // this layer's own — leaving it tinted would bleed into whichever layer
    // becomes active next. [_updateAreaFill] no-ops if nothing was applied.
    await _updateAreaFill(controller, const []);
    await removeMonitorLayers(controller, _ids);
    _controller = null;
  }

  @override
  void onStyleReset() {
    _added = false;
    _boxOnMap = null;
    // The style reload wipes the base style's county/town fill back to
    // default — this cache would otherwise think a still-active alert's
    // tint is already applied and skip re-painting it.
    _fillEewKey = null;
  }

  /// Places the stations: the copy saved on this device at once, then — once
  /// per activation — the server's current list, revalidated with its ETag.
  ///
  /// The saved copy is what lets the monitor draw the moment it opens, and on
  /// a connection too poor to fetch anything; the refresh is retried (bounded)
  /// only while there is nothing at all to draw, since a directory in hand is
  /// already a working monitor.
  Future<void> _ensureStations() async {
    if (_stationsFetching) return;
    if (_stations.isEmpty) {
      final saved = await _stationRepository.saved();
      if (saved != null && _stations.isEmpty) _useStations(saved);
    }
    if (_stationsRefreshed || _stationRetries >= _maxStationRetries) return;
    _stationsFetching = true;
    _stationRetries++;
    try {
      final directory = (await _stationRepository.refresh()).valueOrNull;
      if (directory != null && directory.isNotEmpty) {
        _useStations(directory);
        _stationsRefreshed = true;
        _stationRetries = 0;
      } else if (_stations.isNotEmpty) {
        // The saved copy stands; asking again every frame buys nothing.
        _stationsRefreshed = true;
      }
    } finally {
      _stationsFetching = false;
    }
  }

  void _useStations(Map<String, SeismicStation> directory) {
    _stations = directory;
    _alerts.place(stations: directory);
    _stationEncoder?.placeStations(directory);
    // The dots on the map were placed against the old directory.
    _lastSent = null;
  }

  /// Puts the station layer on the map: nothing while [offline], else
  /// [frame]'s stations.
  ///
  /// When [_stationEncoder] holds the frame, the layer is built and encoded
  /// on the worker and handed to MapLibre as the string, so the UI isolate
  /// neither walks the stations nor encodes them. Otherwise it is built here,
  /// as it always was. The flags, icons and directory are this moment's,
  /// taken before the wait, so both ways draw the same frame the same way.
  Future<void> _writeStations(
    MapLibreMapController controller, {
    required bool offline,
    required Rts? frame,
  }) async {
    final write = ++_stationWrite;
    if (offline) {
      await controller.setGeoJsonSource(
        _ids.stationSource,
        monitorEmptyCollection,
      );
      return;
    }
    final eventLit = _alerts.alerting;
    final eewActive = _eewActive;
    final badgeIcons = _badgeIcons;
    final stations = _stations;
    _dotsDrawnForEew = eewActive;
    final encoder = _stationEncoder;
    if (encoder != null && frame != null) {
      final encoded = await encoder.encode(
        frame,
        eventLit: eventLit,
        eewActive: eewActive,
        badgeIcons: badgeIcons,
      );
      if (write != _stationWrite) return;
      if (encoded != null) {
        await controller.setGeoJsonSourceEncoded(_ids.stationSource, encoded);
        return;
      }
    }
    await controller.setGeoJsonSource(
      _ids.stationSource,
      rtsStationGeoJson(
        frame?.stations ?? const <String, RtsStation>{},
        stations,
        eventLit: eventLit,
        eewActive: eewActive,
        badgeIcons: badgeIcons,
      ),
    );
  }

  /// The station layer for the frame in hand, built here — what [render]
  /// mounts the source with.
  Map<String, dynamic> _geoJson() {
    final eventLit = _alerts.alerting;
    final eewActive = _eewActive;
    _dotsDrawnForEew = eewActive;
    return rtsStationGeoJson(
      _feed.state.data?.stations ?? const <String, RtsStation>{},
      _stations,
      eventLit: eventLit,
      eewActive: eewActive,
      badgeIcons: _badgeIcons,
    );
  }

  /// The badge icon id for each level 0–9, in the artwork for the brightness
  /// last seen (see [_captureBrightness]).
  List<String> get _badgeIcons => _dark ? _darkBadgeIcons : _lightBadgeIcons;

  static final List<String> _lightBadgeIcons = List.unmodifiable([
    for (var level = 0; level < 10; level++)
      monitorBadgeIcon(level, dark: false),
  ]);
  static final List<String> _darkBadgeIcons = List.unmodifiable([
    for (var level = 0; level < 10; level++)
      monitorBadgeIcon(level, dark: true),
  ]);
}
