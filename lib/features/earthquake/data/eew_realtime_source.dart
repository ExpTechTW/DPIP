import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/network/api_exception.dart';
import 'package:dpip/core/network/sse_event.dart';
import 'package:dpip/core/realtime/app_time.dart';
import 'package:dpip/core/realtime/elapsed.dart';
import 'package:dpip/core/realtime/sse_realtime_source.dart';
import 'package:dpip/features/earthquake/domain/eew.dart';
import 'package:dpip/features/earthquake/domain/eew_feed.dart';
import 'package:flutter/foundation.dart' show listEquals;

/// The live EEW feed, streamed over Server-Sent Events (`/api/v2/eq/eew?sse=1`).
///
/// Extends the generic [SseRealtimeSource] with the EEW specifics — nothing here
/// touches connection, buffering, or reconnection. [decode] parses each event's
/// `data:` with the same [Eew.fromJson] mapping the one-shot GET used, so the
/// data format is unchanged by the move to SSE.
///
/// Liveness is [SseLiveness.connectionOpen] (the default): the EEW stream is
/// **silent between earthquakes** apart from the server's keep-alive pings, so
/// an open connection that is still delivering — not event recency — is the
/// liveness signal; a quiet-but-connected feed stays `live` (connected, no
/// alert) instead of aging to offline, while one that has missed its pings is
/// dropped and reconnected rather than trusted. This mirrors the previous
/// fetch-freshness choice ([timestampOf] is null): feed liveness, not payload
/// age, drives staleness.
///
/// **While the stream is down, the one-shot GET stands in for it.** A network
/// that will not hold a long-lived connection — or a stream that keeps
/// dropping — would otherwise leave the alert list frozen at whatever it was
/// when the stream last spoke, and an earthquake that starts during the outage
/// would never reach the screen at all. So once the stream has been failing
/// for [fallbackGrace], the source polls the same list every
/// [fallbackInterval] and answers from the latest snapshot, through the same
/// decode and agency filters as a streamed frame.
///
/// That answer is flagged as a fallback ([servingFallback]), and the channel
/// never classifies it better than stale: a snapshot every ten seconds cannot
/// promise what `live` promises, that an alert reaches the screen within a
/// second of the server having it. The data is shown — flagged as possibly out
/// of date, which is the truth — and the feed is `live` again only once the
/// stream answers, at which point polling stops at once and any poll still in
/// flight is discarded.
///
/// Every answer — streamed or polled — passes through [reduceEewFeed] on its
/// way out, so what the channel publishes is never a report older than one
/// already shown: the server a reconnect or a poll lands on may be a serial
/// behind the one before it.
class EewRealtimeSource extends SseRealtimeSource<List<Eew>> {
  /// [connect] opens one EEW SSE connection — in production
  /// `EarthquakeApi.openEewSse`; the source calls it again to reconnect.
  ///
  /// [poll] fetches the same alert list once, as raw JSON — in production
  /// `EarthquakeApi.getEewRealtime`. Without it there is no fallback.
  ///
  /// [cwaOnly] is read fresh on every [decode] and every poll (a closure, not
  /// a captured bool) so toggling `EewCwaOnlySettings` takes effect on the
  /// very next event instead of needing the connection to be rebuilt.
  ///
  /// [now] stamps each snapshot for the reducer — the calibrated clock in
  /// production, since it is compared with server-stamped instants.
  EewRealtimeSource(
    Stream<SseEvent> Function() connect, {
    required bool Function() cwaOnly,
    Future<List<dynamic>> Function()? poll,
    Elapsed? elapsed,
    Future<void> Function(Duration delay)? delay,
    Random? random,
    DateTime Function()? now,
  }) : this._(
         connect,
         cwaOnly,
         poll,
         elapsed ?? SystemElapsed(),
         delay,
         random,
         now ?? (() => AppTime.utc),
       );

  EewRealtimeSource._(
    Stream<SseEvent> Function() connect,
    this.cwaOnly,
    this._poll,
    this._monotonic,
    Future<void> Function(Duration delay)? delay,
    Random? random,
    this._now,
  ) : super(
        connect: connect,
        label: 'eew',
        elapsed: _monotonic,
        delay: delay,
        random: random,
      );

  /// How long the stream must have been failing before the fallback starts:
  /// past the feed's stale threshold, so the ordinary reconnect after a drop —
  /// a second or two — costs the server no extra request, and an app that is
  /// just starting does not poll before its stream has had a chance.
  static const Duration fallbackGrace = Duration(seconds: 3);

  /// How often the alert list is polled while the stream is down.
  static const Duration fallbackInterval = Duration(seconds: 10);

  /// How long one polled snapshot is answered with after it lands: one
  /// interval, plus room for the next poll's round trip. Past it the polls
  /// have stopped landing, the source answers `Err`, and the channel ages the
  /// feed to offline on its usual schedule.
  static const Duration fallbackHold = Duration(seconds: 15);

