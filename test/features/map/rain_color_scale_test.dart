import 'package:dpip/core/error/result.dart';
import 'package:dpip/features/map/presentation/layers/rain_color_scale.dart';
import 'package:dpip/features/map/presentation/layers/rain_layer.dart';
import 'package:dpip/features/weather/domain/meteor_rain_repository.dart';
import 'package:dpip/features/weather/domain/rain_interval.dart';
import 'package:dpip/features/weather/domain/rain_snapshot.dart';
import 'package:dpip/features/weather/domain/rain_trend.dart';
import 'package:dpip/features/weather/domain/weather_station.dart';
import 'package:dpip/shared/color_hex.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'raster_timeline_harness.dart';

void main() {
  group('the published rainfall scale', () {
    test('both tables carry the same 17 bands in the same order', () {
      final fine = RainColorScale.fine.stops;
      final coarse = RainColorScale.coarse.stops;

      expect(fine, hasLength(17));
      expect(coarse, hasLength(17));
      expect(
        [for (final (_, hex) in coarse) hex],
        [for (final (_, hex) in fine) hex],
        reason:
            'the two scales differ only in where the boundaries fall — a '
            'colour that means "heavy" on one and "moderate" on the other '
            'would make the legend unreadable across a window change',
      );
    });

    test('thresholds ascend strictly, so `step` has a total order', () {
      for (final scale in RainColorScale.values) {
        final values = [for (final (at, _) in scale.stops) at];
        expect(
          values,
          orderedEquals(values.toList()..sort()),
          reason: '$scale is not ascending',
        );
        expect(
          values.toSet(),
          hasLength(values.length),
          reason: '$scale has a duplicate boundary',
        );
      }
    });

    test('the first band is the dry band at zero', () {
      for (final scale in RainColorScale.values) {
        expect(scale.stops.first.$1, 0, reason: '$scale');
      }
    });

    test('every colour parses', () {
      for (final scale in RainColorScale.values) {
        for (final (at, hex) in scale.stops) {
          expect(
            colorFromHexRgb(hex),
            isNotNull,
            reason: '$scale $at mm -> $hex',
          );
        }
      }
    });

    test('the fine table reaches 300 mm and the coarse one 1500 mm', () {
      expect(RainColorScale.fine.stops.last.$1, 300);
      expect(RainColorScale.coarse.stops.last.$1, 1500);
    });
  });

  group('scale suggested for a window', () {
    test('short windows get the fine table', () {
      for (final interval in [
        RainInterval.now,
        RainInterval.min10,
        RainInterval.hour1,
        RainInterval.hour3,
      ]) {
        expect(RainColorScale.defaultFor(interval), RainColorScale.fine);
      }
    });

    test('six hours and longer get the coarse table', () {
      for (final interval in [
        RainInterval.hour6,
        RainInterval.hour12,
        RainInterval.hour24,
        RainInterval.day2,
        RainInterval.day3,
      ]) {
        expect(RainColorScale.defaultFor(interval), RainColorScale.coarse);
      }
    });

    test('every window is covered', () {
      for (final interval in RainInterval.values) {
        expect(() => RainColorScale.defaultFor(interval), returnsNormally);
      }
    });
  });

  group('the rainfall layer', () {
    RainMapLayer layer() => RainMapLayer(_StubRainRepository());

    test('opens on the last hour, on the fine scale', () {
      final rain = layer();
      expect(rain.interval.value, RainInterval.hour1);
      expect(rain.colorScale.value, RainColorScale.fine);
      expect(rain.colorStops.last.$1, 300);
    });

    test('paints bands, not a gradient', () {
      expect(layer().bandedColors, isTrue);
    });

    test('changing the window re-suggests the scale for it', () async {
      final rain = layer();
      await rain.setInterval(RainInterval.day3);
      expect(rain.colorScale.value, RainColorScale.coarse);
      expect(rain.colorStops.last.$1, 1500);

      await rain.setInterval(RainInterval.min10);
      expect(rain.colorScale.value, RainColorScale.fine);
    });

    test('an explicit scale survives until the window moves', () async {
      final rain = layer();
      await rain.setInterval(RainInterval.hour24);
      expect(rain.colorScale.value, RainColorScale.coarse);

      await rain.setColorScale(RainColorScale.fine);
      expect(
        rain.colorScale.value,
        RainColorScale.fine,
        reason: 'a deliberate choice is not overridden while it stands',
      );
      expect(
        rain.interval.value,
        RainInterval.hour24,
        reason: 'changing the scale must not move the window',
      );

      await rain.setInterval(RainInterval.day2);
      expect(
        rain.colorScale.value,
        RainColorScale.coarse,
        reason:
            'the choice was made about a different range, so a new window '
            'starts from the suggestion again',
      );
    });

    test('a scale change keeps the dot size and its white outline', () async {
      final rain = layer();
      final controller = RecordingMapController();
      await rain.render(controller);

      final mounted = controller.lastProperties.keys.where(
        (id) => id.endsWith('-circle'),
      );
      expect(mounted, isEmpty, reason: 'nothing re-asserted yet');

      await rain.setColorScale(RainColorScale.coarse);

      final circleId = controller.lastProperties.keys.firstWhere(
        (id) => id.endsWith('-circle'),
        orElse: () => fail('the ramp was never re-asserted on the dot layer'),
      );
      final sent = controller.lastProperties[circleId]!;
      // setLayerProperties defaults to skipNulls: false and assigns EVERY
      // field, so a colour-only update silently resets the rest. It did:
      // the dots shrank to MapLibre's default radius and lost their outline.
      expect(sent['circle-radius'], 6, reason: 'dot size must not change');
      expect(sent['circle-stroke-width'], 1, reason: 'the outline must stay');
      expect(sent['circle-stroke-color'], '#FFFFFF');
      expect(sent['circle-opacity'], 0.9);
      expect(sent['circle-color'], isNotNull);
    });

    test('re-selecting the current window leaves an override alone', () async {
      final rain = layer();
      await rain.setColorScale(RainColorScale.coarse);
      await rain.setInterval(RainInterval.hour1);
      expect(rain.colorScale.value, RainColorScale.coarse);
    });
  });

  group('stepColor', () {
    final stops = RainColorScale.fine.stops;
    Color? at(double mm) => stepColor(stops, mm);

    test('a value takes its band floor colour, never a blend', () {
      // 70 mm opens the red band; nothing up to (but excluding) 90 changes it.
      final red = colorFromHexRgb('#ff0000');
      expect(at(70), red);
      expect(at(71), red);
      expect(at(89.9), red);
      expect(
        at(90),
        colorFromHexRgb('#c80000'),
        reason: 'the next floor takes over exactly at its own value',
      );
    });

    test('below the first boundary is the dry band', () {
      expect(at(0), colorFromHexRgb('#c2c2c2'));
      expect(at(0.9), colorFromHexRgb('#c2c2c2'));
      expect(at(1), colorFromHexRgb('#a0fffa'));
    });

    test('above the last boundary stays the top band', () {
      final top = colorFromHexRgb('#ffc8ff');
      expect(at(300), top);
      expect(at(9999), top);
    });

    test('only the declared colours are ever produced', () {
      final allowed = {for (final (_, hex) in stops) colorFromHexRgb(hex)};
      for (var mm = 0.0; mm <= 400; mm += 0.5) {
        expect(
          allowed,
          contains(at(mm)),
          reason: '$mm mm produced a colour that is in no band',
        );
      }
    });

    test('an empty ramp has no colour rather than throwing', () {
      expect(stepColor(const [], 5), isNull);
    });
  });
}

/// Minimal stand-in: the layer under test never fetches — these cases exercise
/// the window/scale coupling, which is pure state.
class _StubRainRepository implements MeteorRainRepository {
  @override
  Future<Result<Map<String, WeatherStation>>> stations() async => const Ok({});

  @override
  Future<Result<RainSnapshot>> latest() async =>
      const Ok(RainSnapshot(time: 0, stations: []));

  @override
  Future<Result<List<int>>> history() async => const Ok([]);

  @override
  Future<Result<RainSnapshot>> at(int second) async =>
      const Ok(RainSnapshot(time: 0, stations: []));

  @override
  Future<Result<RainTrend>> trend(String id, {String range = '24h'}) async =>
      Ok(RainTrend(id: id, range: range, times: const [], rain: const []));
}
