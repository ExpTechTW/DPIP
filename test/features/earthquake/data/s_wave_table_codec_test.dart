import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:dpip/features/earthquake/data/s_wave_table_codec.dart';
import 'package:dpip/features/earthquake/domain/seismic_travel_time.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('packs depths, radii and S times in the documented layout', () {
    const table = SeismicTravelTimeTable({
      0: [(p: 0, r: 0, s: 0), (p: 0.4, r: 2, s: 0.703), (p: 0.8, r: 4, s: 1.4)],
      10: [(p: 1, r: 0, s: 2.5), (p: 1.1, r: 2, s: 2.75), (p: 1.2, r: 4, s: 3)],
    });

    final bytes = SWaveTableCodec.encode(table);
    final view = ByteData.sublistView(bytes);

    expect(ascii.decode(bytes.sublist(0, 4)), 'DPSW');
    expect(view.getUint16(4, Endian.little), SWaveTableCodec.formatVersion);
    expect(view.getUint16(6, Endian.little), 2);
    expect(view.getUint16(8, Endian.little), 3);
    expect(view.getUint16(10, Endian.little), 0);
    expect(
      [for (var i = 0; i < 2; i++) view.getUint16(12 + 2 * i, Endian.little)],
      [0, 10],
    );
    expect(
      [for (var i = 0; i < 3; i++) view.getUint16(16 + 2 * i, Endian.little)],
      [0, 2, 4],
    );
    expect(
      [for (var i = 0; i < 6; i++) view.getUint32(22 + 4 * i, Endian.little)],
      [0, 703, 1400, 2500, 2750, 3000],
    );
    expect(bytes.length, 22 + 4 * 6);
  });

  test('refuses a table it could not pack exactly', () {
    final refused = <SeismicTravelTimeTable>[
      const SeismicTravelTimeTable({}),
      const SeismicTravelTimeTable({0: []}),
      const SeismicTravelTimeTable({
        10: [(p: 0, r: 0, s: 0)],
        0: [(p: 0, r: 0, s: 0)],
      }),
      const SeismicTravelTimeTable({
        0: [(p: 0, r: 0.5, s: 0)],
      }),
      const SeismicTravelTimeTable({
        0: [(p: 0, r: 2, s: 0), (p: 0, r: 0, s: 0)],
      }),
      const SeismicTravelTimeTable({
        0: [(p: 0, r: 0, s: 0.0005)],
      }),
      const SeismicTravelTimeTable({
        0: [(p: 0, r: 0, s: 0), (p: 0, r: 2, s: 1)],
        2: [(p: 0, r: 0, s: 0), (p: 0, r: 3, s: 1)],
      }),
      const SeismicTravelTimeTable({
        0: [(p: 0, r: 0, s: 0), (p: 0, r: 2, s: 1)],
        2: [(p: 0, r: 0, s: 0)],
      }),
      const SeismicTravelTimeTable({
        -1: [(p: 0, r: 0, s: 0)],
      }),
    ];
    for (final table in refused) {
      expect(
        () => SWaveTableCodec.encode(table),
        throwsFormatException,
        reason: '${table.rowsByDepth}',
      );
    }
  });

  /// The bundled table packs exactly, at this size and hash. The Swift side
  /// (`EEWLocalEstimateTests`) packs the same JSON with its own test encoder
  /// and pins the same hash, which is what proves the two agree on the layout.
  test('the bundled table packs to the pinned bytes', () {
    final file = [
      'assets/travel_time.json.Z',
      'assets/travel_time.json.gz',
    ].map(File.new).firstWhere((file) => file.existsSync());
    final json = jsonDecode(
      utf8.decode(gzip.decode(file.readAsBytesSync())),
    ) as Map<String, dynamic>;
    final table = SeismicTravelTimeTable({
      for (final entry in json.entries)
        int.parse(entry.key): [
          for (final row in entry.value as List)
            (
              p: ((row as Map)['P'] as num).toDouble(),
              r: (row['R'] as num).toDouble(),
              s: (row['S'] as num).toDouble(),
            ),
        ],
    });

    final bytes = SWaveTableCodec.encode(table);

    expect(bytes.length, 100760);
    expect(sha256.convert(bytes).toString(), _pinnedSha256);
  });
}

const _pinnedSha256 =
    '0e6a27fe3a6a26d4343548270ea2d793d3405163d145ff7c70b96e4015e3be33';
