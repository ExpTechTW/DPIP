/// That every weather glyph is really in the bundled font, and that they are
/// really different pictures.
///
/// This is the test the old mapping did not have. It declared `rainy` as
/// `0xf07c2` against Flutter's bundled font — a codepoint that is actually
/// `Icons.severe_cold` — so a rainy hour drew a snowflake, and nothing in
/// analysis, the gates or the suite objected. Nothing would have, either: a
/// wrong codepoint is a perfectly valid `IconData`.
///
/// So the check is done the only way it can be: rasterise each glyph and look
/// at the pixels. A codepoint the font does not have paints `.notdef` — the
/// empty box — so the test renders the box once from a codepoint known to be
/// absent and asserts no weather glyph matches it. Counting ink would not do:
/// the box inks ~1590 pixels at 64 px, *more* than two thirds of the real
/// glyphs, so a "did it draw something" check passes on the exact bug this
/// file exists to catch.
library;

import 'dart:ui' as ui;

import 'package:dpip/core/settings/weather_mode.dart';
import 'package:dpip/core/weather/weather_condition.dart';
import 'package:dpip/core/weather/weather_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_test/flutter_test.dart';

/// Paints [icon] at 64 px on a transparent ground and returns its pixels.
Future<ui.Image> _render(IconData icon) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final builder = ui.ParagraphBuilder(ui.ParagraphStyle(fontSize: 64))
    ..pushStyle(
      ui.TextStyle(
        fontSize: 64,
        fontFamily: icon.fontFamily,
        color: const Color(0xFF000000),
      ),
    )
    ..addText(String.fromCharCode(icon.codePoint));
  final paragraph = builder.build()
    ..layout(const ui.ParagraphConstraints(width: 128));
  canvas.drawParagraph(paragraph, Offset.zero);
  return recorder.endRecording().toImage(128, 128);
}

Future<List<int>> _pixels(IconData icon) async {
  final image = await _render(icon);
  final data = await image.toByteData();
  return data!.buffer.asUint8List().toList();
}

/// How many pixels the glyph actually inked.
int _inked(List<int> pixels) {
  var count = 0;
  for (var i = 3; i < pixels.length; i += 4) {
    if (pixels[i] > 8) count++;
  }
  return count;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // The test binding does not load pubspec fonts; load the real asset so the
    // glyphs under test are the ones that ship.
    final loader = FontLoader(weatherIconFont)
      ..addFont(rootBundle.load('assets/fonts/DpipWeatherIcons.ttf'));
    await loader.load();
  });

  test('every glyph is in the bundled font', () async {
    // U+E000 is in the private-use area and is deliberately not one of the
    // subset's codepoints, so this is what "the font does not have it" looks
    // like: the .notdef box.
    final notdef = await _pixels(
      const IconData(0xe000, fontFamily: weatherIconFont),
    );
    expect(_inked(notdef), greaterThan(0), reason: 'the box should be visible');

    for (final entry in weatherIconsByName.entries) {
      final icon = entry.value;
      expect(
        icon.fontFamily,
        weatherIconFont,
        reason: '${entry.key} is not from the weather font',
      );
      final pixels = await _pixels(icon);
      expect(
        pixels,
        isNot(orderedEquals(notdef)),
        reason:
            '${entry.key} (0x${icon.codePoint.toRadixString(16)}) rendered the '
            'empty box — that codepoint is not in the font',
      );
      // And it drew a real picture, not a stray dot.
      expect(_inked(pixels), greaterThan(200), reason: '${entry.key} is bare');
    }
  });

  test('the guard would catch a fabricated codepoint', () async {
    // The three the old file invented, against the font it actually used.
    final notdef = await _pixels(
      const IconData(0xe000, fontFamily: weatherIconFont),
    );
    const fabricated = <IconData>[
      IconData(0xf07c2, fontFamily: weatherIconFont), // was called `rainy`
      IconData(0xf07c3, fontFamily: weatherIconFont), // `rainyHeavy`
      IconData(0xf07c4, fontFamily: weatherIconFont), // `rainyLight`
    ];
    for (final icon in fabricated) {
      expect(
        await _pixels(icon),
        orderedEquals(notdef),
        reason: 'a codepoint outside the subset must render as the box',
      );
    }
  });

  test('no two glyphs are the same picture', () async {
    final seen = <String, String>{};
    for (final entry in weatherIconsByName.entries) {
      final key = (await _pixels(entry.value)).join(',').hashCode.toString();
      final clash = seen[key];
      expect(
        clash,
        isNull,
        reason: '${entry.key} draws the same glyph as $clash',
      );
      seen[key] = entry.key;
    }
  });

  group('the CWB code table', () {
    // The regression that started all this: 306 = 陰有雨.
    test('306 (陰有雨) is rain, not snow', () {
      final (icon, _) = weatherVisual('陰有雨', 306, _colors);
      expect(icon, rainy);
      expect(weatherModeFor(306), WeatherMode.rain);
    });

    test('every phenomenon suffix resolves to a weather glyph', () {
      // All three families carry the same 19 suffixes.
      for (final family in [100, 200, 300]) {
        for (var suffix = 0; suffix <= 19; suffix++) {
          final code = family + suffix;
          final (icon, _) = weatherVisual('', code, _colors);
          expect(
            icon.fontFamily,
            weatherIconFont,
            reason: '$code fell through to a non-weather icon',
          );
        }
      }
    });

    test('a plain sky follows day and night; a phenomenon does not', () {
      // 100 晴 / 200 多雲 have a night form…
      expect(weatherVisual('', 100, _colors).$1, clearDay);
      expect(weatherVisual('', 100, _colors, isNight: true).$1, clearNight);
      expect(weatherVisual('', 200, _colors).$1, partlyCloudyDay);
      expect(
        weatherVisual('', 200, _colors, isNight: true).$1,
        partlyCloudyNight,
      );
      // …300 陰 does not: there is nothing behind full cloud to show.
      expect(weatherVisual('', 300, _colors, isNight: true).$1, cloudy);
      // Nor does a phenomenon — rain looks the same at 02:00.
      expect(weatherVisual('', 306, _colors, isNight: true).$1, rainy);
    });

    test('rain intensity reads in the glyph, not only the backdrop', () {
      expect(weatherVisual('', 311, _colors).$1, rainyLight); // 有陣雨
      expect(weatherVisual('', 306, _colors).$1, rainy); // 有雨
      expect(weatherVisual('', 317, _colors).$1, rainyHeavy); // 大雷雨
    });

    test('an unknown code still falls back to the text', () {
      expect(weatherVisual('陰有雨', 0, _colors).$1, rainy);
      expect(weatherVisual('晴', 0, _colors).$1, clearDay);
      expect(weatherVisual('晴', 0, _colors, isNight: true).$1, clearNight);
      expect(weatherVisual('多雲', 0, _colors).$1, partlyCloudyDay);
      expect(weatherVisual('大雷雨', 0, _colors).$1, thunderstorm);
      expect(weatherVisual('', 0, _colors).$1, cloudy);
    });
  });
}

const ColorScheme _colors = ColorScheme.dark();
