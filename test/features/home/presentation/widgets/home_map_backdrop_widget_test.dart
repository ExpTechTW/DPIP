/// The home map backdrop frames the selected township and lays radar under
/// the admin outlines. Those steps are a queue of platform calls, so a test
/// has to drive a fake map through style load, a late boundary future, and a
/// second refresh of the same frame.
library;

import 'dart:async';

import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/geo/location_service.dart';
import 'package:dpip/core/geo/location_status.dart';
import 'package:dpip/core/geo/town_boundaries.dart';
import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/core/settings/region_store.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:dpip/features/home/presentation/home_reset_signal.dart';
import 'package:dpip/features/home/presentation/widgets/home_map_backdrop.dart';
import 'package:dpip/features/weather/domain/radar_repository.dart';
import 'package:dpip/shared/map/map_camera_handoff.dart';
import 'package:dpip/shared/map/raster_frame_source.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _Platform platform;

  setUp(() {
    platform = _Platform();
    final previous = MapLibrePlatform.createInstance;
    MapLibrePlatform.createInstance = () => platform;
    addTearDown(() => MapLibrePlatform.createInstance = previous);
  });

  testWidgets('style load frames a township and refreshes radar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final boundaries = Completer<TownBoundaries>();
    final radar = _Radar();
    final store = RegionStore(SettingsStore.inMemory());
    store.addSaved('6300100');
    store.addSaved('1000200');
    store.select(2);
    final reset = HomeResetSignal();
    final handoff = MapCameraHandoff();
    final location = LocationService(
      const TownDirectory({}),
      isAvailable: () async => false,
      fix: () async => null,
      lastKnown: () async => null,
      status: () async => LocationStatus.denied,
    );

    var side = 800.0;
    Future<void> pump() => tester.pumpWidget(
      _host(
        store: store,
        reset: reset,
        handoff: handoff,
        location: location,
        boundaries: boundaries.future,
        radar: radar,
        child: SizedBox(
          width: side,
          height: 600,
          child: const HomeMapBackdrop(),
        ),
      ),
    );

    platform.throwLayerIds = true;
    await pump();
    await _flush(tester);

    // A second selection while the first apply is still waiting on the
    // boundary future drops the stale one.
    store.select(3);
    await tester.pump();
    boundaries.complete(_boundaries());
    await _flush(tester);
    expect(platform.moves, greaterThan(0));
    expect(handoff.homeBounds, isNotNull);

    platform.includeLocation = true;
    platform.onMapStyleLoadedPlatform.call(null);
    await _flush(tester);

    radar.result = const Ok(['frame-a']);
    reset.fire();
    await _flush(tester);
    expect(platform.sources, contains('home-radar-src'));

    final moves = platform.moves;
    reset.fire();
    await _flush(tester);
    expect(platform.moves, moves);

    radar.result = const Ok([]);
    reset.fire();
    await _flush(tester);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await _flush(tester);

    side = 700;
    await pump();
    await _flush(tester);

    platform.throwMove = true;
    store.select(2);
    await _flush(tester);

    store.select(0);
    store.setCurrentCode('6300100');
    await _flush(tester);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets('a GPS fix frames a span and a missing fix goes nationwide', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final radar = _Radar()..result = const Err(UnexpectedFailure('down'));
    final store = RegionStore(SettingsStore.inMemory());
    store.setCurrentCode('6300100');
    store.select(1);
    GpsFix? known = (lat: 25.04, lng: 121.53);
    final location = LocationService(
      const TownDirectory({}),
      isAvailable: () async => true,
      fix: () async => known,
      lastKnown: () async => known,
      status: () async => LocationStatus.ready,
    );

    Future<void> show() => tester.pumpWidget(
      _host(
        store: store,
        reset: HomeResetSignal(),
        handoff: MapCameraHandoff(),
        location: location,
        boundaries: Future<TownBoundaries>.value(_boundaries()),
        radar: radar,
        child: const SizedBox(
          width: 800,
          height: 600,
          child: HomeMapBackdrop(),
        ),
      ),
    );

    await show();
    await _flush(tester);
    expect(platform.moves, greaterThan(0));

    known = null;
    store.setCurrentCode('1000200');
    await _flush(tester);

    final gate = Completer<void>();
    platform.gate = gate;
    known = (lat: 24, lng: 121);
    store.setCurrentCode('6300100');
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    gate.complete();
    await tester.pump();
  });
}

Future<void> _flush(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump();
  }
}

Widget _host({
  required RegionStore store,
  required HomeResetSignal reset,
  required MapCameraHandoff handoff,
  required LocationService location,
  required Future<TownBoundaries> boundaries,
  required RadarRepository radar,
  required Widget child,
}) {
  return MaterialApp(
    home: MultiProvider(
      providers: [
        ChangeNotifierProvider<RegionStore>.value(value: store),
        ChangeNotifierProvider<HomeResetSignal>.value(value: reset),
        ChangeNotifierProvider<MapCameraHandoff>.value(value: handoff),
        Provider<LocationService>.value(value: location),
        Provider<Future<TownBoundaries>>.value(value: boundaries),
        Provider<RadarRepository>.value(value: radar),
        Provider<TownDirectory>.value(value: const TownDirectory({})),
      ],
      child: child,
    ),
  );
}

