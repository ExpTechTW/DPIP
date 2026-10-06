/// A mesh dot is a claim that a radio is there. The label, the tap radius,
/// and the MQTT filter are what keep a distant internet bridge or a stale
/// name from looking like a neighbour you can reach.
library;

import 'dart:math' show Point;

import 'package:dpip/core/meshtastic/domain/meshtastic_service.dart';
import 'package:dpip/core/meshtastic/mesh_node_store.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:dpip/features/map/presentation/layers/mesh_node_layer.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/widgets/map_menu_toggle_row.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../../../core/meshtastic/fake_mesh_service.dart';
import '../../raster_timeline_harness.dart';

class _Map extends RecordingMapController {
  Point<num> tapAt = const Point(0, 0);
  Point<num> nodeAt = const Point(0, 0);
  bool throwScreen = false;
  bool throwBatch = false;
  bool throwGeo = false;
  bool throwRemove = false;

  @override
  Future<Point<num>> toScreenLocation(LatLng latLng) async {
    if (throwScreen) throw StateError('screen');
    return tapAt;
  }

  @override
  Future<List<Point<num>>> toScreenLocationBatch(
    Iterable<LatLng> coords,
  ) async {
    if (throwBatch) throw StateError('batch');
    return [for (final _ in coords) nodeAt];
  }

  @override
  Future<void> setGeoJsonSource(
    String sourceId,
    Map<String, dynamic> geojson,
  ) async {
    if (throwGeo) {
      throwGeo = false;
      throw StateError('geo');
    }
    await super.setGeoJsonSource(sourceId, geojson);
  }

  @override
  Future<void> removeLayer(String layerId) async {
    if (throwRemove) {
      throwRemove = false;
      throw StateError('remove');
    }
    await super.removeLayer(layerId);
  }
}

