/// The Meshtastic node map layer — every mesh node that has reported a
/// position, coloured by whether it has been heard recently.
///
/// A sheet layer, not a timeline one: nodes have no frames, they have a
/// current state. It draws straight from [MeshNodeStore], so it works with no
/// radio attached — the last known mesh is exactly what you want to see when
/// you are trying to reach one.
library;

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:dpip/core/a11y/color_vision.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/meshtastic/domain/meshtastic_service.dart';
import 'package:dpip/core/meshtastic/mesh_node_store.dart';
import 'package:dpip/features/map/presentation/widgets/mesh_node_sheet.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/map/map_town_labels.dart';
import 'package:dpip/shared/widgets/map_chip_button.dart';
import 'package:dpip/shared/widgets/map_color_legend.dart';
import 'package:dpip/shared/widgets/map_menu_toggle_row.dart';
import 'package:dpip/shared/map/map_layer.dart';
import 'package:dpip/shared/widgets/section_header.dart';
import 'package:dpip/shared/map/map_station_labels.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

/// Traceroute state shared by the sheet's button and the dashed overlay.
///
/// Exactly one of the three readings is set at a time: [tracing] while a
/// probe is in flight, [result] when the destination answered, [failed]
/// when the send failed or the reply never came.
class MeshRouteState {
  const MeshRouteState({
    this.target,
    this.result,
    this.failed = false,
    this.reason,
  });

  const MeshRouteState.none() : this();

  /// The node being probed right now, or null.
  final int? target;

  /// The path the last probe found, or null.
  final MeshRoute? result;

  /// The last probe failed or timed out.
  final bool failed;

  /// What the radio said was wrong, when it said anything — a rate limit, a
  /// refusal. Null for a plain timeout, which is silence rather than an
  /// answer.
  final String? reason;

  bool get tracing => target != null;
  bool get hasRoute => result != null;
}

class MeshNodeMapLayer with MapLayerDefaults implements MapLayer {
  MeshNodeMapLayer(this._store, {required this._service});

  final MeshNodeStore _store;
  final MeshtasticService _service;

  static const String _sourceId = 'mesh-node-src';
  static const String _circleId = 'mesh-node-circle';
  static const String _labelId = 'mesh-node-label';

  /// Zoom at which a node's readings join its name on the map. Below this the
  /// dots are a distribution; above it the user is looking at individuals.
  static const double _detailZoom = 12;

  /// Tap tolerance, in the same logical pixels a touch target is measured in.
  ///
  /// A fixed degree radius is only ever right at one zoom: 0.05° is five
  /// kilometres, which is most of the screen in a street view and a couple of
  /// pixels when the whole island is showing — so zoomed out, the dots became
  /// almost unhittable. Screen distance is what the finger actually works in,
  /// and 44 px is the standard minimum touch target.
  static const double _tapRadiusPx = 44;

  // The dot palette. Getters rather than `static const`, because the
  // colour-vision transform at each definition is not a compile-time constant;
  // they are read per paint, which is where the current setting matters. The
  // legend below states the same three colours as `Color`s and routes them the
  // same way, so the key and the map stay in step under every setting.

  /// Heard within [MeshNodeStore.onlineWindow] — a node that is part of the
  /// mesh right now.
  static String get _onlineColor => '#4CAF50'.vision;

  /// Known, but silent for a while. Kept on the map rather than hidden: a
  /// repeater that was there yesterday is still where you would go looking.
  static String get _offlineColor => '#9E9E9E'.vision;

  /// Only ever heard through an MQTT bridge. A different hue, not a shade of
  /// the same one: it is a different *kind* of thing — an internet report of a
  /// node, not a radio contact — so it must not read as "a slightly less
  /// online node". The correction has to keep that separation, so it is
  /// transformed like the rest rather than pinned.
  static String get _mqttColor => '#7E57C2'.vision;
  static String get _strokeColor => '#FFFFFF'.vision;

  /// Ring around the tapped node — the map has to answer "which one did I
  /// tap?" without the user having to compare the sheet to the dots.
  static String get _selectedColor => '#1E88E5'.vision;

  MapLibreMapController? _controller;
  bool _added = false;
  bool _listening = false;

