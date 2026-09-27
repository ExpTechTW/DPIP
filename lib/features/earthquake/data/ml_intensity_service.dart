/// [MlIntensityEstimator] for ML v1: fetches the model the first time the
/// 強震監視器 asks for it, keeps it on the device, and scores quakes in a
/// worker isolate.
///
/// **Where it comes from.** ExpTech's own hosts do not serve the model yet, so
/// it is fetched where TREM-Lite publishes it — its GitHub Pages site, then
/// jsDelivr's mirror of the same repository. Both send it gzip-encoded (about
/// 2.3 MB on the wire for 14.7 MB).
///
/// **Which file.** The SHA-256 is pinned: jsDelivr follows the repository's
/// `main`, and a retrained model published over the same name would otherwise
/// replace this one silently — with levels that no longer match the server's.
/// A file with another hash is refused, and the next source is tried.
///
/// **Kept.** A verified model is stored gzip-compressed in [MlModelStore] and
/// every later session builds from that copy, network or not. A copy that no
/// longer builds is dropped so the next attempt downloads afresh.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/network/api_client.dart';
import 'package:dpip/core/storage/ml_model_store.dart';
import 'package:dpip/features/earthquake/data/ml_intensity_worker.dart';
import 'package:dpip/features/earthquake/domain/eew.dart';
import 'package:dpip/features/earthquake/domain/eew_town_levels.dart';
import 'package:flutter/services.dart' show rootBundle;

/// The points a quake is scored at — the townships, by code, at the reference
/// coordinates the server and TREM-Lite score them at (`region.json`), which
/// differ from the app's own township centroids for 17 of the 368.
typedef MlTownPoints = ({
  List<String> codes,
  Float64List latitudes,
  Float64List longitudes,
});

/// Reads the bundled `assets/eew_points.json` (`{code: [lat, lon]}`).
Future<MlTownPoints> loadMlTownPoints() async =>
    parseMlTownPoints(await rootBundle.loadString('assets/eew_points.json'));

MlTownPoints parseMlTownPoints(String json) {
  final map = jsonDecode(json) as Map<String, dynamic>;
  final codes = map.keys.toList();
  return (
    codes: codes,
    latitudes: Float64List.fromList([
      for (final code in codes) ((map[code] as List)[0] as num).toDouble(),
    ]),
    longitudes: Float64List.fromList([
      for (final code in codes) ((map[code] as List)[1] as num).toDouble(),
    ]),
  );
}

/// Starts a worker — [MlIntensityWorker.spawn], replaceable in tests.
typedef MlWorkerSpawner = Future<MlIntensityWorker> Function({
  required Uint8List model,
  required bool gzipped,
  required Float64List latitudes,
  required Float64List longitudes,
});

class MlIntensityService implements MlIntensityEstimator {
  MlIntensityService({
    required this._client,
    required this._store,
    required this._now,
    this._points = loadMlTownPoints,
    this._spawn = MlIntensityWorker.spawn,
    this._sha256 = modelSha256,
    this._sources = sources,
  });

  final ApiClient _client;
  final MlModelStore _store;
  final DateTime Function() _now;
  final Future<MlTownPoints> Function() _points;
  final MlWorkerSpawner _spawn;
  final String _sha256;
  final List<String> _sources;

  /// The row name in [MlModelStore].
  static const String modelName = 'intensity_ml_v1';

  /// SHA-256 of `intensity_ml_v1.onnx` — the file the golden tests pin.
  static const String modelSha256 =
      'cf2969c816d64413d12d9fa3949e34424529189cc395ca718c8421188ddb5517';

  /// Tried in order.
  static const List<String> sources = [
    'https://exptechtw.github.io/TREM-Lite/models/intensity_ml_v1.onnx',
    'https://cdn.jsdelivr.net/gh/ExpTechTW/TREM-Lite@main/packages/core/static/models/intensity_ml_v1.onnx',
  ];

