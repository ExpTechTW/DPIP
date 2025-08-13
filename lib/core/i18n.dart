import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:i18n_extension/i18n_extension.dart';

class I18nCsvLoader {
  I18nCsvLoader._();

  static Future<Map<String, Map<String, String>>> fromFile(String path) async {
    final csvContent = await rootBundle.loadString(path);
    return _parseCsvTranslations(csvContent);
  }

  static Map<String, Map<String, String>> _parseCsvTranslations(String csvContent) {
    final lines = LineSplitter.split(csvContent);
    if (lines.isEmpty) return {};

    // Parse headers
    final headers = _parseCsvLine(lines.first);
    if (headers.isEmpty || headers[0] != 'key') {
      throw const FormatException('CSV must start with "key" column');
    }

    // Extract language codes from headers (skip 'key' column)
    final languageCodes = headers.skip(1).toList();

    // Initialize result map with empty language maps
    final Map<String, Map<String, String>> result = {};
    for (final langCode in languageCodes) {
      result[langCode] = <String, String>{};
    }

    // Process data rows
    for (final line in lines.skip(1)) {
      if (line.trim().isEmpty) continue;

      final values = _parseCsvLine(line);
      if (values.isEmpty || values[0].isEmpty) continue;

      final key = values[0];
      final translations = values.skip(1).toList();

      result[key] = {for (final langCode in languageCodes) langCode: translations[languageCodes.indexOf(langCode)]};
    }

    return result;
  }

  /// Parse a CSV line, handling quoted fields and commas
  static List<String> _parseCsvLine(String line) {
    final List<String> result = [];
    final StringBuffer current = StringBuffer();
    bool inQuotes = false;
    bool lastWasQuote = false;

    for (int i = 0; i < line.length; i++) {
      final char = line[i];

      if (char == '"') {
        if (inQuotes && lastWasQuote) {
          // Double quote inside quoted field - add single quote
          current.write('"');
          lastWasQuote = false;
        } else if (inQuotes) {
          // End of quoted field
          lastWasQuote = true;
        } else {
          // Start of quoted field
          inQuotes = true;
          lastWasQuote = false;
        }
      } else if (char == ',' && (!inQuotes || lastWasQuote)) {
        // Field separator
        result.add(current.toString());
        current.clear();
        inQuotes = false;
        lastWasQuote = false;
      } else {
        // Regular character
        current.write(char);
        lastWasQuote = false;
      }
    }

    // Add final field
    result.add(current.toString());

    return result;
  }
}

extension AppLocalizations on String {
  static final _t = Translations.byFile('zh-Hant', dir: 'assets/translations');
  static Future<void> load() => _t.load();
  String get i18n => localize(this, _t);
}

extension LocationNameLocalizations on String {
  static late final Translations _locationNames;
  static bool _isLoaded = false;

  static Future<void> load() async {
    if (_isLoaded) return;

    final translations = await I18nCsvLoader.fromFile('assets/location_names.csv');

    _locationNames = Translations.byId('zh-Hant', translations);
    _isLoaded = true;
  }

  String get locationName => localize(this, _locationNames);
}

extension WeatherStationLocalizations on String {
  static late final Translations _weatherStations;
  static bool _isLoaded = false;

  static Future<void> load() async {
    if (_isLoaded) return;

    final translations = await I18nCsvLoader.fromFile('assets/weather_station_names.csv');

    _weatherStations = Translations.byId('zh-Hant', translations);
    _isLoaded = true;
  }

  String get weatherStation => localize(this, _weatherStations);
}
