/// Event cards and reports for presentation tests, with every field the tests
/// do not care about filled with a plausible value.
library;

import 'package:dpip/features/events/domain/event_card.dart';
import 'package:dpip/features/events/domain/event_hazard.dart';

/// A card of [hazard], sent at [send] and ending at [expires].
EventCard eventCard({
  int id = 1,
  int serial = 1,
  EventReportKind kind = EventReportKind.issue,
  String type = 'heavy-rain',
  EventHazard hazard = EventHazard.heavyRain,
  String? hazardCode,
  String title = 'Heavy rain advisory',
  String subtitle = 'Taipei City',
  required DateTime send,
  DateTime? expires,
  bool expiresOpen = false,
}) => EventCard(
  id: id,
  serial: serial,
  kind: kind,
  type: type,
  hazard: hazard,
  hazardCode: hazardCode ?? hazard.code,
  status: 1,
  author: 'cwa',
  lang: 'en',
  title: title,
  subtitle: subtitle,
  send: send,
  expires: expires,
  expiresOpen: expiresOpen,
  hasPolygon: false,
);

/// Report [serial] of card [id].
EventReport eventReport({
  int id = 1,
  required int serial,
  EventReportKind kind = EventReportKind.update,
  String type = 'heavy-rain',
  EventHazard hazard = EventHazard.heavyRain,
  String lang = 'en',
  String title = 'Heavy rain advisory',
  String subtitle = 'Taipei City',
  required DateTime send,
  DateTime? expires,
  bool expiresOpen = false,
  Map<String, dynamic>? addition,
  String? description,
  EventOriginal? original,
}) => EventReport(
  id: id,
  serial: serial,
  kind: kind,
  type: type,
  hazard: hazard,
  hazardCode: hazard.code,
  status: 1,
  author: 'cwa',
  lang: lang,
  title: title,
  subtitle: subtitle,
  send: send,
  expires: expires,
  expiresOpen: expiresOpen,
  hasPolygon: false,
  addition: addition,
  description: description,
  original: original,
);