  /// How long a failed attempt holds off the next one — [prepare] is called
  /// on every alert update, and a phone offline mid-quake must not start a
  /// 2 MB download each time.
  static const Duration retryAfter = Duration(minutes: 1);

  MlIntensityWorker? _worker;
  List<String> _codes = const [];
  Future<bool>? _preparing;
  DateTime? _failedAt;

  (double, double, double, double)? _lastQuake;
  Future<Map<String, int>?>? _lastLevels;

  @override
  bool get ready => _worker != null;

  @override
  Future<bool> prepare() {
    if (_worker != null) return Future.value(true);
    final preparing = _preparing;
    if (preparing != null) return preparing;
    final failedAt = _failedAt;
    if (failedAt != null && _now().difference(failedAt) < retryAfter) {
      return Future.value(false);
    }
    return _preparing = _prepare().whenComplete(() => _preparing = null);
  }

  Future<bool> _prepare() async {
    try {
      final points = await _points();
      final stored = await _store.read(modelName);
      if (stored != null && stored.sha256 == _sha256) {
        try {
          await _start(points, stored.gzip, gzipped: true);
          return true;
        } catch (error) {
          Log.warning(
            'ml: the stored model does not build ($error); refetching',
          );
          await _store.delete(modelName);
        }
      }
      await _start(points, await _download(), gzipped: false);
      return true;
    } catch (error, stackTrace) {
      _failedAt = _now();
      Log.handle(error, stackTrace, 'ml: intensity model unavailable');
      return false;
    }
  }

  Future<void> _start(
    MlTownPoints points,
    Uint8List model, {
    required bool gzipped,
  }) async {
    final watch = Stopwatch()..start();
    _worker = await _spawn(
      model: model,
      gzipped: gzipped,
      latitudes: points.latitudes,
      longitudes: points.longitudes,
    );
    _codes = points.codes;
    Log.info('ml: $modelName ready in ${watch.elapsedMilliseconds} ms');
  }

  /// The model's uncompressed bytes from the first source that serves the
  /// pinned file, stored compressed on the way through.
  Future<Uint8List> _download() async {
    Object? lastError;
    for (final url in _sources) {
      try {
        final bytes = (await _client.getBytesAbsolute(url)).bytes;
        // Hashing and compressing 14.7 MB is off the UI isolate's budget.
        final (hash, packed) = await Isolate.run(
          () => (
            sha256.convert(bytes).toString(),
            Uint8List.fromList(gzip.encode(bytes)),
          ),
        );
        if (hash != _sha256) {
          lastError = StateError('$url served a different file ($hash)');
          Log.warning('ml: $lastError');
          continue;
        }
        await _store.write(
          modelName,
          gzip: packed,
          sha256: hash,
          fetchedAt: _now(),
        );
        return bytes;
      } catch (error) {
        lastError = error;
        Log.warning('ml: $url failed: $error');
      }
    }
    throw StateError('no source served the model: $lastError');
  }

  @override
  Future<Map<String, int>?> townLevels(EewInfo info) {
    final worker = _worker;
    if (worker == null) return Future.value();
    // Successive serials of one alert often repeat the same solution; the
    // answer is the same, so is the future.
    final quake = (info.magnitude, info.depth, info.latitude, info.longitude);
    final last = _lastLevels;
    if (last != null && quake == _lastQuake) return last;
    final codes = _codes;
    final levels = worker
        .levels(
          magnitude: info.magnitude,
          depth: info.depth,
          latitude: info.latitude,
          longitude: info.longitude,
        )
        .then<Map<String, int>?>(
          (levels) => {
            for (var i = 0; i < codes.length; i++) codes[i]: levels[i],
          },
        )
        .catchError((Object error) {
          Log.warning('ml: scoring failed: $error');
          return null;
        });
    _lastQuake = quake;
    _lastLevels = levels;
    return levels;
  }

  void dispose() {
    _worker?.dispose();
    _worker = null;
  }
}
