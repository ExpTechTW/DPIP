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
import 'dart:math' as math;

import 'package:dpip/core/geo/geo_math.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/meshtastic/data/mesh_store.dart';
import 'package:dpip/core/meshtastic/domain/meshtastic_service.dart';
import 'package:dpip/core/realtime/app_time.dart';
import 'package:dpip/core/settings/setting_keys.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:flutter/foundation.dart';

/// One point in a node's telemetry history — what the sheet's trend charts
/// plot. Kept in memory only (see [MeshNodeStore.historyLimit]).
///
/// [snr] is null when the node did not report a reading at that time — a gap
/// the trend must draw as a break, not bridge.
class MeshNodeSample {
  const MeshNodeSample({required this.time, this.snr, this.battery});

  final DateTime time;
  final double? snr;
  final int? battery;
}

// The store is handed in as a named parameter and copied to a private field;
// an initializing formal cannot be used because named parameters may not be
// private.
// ignore_for_file: prefer_initializing_formals
class MeshNodeStore extends ChangeNotifier {
  MeshNodeStore(
    this._service,
    this._settings, {
    MeshStore? store,
    DateTime Function()? now,
  }) : _store = store,
       _now = now ?? (() => AppTime.utc.toLocal());

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
  final SettingsStore _settings;

  /// Where the node table is persisted. Null in tests and when the database
  /// would not open — the store then keeps nodes for the session only.
  final MeshStore? _store;

  Future<void>? _restoring;