  /// The tapped node, or null. A [ValueNotifier] because the sheet is a widget
  /// and this class is not — the scaffold rebuilds it from this.
  final ValueNotifier<int?> _selected = ValueNotifier<int?>(null);

  /// Bumped on every selecting tap, so tapping the same node again re-pops a
  /// sheet the user had collapsed — a same-value notifier would not notify.
  final ValueNotifier<int> _selectionRevision = ValueNotifier<int>(0);

  /// Traceroute in flight or its latest result — the sheet's button reads it,
  /// the overlay draws it.
  final ValueNotifier<MeshRouteState> _routeState = ValueNotifier(
    const MeshRouteState.none(),
  );

  /// Traceroute state for the sheet's button and the dashed overlay.
  ValueListenable<MeshRouteState> get routeState => _routeState;

  /// The route's hops projected to screen points, split where a hop has no
  /// position (an unknown hop, or a node that never reported GPS). Updated on
  /// camera idle so a pan/zoom lands on the new projection.
  final ValueNotifier<List<List<Offset>>> _routeSegments = ValueNotifier(
    const [],
  );

  /// The projected trace for the overlay, and a way tests can read it.
  ValueListenable<List<List<Offset>>> get routeSegments => _routeSegments;

  StreamSubscription<MeshRoute>? _routeSub;
  StreamSubscription<MeshNotice>? _noticeSub;
  StreamSubscription<MeshConnectionStatus>? _linkSub;
  Timer? _routeTimeout;

  /// Whether the radio is attached right now — a probe needs it, so the sheet
  /// disables the button without it rather than offering an action that can
  /// only fail.
  ///
  /// Seeded from the transport rather than waiting for the first status
  /// event, so a sheet opened on an already-connected radio is not briefly
  /// greyed out.
  late final ValueNotifier<bool> _connected = ValueNotifier(
    _service.isConnected,
  );

  /// Live view of [_connected] for the sheet.
  ValueListenable<bool> get connected => _connected;

  /// Seconds left before the radio will accept another probe; 0 when free.
  ///
  /// The firmware throttles `TRACEROUTE_APP` from the phone to one every 30 s
  /// and refuses the rest outright, so without this the button is live and the
  /// answer to pressing it is a refusal. Counting down instead turns a hidden
  /// rule into a visible wait.
  final ValueNotifier<int> _traceCooldown = ValueNotifier(0);

  ValueListenable<int> get traceCooldown => _traceCooldown;

  Timer? _cooldownTicker;

  /// The firmware's throttle (`PhoneAPI`, one traceroute per 30 s).
  static const int _cooldownSeconds = 30;

  /// The id of the probe in flight — how a reply, or the radio's refusal, is
  /// told apart from one belonging to an earlier probe or another app.
  int? _probeId;

  /// How long a probe may take before it counts as lost.
  ///
  /// Both legs cross the mesh and each hop re-floods with its own random
  /// backoff, so a 3-hop round trip on a slow modem preset is tens of
  /// seconds; the reference clients scale their wait with the hop limit up to
  /// ~80 s. (An earlier note here blamed the firmware's 10 s tracking window
  /// and 30 s cooldown, but those govern the radio's *own screen* — a probe
  /// from the phone reaches the mesh by another path and touches neither.)
  static const Duration _traceTimeout = Duration(seconds: 60);

  @override
  String get id => 'meshtastic';

  @override
  IconData get icon => Icons.hub_outlined;

  @override
  String label(BuildContext context) =>
      AppLocalizations.of(context).mapLayerMeshtastic;

  @override
  String? subtitle(BuildContext context) =>
      AppLocalizations.of(context).mapLayerMeshtasticSubtitle;

  @override
  bool get usesTimeline => false;

