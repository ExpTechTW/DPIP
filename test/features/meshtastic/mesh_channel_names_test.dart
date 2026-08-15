/// Channel names outlive the radio that reported them.
///
/// A channel's name arrives once, in the config download, and lives nowhere
/// else — so the moment the radio disconnects (or before it finishes
/// configuring, which is most of a cold start) the chat screen had nothing to
/// call it and fell back to its slot number. A conversation the user knows as
/// "DPIP" showed up as "CH2".
///
/// The stored log outlives the connection, so its labels have to as well. The
/// node table already worked this way; the channel table did not.
library;

import 'package:dpip/core/meshtastic/data/mesh_store.dart';
import 'package:dpip/core/meshtastic/domain/meshtastic_service.dart';
import 'package:dpip/core/meshtastic/mesh_link.dart';
import 'package:dpip/core/meshtastic/mesh_node_store.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:dpip/features/meshtastic/presentation/mesh_chat_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../core/meshtastic/fake_mesh_service.dart';

/// A service whose channel table can be set and cleared, the way a radio's is
/// by connecting and disconnecting.
class _ChannelService extends FakeMeshService {
  List<MeshChannel> table = const [];

  @override
  List<MeshChannel> get channels => table;
}

MeshChannel _channel(int index, String name) =>
    MeshChannel(index: index, name: name, psk: const [1], enabled: true);

Future<Database> _open() async {
  // `singleInstance: false`: sqflite hands back the same handle for a repeated
  // path, and `:memory:` is a path — without it every test here shares one
  // database and tearDown closes the handle the next one is about to use.
  final db = await databaseFactoryFfi.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(singleInstance: false),
  );
  await MeshStore.createSchema(db);
  return db;
}

Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 60));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(sqfliteFfiInit);

  test('a name reported by the radio is remembered', () async {
    final db = await _open();
    addTearDown(db.close);
    final service = _ChannelService()..table = [_channel(2, 'DPIP')];
    final settings = SettingsStore.inMemory();
    final controller = MeshChatController(
      service,
      MeshLink(service, settings),
      MeshNodeStore(service, settings),
      MeshStore(db),
    );
    await settle();

    // The config download lands: the connection stream is what says so.
    service.connections.add(
      const MeshConnectionStatus(state: MeshConnectionState.connected),
    );
    await settle();

    expect(controller.channelNames[2], 'DPIP');
    expect(await MeshStore(db).readChannels(), {
      2: 'DPIP',
    }, reason: 'the name has to survive the process, not just the connection');
    controller.dispose();
  });

  test('the name survives a restart with no radio at all', () async {
    final db = await _open();
    addTearDown(db.close);
    await MeshStore(db).writeChannels({2: 'DPIP'});

    // A fresh session, nothing connected — exactly the cold start that used to
    // show CH2.
    final service = _ChannelService();
    final settings = SettingsStore.inMemory();
    final controller = MeshChatController(
      service,
      MeshLink(service, settings),
      MeshNodeStore(service, settings),
      MeshStore(db),
    );
    await settle();

    expect(service.channels, isEmpty, reason: 'no radio to ask');
    expect(controller.channelNames[2], 'DPIP');
    controller.dispose();
  });

  test('a partial config download never blanks a known name', () async {
    // The table arrives one slot at a time. A snapshot taken mid-download is
    // incomplete, and replacing the map with it would drop names already known
    // and flicker the labels back to slot numbers while connecting.
    final db = await _open();
    addTearDown(db.close);
    final service = _ChannelService()..table = [_channel(2, 'DPIP')];
    final settings = SettingsStore.inMemory();
    final controller = MeshChatController(
      service,
      MeshLink(service, settings),
      MeshNodeStore(service, settings),
      MeshStore(db),
    );
    await settle();
    service.connections.add(
      const MeshConnectionStatus(state: MeshConnectionState.connected),
    );
    await settle();
    expect(controller.channelNames[2], 'DPIP');

    // A reconnect whose download has only reached slot 0 so far.
    service.table = [_channel(0, 'LongFast')];
    service.connections.add(
      const MeshConnectionStatus(state: MeshConnectionState.connected),
    );
    await settle();

    expect(controller.channelNames[0], 'LongFast');
    expect(controller.channelNames[2], 'DPIP', reason: 'blanked mid-download');
    controller.dispose();
  });

  test('an unnamed slot is not remembered as a blank', () async {
    // Storing an empty name would let a stale blank outrank a real name that
    // arrives later.
    final db = await _open();
    addTearDown(db.close);
    final store = MeshStore(db);
    await store.writeChannels({1: '', 2: 'DPIP'});
    expect(await store.readChannels(), {2: 'DPIP'});
  });

  test('the table is replaced, not merged', () async {
    // The radio always reports every slot, so merging would keep the name of a
    // channel the user has since deleted.
    final db = await _open();
    addTearDown(db.close);
    final store = MeshStore(db);
    await store.writeChannels({1: 'Old', 2: 'DPIP'});
    await store.writeChannels({2: 'DPIP'});
    expect(await store.readChannels(), {2: 'DPIP'});
  });

  group('a channel hash is not a channel index', () {
    // `MeshPacket.channel` carries the channel *index* on a packet the radio
    // decrypted, and the channel *hash* on one it could not. The numbers below
    // are real, off the air: 242, 92, 227 all arrived on a Taiwan mesh in one
    // ten-minute capture, from foreign encrypted traffic.
    test('rejects the hashes seen on air', () {
      for (final hash in [242, 92, 102, 227, 71, 255, 8]) {
        expect(
          isMeshChannelIndex(hash),
          isFalse,
          reason: '$hash would invent a conversation called CH$hash',
        );
      }
    });

    test('accepts every real slot', () {
      for (var index = 0; index < meshChannelSlots; index++) {
        expect(isMeshChannelIndex(index), isTrue);
      }
      expect(meshChannelSlots, 8, reason: 'fixed by the firmware');
    });

    test('rejects a negative, which no field should ever hold', () {
      expect(isMeshChannelIndex(-1), isFalse);
    });
  });
}
