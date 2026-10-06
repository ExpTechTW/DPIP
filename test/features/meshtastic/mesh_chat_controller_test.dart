import 'dart:async';

import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/meshtastic/data/mesh_store.dart';
import 'package:dpip/core/meshtastic/domain/meshtastic_service.dart';
import 'package:dpip/core/meshtastic/mesh_link.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:dpip/features/meshtastic/presentation/mesh_chat_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite_async/sqlite_async.dart';

import '../../core/meshtastic/fake_mesh_service.dart';
import '../../core/storage/memory_db.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SqliteDatabase db;

  MeshMessage message(String text, {int from = 1, int seconds = 0}) =>
      MeshMessage(
        from: from,
        channel: 0,
        text: text,
        timestamp: DateTime.utc(2026, 1, 1).add(Duration(seconds: seconds)),
      );

  /// A controller over a fresh in-memory database, or over [reuse] to model a
  /// restart against the same storage.
  Future<(MeshChatController, FakeMeshService, MeshStore)> makeController([
    MeshStore? reuse,
  ]) async {
    final service = FakeMeshService();
    final settings = SettingsStore.inMemory({});
    MeshStore store;
    if (reuse != null) {
      store = reuse;
    } else {
      db = openMemoryDb();
      await MeshStore.createSchema(db);
      store = MeshStore(db);
    }
    final controller = MeshChatController(
      service,
      MeshLink(service, settings),
      store,
    );
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return (controller, service, store);
  }

  tearDown(() async => db.close());

  /// Lets the fire-and-forget SQLite writes land — they cross an isolate, so
  /// a bare microtask drain isn't enough.
  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 150));

  /// Waits until [store] holds [expected] messages.
  ///
  /// `_add` writes fire-and-forget and only adopts a message into the in-memory
  /// list once the insert answers (mesh_chat_controller.dart:322-328), so both
  /// halves of what these tests assert land *after* the controller has been
  /// handed the packet. A fixed delay is therefore a guess about how fast the
  /// machine is: 150 ms was enough on a laptop and not on CI, where the last
  /// dozen inserts arrived after the test had already closed the database and
  /// the failure read as `This database has already been closed`.
  Future<void> drained(MeshStore store, int expected) async {
    final deadline = DateTime.now().add(const Duration(seconds: 10));
    while (DateTime.now().isBefore(deadline)) {
      if ((await store.messages(limit: 100000)).length >= expected) return;
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  }

  test('keeps the newest messages first', () async {
    final (controller, service, _) = await makeController();
    for (var i = 0; i < 10; i++) {
      service.messages.add(message('m$i', seconds: i));
    }
    await settle();

    expect(controller.messages, hasLength(10));
    expect(controller.messages.first.text, 'm9');
    expect(controller.messages.last.text, 'm0');
  });

  test('holds only a window of the log in memory', () async {
    final (controller, service, store) = await makeController();
    for (var i = 0; i < MeshChatController.windowSize + 20; i++) {
      service.messages.add(message('m$i', seconds: i));
    }
    await drained(store, MeshChatController.windowSize + 20);

    expect(controller.messages, hasLength(MeshChatController.windowSize));
    // The store keeps everything — the window is a view, not a retention cap.
    expect(
      await store.messages(limit: 10000),
      hasLength(MeshChatController.windowSize + 20),
    );
  });

  test('persists the log and reloads it after a restart', () async {
    final (controller, service, store) = await makeController();
    service.messages.add(message('hello'));
    await drained(store, 1);
    controller.dispose();

    final (restored, _, _) = await makeController(store);
    expect(restored.messages.single.text, 'hello');
    expect(restored.messages.single.outgoing, isFalse);
  });

  test('drops a message the log already holds', () async {
    final (controller, service, _) = await makeController();
    service.messages
      ..add(message('same'))
      ..add(message('same'));
    await settle();

    expect(controller.messages, hasLength(1));
  });

  test('records a sent message as outgoing, and not a failed one', () async {
    final (controller, service, _) = await makeController();

    expect(await controller.send('  hi  '), isNull);
    await settle();
    expect(service.sentText, ['hi']);
    expect(controller.messages.single.text, 'hi');
    expect(controller.messages.single.outgoing, isTrue);

    service.sendFailure = const UnexpectedFailure('radio busy');
    expect(await controller.send('nope'), 'radio busy');
    await settle();
    expect(controller.messages, hasLength(1));
  });

  test('sends on the channel it is given and records it there', () async {
    final (controller, service, _) = await makeController();

    expect(await controller.send('hi', channel: 3), isNull);
    await settle();

    expect(service.sentChannels, [3]);
    expect(controller.messages.single.channel, 3);
  });

  test('counts stored messages per channel', () async {
    final (controller, service, _) = await makeController();
    service.messages
      ..add(message('a', seconds: 1))
      ..add(message('b', seconds: 2));
    await settle();
    await controller.send('mine', channel: 3);
    await settle();

    expect(controller.messageCountsByChannel, {0: 2, 3: 1});
  });

  test('clearMessages empties the log and its storage', () async {
    final (controller, service, store) = await makeController();
    service.messages.add(message('bye'));
    await settle();

    controller.clearMessages();
    await settle();

    expect(controller.messages, isEmpty);
    expect(await store.messages(), isEmpty);
  });

  test('an empty log is already clear', () async {
    final (controller, _, _) = await makeController();
    controller.clearMessages();
    expect(controller.messages, isEmpty);
    controller.dispose();
  });

  test('a null store dedups in memory and has no metrics', () async {
    db = openMemoryDb();
    final service = FakeMeshService();
    final controller = MeshChatController(
      service,
      MeshLink(service, SettingsStore.inMemory()),
      null,
    );
    addTearDown(controller.dispose);
    service.messages.add(message('same', seconds: 1));
    service.messages.add(message('same', seconds: 1));
    service.messages.add(
      MeshMessage(
        from: 1,
        channel: 0,
        text: '00 ff',
        timestamp: DateTime.utc(2026, 1, 1, 0, 0, 2),
        binary: true,
      ),
    );
    await settle();
    expect(controller.messages, hasLength(2));
    expect(controller.messages.first.binary, isTrue);
    expect(await controller.metricsHistory(), isEmpty);
    expect(await controller.send('   '), isNull);
    expect(controller.messages, hasLength(2));
  });

  test('scan reports devices once, and names the failure', () async {
    final (controller, service, _) = await makeController();
    service.scanResults = const [
      MeshDevice(id: 'a', name: 'Porch'),
      MeshDevice(id: 'a', name: 'Porch again'),
      MeshDevice(id: 'b', name: 'Roof'),
    ];
    await controller.startScan();
    expect(controller.scanning, isFalse);
    expect(controller.devices.map((d) => d.id), ['a', 'b']);
    expect(controller.scanError, isNull);

    final errored = _ScriptedScan(
      Stream<MeshDevice>.error(StateError('adapter off')),
    );
    final errorController = MeshChatController(
      errored,
      MeshLink(errored, SettingsStore.inMemory()),
      null,
    );
    addTearDown(errorController.dispose);
    await errorController.startScan();
    expect(errorController.scanError, 'adapter off');
    expect(errorController.scanning, isFalse);

    final generic = _ScriptedScan(Stream<MeshDevice>.error(Exception('boom')));
    final genericController = MeshChatController(
      generic,
      MeshLink(generic, SettingsStore.inMemory()),
      null,
    );
    addTearDown(genericController.dispose);
    await genericController.startScan();
    expect(genericController.scanError, contains('boom'));
  });

  test('stopping a scan does not wait for it to finish', () async {
    db = openMemoryDb();
    final hung = _ScriptedScan(StreamController<MeshDevice>().stream);
    final controller = MeshChatController(
      hung,
      MeshLink(hung, SettingsStore.inMemory()),
      null,
    );
    addTearDown(controller.dispose);
    unawaited(controller.startScan());
    await Future<void>.delayed(Duration.zero);
    expect(controller.scanning, isTrue);
    await controller.stopScan();
    expect(controller.scanning, isFalse);
  });

  test('connect shows the in-flight id, then disconnects', () async {
    db = openMemoryDb();
    final gated = _GatedConnect();
    final settings = SettingsStore.inMemory();
    final link = MeshLink(gated, settings);
    final controller = MeshChatController(gated, link, null);
    addTearDown(() {
      controller.dispose();
      link.dispose();
    });
    const device = MeshDevice(id: 'radio-1', name: 'Porch');
    final connecting = controller.connect(device);
    await Future<void>.delayed(Duration.zero);
    expect(controller.connectingId, 'radio-1');
    gated.gate.complete();
    expect(await connecting, isNull);
    expect(controller.connectingId, isNull);
    expect(await controller.disconnect(), isNull);
  });

  test(
    'channel names are remembered and unchanged names are not rewritten',
    () async {
      final (controller, service, store) = await makeController();
      service.channels = const [
        MeshChannel(index: 0, name: '', psk: [1], enabled: true),
        MeshChannel(index: 2, name: 'DPIP', psk: [1], enabled: true),
      ];
      service.connections.add(
        const MeshConnectionStatus(state: MeshConnectionState.connected),
      );
      await settle();
      expect(controller.channelNames, {2: 'DPIP'});

      service.connections.add(
        const MeshConnectionStatus(state: MeshConnectionState.connected),
      );
      await settle();
      expect(controller.channelNames, {2: 'DPIP'});

      service.channels = const [
        MeshChannel(index: 2, name: 'Town', psk: [1], enabled: true),
      ];
      service.connections.add(
        const MeshConnectionStatus(state: MeshConnectionState.disconnected),
      );
      await settle();
      expect(controller.channelNames[2], 'Town');
      expect((await store.readChannels())[2], 'Town');

      controller.markVisible(2);
      expect(controller.unreadDividerTs(2), isNull);
    },
  );
}

class _ScriptedScan extends FakeMeshService {
  _ScriptedScan(this._scan);

  final Stream<MeshDevice> _scan;

  @override
  Stream<MeshDevice> scanForDevices({Duration timeout = Duration.zero}) =>
      _scan;
}

class _GatedConnect extends FakeMeshService {
  final gate = Completer<void>();

  @override
  Future<Result<void>> connectToId(String id) async {
    await gate.future;
    return super.connectToId(id);
  }
}
