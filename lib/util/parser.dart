import "package:timezone/timezone.dart";

bool parseBoolishInt(v) => v == 1 || v == "1";
TZDateTime parseDateTime(v) => TZDateTime.fromMillisecondsSinceEpoch(getLocation("Asia/Taipei"), v);
int dateTimeToJson(TZDateTime v) => v.millisecondsSinceEpoch;