void main() {
  // The automated binding owns the clock. Without it a pump waits on a
  // platform frame that the tester never delivers.
  AutomatedTestWidgetsFlutterBinding.ensureInitialized();

  final now = DateTime.utc(2026, 1, 1, 12);

  late FakeMeshService service;
  late MeshNodeStore store;
  late MeshNodeMapLayer layer;
  late _Map map;

  setUp(() {
    service = FakeMeshService();
    store = MeshNodeStore(service, SettingsStore.inMemory({}), now: () => now)
      ..start();
    layer = MeshNodeMapLayer(store, service: service);
    map = _Map();
  });

  tearDown(() async {
    await layer.clear(map);
    store.dispose();
  });

  Future<void> hear(MeshNode node) async {
    service.nodes.add(node);
  }

  List<Map<String, dynamic>> features() {
    final data = map.sourceData['mesh-node-src'];
    final raw = (data?['features'] as List?) ?? const [];
    return [
      for (final feature in raw) Map<String, dynamic>.from(feature as Map),
    ];
  }

  Map<String, dynamic> props(int num) => Map<String, dynamic>.from(
    features().firstWhere(
          (feature) => (feature['properties'] as Map)['num'] == num,
        )['properties']
        as Map,
  );

  testWidgets('labels, a debounced push, and a tap use screen distance', (
    tester,
  ) async {
    // A frame has to exist before a timed pump: with no tree, the binding
    // waits for a frame that never arrives.
    await tester.pumpWidget(const SizedBox.shrink());
    await hear(
      MeshNode(
        num: 1,
        displayName: 'Alpha',
        batteryLevel: 80,
        snr: 1.5,
        hopsAway: 0,
        lastHeard: now,
        latitude: 24,
        longitude: 121,
      ),
    );
    await hear(
      MeshNode(
        num: 2,
        displayName: '',
        lastHeard: now.subtract(const Duration(hours: 1)),
        latitude: 24.1,
        longitude: 121.1,
      ),
    );
    await hear(
      MeshNode(
        num: 3,
        displayName: '一二三四五六七八九十甲乙丙',
        batteryLevel: 120,
        hopsAway: 2,
        lastHeard: now,
        latitude: 24.2,
        longitude: 121.2,
      ),
    );
    await hear(
      MeshNode(
        num: 4,
        displayName: 'Bridge',
        viaMqtt: true,
        lastHeard: now,
        latitude: 35,
        longitude: 139,
      ),
    );
    await hear(
      MeshNode(
        num: 5,
        displayName: 'Old',
        lastHeard: now.subtract(const Duration(days: 3)),
        latitude: 24.3,
        longitude: 121.3,
      ),
    );

    await layer.render(map);
    final drawn = features();
    expect(drawn, hasLength(3));
    expect(props(1)['label'], contains('80%'));
    expect(props(1)['label'], contains('SNR 1.5'));
    expect(props(1)['label'], contains('0 hop'));
    expect(props(1)['online'], 1);
    expect(props(1)['direct'], 1);
    expect(props(2)['name'], '0x2');
    expect(props(2)['online'], 0);
    expect(props(3)['name'], '一二三四五六七八九十甲乙…');
    expect(props(3)['label'], contains('DC'));
    expect(props(3)['label'], contains('2 hop'));
    expect(props(3)['mqtt'], 0);

    final before = map.calls
        .where((call) => call.startsWith('setGeoJson'))
        .length;
    await hear(
      MeshNode(
        num: 6,
        displayName: 'New',
        lastHeard: now,
        latitude: 24.4,
        longitude: 121.4,
      ),
    );
    await hear(
      MeshNode(
        num: 7,
        displayName: 'Newer',
        lastHeard: now,
        latitude: 24.5,
        longitude: 121.5,
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));
    expect(
      map.calls.where((call) => call.startsWith('setGeoJson')).length,
      before,
    );
    map.throwGeo = true;
    await tester.pump(const Duration(milliseconds: 300));

    map.tapAt = const Point(0, 0);
    map.nodeAt = const Point(10, 0);
    await layer.onMapTap(const LatLng(24, 121), map);
    expect(layer.routeState.value.result, isNull);

    map.throwScreen = true;
    await layer.onMapTap(const LatLng(0, 0), map);
  });

  testWidgets('iOS misses a dot that Android device pixels still reach', (
    tester,
  ) async {
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    await tester.pumpWidget(const SizedBox.shrink());
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetDevicePixelRatio);

    await hear(
      MeshNode(
        num: 1,
        displayName: 'Alpha',
        lastHeard: now,
        latitude: 24,
        longitude: 121,
      ),
    );
    await layer.render(map);
    map.tapAt = const Point(0, 0);
    map.nodeAt = const Point(60, 0);

    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    await layer.onMapTap(const LatLng(24, 121), map);
    expect(props(1)['selected'], 0);

    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    await layer.onMapTap(const LatLng(24, 121), map);
    expect(props(1)['selected'], 1);

    debugDefaultTargetPlatformOverride = null;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: Builder(builder: layer.buildSheet)),
      ),
    );
    await tester.pump();
    expect(find.text('Alpha'), findsWidgets);
    await tester.pumpWidget(const SizedBox.shrink());
    // Checked before tearDown. A leftover override fails the test on its own.
    debugDefaultTargetPlatformOverride = null;
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('a broken hop splits the route, and the legend hides MQTT', (
    tester,
  ) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    for (final node in [
      MeshNode(
        num: 1,
        displayName: 'A',
        lastHeard: now,
        latitude: 24,
        longitude: 121,
      ),
      MeshNode(
        num: 2,
        displayName: 'B',
        lastHeard: now,
        latitude: 24.2,
        longitude: 121.2,
      ),
      MeshNode(num: 3, displayName: 'Gap', lastHeard: now),
      MeshNode(
        num: 4,
        displayName: 'C',
        lastHeard: now,
        latitude: 24.4,
        longitude: 121.4,
      ),
      MeshNode(
        num: 5,
        displayName: 'D',
        lastHeard: now,
        latitude: 24.6,
        longitude: 121.6,
      ),
      MeshNode(
        num: 9,
        displayName: 'Mqtt',
        viaMqtt: true,
        lastHeard: now,
        latitude: 35,
        longitude: 139,
      ),
    ]) {
      await hear(node);
    }
    await layer.render(map);
    expect(store.byNum(1)?.latitude, isNotNull);
    expect(store.byNum(5)?.latitude, isNotNull);

    map.nodeAt = const Point(40, 40);
    final sent = layer.startTrace(5);
    await sent;
    expect(layer.routeState.value.target, 5);
    service.routes.add(
      MeshRoute(
        target: 5,
        towards: [
          MeshRouteHop(num: 1),
          MeshRouteHop(num: 2),
          MeshRouteHop(num: 3),
          MeshRouteHop(num: 4),
          MeshRouteHop(num: 5),
        ],
        back: const [],
      ),
    );
    // The route stream delivers on a zero-duration timer, which a bare
    // microtask flush does not run.
    await tester.pump(Duration.zero);
    expect(layer.routeSegments.value, hasLength(2));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: Builder(builder: layer.buildMapOverlay)),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    expect(find.byType(CustomPaint), findsWidgets);

    map.nodeAt = const Point(80, 90);
    await layer.onCameraIdle(map);
    await tester.pump();
    expect(find.byType(CustomPaint), findsWidgets);

    map.throwBatch = true;
    await layer.onCameraIdle(map);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());

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
    expect(find.text(l10n.meshtasticOnline), findsOneWidget);
    expect(find.text(l10n.meshtasticViaMqtt), findsNothing);

    await tester.tap(find.byTooltip(l10n.meshtasticLayerOptions));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text(l10n.meshtasticExcludeMqttHidden(1)), findsOneWidget);
    final mqtt = find.ancestor(
      of: find.text(l10n.meshtasticExcludeMqtt),
      matching: find.byType(MapMenuToggleRow),
    );
    tester.widget<MapMenuToggleRow>(mqtt).onTap();
    await tester.pump();
    expect(store.excludeMqtt, isFalse);
    expect(find.text(l10n.meshtasticViaMqtt), findsOneWidget);

    map.throwRemove = true;
    layer.onStyleReset();
    await layer.render(map);
    expect(map.calls.where((call) => call.startsWith('addSource')), isNotEmpty);

    // Dropping the link cancels the probe cooldown. Elapsing it instead
    // would also step the route overlay's repeating ticker, which never ends.
    service.connections.add(
      const MeshConnectionStatus(state: MeshConnectionState.disconnected),
    );
    // The MQTT toggle notifies the layer, which trails one map push by 250 ms.
    await tester.pump(const Duration(milliseconds: 300));
  });
}
