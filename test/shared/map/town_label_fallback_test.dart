/// A township with no baked label point still appears, at the directory
/// centroid. The selected-township highlight is a colour-vision-aware purple.
library;

import 'dart:convert';

import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/shared/map/map_style.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('missing baked points fall back to the directory centroid', () {
    final directory = TownDirectory.fromJson({
      'ZZ-missing': {
        'city': '測試',
        'town': '無點',
        'lat': 23.5,
        'lng': 121.0,
        'cityLevel': '縣',
        'townLevel': '鄉',
      },
    });
    final geo = jsonDecode(townLabelGeoJson(directory)) as Map<String, dynamic>;
    final feature = (geo['features'] as List).single as Map<String, dynamic>;
    final coordinates =
        (feature['geometry'] as Map<String, dynamic>)['coordinates'] as List;
    expect(coordinates, [121.0, 23.5]);
    expect((feature['properties'] as Map<String, dynamic>)['name'], '無點鄉');
    expect(selectedColor, startsWith('#'));
  });
}