  @override
  Future<void> render(MapLibreMapController controller) async {
    _controller = controller;
    _watchLink();
    await _removeFromMap(controller);
    await controller.addSource(
      _sourceId,
      GeojsonSourceProperties(data: _geoJson()),
    );
    await controller.addCircleLayer(
      _sourceId,
      _circleId,
      _circleProps(),
      // **false on purpose.** An interactive layer fires `feature#onTap`
      // instead of `map#onMapClick`, and nothing in this app listens to
      // feature taps — a tap on the dot would go nowhere while a tap on
      // empty sea still reached onMapTap. Every other layer is false too.
      enableInteraction: false,
    );
    // Names only from mid zoom: a dense urban mesh would otherwise be a wall
    // of overlapping labels.
    await controller.addSymbolLayer(
      _sourceId,
      _labelId,
      _labelProps(),
      minzoom: 9,
      enableInteraction: false,
    );
    _added = true;
    if (!_listening) {
      _store.addListener(_onNodes);
      _listening = true;
    }
  }

  /// Coalesces store notifications into one trailing push.
  ///
  /// The store notifies per packet, and a config download replays the whole
  /// node table as a burst — ~250 notifications in a couple of seconds, each
  /// of which used to re-serialise a 250-feature GeoJSON and cross the
  /// platform channel. One trailing update renders the same final state; the
  /// intermediate frames were never visible anyway, because the flood itself
  /// was what the frame rate was being spent on.
  void _onNodes() {
    if (_pushQueued) return;
    _pushQueued = true;
    _pushTimer = Timer(const Duration(milliseconds: 250), () {
      _pushQueued = false;
      unawaited(_push());
    });
  }

  bool _pushQueued = false;
  Timer? _pushTimer;

  @override
  Future<void> onMapTap(LatLng latLng, MapLibreMapController controller) async {
    if (_store.positioned.isEmpty) return;
    final best = await _nodeNear(latLng, controller);
    if (best == null) return;
    _selected.value = best;
    _selectionRevision.value++;
    // The selected node draws with a ring, so the map has to be re-pushed.
    await _push();
  }

