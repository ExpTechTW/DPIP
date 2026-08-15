/// Presentation state for the mesh page: connection, nodes, and the message
/// log.
///
/// Lives in the provider tree rather than in the page's `State` for two
/// reasons: the radio keeps delivering while the page is closed, and the log is
/// persisted (in SQLite — see [MeshStore]), so it survives navigation *and* an
/// app restart. That persistence is not a nicety — the radio's own replay queue
/// is small, shared with telemetry/position traffic, and emptied once read, so
/// it can never be the app's message history.
///
/// The in-memory list is a **window** onto that store, not the log itself: the
/// newest [MeshChatController.windowSize] messages, which is what a chat screen
/// can show. Retention lives in the store.
///
/// The controller owns no BLE: it only listens to [MeshtasticService] and
/// turns its streams into a snapshot the page renders.
library;

import 'dart:async';

import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/meshtastic/domain/meshtastic_service.dart';
import 'package:dpip/core/meshtastic/mesh_link.dart';
import 'package:dpip/core/meshtastic/mesh_node_store.dart';
import 'package:dpip/core/realtime/app_time.dart';
import 'package:dpip/core/meshtastic/data/mesh_store.dart';
import 'package:flutter/foundation.dart';

/// One line in the message log — a packet heard from the mesh, or a message
/// this device sent ([outgoing]).
@immutable
class MeshChatMessage {
  const MeshChatMessage({
    required this.from,
    required this.channel,
    required this.text,
    required this.timestamp,
    this.outgoing = false,
  });

  /// Adapts a stored row.
  MeshChatMessage.stored(MeshStoredMessage row)
    : from = row.from,
      channel = row.channel,
      text = row.text,
      timestamp = row.timestamp,
      outgoing = row.outgoing;

  /// Sender node number (0 for [outgoing] — the local radio's own number is
  /// not part of the transport's surface, and the bubble never shows it).
  final int from;

  /// Mesh channel index the message travelled on (0 = primary).
  final int channel;

  final String text;
  final DateTime timestamp;

  /// Whether this device sent it (the radio does not echo our own packets
  /// back, so a sent message is recorded locally).
  final bool outgoing;

  MeshStoredMessage toStored() => MeshStoredMessage(
    from: from,
    channel: channel,
    text: text,
    timestamp: timestamp,
    outgoing: outgoing,
  );
}

class MeshChatController extends ChangeNotifier {
  MeshChatController(this._service, this._link, this._nodes, this._store) {
    unawaited(_restore());
    // Nodes come from the shared store, which persists them — this page is one
    // of two surfaces showing the same table (the map layer is the other).
    _nodes.addListener(notifyListeners);
    _messageSub = _service.messageStream.listen(_onMessage);
    // The radio reports its channel table during the config download; capture
    // the names each time so the log stays labelled after it disconnects.
    _connectionSub = _service.connectionStream.listen(
      (_) => _rememberChannels(),
    );
  }

  /// How many messages the in-memory window holds. Not a retention limit —
  /// the store keeps far more (see [MeshStore.messageRetention]); this is just
  /// how much of it a chat screen keeps materialised.
  static const int windowSize = 300;

  final MeshtasticService _service;

  /// Connection lifecycle lives in [MeshLink] (app-wide, survives this page);
  /// this controller only owns the conversation.
  final MeshLink _link;
  final MeshNodeStore _nodes;

  /// Null when the database couldn't be opened — the log then lives only for
  /// this session rather than the page failing to work at all.
  final MeshStore? _store;

  StreamSubscription<MeshMessage>? _messageSub;
  StreamSubscription<MeshConnectionStatus>? _connectionSub;
  StreamSubscription<MeshDevice>? _scanSub;

  final List<MeshChatMessage> _messages = [];
  final Map<int, int> _counts = {};
  final List<MeshDevice> _devices = [];
  bool _scanning = false;
  String? _connectingId;
  String? _scanError;

  /// Whether the radio is connected *and* configured — the only state in which
  /// sending works. Owned by [MeshLink]; mirrored here so the composer doesn't
  /// need both objects.
  bool get isConnected => _link.isConnected;

