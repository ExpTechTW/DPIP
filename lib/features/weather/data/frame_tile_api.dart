/// Shared frame-keyed tile API for the v2 raster overlays (radar, satellite,
/// QPESUMS, wind forecast).
library;

import 'dart:typed_data';

import 'package:dpip/core/network/api_client.dart';
import 'package:dpip/core/network/api_paths.dart';
import 'package:dpip/core/network/api_region.dart';
import 'package:dpip/core/network/meteor_decode.dart';

/// Tile endpoints for one v2 raster overlay.
///
/// Radar and QPESUMS use a timestamp directly. Satellite puts its channel and
/// style in the path. Wind is the exceptional mutable forecast: its public
/// frame id combines valid time and model cycle (`valid@cycle`) so a newer run
/// is a different identity all the way through the timeline, MapLibre L1 and
/// SQLite L2. [tileUrl] turns that opaque id into the server's `cycle/valid`
/// path.
class FrameTileApi {
  FrameTileApi(this._client, this.path, {this.channel, this.style, this.model});

  final ApiClient _client;

  /// The overlay's URL path segment: `radar`, `satellite`, `qpesums`, or
  /// `wind`.
  final String path;

  /// Satellite path segment selecting a band or derived product. Null means
  /// the service's B13 default; radar / QPESUMS never set it.
  final String? channel;

  /// Satellite style path segment (`normal` / `jma` / `bd`). Mutable because
  /// the map's style menu switches it live. Named products always use
  /// `normal`, as their palette is intrinsic to the product.
  String? style;

  /// Wind model path segment (`gfs` / `ecmwf`). Required when [path] is wind;
  /// radar / satellite / QPESUMS never set it.
  final String? model;

  /// The v2 frame list lives on `api.core-tnn1` (no region failover).
  static const ApiTier _listTier = ApiTier.coreExclusiveApi;

  /// v2 tiles live on `static.core-tnn1` (no region failover).
  static const ApiTier _tileTier = ApiTier.coreStaticExclusive;

  /// Available opaque frame ids, **newest valid time first**.
  Future<List<String>> getFrames() async {
    final body = await _client.get(_listTier, _listPath) as List;
    return path == 'wind' ? windFramesFromList(body) : framesFromList(body);
  }

  String get _listPath => switch (path) {
    'satellite' => '${ApiPaths.tiles}/satellite/${channel ?? '13'}/list',
    'wind' => '${ApiPaths.tiles}/wind/$_windModel/list',
    _ => '${ApiPaths.tiles}/$path/list',
  };

  /// XYZ WebP raster tile URL template for [frame].
  String tileUrl(String frame) {
    final host = _client.hostsFor(_tileTier).first;
    if (path == 'satellite') {
      return '$host${ApiPaths.tiles}/satellite/'
          '${channel ?? '13'}/$_satelliteStyle/'
          '$frame/{z}/{x}/{y}.webp';
    }
    if (path == 'wind') {
      final parts = windFrameParts(frame);
      return '$host${ApiPaths.tiles}/wind/$_windModel/'
          '${parts.cycle}/${parts.validTime}/{z}/{x}/{y}.webp';
    }
    return '$host${ApiPaths.tiles}/$path/$frame/{z}/{x}/{y}.webp';
  }

  String get _satelliteStyle {
    final selected = channel ?? '13';
    if (int.tryParse(selected) == null) return 'normal';
    final selectedStyle = style ?? 'normal';
    return selectedStyle == 'gray' ? 'normal' : selectedStyle;
  }

  String get _windModel =>
      model ?? (throw StateError('A wind FrameTileApi requires a model'));

  /// Restores the delta-encoded list `[base, Δ, Δ, …]` to absolute timestamps
  /// and returns them **newest first** as strings (the frame id used by
  /// [tileUrl]). Empty in → empty out. Exposed for unit testing.
  static List<String> framesFromList(List<dynamic> deltas) => [
    for (final v in MeteorDecode.deltaSeconds(deltas).reversed) v.toString(),
  ];

  /// Converts the wind list's `{t: validTime, c: cycle}` rows into stable,
  /// opaque frame ids. Valid time comes first so the shared timeline can read
  /// it without knowing weather API details; cycle remains part of identity so
  /// two model runs can never share a native or SQLite cache key.
  static List<String> windFramesFromList(List<dynamic> rows) {
    final frames = <({int validTime, int cycle})>[];
    for (final row in rows) {
      if (row is! Map || row['t'] is! int || row['c'] is! int) {
        throw const FormatException('invalid wind frame list');
      }
      frames.add((validTime: row['t'] as int, cycle: row['c'] as int));
    }
    frames.sort((a, b) => b.validTime.compareTo(a.validTime));
    return [for (final frame in frames) '${frame.validTime}@${frame.cycle}'];
  }

  /// Decodes the app's opaque `valid@cycle` wind frame id.
  static ({String validTime, String cycle}) windFrameParts(String frame) {
    final separator = frame.indexOf('@');
    if (separator <= 0 ||
        separator != frame.lastIndexOf('@') ||
        separator == frame.length - 1) {
      throw FormatException('invalid wind frame id: $frame');
    }
    final validTime = frame.substring(0, separator);
    final cycle = frame.substring(separator + 1);
    if (int.tryParse(validTime) == null || int.tryParse(cycle) == null) {
      throw FormatException('invalid wind frame id: $frame');
    }
    return (validTime: validTime, cycle: cycle);
  }

  /// The raw WND1 field for the exact model cycle used by [tileUrl].
  Future<Uint8List> fetchWindBin(String frame) async {
    final parts = windFrameParts(frame);
    return (await _client.getBytes(
      _tileTier,
      '${ApiPaths.windV1}/$_windModel/'
      '${parts.cycle}/${parts.validTime}.bin',
    )).bytes;
  }
}
