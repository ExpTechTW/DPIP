import 'package:dpip/core/meshtastic/domain/meshtastic_service.dart';
import 'package:dpip/core/meshtastic/mesh_node_store.dart';
import 'package:dpip/core/settings/prefs.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_mesh_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  var clock = DateTime.utc(2026, 1, 1, 12);

  MeshNode node(
    int num, {
    String name = 'n',
    double? lat,
    double? lon,
    int? battery,
    double snr = 0,
    DateTime? heard,
    bool viaMqtt = false,
  }) => MeshNode(
    num: num,
    displayName: name,
    isOnline: true,
    batteryLevel: battery,
    lastHeard: heard,
    latitude: lat,
    longitude: lon,
    snr: snr,
    viaMqtt: viaMqtt,
  );

  Future<(MeshNodeStore, FakeMeshService)> makeStore([
    Map<String, Object> initial = const {},
  ]) async {
    clock = DateTime.utc(2026, 1, 1, 12);
    SharedPreferences.setMockInitialValues(initial);
    final service = FakeMeshService();
    final store = MeshNodeStore(
      service,
      Prefs(await SharedPreferences.getInstance()),
      now: () => clock,
    )..start();
    return (store, service);
  }

  /// Lets the debounced write fire.
  Future<void> flush() =>
      Future<void>.delayed(const Duration(seconds: 2, milliseconds: 100));

  test('collects nodes off the stream', () async {
    final (store, service) = await makeStore();
    service.nodes
      ..add(node(1, name: 'a'))
      ..add(node(2, name: 'b'));
    await Future<void>.delayed(Duration.zero);

    expect(store.nodes, hasLength(2));
    expect(store.byNum(1)?.displayName, 'a');
  });

  test('keeps a position a later update omits', () async {
    final (store, service) = await makeStore();
    service.nodes.add(node(1, lat: 23.5, lon: 120.5));
    await Future<void>.delayed(Duration.zero);
    // A telemetry-driven re-emit carries fresh metrics but no position.
    service.nodes.add(node(1, battery: 80));
    await Future<void>.delayed(Duration.zero);

    expect(store.byNum(1)?.latitude, 23.5);
    expect(store.byNum(1)?.batteryLevel, 80);
  });

  test('only offers positioned nodes to the map', () async {
    final (store, service) = await makeStore();
    service.nodes
      ..add(node(1, lat: 23.5, lon: 120.5))
      ..add(node(2));
    await Future<void>.delayed(Duration.zero);

    expect(store.positioned.single.num, 1);
  });

  test('survives a restart, with freshness recomputed', () async {
    final (store, service) = await makeStore();
    service.nodes.add(
      node(7, name: 'repeater', lat: 23.5, lon: 120.5, heard: clock),
    );
    await flush();

    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList('meshtastic.nodes');
    expect(stored, hasLength(1));

    // A day later the same entry must not still claim to be online.
    final (restored, _) = await makeStore({'meshtastic.nodes': stored!});
    clock = clock.add(const Duration(days: 1));

    final node7 = restored.byNum(7);
    expect(node7?.displayName, 'repeater');
    expect(node7?.latitude, 23.5);
    expect(restored.isOnline(node7!), isFalse);
  });

  test('online is a window on lastHeard, not a stored flag', () async {
    final (store, service) = await makeStore();
    service.nodes
      ..add(node(1, heard: clock.subtract(const Duration(minutes: 1))))
      ..add(node(2, heard: clock.subtract(const Duration(hours: 3))))
      ..add(node(3));
    await Future<void>.delayed(Duration.zero);

    expect(store.isOnline(store.byNum(1)!), isTrue);
    expect(store.isOnline(store.byNum(2)!), isFalse);
    expect(store.isOnline(store.byNum(3)!), isFalse); // never heard
  });

  test('drops the least recently heard past the cap', () async {
    final (store, service) = await makeStore();
    for (var i = 0; i < MeshNodeStore.maxNodes + 5; i++) {
      service.nodes.add(node(i, heard: clock.subtract(Duration(minutes: i))));
    }
    await flush();

    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList('meshtastic.nodes')!;
    expect(stored, hasLength(MeshNodeStore.maxNodes));

    final (restored, _) = await makeStore({'meshtastic.nodes': stored});
    // 0 was heard most recently, the tail is the oldest.
    expect(restored.byNum(0), isNotNull);
    expect(restored.byNum(MeshNodeStore.maxNodes + 4), isNull);
  });

  group('MQTT nodes', () {
    test('are kept off the map by default', () async {
      final (store, service) = await makeStore();
      service.nodes
        ..add(node(1, lat: 23.5, lon: 120.5))
        ..add(node(2, lat: 35.6, lon: 139.7, viaMqtt: true)); // Tokyo
      await Future<void>.delayed(Duration.zero);

      expect(store.excludeMqtt, isTrue);
      // The node is still known — it just isn't evidence of radio reach.
      expect(store.nodes, hasLength(2));
      expect(store.positioned.single.num, 1);
      expect(store.hiddenMqttCount, 1);
    });

    test(
      'come back when the filter is turned off, and that persists',
      () async {
        final (store, service) = await makeStore();
        service.nodes.add(node(2, lat: 35.6, lon: 139.7, viaMqtt: true));
        await Future<void>.delayed(Duration.zero);

        await store.setExcludeMqtt(exclude: false);
        expect(store.positioned, hasLength(1));
        expect(store.hiddenMqttCount, 0);

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('map.meshExcludeMqtt'), isFalse);
      },
    );

    test('the flag survives a restart', () async {
      final (store, service) = await makeStore();
      service.nodes.add(node(2, lat: 35.6, lon: 139.7, viaMqtt: true));
      await flush();
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getStringList('meshtastic.nodes')!;

      final (restored, _) = await makeStore({'meshtastic.nodes': stored});
      expect(restored.byNum(2)?.viaMqtt, isTrue);
      expect(restored.positioned, isEmpty);
    });
  });

  test('ignores a corrupt entry instead of losing the table', () async {
    final (store, service) = await makeStore();
    service.nodes.add(node(1, name: 'good'));
    await flush();
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList('meshtastic.nodes')!;

    final (restored, _) = await makeStore({
      'meshtastic.nodes': ['not json', ...stored],
    });
    expect(restored.nodes.single.displayName, 'good');
  });

  test('clear empties the table and its storage', () async {
    final (store, service) = await makeStore();
    service.nodes.add(node(1));
    await flush();

    await store.clear();
    expect(store.nodes, isEmpty);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('meshtastic.nodes'), isEmpty);
  });

  group('telemetry history', () {
    test('records one sample per distinct reading', () async {
      final (store, service) = await makeStore();
      service.nodes.add(node(1, snr: -5.0, battery: 80));
      await Future<void>.delayed(Duration.zero);
      clock = clock.add(const Duration(minutes: 1));
      service.nodes.add(node(1, snr: -3.5, battery: 79));
      await Future<void>.delayed(Duration.zero);

      final history = store.historyOf(1);
      expect(history, hasLength(2));
      expect(history.first.snr, -5.0);
      expect(history.last.snr, -3.5);
      expect(history.last.battery, 79);
      expect(
        history.last.time.difference(history.first.time),
        const Duration(minutes: 1),
      );
    });

    test('a repeated reading only moves the last sample in time', () async {
      final (store, service) = await makeStore();
      service.nodes.add(node(1, snr: -5.0, battery: 80));
      await Future<void>.delayed(Duration.zero);
      clock = clock.add(const Duration(minutes: 5));
      // A node burst re-emits the same telemetry; that must not pile up.
      service.nodes
        ..add(node(1, snr: -5.0, battery: 80))
        ..add(node(1, snr: -5.0, battery: 80));
      await Future<void>.delayed(Duration.zero);

      final history = store.historyOf(1);
      expect(history, hasLength(1));
      expect(history.single.time, clock);
    });

    test('capped at the ring size', () async {
      final (store, service) = await makeStore();
      for (var i = 0; i < MeshNodeStore.historyLimit + 10; i++) {
        service.nodes.add(node(1, snr: -10.0 + i));
        await Future<void>.delayed(Duration.zero);
        clock = clock.add(const Duration(seconds: 1));
      }

      final history = store.historyOf(1);
      expect(history, hasLength(MeshNodeStore.historyLimit));
      // The newest survives, the oldest is gone.
      expect(history.last.snr, -10.0 + MeshNodeStore.historyLimit + 9);
      expect(history.first.snr, -10.0 + 10);
    });
  });

  group('distance to my radio', () {
    test('measured from the radio node, not the phone', () async {
      final (store, service) = await makeStore();
      // My radio sits in Hualien city; the node is 1° north on the same
      // meridian (~111 km) and 1° east on it (~100 km).
      service.nodes
        ..add(node(0x1234, name: 'mine', lat: 24.0, lon: 121.6))
        ..add(node(1, lat: 25.0, lon: 122.6));
      await Future<void>.delayed(Duration.zero);

      final km = store.distanceToMyRadioKm(store.byNum(1)!);
      expect(km, isNotNull);
      expect(km!, greaterThan(140));
      expect(km, lessThan(160));
    });

    test('null without a radio position', () async {
      final (store, service) = await makeStore();
      service.nodes.add(node(1, lat: 25.0, lon: 122.6));
      await Future<void>.delayed(Duration.zero);

      expect(store.distanceToMyRadioKm(store.byNum(1)!), isNull);
    });
  });
}
