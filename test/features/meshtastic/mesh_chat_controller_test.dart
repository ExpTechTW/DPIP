import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/meshtastic/data/mesh_store.dart';
import 'package:dpip/core/meshtastic/domain/meshtastic_service.dart';
import 'package:dpip/core/meshtastic/mesh_link.dart';
import 'package:dpip/core/meshtastic/mesh_node_store.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:dpip/features/meshtastic/presentation/mesh_chat_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../core/meshtastic/fake_mesh_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(sqfliteFfiInit);

  late Database db;

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
      db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
      await MeshStore.createSchema(db);
      store = MeshStore(db);
    }
    final controller = MeshChatController(
      service,
      MeshLink(service, settings),
      MeshNodeStore(service, settings)..start(),
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
    await settle();

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
    await settle();
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
}
