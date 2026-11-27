/// App API v2 event cards: the list's summary of each card, and the reports a
/// card's detail lists.
///
/// Parsing is defensive. A card or report missing a field it cannot be shown
/// without is dropped with a warning and the rest of the response is kept; a
/// field that only refines it (its kind, hazard, end time, area…) falls back
/// to its empty value instead. All times are UTC.
library;

import 'package:dpip/core/logging/log.dart';
import 'package:dpip/features/events/domain/event_hazard.dart';

/// The `expires` value, 9999-12-31T23:59:59Z in epoch milliseconds, that
/// marks a card whose end time is not known yet — a tsunami warning until it
/// is lifted.
const int kEventExpiresOpenMs = 253402300799000;

/// Which report of its card a report is.
enum EventReportKind {
  /// The first report.
  issue,

  /// A later report. Lifting a tsunami warning and cancelling a detection are
  /// updates too: the card then ends at its end time.
  update,

  /// A correction.
  correct,

  /// A withdrawal by the issuer. Always the card's last report.
  cancel,

  /// A missing or unrecognised kind.
  unknown;

  /// The kind named [value] on the wire; [unknown] for anything else.
  static EventReportKind fromWire(String? value) => switch (value) {
    'issue' => issue,
    'update' => update,
    'correct' => correct,
    'cancel' => cancel,
    _ => unknown,
  };
}

/// The Taiwan-Mandarin text of a report that is shown translated.
final class EventOriginal {
  const EventOriginal({
    required this.title,
    required this.subtitle,
    this.description,
  });

  final String title;
  final String subtitle;
  final String? description;

  /// The original text in [json]; null unless it is an object with string
  /// `title` and `subtitle`.
  static EventOriginal? _tryParse(Object? json) {
    final object = _asObject(json);
    if (object == null) return null;
    final title = object['title'];
    final subtitle = object['subtitle'];
    if (title is! String || subtitle is! String) return null;
    final description = object['description'];
    return EventOriginal(
      title: title,
      subtitle: subtitle,
      description: description is String ? description : null,
    );
  }
}

/// One card of a list: the summary of the card's latest report.
final class EventCard {
  const EventCard({
    required this.id,
    required this.serial,
    required this.kind,
    required this.type,
    required this.hazard,
    required this.hazardCode,
    required this.status,
    required this.author,
    required this.lang,
    required this.title,
    required this.subtitle,
    required this.send,
    required this.expires,
    this.expiresOpen = false,
    required this.hasPolygon,
  });

  EventCard._read(_Reader r)
    : id = r.id(),
      serial = r.integer('serial'),
      kind = EventReportKind.fromWire(r.optional('kind', _asString)),
      type = r.string('type'),
      hazard = EventHazard.fromCode(r.hazardCode),
      hazardCode = r.hazardCode,
      status = r.integer('status'),
      author = r.string('author'),
      lang = r.string('lang'),
      title = r.string('title'),
      subtitle = r.string('subtitle'),
      send = r.time('send'),
      expires = r.expiry.at,
      expiresOpen = r.expiry.open,
      hasPolygon = r.optional('hasPolygon', _asBool) ?? false;

  /// The card id, shared by all of its reports.
  final int id;

  /// Which report this is. Follows the source's own numbering for some types,
  /// so it can skip numbers and start above 1.
  final int serial;

  final EventReportKind kind;

  /// The card type exactly as sent, including types this version does not
  /// know.
  final String type;

  /// The hazard the server classified [type] under.
  final EventHazard hazard;

  /// The `hazard` string exactly as sent — empty when absent — so an
  /// unrecognised code can still be shown.
  final String hazardCode;

  final int status;
  final String author;

  /// The language the text is actually in: the requested one, or `zh-TW`
  /// when its translation is not complete yet.
  final String lang;

  final String title;
  final String subtitle;

  /// When this report was issued.
  final DateTime send;

  /// When the card ends. Null when the server gave no end time, and when the
  /// end time is not known yet ([expiresOpen]).
  final DateTime? expires;

  /// Whether the end time is not known yet: the card stays current until a
  /// later report gives one.
  final bool expiresOpen;

  /// Whether the card has a polygon, which only the detail carries.
  final bool hasPolygon;

