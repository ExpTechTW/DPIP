/// Keeps the native report heartbeat supplied with what it sends.
library;

import 'dart:async';

import 'package:dpip/core/geo/location_mode.dart';
import 'package:dpip/core/geo/location_service.dart' show GpsFix;
import 'package:dpip/core/geo/town.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/platform/background_location.dart';

/// Hands the native report heartbeat the push token and, while a township is
/// pinned by hand, the point reported for it — and clears that point on the
/// way back to automatic.
///
/// The heartbeat reports once when the device has had no successful report
/// for about three days, in every location mode, with no Flutter isolate
/// running and without ever asking for a fix. So it can only send what it was
/// given beforehand: this pushes both on start and again on every change. The
/// third input, the point and time of each foreground 2xx, is recorded where
/// the report is made (`BackgroundLocationService.recordReport`).
///
/// Independent of onboarding and of background reporting being armed: none of
/// it sends anything by itself, and the heartbeat skips a device that has never
/// had a successful report.
class ReportHeartbeatSync {
  ReportHeartbeatSync({
    required this._native,
    required this._mode,
    required this._manualFix,
    required this._token,
    required this._tokenChanges,
  });

  final BackgroundLocationService _native;
  final LocationMode _mode;

  /// The point reported for a pinned township (`LocationService.manualFix`).
  final Future<GpsFix> Function(Town town) _manualFix;
  final String? Function() _token;
  final Stream<String> _tokenChanges;

  StreamSubscription<String>? _tokenSub;

  /// The point push before this one; the next waits for it, so the last
  /// change is also the last write.
  Future<void> _points = Future<void>.value();
  bool _started = false;

  /// Pushes the current token and point, then follows both. Idempotent.
  void start() {
    if (_started) return;
    _started = true;
    final token = _token();
    if (token != null) unawaited(_pushToken(token, changed: false));
    _tokenSub = _tokenChanges.listen(
      (token) => unawaited(_pushToken(token, changed: true)),
    );
    _mode.addListener(_onModeChanged);
    _queuePoint(changed: false);
  }

  void _onModeChanged() => _queuePoint(changed: true);

  void _queuePoint({required bool changed}) {
    _points = _points.then((_) => _pushPoint(changed: changed));
  }

  /// Completes once every push queued so far is done. For tests.
  Future<void> get settled => _points;

  Future<void> _pushToken(String token, {required bool changed}) async {
    if (!await _native.setReportIdentity(token)) return;
    final line = 'report heartbeat: push token handed to native';
    changed ? Log.info(line) : Log.debug(line);
  }

  Future<void> _pushPoint({required bool changed}) async {
    try {
      final town = _mode.manualTown;
      if (town == null) {
        if (!await _native.clearManualPoint()) return;
        final line = 'report heartbeat: automatic — resends the last report';
        changed ? Log.info(line) : Log.debug(line);
        return;
      }
      final fix = await _manualFix(town);
      // The mode moved on while the point was computed; the push queued for
      // that change writes the current state.
      if (_mode.manualTown?.code != town.code) return;
      if (!await _native.setManualPoint(lat: fix.lat, lng: fix.lng)) return;
      final line = 'report heartbeat: pinned to ${town.code}';
      changed ? Log.info(line) : Log.debug(line);
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'report heartbeat: manual point');
    }
  }

  void dispose() {
    _mode.removeListener(_onModeChanged);
    unawaited(_tokenSub?.cancel());
    _tokenSub = null;
  }
}
