/// The disaster-map legend and the options chip are the only names a reader
/// has for the three facility layers. A missing label, or a chip that does
/// not offer the restroom kinds, leaves the toggles unlabeled.
library;

import 'dart:math' show Point;

import 'package:dpip/core/error/result.dart';
import 'package:dpip/features/disaster_map/domain/aed_detail.dart';
import 'package:dpip/features/disaster_map/domain/disaster_map_repository.dart';
import 'package:dpip/features/disaster_map/domain/restroom_detail.dart';
import 'package:dpip/features/disaster_map/domain/shelter_detail.dart';
import 'package:dpip/features/map/presentation/layers/disaster_map_layer.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/map/map_style.dart' show dpmAedPointsLayerId;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../raster_timeline_harness.dart';

class _Repo implements DisasterMapRepository {
  @override
  String tileUrl(String layer) => 'https://example.invalid/$layer/{z}/{x}/{y}';

  @override
  Future<Result<AedDetail>> aedDetail(int id) async =>
      const Ok(AedDetail(id: 1, aedId: 'A', name: 'Lobby', lat: 25, lng: 121));

  @override
  Future<Result<RestroomDetail>> restroomDetail(int id) async => const Ok(
    RestroomDetail(name: 'Park', address: 'Park Road', type: 1, type2: 2),
  );

  @override
  Future<Result<ShelterDetail>> shelterDetail(int id) async =>
      const Ok(ShelterDetail(id: 9, name: 'Hall', lat: 24, lng: 121));

  @override
  Future<void> prefetchTiles({
    required String layer,
    required double south,
    required double west,
    required double north,
    required double east,
    required double zoom,
  }) async {}

  @override
  void cancelTilePrefetch() {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the legend and the options chip name the facilities', (
    tester,
  ) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    final layer = DisasterMapLayer(_Repo());
    addTearDown(layer.close);
    final towns = ValueNotifier(true);
    final terrain = ValueNotifier(true);
    addTearDown(towns.dispose);
    addTearDown(terrain.dispose);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => Column(
              children: [
                layer.buildLegend(context),
                layer.buildTopTrailingChrome(
                  context,
                  showTownLabels: towns,
                  onShowTownLabelsChanged: (value) => towns.value = value,
                  showTerrain: terrain,
                  onShowTerrainChanged: (value) => terrain.value = value,
                  onReloadActive: () async {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
    expect(find.text(l10n.mapLayerAed), findsOneWidget);
    expect(find.text(l10n.restroomTypeFemale), findsOneWidget);
  });

  testWidgets('render mounts the markers and a tap selects one hit', (
    tester,
  ) async {
    await tester.pumpWidget(const SizedBox.shrink());
    final layer = DisasterMapLayer(_Repo());
    addTearDown(layer.close);
    final map = _Map();

    await tester.runAsync(() => layer.render(map));
    expect(map.calls.where((call) => call.startsWith('addSource')), isNotEmpty);
    expect(layer.aed.visible.value, isTrue);

    layer.restroom.filters['type']!.values.value = {1};
    await tester.pump();
    expect(
      map.calls.where((call) => call.startsWith('setLayerFilter')),
      isNotEmpty,
    );

    map.throwFilter = true;
    layer.shelter.filters['category']!.values.value = {'school'};
    await tester.pump();

    await layer.onMapTap(const LatLng(25, 121), map);
    expect(layer.aed.selectionId.value, isNull);

    map.hits = [
      {
        'id': 7,
        'properties': {'name': 'Lobby', 'place': 'Hall'},
      },
    ];
    await layer.onMapTap(const LatLng(25, 121), map);
    await tester.pump();
    expect(layer.aed.selectionId.value, 7);
    expect(layer.aed.detail.value?.name, 'Lobby');

    map.hits = [
      {
        'id': 1,
        'properties': {'name': 'A'},
      },
      {
        'id': 2,
        'properties': {'name': 'B'},
      },
    ];
    await layer.onMapTap(const LatLng(25, 121), map);
    expect(map.calls, contains('animateCamera'));
    expect(layer.aed.selectionId.value, 7);

    map.reportCamera(zoom: 16);
    await layer.onMapTap(const LatLng(25, 121), map);
    await tester.pump();
    expect(layer.aed.selectionId.value, 1);

    layer.setSubLayerVisible(layer.aed, false);
    layer.setSubLayerVisible(layer.restroom, false);
    layer.setSubLayerVisible(layer.shelter, false);
    expect(layer.aed.visible.value, isFalse);

    await layer.onCameraIdle(map);
    await layer.clear(map);
    expect(
      map.calls.where((call) => call.startsWith('removeLayer')),
      isNotEmpty,
    );
  });
}

class _Map extends RecordingMapController {
  List<Map<String, dynamic>> hits = const [];
  bool throwFilter = false;

  @override
  Future<List<dynamic>> getLayerIds() async => const [];

  @override
  Future<Point<num>> toScreenLocation(LatLng latLng) async =>
      const Point(80, 80);

  @override
  Future<bool> setLayerFilter(String layerId, String filter) async {
    calls.add('setLayerFilter:$layerId');
    if (throwFilter) {
      throwFilter = false;
      throw StateError('filter');
    }
    return true;
  }

  @override
  Future<List<dynamic>> queryRenderedFeaturesInRect(
    Rect rect,
    List<String> layerIds,
    String? filter,
  ) async => layerIds.contains(dpmAedPointsLayerId) ? hits : const [];

  @override
  Future<bool?> animateCamera(
    CameraUpdate cameraUpdate, {
    Duration? duration,
  }) async {
    calls.add('animateCamera');
    return true;
  }
}
