import 'package:flutter/widgets.dart';

import 'package:dpip/utils/extensions/datetime.dart';
import 'package:dpip/utils/extensions/int.dart';

extension LocaleString on String {
  Locale get asLocale {
    final a = split('-');
    return Locale(a[0], a.elementAtOrNull(1));
  }

  Uri get asUri => Uri.parse(this);

  int get asInt => int.parse(this);

  String toLocalTimeString(BuildContext context) => asInt.asTZDateTime.toLocalTimeString(context);
}
