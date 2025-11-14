import 'package:dpip/api/model/location/location.dart';
import 'package:dpip/global.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/utils/extensions/datetime.dart';
import 'package:dpip/utils/extensions/int.dart';
import 'package:flutter/widgets.dart';

extension StringExtension on String {
  Locale get asLocale {
    final a = split('-');
    return Locale(a[0], a.elementAtOrNull(1));
  }

  Uri get asUri => Uri.parse(this);
  int get asInt => int.parse(this);

  String toLocaleFullDateString(BuildContext context) => asInt.asTZDateTime.toLocaleFullDateString(context);
  String toLocaleTimeString(BuildContext context) => asInt.asTZDateTime.toLocaleTimeString(context);
  String toSimpleDateTimeString() => asInt.asTZDateTime.toSimpleDateTimeString();

  Text get asText => Text(this);
  TextSpan get asTextSpan => TextSpan(text: this);

  Location getLocation() => Global.location[this]!;
  Location? get asLocation => Location.tryParse(this);
}

extension TextExtension on Text {
  Text size(double fontSize) => Text(data!, style: style?.copyWith(fontSize: fontSize));

  Text get bold => Text(data!, style: style?.copyWith(fontWeight: FontWeight.bold));

  Text onSurfaceVariant(BuildContext context) =>
      Text(data!, style: style?.copyWith(color: context.colors.onSurfaceVariant));
}
