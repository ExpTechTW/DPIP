/// Keeps Android's MapLibre asking the app's tile store while the phone reports
/// no network.
library;

import 'dart:async';

import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/network/endpoint_health.dart';
import 'package:flutter/foundation.dart';
import 'package:maplibre_gl/maplibre_gl.dart' as maplibre;

/// MapLibre Android's view of connectivity, held at "connected".
///
/// ## Why
/// MapLibre Android listens for the OS connectivity broadcast, and while the
/// phone reports no network it never issues a tile request at all: native
/// `NetworkStatus::Offline` parks every pending request until the network
/// returns. The app's tile store answers *inside* that request — it is an
/// OkHttp interceptor in front of the network — so with no request there is no
/// answer, and tiles already on disk stayed invisible for as long as the phone
/// was offline. iOS never parks requests (it uses reachability only to retry
/// sooner), which is why only Android drew a blank map.
///
/// [attach] forces the flag on for every map, so each request reaches the
/// store; one the store cannot answer goes on to the network and fails there,
/// at once, like it does on iOS.
///
/// ## What forcing it costs, and [networkRestored]
/// MapLibre retries a request that failed for want of a connection on an
/// exponential backoff — 1 s, 2 s, 4 s … — and normally cuts the wait short
/// the moment the OS says the network is back. With the flag forced it no
/// longer hears that, so a tile nothing could answer while offline would wait
/// out its backoff after the network returned. [networkRestored] gives that
/// back: MapLibre retries on its own offline → online edge, so a brief flip
/// through offline wakes every one of them immediately. [watch] calls it when
/// the app's own requests show the network has come back.
class MapConnectivity {
  // Not an initializing formal: Dart has no private *named* parameter, and the
  // field must stay private.
  MapConnectivity({
    Future<void> Function(bool offline)? setOffline,
    Duration minRestoreInterval = const Duration(seconds: 5),
  }) : _setOffline = setOffline ?? maplibre.setOffline,
       // ignore: prefer_initializing_formals
       _minRestoreInterval = minRestoreInterval;

  /// The process's one instance — MapLibre's connectivity is process-wide too.
  static final MapConnectivity instance = MapConnectivity();

  final Future<void> Function(bool offline) _setOffline;
  final Duration _minRestoreInterval;

  /// Live maps' `forceOnlineMode`, by map. MapLibre's flag is process-wide,
  /// but it can only be forced through a map's own channel, so any live one
  /// will do.
  final Map<Object, Future<void> Function()> _maps = {};

  bool _restoring = false;
  Stopwatch? _sinceRestore;
  int? _failingHosts;
  VoidCallback? _unwatch;

  /// Whether MapLibre on this platform parks requests while offline.
  static bool get applies =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Forces [map]'s MapLibre to keep issuing requests, and remembers it for
  /// [networkRestored]. A no-op where [applies] is false.
  void attach(Object map, Future<void> Function() forceOnline) {
    if (!applies) return;
    _maps[map] = forceOnline;
    unawaited(_run(forceOnline, 'force online'));
  }

  /// Forgets [map] — its native view is gone and its channel with it.
  void detach(Object map) => _maps.remove(map);

  /// Wakes every request MapLibre is holding back for a connection.
  ///
  /// Throttled to one flip per [MapConnectivity.new]'s `minRestoreInterval`:
  /// a recovering network reports itself host by host, and one flip retries
  /// everything there is to retry.
  Future<void> networkRestored() async {
    if (!applies || _maps.isEmpty || _restoring) return;
    final since = _sinceRestore;
    if (since != null && since.elapsed < _minRestoreInterval) return;
    _sinceRestore = Stopwatch()..start();
    _restoring = true;
    try {
      await _setOffline(true);
      // Back on through a live map. If none answers, hand connectivity back to
      // MapLibre's own detection rather than leave it switched off: a parked
      // map is the failure this class exists to prevent, and the next map to
      // attach forces it on again.
      var restored = false;
      for (final forceOnline in _maps.values.toList().reversed) {
        if (await _run(forceOnline, 'restore online')) {
          restored = true;
          break;
        }
      }
      if (!restored) await _setOffline(false);
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'MapConnectivity.networkRestored');
    } finally {
      _restoring = false;
    }
  }

  /// Calls [networkRestored] whenever one of [health]'s hosts recovers from a
  /// failure streak — the app's own requests are its signal that the network
  /// is back. Replaces any earlier [watch].
  void watch(EndpointHealthMonitor health) {
    _unwatch?.call();
    _unwatch = null;
    if (!applies) return;
    _failingHosts = _countFailing(health);
    void listener() {
      final failing = _countFailing(health);
      final recovered = failing < (_failingHosts ?? 0);
      _failingHosts = failing;
      if (recovered) unawaited(networkRestored());
    }

    health.addListener(listener);
    _unwatch = () => health.removeListener(listener);
  }

  static int _countFailing(EndpointHealthMonitor health) =>
      health.entries.where((entry) => entry.consecutiveFailures > 0).length;

  static Future<bool> _run(Future<void> Function() call, String context) async {
    try {
      await call();
      return true;
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'MapConnectivity $context');
      return false;
    }
  }
}
