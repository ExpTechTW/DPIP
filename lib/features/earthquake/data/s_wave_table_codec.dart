import 'dart:typed_data';

import 'package:dpip/features/earthquake/domain/seismic_travel_time.dart';

/// The S-wave half of the travel-time table, packed for the iOS EEW Live
/// Activity widget.
///
/// The widget has to work out the S-wave arrival itself — a remotely started
/// activity renders while the app is not running — but it must not carry the
/// 213 KB asset, nor inflate 834 KB of JSON on every render. So the app packs
/// the one column the widget reads into the App Group once per app version,
/// and the widget memory-maps it (`ios/Shared/EEWLocalEstimate.swift`, the
/// reader; keep the two in step).
///
/// Layout, little-endian, no padding:
///
/// | offset | size | field |
/// |---|---|---|
/// | 0 | 4 | magic `DPSW` |
/// | 4 | 2 | [formatVersion] |
/// | 6 | 2 | depth count D |
/// | 8 | 2 | radius count N |
/// | 10 | 2 | 0 |
/// | 12 | 2·D | depths (km), ascending |
/// | 12 + 2·D | 2·N | epicentral radii (km), ascending |
/// | 12 + 2·D + 2·N | 4·D·N | S travel time (ms), depth-major |
///
/// The bundled table has one radius grid shared by every depth, whole-km
/// depths and radii, and S times in whole milliseconds, which is what makes
/// this exact: the widget reads back the same doubles `SeismicTravelTimeTable`
/// holds (`ms / 1000` is the double nearest the JSON's decimal, as the parse
/// was). A table that is not like that is refused rather than approximated.
abstract final class SWaveTableCodec {
  static const int formatVersion = 1;

  static const List<int> _magic = [0x44, 0x50, 0x53, 0x57]; // DPSW

  /// Packs [table], or throws [FormatException] if it cannot be packed
  /// exactly.
  static Uint8List encode(SeismicTravelTimeTable table) {
    final depths = table.rowsByDepth.keys.toList();
    if (depths.isEmpty) throw const FormatException('empty table');
    for (var i = 0; i < depths.length; i++) {
      final depth = depths[i];
      if (depth < 0 || depth > 0xFFFF) {
        throw FormatException('depth out of range: $depth');
      }
      if (i > 0 && depth <= depths[i - 1]) {
        throw const FormatException('depths are not ascending');
      }
    }

    final grid = table.rowsByDepth[depths.first]!;
    final radii = <int>[];
    for (final row in grid) {
      final radius = row.r.round();
      if (row.r != radius || radius < 0 || radius > 0xFFFF) {
        throw FormatException('radius is not a whole km: ${row.r}');
      }
      if (radii.isNotEmpty && radius < radii.last) {
        throw const FormatException('radii are not ascending');
      }
      radii.add(radius);
    }
    if (radii.isEmpty) throw const FormatException('empty radius grid');

    final dataOffset = 12 + 2 * depths.length + 2 * radii.length;
    final bytes = ByteData(dataOffset + 4 * depths.length * radii.length);
    for (var i = 0; i < 4; i++) {
      bytes.setUint8(i, _magic[i]);
    }
    bytes
      ..setUint16(4, formatVersion, Endian.little)
      ..setUint16(6, depths.length, Endian.little)
      ..setUint16(8, radii.length, Endian.little)
      ..setUint16(10, 0, Endian.little);
    var offset = 12;
    for (final depth in depths) {
      bytes.setUint16(offset, depth, Endian.little);
      offset += 2;
    }
    for (final radius in radii) {
      bytes.setUint16(offset, radius, Endian.little);
      offset += 2;
    }
    for (final depth in depths) {
      final rows = table.rowsByDepth[depth]!;
      if (rows.length != radii.length) {
        throw FormatException('depth $depth has its own radius grid');
      }
      for (var i = 0; i < rows.length; i++) {
        final row = rows[i];
        if (row.r != radii[i]) {
          throw FormatException('depth $depth has its own radius grid');
        }
        final ms = (row.s * 1000).round();
        // Exact only if ms / 1000 reads back as the very double the table
        // holds; anything finer than a millisecond would not.
        if (ms < 0 || ms > 0xFFFFFFFF || ms / 1000 != row.s) {
          throw FormatException('S time is not whole ms: ${row.s}');
        }
        bytes.setUint32(offset, ms, Endian.little);
        offset += 4;
      }
    }
    return bytes.buffer.asUint8List();
  }
}
