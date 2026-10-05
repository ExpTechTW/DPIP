import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/map/map_layer_category.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('categoryOf', () {
    test('seismic monitor is its own group', () {
      expect(categoryOf('monitor'), MapLayerCategory.earthquake);
    });

    test('tsunami bulletins share the seismology group', () {
      // The group header reads 「地震與海嘯」 for exactly this reason: a tsunami
      // bulletin is issued off an earthquake, and the two are one product family
      // at CWA. A tsunami row under a header saying only 「地震」 would read as a
      // misfiled alert.
      expect(categoryOf('tsunami'), MapLayerCategory.earthquake);
    });

    test('typhoon is its own group', () {
      expect(categoryOf('typhoon'), MapLayerCategory.typhoon);
    });

    test('weather observations are the fields + lightning', () {
      for (final id in [
        'temperature',
        'humidity',
        'pressure',
        'wind',
        'rain',
        'lightning',
      ]) {
        expect(categoryOf(id), MapLayerCategory.weather, reason: id);
      }
    });

    test('satellite imagery is its own group', () {
      expect(categoryOf('satellite'), MapLayerCategory.satellite);
    });

    test('numerical weather prediction is its own group', () {
      expect(categoryOf('qpesums'), MapLayerCategory.forecast);
      expect(categoryOf('wind-gfs'), MapLayerCategory.forecast);
      expect(categoryOf('wind-ecmwf'), MapLayerCategory.forecast);
    });

    test('radar is its own group', () {
      expect(categoryOf('radar'), MapLayerCategory.radar);
    });

    test('the disaster-prevention map is the daily-life group', () {
      expect(categoryOf('dpm'), MapLayerCategory.life);
    });

    test('an unknown id resolves deterministically instead of throwing', () {
      // A layer added after the classification was written must not crash.
      expect(categoryOf('next-weather-layer'), MapLayerCategory.weather);
    });
  });

  test('every category resolves a label from every locale', () {
    for (final locale in AppLocalizations.supportedLocales) {
      final l10n = lookupAppLocalizations(locale);
      for (final category in MapLayerCategory.values) {
        expect(categoryLabel(category, l10n), isNotEmpty, reason: '$locale');
      }
    }
  });
}
