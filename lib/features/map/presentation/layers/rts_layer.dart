/// The 強震監視器 (real-time seismic monitor) map layer — every reporting station
/// as a dot coloured by its live shaking intensity, refreshed from the RTS feed,
/// plus live EEW (epicentre cross + P/S wave-front circles) while an alert is up.
library;

import 'dart:async';

import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/realtime/app_time.dart';
import 'package:dpip/core/realtime/realtime_notifier.dart';
import 'package:dpip/core/realtime/realtime_state.dart';
import 'package:dpip/features/earthquake/domain/eew.dart';
import 'package:dpip/features/earthquake/domain/rts.dart';
import 'package:dpip/features/earthquake/domain/seismic_station.dart';
import 'package:dpip/features/earthquake/domain/seismic_travel_time.dart';
import 'package:dpip/features/earthquake/domain/trem_station_repository.dart';
import 'package:dpip/features/map/presentation/widgets/rts_monitor_panel.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/map/geo_circle.dart';
import 'package:dpip/shared/map/map_layer.dart';
import 'package:dpip/shared/map/map_station_labels.dart';
import 'package:dpip/shared/map/map_style.dart'
    show landLayerId, townLabelLayerId;
import 'package:dpip/shared/seismic/intensity_colors.dart';
import 'package:dpip/shared/widgets/intensity_legend.dart';
import 'package:dpip/shared/widgets/map_color_legend.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
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
/// alert is active (the same geometry the replay map draws). Not tap- or
/// timeline-driven; its "sheet" is a compact monitor panel showing the feed's
/// freshness and the active EEW cards, and [buildLegend] shows the intensity
/// scale.
class RtsMapLayer with MapLayerDefaults implements MapLayer {
  RtsMapLayer(
    this._feed,
    this._stationRepository, {
    required RealtimeNotifier<List<Eew>> eew,
    required Future<SeismicTravelTimeTable> travelTimeTable,
    // Not initializing formals: Dart has no private *named* parameter, and
    // these fields must stay private.
    // ignore: prefer_initializing_formals
  }) : _eew = eew,
       // ignore: prefer_initializing_formals
       _travelTimeTable = travelTimeTable;

  final RealtimeNotifier<Rts> _feed;
  final TremStationRepository _stationRepository;
  final RealtimeNotifier<List<Eew>> _eew;
  final Future<SeismicTravelTimeTable> _travelTimeTable;

  Map<String, SeismicStation> _stations = const {};
  MapLibreMapController? _controller;
  bool _listening = false;
  bool _eewListening = false;
  bool _added = false;
  RealtimeStatus? _appliedStatus;
  bool _stationsFetching = false;
  int _stationRetries = 0;
  SeismicTravelTimeTable? _travelTime;
  Timer? _eewTicker;

  static const String _sourceId = 'rts-src';
  static const String _circleId = 'rts-circle';
  static const String _labelId = 'rts-label';
  static const String _eewSourceId = 'rts-eew-src';
  static const String _eewPWaveId = 'rts-eew-p';
  static const String _eewSWaveId = 'rts-eew-s';
  static const String _eewSWaveFillId = 'rts-eew-s-fill';
  static const String _eewEpicenterId = 'rts-eew-epicenter';
  static const String _eewCrossIcon = 'rts-eew-cross';

  /// Wave-front rings keep expanding between RTS polls (a realtime channel only
  /// emits on a real transition) — a fixed cadence redraws them against the
  /// calibrated clock so the circles grow every frame regardless.
  static const Duration _eewTick = Duration(milliseconds: 200);
  static const int _maxStationRetries = 8;
  static const double _liveOpacity = 1.0;
  static const double _staleOpacity = 0.35;

  /// A neutral hairline separating overlapping dots — legacy uses the theme's
  /// outlineVariant, but render() has no BuildContext, so a mid-grey that reads
  /// on both light and dark tiles stands in.
  static const String _strokeColor = '#9E9E9E';
  static const Map<String, dynamic> _emptyCollection = {
    'type': 'FeatureCollection',
    'features': <dynamic>[],
  };

