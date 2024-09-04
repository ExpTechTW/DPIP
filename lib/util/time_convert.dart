import 'package:timezone/timezone.dart';

TZDateTime convertToTZDateTime(int timestamp) {
  DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
  TZDateTime taipeTime = TZDateTime.from(dateTime, getLocation('Asia/Taipei'));
  return taipeTime;
}
