import 'package:flutter/widgets.dart';

import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart';

import 'package:dpip/utils/extensions/build_context.dart';

extension TZDateTimeExtension on TZDateTime {
  String toSimpleDateTimeString(BuildContext context) =>
      DateFormat('MM/dd HH:mm', context.locale.toLanguageTag()).format(this);
  String toLocaleFullDateString(BuildContext context) =>
      DateFormat(context.i18n.full_date_format, context.locale.toLanguageTag()).format(this);
  String toLocaleDateTimeString(BuildContext context) =>
      DateFormat(context.i18n.datetime_format, context.locale.toLanguageTag()).format(this);
  String toLocaleTimeString(BuildContext context) =>
      DateFormat(context.i18n.time_format, context.locale.toLanguageTag()).format(this);
}
