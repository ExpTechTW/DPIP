/// The hex bridge between a MapLibre style expression and the Flutter widget
/// that reads the same ramp back.
///
/// The two have to agree by construction — a station's colour on the map and
/// the dot in its sheet come from one stop list — so the round trip is pinned,
/// and so is the one place `stepColor` and `rampColor` differ on purpose: a
/// banded scale must never invent a colour between two stops, because that
/// renders a reading no band defines.
library;

import 'package:dpip/shared/color_hex.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('hex round trip', () {
    test('a parsed colour writes back the string it came from', () {
      for (final hex in ['#000000', '#ffffff', '#1e88e5', '#0a0b0c']) {
        expect(colorFromHexRgb(hex)!.toHexRgb(), hex);
      }
    });

    test('alpha is dropped, not folded into the colour', () {
      // MapLibre is handed opaque hex, so a theme colour that arrives with
      // alpha must not come out as a darker shade of itself on the map.
      expect(const Color(0x801E88E5).toHexRgb(), '#1e88e5');
    });

    test('the leading hash is optional and a malformed string is null', () {
      expect(colorFromHexRgb('1e88e5'), const Color(0xFF1E88E5));
      expect(colorFromHexRgb('#1e88e'), isNull, reason: 'five digits');
      expect(colorFromHexRgb('#1e88e50'), isNull, reason: 'seven digits');
      expect(colorFromHexRgb('#gggggg'), isNull, reason: 'six, but not hex');
      expect(colorFromHexRgb(''), isNull);
    });
  });

  group('stepColor', () {
    const stops = [(0.0, '#00ff00'), (10.0, '#ffff00'), (50.0, '#ff0000')];

    test('takes the last stop it is at or above', () {
      expect(stepColor(stops, 0.0), const Color(0xFF00FF00));
      expect(stepColor(stops, 9.9), const Color(0xFF00FF00));
      expect(stepColor(stops, 10.0), const Color(0xFFFFFF00));
      expect(stepColor(stops, 50.0), const Color(0xFFFF0000));
    });

    test('clamps outside the range rather than returning nothing', () {
      expect(stepColor(stops, -5), const Color(0xFF00FF00));
      expect(stepColor(stops, 999), const Color(0xFFFF0000));
    });

    test('invents no colour between two stops', () {
      // This is the whole reason it exists beside `rampColor`: the CWA rainfall
      // bands are categorical, so a value that falls between two of them has to
      // render as the band below it.
      expect(stepColor(stops, 30), const Color(0xFFFFFF00));
      expect(stepColor(stops, 30), isNot(rampColor(stops, 30)));
    });

    test('a chosen stop with unparseable hex yields no colour', () {
      expect(stepColor(const [(0.0, 'not-a-colour')], 1), isNull);
    });
  });

  group('rampColor', () {
    const stops = [(0.0, '#000000'), (10.0, '#ffffff')];

    test('an empty ramp has no colour to give', () {
      expect(stepColor(const [], 1), isNull);
      expect(rampColor(const [], 1), isNull);
    });

    test('clamps to the ends', () {
      expect(rampColor(stops, -1), const Color(0xFF000000));
      expect(rampColor(stops, 11), const Color(0xFFFFFFFF));
    });

    test('interpolates between two stops', () {
      final mid = rampColor(stops, 5)!.toARGB32();
      expect(mid, greaterThan(const Color(0xFF000000).toARGB32()));
      expect(mid, lessThan(const Color(0xFFFFFFFF).toARGB32()));
    });

    test('a malformed stop does not blank the ramp', () {
      // Degenerate, and it is what the code deliberately does: one bad entry in
      // a colour table costs that entry, not the whole map layer.
      expect(
        rampColor(const [(0.0, 'not-a-colour'), (10.0, '#ffffff')], 5),
        const Color(0xFFFFFFFF),
      );
    });
  });
}
