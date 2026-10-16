/// The monitor's station layer, golden-pinned against the builder it replaced.
///
/// [_legacy] is `RtsMapLayer._geoJson` as it stood before the layer moved to
/// the RTS worker, frozen here word for word except that its inputs are
/// parameters. Both new builders must agree with it exactly: the map one
/// value for value, the encoded one character for character with what
/// `jsonEncode` — the encoder the map path goes through — makes of the map.
/// A difference in either is a difference on screen.
library;

import 'dart:convert';
import 'dart:math';

import 'package:dpip/features/earthquake/domain/rts.dart';
import 'package:dpip/features/earthquake/domain/rts_station_geojson.dart';
import 'package:dpip/features/earthquake/domain/rts_station_mark.dart';
import 'package:dpip/features/earthquake/domain/seismic_station.dart';
import 'package:dpip/shared/map/monitor_map_stack.dart';
import 'package:flutter_test/flutter_test.dart';

/// The pre-worker builder. Do not "fix" it: it is the reference.
Map<String, dynamic> _legacy(
  Map<String, RtsStation> live,
  Map<String, SeismicStation> stations, {
  required bool eventLit,
  required bool eewActive,
  required bool dark,
}) {
  final features = <Map<String, dynamic>>[];
  for (final entry in live.entries) {
    final station = stations[entry.key];
    if (station == null) continue;
    final data = entry.value;
    final mark = rtsStationMark(data, eventLit: eventLit, eewActive: eewActive);
    if (mark == null) continue;
    features.add({
      'type': 'Feature',
      'geometry': {
        'type': 'Point',
        'coordinates': [station.longitude, station.latitude],
      },
      'properties': {
        'i': mark.colorValue,
        'sort': data.intensity,
        'label': '${entry.key}\n${data.intensity.toStringAsFixed(1)}',
        'icon': mark.kind == RtsStationMarkKind.badge
            ? monitorBadgeIcon(mark.level, dark: dark)
            : '',
        'grey': mark.kind == RtsStationMarkKind.grey ? 1 : 0,
      },
    });
  }
  return {'type': 'FeatureCollection', 'features': features};
}

/// The icon table the monitor hands the builders for [dark].
List<String> _icons({required bool dark}) => [
  for (var level = 0; level < 10; level++) monitorBadgeIcon(level, dark: dark),
];

/// Every pairing of the two flags and the two artworks.
const _modes = [
  (eventLit: false, eewActive: false, dark: false),
  (eventLit: true, eewActive: false, dark: false),
  (eventLit: false, eewActive: true, dark: false),
  (eventLit: true, eewActive: true, dark: false),
  (eventLit: false, eewActive: false, dark: true),
  (eventLit: true, eewActive: false, dark: true),
  (eventLit: false, eewActive: true, dark: true),
  (eventLit: true, eewActive: true, dark: true),
];

void _expectSameAsLegacy(
  Map<String, RtsStation> live,
  Map<String, SeismicStation> stations,
) {
  for (final mode in _modes) {
    final reference = _legacy(
      live,
      stations,
      eventLit: mode.eventLit,
      eewActive: mode.eewActive,
      dark: mode.dark,
    );
    final icons = _icons(dark: mode.dark);
    final built = rtsStationGeoJson(
      live,
      stations,
      eventLit: mode.eventLit,
      eewActive: mode.eewActive,
      badgeIcons: icons,
    );
    final encoded = encodeRtsStationGeoJson(
      live,
      stations,
      eventLit: mode.eventLit,
      eewActive: mode.eewActive,
      badgeIcons: icons,
    );
    expect(built, reference, reason: '$mode: the map');
    expect(encoded, jsonEncode(reference), reason: '$mode: the string');
    expect(jsonDecode(encoded), reference, reason: '$mode: it parses back');
  }
}

SeismicStation _at(String id, double latitude, double longitude) =>
    SeismicStation(id: id, latitude: latitude, longitude: longitude);

