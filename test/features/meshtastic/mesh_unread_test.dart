/// Unread state, and the offline-history fixes that shipped with it.
///
/// Three behaviours pinned together because they share the failure surface —
/// what the chat page shows when the radio is *not* connected:
/// * unread dots: received messages in a conversation the user is not looking
///   at accrue a dot; opening it clears the dot and the position survives a
///   restart;
/// * per-conversation history windows: a busy channel must not evict a quiet
///   one's messages from the offline view;
/// * the disconnected default conversation: the DPIP slot survives a restart,
///   not just a drop.
library;

import 'package:dpip/core/meshtastic/data/mesh_store.dart';
import 'package:dpip/core/meshtastic/domain/meshtastic_service.dart';
import 'package:dpip/core/meshtastic/mesh_link.dart';
import 'package:dpip/core/settings/setting_keys.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:dpip/features/meshtastic/presentation/mesh_chat_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../core/meshtastic/fake_mesh_service.dart';

Future<Database> _open() async {
  final db = await databaseFactoryFfi.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(singleInstance: false),
  );
  await MeshStore.createSchema(db);
  return db;
}

MeshMessage _incoming(String text, int channel, {int seconds = 0}) =>
    MeshMessage(
      from: 7,
      channel: channel,
      text: text,
      timestamp: DateTime.utc(2026, 1, 1).add(Duration(seconds: seconds)),
    );

Future<void> _settle() =>
    Future<void>.delayed(const Duration(milliseconds: 80));

