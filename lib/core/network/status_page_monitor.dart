/// Server-side health of ExpTech's services, as the public status page judges
/// it — the second half of the More tab's server-status dot.
///
/// [EndpointHealthMonitor] knows only what *this* device saw: a host it stopped
/// reaching. It cannot tell a regional outage from a bad Wi-Fi, and it says
/// nothing about a service the user has not opened yet. The status page
/// (exptech.dev/status/) probes every service from several vantage points and
/// publishes its headline as `summary.json`, computed by the same rules as the
/// page's banner, so the dot and the page the user lands on never disagree.
///
/// The dot is lit while the summary says `partial` or `outage` — no "seen"
/// state: as long as something is down, there is something to look at.
///
/// A summary only counts while it is fresh ([maxAge] by the calibrated clock):
/// the ETag cache answers with the last good copy when the network is gone,
/// and an outage that ended hours ago must not keep the dot lit. A stale,
/// missing or `unknown` summary lights nothing — the client-side monitor still
/// covers "I cannot reach you".
library;

import 'dart:async';
import 'dart:convert';

import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/network/api_client.dart';
import 'package:dpip/core/realtime/app_time.dart';
import 'package:flutter/widgets.dart';

/// One parsed `summary.json`: the overall level and when the server produced
/// it.
@immutable
class StatusSummary {
  const StatusSummary({required this.level, required this.generatedAt});

  /// `ok`, `partial`, `outage` or `unknown`; anything newer reads as unknown.
  final String level;

  /// The server's own timestamp for this summary (UTC).
  final DateTime generatedAt;

  /// Whether the level is one the status page shows as a problem.
  bool get isAbnormal => level == 'partial' || level == 'outage';

  /// Parses the decoded (or raw) JSON body; null when it is not a summary.
  ///
  /// Layout: `{version, generated_at (unix seconds), level, since, services}`.
  static StatusSummary? parse(Object? body) {
    var data = body;
    if (data is String) {
      try {
        data = jsonDecode(data);
      } on FormatException {
        return null;
      }
    }
    if (data is! Map) return null;
    final level = data['level'];
    final generated = data['generated_at'];
    if (level is! String || generated is! num) return null;
    return StatusSummary(
      level: level,
      generatedAt: DateTime.fromMillisecondsSinceEpoch(
        (generated * 1000).round(),
        isUtc: true,
      ),
    );
  }

  /// Whether this summary still describes now: at most [maxAge] old, and not
  /// more than [maxAge] ahead (a clock that jumped is not evidence).
  bool isFreshAt(DateTime now, Duration maxAge) =>
      now.difference(generatedAt).abs() <= maxAge;
}

class StatusPageMonitor extends ChangeNotifier with WidgetsBindingObserver {
  StatusPageMonitor({
    required this._fetch,
    DateTime Function()? now,
    this.interval = const Duration(minutes: 5),
    this.maxAge = const Duration(minutes: 10),
    this.resumeGap = const Duration(seconds: 30),
  }) : _now = now ?? (() => AppTime.utc);

  /// Reads the public summary through [client] — a plain GET, so the ETag
  /// interceptor revalidates it and no region failover applies.
  factory StatusPageMonitor.over(ApiClient client) =>
      StatusPageMonitor(fetch: () => client.getAbsolute(url));

  /// Published by the status page's snapshot service.
  static const String url = 'https://status.exptech.dev/data/summary.json';

  final Future<Object?> Function() _fetch;
  final DateTime Function() _now;

  /// How often the summary is re-read while the app is in the foreground.
  final Duration interval;

  /// How old a summary may be and still light the dot.
  final Duration maxAge;

  /// A resume this soon after the last read does not read again.
  final Duration resumeGap;

  StatusSummary? _summary;
  DateTime? _lastAttempt;
  Future<void>? _inFlight;
  Timer? _timer;
  bool _started = false;
  bool _disposed = false;
  bool _abnormal = false;

  /// Whether the status page currently reports a problem — what the dot
  /// watches.
  bool get abnormal => _abnormal;

  /// Begins watching. Call once, after the first frame.
  void start() {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    _schedule();
    unawaited(refresh());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _schedule();
        final last = _lastAttempt;
        if (last == null || _now().difference(last).abs() >= resumeGap) {
          unawaited(refresh());
        }
      case AppLifecycleState.hidden ||
          AppLifecycleState.paused ||
          AppLifecycleState.detached:
        // Nothing shows the dot in the background; reading on would only
        // spend the user's data.
        _timer?.cancel();
        _timer = null;
      case AppLifecycleState.inactive:
        break;
    }
  }

  void _schedule() {
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) => unawaited(refresh()));
  }

  /// Reads the summary once. Never throws: a failed read keeps the last
  /// summary, which then ages out by [maxAge] on its own.
  Future<void> refresh() => _inFlight ??= _read().whenComplete(() {
    _inFlight = null;
  });

  Future<void> _read() async {
    _lastAttempt = _now();
    try {
      final summary = StatusSummary.parse(await _fetch());
      if (summary == null) {
        Log.warning('service status: unreadable summary');
      } else {
        _summary = summary;
      }
    } catch (error) {
      // Offline is ordinary; the client-side monitor already reports it.
      Log.debug('service status: read failed ($error)');
    }
    _evaluate();
  }

  void _evaluate() {
    if (_disposed) return;
    final summary = _summary;
    final abnormal =
        summary != null &&
        summary.isAbnormal &&
        summary.isFreshAt(_now(), maxAge);
    if (abnormal == _abnormal) return;
    _abnormal = abnormal;
    Log.info(
      'service status: abnormal=$abnormal (level=${summary?.level} '
      'generated=${summary?.generatedAt.toIso8601String()})',
    );
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    if (_started) WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
