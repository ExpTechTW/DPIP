/// Bridge between ExpTech's terrain-RGB PNGs and MapLibre's DEM decoders.
library;

import 'dart:typed_data';

import 'package:dpip/core/network/api_paths.dart';
import 'package:image/image.dart' as img;

/// The tile authority answers every ExpTech tile (see [MapTileCache]), so this
/// file's [isTerrainPng] / [ensureTerrarium] are the single conversion point
/// shared by the Dio interceptor and the tile cache — a PNG that ever reaches
/// MapLibre has been rewritten once, here, and never anywhere else.
///
/// ## Why a rewrite is needed
/// The `/api/v1/map/terrain/` tiles are **Mapbox.com terrain-RGB**: an 8-bit
/// RGB pixel encodes
/// `height = (R·65536 + G·256 + B)/10 − 10000` metres (0 → sea level).
/// MapLibre Native only speaks two DEM encodings — `terrarium`
/// (`R·256 + G + B/256 − 32768`) and its own `mapbox`
/// (`num/256 − 32768`) — so it would read every Taiwan tile as a −32 km pit.
/// Rewriting to **terrarium** (16-bit, 1 m steps — a half-metre rounding on the
/// source's 0.1 m precision, invisible at render scale; Taiwan's 0–3952 m
/// survives losslessly) makes the tiles render as elevation without touching
/// native code.

/// Whether [uri] names an ExpTech terrain tile this app rewrites.
///
/// Host + path + extension, so radar/satellite/DPM PNGs are untouched.
bool isTerrainPng(Uri uri) =>
    uri.host == 'static.lb.exptech.dev' &&
    uri.path.contains(ApiPaths.mapTerrainV1) &&
    uri.path.endsWith('.png');

/// Rewrites an ExpTech terrain-RGB PNG into MapLibre's terrarium encoding.
///
/// Returns the converted bytes, or `null` when [png] is already terrarium (or
/// not decodable) — callers store the returned value if non-null, the input
/// otherwise, so the store converges on converted bytes and re-encoding never
/// repeats on a warm cache.
Uint8List? ensureTerrarium(Uint8List png) {
  final image = img.decodePng(png);
  if (image == null) return null;
  final raw = image.getBytes(order: img.ChannelOrder.rgb);
  // Terrarium sea level is R=128; Mapbox.com terrain-RGB sea is R≈0-1, and
  // every land pixel stays below R≈3 (Taiwan tops out at 3952 m). A mean R
  // below 64 is unambiguous.
  var sum = 0;
  var n = 0;
  for (var i = 0; i < raw.length; i += 48) {
    sum += raw[i];
    n++;
  }
  if (sum ~/ n >= 64) return null;
  for (var i = 0; i < raw.length; i += 3) {
    final num = (raw[i] << 16) | (raw[i + 1] << 8) | raw[i + 2];
    // t = (height + 32768); height = num/10 − 10000.
    final t = (num + 227680) ~/ 10;
    raw[i] = t >> 8;
    raw[i + 1] = t & 0xFF;
    raw[i + 2] = 0;
  }
  final out = img.Image.fromBytes(
    width: image.width,
    height: image.height,
    bytes: raw.buffer,
    numChannels: 3,
  );
  return Uint8List.fromList(img.encodePng(out));
}
