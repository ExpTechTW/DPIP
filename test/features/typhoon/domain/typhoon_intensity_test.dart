import 'package:dpip/features/typhoon/domain/typhoon_intensity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('typhoonIntensityFromWind', () {
    test('CWA thresholds', () {
      expect(typhoonIntensityFromWind(null), isNull);
      expect(typhoonIntensityFromWind(17.1), TyphoonIntensity.td);
      expect(typhoonIntensityFromWind(17.2), TyphoonIntensity.mild);
      expect(typhoonIntensityFromWind(32.6), TyphoonIntensity.mild);
      expect(typhoonIntensityFromWind(32.7), TyphoonIntensity.moderate);
      expect(typhoonIntensityFromWind(50.9), TyphoonIntensity.moderate);
      expect(typhoonIntensityFromWind(51.0), TyphoonIntensity.intense);
    });
  });
}