void main() {
  test('a network-sized frame, every flag and artwork', () {
    final random = Random(20260916);
    final stations = <String, SeismicStation>{};
    final live = <String, RtsStation>{};
    for (var n = 0; n < 1200; n++) {
      final id = (0x11D0000 + n * 37).toRadixString(16).toUpperCase();
      // Some stations report without being in the directory, and some in the
      // directory are silent: both are skipped, not guessed at.
      if (n % 23 != 0) {
        stations[id] = _at(
          id,
          21.9 + random.nextDouble() * 3.4,
          119.9 + random.nextDouble() * 2.2,
        );
      }
      if (n % 31 == 0) continue;
      live[id] = RtsStation(
        intensity: switch (n % 9) {
          0 => -3.0,
          1 => double.parse((random.nextDouble() * 10 - 3).toStringAsFixed(2)),
          _ => random.nextDouble() * 10 - 3,
        },
        pga: random.nextDouble() * 400,
        alert: random.nextInt(4) == 0,
      );
    }
    _expectSameAsLegacy(live, stations);
  });

  test('every mark rule and its boundaries', () {
    final stations = <String, SeismicStation>{};
    final live = <String, RtsStation>{};
    const readings = [
      -3.0, -1.0, -0.0, 0.0, 0.1, 0.19, 0.2, 0.21, 0.49, 0.5, 1.0, 1.49, //
      1.5, 2.5, 3.5, 4.5, 4.99, 5.0, 5.5, 6.0, 6.5, 7.0, 9.9, 1e-7, 1e21,
    ];
    for (var n = 0; n < readings.length; n++) {
      for (final alert in [false, true]) {
        final id = 'S$n${alert ? 'A' : ''}';
        stations[id] = _at(id, 23.0 + n / 100, 121.0 - n / 1000);
        live[id] = RtsStation(intensity: readings[n], alert: alert);
      }
    }
    _expectSameAsLegacy(live, stations);
  });

  test('ids that need escaping are escaped the way jsonEncode does', () {
    const ids = [
      'plain',
      'quote"d',
      r'back\slash',
      'tab\there',
      'new\nline',
      'nul\u0000',
      'unit\u001f',
      'del\u007f',
      '測站',
      'line sep',
      'volcano 🌋',
      'lone \ud800 lead',
      'lone \udc00 trail',
      'ends in lead \ud83c',
      '\udf0b starts in trail',
      '\udf0b\ud83c reversed',
      '',
    ];
    final stations = {for (final id in ids) id: _at(id, 23.5, 121.0)};
    final live = {
      for (final (n, id) in ids.indexed)
        id: RtsStation(intensity: n / 2 - 1, alert: n.isEven),
    };
    _expectSameAsLegacy(live, stations);
  });

  test('awkward coordinates are written the way jsonEncode writes them', () {
    final stations = {
      'a': _at('a', 23.000000000000004, 121.1),
      'b': _at('b', -0.0, 0.0),
      'c': _at('c', 1e-7, 123456789.123),
      'd': _at('d', 25, 122),
    };
    final live = {
      for (final id in stations.keys) id: const RtsStation(intensity: 1.2),
    };
    _expectSameAsLegacy(live, stations);
  });

  test('nothing to draw is the empty collection', () {
    expect(
      encodeRtsStationGeoJson(
        const {},
        const {},
        eventLit: false,
        eewActive: false,
        badgeIcons: _icons(dark: false),
      ),
      jsonEncode(monitorEmptyCollection),
    );
    _expectSameAsLegacy(const {}, {'a': _at('a', 23, 121)});
  });

  test('a reading that is not a number fails as jsonEncode fails', () {
    final stations = {'a': _at('a', 23, 121)};
    final live = {'a': const RtsStation(intensity: double.nan)};
    final reference = _legacy(
      live,
      stations,
      eventLit: false,
      eewActive: false,
      dark: false,
    );
    expect(
      () => jsonEncode(reference),
      throwsA(isA<JsonUnsupportedObjectError>()),
    );
    expect(
      () => encodeRtsStationGeoJson(
        live,
        stations,
        eventLit: false,
        eewActive: false,
        badgeIcons: _icons(dark: false),
      ),
      throwsA(isA<JsonUnsupportedObjectError>()),
    );
  });
}
