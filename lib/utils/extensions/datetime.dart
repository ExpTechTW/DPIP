import 'package:flutter/widgets.dart';

import 'package:i18n_extension/i18n_extension.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart';

final Map<String, DateFormat> _dateFormatCache = {};

DateFormat _getDateFormat(String pattern, [String? locale]) {
  final key = locale != null ? '$pattern-$locale' : pattern;
  return _dateFormatCache.putIfAbsent(key, () => DateFormat(pattern, locale));
}

extension DateTimeExtension on DateTime {
  String toSimpleDateTimeString() => _getDateFormat('MM/dd HH:mm').format(this);
  String toLocaleFullDateString(BuildContext context) =>
      _getDateFormat('yyyy/MM/dd (EEEE)', context.locale.toLanguageTag()).format(this);
  String toDateTimeString() => _getDateFormat('yyyy/MM/dd HH:mm:ss').format(this);
  String toLocaleTimeString() => _getDateFormat('HH:mm:ss').format(this);
  String toFullSimpleDateTimeString() => _getDateFormat('MM/dd HH:mm:ss').format(this);
}

extension TZDateTimeExtension on TZDateTime {
  String toSimpleDateTimeString() => _getDateFormat('MM/dd HH:mm').format(this);
  String toLocaleFullDateString(BuildContext context) =>
      _getDateFormat('yyyy/MM/dd (EEEE)', context.locale.toLanguageTag()).format(this);
  String toLocaleDateTimeString(BuildContext context) =>
      _getDateFormat('yyyy/MM/dd HH:mm:ss', context.locale.toLanguageTag()).format(this);
  String toLocaleTimeString(BuildContext context) =>
      _getDateFormat('HH:mm:ss', context.locale.toLanguageTag()).format(this);
  String toFullSimpleDateTimeString() => _getDateFormat('MM/dd HH:mm:ss').format(this);
}
