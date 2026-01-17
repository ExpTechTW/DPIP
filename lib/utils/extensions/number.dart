import 'dart:math';

import 'package:dpip/core/i18n.dart';
import 'package:dpip/utils/extensions/datetime.dart';
import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart';

/// Extension on [int] that provides convenient utilities for working with integer values.
///
/// This extension adds helpful methods and getters to simplify common operations on [int] values, such as earthquake
/// intensity conversions, temperature unit conversions, and date-time formatting.
extension IntExtension on int {
  /// Converts this earthquake intensity value to its numeric string representation.
  ///
  /// Returns a string representation of the intensity level (0-7). Note that intensity levels 5 and 6 each map to two
  /// values (5→'5', 6→'5', 7→'6', 8→'6', 9→'7') to account for the 5弱/5強 and 6弱/6強 subdivisions in the Japanese
  /// intensity scale.
  String get asIntensityNumber =>
      ['0', '1', '2', '3', '4', '5', '5', '6', '6', '7'][this];

  /// Converts this earthquake intensity value to its localized label.
  ///
  /// Returns a localized string label for the intensity level (e.g., "０級", "５弱", "７級"). The labels are translated
  /// via i18n according to the current locale.
  String get asIntensityLabel => [
    '０級'.i18n,
    '１級'.i18n,
    '２級'.i18n,
    '３級'.i18n,
    '４級'.i18n,
    '５弱'.i18n,
    '５強'.i18n,
    '６弱'.i18n,
    '６強'.i18n,
    '７級'.i18n,
  ][this];

  /// Converts this earthquake intensity value to its display label.
  ///
  /// Returns a compact string label suitable for display (e.g., "0", "5⁻", "5⁺", "7"). Uses superscript minus (⁻) and
  /// plus (⁺) symbols for the 5弱/5強 and 6弱/6強 subdivisions.
  String get asIntensityDisplayLabel =>
      ['0', '1', '2', '3', '4', '5⁻', '5⁺', '6⁻', '6⁺', '7'][this];

  /// Converts this timestamp (milliseconds since epoch) to a [TZDateTime].
  ///
  /// The timestamp is parsed and converted to a timezone-aware date-time object using the default timezone location
  /// (typically 'Asia/Taipei').
  TZDateTime get asTZDateTime {
    final location = getLocation('Asia/Taipei');
    return TZDateTime.fromMillisecondsSinceEpoch(location, this);
  }

  /// Formats this timestamp as a simple date-time string.
  ///
  /// Returns a string in the format "MM/dd HH:mm" (e.g., "12/25 14:30").
  String toSimpleDateTimeString() => asTZDateTime.toSimpleDateTimeString();

  /// Formats this timestamp as a full simple date-time string.
  ///
  /// Returns a string in the format "MM/dd HH:mm:ss" (e.g., "12/25 14:30:45").
  String toFullSimpleDateTimeString() =>
      asTZDateTime.toFullSimpleDateTimeString();

  /// Formats this timestamp as a locale-aware full date string.
  ///
  /// Returns a string in the format "yyyy/MM/dd (EEEE)" (e.g., "2024/12/25 (Wednesday)"). The day of the week is
  /// localized according to [context]'s locale.
  String toLocaleFullDateString(BuildContext context) =>
      asTZDateTime.toLocaleFullDateString(context);

  /// Formats this timestamp as a locale-aware date-time string.
  ///
  /// Returns a string in the format "yyyy/MM/dd HH:mm:ss" (e.g., "2024/12/25 14:30:45"). The format is localized
  /// according to [context]'s locale.
  String toLocaleDateTimeString(BuildContext context) =>
      asTZDateTime.toLocaleDateTimeString(context);

  /// Formats this timestamp as a locale-aware time string.
  ///
  /// Returns a string in the format "HH:mm:ss" (e.g., "14:30:45"). The format is localized according to [context]'s
  /// locale.
  String toLocaleTimeString(BuildContext context) =>
      asTZDateTime.toLocaleTimeString(context);
}

RegExp _trailingRegex = RegExp(r'([.]*0)(?!.*\d)');

/// Extension on [double] that provides convenient utilities for working with double values.
///
/// This extension adds helpful methods and getters to simplify common operations on [double] values, such as unit
/// conversions and formatting.
extension DoubleExtension on double {
  /// Round this to a specific floating precision
  double precision(int precision) {
    final mod = pow(10.0, precision);
    return ((this * mod).round() / mod);
  }

  /// Round this to a specific floating precision and convert it to a [String] without trailing zeros
  String precisionString(int precision) {
    final mod = pow(10.0, precision);
    final value = ((this * mod).round() / mod).toString();

    return value.replaceAll(_trailingRegex, '');
  }
}

/// Extension for number conversions
extension NumberConvert on num {
  /// Converts this to a double.
  double get asDouble => this.toDouble();

  /// Converts this to a integer.
  int get asInt => this.toInt();

  /// Converts this to a percentage.
  int get asPercentage => (this * 100).truncate();

  /// Converts this to a TZDateTime in Asia/Taipei Timezone.
  ///
  /// This calls [TZDateTime.fromMillisecondsSinceEpoch] under the hood.
  TZDateTime get asTZDateTime =>
      .fromMillisecondsSinceEpoch(getLocation('Asia/Taipei'), this.asInt);

  /// Converts this temperature value from Celsius to Fahrenheit.
  ///
  /// The conversion formula is: `F = C × 9/5 + 32`. The result preserves decimal precision, returning a [double] value.
  ///
  /// Example:
  /// ```dart
  /// final celsius = 25.5;
  /// final fahrenheit = celsius.asFahrenheit; // 77.9
  ///
  /// final zeroCelsius = 0.0;
  /// final zeroFahrenheit = zeroCelsius.asFahrenheit; // 32.0
  /// ```
  double get asFahrenheit => this * 9 / 5 + 32;
}
