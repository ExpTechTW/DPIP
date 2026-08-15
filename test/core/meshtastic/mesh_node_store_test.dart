import 'package:dpip/core/meshtastic/data/mesh_store.dart';
import 'package:dpip/core/meshtastic/domain/meshtastic_service.dart';
import 'package:dpip/core/meshtastic/mesh_node_store.dart';
import 'package:dpip/core/settings/setting_keys.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'fake_mesh_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

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

  /// Nodes now live in the `mesh_nodes` table, so a restart test needs the
  /// *same* database on the second open — hence the explicit handle rather
  /// than a fresh `:memory:` each time (sqflite would hand back a shared one
  /// anyway, which is worse: silent cross-test state).
  Future<Database> memoryDb() => databaseFactoryFfi.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(singleInstance: false),
  );

  late SettingsStore settings;

  Future<(MeshNodeStore, FakeMeshService)> makeStore({
    Map<String, Object> initial = const {},
    Database? db,
  }) async {
    clock = DateTime.utc(2026, 1, 1, 12);
    final service = FakeMeshService();
    settings = SettingsStore.inMemory(initial);
    MeshStore? mesh;
    if (db != null) {
      await MeshStore.createSchema(db);
      mesh = MeshStore(db);
    }
    final store = MeshNodeStore(
      service,
      settings,
      store: mesh,
      now: () => clock,
    )..start();
    // The restore is a query now, so wait for it rather than for a delay
    // chosen by guesswork.
    await store.whenRestored;
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
    final db = await memoryDb();
    final (store, service) = await makeStore(db: db);
    service.nodes.add(
      node(7, name: 'repeater', lat: 23.5, lon: 120.5, heard: clock),
    );
    await flush();

    expect(await MeshStore(db).readNodes(), hasLength(1));

    // A day later the same entry must not still claim to be online.
    final (restored, _) = await makeStore(db: db);
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
    final db = await memoryDb();
    final (store, service) = await makeStore(db: db);
    for (var i = 0; i < MeshNodeStore.maxNodes + 5; i++) {
      service.nodes.add(node(i, heard: clock.subtract(Duration(minutes: i))));
    }
    await flush();

    expect(await MeshStore(db).readNodes(), hasLength(MeshNodeStore.maxNodes));

    final (restored, _) = await makeStore(db: db);
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

        expect(settings.getBool(SettingKeys.meshExcludeMqtt), isFalse);
      },
    );

    test('the MQTT flag survives a restart', () async {
      final db = await memoryDb();
      final (store, service) = await makeStore(db: db);
      service.nodes.add(node(2, lat: 35.6, lon: 139.7, viaMqtt: true));
      await flush();

      final (restored, _) = await makeStore(db: db);
      expect(restored.byNum(2)?.viaMqtt, isTrue);
      expect(restored.positioned, isEmpty);
    });
  });

  test('the schema makes a half-written node impossible', () async {
    // The JSON-blob version could restore a node with no number, or lose the
    // whole list to one malformed entry. Columns with NOT NULL make both
    // states unrepresentable — the row is rejected at write time instead of
    // being discovered at read time.
    final db = await memoryDb();
    await MeshStore.createSchema(db);
    // A node with no name is rejected at write time.
    await expectLater(
      db.insert('mesh_nodes', {'num': 5, 'snr': 0.0}),
      throwsA(isA<Object>()),
    );
    // A node always has a number: `num INTEGER PRIMARY KEY` is the rowid, so
    // one is assigned even when the caller omits it. There is no such thing
    // as the numberless entry the JSON blob could produce.
    final id = await db.insert('mesh_nodes', {'name': 'auto', 'snr': 0.0});
    expect(id, greaterThan(0));
    await db.delete('mesh_nodes');
    // And a well-formed row round-trips.
    final (store, _) = await makeStore(db: db);
    await MeshStore(db).writeNodes([
      {'num': 5, 'name': 'ok', 'snr': 0.0, 'via_mqtt': 0},
    ]);
    final (restored, _) = await makeStore(db: db);
    expect(restored.byNum(5)?.displayName, 'ok');
    expect(store.nodes, isEmpty);
  });

  test('clear empties the table and its storage', () async {
    final db = await memoryDb();
    final (store, service) = await makeStore(db: db);
    service.nodes.add(node(1));
    await flush();

    await store.clear();
    expect(store.nodes, isEmpty);
    expect(await MeshStore(db).readNodes(), isEmpty);
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
