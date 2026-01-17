import 'package:dpip/core/i18n.dart';
import 'package:dpip/global.dart';
import 'package:i18n_extension/i18n_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'location.g.dart';

final Map<String, String> _cityWithLevelCache = {};
final Map<String, String> _townWithLevelCache = {};

/// Represents a geographical location in Taiwan with administrative hierarchy.
///
/// This class encapsulates location data including the city and town names, their administrative levels (縣/市/區/鄉/
/// 鎮), and geographical coordinates. It provides localized display methods for different presentation formats.
///
/// Example:
/// ```dart
/// const location = Location(
///   city: '臺北',
///   town: '信義',
///   lat: 25.0330,
///   lng: 121.5654,
///   cityLevel: '市',
///   townLevel: '區',
/// );
///
/// print(location.dynamicName); // "臺北市 信義區" or shorter if too long
/// ```
@JsonSerializable()
class Location {
  /// The city name (e.g., "臺北", "高雄").
  ///
  /// This represents the primary administrative division in Taiwan's government hierarchy.
  final String city;

  /// The town/district name (e.g., "信義", "前金").
  ///
  /// This represents the secondary administrative division within a city.
  final String town;

  /// The latitude coordinate in decimal degrees.
  ///
  /// Valid range is approximately 21.5° to 25.5° for Taiwan.
  final double lat;

  /// The longitude coordinate in decimal degrees.
  ///
  /// Valid range is approximately 120° to 122° for Taiwan.
  final double lng;

  /// The administrative level of the city (e.g., "市", "縣").
  ///
  /// This indicates the type of primary administrative division:
  /// - "市" for special municipalities and provincial cities
  /// - "縣" for counties
  final String cityLevel;

  /// The administrative level of the town (e.g., "區", "鄉", "鎮").
  ///
  /// This indicates the type of secondary administrative division:
  /// - "區" for districts (in cities)
  /// - "鄉" for townships
  /// - "鎮" for towns
  final String townLevel;

  /// Creates a new [Location] instance.
  ///
  /// All parameters are required and represent the administrative and geographical data for a location in Taiwan.
  const Location({
    required this.city,
    required this.town,
    required this.lat,
    required this.lng,
    required this.cityLevel,
    required this.townLevel,
  });

  /// Returns the full localized location name with both city and town levels.
  ///
  /// Format: `"{city}{cityLevel} {town}{townLevel}"`\
  /// Example: "臺北市 信義區" or "Taipei City Xinyi District"
  ///
  /// This is the most complete form of the location name including all administrative level indicators.
  String get cityTownWithLevel =>
      '{city}{cityLevel} {town}{townLevel}'.i18n.args({
        'city': city.locationName,
        'cityLevel': cityLevel.locationName,
        'town': town.locationName,
        'townLevel': townLevel.locationName,
      });

  /// Returns the localized location name without administrative levels.
  ///
  /// Format: `"{city} {town}"`\
  /// Example: "臺北 信義" or "Taipei Xinyi"
  ///
  /// This provides a cleaner, shorter display format without the administrative level suffixes.
  String get cityTown => '{city} {town}'.i18n.args({
    'city': city.locationName,
    'town': town.locationName,
  });

  /// Returns the localized city name with its administrative level.
  ///
  /// Format: `"{city}{cityLevel}"`\
  /// Example: "臺北市" or "Taipei City"
  ///
  /// Use this when you only need to display the primary administrative division.
  String get cityWithLevel {
    final key = '$city$cityLevel';
    return _cityWithLevelCache.putIfAbsent(
      key,
      () => '{city}{cityLevel}'.i18n.args({
        'city': city.locationName,
        'cityLevel': cityLevel.locationName,
      }),
    );
  }

  /// Returns the localized town name with its administrative level.
  ///
  /// Format: `"{town}{townLevel}"`\
  /// Example: "信義區" or "Xinyi District"
  ///
  /// Use this when you only need to display the secondary administrative division.
  String get townWithLevel {
    final key = '$town$townLevel';
    return _townWithLevelCache.putIfAbsent(
      key,
      () => '{town}{townLevel}'.i18n.args({
        'town': town.locationName,
        'townLevel': townLevel.locationName,
      }),
    );
  }

  /// Returns a localized location name that adapts to available space.
  ///
  /// This method implements a fallback strategy to provide the most appropriate location name based on length
  /// constraints:
  ///
  /// 1. First tries [cityTownWithLevel] (full format)
  /// 2. If too long (>24 chars), falls back to [townWithLevel]
  /// 3. If still too long, falls back to just [town] name
  ///
  /// This is ideal for UI elements with limited space where you want to show as much location detail as possible while
  /// maintaining readability.
  ///
  /// Example progression:
  /// - `"新北市板橋區"` → `"板橋區"` → `"板橋"`
  /// - `"Qianzhen District, Kaohsiung City"` → `"Qianzhen District"` → `"Qianzhen"`
  String get dynamicName {
    // Try full format first
    String content = cityTownWithLevel;

    // Fall back to town with level if too long
    if (content.length > 24) {
      content = townWithLevel;
    }

    // Fall back to town name only if still too long
    if (content.length > 24) {
      content = town;
    }

    return content;
  }

