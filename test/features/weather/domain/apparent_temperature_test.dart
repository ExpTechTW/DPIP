import 'package:dpip/features/weather/domain/apparent_temperature.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('matches fixed CWA-formula parity vectors', () {
    // Project goldens from the published formula, shared with Swift tests.
    const vectors =
        <
          ({
            double temperature,
            int humidity,
            double windSpeed,
            double expected,
          })
        >[
          (
            temperature: 30,
            humidity: 80,
            windSpeed: 2,
            expected: 33.9659458296072,
          ),
          (
            temperature: 12,
            humidity: 65,
            windSpeed: 1.2,
            expected: 10.820012239693988,
          ),
          (
            temperature: 25,
            humidity: 60,
            windSpeed: 0,
            expected: 27.089955502470914,
          ),
          (
            temperature: 25,
            humidity: 60,
            windSpeed: 8,
            expected: 21.889955502470915,
          ),
          (
            temperature: 32,
            humidity: 10,
            windSpeed: 2,
            expected: 30.227599518688184,
          ),
          (
            temperature: 32,
            humidity: 95,
            windSpeed: 2,
            expected: 38.28219542753772,
          ),
          (
            temperature: -5,
            humidity: 70,
            windSpeed: 3,
            expected: -9.26026582286526,
          ),
          (
            temperature: 20,
            humidity: 0,
            windSpeed: 1,
            expected: 17.450000000000003,
          ),
          (
            temperature: 20,
            humidity: 100,
            windSpeed: 1,
            expected: 22.114536136797756,
          ),
        ];

    for (final vector in vectors) {
      expect(
        currentApparentTemperature(
          temperature: vector.temperature,
          humidity: vector.humidity,
          windSpeed: vector.windSpeed,
        ),
        closeTo(vector.expected, 1e-9),
        reason: '$vector',
      );
    }
  });

  test('rejects missing and invalid inputs', () {
    const valid = (temperature: 25.0, humidity: 60, windSpeed: 1.0);
    expect(
      currentApparentTemperature(
        temperature: null,
        humidity: valid.humidity,
        windSpeed: valid.windSpeed,
      ),
      isNull,
    );
    expect(
      currentApparentTemperature(
        temperature: valid.temperature,
        humidity: null,
        windSpeed: valid.windSpeed,
      ),
      isNull,
    );
    expect(
      currentApparentTemperature(
        temperature: valid.temperature,
        humidity: valid.humidity,
        windSpeed: null,
      ),
      isNull,
    );
    for (final humidity in [-1, 101]) {
      expect(
        currentApparentTemperature(
          temperature: valid.temperature,
          humidity: humidity,
          windSpeed: valid.windSpeed,
        ),
        isNull,
      );
    }
    expect(
      currentApparentTemperature(
        temperature: valid.temperature,
        humidity: valid.humidity,
        windSpeed: -0.1,
      ),
      isNull,
    );
    for (final nonFinite in [
      double.nan,
      double.infinity,
      double.negativeInfinity,
    ]) {
      expect(
        currentApparentTemperature(
          temperature: nonFinite,
          humidity: valid.humidity,
          windSpeed: valid.windSpeed,
        ),
        isNull,
      );
      expect(
        currentApparentTemperature(
          temperature: valid.temperature,
          humidity: valid.humidity,
          windSpeed: nonFinite,
        ),
        isNull,
      );
    }
    expect(
      currentApparentTemperature(
        temperature: -237.700000001,
        humidity: 100,
        windSpeed: 1,
      ),
      isNull,
    );
  });
}
