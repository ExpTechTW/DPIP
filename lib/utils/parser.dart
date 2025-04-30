import "package:timezone/timezone.dart";

bool parseBoolishInt(v) => v == 1 || v == "1";
double parseDouble(v) => double.parse(v);
TZDateTime parseDateTime(v) {
  final location = getLocation("Asia/Taipei");
  if (v is String) return TZDateTime.fromMillisecondsSinceEpoch(location, int.parse(v));
  return TZDateTime.fromMillisecondsSinceEpoch(location, v);
}

int dateTimeToJson(TZDateTime v) => v.millisecondsSinceEpoch;
