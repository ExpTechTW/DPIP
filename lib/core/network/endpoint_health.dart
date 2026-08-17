/// Client-side health of the multi-active API endpoints, per service × tier ×
/// host.
///
/// The app reaches region-pinned hosts (`api.lb-tpe1.exptech.dev`, …) instead
/// of DNS-balanced bare hosts, so *it* is the only thing that can observe which
/// region is actually answering. [ApiClient] feeds every request outcome into
/// the monitor: a retryable failure (connection drop, timeout, 5xx) marks the
/// tried host down-ish, a success marks it up.
///
/// Outcomes are bucketed by **service × tier × host**: the same region carries
/// different services (EEW/RTS on `lbApi`, radar lists on
/// `coreExclusiveApi` → `api.core-tnn1`), and one service's dead host may be
/// another's healthy one. The More → 伺服器狀態 screen renders this map as a
/// table — rows are services, columns are tier groups, cells are the regions
/// each service was observed on.
library;

import 'package:dpip/core/network/api_region.dart';
import 'package:flutter/foundation.dart';

/// The service a request carried — derived from the path so [ApiClient]'s
/// callers never have to name it.
enum EndpointService {
  eew,
  rts,
  radar,
  satellite,
  qpesums,
  wind,
  dpm,
  weather,
  rain,
  lightning,
  typhoon,
  report,
  tremStation,
  event,
  location,
  notify,
  other;

  /// Maps a wire path to the service it belongs to. The first segment od the
  /// path after `/api/` decides; the families share the `ApiPaths` constants.
  static EndpointService ofPath(String path) {
    if (path.startsWith('/api/v2/eq/eew')) return eew;
    if (path.startsWith('/api/v2/trem/rts')) return rts;
    if (path.contains('/tiles/radar')) return radar;
    if (path.contains('/tiles/satellite')) return satellite;
    if (path.contains('/tiles/qpesums')) return qpesums;
    if (path.contains('/tiles/wind') || path.startsWith('/api/v1/wind')) {
      return wind;
    }
    if (path.contains('/tiles/dpm')) return dpm;
    if (path.startsWith('/api/v5/meteor/weather')) return weather;
    if (path.startsWith('/api/v5/meteor/rain')) return rain;
    if (path.startsWith('/api/v5/meteor/lightning')) return lightning;
    if (path.startsWith('/api/v5/meteor/typhoon')) return typhoon;
    if (path.startsWith('/api/v2/eq/report')) return report;
    if (path.startsWith('/api/v1/trem/')) return tremStation;
    if (path.startsWith('/api/v1/dpip')) return event;
    if (path.startsWith('/api/v2/location')) return location;
    if (path.startsWith('/api/v2/notify')) return notify;
    return other;
  }
}

/// How [EndpointHealthMonitor] currently judges one service host.
enum EndpointState {
  /// No request has touched this host since the app started.
  unknown,

  /// The last request to this host succeeded and it has no consecutive
  /// failure streak.
  healthy,

  /// The last request failed once — a blip, not yet a determination.
  degraded,

  /// Multiple consecutive retryable failures — the client considers the host
  /// unreachable and will keep failing over around it.
  down,
}

/// One service host's observed behaviour since app start.
@immutable
class EndpointHealth {
  const EndpointHealth({
    required this.service,
    required this.tier,
    required this.host,
    required this.state,
    required this.lastSuccess,
    required this.lastFailure,
    required this.consecutiveFailures,
  });

  /// The service the requests carried (EEW, RTS, radar lists…).
  final EndpointService service;

  /// The service tier the requests hit (EEW/RTS on `lbApi`, radar on
  /// `coreExclusiveApi` …).
  final ApiTier tier;

  /// Host without scheme, e.g. `api.lb-tpe1.exptech.dev`.
  final String host;

  final EndpointState state;

  /// Last time a request to this host completed successfully. Null if none.
  final DateTime? lastSuccess;

  /// Last time a retryable failure was observed on this host. Null if none.
  final DateTime? lastFailure;

  /// Consecutive retryable failures since the last success (or since start).
  final int consecutiveFailures;

  /// Uppercase region code the host lives in — `api.lb-tpe1.exptech.dev` →
  /// `TPE1`. Also covers the static hosts (`static.core-tnn1…`) and legacy
  /// `api-1` (no region → the host's own last segment).
  String get regionCode {
    final core = RegExp(r'-(tpe1|khh1|tyo1|tnn1)\.').firstMatch(host);
    if (core != null) return core.group(1)!.toUpperCase();
    return host.split('.').first.toUpperCase();
  }
}

