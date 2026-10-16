/// The 強震監視器's station layer as GeoJSON: one point per station in a frame
/// that the directory can place and [rtsStationMark] draws, carrying what the
/// monitor's dot, badge and label layers read.
///
/// Two builders, one output. [rtsStationGeoJson] builds the map that
/// `setGeoJsonSource` takes. [encodeRtsStationGeoJson] writes the same
/// collection straight to the JSON string MapLibre is finally handed —
/// character for character what `jsonEncode` makes of the map, which a test
/// pins — so the RTS worker isolate that runs it draws exactly what the
/// in-isolate path draws, without building ~a thousand feature maps only to
/// walk them again to encode them.
library;

import 'dart:convert';

import 'package:dpip/features/earthquake/domain/rts.dart';
import 'package:dpip/features/earthquake/domain/rts_station_mark.dart';
import 'package:dpip/features/earthquake/domain/seismic_station.dart';

/// The station layer for [readings], placed against [stations].
///
/// [eventLit] and [eewActive] decide each mark (see [rtsStationMark]);
/// [badgeIcons] is the badge icon id for each discrete level 0–9, in the
/// light or dark artwork the map is showing.
Map<String, dynamic> rtsStationGeoJson(
  Map<String, RtsStation> readings,
  Map<String, SeismicStation> stations, {
  required bool eventLit,
  required bool eewActive,
  required List<String> badgeIcons,
}) {
  final features = <Map<String, dynamic>>[];
  for (final entry in readings.entries) {
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
        // Sort key for both the dot and the badge layer, so a stronger
        // reading always draws over a weaker one.
        'sort': data.intensity,
        'label': '${entry.key}\n${data.intensity.toStringAsFixed(1)}',
        // The badge is a fuller circle drawn over the same dot, never a
        // shape swap (see `MonitorLayerIds.stationBadge`).
        'icon': mark.kind == RtsStationMarkKind.badge
            ? badgeIcons[mark.level]
            : '',
        'grey': mark.kind == RtsStationMarkKind.grey ? 1 : 0,
      },
    });
  }
  return {'type': 'FeatureCollection', 'features': features};
}

/// [rtsStationGeoJson], already encoded: the same arguments give exactly the
/// string `jsonEncode` makes of that map.
///
/// Numbers are written with `toString`, which is what `jsonEncode` writes, and
/// a non-finite one throws as it does. A string is written as it stands when
/// nothing in it needs escaping — a station id is a hex device id, an icon id
/// is ASCII — and through `jsonEncode` otherwise, so an unexpected character
/// is escaped by the encoder itself rather than by a copy of its rules.
String encodeRtsStationGeoJson(
  Map<String, RtsStation> readings,
  Map<String, SeismicStation> stations, {
  required bool eventLit,
  required bool eewActive,
  required List<String> badgeIcons,
}) {
  final out = StringBuffer('{"type":"FeatureCollection","features":[');
  var first = true;
  for (final entry in readings.entries) {
    final station = stations[entry.key];
    if (station == null) continue;
    final data = entry.value;
    final mark = rtsStationMark(data, eventLit: eventLit, eewActive: eewActive);
    if (mark == null) continue;
    if (!first) out.write(',');
    first = false;
    out.write('{"type":"Feature","geometry":{"type":"Point","coordinates":[');
    _writeNumber(out, station.longitude);
    out.write(',');
    _writeNumber(out, station.latitude);
    out.write(']},"properties":{"i":');
    _writeNumber(out, mark.colorValue);
    out.write(',"sort":');
    _writeNumber(out, data.intensity);
    // The label is `id\nreading`. Escaping the parts on their own is escaping
    // the whole: the newline between them is not a surrogate, so it cannot
    // pair with either side, and `toStringAsFixed` only ever writes ASCII.
    out.write(',"label":"');
    _writeStringContent(out, entry.key);
    out
      ..write(r'\n')
      ..write(data.intensity.toStringAsFixed(1))
      ..write('","icon":');
    _writeString(
      out,
      mark.kind == RtsStationMarkKind.badge ? badgeIcons[mark.level] : '',
    );
    out
      ..write(',"grey":')
      ..write(mark.kind == RtsStationMarkKind.grey ? 1 : 0)
      ..write('}}');
  }
  out.write(']}');
  return out.toString();
}

void _writeNumber(StringBuffer out, double value) {
  if (!value.isFinite) throw JsonUnsupportedObjectError(value);
  out.write(value);
}

void _writeString(StringBuffer out, String value) {
  if (_needsNoEscape(value)) {
    out
      ..write('"')
      ..write(value)
      ..write('"');
  } else {
    out.write(jsonEncode(value));
  }
}

void _writeStringContent(StringBuffer out, String value) {
  if (_needsNoEscape(value)) {
    out.write(value);
  } else {
    final quoted = jsonEncode(value);
    out.write(quoted.substring(1, quoted.length - 1));
  }
}

/// No control character, quote, backslash or surrogate: the characters
/// `jsonEncode` writes exactly as they are. Surrogates are sent to the encoder
/// even when paired, since only it decides which ones stand alone.
bool _needsNoEscape(String value) {
  for (var i = 0; i < value.length; i++) {
    final unit = value.codeUnitAt(i);
    if (unit < 0x20 ||
        unit == 0x22 ||
        unit == 0x5c ||
        (unit >= 0xd800 && unit <= 0xdfff)) {
      return false;
    }
  }
  return true;
}