  final bool Function() cwaOnly;
  final Future<List<dynamic>> Function()? _poll;
  final Elapsed _monotonic;
  final DateTime Function() _now;

  /// Survives reconnects, failovers and the switch to polling and back —
  /// that is the point of it.
  EewFeedState _feed = EewFeedState.initial;

  /// When the stream started failing, or null while it answers.
  Duration? _downSince;

  /// When the last poll was sent, or null if none has been this outage.
  Duration? _lastPollAt;

  bool _polling = false;
  bool _closed = false;

  /// Bumped whenever the fallback stops, so a poll still in flight cannot
  /// land after the stream came back and replace a streamed answer.
  int _pollEpoch = 0;

  /// The latest polled snapshot and when it landed.
  ({List<Eew> alerts, Duration at})? _snapshot;

  bool _servingFallback = false;

  @override
  bool get servingFallback => _servingFallback;

  /// The answer, folded through [reduceEewFeed]. The channel calls this once
  /// a second whether or not a new frame arrived, so the fold runs on the same
  /// snapshot repeatedly; it is idempotent for an unchanged one.
  @override
  Future<Result<List<Eew>>> fetch() async {
    final result = await _fetchUnreduced();
    return result.map((frame) {
      _feed = reduceEewFeed(_feed, frame, _now());
      return _feed.visible;
    });
  }

  Future<Result<List<Eew>>> _fetchUnreduced() async {
    final streamed = await super.fetch();
    final poll = _poll;
    if (poll == null || _closed) return streamed;
    if (streamed.isOk) {
      _stopFallback();
      return streamed;
    }

    final now = _monotonic.elapsed;
    final downSince = _downSince ??= now;
    final lastPoll = _lastPollAt;
    if (!_polling &&
        now - downSince >= fallbackGrace &&
        (lastPoll == null || now - lastPoll >= fallbackInterval)) {
      _startPoll(poll, now);
    }

    final snapshot = _snapshot;
    if (snapshot == null || now - snapshot.at > fallbackHold) {
      _servingFallback = false;
      return streamed;
    }
    _servingFallback = true;
    return Ok(snapshot.alerts);
  }

  void _startPoll(Future<List<dynamic>> Function() poll, Duration now) {
    if (_lastPollAt == null) {
      Log.warning(
        '[eew] SSE down for ${fallbackGrace.inSeconds}s — polling the alert '
        'list every ${fallbackInterval.inSeconds}s until it is back',
      );
    }
    _polling = true;
    _lastPollAt = now;
    final epoch = _pollEpoch;
    unawaited(_runPoll(poll, epoch));
  }

  Future<void> _runPoll(
    Future<List<dynamic>> Function() poll,
    int epoch,
  ) async {
    final result = await guardResult(
      () async => _alertsFrom(await poll()),
      // An unreachable server is what an outage looks like and is already
      // being logged once a second by the channel; a body that does not
      // decode is a fault, and keeps the full report.
      shouldLog: (failure) =>
          failure is! NetworkFailure && failure is! TimeoutFailure,
    );
    if (epoch != _pollEpoch) return; // the stream came back meanwhile
    _polling = false;
    switch (result) {
      case Ok(:final value):
        _snapshot = (alerts: value, at: _monotonic.elapsed);
      case Err(:final failure):
        Log.warning('[eew] fallback poll failed: ${failure.message}');
    }
  }

  void _stopFallback() {
    if (_lastPollAt != null) Log.info('[eew] SSE is back — polling stopped');
    _pollEpoch++;
    _downSince = null;
    _lastPollAt = null;
    _polling = false;
    _snapshot = null;
    _servingFallback = false;
  }

  /// A background stint ends the outage as far as the fallback is concerned:
  /// resuming opens a fresh stream, which deserves its own grace before any
  /// poll — and a snapshot from before the pause is not one to answer with.
  @override
  void pause() {
    _stopFallback();
    super.pause();
  }

  @override
  void dispose() {
    _closed = true;
    _stopFallback();
    super.dispose();
  }

  @override
  List<Eew> decode(String data) => _alertsFrom(jsonDecode(data) as List);

  /// The one mapping both paths share: JMA never, and only CWA when the user
  /// asked for that.
  List<Eew> _alertsFrom(List<dynamic> raw) {
    final all = [
      for (final item in raw) Eew.fromJson(item as Map<String, dynamic>),
    ];
    final onlyCwa = cwaOnly();
    return [
      for (final e in all)
        if (!e.isJma && (!onlyCwa || e.isCwa)) e,
    ];
  }

  /// Null on purpose: EEW uses connection/fetch-freshness. `EewInfo.time` recedes
  /// within a single active event while fresh updates keep arriving, so payload
  /// age would false-positive "stale" mid-alert.
  @override
  DateTime? timestampOf(List<Eew> value) => null;

  /// Element-wise equality so the channel dedups emissions (each decoded event
  /// yields a fresh list, whose default identity `==` would never match). `Eew`
  /// is a value type.
  @override
  bool sameData(List<Eew>? a, List<Eew>? b) => listEquals(a, b);
}
