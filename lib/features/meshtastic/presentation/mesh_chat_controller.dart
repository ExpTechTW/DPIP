/// Presentation state for the mesh page: connection, nodes, and the message
/// log.
///
/// Lives in the provider tree rather than in the page's `State` for two
/// reasons: the radio keeps delivering while the page is closed, and the last
/// [MeshChatController.maxMessages] messages are persisted, so the log survives
/// navigation *and* an app restart. That persistence is not a nicety — the
/// radio's own replay queue is small, shared with telemetry/position traffic,
/// and emptied once read, so it can never be the app's message history.
///
/// The controller owns no BLE: it only listens to [MeshtasticService] and
/// turns its streams into a snapshot the page renders.
library;

import 'dart:async';
import 'dart:convert';

import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/meshtastic/domain/meshtastic_service.dart';
import 'package:dpip/core/meshtastic/mesh_link.dart';
import 'package:dpip/core/realtime/app_time.dart';
import 'package:dpip/core/settings/preference_keys.dart';
import 'package:dpip/core/settings/prefs.dart';
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

  /// Restores a message written by [toJson]; returns null for anything
  /// unreadable, so one corrupt entry can't take the whole log down.
  static MeshChatMessage? fromJson(String encoded) {
    try {
      final json = jsonDecode(encoded);
      if (json is! Map<String, dynamic>) return null;
      return MeshChatMessage(
        from: (json['f'] as num?)?.toInt() ?? 0,
        channel: (json['c'] as num?)?.toInt() ?? 0,
        text: json['t'] as String? ?? '',
        timestamp: DateTime.fromMillisecondsSinceEpoch(
          (json['ts'] as num?)?.toInt() ?? 0,
        ),
        outgoing: json['o'] as bool? ?? false,
      );
    } catch (_) {
      return null;
    }
  }

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

  String toJson() => jsonEncode({
    'f': from,
    'c': channel,
    't': text,
    'ts': timestamp.millisecondsSinceEpoch,
    'o': outgoing,
  });

  /// Identity used to drop a message the log already holds — a reconnect can
  /// replay a packet that was stored during the previous session.
  String get _identity =>
      '$from/$channel/${timestamp.millisecondsSinceEpoch}/$text';
}

class MeshChatController extends ChangeNotifier {
  MeshChatController(this._service, this._link, this._prefs) {
    _restore();
    _nodeSub = _service.nodeStream.listen(_onNode);
    _messageSub = _service.messageStream.listen(_onMessage);
  }

  /// How many messages the log keeps, in memory and on disk.
  static const int maxMessages = 50;

  final MeshtasticService _service;

  /// Connection lifecycle lives in [MeshLink] (app-wide, survives this page);
  /// this controller only owns the conversation.
  final MeshLink _link;
  final Prefs _prefs;

  StreamSubscription<MeshNode>? _nodeSub;
  StreamSubscription<MeshMessage>? _messageSub;
  StreamSubscription<MeshDevice>? _scanSub;

  final Map<int, MeshNode> _nodes = {};
  final List<MeshChatMessage> _messages = [];
  final List<MeshDevice> _devices = [];
  bool _scanning = false;
  String? _connectingId;
  String? _scanError;

  /// Whether the radio is connected *and* configured — the only state in which
  /// sending works. Owned by [MeshLink]; mirrored here so the composer doesn't
  /// need both objects.
  bool get isConnected => _link.isConnected;

  /// The message log, **newest first** (the page renders it reversed).
  List<MeshChatMessage> get messages => List.unmodifiable(_messages);

  /// Every node heard so far, online first, then most-recently-heard.
  List<MeshNode> get nodes {
    final all = _nodes.values.toList()
      ..sort((a, b) {
        if (a.isOnline != b.isOnline) return a.isOnline ? -1 : 1;
        final aHeard = a.lastHeard, bHeard = b.lastHeard;
        if (aHeard != null && bHeard != null) return bHeard.compareTo(aHeard);
        if (aHeard != null) return -1;
        if (bHeard != null) return 1;
        return a.displayName.compareTo(b.displayName);
      });
    return List.unmodifiable(all);
  }

  /// Radios found by the current/last scan.
  List<MeshDevice> get devices => List.unmodifiable(_devices);

  bool get scanning => _scanning;

  /// Id of the device a connect is in flight for, so its row can show it.
  String? get connectingId => _connectingId;

  /// Why the last scan failed (permission denied, adapter off), else null.
  String? get scanError => _scanError;

  /// The sender's node name once the mesh has told us about it, else its id.
  String senderLabel(int num) {
    final name = _nodes[num]?.displayName;
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

  /// Broadcasts [text] on the primary channel and records it locally — the
  /// radio does not echo our own packets back. Returns null on success.
  Future<String?> send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;
    final result = await _service.sendText(trimmed);
    if (result case Err(:final failure)) return failure.message;
    _add(
      MeshChatMessage(
        from: 0,
        channel: 0,
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
    notifyListeners();
    unawaited(_persist());
  }

  void _onNode(MeshNode node) {
    _nodes[node.num] = node;
    notifyListeners();
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
    if (_messages.any((m) => m._identity == message._identity)) return;
    _messages.insert(0, message);
    if (_messages.length > maxMessages) {
      _messages.removeRange(maxMessages, _messages.length);
    }
    notifyListeners();
    unawaited(_persist());
  }

  void _restore() {
    final stored = _prefs.getStringList(PreferenceKeys.meshMessages);
    if (stored == null) return;
    for (final entry in stored.take(maxMessages)) {
      final message = MeshChatMessage.fromJson(entry);
      if (message != null) _messages.add(message);
    }
    Log.debug('mesh chat: restored ${_messages.length} message(s)');
  }

  Future<void> _persist() async {
    try {
      await _prefs.setStringList(PreferenceKeys.meshMessages, [
        for (final message in _messages) message.toJson(),
      ]);
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'mesh chat persist');
    }
  }

  @override
  void dispose() {
    unawaited(_nodeSub?.cancel());
    unawaited(_messageSub?.cancel());
    unawaited(_scanSub?.cancel());
    super.dispose();
  }
}