  /// Whether the card is still in effect at [nowUtc]: its end time is not
  /// known yet, or is strictly after [nowUtc].
  bool isActiveAt(DateTime nowUtc) =>
      expiresOpen || (expires?.isAfter(nowUtc) ?? false);

  /// The card in [json]; null, with a warning logged, when it is not an
  /// object or lacks a field it cannot be shown without. Never throws.
  static EventCard? tryParse(Object? json) =>
      _parse(json, 'card', EventCard._read);
}

/// One report of a card's detail.
final class EventReport extends EventCard {
  const EventReport({
    required super.id,
    required super.serial,
    required super.kind,
    required super.type,
    required super.hazard,
    required super.hazardCode,
    required super.status,
    required super.author,
    required super.lang,
    required super.title,
    required super.subtitle,
    required super.send,
    required super.expires,
    super.expiresOpen,
    required super.hasPolygon,
    this.area = const [],
    this.addition,
    this.description,
    this.polygon,
    this.original,
  });

  EventReport._read(super.r)
    : area = r.area(),
      addition = r.optional('addition', _asObject),
      description = r.optional('description', _asString),
      polygon = r.optional('polygon', _asObject),
      original = r.optional('original', EventOriginal._tryParse),
      super._read();

  /// The township codes this report covers; empty when it covers none.
  final List<int> area;

  /// The source's raw data, as sent.
  final Map<String, dynamic>? addition;

  final String? description;

  /// The GeoJSON polygon, as sent.
  final Map<String, dynamic>? polygon;

  /// The original text, present only when this report is shown translated.
  final EventOriginal? original;

  /// The report in [json]; null, with a warning logged, when it is not an
  /// object or lacks a field it cannot be shown without. Never throws.
  static EventReport? tryParse(Object? json) =>
      _parse(json, 'report', EventReport._read);
}

/// A list response: the latest report of each card.
final class EventCardList {
  const EventCardList({required this.lang, required this.cards});

  /// The requested language tag.
  final String lang;

  final List<EventCard> cards;

  /// The list in [json]. Throws [FormatException] when the body is not a list
  /// response; a card that cannot be read is left out.
  static EventCardList fromJson(Object? json) {
    final (lang, items) = _envelope(json, 'list');
    return EventCardList(
      lang: lang,
      cards: List.unmodifiable([
        for (final item in items) ?EventCard.tryParse(item),
      ]),
    );
  }
}

/// A detail response: every report of one card.
final class EventCardDetail {
  EventCardDetail({required this.lang, required this.reports})
    : assert(reports.isNotEmpty, 'a card has at least one report');

  /// The requested language tag.
  final String lang;

  /// Every report, by [EventCard.serial] ascending. Never empty.
  final List<EventReport> reports;

  /// The newest report, which the list shows.
  EventReport get latest => reports.last;

  /// The detail in [json]. Throws [FormatException] when the body is not a
  /// detail response or none of its reports can be read; a report that cannot
  /// be read is left out.
  static EventCardDetail fromJson(Object? json) {
    final (lang, items) = _envelope(json, 'detail');
    final reports = [for (final item in items) ?EventReport.tryParse(item)];
    if (reports.isEmpty) {
      throw const FormatException('App API v2 detail: no readable report');
    }
    // Stable: reports with the same serial keep the server's order.
    final ordered = reports.indexed.toList()
      ..sort((a, b) {
        final bySerial = a.$2.serial.compareTo(b.$2.serial);
        return bySerial != 0 ? bySerial : a.$1.compareTo(b.$1);
      });
    return EventCardDetail(
      lang: lang,
      reports: List.unmodifiable([for (final (_, report) in ordered) report]),
    );
  }
}

/// The `lang` and `cards` of a list or detail body.
(String, List<Object?>) _envelope(Object? json, String what) {
  final object = _asObject(json);
  if (object == null) {
    throw FormatException('App API v2 $what: the body is not a JSON object');
  }
  final lang = object['lang'];
  if (lang is! String) {
    throw FormatException(
      'App API v2 $what: "lang" is missing or not a string',
    );
  }
  final cards = object['cards'];
  if (cards is! List<Object?>) {
    throw FormatException('App API v2 $what: "cards" is missing or not a list');
  }
  return (lang, cards);
}