  /// The node under (or near) a tap.
  ///
  /// Computes screen distances in Dart instead of asking MapLibre to
  /// hit-test: a rendered-feature query on a **circle** layer is not reliable
  /// for tapping — the engine's point hit test can shrink the reachable area
  /// far below the drawn dot (and the two platforms even differ), which is why
  /// the old 44 px box still felt unhittable while the disaster map's big
  /// symbol icons never did. Projecting the nodes ourselves makes the target
  /// exactly the pixel radius it looks like — one batch call for all of them,
  /// one distance loop, no query semantics to get wrong.
  Future<int?> _nodeNear(
    LatLng latLng,
    MapLibreMapController controller,
  ) async {
    try {
      final tap = await controller.toScreenLocation(latLng);
      final nodes = _store.positioned;
      final points = await controller.toScreenLocationBatch([
        // [positioned] already filtered out nulls — the list this mirrors.
        for (final node in nodes) LatLng(node.latitude!, node.longitude!),
      ]);
      final reach = _tapRadiusPx * _screenScale;
      final reachSquared = reach * reach;
      int? best;
      var bestSquared = reachSquared;
      for (var i = 0; i < points.length; i++) {
        final dx = points[i].x.toDouble() - tap.x.toDouble();
        final dy = points[i].y.toDouble() - tap.y.toDouble();
        final distanceSquared = dx * dx + dy * dy;
        if (distanceSquared < bestSquared) {
          bestSquared = distanceSquared;
          best = nodes[i].num;
        }
      }
      return best;
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'mesh node hit test');
    }
    return null;
  }

  /// Android reports screen coordinates in device pixels, iOS in logical
  /// points — so the same tolerance means different things unless it is
  /// scaled.
  double get _screenScale => defaultTargetPlatform == TargetPlatform.android
      ? PlatformDispatcher.instance.views.first.devicePixelRatio
      : 1.0;

  /// Sends a traceroute probe to [nodeNum] and watches for the reply.
  ///
  /// One probe at a time (the firmware itself is on a 30 s cooldown): a
  /// second tap while one is in flight is ignored, and the send failing or
  /// the reply not arriving both land in [MeshRouteState.failed].
  Future<void> startTrace(int nodeNum) async {
    if (_routeState.value.tracing) return;
    _listenRoutes();
    _probeId = null;
    _routeState.value = MeshRouteState(target: nodeNum);
    final result = await _service.traceRoute(nodeNum);
    _routeTimeout?.cancel();
    if (result is Err) {
      _routeState.value = const MeshRouteState(failed: true);
      return;
    }
    _probeId = result.valueOrNull;
    // The radio took it, so its throttle clock just started — begin counting
    // before the user can press again, not after the refusal.
    _startCooldown();
    _routeTimeout = Timer(_traceTimeout, _giveUp);
  }

  /// Runs the visible countdown to when the radio will accept another probe.
  ///
  /// A local countdown cannot be exact — the radio's clock also advances for
  /// traceroutes *other* clients send, which we never see — so it is the upper
  /// bound, restarted whenever the radio tells us it refused. Being a few
  /// seconds pessimistic costs a wait; being optimistic costs a refusal, which
  /// is what this exists to stop.
  ///
  /// Seconds counted down here rather than a wall-clock deadline: a device
  /// clock that moves mid-probe would otherwise jump the countdown.
  void _startCooldown() {
    _traceCooldown.value = _cooldownSeconds;
    _cooldownTicker?.cancel();
    _cooldownTicker = Timer.periodic(const Duration(seconds: 1), (ticker) {
      final left = _traceCooldown.value - 1;
      _traceCooldown.value = left > 0 ? left : 0;
      if (left <= 0) ticker.cancel();
    });
  }

  /// Picks up the reply, and anything the radio says about the probe —
  /// subscribed lazily so an unvisited mesh page never pays for the streams.
  void _listenRoutes() {
    _routeSub ??= _service.routeStream.listen((route) {
      // Only the answer to the probe on screen. Another node's reply, or a
      // late one from a probe already given up on, would otherwise redraw the
      // map with a path that answers a different question.
      if (route.target != _routeState.value.target) return;
      _routeTimeout?.cancel();
      _routeState.value = MeshRouteState(result: route);
      unawaited(_projectRoute());
    });
    _noticeSub ??= _service.noticeStream.listen((notice) {
      // The radio refusing to send is an answer, and a faster one than the
      // timeout: it names the reason ("TraceRoute can only be sent once every
      // 30 seconds") instead of leaving a minute of spinner and a bare "no
      // reply" that blames the mesh for something the radio did.
      if (!_routeState.value.tracing || notice.replyId != _probeId) return;
      _routeTimeout?.cancel();
      _routeState.value = MeshRouteState(failed: true, reason: notice.message);
      // Refused means the packet never went out, so the radio's clock did not
      // restart — but we cannot see how much of it is left (another client's
      // probe may have started it). A full window is the safe bound.
      _startCooldown();
    });
  }

  /// Tracks whether the radio is attached, for the sheet's trace button.
  ///
  /// Subscribed on render rather than in the constructor for the same reason
  /// the route streams are: a map the user never opens pays nothing.
  void _watchLink() {
    _connected.value = _service.isConnected;
    _linkSub ??= _service.connectionStream.listen((status) {
      final connected = status.state == MeshConnectionState.connected;
      if (_connected.value != connected) _connected.value = connected;
      // A probe cannot survive the radio going away — its answer had to come
      // back over that link.
      if (!connected && _routeState.value.tracing) {
        _routeTimeout?.cancel();
        _routeState.value = const MeshRouteState(failed: true);
      }
      // A different radio has its own throttle clock, and this one's is
      // unknowable after a drop — either way the count we were showing is
      // about a link that no longer exists.
      if (!connected) {
        _cooldownTicker?.cancel();
        _traceCooldown.value = 0;
      }
    });
  }

  /// The probe's time ran out. Guarded on [MeshRouteState.tracing] so a timer
  /// that fires just after an answer landed cannot erase it.
  void _giveUp() {
    if (!_routeState.value.tracing) return;
    _routeState.value = const MeshRouteState(failed: true);
  }

  /// Projects the traced hops to screen points, breaking the line where a
  /// hop has no position. One batch call for all of them.
  Future<void> _projectRoute() async {
    final controller = _controller;
    final route = _routeState.value.result;
    if (controller == null || route == null) return;
    try {
      final coords = <LatLng>[];
      final hopIndices = <int>[];
      for (var i = 0; i < route.towards.length; i++) {
        final node = _store.byNum(route.towards[i].num);
        if (node == null || node.latitude == null || node.longitude == null) {
          continue;
        }
        hopIndices.add(i);
        coords.add(LatLng(node.latitude!, node.longitude!));
      }
      if (coords.isEmpty) {
        _routeSegments.value = const [];
        return;
      }
      final points = await controller.toScreenLocationBatch(coords);
      final segments = <List<Offset>>[];
      var current = <Offset>[];
      var pointIndex = 0;
      for (var i = 0; i < route.towards.length; i++) {
        if (pointIndex < hopIndices.length && hopIndices[pointIndex] == i) {
          current.add(
            Offset(
              points[pointIndex].x.toDouble(),
              points[pointIndex].y.toDouble(),
            ),
          );
          pointIndex++;
        } else if (current.length >= 2) {
          segments.add(current);
          current = <Offset>[];
        }
      }
      if (current.length >= 2) segments.add(current);
      _routeSegments.value = segments;
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'mesh route projection');
    }
  }

  @override
  Widget buildSheet(BuildContext context) => MeshNodeSheet(
    store: _store,
    selected: _selected,
    selectionRevision: _selectionRevision,
    routeState: _routeState,
    connected: _connected,
    traceCooldown: _traceCooldown,
    onTraceRoute: (nodeNum) => unawaited(startTrace(nodeNum)),
    onClose: () {
      _selected.value = null;
      unawaited(_push());
    },
  );

  @override
  Widget buildMapOverlay(BuildContext context) {
    // The traced path, drawn as marching ants over the dots. Read the route
    // state and the projection separately so a camera settle (which
    // re-projects) rebuilds only the painter's input, never the sheet.
    return ValueListenableBuilder<MeshRouteState>(
      valueListenable: _routeState,
      builder: (context, state, _) {
        if (state.result == null) return const SizedBox.shrink();
        return ValueListenableBuilder<List<List<Offset>>>(
          valueListenable: _routeSegments,
          builder: (context, segments, _) => segments.isEmpty
              ? const SizedBox.shrink()
              : _RouteOverlay(
                  segments: segments,
                  color: const Color(0xFF1E88E5).vision,
                ),
        );
      },
    );
  }

  @override
  Future<void> onCameraIdle(MapLibreMapController controller) async {
    // Re-project after the camera settles — the overlay is keyed by the
    // scaffold's camera epoch, so this runs just before its rebuild.
    if (_routeState.value.result != null) await _projectRoute();
  }

  /// The collapsed peek the scaffold frames around — the sheet is always
  /// present, just resting at its handle when nothing is selected.
  @override
  double get bottomChromeFraction => MeshNodeSheet.peekExtent;

  Future<void> _push() async {
    final controller = _controller;
    if (controller == null || !_added) return;
    try {
      await controller.setGeoJsonSource(_sourceId, _geoJson());
    } catch (_) {
      // The style can reload underneath us; the next render re-adds.
    }
  }

  Map<String, dynamic> _geoJson() {
    final features = <Map<String, dynamic>>[];
    for (final node in _store.positioned) {
      // Bound once: `_twoLineLabel` starts from the same stub, and walking a
      // CJK name's grapheme clusters twice per node per push is the most
      // expensive thing in this loop.
      final name = _shortLabel(node);
      features.add({
        'type': 'Feature',
        'geometry': {
          'type': 'Point',
          'coordinates': [node.longitude, node.latitude],
        },
        'properties': {
          'num': node.num,
          'name': name,
          // Precomposed rather than concatenated in the style: an empty
          // detail would otherwise leave a trailing blank line under the
          // name.
          'label': _twoLineLabel(node, name),
          'online': _store.isOnline(node) ? 1 : 0,
          'mqtt': node.viaMqtt ? 1 : 0,
          // Direct neighbour — a node this radio hears itself, rather than
          // through someone. Binary on purpose: at a 4.5–9 px dot, three
          // grades of ring are indistinguishable, and the meaningful line is
          // between "I can hear this" and "someone relays it for me".
          // Unknown reads the same as not-direct, because that is the
          // conservative claim.
          'direct': node.hopsAway == 0 ? 1 : 0,
          'selected': node.num == _selected.value ? 1 : 0,
        },
      });
    }
    return {'type': 'FeatureCollection', 'features': features};
  }

  /// Node names run long (`故宮南院 東側山線 (Heltec V3)`); the map shows a
  /// readable stub and the mesh page has the full list.
  String _shortLabel(MeshNode node) {
    final name = node.displayName.trim();
    if (name.isEmpty) return '0x${node.num.toRadixString(16)}';
    final chars = name.characters;
    return chars.length <= 12 ? name : '${chars.take(12)}…';
  }

  /// Name over its readings, for the close-in zooms.
  ///
  /// Deliberately **no "heard N minutes ago"** here. This string is baked into
  /// the map source and only rewritten when the store changes — so for a node
  /// that has gone quiet, which is exactly the node whose age matters, the
  /// label would freeze at whatever it said when the node last reported and
  /// then keep claiming it. A frozen age is worse than none: the dot's colour
  /// already separates heard-recently from silent, and the sheet carries a
  /// live "last heard" because it rebuilds.
  // l10n-ignore: numeric readouts
  String _twoLineLabel(MeshNode node, String name) {
    final parts = <String>[
      if (node.batteryLevel != null)
        node.batteryLevel! > 100 ? 'DC' : '${node.batteryLevel}%',
      if (node.snr != 0) 'SNR ${node.snr.toStringAsFixed(1)}',
      // How far, when the radio knows. Written as text rather than encoded in
      // the dot because it is a small integer with an "unknown" state, and an
      // absent word is the only honest way to draw not-knowing — a shade or a
      // size always looks like a value.
      if (node.hopsAway != null)
        node.hopsAway == 0 ? '0 hop' : '${node.hopsAway} hop',
    ];
    return parts.isEmpty ? name : '$name\n${parts.join(' · ')}';
  }

  CircleLayerProperties _circleProps() => CircleLayerProperties(
    // Grown from 3–7: a node is a thing to tap, and the dot has to look like
    // the target the hit test actually allows.
    circleRadius: [
      Expressions.interpolate,
      ['linear'],
      [Expressions.zoom],
      6,
      4.5,
      12,
      9.0,
    ],
    circleColor: [
      Expressions.caseExpression,
      [
        Expressions.equal,
        [Expressions.get, 'mqtt'],
        1,
      ],
      _mqttColor,
      [
        Expressions.equal,
        [Expressions.get, 'online'],
        1,
      ],
      _onlineColor,
      _offlineColor,
    ],
    circleStrokeWidth: [
      Expressions.caseExpression,
      [
        Expressions.equal,
        [Expressions.get, 'selected'],
        1,
      ],
      3.0,
      // A heavier ring on a direct neighbour. Stroke *width*, not hue: hue is
      // already spoken for by online/silent/MQTT, and adding a fourth meaning
      // to it would make every dot ambiguous.
      [
        Expressions.equal,
        [Expressions.get, 'direct'],
        1,
      ],
      2.2,
      1.0,
    ],
    circleStrokeColor: [
      Expressions.caseExpression,
      [
        Expressions.equal,
        [Expressions.get, 'selected'],
        1,
      ],
      _selectedColor,
      _strokeColor,
    ],
    circleOpacity: [
      Expressions.caseExpression,
      [
        Expressions.equal,
        [Expressions.get, 'online'],
        1,
      ],
      1.0,
      0.55,
    ],
  );

  /// **One** symbol layer, not two.
  ///
  /// `stationLabelProps` is built for a single two-line label — it owns the
  /// offset under the dot and the CJK-aware line height. Two stacked layers
  /// would each claim that same offset (drawing the second line on top of the
  /// first) and then collide-avoid *each other*, so a node would keep losing
  /// one of its own lines. A `step` on zoom switches between the one-line and
  /// two-line strings instead: the readings appear only once the map is close
  /// enough to attribute them to a specific node.
  SymbolLayerProperties _labelProps() => stationLabelProps(
    textField: [
      'step',
      [Expressions.zoom],
      [Expressions.get, 'name'],
      _detailZoom,
      [Expressions.get, 'label'],
    ],
    opacity: 1,
  );

  @override
  Future<void> clear(MapLibreMapController controller) async {
    if (_listening) {
      _store.removeListener(_onNodes);
      _listening = false;
    }
    _pushTimer?.cancel();
    _pushQueued = false;
    _selected.value = null;
    _routeTimeout?.cancel();
    _routeSegments.value = const [];
    // A probe in flight survives a style rebuild: the subscriptions are the
    // only way its answer can arrive, and the base map reloading (a layer
    // switch, a theme change) is not the user abandoning the trace.
    if (!_routeState.value.tracing) {
      _routeState.value = const MeshRouteState.none();
      await _routeSub?.cancel();
      await _noticeSub?.cancel();
      _routeSub = null;
      _noticeSub = null;
      await _linkSub?.cancel();
      _linkSub = null;
    }
    await _removeFromMap(controller);
    _controller = null;
  }

  Future<void> _removeFromMap(MapLibreMapController controller) async {
    if (!_added) return;
    _added = false;
    for (final layerId in [_labelId, _circleId]) {
      try {
        await controller.removeLayer(layerId);
      } catch (_) {
        // Not present — the style may have been rebuilt under us.
      }
    }
    try {
      await controller.removeSource(_sourceId);
    } catch (_) {
      // Same.
    }
  }

  /// The key for the two dot colours.
  ///
  /// Without it the map shows green and grey dots and never says which is
  /// which — the one thing a reader cannot work out by looking.
  ///
  /// The swatches restate the map's hexes as `Color`s, so each one is routed
  /// through `.vision` exactly like its counterpart above — same input, same
  /// deterministic transform, so the key still names the dot it points at when
  /// a correction is on. (Not `const` any more, for the same reason.)
  @override
  Widget buildLegend(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // `MapLegendCard` is the surface every other layer's legend sits on —
    // without it the swatches float straight on the map and the labels fight
    // whatever tiles happen to be underneath.
    return MapLegendCard(
      child: ListenableBuilder(
        listenable: _store,
        builder: (context, _) => SymbolLegend(
          items: [
            SymbolLegendItem(
              swatch: LegendDot(color: const Color(0xFF4CAF50).vision),
              label: l10n.meshtasticOnline,
            ),
            SymbolLegendItem(
              swatch: LegendDot(color: const Color(0xFF9E9E9E).vision),
              label: l10n.meshtasticSilent,
            ),
            // Only keyed when such nodes can actually be on the map: a legend
            // row for something the filter is hiding is noise.
            if (!_store.excludeMqtt)
              SymbolLegendItem(
                swatch: LegendDot(color: const Color(0xFF7E57C2).vision),
                label: l10n.meshtasticViaMqtt,
              ),
          ],
        ),
      ),
    );
  }

  /// Layer-specific chrome beside the layer switcher: the MQTT filter, plus
  /// the shared base-map toggles so the user has one menu rather than three.
  @override
  Widget buildTopTrailingChrome(
    BuildContext context, {
    required ValueListenable<bool> showTownLabels,
    required ValueChanged<bool> onShowTownLabelsChanged,
    required ValueListenable<bool> showTerrain,
    required ValueChanged<bool> onShowTerrainChanged,
    required Future<void> Function() onReloadActive,
  }) => _MeshNodeMenu(
    store: _store,
    onExcludeMqttChanged: (exclude) async {
      await _store.setExcludeMqtt(exclude: exclude);
      await _push();
    },
    showTownLabels: showTownLabels,
    onShowTownLabelsChanged: onShowTownLabelsChanged,
    showTerrain: showTerrain,
    onShowTerrainChanged: onShowTerrainChanged,
  );

  @override
  void onStyleReset() {
    _added = false;
    _controller = null;
  }
}

