import 'package:flutter/widgets.dart';

import 'package:i18n_extension/i18n_extension.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart';

extension TZDateTimeExtension on TZDateTime {
  String toSimpleDateTimeString(BuildContext context) =>
      DateFormat('MM/dd HH:mm', context.locale.toLanguageTag()).format(this);
  String toLocaleFullDateString(BuildContext context) =>
      DateFormat('yyyy/MM/dd (EEEE)', context.locale.toLanguageTag()).format(this);
  String toLocaleDateTimeString(BuildContext context) =>
      DateFormat('yyyy/MM/dd HH:mm:ss', context.locale.toLanguageTag()).format(this);
  String toLocaleTimeString(BuildContext context) =>
      DateFormat('HH:mm:ss', context.locale.toLanguageTag()).format(this);
}
