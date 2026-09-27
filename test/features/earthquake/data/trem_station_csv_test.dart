/// The `/resource/station` directory as it is actually served: CSV under a
/// JSON content type.
///
/// The parser finds columns by header name, because a column the server adds
/// or moves must not shift every station's coordinates one field over — a
/// monitor that draws every station in the sea looks exactly like one that
/// works. And a header missing a column the join needs has to fail loudly:
/// read as an empty directory it would be saved over a good one.
library;

import 'package:dpip/features/earthquake/data/trem_station_csv.dart';
import 'package:flutter_test/flutter_test.dart';

const _csv = '''loc_code,id,lat,lon,floor,code,net,time,work
1,125313C,23.3188,121.4564,2,962,3,2026-02-16,1
2,1255670,23.3188,121.4564,2,962,3,2026-02-16,1
,12686D0,24.9993,121.5087,2,235,4,2025-12-12,0
''';

void main() {
  test('reads id, position and township by header name', () {
    final stations = parseTremStationCsv(_csv);

    expect(stations.keys, ['125313C', '1255670', '12686D0']);
    final station = stations['125313C']!;
    expect(station.latitude, 23.3188);
    expect(station.longitude, 121.4564);
    expect(station.townCode, '962');
  });

  test('two devices on one site are two stations', () {
    final stations = parseTremStationCsv(_csv);

    expect(stations['125313C']!.latitude, stations['1255670']!.latitude);
    expect(stations, hasLength(3));
  });

  test('a reordered header still reads the right columns', () {
    final stations = parseTremStationCsv(
      'lon,code,id,lat\n121.5,100,ABC,25.0\n',
    );

    expect(stations['ABC']!.latitude, 25.0);
    expect(stations['ABC']!.longitude, 121.5);
    expect(stations['ABC']!.townCode, '100');
  });

  test('a row without a usable position is skipped, not zeroed', () {
    final stations = parseTremStationCsv(
      'id,lat,lon,code\nGOOD,23.0,121.0,1\nBAD,,121.0,1\nSHORT,23.0\n',
    );

    expect(stations.keys, ['GOOD']);
  });

  test('a header missing a join column is a FormatException', () {
    expect(
      () => parseTremStationCsv('id,latitude,lon\nA,23,121\n'),
      throwsFormatException,
    );
  });
}
