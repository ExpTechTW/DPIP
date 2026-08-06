/// [NotifyRepository] backed by the region-aware [NotifyApi].
library;

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/geo/location_api.dart';
import 'package:dpip/core/geo/location_service.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/network/api_exception.dart';
import 'package:dpip/features/notification/data/notify_api.dart';
import 'package:dpip/features/notification/domain/notify_repository.dart';
import 'package:dpip/features/notification/domain/notify_settings.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Owns the wire-list → [NotifySettings] mapping and converts transport/decode
/// errors into typed [Failure]s via [guardResult], so presentation never sees
/// a raw `DioException` or a malformed list.
///
/// `/v2/notify/{token}` 401s whenever the backend has never seen this push
/// token — normally because `/v2/location` hasn't fired yet for it (the app's
/// only registration path is a distance-triggered background report, so a
/// fresh install or a stationary device may not have registered at all). A 401
/// is therefore recovered once: register the device's current position for
/// this token via [LocationApi], then retry the call that failed. Any other
/// outcome — success, a different error, or a registration that itself
/// fails — is returned as-is.
class NotifyRepositoryImpl implements NotifyRepository {
  const NotifyRepositoryImpl(this._api, this._locationApi, this._location);

  final NotifyApi _api;
  final LocationApi _locationApi;
  final LocationService _location;

  /// Cool-down applied twice during 401 recovery: before the registration
  /// call, and again before retrying the call that 401'd.
  ///
  /// Each request in this recovery — the original 401, the registration POST,
  /// the retry GET — counts against the backend's short-window rate limit for
  /// this token; back-to-back with no gap 429s just as reliably whether it's
  /// the registration or the retry that fires immediately (confirmed live: a
  /// registration that itself succeeded still had its immediate retry 429).
  /// The legacy app carried the same delay for the same recovery. The
  /// caller's loading state (page spinner / per-row spinner) already spans the
  /// whole `fetch`/`setChannel` call, so nothing else needs to show it.
  static const _locationRecoveryDelay = Duration(seconds: 2);

  @override
  Future<Result<NotifySettings>> fetch(String token) =>
      _guardWithLocationRecovery(
        token,
        'getNotify',
        () => _api.getNotify(token),
      );

  @override
  Future<Result<NotifySettings>> setChannel(
    String token,
    NotifyChannel channel,
    int optionIndex,
  ) => _guardWithLocationRecovery(
    token,
    'setNotify(${channel.name})',
    () => _api.setNotify(token, channel.index, optionIndex),
  );

  /// Runs [call] and logs its outcome — every attempt, not just the failures
  /// inside the 401 path — so a 429 (or anything else) is visible in the
  /// in-app log viewer exactly where it happened, instead of having to be
  /// inferred from timing.
  Future<Result<NotifySettings>> _guardWithLocationRecovery(
    String token,
    String label,
    Future<List<dynamic>> Function() call,
  ) async {
    try {
      final settings = _map(await call());
      Log.info('notify: $label → OK');
      return Ok(settings);
    } catch (error) {
      _logRequestFailure(label, error);
      final unauthorized =
          error is DioException && error.response?.statusCode == 401;
      if (!unauthorized) return Err(mapException(error));

      await Future<void>.delayed(_locationRecoveryDelay);
      if (!await _registerLocation(token)) return Err(mapException(error));
      // Same cool-down again: the registration POST and the retry GET are two
      // more requests against the same short window, right on the heels of
      // the 401 that already spent it — an immediate retry here 429s just as
      // reliably as an immediate registration did.
      await Future<void>.delayed(_locationRecoveryDelay);

      try {
        final settings = _map(await call());
        Log.info('notify: $label retry → OK');
        return Ok(settings);
      } catch (retryError) {
        _logRequestFailure('$label retry', retryError);
        return Err(mapException(retryError));
      }
    }
  }

  /// Logs a failed `/v2/notify` request: the HTTP status for a plain non-2xx
  /// (in practice almost always the backend's own rate limit, 429 — routine,
  /// not a bug), or the full error via [Log.handle] for anything unexpected
  /// (timeout, no connection, a malformed body).
  static void _logRequestFailure(String label, Object error) {
    if (error is DioException && error.response != null) {
      Log.warning('notify: $label → HTTP ${error.response?.statusCode}');
    } else {
      Log.handle(error, StackTrace.current, 'notify: $label');
    }
  }

  /// Best-effort device-location registration so the backend can create a
  /// notify record for [token]. Uses whatever position [LocationService] can
  /// get without prompting — a fresh cached fix (which may be network-derived,
  /// not GPS) before a live one — since any real position unblocks
  /// `/v2/notify`; precision doesn't matter here. Never throws; false when no
  /// position or app metadata could be obtained, or the request itself fails.
  ///
  /// Logs the request and its outcome — including a non-2xx, which in practice
  /// is the backend's own rate limit (429) rather than a bug — so a repeat of
  /// this shows up in the in-app log viewer instead of needing an external
  /// request replay to diagnose.
  Future<bool> _registerLocation(String token) async {
    final fix = await _location.currentFix();
    if (fix == null) {
      Log.info('notify: register location — no position available, skipped');
      return false;
    }
    try {
      final info = await PackageInfo.fromPlatform();
      final platform = Platform.isIOS ? 1 : 0;
      Log.info(
        'notify: register location → platform=$platform '
        'version=${info.version} lat=${fix.lat} lng=${fix.lng} '
        'token=…${_redactToken(token)}',
      );
      await _locationApi.updateDeviceLocation(
        platform: platform,
        token: token,
        version: info.version,
        lat: fix.lat,
        lng: fix.lng,
      );
      Log.info('notify: register location → OK');
      return true;
    } on DioException catch (error) {
      // A non-2xx here is routine load-shedding by the backend (429), not a
      // bug — log it plainly rather than forwarding to crash reporting.
      Log.warning(
        'notify: register location → HTTP ${error.response?.statusCode}',
      );
      return false;
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'notify: register location');
      return false;
    }
  }

  /// Last 6 characters of [token] — enough to correlate log lines within a
  /// session without printing the full push token (the developer diagnostics
  /// page redacts it the same way from "Copy all").
  static String _redactToken(String token) =>
      token.length <= 6 ? token : token.substring(token.length - 6);

  NotifySettings _map(List<dynamic> raw) =>
      NotifySettings.fromWire(raw.cast<int>());
}
