import 'package:dpip/utils/extensions/build_context.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart';

extension TZDateTimeExtension on TZDateTime {
  String toLocalTimeString(BuildContext context) {
    return DateFormat(context.i18n.full_date_format, context.locale.toLanguageTag()).format(this);
  }
}
