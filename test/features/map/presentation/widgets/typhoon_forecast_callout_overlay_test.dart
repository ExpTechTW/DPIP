/// Forecast cards are drawn in Flutter, not by the map, so a pan has to hide
/// them immediately and a zoomed-out basin has to thin them — stacked cards
/// would cover the track they are labelling.
library;

import 'dart:math' as math;

import 'package:dpip/core/error/result.dart';
import 'package:dpip/features/map/presentation/layers/typhoon_layer.dart';
import 'package:dpip/features/map/presentation/widgets/typhoon_forecast_callouts.dart';
import 'package:dpip/features/typhoon/domain/meteor_typhoon_repository.dart';
import 'package:dpip/features/typhoon/domain/typhoon_cyclone.dart';
import 'package:dpip/features/typhoon/domain/typhoon_kind.dart';
import 'package:dpip/features/typhoon/domain/typhoon_potential.dart';
import 'package:dpip/features/typhoon/domain/typhoon_probability.dart';
import 'package:dpip/features/typhoon/domain/typhoon_track.dart';
import 'package:dpip/features/typhoon/domain/typhoon_warning.dart';
import 'package:dpip/features/weather/domain/radar_repository.dart';
import 'package:dpip/features/weather/domain/satellite_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../raster_timeline_harness.dart';

class _Map extends RecordingMapController {
  _Map()
    : super(camera: const CameraPosition(target: LatLng(23, 121), zoom: 8));

  final List<VoidCallback> listeners = [];
  bool moving = false;
  bool throwProject = false;

  @override
  bool get isCameraMoving => moving;

  @override
  void addListener(VoidCallback listener) => listeners.add(listener);

  @override
  void removeListener(VoidCallback listener) => listeners.remove(listener);

  void poke() {
    for (final listener in List<VoidCallback>.of(listeners)) {
      listener();
    }
  }

  @override
  Future<List<math.Point<num>>> toScreenLocationBatch(
    Iterable<LatLng> coords,
  ) async {
    if (throwProject) throw StateError('project');
    // Cluster the first points so the placer has to nudge overlapping cards.
    return [
      for (final coord in coords)
        math.Point<num>(120 + coord.longitude / 10, 180 + coord.latitude),
    ];
  }
}

TrackForecast _fix(int tau, {double lat = 23, double lon = 121}) =>
    TrackForecast(
      tau: tau,
      time: 1700000000 + tau * 3600,
      latitude: lat,
      longitude: lon,
      wind: 30,
      pressure: 970,
      speed: 15,
      direction: 'N',
      r15: 150,
    );

class _Repo implements MeteorTyphoonRepository {
  _Repo(this.tracks);

  final List<TyphoonTrack> tracks;

  @override
  Future<Result<CycloneIndex>> cyclones() async => Ok(
    CycloneIndex(
      updated: 1,
      cyclones: [
        for (final track in tracks)
          TyphoonCyclone(
            name: track.name,
            cwaName: track.cwaName,
            year: track.year,
            tdNo: track.tdNo,
            tyNo: track.tyNo,
            time: 1700000000,
            latitude: track.analysis.last.latitude,
            longitude: track.analysis.last.longitude,
          ),
      ],
    ),
  );

  @override
  Future<Result<TrackPayload>> track() async =>
      Ok(TrackPayload(updated: 1700000000, cyclones: tracks));

  @override
  Future<Result<PotentialPayload>> potential() async =>
      const Ok(PotentialPayload(updated: 1, cyclones: []));

  @override
  Future<Result<TyphoonProbability>> probability() async =>
      const Ok(TyphoonProbability(updated: 1, cyclones: []));

  @override
  Future<Result<WarningPayload>> warning() async =>
      const Ok(WarningPayload(updated: 1, cyclones: []));

  @override
  Future<Result<List<int>>> history(TyphoonKind kind) async => const Ok([]);

