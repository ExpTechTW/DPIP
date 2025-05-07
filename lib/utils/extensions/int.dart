import 'package:flutter/material.dart';

import 'package:timezone/timezone.dart';

import 'package:dpip/utils/extensions/datetime.dart';
import 'package:dpip/utils/parser.dart';

extension CommonContext on int {
  String get asIntensityLabel => ['0', '1', '2', '3', '4', '5-', '5+', '6-', '6+', '7'][this];
  String get asIntensityDisplayLabel => ['0', '1', '2', '3', '4', '5⁻', '5⁺', '6⁻', '6⁺', '7'][this];
  TZDateTime get asTZDateTime => parseDateTime(this);
  String toLocaleFullDateString(BuildContext context) => asTZDateTime.toLocaleFullDateString(context);
  String toLocaleTimeString(BuildContext context) => asTZDateTime.toLocaleTimeString(context);
}
