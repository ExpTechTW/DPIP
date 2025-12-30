/// Utility functions for JSON serialization and deserialization.
///
/// These functions are designed to be used with `json_serializable`'s `@JsonKey` annotation to handle custom type
/// conversions during JSON parsing and serialization. They provide consistent parsing logic for common data types that
/// may come in different formats from JSON APIs.
library;

import 'package:dpip/utils/extensions/number.dart';
import 'package:dpip/utils/extensions/string.dart';
import 'package:timezone/timezone.dart';

/// Parses a boolean-like integer value from JSON.
///
/// Returns `true` if the value is `1` (as an integer) or `'1'` (as a string), `false` otherwise. This is useful for
/// parsing boolean values that are represented as integers in JSON (common in some APIs).
///
/// Used with `@JsonKey(fromJson: parseBoolishInt)` in `json_serializable` models.
///
/// Example:
/// ```dart
/// @JsonKey(fromJson: parseBoolishInt)
/// final bool? alert;
/// ```
bool parseBoolishInt(v) => v == 1 || v == '1';

/// Parses a double value from JSON.
///
/// Converts the value to a string and then parses it as a double. This handles cases where numeric values may come as
/// strings or numbers in JSON.
///
/// Used with `@JsonKey(fromJson: parseDouble)` in `json_serializable` models.
///
/// Example:
/// ```dart
/// @JsonKey(fromJson: parseDouble)
/// final double temperature;
/// ```
double parseDouble(v) => double.parse(v.toString());

/// Parses a timestamp (milliseconds since epoch) from JSON into a [TZDateTime].
///
/// Converts a timestamp value (as an integer or string) to a timezone-aware date-time object using the 'Asia/Taipei'
/// timezone. The timestamp is expected to be in milliseconds since the Unix epoch.
///
/// Used with `@JsonKey(fromJson: parseDateTime, toJson: dateTimeToJson)` in `json_serializable` models.
///
/// Example:
/// ```dart
/// @JsonKey(fromJson: parseDateTime, toJson: dateTimeToJson)
/// final TZDateTime time;
/// ```
TZDateTime parseDateTime(v) {
  final value = v is int ? v : v.toString().asInt;
  return value.asTZDateTime;
}

/// Converts a [TZDateTime] to a JSON-serializable integer timestamp.
///
/// Returns the milliseconds since the Unix epoch for the given [TZDateTime]. This is the inverse operation of
/// [parseDateTime] and is used when serializing timezone-aware date-time objects to JSON.
///
/// Used with `@JsonKey(fromJson: parseDateTime, toJson: dateTimeToJson)` in `json_serializable` models.
///
/// Example:
/// ```dart
/// @JsonKey(fromJson: parseDateTime, toJson: dateTimeToJson)
/// final TZDateTime time;
/// ```
int dateTimeToJson(TZDateTime v) => v.millisecondsSinceEpoch;