  /// How many stored messages each channel holds — what the channel tabs
  /// badge, so a quiet channel with history is distinguishable from an empty
  /// one.
  /// The last 24 hours of utilization samples, oldest first — what the chart
  /// plots. Read on demand rather than held: it is only looked at when the
  /// radio panel is open.
  Future<List<MeshMetricSample>> metricsHistory() async =>
      await _store?.metrics() ?? const [];

  /// Counted in SQL at load and kept up to date locally, so a channel whose
  /// history falls outside the in-memory window still reports its real total.
  Map<int, int> get messageCountsByChannel => Map.unmodifiable(_counts);

  /// Channel index → the name last reported by a radio.
  ///
  /// A channel's name arrives only in the config download, so between
  /// connections the radio cannot be asked. Without this the chat screen fell
  /// back to the slot number — a conversation the user knows as "DPIP" showing
  /// as "CH2" whenever the page was opened before the radio finished
  /// configuring, which is most of the time on a cold start.
  Map<int, String> get channelNames => Map.unmodifiable(_channelNames);

  final Map<int, String> _channelNames = {};

  /// Records the radio's channel names, if it has reported any yet.
  ///
  /// Only ever *adds* names. The table arrives one slot at a time, so a
  /// snapshot taken mid-download is partial; replacing the map with it would
  /// blank out names that are already known and make the labels flicker back
  /// to slot numbers while connecting.
  Future<void> _rememberChannels() async {
    final named = <int, String>{
      for (final channel in _service.channels)
        if (channel.name.isNotEmpty) channel.index: channel.name,
    };
    if (named.isEmpty) return;
    var changed = false;
    for (final entry in named.entries) {
      if (_channelNames[entry.key] == entry.value) continue;
      _channelNames[entry.key] = entry.value;
      changed = true;
    }
    if (!changed) return;
    notifyListeners();
    await _store?.writeChannels(_channelNames);
  }

  /// The message log, **newest first** (the page renders it reversed).
  List<MeshChatMessage> get messages => List.unmodifiable(_messages);

  /// Every node heard so far, online first, then most-recently-heard.
  List<MeshNode> get nodes => _nodes.nodes;

  /// Node count without the sorted-list construction — for the page badge,
  /// which rebuilds on every packet.
  int get nodeCount => _nodes.count;

  /// Whether [node] has been heard recently enough to count as online.
  bool isOnline(MeshNode node) => _nodes.isOnline(node);

  /// Radios found by the current/last scan.
  List<MeshDevice> get devices => List.unmodifiable(_devices);

  bool get scanning => _scanning;

  /// Id of the device a connect is in flight for, so its row can show it.
  String? get connectingId => _connectingId;

  /// Why the last scan failed (permission denied, adapter off), else null.
  String? get scanError => _scanError;

  /// The sender's node name once the mesh has told us about it, else its id.
  String senderLabel(int num) {
    final name = _nodes.byNum(num)?.displayName;
    return (name != null && name.isNotEmpty)
        ? name
        : '0x${num.toRadixString(16)}';
  }

  /// Starts a scan, replacing the previous results. Safe to call repeatedly —
  /// a running scan is cancelled first.
  Future<void> startScan() async {
    await _scanSub?.cancel();
    _scanSub = null;
    _devices.clear();
    _scanError = null;
    _scanning = true;
    notifyListeners();

    final completion = Completer<void>();
    _scanSub = _service.scanForDevices().listen(
      (device) {
        if (_devices.any((d) => d.id == device.id)) return;
        _devices.add(device);
        notifyListeners();
      },
      onError: (Object error, StackTrace stackTrace) {
        Log.handle(error, stackTrace, 'mesh scan');
        // A scan/init failure arrives as a StateError carrying the underlying
        // failure's message (which permission was denied, adapter off …).
        _scanError = error is StateError && error.message.isNotEmpty
            ? error.message
            : '$error';
        _scanning = false;
        notifyListeners();
        if (!completion.isCompleted) completion.complete();
      },
      onDone: () {
        _scanning = false;
        notifyListeners();
        if (!completion.isCompleted) completion.complete();
      },
      cancelOnError: true,
    );
    return completion.future;
  }

