/// Station labels are one symbol layer. A missing font stack makes MapLibre
/// drop the layer, and an optional opacity or sort key has to survive into
/// the paint properties.
library;

import 'package:dpip/shared/map/map_station_labels.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('labels pin under the dot in the glyph the CDN serves', () {
    final props = stationLabelProps(textField: const ['get', 'name']);
    expect(props.textFont, [stationLabelFont]);
    expect(props.textAnchor, 'top');
    expect(props.textOffset, [0, stationLabelOffsetEm]);
    expect(props.textAllowOverlap, isFalse);
    expect(props.textOpacity, isNull);
    expect(props.symbolSortKey, isNull);
    expect(stationLabelOffsetEm, 1);

    final faded = stationLabelProps(
      textField: const ['get', 'name'],
      textSize: 13,
      textColor: '#fff',
      haloColor: '#111',
      haloWidth: 2,
      opacity: 0.4,
      sortKey: const ['get', 'rank'],
    );
    expect(faded.textSize, 13);
    expect(faded.textColor, '#fff');
    expect(faded.textHaloColor, '#111');
    expect(faded.textHaloWidth, 2);
    expect(faded.textOpacity, 0.4);
    expect(faded.symbolSortKey, ['get', 'rank']);
  });
}
