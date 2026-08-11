import 'dart:typed_data';

import 'package:dpip/features/weather/domain/wind_field.dart';
import 'package:flutter_test/flutter_test.dart';

/// Builds a minimal 2×2 WND1 payload covering the whole globe (0..360° lon,
/// 90..-90 lat) with known quantised planes.
Uint8List _wnd1({
  String magic = 'WND1',
  int version = 1,
  String model = 'gfs',
}) {
  final name = Uint8List.fromList(model.codeUnits);
  final data = ByteData(67 + name.length + 4 * 2);
  data.setUint8(0, 0x57);
  data.setUint8(1, 0x4e);
  data.setUint8(2, 0x44);
  data.setUint8(3, 0x31);
  if (magic != 'WND1') data.setUint8(0, 0x58);
  data.setUint16(4, version, Endian.little);
  data.setUint16(6, 2, Endian.little); // width
  data.setUint16(8, 2, Endian.little); // height
  data.setFloat64(10, 90, Endian.little); // lat0
  data.setFloat64(18, 0, Endian.little); // lon0
  data.setFloat64(26, -90, Endian.little); // dLat
  data.setFloat64(34, 180, Endian.little); // dLon
  data.setFloat32(42, -1, Endian.little); // uMin
  data.setFloat32(46, 1, Endian.little); // uMax
  data.setFloat32(50, -1, Endian.little); // vMin
  data.setFloat32(54, 1, Endian.little); // vMax
  data.setUint64(58, 1700000000000, Endian.little); // timeMs
  data.setUint8(66, name.length);
  data.buffer.asUint8List().setRange(67, 67 + name.length, name);
  final u = data.buffer.asUint8List();
  final offset = 67 + name.length;
  // u plane: [0, 255, 0, 255]; v plane: [255, 0, 255, 0]
  for (final (i, value) in [(0, 0), (1, 255), (2, 0), (3, 255)]) {
    u[offset + i] = value;
    u[offset + 4 + i] = 255 - value;
  }
  return Uint8List.fromList(data.buffer.asUint8List());
}

void main() {
  test('parses every header field and keeps the planes as views', () {
    final field = WindField.fromWnd1(_wnd1());

    expect(field.width, 2);
    expect(field.height, 2);
    expect(field.lat0, 90);
    expect(field.lon0, 0);
    expect(field.dLat, -90);
    expect(field.dLon, 180);
    expect(field.uMin, -1);
    expect(field.uMax, 1);
    expect(field.vMin, -1);
    expect(field.vMax, 1);
    expect(field.timeMs, 1700000000000);
    expect(field.model, 'gfs');
    expect(field.u.length, 4);
    expect(field.v.length, 4);
  });

  test('dequantises the planes onto the min..max range', () {
    final field = WindField.fromWnd1(_wnd1());
    // u plane [0, 255, 0, 255] maps onto -1..1; v is the complement.
    expect(field.uAt(0), -1);
    expect(field.uAt(1), 1);
    expect(field.vAt(0), 1);
    expect(field.vAt(1), -1);
  });

  test('a variable-length model name shifts the plane offset', () {
    final field = WindField.fromWnd1(_wnd1(model: 'ecmwf'));
    expect(field.model, 'ecmwf');
    expect(field.uAt(0), -1);
    expect(field.uAt(1), 1);
  });

  test('rejects a non-WND1 magic', () {
    expect(
      () => WindField.fromWnd1(_wnd1(magic: 'XND1')),
      throwsFormatException,
    );
  });

  test('rejects an unsupported version', () {
    expect(() => WindField.fromWnd1(_wnd1(version: 2)), throwsFormatException);
  });

  test('rejects a truncated payload', () {
    final bytes = _wnd1();
    expect(
      () => WindField.fromWnd1(Uint8List.sublistView(bytes, 0, 60)),
      throwsFormatException,
    );
  });
}