  /// Stops a running scan (e.g. the picker was dismissed).
  Future<void> stopScan() async {
    await _scanSub?.cancel();
    _scanSub = null;
    if (!_scanning) return;
    _scanning = false;
    notifyListeners();
  }

  /// Adopts [device] as the app's radio — [MeshLink] then keeps it attached
  /// for the rest of the app's life, page changes included.
  ///
  /// Returns null on success, [MeshLink.busySentinel] when another app holds
  /// the radio (the caller asks the user, then retries with [force]), else a
  /// message to show.
  Future<String?> connect(MeshDevice device, {bool force = false}) async {
    _connectingId = device.id;
    notifyListeners();
    final failure = await _link.attach(device, force: force);
    _connectingId = null;
    notifyListeners();
    return failure;
  }

  /// Forgets the radio and disconnects — the only thing that stops
  /// reconnection short of closing the app.
  Future<String?> disconnect() async {
    await _link.detach();
    return null;
  }

  /// Broadcasts [text] on [channel] and records it locally — the radio does
  /// not echo our own packets back. Returns null on success.
  Future<String?> send(String text, {int channel = 0}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;
    final result = await _service.sendText(trimmed, channel: channel);
    if (result case Err(:final failure)) return failure.message;
    _add(
      MeshChatMessage(
        from: 0,
        channel: channel,
        text: trimmed,
        timestamp: AppTime.utc.toLocal(),
        outgoing: true,
      ),
    );
    return null;
  }

  /// Empties the log, on screen and on disk.
  void clearMessages() {
    if (_messages.isEmpty) return;
    _messages.clear();
    _counts.clear();
    notifyListeners();
    unawaited(_store?.clearMessages());
  }

  void _onMessage(MeshMessage message) {
    _add(
      MeshChatMessage(
        from: message.from,
        channel: message.channel,
        text: message.text,
        timestamp: message.timestamp,
      ),
    );
  }

  void _add(MeshChatMessage message) {
    final store = _store;
    if (store == null) {
      // No database: fall back to an in-memory log, deduplicated here instead
      // of by the store's unique index.
      if (_messages.any((m) => _sameMessage(m, message))) return;
      _remember(message);
      return;
    }
    unawaited(
      store.addMessage(message.toStored()).then((isNew) {
        // A reconnect replays packets the log may already hold; the store's
        // unique index is what decides, so the UI follows its answer.
        if (isNew) _remember(message);
      }),
    );
  }

  void _remember(MeshChatMessage message) {
    _messages.insert(0, message);
    if (_messages.length > windowSize) {
      _messages.removeRange(windowSize, _messages.length);
    }
    _counts[message.channel] = (_counts[message.channel] ?? 0) + 1;
    notifyListeners();
  }

  bool _sameMessage(MeshChatMessage a, MeshChatMessage b) =>
      a.from == b.from &&
      a.channel == b.channel &&
      a.timestamp == b.timestamp &&
      a.text == b.text;

  Future<void> _restore() async {
    final store = _store;
    if (store == null) return;
    final rows = await store.messages(limit: windowSize);
    _messages
      ..clear()
      ..addAll([for (final row in rows) MeshChatMessage.stored(row)]);
    _counts
      ..clear()
      ..addAll(await store.messageCountsByChannel());
    _channelNames
      ..clear()
      ..addAll(await store.readChannels());
    Log.debug(
      'mesh chat: loaded ${_messages.length} message(s), '
      '${_channelNames.length} channel name(s)',
    );
    notifyListeners();
  }

  @override
  void dispose() {
    _nodes.removeListener(notifyListeners);
    unawaited(_messageSub?.cancel());
    unawaited(_connectionSub?.cancel());
    unawaited(_scanSub?.cancel());
    super.dispose();
  }
}
