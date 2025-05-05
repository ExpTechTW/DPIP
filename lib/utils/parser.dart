import "package:timezone/timezone.dart";

bool parseBoolishInt(dynamic v) => v == 1 || v == "1";
double parseDouble(dynamic v) => double.parse(v.toString());
TZDateTime parseDateTime(dynamic v) {
  final location = getLocation("Asia/Taipei");
  if (v is int) return TZDateTime.fromMillisecondsSinceEpoch(location, v);
  return TZDateTime.fromMillisecondsSinceEpoch(location, int.parse(v.toString()));
}

int dateTimeToJson(TZDateTime v) => v.millisecondsSinceEpoch;
