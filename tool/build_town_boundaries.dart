/// Re-encodes the township boundary polygons into the compact binary the app
/// bundles (`assets/map/town_boundaries.bin.gz`).
///
/// Source of truth is the human-readable `town_boundaries.json.gz`
/// (`{ code: { b: bbox, p: [polygon…] } }`, rings are flat `[lng,lat,…]`).
/// That JSON stores coordinates as text floats, which gzip can't pack tightly.
/// This tool rewrites the geometry as **delta + zig-zag varint** integers
/// (coordinates are ≤4 decimals, so `×1e4` is lossless): each coordinate is the
/// signed delta from the previous vertex, zig-zag-mapped to an unsigned int and
/// LEB128-encoded, then the whole blob is gzipped. Deltas are tiny and highly
/// repetitive, so gzip shrinks it far more than the float text (~1.3 MB → ~0.4
/// MB). The bounding box is dropped — the loader recomputes it from the points.
///
/// Run after changing the source: `dart run tool/build_town_boundaries.dart`.
/// The decoder is `TownBoundaries.fromBinary` in
/// `lib/core/geo/town_boundaries.dart`; the format must stay in lockstep.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

const _src = 'assets/map/town_boundaries.json.gz';
const _out = 'assets/map/town_boundaries.bin.gz';

void main() {
  final json =
      jsonDecode(utf8.decode(gzip.decode(File(_src).readAsBytesSync())))
          as Map<String, dynamic>;

  final out = BytesBuilder();
  void writeVarint(int value) {
    var v = value;
    while (v >= 0x80) {
      out.addByte((v & 0x7f) | 0x80);
      v >>= 7;
    }
    out.addByte(v);
  }

  int zigzag(int n) => n >= 0 ? n << 1 : ((-n) << 1) - 1;

  writeVarint(json.length);
  var vertices = 0;
  json.forEach((code, value) {
    final obj = value as Map<String, dynamic>;
    final codeBytes = ascii.encode(code);
    writeVarint(codeBytes.length);
    out.add(codeBytes);
    final polygons = obj['p'] as List;
    writeVarint(polygons.length);
    for (final poly in polygons) {
      final rings = poly as List;
      writeVarint(rings.length);
      for (final ring in rings) {
        final flat = (ring as List).cast<num>();
        final pointCount = flat.length ~/ 2;
        writeVarint(pointCount);
        var px = 0;
        var py = 0;
        for (var i = 0; i < flat.length; i += 2) {
          final x = (flat[i] * 1e4).round();
          final y = (flat[i + 1] * 1e4).round();
          writeVarint(zigzag(x - px));
          writeVarint(zigzag(y - py));
          px = x;
          py = y;
          vertices++;
        }
      }
    }
  });

  final bin = out.toBytes();
  final gz = GZipCodec(level: 9).encode(bin);
  File(_out).writeAsBytesSync(gz);

  final srcSize = File(_src).lengthSync();
  final outSize = File(_out).lengthSync();
  stdout.writeln(
    'Encoded ${json.length} townships, $vertices vertices.\n'
    'raw binary: ${(bin.length / 1024).round()} KB  →  gzip: '
    '${(outSize / 1024).round()} KB\n'
    'was (json.gz): ${(srcSize / 1024).round()} KB  '
    '(saved ${((srcSize - outSize) / 1024).round()} KB, '
    '${(100 * (srcSize - outSize) / srcSize).round()}%)',
  );
}
