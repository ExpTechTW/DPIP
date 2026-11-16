import 'dart:async';
import 'dart:convert';

import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/network/api_client.dart';
import 'package:dpip/core/network/api_paths.dart';
import 'package:dpip/core/network/api_region.dart';
import 'package:dpip/core/network/sse_client.dart';
import 'package:dpip/core/network/sse_event.dart';
import 'package:dpip/core/realtime/elapsed.dart';

/// Opens one connection to the shared stream carrying [topics] (sorted).
/// [live] asks for `mode=live`: every RTS frame, not only the alerting ones.
typedef SseMuxOpener = Stream<SseEvent> Function(
  List<String> topics, {
  required bool live,
});

/// One Server-Sent Events connection shared by every live feed, instead of a
/// connection per feed.
///
/// The server's mixed entry (`/api/v1/sse?topics=a,b`) streams any number of
/// topics over one connection and names each frame for its topic
/// (`event: trem.rts.v1`). A feed registers its topic with [topic] and gets a
/// connection factory, [SseMuxTopic.connect], that behaves to it exactly like
/// opening a connection of its own: a single-subscription stream of the
/// frames of its topic, plus everything about the connection itself — the
/// `retry:` hint, the `info` greeting, the `: ping` keep-alives, `close` — and
/// that ends or errors when the connection does. So `SseRealtimeSource` keeps
/// its whole connection policy (backoff, silence limit, pause, network
/// change) unchanged; it just leases a share of one socket instead of owning
/// one.
///
/// **One connection, open while anyone listens.** The first lease opens it,
/// with every registered topic, and the last one to cancel closes it — so a
/// background stint, where every feed lets go, still drops the socket, and a
/// network change, where every feed lets go and comes back after its own
/// settle, still replaces it. A feed that reconnects on its own (its backoff
/// after a drop, its silence limit) joins the connection already open. Changes
/// are applied a microtask later, so feeds that let go or come back in one
/// synchronous burst (resume, pause) cost one connection, not one each.
///
/// **A late joiner hears what a fresh connection would have said.** The
/// server greets each connection once, and a snapshot topic (`snapshot: true`
/// — every frame the whole current state, sent again on connect) answers a new
/// connection with its current state at once. A lease joining a connection
/// that has already spoken is replayed the `retry:` hint, the greeting and its
/// topic's latest snapshot, so it is connected and current the moment it
/// joins, as if it had dialled itself. A stream topic (RTS) is not replayed:
/// the server sends nothing on connect there either, and the next frame is
/// half a second away.
///
/// **A change of parameters is a handover, never a gap.** The connection's
/// mode is `live` while any lease asks for it. When that changes — the
/// monitor opens or closes — a new connection opens alongside the current one
/// and takes over on its first frame (the greeting), so no feed sees a drop.
/// If the new one fails before then, every lease ends and each feed
/// reconnects through its own backoff: the old connection still carries the
/// old parameters, and keeping it would leave the change quietly unapplied.
///
/// **A dead connection is not joined.** A connection silent past
/// [sseSilenceLimit] is half-open (see there). A feed leaving it because of
/// that would otherwise come straight back to it while another feed still
/// holds it; instead the joining lease replaces it, and every other lease is
/// ended so its feed reconnects to the new one. The transport's own idle
/// timeout (`HttpSseClient`) is the backstop that ends it while no one joins.
///
/// Every payload frame on this endpoint is `base64(gzip(json))`; decoding is
/// the feed's business (`SseRealtimeSource`), so the mux never touches a
/// payload — it only routes by event name.
class SseMux {
  SseMux(
    this._open, {
    Elapsed? elapsed,
    this._silenceLimit = sseSilenceLimit,
    this._label = 'sse',
  }) : _elapsed = elapsed ?? SystemElapsed();

  /// The shared stream on the LB tier, with the region failover every LB
  /// request has:
  ///
  /// `https://api.lb-{tpe1,khh1}.exptech.dev/api/v1/sse?topics=<a,b>[&mode=live]`
  ///
  /// No token: every topic the app streams is public, and the server answers
  /// a request with an *invalid* token with 401 even for public topics.
  factory SseMux.lb(ApiClient api) => SseMux(
    (topics, {required live}) => HttpSseClient(api).connect(
      ApiTier.lbApi,
      ApiPaths.sse,
      query: {'topics': topics.join(','), if (live) 'mode': 'live'},
    ),
  );

  final SseMuxOpener _open;
  final Elapsed _elapsed;
  final Duration _silenceLimit;
  final String _label;

  /// Every registered topic; the connection always asks for all of them.
  final Set<String> _topics = {};

