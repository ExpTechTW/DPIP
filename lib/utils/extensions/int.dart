import 'package:flutter/material.dart';

import 'package:timezone/timezone.dart';

import 'package:dpip/core/i18n.dart';
import 'package:dpip/utils/extensions/datetime.dart';
import 'package:dpip/utils/parser.dart';

extension CommonContext on int {
  String get asIntensityNumber => ['0', '1', '2', '3', '4', '5', '5', '6', '6', '7'][this];
  String get asIntensityLabel =>
      [
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
  String get asIntensityDisplayLabel => ['0', '1', '2', '3', '4', '5⁻', '5⁺', '6⁻', '6⁺', '7'][this];
  TZDateTime get asTZDateTime => parseDateTime(this);
  int get asFahrenheit => (this * 9 / 5 + 32).round();

  String toSimpleDateTimeString() => asTZDateTime.toSimpleDateTimeString();
  String toLocaleFullDateString(BuildContext context) => asTZDateTime.toLocaleFullDateString(context);
  String toLocaleDateTimeString(BuildContext context) => asTZDateTime.toLocaleDateTimeString(context);
  String toLocaleTimeString(BuildContext context) => asTZDateTime.toLocaleTimeString(context);
}