/// The mesh layer's overlay menu.
class _MeshNodeMenu extends StatelessWidget {
  const _MeshNodeMenu({
    required this.store,
    required this.onExcludeMqttChanged,
    required this.showTownLabels,
    required this.onShowTownLabelsChanged,
    required this.showTerrain,
    required this.onShowTerrainChanged,
  });

  final MeshNodeStore store;
  final ValueChanged<bool> onExcludeMqttChanged;
  final ValueListenable<bool> showTownLabels;
  final ValueChanged<bool> onShowTownLabelsChanged;
  final ValueListenable<bool> showTerrain;
  final ValueChanged<bool> onShowTerrainChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([store, showTownLabels, showTerrain]),
      builder: (context, _) {
        final excludeMqtt = store.excludeMqtt;
        final hidden = store.hiddenMqttCount;
        // The chip marks a *deviation from the defaults*, and hiding MQTT is
        // the default here — so only the opposite lights it up.
        final active =
            !excludeMqtt || !showTownLabels.value || !showTerrain.value;
        return MenuAnchor(
          alignmentOffset: const Offset(0, 4),
          style: MapChipButton.menuStyle(context),
          builder: (context, controller, _) => MapChipButton(
            icon: Icons.tune,
            tooltip: l10n.meshtasticLayerOptions,
            active: active,
            onTap: controller.isOpen ? controller.close : controller.open,
          ),
          menuChildren: [
            MapMenuScrollView(
              children: [
                // The shared map section stays first in every settings list;
                // OSM is the common action and should never be buried below a
                // layer-specific filter.
                MapBasemapControlRows(
                  showTownLabels: showTownLabels,
                  onShowTownLabelsChanged: onShowTownLabelsChanged,
                  showTerrain: showTerrain,
                  onShowTerrainChanged: onShowTerrainChanged,
                ),
                const MapMenuDivider(),
                SectionHeader(l10n.meshtasticNodes),
                MapMenuToggleRow(
                  selected: excludeMqtt,
                  icon: Icons.cloud_off_outlined,
                  title: l10n.meshtasticExcludeMqtt,
                  subtitle: excludeMqtt && hidden > 0
                      ? l10n.meshtasticExcludeMqttHidden(hidden)
                      : l10n.meshtasticExcludeMqttSubtitle,
                  tooltip: l10n.meshtasticExcludeMqttSubtitle,
                  onTap: () => onExcludeMqttChanged(!excludeMqtt),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

/// The traced path as an animated dashed line — marching ants.
///
/// Painted in the Flutter overlay rather than as a MapLibre line layer
/// because the animation would otherwise have to rewrite `line-dasharray`
/// through the platform channel every frame. Here one `CustomPaint` repaints
/// per frame, and the platform channel is hit once per camera settle (the
/// projection).
///
/// [segments] are already in the overlay's coordinate space; the painter
/// never needs the map.
class _RouteOverlay extends StatefulWidget {
  const _RouteOverlay({required this.segments, required this.color});

  final List<List<Offset>> segments;
  final Color color;

  @override
  State<_RouteOverlay> createState() => _RouteOverlayState();
}

class _RouteOverlayState extends State<_RouteOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _phase = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _phase.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _phase,
        builder: (context, _) => CustomPaint(
          size: Size.infinite,
          painter: _RoutePainter(
            segments: widget.segments,
            color: widget.color,
            phase: _phase.value,
          ),
        ),
      ),
    );
  }
}

class _RoutePainter extends CustomPainter {
  const _RoutePainter({
    required this.segments,
    required this.color,
    required this.phase,
  });

  final List<List<Offset>> segments;
  final Color color;

  /// 0..1 — where the dash pattern sits along the path; the controller
  /// advances it so the dashes appear to march.
  final double phase;

  static const double _dash = 10;
  static const double _gap = 8;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color;
    final cycle = _dash + _gap;
    final offset = phase * cycle;
    for (final segment in segments) {
      if (segment.length < 2) continue;
      final path = Path()..moveTo(segment.first.dx, segment.first.dy);
      for (final point in segment.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      for (final metric in path.computeMetrics()) {
        var distance = offset;
        while (distance < metric.length) {
          final end = math.min(distance + _dash, metric.length);
          canvas.drawPath(metric.extractPath(distance, end), stroke);
          distance += cycle;
        }
      }
    }
    // Endpoints as dots, so the path says where it starts and where it ends
    // even when the dashed line between them is broken by a hop without a
    // position.
    final dot = Paint()..color = color;
    for (final segment in segments) {
      canvas.drawCircle(segment.first, 4.5, dot);
      canvas.drawCircle(segment.last, 4.5, dot);
    }
  }

  @override
  bool shouldRepaint(_RoutePainter oldDelegate) =>
      oldDelegate.segments != segments ||
      oldDelegate.color != color ||
      oldDelegate.phase != phase;
}