  /// The registered topics whose frames are whole snapshots, replayed to a
  /// lease that joins an open connection.
  final Set<String> _snapshotTopics = {};

  /// The leases currently listening, in the order they joined.
  final List<_Lease> _leases = [];

  /// The connection the leases are reading.
  _Link? _current;

  /// Its replacement during a handover, until it speaks.
  _Link? _pending;

  bool _reconcileQueued = false;

  /// Registers [name] on the shared stream and returns the feed's handle.
  ///
  /// [snapshot] marks a topic whose every frame is the whole current state and
  /// which the server sends again on connect; see the class docs. Registering
  /// a topic again returns an equivalent handle.
  SseMuxTopic topic(String name, {bool snapshot = false}) {
    _topics.add(name);
    if (snapshot) _snapshotTopics.add(name);
    return SseMuxTopic._(this, name);
  }

  Stream<SseEvent> _lease(String topic, {required bool live}) {
    final lease = _Lease(topic, live: live);
    lease.controller = StreamController<SseEvent>(
      onListen: () => _attach(lease),
      onCancel: () => _detach(lease),
    );
    return lease.controller.stream;
  }

  void _attach(_Lease lease) {
    final current = _current;
    if (current != null &&
        _elapsed.elapsed - current.lastByte > _silenceLimit) {
      Log.warning(
        '[$_label] shared SSE stream silent past '
        '${_silenceLimit.inSeconds}s — replacing it',
      );
      _closeLinks();
      _endLeases();
    }
    _leases.add(lease);
    final link = _current;
    if (link != null && link.spoke && link.satisfies(lease)) {
      _replay(link, lease);
    }
    _scheduleReconcile();
  }

  void _detach(_Lease lease) {
    if (_leases.remove(lease)) _scheduleReconcile();
  }

  void _scheduleReconcile() {
    if (_reconcileQueued) return;
    _reconcileQueued = true;
    scheduleMicrotask(_reconcile);
  }

  /// Brings the connection in line with the leases: none open when nobody
  /// listens, one with every registered topic at the mode they ask for
  /// otherwise.
  void _reconcile() {
    _reconcileQueued = false;
    if (_leases.isEmpty) {
      if (_current != null) {
        Log.debug('[$_label] no feed is listening — closing the SSE stream');
      }
      _closeLinks();
      return;
    }
    final topics = _topics.toList()..sort();
    final live = _leases.any((lease) => lease.live);
    final current = _current;
    if (current != null && current.matches(topics, live: live)) {
      _cancelPending();
      return;
    }
    if (current == null || !current.spoke) {
      // Nothing has been read from it yet, so there is nothing to hand over:
      // the leases waiting on it wait on the replacement instead.
      current?.close();
      _cancelPending();
      _start(_current = _Link(topics, live: live, openedAt: _elapsed.elapsed));
      return;
    }
    if (_pending?.matches(topics, live: live) ?? false) return;
    _cancelPending();
    _start(_pending = _Link(topics, live: live, openedAt: _elapsed.elapsed));
  }

  void _start(_Link link) {
    Log.info(
      '[$_label] opening the shared SSE stream: ${link.topics.join(',')}'
      '${link.live ? ' (live)' : ''}',
    );
    link.subscription = _open(link.topics, live: link.live).listen(
      (event) => _onLinkEvent(link, event),
      onError: (Object error, StackTrace stackTrace) =>
          _onLinkEnd(link, error, stackTrace),
      onDone: () => _onLinkEnd(link),
      cancelOnError: true,
    );
  }

  void _onLinkEvent(_Link link, SseEvent event) {
    if (identical(link, _pending)) {
      // The replacement spoke: it takes over, without a gap.
      _current?.close();
      _current = link;
      _pending = null;
      Log.debug('[$_label] shared SSE stream handed over');
    } else if (!identical(link, _current)) {
      return; // already replaced
    }
    link
      ..lastByte = _elapsed.elapsed
      ..spoke = true;
    if (event.retry case final retry?) link.retry = retry;
    _route(link, event);
  }

