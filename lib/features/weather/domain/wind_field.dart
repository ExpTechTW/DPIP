import 'dart:typed_data';

/// A decoded WND1 wind field — the numeric grid that drives the wind-forecast
/// particle animation.
///
/// The wire format is a fixed-size header followed by two quantised planes:
///
/// ```
/// 0  4  'WND1'             10 lat0 (f64)         42 uMin (f32)
/// 4  2  version (u16)      18 lon0 (f64)         46 uMax (f32)
/// 6  2  width (u16)        26 dLat (f64)         50 vMin (f32)
/// 8  2  height (u16)       34 dLon (f64)         54 vMax (f32)
///                           58 timeMs (u64)       66 nameLen (u8)
///                           67 model name         …  u plane (u8 × n)
///                                                …  v plane (u8 × n)
/// ```
///
/// All multi-byte values are little-endian. Each plane holds one quantised
/// component per cell, raster order, values `0..255` mapped onto
/// `min..max` — so [u]/[v] act as texture texels, exactly what the GPU
/// particle renderer consumes ([satellite-tiles-go/web/wind.js]).
///
/// [u] and [v] are views over the source bytes, not copies: a parsed field
/// keeps the whole binary alive so the per-frame animation can read it without
/// another allocation. At ~2 MB (a 1440×721 global grid) that is a deliberate
/// one-field-at-a-time trade.
class WindField {
  const WindField({
    required this.width,
    required this.height,
    required this.lat0,
    required this.lon0,
    required this.dLat,
    required this.dLon,
    required this.uMin,
    required this.uMax,
    required this.vMin,
    required this.vMax,
    required this.timeMs,
    required this.model,
    required this.u,
    required this.v,
  });

  /// Cells across — the field spans `dLon × width` degrees of longitude.
  final int width;

  /// Cells down — the field spans `dLat × height` degrees of latitude.
  final int height;

  /// Latitude of row 0 (the north edge, `90` for a global grid).
  final double lat0;

  /// Longitude of column 0.
  final double lon0;

  /// Degrees of latitude per row (negative — rows run north → south).
  final double dLat;

  /// Degrees of longitude per column.
  final double dLon;

  /// Quantisation range of the u (eastward) component, m/s.
  final double uMin;
  final double uMax;

  /// Quantisation range of the v (northward) component, m/s.
  final double vMin;
  final double vMax;

  /// Valid time of the field, Unix milliseconds.
  final int timeMs;

  /// The forecast model this grid came from (`gfs` / `ecmwf`).
  final String model;

  /// Quantised eastward component, `width × height`, raster order.
  final Uint8List u;

  /// Quantised northward component, `width × height`, raster order.
  final Uint8List v;

  /// Parses a WND1 payload. Throws [FormatException] on any structural
  /// mismatch (bad magic, unsupported version, truncation) — the data layer
  /// wraps that into a [DecodeFailure] before anything else sees it.
  factory WindField.fromWnd1(Uint8List bytes) {
    const header = 67;
    if (bytes.length < header) {
      throw const FormatException('wind field truncated before its header');
    }
    if (String.fromCharCodes(bytes.sublist(0, 4)) != 'WND1') {
      throw const FormatException('not a WND1 wind field');
    }
    final data = ByteData.sublistView(bytes);
    if (data.getUint16(4, Endian.little) != 1) {
      throw const FormatException('unsupported WND1 version');
    }
    final width = data.getUint16(6, Endian.little);
    final height = data.getUint16(8, Endian.little);
    final n = width * height;
    final nameLen = data.getUint8(66);
    final planeOffset = header + nameLen;
    if (bytes.length < planeOffset + n * 2) {
      throw const FormatException('wind field truncated after its header');
    }
    return WindField(
      width: width,
      height: height,
      lat0: data.getFloat64(10, Endian.little),
      lon0: data.getFloat64(18, Endian.little),
      dLat: data.getFloat64(26, Endian.little),
      dLon: data.getFloat64(34, Endian.little),
      uMin: data.getFloat32(42, Endian.little),
      uMax: data.getFloat32(46, Endian.little),
      vMin: data.getFloat32(50, Endian.little),
      vMax: data.getFloat32(54, Endian.little),
      timeMs: data.getUint64(58, Endian.little).toInt(),
      model: String.fromCharCodes(bytes.sublist(67, planeOffset)),
      u: Uint8List.sublistView(bytes, planeOffset, planeOffset + n),
      v: Uint8List.sublistView(bytes, planeOffset + n, planeOffset + n * 2),
    );
  }

  /// Dequantised eastward component at cell [i], m/s.
  double uAt(int i) => uMin + (u[i] / 255) * (uMax - uMin);

  /// Dequantised northward component at cell [i], m/s.
  double vAt(int i) => vMin + (v[i] / 255) * (vMax - vMin);
}
