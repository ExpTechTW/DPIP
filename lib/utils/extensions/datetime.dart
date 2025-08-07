import 'package:flutter/widgets.dart';

import 'package:i18n_extension/i18n_extension.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart';

extension DateTimeExtension on DateTime {
  String toSimpleDateTimeString() => DateFormat('MM/dd HH:mm').format(this);
  String toLocaleFullDateString(BuildContext context) =>
      DateFormat('yyyy/MM/dd (EEEE)', context.locale.toLanguageTag()).format(this);
  String toDateTimeString() => DateFormat('yyyy/MM/dd HH:mm:ss').format(this);
  String toLocaleTimeString() => DateFormat('HH:mm:ss').format(this);
}

extension TZDateTimeExtension on TZDateTime {
  String toSimpleDateTimeString() => DateFormat('MM/dd HH:mm').format(this);
  String toLocaleFullDateString(BuildContext context) =>
      DateFormat('yyyy/MM/dd (EEEE)', context.locale.toLanguageTag()).format(this);
  String toLocaleDateTimeString(BuildContext context) =>
      DateFormat('yyyy/MM/dd HH:mm:ss', context.locale.toLanguageTag()).format(this);
  String toLocaleTimeString(BuildContext context) =>
      DateFormat('HH:mm:ss', context.locale.toLanguageTag()).format(this);
}