  void _route(_Link link, SseEvent event) {
    if (event.isComment) {
      _broadcast(event);
      return;
    }
    final name = event.name;
    if (name == null || name.isEmpty || name == 'message') {
      // Every payload on this endpoint is named for its topic, so an unnamed
      // frame carries only the reconnect hint. A stray `data:` on one must
      // not reach a feed that reads unnamed frames as its own payload.
      _broadcast(SseEvent(retry: event.retry));
      return;
    }
    if (name == 'info') {
      link.greeting = event;
      _broadcast(event);
      return;
    }
    if (link.topics.contains(name)) {
      if (_snapshotTopics.contains(name)) link.snapshots[name] = event;
      _deliver(name, event);
      return;
    }
    if (name == 'unsubscribed') {
      // `{"topic": …, "reason": …}`: only the feed of that topic is told, and
      // it logs why. Only metered topics are ever dropped, never the public
      // ones an anonymous app streams.
      final topic = _unsubscribedTopic(event.data);
      if (topic != null && link.topics.contains(topic)) {
        _deliver(topic, event);
        return;
      }
    }
    // `close`, and anything this client does not know: every feed sees it.
    _broadcast(event);
    if (name == 'close') {
      // The server is going away and says so first: every feed reconnects now,
      // rather than when — or if — the socket finally ends.
      _closeLinks();
      _endLeases();
    }
  }

  void _onLinkEnd(_Link link, [Object? error, StackTrace? stackTrace]) {
    link.subscription = null;
    if (identical(link, _pending)) {
      // The replacement failed before it spoke. The current connection still
      // has the old parameters; every feed reconnects instead.
      Log.warning(
        '[$_label] shared SSE handover failed${error == null ? '' : ': $error'}',
      );
      _pending = null;
      _closeLinks();
      _endLeases();
      return;
    }
    if (!identical(link, _current)) return;
    _current = null;
    _cancelPending();
    _endLeases(error, stackTrace);
  }

  void _replay(_Link link, _Lease lease) {
    final retry = link.retry;
    if (retry != null) lease.controller.add(SseEvent(retry: retry));
    final greeting = link.greeting;
    if (greeting != null) lease.controller.add(greeting);
    final snapshot = link.snapshots[lease.topic];
    if (snapshot != null) lease.controller.add(snapshot);
  }

  void _broadcast(SseEvent event) {
    for (final lease in _leases) {
      lease.controller.add(event);
    }
  }

  void _deliver(String topic, SseEvent event) {
    for (final lease in _leases) {
      if (lease.topic == topic) lease.controller.add(event);
    }
  }

  /// Ends every lease, as a dropped connection would: each feed reconnects
  /// through its own backoff.
  void _endLeases([Object? error, StackTrace? stackTrace]) {
    final leases = [..._leases];
    _leases.clear();
    for (final lease in leases) {
      if (error != null) lease.controller.addError(error, stackTrace);
      lease.controller.close();
    }
  }

  void _cancelPending() {
    _pending?.close();
    _pending = null;
  }

  void _closeLinks() {
    _cancelPending();
    _current?.close();
    _current = null;
  }

  static String? _unsubscribedTopic(String data) {
    try {
      final json = jsonDecode(data);
      if (json is Map<String, dynamic>) {
        final topic = json['topic'];
        if (topic is String) return topic;
      }
    } on FormatException {
      // Not the documented shape: told to every feed instead.
    }
    return null;
  }
}

/// A feed's handle on the shared stream (see [SseMux.topic]).
class SseMuxTopic {
  const SseMuxTopic._(this._mux, this.name);

  final SseMux _mux;

  /// The topic, which is also the event name of its frames.
  final String name;

  /// A fresh lease on the shared stream for this topic: what a feed calls
  /// wherever it would open a connection, and again to reconnect. Listening
  /// joins (or opens) the connection; cancelling lets go of it.
  ///
  /// [live] asks for every frame of a topic that has a sleep mode (RTS); the
  /// connection runs live while any lease asks for it.
  Stream<SseEvent> connect({bool live = false}) =>
      _mux._lease(name, live: live);
}

class _Lease {
  _Lease(this.topic, {required this.live});

  final String topic;
  final bool live;
  late final StreamController<SseEvent> controller;
}

/// One physical connection to the shared stream.
class _Link {
  _Link(this.topics, {required this.live, required Duration openedAt})
    : lastByte = openedAt;

  final List<String> topics;
  final bool live;
  StreamSubscription<SseEvent>? subscription;

  /// Whether anything at all has arrived on it.
  bool spoke = false;

  /// When it last received anything, or was opened.
  Duration lastByte;

  /// What a lease joining it is replayed (see [SseMux]).
  Duration? retry;
  SseEvent? greeting;
  final Map<String, SseEvent> snapshots = {};

  bool matches(List<String> wanted, {required bool live}) =>
      this.live == live && wanted.every(topics.contains);

  /// Whether it already gives [lease] what a fresh connection would.
  bool satisfies(_Lease lease) =>
      topics.contains(lease.topic) && (live || !lease.live);

  void close() {
    subscription?.cancel();
    subscription = null;
  }
}