TownBoundaries _boundaries() => TownBoundaries.fromDecoded(<String, dynamic>{
  '6300100': <String, dynamic>{
    'b': <num>[121.50, 25.02, 121.55, 25.06],
    'p': <dynamic>[
      <dynamic>[
        <num>[
          121.50,
          25.02,
          121.55,
          25.02,
          121.55,
          25.06,
          121.50,
          25.06,
          121.50,
          25.02,
        ],
      ],
    ],
  },
  '1000200': <String, dynamic>{
    'b': <num>[121.60, 25.00, 121.70, 25.10],
    'p': <dynamic>[
      <dynamic>[
        <num>[
          121.60,
          25.00,
          121.70,
          25.00,
          121.70,
          25.10,
          121.60,
          25.10,
          121.60,
          25.00,
        ],
      ],
    ],
  },
});

class _Radar implements RadarRepository {
  Result<List<String>> result = const Ok([]);

  @override
  Future<Result<List<String>>> frames() async => result;

  @override
  int get sourceMaxZoom => 8;

  @override
  int get sourceMinZoom => 3;

  @override
  String tileUrl(String frame) => 'https://example.test/$frame/{z}/{x}/{y}.png';

  @override
  Future<void> warmFrameTiles({
    required List<String> frames,
    required double south,
    required double west,
    required double north,
    required double east,
    required double zoom,
    bool fill = false,
    bool immediate = false,
    bool refreshResident = false,
  }) async {}

  @override
  Future<FrameTileReadiness> frameTileReadiness({
    required String frame,
    required double south,
    required double west,
    required double north,
    required double east,
    required double zoom,
    bool warm = false,
  }) async => (ready: true, resident: 1, required: 1);

  @override
  void cancelTileWarm() {}

  @override
  Future<void> abandonFrames(List<String> frames) async {}

  @override
  Future<void> releaseTiles() async {}
}

class _Platform extends MapLibrePlatform {
  final layers = <String>{};
  final sources = <String>{};
  bool throwLayerIds = false;
  bool throwMove = false;
  bool includeLocation = false;
  int moves = 0;
  Completer<void>? gate;

  @override
  Future<void> initPlatform(int id) async {
    onMapStyleLoadedPlatform.call(null);
  }

  @override
  Widget buildView(
    Map<String, dynamic> creationParams,
    OnPlatformViewCreatedCallback onPlatformViewCreated,
    Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers,
  ) {
    onPlatformViewCreated(1);
    return const SizedBox.shrink();
  }

  @override
  Future<void> setRenderPaused(bool paused) async {}

  @override
  Future<CameraPosition?> updateMapOptions(
    Map<String, dynamic> optionsUpdate,
  ) async => null;

  @override
  Future<bool?> moveCamera(CameraUpdate cameraUpdate) async {
    final waiting = gate;
    if (waiting != null) {
      gate = null;
      await waiting.future;
    }
    moves++;
    if (throwMove) {
      throwMove = false;
      throw StateError('move');
    }
    return true;
  }

  @override
  Future<List<dynamic>> getLayerIds() async {
    if (throwLayerIds) {
      throwLayerIds = false;
      throw StateError('layers');
    }
    return [...layers, if (includeLocation) 'mapbox-location-foreground-layer'];
  }

  @override
  Future<void> addGeoJsonSource(
    String sourceId,
    Map<String, dynamic> geojson, {
    String? promoteId,
  }) async {
    sources.add(sourceId);
  }

  @override
  Future<void> setGeoJsonSource(
    String sourceId,
    Map<String, dynamic> geojson,
  ) async {}

  @override
  Future<void> addLineLayer(
    String sourceId,
    String layerId,
    Map<String, dynamic> properties, {
    String? belowLayerId,
    String? sourceLayer,
    double? minzoom,
    double? maxzoom,
    dynamic filter,
    required bool enableInteraction,
  }) async {
    layers.add(layerId);
  }

  @override
  Future<void> addFillLayer(
    String sourceId,
    String layerId,
    Map<String, dynamic> properties, {
    String? belowLayerId,
    String? sourceLayer,
    double? minzoom,
    double? maxzoom,
    dynamic filter,
    required bool enableInteraction,
  }) async {
    layers.add(layerId);
  }

  @override
  Future<void> addCircleLayer(
    String sourceId,
    String layerId,
    Map<String, dynamic> properties, {
    String? belowLayerId,
    String? sourceLayer,
    double? minzoom,
    double? maxzoom,
    dynamic filter,
    required bool enableInteraction,
  }) async {
    layers.add(layerId);
  }

  @override
  Future<void> addSymbolLayer(
    String sourceId,
    String layerId,
    Map<String, dynamic> properties, {
    String? belowLayerId,
    String? sourceLayer,
    double? minzoom,
    double? maxzoom,
    dynamic filter,
    required bool enableInteraction,
  }) async {
    layers.add(layerId);
  }

  @override
  Future<void> addRasterLayer(
    String sourceId,
    String layerId,
    Map<String, dynamic> properties, {
    String? belowLayerId,
    String? sourceLayer,
    double? minzoom,
    double? maxzoom,
  }) async {
    layers.add(layerId);
  }

  @override
  Future<void> addSource(String sourceId, SourceProperties properties) async {
    sources.add(sourceId);
  }

  @override
  Future<void> removeLayer(String layerId) async {
    if (!layers.remove(layerId)) throw StateError('missing layer $layerId');
  }

  @override
  Future<void> removeSource(String sourceId) async {
    if (!sources.remove(sourceId)) throw StateError('missing source $sourceId');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.isAccessor || invocation.isGetter) return null;
    return Future<Object?>.value();
  }
}
