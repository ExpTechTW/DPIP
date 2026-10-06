/// An EEW wavefront is a polygon, not a MapLibre circle. A ring that does not
/// close, or that is measured in the wrong axis order, draws the shaken area
/// somewhere else.
library;

import 'package:dpip/core/geo/geo_math.dart';
import 'package:dpip/core/models/lat_lng.dart';
import 'package:dpip/shared/map/geo_circle.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('degrees convert to radians', () {
    expect(degToRad(180), closeTo(3.1415926535, 1e-9));
    expect(degToRad(0), 0);
  });

  test('outline and fill share a closed ring around the centre', () {
    const centre = LatLng(25.03, 121.56);
    final line = circleFeature(
      centre,
      10000,
      steps: 8,
      properties: const {'type': 'p'},
    );
    final fill = circleFillFeature(centre, 10000, steps: 8);

    expect(line['type'], 'Feature');
    expect(line['properties'], {'type': 'p'});
    final coords = (line['geometry'] as Map)['coordinates'] as List;
    expect((line['geometry'] as Map)['type'], 'LineString');
    expect(coords.first, coords.last);
    expect(coords, hasLength(9));
    // GeoJSON is longitude, latitude. The ring stays near Taipei.
    final first = coords.first as List;
    expect(first[0], closeTo(121.56, 0.2));
    expect(first[1], closeTo(25.03, 0.2));

    final ring = ((fill['geometry'] as Map)['coordinates'] as List).single;
    expect((fill['geometry'] as Map)['type'], 'Polygon');
    expect(ring, coords);

    // A second ring of the same step count reuses the bearing table.
    final again = circleFeature(centre, 20000, steps: 8);
    final againCoords = (again['geometry'] as Map)['coordinates'] as List;
    expect(againCoords, hasLength(coords.length));
    expect(againCoords.first, isNot(equals(coords.first)));
  });
}