/// Tracks per-service-host request outcomes so the UI can show which region is
/// being preferred and which one the client has stopped trusting.
class EndpointHealthMonitor extends ChangeNotifier {
  final Map<String, _HostState> _hosts = {};

  /// An API request to [hostUrl] on [tier] for [path] completed with a 2xx/3xx.
  /// The URL is keyed by hostname (scheme stripped).
  void success(ApiTier tier, String hostUrl, String path) {
    final key = _keyOf(EndpointService.ofPath(path), tier, hostUrl);
    final s = _hosts.putIfAbsent(key, _HostState.new);
    final changed =
        s.lastSuccess == null ||
        s.consecutiveFailures > 0 ||
        s.state != EndpointState.healthy;
    s.consecutiveFailures = 0;
    s.lastSuccess = _now();
    s.state = EndpointState.healthy;
    if (changed) notifyListeners();
  }

  /// A retryable failure (transport fault, timeout, 5xx) hit [hostUrl] on
  /// [tier] for [path].
  ///
  /// Non-retryable outcomes (4xx, cancellation, certificate errors) never reach
  /// here — they are the client's problem, not the host's.
  void failure(ApiTier tier, String hostUrl, String path) {
    final key = _keyOf(EndpointService.ofPath(path), tier, hostUrl);
    final s = _hosts.putIfAbsent(key, _HostState.new);
    s.consecutiveFailures++;
    s.lastFailure = _now();
    s.state = s.consecutiveFailures >= 2
        ? EndpointState.down
        : EndpointState.degraded;
    notifyListeners();
  }

  /// Health for [service] × [tier] × [host], or null if no request has touched
  /// it yet.
  EndpointHealth? of(EndpointService service, ApiTier tier, String host) {
    final s = _hosts[_keyOf(service, tier, host)];
    if (s == null) return null;
    return EndpointHealth(
      service: service,
      tier: tier,
      host: host,
      state: s.state,
      lastSuccess: s.lastSuccess,
      lastFailure: s.lastFailure,
      consecutiveFailures: s.consecutiveFailures,
    );
  }

  /// All known service hosts, first-seen order.
  List<EndpointHealth> get entries => [
    for (final e in _hosts.entries) _entryOf(e.key, e.value),
  ];

  /// Whether any service host is judged unhealthy (down or still-degraded) —
  /// what the More tab's dot and the status card's dot watch.
  bool get needsAttention {
    for (final s in _hosts.values) {
      if (s.state == EndpointState.down || s.state == EndpointState.degraded) {
        return true;
      }
    }
    return false;
  }

  /// Aggregate across all observed service hosts: `down` if any is down,
  /// `degraded` if any is degraded and none down, healthy if every observed
  /// host is healthy, unknown when nothing has been observed yet.
  EndpointState get summary {
    var degraded = false;
    for (final s in _hosts.values) {
      if (s.state == EndpointState.down) return EndpointState.down;
      if (s.state == EndpointState.degraded) degraded = true;
    }
    if (degraded) return EndpointState.degraded;
    return _hosts.isEmpty ? EndpointState.unknown : EndpointState.healthy;
  }

  static String _keyOf(EndpointService service, ApiTier tier, String hostUrl) =>
      '${service.name}\u0000${tier.name}\u0000${_hostOf(hostUrl)}';

  EndpointHealth _entryOf(String key, _HostState s) {
    final first = key.indexOf('\u0000');
    final serviceName = key.substring(0, first);
    final rest = key.substring(first + 1);
    final sep = rest.indexOf('\u0000');
    final tierName = rest.substring(0, sep);
    final host = rest.substring(sep + 1);
    return EndpointHealth(
      service: EndpointService.values.byName(serviceName),
      tier: ApiTier.values.byName(tierName),
      host: host,
      state: s.state,
      lastSuccess: s.lastSuccess,
      lastFailure: s.lastFailure,
      consecutiveFailures: s.consecutiveFailures,
    );
  }

  static DateTime _now() => DateTime.now();

  static String _hostOf(String url) {
    final scheme = url.indexOf('://');
    if (scheme == -1) return url;
    var host = url.substring(scheme + 3);
    final slash = host.indexOf('/');
    if (slash != -1) host = host.substring(0, slash);
    return host;
  }
}

class _HostState {
  EndpointState state = EndpointState.unknown;
  DateTime? lastSuccess;
  DateTime? lastFailure;
  int consecutiveFailures = 0;
}