/// Reads one card or report with [read], logging what was dropped or ignored.
T? _parse<T>(Object? json, String what, T Function(_Reader) read) {
  final object = _asObject(json);
  if (object == null) {
    Log.warning('events v2: dropped a $what that is not a JSON object');
    return null;
  }
  final reader = _Reader(object);
  try {
    final value = read(reader);
    if (reader.ignored.isNotEmpty) {
      Log.warning(
        'events v2: $what ${object['id']} — ignored malformed '
        '${reader.ignored.join(', ')}',
      );
    }
    return value;
  } on _MissingField catch (missing) {
    Log.warning(
      'events v2: dropped $what ${object['id']} — "${missing.field}" is '
      'missing or malformed',
    );
    return null;
  }
}

/// A required field that is absent or of the wrong shape. Thrown and caught
/// within [_parse] only.
final class _MissingField implements Exception {
  const _MissingField(this.field);

  final String field;
}

/// Field access over one card or report object.
///
/// A required field throws [_MissingField] when absent or of the wrong shape.
/// An optional one reads as null when absent, and also when of the wrong
/// shape, in which case its name is added to [ignored].
final class _Reader {
  _Reader(this._json);

  final Map<String, dynamic> _json;

  /// Optional fields that were present but of the wrong shape.
  final List<String> ignored = [];

  /// A JSON number, or a decimal string such as `"1001"`.
  int id() => switch (_json['id']) {
    final String text when _decimal.hasMatch(text) =>
      int.tryParse(text) ?? (throw const _MissingField('id')),
    final Object? value => _asInt(value) ?? (throw const _MissingField('id')),
  };

  int integer(String key) => _asInt(_json[key]) ?? (throw _MissingField(key));

  String string(String key) =>
      _asString(_json[key]) ?? (throw _MissingField(key));

  DateTime time(String key) => _utc(integer(key)) ?? (throw _MissingField(key));

  T? optional<T>(String key, T? Function(Object?) parse) {
    final raw = _json[key];
    if (raw == null) return null;
    final value = parse(raw);
    if (value == null) ignored.add(key);
    return value;
  }

  late final String hazardCode = optional('hazard', _asString) ?? '';

  /// The end time, and whether it is the open-ended marker.
  late final ({DateTime? at, bool open}) expiry = _expiry();

  ({DateTime? at, bool open}) _expiry() {
    final ms = optional('expires', _asInt);
    // `0` is how the server says there is no end time.
    if (ms == null || ms == 0) return (at: null, open: false);
    if (ms == kEventExpiresOpenMs) return (at: null, open: true);
    final at = _utc(ms);
    if (at == null) ignored.add('expires');
    return (at: at, open: false);
  }

  /// The township codes, keeping only the elements that are integers.
  List<int> area() {
    final raw = _json['area'];
    if (raw == null) return const [];
    if (raw is! List<Object?>) {
      ignored.add('area');
      return const [];
    }
    final codes = [for (final element in raw) ?_asInt(element)];
    if (codes.length != raw.length) ignored.add('area');
    return List.unmodifiable(codes);
  }
}

final RegExp _decimal = RegExp(r'^-?[0-9]+$');

/// The widest instant [DateTime] can hold, in epoch milliseconds.
const int _maxEpochMs = 8640000000000000;

/// The largest integer a double holds exactly, 2^53.
const double _maxExactDouble = 9007199254740992;

/// [value] as an int: an int, or a double holding a whole number exactly.
int? _asInt(Object? value) => switch (value) {
  final int whole => whole,
  final double number
      when number.abs() <= _maxExactDouble &&
          number == number.truncateToDouble() =>
    number.toInt(),
  _ => null,
};

String? _asString(Object? value) => value is String ? value : null;

bool? _asBool(Object? value) => value is bool ? value : null;

/// [value] as a JSON object, the same instance when it already is one.
Map<String, dynamic>? _asObject(Object? value) => switch (value) {
  final Map<String, dynamic> object => object,
  final Map<Object?, Object?> map when map.keys.every((key) => key is String) =>
    Map<String, dynamic>.from(map),
  _ => null,
};

DateTime? _utc(int ms) => ms < -_maxEpochMs || ms > _maxEpochMs
    ? null
    : DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
