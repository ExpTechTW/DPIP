/// The mesh's node table, kept across reconnects and app restarts.
///
/// The radio hands over its whole node DB on every connect, so nothing here is
/// needed to *see* nodes while attached. It exists for the times you are not:
/// after a drop, before the first connect of a session, or with no radio at
/// all, the last known mesh is still the most useful thing the app can show —
/// which repeaters exist, roughly where they are, and when each was last heard.
///
/// Lives in `core/` because two unrelated surfaces consume it (the mesh page's
/// node list and the map's node layer) and neither may reach into the other's
/// feature.
library;

import 'dart:async';
import 'dart:convert';

import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/meshtastic/domain/meshtastic_service.dart';
import 'package:dpip/core/realtime/app_time.dart';
import 'package:dpip/core/settings/preference_keys.dart';
import 'package:dpip/core/settings/prefs.dart';
import 'package:flutter/foundation.dart';

class MeshNodeStore extends ChangeNotifier {
  MeshNodeStore(this._service, this._prefs, {DateTime Function()? now})
    : _now = now ?? (() => AppTime.utc.toLocal());

  /// How many nodes are kept. A busy region's mesh runs to a few hundred; the
  /// least-recently-heard are dropped first, because a node nobody has heard
  /// from in weeks is the one least worth remembering.
  static const int maxNodes = 250;

  /// How long after its last transmission a node still counts as online. The
  /// firmware uses the same window for its own node list.
  static const Duration onlineWindow = Duration(minutes: 15);

  /// Node bursts arrive twenty at a time during a config download; writing on
  /// each one would mean twenty serialisations of the whole table.
  static const Duration _writeDebounce = Duration(seconds: 2);

  final MeshtasticService _service;
  final Prefs _prefs;
  final DateTime Function() _now;

  StreamSubscription<MeshNode>? _sub;
  Timer? _writeTimer;
  final Map<int, MeshNode> _nodes = {};
  bool _excludeMqtt = true;

  /// Whether MQTT-only nodes are kept off the map.
  ///
  /// **On by default**, and that default is the honest one: a node heard only
  /// through an MQTT bridge arrived over the internet, so its marker says
  /// nothing about what this radio can actually reach. Left in, a Taiwanese
  /// mesh sprouts nodes in Japan and the United States and the map stops
  /// answering the question it exists to answer.
  bool get excludeMqtt => _excludeMqtt;

  Future<void> setExcludeMqtt({required bool exclude}) async {
    if (_excludeMqtt == exclude) return;
    _excludeMqtt = exclude;
    notifyListeners();
    await _prefs.setBool(PreferenceKeys.meshExcludeMqtt, exclude);
  }

  /// Every node known, online first, then most-recently-heard.
  List<MeshNode> get nodes {
    final all = _nodes.values.toList()
      ..sort((a, b) {
        final aOnline = isOnline(a);
        final bOnline = isOnline(b);
        if (aOnline != bOnline) return aOnline ? -1 : 1;
        final aHeard = a.lastHeard, bHeard = b.lastHeard;
        if (aHeard != null && bHeard != null) return bHeard.compareTo(aHeard);
        if (aHeard != null) return -1;
        if (bHeard != null) return 1;
        return a.displayName.compareTo(b.displayName);
      });
    return List.unmodifiable(all);
  }

  /// The nodes the map can draw: they have a position, and — unless
  /// [excludeMqtt] is off — they were heard over the air rather than through
  /// an MQTT bridge.
  List<MeshNode> get positioned => [
    for (final node in _nodes.values)
      if (node.latitude != null && node.longitude != null)
        if (!_excludeMqtt || !node.viaMqtt) node,
  ];

  /// How many positioned nodes [excludeMqtt] is currently hiding — so the UI
  /// can say what it left out instead of silently showing less.
  int get hiddenMqttCount {
    if (!_excludeMqtt) return 0;
    return _nodes.values
        .where((n) => n.latitude != null && n.longitude != null && n.viaMqtt)
        .length;
  }

  MeshNode? byNum(int num) => _nodes[num];

  /// Whether [node] counts as online **right now**.
  ///
  /// Derived, never read from storage: a node persisted as online yesterday is
  /// not online today, and a stored flag would say otherwise for as long as
  /// the app went without hearing from it.
  bool isOnline(MeshNode node) {
    final heard = node.lastHeard;
    if (heard == null) return false;
    return _now().difference(heard) < onlineWindow;
  }