Future<(MeshChatController, FakeMeshService)> _controller(Database db) async {
  final service = FakeMeshService();
  final settings = SettingsStore.inMemory();
  final controller = MeshChatController(
    service,
    MeshLink(service, settings),
    MeshStore(db),
  );
  await _settle();
  return (controller, service);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(sqfliteFfiInit);

  group('unread', () {
    test('accrues off-screen, never on-screen, never for own sends', () async {
      final db = await _open();
      addTearDown(db.close);
      final (controller, service) = await _controller(db);
      controller.markVisible(0);

      service.messages.add(_incoming('here', 0, seconds: 1));
      service.messages.add(_incoming('elsewhere', 2, seconds: 2));
      await _settle();

      expect(controller.unreadByChannel[0], isNull, reason: 'was on screen');
      expect(controller.unreadByChannel[2], 1);

      await controller.send('mine', channel: 2);
      await _settle();
      expect(
        controller.unreadByChannel[2],
        1,
        reason: 'the user has read what they typed',
      );
      controller.dispose();
    });

    test(
      'opening the conversation clears it, and the position persists',
      () async {
        final db = await _open();
        addTearDown(db.close);
        final (first, service) = await _controller(db);
        first.markVisible(0);
        service.messages.add(_incoming('unseen', 2, seconds: 5));
        await _settle();
        expect(first.unreadByChannel[2], 1);

        first.markVisible(2); // the user opens the conversation
        await _settle();
        expect(first.unreadByChannel[2], isNull);
        first.dispose();

        // A fresh session over the same store: still read.
        final (second, _) = await _controller(db);
        expect(
          second.unreadByChannel[2],
          isNull,
          reason: 'the read position did not survive the restart',
        );
        second.dispose();
      },
    );
  });

  group('the divider', () {
    test('snapshots where new began, before reading clears it', () async {
      final db = await _open();
      addTearDown(db.close);
      final (controller, service) = await _controller(db);
      controller.markVisible(0);
      service.messages.add(_incoming('old, read', 2, seconds: 1));
      await _settle();
      controller.markVisible(2); // read it, then leave
      controller.markVisible(0);
      service.messages.add(_incoming('new, unseen', 2, seconds: 60));
      await _settle();

      controller.markVisible(2);
      // The line sits at the read position as it stood on entry — between
      // "old, read" and "new, unseen" — even though entering has already
      // marked everything read. Deriving it live from last_read would erase
      // the line in the same frame it appeared.
      final divider = controller.unreadDividerTs(2);
      expect(divider, isNotNull);
      expect(divider, DateTime.utc(2026, 1, 1, 0, 0, 1).millisecondsSinceEpoch);
      expect(controller.unreadByChannel[2], isNull, reason: 'already read');
    });

    test('holds for the visit, clears on leaving', () async {
      final db = await _open();
      addTearDown(db.close);
      final (controller, service) = await _controller(db);
      controller.markVisible(0);
      service.messages.add(_incoming('unseen', 2, seconds: 5));
      await _settle();

      controller.markVisible(2);
      expect(controller.unreadDividerTs(2), isNotNull);
      // Still there mid-visit; gone once the user moves on.
      controller.markVisible(0);
      expect(controller.unreadDividerTs(2), isNull);
      // And re-entering with nothing new shows no line.
      controller.markVisible(2);
      expect(controller.unreadDividerTs(2), isNull);
    });

    test('no unread, no line', () async {
      final db = await _open();
      addTearDown(db.close);
      final (controller, _) = await _controller(db);
      controller.markVisible(2);
      expect(controller.unreadDividerTs(2), isNull);
    });
  });

  group('offline history', () {
    test('a busy channel cannot evict a quiet one from the window', () async {
      final db = await _open();
      addTearDown(db.close);
      final store = MeshStore(db);
      // One quiet message, then a full window of noise on another channel,
      // all newer.
      await store.addMessage(
        MeshStoredMessage(
          from: 1,
          channel: 2,
          text: 'the quiet conversation',
          timestamp: DateTime.utc(2026, 1, 1),
          outgoing: false,
        ),
      );
      for (var i = 0; i < MeshChatController.windowSize + 10; i++) {
        await store.addMessage(
          MeshStoredMessage(
            from: 1,
            channel: 0,
            text: 'noise $i',
            timestamp: DateTime.utc(2026, 1, 2).add(Duration(seconds: i)),
            outgoing: false,
          ),
        );
      }

      final (controller, _) = await _controller(db);
      // The old single global window held only the newest 300 overall, so the
      // quiet channel opened empty offline — which read as its history having
      // landed in some other channel.
      expect(
        controller.messages.where((m) => m.channel == 2).length,
        1,
        reason: 'the quiet conversation lost its history to the busy one',
      );
      controller.dispose();
    });

    test('legacy hash-channel rows are pruned, not offered as CH242', () async {
      final db = await _open();
      addTearDown(db.close);
      // A row written before the channel-hash guard: `channel` holds a hash.
      await db.insert('mesh_messages', {
        'ts': DateTime.utc(2026, 1, 1).millisecondsSinceEpoch,
        'node': 7,
        'channel': 242,
        'text': 'foreign',
        'outgoing': 0,
      });
      final store = MeshStore(db);
      await store.prune();
      expect(
        await store.messageCountsByChannel(),
        isNot(contains(242)),
        reason: 'the phantom conversation survived the prune',
      );
    });
  });

  group('the disconnected default', () {
    test('the DPIP slot survives a restart, not just a drop', () async {
      final service = FakeMeshService();
      final settings = SettingsStore.inMemory({'meshtastic.dpipChannel': 2});
      final link = MeshLink(service, settings)..start();
      // Fresh process, nothing connected: the remembered slot is what lets
      // the chat page default to the DPIP conversation instead of whatever
      // sorts first — the in-memory copy only survived a drop, which made a
      // relaunch open a different channel than a disconnect did.
      expect(link.lastKnownDpipChannel, 2);
    });

    test('forgetting the radio forgets its slot', () async {
      final service = FakeMeshService();
      final settings = SettingsStore.inMemory({'meshtastic.dpipChannel': 2});
      final link = MeshLink(service, settings)..start();
      await link.detach();
      expect(link.lastKnownDpipChannel, isNull);
      expect(settings.getInt(SettingKeys.meshDpipChannel), isNull);
    });
  });
}
