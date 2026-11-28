import 'dart:async';
import 'dart:io';

import 'package:dpip/core/geo/location_service.dart' show GpsFix;
import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/platform/eew_live_activity_data.dart';
import 'package:dpip/core/settings/region_store.dart';
import 'package:dpip/features/earthquake/data/s_wave_table_codec.dart';
import 'package:dpip/features/earthquake/domain/seismic_travel_time.dart';

/// Keeps the iOS EEW Live Activity widget supplied with what
/// `estimateLocalShaking` needs: the S-wave table and the observer.
///
/// The observer is resolved the way the app's own EEW card resolves it — the
/// last GPS fix, else the selected township's centroid — but the widget makes
/// that choice itself at render time, so both halves are kept: a fix is only
/// ever replaced by a newer fix, never erased because a later launch had no
/// fresh one ("the last stored fix").
///
/// The table is packed and written only when the app build differs from the
/// one that wrote the stored copy; an unknown build (code 0) always rewrites.
final class EewLiveActivityPublisher {
  EewLiveActivityPublisher({
    required this._data,
    required this._table,
    required this._appBuild,
    required this._lastFix,
    required this._fixes,
    required this._regions,
    required this._towns,
    bool? enabled,
  }) : _enabled = enabled ?? Platform.isIOS;

  final EewLiveActivityData _data;
  final Future<SeismicTravelTimeTable> _table;
  final int _appBuild;
  final Future<GpsFix?> Function() _lastFix;
  final Stream<GpsFix> _fixes;
  final RegionStore _regions;
  final TownDirectory _towns;
  final bool _enabled;

  StreamSubscription<GpsFix>? _fixSubscription;
  String? _publishedTown;
  bool _townPublished = false;
  bool _started = false;

  /// Starts publishing. Idempotent; a no-op off iOS.
  void start() {
    if (_started || !_enabled) return;
    _started = true;
    unawaited(_publishTable());
    unawaited(
      _lastFix().then((fix) {
        if (fix != null) _publishFix(fix);
      }),
    );
    _fixSubscription = _fixes.listen(_publishFix);
    _regions.addListener(_publishTown);
    _publishTown();
  }

  void dispose() {
    if (!_started) return;
    _started = false;
    unawaited(_fixSubscription?.cancel());
    _fixSubscription = null;
    _regions.removeListener(_publishTown);
  }

  Future<void> _publishTable() async {
    try {
      final stored = await _data.travelTimeVersion();
      if (_appBuild != 0 && stored == _appBuild) return;
      final bytes = SWaveTableCodec.encode(await _table);
      await _data.writeTravelTime(bytes, version: _appBuild);
    } on FormatException catch (error) {
      // The bundled table is always packable; this is a changed asset, and
      // the widget then shows 未提供 rather than a wrong arrival.
      Log.warning('Live Activity S-wave table not written: ${error.message}');
    }
  }

  void _publishFix(GpsFix fix) {
    unawaited(_data.writeFix(lat: fix.lat, lng: fix.lng));
  }

  void _publishTown() {
    final code = _regions.selectedCode;
    if (_townPublished && code == _publishedTown) return;
    _townPublished = true;
    _publishedTown = code;
    final town = _towns.byCode(code);
    unawaited(
      _data.writeTown(
        town == null ? null : (code: town.code, lat: town.lat, lng: town.lng),
      ),
    );
  }
}
