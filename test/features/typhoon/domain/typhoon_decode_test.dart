/// A missing `cyclones` array used to throw and blank the whole typhoon
/// panel. An empty string used to render as a name.
library;

import 'package:dpip/features/map/presentation/layers/typhoon_storm_band.dart';
import 'package:dpip/features/typhoon/domain/typhoon_decode.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a missing or malformed cyclone list degrades to empty', () {
    final missing = decodeCyclonesPayload<({int updated, int count})>(
      const {},
      (updated, raw) => (updated: updated, count: raw.length),
    );
    expect(missing.updated, 0);
    expect(missing.count, 0);

    final bad = decodeCyclonesPayload<int>(const {
      'updated': 12.0,
      'cyclones': 'nope',
    }, (updated, raw) => updated + raw.length);
    expect(bad, 12);

    final rows = decodeCyclonesPayload<List<dynamic>>(const {
      'updated': 3,
      'cyclones': [
        {'id': 'a'},
      ],
    }, (_, raw) => raw);
    expect(rows, [
      {'id': 'a'},
    ]);
  });

  test('trimToNull drops blank strings and keeps the rest', () {
    expect(trimToNull(null), isNull);
    expect(trimToNull('   '), isNull);
    expect(trimToNull(' 山竹 '), '山竹');
  });

  test('the two storm bands stay distinct', () {
    expect(TyphoonStormBand.values, [
      TyphoonStormBand.level7,
      TyphoonStormBand.level10,
    ]);
  });
}