  @override
  Future<Result<TrackPayload>> trackAt(int second) async =>
      const Ok(TrackPayload(updated: 0, cyclones: []));

  @override
  Future<Result<PotentialPayload>> potentialAt(int second) async =>
      const Ok(PotentialPayload(updated: 0, cyclones: []));

  @override
  Future<Result<TyphoonProbability>> probabilityAt(int second) async =>
      const Ok(TyphoonProbability(updated: 0, cyclones: []));

  @override
  Future<Result<WarningPayload>> warningAt(int second) async =>
      const Ok(WarningPayload(updated: 0, cyclones: []));
}

class _Radar extends FakeRasterFrameSource implements RadarRepository {
  _Radar() : super(const []);

  @override
  String tileUrl(String frame) => 'https://example.invalid/{z}/{x}/{y}';
}

class _Sat extends FakeRasterFrameSource implements SatelliteRepository {
  _Sat() : super(const []);

  @override
  String tileUrl(String frame) => 'https://example.invalid/{z}/{x}/{y}';

  @override
  void setStyle(String? style) {}
}

TyphoonTrack _storm(String name, String td) => TyphoonTrack(
  name: name,
  year: 2026,
  tdNo: td,
  analysis: const [TrackFix(time: 1700000000, latitude: 23, longitude: 121)],
  forecast: [
    _fix(12, lat: 23.0, lon: 121.0),
    _fix(24, lat: 23.05, lon: 121.05),
    _fix(36, lat: 25, lon: 123),
  ],
);

Widget _app(Widget home) => MaterialApp(home: Scaffold(body: home));

void main() {
  test('stride thins cards as the basin zooms out', () {
    expect(forecastCalloutStride(8), 1);
    expect(forecastCalloutStride(6), 2);
    expect(forecastCalloutStride(5), 3);
    expect(forecastCalloutStride(4.2), 4);
    expect(forecastCalloutStride(3), 4);
  });

  testWidgets('cards show, hide while the camera moves, and recover', (
    tester,
  ) async {
    final map = _Map();
    final layer = TyphoonMapLayer(
      _Repo([_storm('HAISHEN', '1'), _storm('KONG-REY', '2')]),
      radar: _Radar(),
      satellite: _Sat(),
    );
    await layer.render(map);

    await tester.pumpWidget(_app(TyphoonForecastCalloutOverlay(layer: layer)));
    await tester.pump();
    await tester.pump();
    expect(find.textContaining('預測'), findsWidgets);

    await tester.pumpWidget(_app(TyphoonForecastCalloutOverlay(layer: layer)));
    await tester.pump();
    await tester.pump();
    expect(find.textContaining('預測'), findsWidgets);

    map.moving = true;
    map.poke();
    await tester.pump();
    expect(find.textContaining('預測'), findsNothing);

    map.moving = false;
    layer.onMapGestureStart();
    await tester.pump();
    layer.onMapGestureEnd();
    await tester.pump();
    await tester.pump();
    expect(find.textContaining('預測'), findsWidgets);

    layer.showForecastCallouts.value = false;
    await tester.pump();
    expect(find.textContaining('預測'), findsNothing);

    map.reportCamera(zoom: 3);
    layer.showForecastCallouts.value = true;
    await tester.pump();
    await tester.pump();
    expect(find.textContaining('預測'), findsNothing);

    map.reportCamera(zoom: 8);
    map.throwProject = true;
    layer.tapped.value = '+12h';
    await tester.pump();
    await tester.pump();
    expect(find.textContaining('預測'), findsNothing);

    map.throwProject = false;
    layer.track.value = const TrackPayload(
      updated: 2,
      cyclones: [
        TyphoonTrack(
          name: 'HAISHEN',
          year: 2026,
          tdNo: '1',
          analysis: [TrackFix(time: 1, latitude: 23, longitude: 121)],
          forecast: [],
        ),
      ],
    );
    await tester.pump();
    await tester.pump();
    expect(find.textContaining('預測'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
