import 'package:timezone/timezone.dart';

TZDateTime convertToTZDateTime(int timestamp) {
  final DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
  final TZDateTime taipeTime = TZDateTime.from(dateTime, getLocation('Asia/Taipei'));
  return taipeTime;
}