  void start() {
    _excludeMqtt = _prefs.getBool(PreferenceKeys.meshExcludeMqtt) ?? true;
    _restore();
    _sub ??= _service.nodeStream.listen(_onNode);
  }

  /// Forgets every node, on screen and on disk.
  Future<void> clear() async {
    if (_nodes.isEmpty) return;
    _nodes.clear();
    notifyListeners();
    _writeTimer?.cancel();
    await _persist();
  }

  void _onNode(MeshNode node) {
    final existing = _nodes[node.num];
    // A node re-emitted from a telemetry packet carries fresh metrics but may
    // carry no position; keep the last one we were told rather than dropping
    // the node off the map.
    _nodes[node.num] = existing == null
        ? node
        : MeshNode(
            num: node.num,
            displayName: node.displayName.isNotEmpty
                ? node.displayName
                : existing.displayName,
            isOnline: node.isOnline,
            batteryLevel: node.batteryLevel ?? existing.batteryLevel,
            lastHeard: node.lastHeard ?? existing.lastHeard,
            latitude: node.latitude ?? existing.latitude,
            longitude: node.longitude ?? existing.longitude,
            snr: node.snr != 0 ? node.snr : existing.snr,
            viaMqtt: node.viaMqtt,
          );
    notifyListeners();
    _scheduleWrite();
  }

  void _scheduleWrite() {
    _writeTimer?.cancel();
    _writeTimer = Timer(_writeDebounce, () {
      _writeTimer = null;
      unawaited(_persist());
    });
  }

  void _restore() {
    final stored = _prefs.getStringList(PreferenceKeys.meshNodes);
    if (stored == null) return;
    for (final entry in stored) {
      final node = _decode(entry);
      if (node != null) _nodes[node.num] = node;
    }
    Log.debug('mesh nodes: restored ${_nodes.length}');
  }

  Future<void> _persist() async {
    try {
      // Keep the most recently heard when trimming: an old node is the one the
      // mesh has already forgotten.
      final ordered = _nodes.values.toList()
        ..sort((a, b) {
          final aHeard = a.lastHeard, bHeard = b.lastHeard;
          if (aHeard == null && bHeard == null) return 0;
          if (aHeard == null) return 1;
          if (bHeard == null) return -1;
          return bHeard.compareTo(aHeard);
        });
      await _prefs.setStringList(PreferenceKeys.meshNodes, [
        for (final node in ordered.take(maxNodes)) _encode(node),
      ]);
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'mesh nodes persist');
    }
  }

  String _encode(MeshNode node) => jsonEncode({
    'n': node.num,
    'd': node.displayName,
    if (node.batteryLevel != null) 'b': node.batteryLevel,
    if (node.lastHeard != null) 'h': node.lastHeard!.millisecondsSinceEpoch,
    if (node.latitude != null) 'la': node.latitude,
    if (node.longitude != null) 'lo': node.longitude,
    if (node.snr != 0) 's': node.snr,
    if (node.viaMqtt) 'm': true,
  });

  MeshNode? _decode(String encoded) {
    try {
      final json = jsonDecode(encoded);
      if (json is! Map<String, dynamic>) return null;
      final nodeNum = (json['n'] as num?)?.toInt();
      if (nodeNum == null) return null;
      final heard = (json['h'] as num?)?.toInt();
      final lastHeard = heard == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(heard);
      return MeshNode(
        num: nodeNum,
        displayName: json['d'] as String? ?? '',
        // Recomputed from `lastHeard`, never restored — see [isOnline].
        isOnline:
            lastHeard != null && _now().difference(lastHeard) < onlineWindow,
        batteryLevel: (json['b'] as num?)?.toInt(),
        lastHeard: lastHeard,
        latitude: (json['la'] as num?)?.toDouble(),
        longitude: (json['lo'] as num?)?.toDouble(),
        snr: (json['s'] as num?)?.toDouble() ?? 0,
        viaMqtt: json['m'] as bool? ?? false,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _writeTimer?.cancel();
    unawaited(_sub?.cancel());
    super.dispose();
  }
}
