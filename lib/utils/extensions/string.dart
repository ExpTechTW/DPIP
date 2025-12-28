import 'package:flutter/widgets.dart';

import 'package:dpip/api/model/location/location.dart';
import 'package:dpip/global.dart';
import 'package:dpip/utils/extensions/datetime.dart';
import 'package:dpip/utils/extensions/number.dart';

/// Extension on [String] that provides convenient utilities for type conversion and formatting.
///
/// This extension adds helpful methods and getters to simplify common string operations, including type conversions,
/// date-time formatting, widget creation, and location parsing.
extension StringExtension on String {
  /// Converts this string to a [Locale] object.
  ///
  /// The string should be in the format "language-country" (e.g., "en-US", "zh-TW"). The method splits the string by
  /// '-' and creates a [Locale] with the language code as the first part and the country code as the optional second
  /// part.
  ///
  /// Example:
  /// ```dart
  /// final locale = 'zh-TW'.asLocale; // Locale('zh', 'TW')
  /// final locale2 = 'en'.asLocale; // Locale('en', null)
  /// ```
  Locale get asLocale {
    final a = split('-');
    return Locale(a[0], a.elementAtOrNull(1));
  }

  /// Converts this string to a [Uri] object.
  ///
  /// Parses this string as a URI. Throws a [FormatException] if the string is not a valid URI.
  ///
  /// Example:
  /// ```dart
  /// final uri = 'https://example.com'.asUri;
  /// ```
  Uri get asUri => .parse(this);

  /// Converts this string to an integer.
  ///
  /// Parses this string as an integer. Throws a [FormatException] if the string is not a valid integer.
  ///
  /// Example:
  /// ```dart
  /// final number = '123'.asInt; // 123
  /// ```
  int get asInt => .parse(this);

  /// Formats this string as a timestamp and converts it to a locale-aware full date string.
  ///
  /// This method first converts the string to an integer (milliseconds since epoch), then formats it as a locale-aware
  /// full date string in the format "yyyy/MM/dd (EEEE)" (e.g., "2024/12/25 (Wednesday)"). The day of the week is
  /// localized according to [context]'s locale.
  String toLocaleFullDateString(BuildContext context) =>
      asInt.asTZDateTime.toLocaleFullDateString(context);

  /// Formats this string as a timestamp and converts it to a locale-aware time string.
  ///
  /// This method first converts the string to an integer (milliseconds since epoch), then formats it as a locale-aware
  /// time string in the format "HH:mm:ss" (e.g., "14:30:45"). The format is localized according to [context]'s locale.
  String toLocaleTimeString(BuildContext context) =>
      asInt.asTZDateTime.toLocaleTimeString(context);

  /// Formats this string as a timestamp and converts it to a simple date-time string.
  ///
  /// This method first converts the string to an integer (milliseconds since epoch), then formats it as a simple
  /// date-time string in the format "MM/dd HH:mm" (e.g., "12/25 14:30").
  String toSimpleDateTimeString() =>
      asInt.asTZDateTime.toSimpleDateTimeString();

  /// Converts this string to a [Text] widget.
  ///
  /// Creates a [Text] widget with this string as its content. This is useful for quickly creating text widgets from
  /// strings in widget trees.
  ///
  /// Example:
  /// ```dart
  /// final widget = 'Hello'.asText;
  /// ```
  Text get asText => .new(this);

  /// Converts this string to a [TextSpan] object.
  ///
  /// Creates a [TextSpan] with this string as its text content. This is useful for building rich text widgets with
  /// multiple spans.
  ///
  /// Example:
  /// ```dart
  /// final span = 'Hello'.asTextSpan;
  /// ```
  TextSpan get asTextSpan => .new(text: this);

  /// Gets the [Location] object associated with this location code.
  ///
  /// Looks up this string as a location code in the global location map and returns the corresponding [Location].
  /// Throws an exception if the location code is not found.
  ///
  /// Example:
  /// ```dart
  /// final location = '10001'.getLocation();
  /// ```
  Location getLocation() => Global.location[this]!;

  /// Attempts to parse this string as a [Location] object.
  ///
  /// Parses this string as a location code and returns the corresponding [Location] if successful, or `null` if the
  /// string cannot be parsed or the location is not found.
  ///
  /// Example:
  /// ```dart
  /// final location = '10001'.asLocation; // Location or null
  /// ```
  Location? get asLocation => .tryParse(this);
}
