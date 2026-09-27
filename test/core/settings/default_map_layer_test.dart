/// [DefaultMapLayer.id] is `name` today, but call sites treat it as a stable
/// identity string rather than reaching for the enum directly — `map_page.dart`
/// decides whether to enable the OSM base layer with
/// `initial.id == DefaultMapLayer.dpm.id`, and the map's camera handoff passes
/// this id across a nav-bar tap. If `id` ever stopped being exactly `name` (a
/// per-value override, a reordered `values` list feeding something
/// index-based), those identity comparisons would drift without any type
/// error to catch it.
library;

import 'package:dpip/core/settings/default_map_layer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('id is exactly the member name for every layer', () {
    expect(DefaultMapLayer.values, hasLength(12));
    for (final layer in DefaultMapLayer.values) {
      expect(layer.id, layer.name, reason: layer.name);
    }
  });

  test(
    'the dpm layer id is stable, since map_page compares against it directly',
    () {
      expect(DefaultMapLayer.dpm.id, 'dpm');
    },
  );
}