  /// Creates a [Location] instance from a JSON map.
  ///
  /// This factory constructor is generated by `json_annotation` and is used for deserializing location data from JSON
  /// sources such as APIs or local storage.
  ///
  /// Example:
  /// ```dart
  /// final json = {
  ///   'city': '臺北',
  ///   'town': '信義',
  ///   'lat': 25.0330,
  ///   'lng': 121.5654,
  ///   'cityLevel': '市',
  ///   'townLevel': '區',
  /// };
  /// final location = Location.fromJson(json);
  /// ```
  factory Location.fromJson(Map<String, dynamic> json) =>
      _$LocationFromJson(json);

  /// Converts this [Location] instance to a JSON map.
  ///
  /// This method is generated by `json_annotation` and is used for serializing location data to JSON format for storage
  /// or transmission.
  ///
  /// Returns a [Map<String, dynamic>] containing all the location properties with their original keys.
  Map<String, dynamic> toJson() => _$LocationToJson(this);

  /// Attempts to parse a Chinese location string into a [Location] instance.
  ///
  /// The input string should be in Chinese and follow the format `"{city}{cityLevel}{town}{townLevel}"`, but can have
  /// variations such as:
  /// - Missing administrative levels: `"臺北信義"` or `"臺北市信義"`
  /// - Extra spaces: `"臺北市 信義區"` or `"臺北 信義"`
  /// - Different combinations of levels
  ///
  /// Returns `null` if:
  /// - The city name cannot be found in the location database
  /// - The town name cannot be found within the identified city
  /// - The input string is empty or invalid
  ///
  /// Examples:
  /// ```dart
  /// Location.tryParse("臺北市信義區");     // ✓ Full format
  /// Location.tryParse("臺北信義");       // ✓ No levels
  /// Location.tryParse("臺北市 信義區");   // ✓ With spaces
  /// Location.tryParse("臺北信義區");     // ✓ Mixed levels
  /// Location.tryParse("不存在的地方");    // ✗ Returns null
  /// ```
  ///
  /// This method searches through the global location map (`Global.location`) to find matching city and town
  /// combinations.
  static Location? tryParse(String input) {
    if (input.trim().isEmpty) return null;

    // Clean the input: remove all spaces and normalize
    final cleanInput = input.replaceAll(RegExp(r'\s+'), '').toLowerCase();

    // Normalize traditional/simplified characters for better matching
    final normalizedInput = _normalizeChineseCharacters(cleanInput);

    // Try to find the best matching location
    Location? bestMatch;
    int bestMatchScore = 0;

    // Iterate through all locations in the database
    for (final locationEntry in Global.location.entries) {
      final location = locationEntry.value;

      // Generate possible Chinese representations of this location
      final possibleFormats = [
        '${location.city}${location.cityLevel}${location.town}${location.townLevel}', // Full format
        '${location.city}${location.cityLevel}${location.town}', // No town level
        '${location.city}${location.town}${location.townLevel}', // No city level
        '${location.city}${location.town}', // No levels
      ];

      // Check each possible format against the input
      for (final format in possibleFormats) {
        final normalizedFormat = _normalizeChineseCharacters(
          format.toLowerCase(),
        );

        if (normalizedInput == normalizedFormat) {
          // Exact match found - return immediately
          return location;
        }

        // Calculate match score for partial matches
        final score = _calculateMatchScore(normalizedInput, normalizedFormat);
        if (score > bestMatchScore) {
          bestMatchScore = score;
          bestMatch = location;
        }
      }
    }

    // Return the best match if it's good enough (threshold: 90% similarity for safety)
    return bestMatchScore >= 90 ? bestMatch : null;
  }

  /// Calculates a match score between input and target strings.
  ///
  /// Returns a score from 0-100 where 100 is a perfect match.
  /// Uses a simple similarity algorithm based on common character sequences.
  static int _calculateMatchScore(String input, String target) {
    if (input == target) return 100;
    if (input.isEmpty || target.isEmpty) return 0;

    // Check if input is a substring of target or vice versa
    if (target.contains(input)) {
      return (input.length * 100) ~/ target.length;
    }
    if (input.contains(target)) {
      return (target.length * 100) ~/ input.length;
    }

    // Count matching characters in order
    int matches = 0;
    int inputIndex = 0;
    int targetIndex = 0;

    while (inputIndex < input.length && targetIndex < target.length) {
      if (input[inputIndex] == target[targetIndex]) {
        matches++;
        inputIndex++;
        targetIndex++;
      } else {
        targetIndex++;
      }
    }

    return (matches * 100) ~/ input.length;
  }

  /// Normalizes Chinese characters for better matching between traditional and simplified forms.
  ///
  /// This method handles common character variations that might appear in user input
  /// vs. the database, ensuring "台中" matches "臺中", etc.
  static String _normalizeChineseCharacters(String input) {
    // Map of common simplified -> traditional character pairs used in Taiwan location names
    const charMap = {
      '台': '臺', // Taiwan/Platform
      '县': '縣', // County
      '区': '區', // District
      '乡': '鄉', // Township
      '镇': '鎮', // Town
      // Add more mappings as needed
    };

    String result = input;
    for (final entry in charMap.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }
    return result;
  }
}