  @override
  String get id => 'monitor';

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
    await _setupEew(controller);
    _added = true;
    _appliedStatus = null;
    await _pushUpdate();
    if (!_listening) {
      _feed.addListener(_onFeed);
      _listening = true;
    }
    if (!_eewListening) {
      _eew.addListener(_onEew);
      _eewListening = true;
    }
    _eewTicker?.cancel();
    _eewTicker = Timer.periodic(_eewTick, (_) {
      // Only repaint while an alert is actually up — a calm feed needs no
      // platform churn, and the `_onEew` listener already clears the source
      // the moment an alert leaves.
      final live =
          _eew.state.status == RealtimeStatus.live &&
          (_eew.state.data?.isNotEmpty ?? false);
      if (live) unawaited(_pushEew());
    });
    _travelTimeTable.then((table) {
      _travelTime = table;
      unawaited(_pushEew());
    });
  }

  void _onFeed() => unawaited(_pushUpdate());

  void _onEew() => unawaited(_pushEew());

  Future<void> _pushUpdate() async {
    final controller = _controller;
    if (controller == null || !_added) return;
    if (_stations.isEmpty) await _ensureStations();
    final status = _feed.state.status;
    // Never present aged shaking as current: hide the dots when the feed is
    // offline, and dim them while stale (the monitor panel flags the status too).
    final offline = status == RealtimeStatus.offline;
    try {
      await controller.setGeoJsonSource(
        _sourceId,
        offline ? _emptyCollection : _geoJson(),
      );
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
    await _pushEew();
  }

  /// Repaints the EEW overlay. An alert is only current while its feed is live;
  /// a stale/offline EEW feed's last snapshot must never be presented as an
  /// expanding wavefront, so anything not live renders nothing.
  Future<void> _pushEew() async {
    final controller = _controller;
    if (controller == null || !_added) return;
    final live =
        _eew.state.status == RealtimeStatus.live &&
        (_eew.state.data?.isNotEmpty ?? false);
    try {
      await controller.setGeoJsonSource(
        _eewSourceId,
        live ? _eewGeoJson() : _emptyCollection,
      );
    } catch (_) {
      // Source not on the map (mid style-reload); the next render re-adds it.
    }
  }

  Map<String, dynamic> _eewGeoJson() =>
      eewWaveGeoJson(_eew.state.data ?? const [], _travelTime, AppTime.utc);

  /// Adds the EEW source + layers: the S wave's translucent disc ("inner
  /// circle") — the damaging, already-shaking zone — anchored below the land
  /// layer so the wash only shows over open sea, never over Taiwan itself. The
  /// P wave is a heads-up leading edge only, no fill; the epicentre cross sits
  /// on top. Isolated in its own try/catch so a failure here can never take
  /// down the station dots set up above.
  Future<void> _setupEew(MapLibreMapController controller) async {
    try {
      final data = await rootBundle.load('assets/map/icons/cross.png');
      await controller.addImage(_eewCrossIcon, data.buffer.asUint8List());
      await controller.addSource(
        _eewSourceId,
        GeojsonSourceProperties(data: _emptyCollection),
      );
      await controller.addFillLayer(
        _eewSourceId,
        _eewSWaveFillId,
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
        _eewPWaveId,
        const LineLayerProperties(lineColor: '#00E5FF', lineWidth: 2),
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
        const LineLayerProperties(lineColor: '#FF3B30', lineWidth: 2),
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

  /// The full circle style at [opacity] — passed whole (not a partial update),
  /// since setLayerProperties resets any property left null. Colour comes from
  /// the shared instrumental-intensity palette, so the dots and the legend can
  /// never drift.
  CircleLayerProperties _circleProps(double opacity) => CircleLayerProperties(
    circleColor: InstrumentalIntensityColors.mapLibreInterpolate,
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
  Widget buildSheet(BuildContext context) =>
      RtsMonitorPanel(feed: _feed, eew: _eew);

  @override
  Widget buildLegend(BuildContext context) => const MapLegendCard(
    child: IntensityLegend(mode: IntensityLegendMode.rts),
  );

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
    await _removeFromMap(controller);
    _controller = null;
  }

  @override
  void onStyleReset() => _added = false;

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
    final features = <Map<String, dynamic>>[];
    for (final entry in live.entries) {
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

  Future<void> _removeFromMap(MapLibreMapController controller) async {
    // Layers before their sources; tolerate any not currently on the map.
    for (final layerId in [
      _circleId,
      _labelId,
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
    for (final sourceId in [_sourceId, _eewSourceId]) {
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

  /// Higher instrumental intensity draws on top; stations without an `i` sink.
  static const List<Object> _sortKey = [
    'coalesce',
    ['get', 'i'],
    -5,
  ];

  /// Labels place strongest-first: a symbol's *lower* sort key wins a collision,
  /// so negate the intensity — a hot station's reading never loses to a calm one.
  static const List<Object> _labelSortKey = [
    '-',
    0,
    [
      'coalesce',
      ['get', 'i'],
      -5,
    ],
  ];
}