  /// Completes when the stored table has been read back.
  ///
  /// Restoring is a query now, so it finishes a moment after [start]. Callers
  /// that only draw can ignore this — the store notifies — but anything that
  /// needs the remembered mesh to be *there* has something to await instead of
  /// a delay chosen by guesswork.
  Future<void> get whenRestored => _restoring ?? Future<void>.value();
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
    await _settings.setBool(SettingKeys.meshExcludeMqtt, exclude);
  }

  /// Every node known, online first, then most-recently-heard.
  List<MeshNode> get nodes {
    // The online cutoff is resolved once, not per comparison: the comparator
    // runs O(n log n) times per access, this getter runs on every rebuild of
    // the mesh page, and the page rebuilds on every packet — recomputing
    // `now - lastHeard` inside the sort was thousands of DateTime subtractions
    // a second on a busy mesh, all answering the same question.
    final cutoff = _now().subtract(onlineWindow).millisecondsSinceEpoch;
    final all = _nodes.values.toList()
      ..sort((a, b) {
        final aHeard = a.lastHeard?.millisecondsSinceEpoch;
        final bHeard = b.lastHeard?.millisecondsSinceEpoch;
        final aOnline = aHeard != null && aHeard > cutoff;
        final bOnline = bHeard != null && bHeard > cutoff;
        if (aOnline != bOnline) return aOnline ? -1 : 1;
        if (aHeard != null && bHeard != null) return bHeard.compareTo(aHeard);
        if (aHeard != null) return -1;
        if (bHeard != null) return 1;
        return a.displayName.compareTo(b.displayName);
      });
    return List.unmodifiable(all);
  }

  /// How many nodes are known — for badges, without paying for the sort
  /// [nodes] does.
  int get count => _nodes.length;

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
    _excludeMqtt = _settings.getBool(SettingKeys.meshExcludeMqtt) ?? true;
    _restoring = _restore();
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
    _recordSample(node);
    notifyListeners();
    _scheduleWrite();
  }

  /// Keeps a node's recent telemetry so the sheet can draw trends.
  ///
  /// Memory-only on purpose: a ring of numbers is worth showing, not worth
  /// persisting — the radio re-sends the whole node DB on every connect
  /// anyway, and the sample cadence is the node's own broadcast rate
  /// (seconds to minutes), so a full ring is a long recent past.
  static const int historyLimit = 60;

  final Map<int, List<MeshNodeSample>> _history = {};

  /// This node's samples across the last day, oldest first: the persisted
  /// 2-minute series with the live in-memory ring appended for the freshest
  /// minutes the recorder has not written yet.
  ///
  /// The ring alone was the whole trend before the day series existed, and on
  /// a busy mesh its 60 slots covered only minutes — "when did that repeater
  /// start failing" needs the day.
  Future<List<MeshNodeSample>> dayHistoryOf(int num) async {
    final store = _store;
    final ring = historyOf(num);
    if (store == null) return ring;
    final persisted = await store.nodeMetrics(node: num);
    final ringStart = ring.isEmpty
        ? null
        : ring.first.time.millisecondsSinceEpoch;
    return [
      for (final sample in persisted)
        if (ringStart == null || sample.at.millisecondsSinceEpoch < ringStart)
          MeshNodeSample(
            time: sample.at,
            snr: sample.snr,
            battery: sample.battery,
          ),
      ...ring,
    ];
  }

  /// This node's recent (time, SNR, battery) samples, oldest first.
  List<MeshNodeSample> historyOf(int num) =>
      List.unmodifiable(_history[num] ?? const []);

  void _recordSample(MeshNode node) {
    final samples = _history.putIfAbsent(node.num, () => []);
    final last = samples.isNotEmpty ? samples.last : null;
    final time = _now();
    // A burst arrives twenty nodes at a time and the radio re-emits the same
    // telemetry repeatedly; a sample that changes nothing just moves the last
    // one's time instead of piling up identical points.
    if (last != null &&
        last.snr == node.snr &&
        last.battery == node.batteryLevel) {
      samples[samples.length - 1] = MeshNodeSample(
        time: time,
        snr: last.snr,
        battery: last.battery,
      );
      return;
    }
    samples.add(
      MeshNodeSample(time: time, snr: node.snr, battery: node.batteryLevel),
    );
    if (samples.length > historyLimit) {
      samples.removeRange(0, samples.length - historyLimit);
    }
  }

  /// Straight-line distance from this node to the radio's own node, km.
  ///
  /// The map's "how far is it" — computed here so the sheet stays a view.
  /// Null when either side has no position yet.
  double? distanceToMyRadioKm(MeshNode node) {
    final mine = _service.myNodeNum == null
        ? null
        : _nodes[_service.myNodeNum!];
    final a = mine;
    if (a == null ||
        a.latitude == null ||
        a.longitude == null ||
        node.latitude == null ||
        node.longitude == null) {
      return null;
    }
    return _haversineKm(
      a.latitude!,
      a.longitude!,
      node.latitude!,
      node.longitude!,
    );
  }

  /// Great-circle distance between two points (km) — short-range accuracy is
  /// all a mesh needs, and the formula stays cheap on every sample.
  static double _haversineKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadiusKm = 6371.0;
    final dLat = degToRad(lat2 - lat1);
    final dLon = degToRad(lon2 - lon1);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(degToRad(lat1)) *
            math.cos(degToRad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return earthRadiusKm * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  void _scheduleWrite() {
    _writeTimer?.cancel();
    _writeTimer = Timer(_writeDebounce, () {
      _writeTimer = null;
      unawaited(_persist());
    });
  }

  /// Reads the stored table back.
  ///
  /// Asynchronous now that the rows are in SQLite, so nodes appear a frame or
  /// two after the page does. That is the right trade: this is a memory of the
  /// mesh, not live state, and the radio replaces it wholesale on connect.
  Future<void> _restore() async {
    final store = _store;
    if (store == null) return;
    for (final row in await store.readNodes(limit: maxNodes)) {
      final node = _fromRow(row);
      if (node != null) _nodes[node.num] = node;
    }
    if (_nodes.isEmpty) return;
    Log.debug('mesh nodes: restored ${_nodes.length}');
    notifyListeners();
  }

  Future<void> _persist() async {
    final store = _store;
    if (store == null) return;
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
    await store.writeNodes([
      for (final node in ordered.take(maxNodes)) _toRow(node),
    ]);
  }

  Map<String, Object?> _toRow(MeshNode node) => {
    'num': node.num,
    'name': node.displayName,
    'battery': node.batteryLevel,
    'last_heard': node.lastHeard?.millisecondsSinceEpoch,
    'latitude': node.latitude,
    'longitude': node.longitude,
    'snr': node.snr,
    'via_mqtt': node.viaMqtt ? 1 : 0,
  };

  MeshNode? _fromRow(Map<String, Object?> row) {
    final nodeNum = (row['num'] as num?)?.toInt();
    if (nodeNum == null) return null;
    final heard = (row['last_heard'] as num?)?.toInt();
    final lastHeard = heard == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(heard);
    return MeshNode(
      num: nodeNum,
      displayName: row['name'] as String? ?? '',
      // Recomputed from `lastHeard`, never restored — see [isOnline].
      isOnline:
          lastHeard != null && _now().difference(lastHeard) < onlineWindow,
      batteryLevel: (row['battery'] as num?)?.toInt(),
      lastHeard: lastHeard,
      latitude: (row['latitude'] as num?)?.toDouble(),
      longitude: (row['longitude'] as num?)?.toDouble(),
      snr: (row['snr'] as num?)?.toDouble() ?? 0,
      viaMqtt: (row['via_mqtt'] as num?) == 1,
    );
  }

  @override
  void dispose() {
    _writeTimer?.cancel();
    unawaited(_sub?.cancel());
    super.dispose();
  }
}
