import 'package:dpip/core/i18n.dart';
import 'package:flutter/widgets.dart';
import 'package:i18n_extension/i18n_extension.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart';

/// Cache for [DateFormat] instances to avoid recreating them for the same pattern and locale.
final Map<String, DateFormat> _dateFormatCache = {};

/// Gets or creates a [DateFormat] instance for the given [pattern] and optional [locale].
///
/// This function implements a caching mechanism to reuse [DateFormat] instances, improving performance when formatting
/// multiple dates with the same pattern and locale.
///
/// The [pattern] is first translated via i18n (if a translation exists), then used to create or retrieve a cached
/// [DateFormat] instance. The cache key is constructed from the translated pattern and locale identifier to ensure
/// proper caching even when patterns differ by locale.
DateFormat _getDateFormat(String pattern, [String? locale]) {
  // Translate the pattern via i18n first
  final translatedPattern = pattern.i18n;

  // Construct cache key from translated pattern and locale
  final key = locale != null ? '$translatedPattern-$locale' : translatedPattern;

  return _dateFormatCache.putIfAbsent(
    key,
    () => DateFormat(translatedPattern, locale),
  );
}

/// Extension on [DateTime] that provides convenient utilities for formatting dates and times.
///
/// This extension adds helpful methods and getters to simplify date and time formatting operations, including
/// locale-aware formatting and standardized string representations.
extension DateTimeExtension on DateTime {
  /// Formats this date and time as a simple string.
  ///
  /// Returns a string in the format "MM/dd HH:mm" (e.g., "12/25 14:30").
  String toSimpleDateTimeString() => _getDateFormat('MM/dd HH:mm').format(this);

  /// Formats this date as a locale-aware full date string.
  ///
  /// Returns a string in the format "yyyy/MM/dd (EEEE)" (e.g., "2024/12/25 (Wednesday)"). The day of the week is
  /// localized according to [context]'s locale.
  String toLocaleFullDateString(BuildContext context) => _getDateFormat(
    'yyyy/MM/dd (EEEE)',
    context.locale.toLanguageTag(),
  ).format(this);

  /// Formats this date and time as a full string.
  ///
  /// Returns a string in the format "yyyy/MM/dd HH:mm:ss" (e.g., "2024/12/25 14:30:45").
  String toDateTimeString() =>
      _getDateFormat('yyyy/MM/dd HH:mm:ss').format(this);

  /// Formats the time portion of this date as a string.
  ///
  /// Returns a string in the format "HH:mm:ss" (e.g., "14:30:45").
  String toLocaleTimeString() => _getDateFormat('HH:mm:ss').format(this);

  /// Formats this date and time as a full simple string.
  ///
  /// Returns a string in the format "MM/dd HH:mm:ss" (e.g., "12/25 14:30:45").
  String toFullSimpleDateTimeString() =>
      _getDateFormat('MM/dd HH:mm:ss').format(this);
}

/// Extension on [TZDateTime] that provides convenient utilities for formatting timezone-aware dates and times.
///
/// This extension adds helpful methods and getters to simplify timezone-aware date and time formatting operations,
/// including locale-aware formatting and standardized string representations.
extension TZDateTimeExtension on TZDateTime {
  /// Formats this date and time as a simple string.
  ///
  /// Returns a string in the format "MM/dd HH:mm" (e.g., "12/25 14:30").
  String toSimpleDateTimeString() => _getDateFormat('MM/dd HH:mm').format(this);

  /// Formats this date as a locale-aware full date string.
  ///
  /// Returns a string in the format "yyyy/MM/dd (EEEE)" (e.g., "2024/12/25 (Wednesday)"). The day of the week is
  /// localized according to [context]'s locale.
  String toLocaleFullDateString(BuildContext context) => _getDateFormat(
    'yyyy/MM/dd (EEEE)',
    context.locale.toLanguageTag(),
  ).format(this);

  /// Formats this date and time as a locale-aware full string.
  ///
  /// Returns a string in the format "yyyy/MM/dd HH:mm:ss" (e.g., "2024/12/25 14:30:45"). The format is localized
  /// according to [context]'s locale.
  String toLocaleDateTimeString(BuildContext context) => _getDateFormat(
    'yyyy/MM/dd HH:mm:ss',
    context.locale.toLanguageTag(),
  ).format(this);

  /// Formats the time portion of this date as a locale-aware string.
  ///
  /// Returns a string in the format "HH:mm:ss" (e.g., "14:30:45"). The format is localized according to [context]'s
  /// locale.
  String toLocaleTimeString(BuildContext context) =>
      _getDateFormat('HH:mm:ss', context.locale.toLanguageTag()).format(this);

  /// Formats this date and time as a full simple string.
  ///
  /// Returns a string in the format "MM/dd HH:mm:ss" (e.g., "12/25 14:30:45").
  String toFullSimpleDateTimeString() =>
      _getDateFormat('MM/dd HH:mm:ss').format(this);
}
