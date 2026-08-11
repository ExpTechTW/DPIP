/// The kind of a disaster event, which drives its timeline icon.
enum EventType {
  earthquake,
  report,
  intensity,
  thunderstorm,
  heavyRain,
  weatherWarning,
  tsunami,
  other;

  /// The wire `type` string mapped to a kind. An unrecognised weather notice
  /// still renders as a generic warning rather than dropping out of the feed —
  /// a disaster app must not silently hide a notice because a new type shipped.
  static EventType parse(String? wire) => switch (wire) {
    'earthquake' || 'eew' => EventType.earthquake,
    'report' => EventType.report,
    'intensity' => EventType.intensity,
    'thunderstorm' => EventType.thunderstorm,
    'heavy-rain' || 'heavy_rain' || 'rain' => EventType.heavyRain,
    'tsunami' => EventType.tsunami,
    null => EventType.other,
    _ => EventType.weatherWarning,
  };

  /// Semantic icon key for the shared [eventTypeIcon] resolver — kept a plain
  /// string so this domain enum never imports Material.
  String get iconKey => switch (this) {
    EventType.earthquake => 'earthquake',
    EventType.report => 'report',
    EventType.intensity => 'intensity',
    EventType.thunderstorm => 'thunderstorm',
    EventType.heavyRain => 'heavy_rain',
    EventType.weatherWarning => 'weather_warning',
    EventType.tsunami => 'tsunami',
    EventType.other => 'other',
  };
}

/// One item in the events timeline — an earthquake report, weather warning, etc.
///
/// A clean value type mapped from the v1 DPIP history feed, whose `text.content`
/// and `text.description` are **maps keyed by township code**. [fromJson] picks
/// the entry for the township being viewed, so the copy names the user's own
/// area rather than whichever one happens to sort first.
class Event {
  const Event({
    required this.id,
    required this.type,
    required this.time,
    required this.title,
    required this.description,
  });

  /// Maps one wire item for the township [regionCode], or null for the
  /// nationwide feed. Returns null when the item carries no usable timestamp —
  /// an undated entry can't be placed on a timeline.
  ///
  /// Every field is treated as optional: this is a legacy v1 feed, and a missing
  /// subtitle or description must degrade to a thinner row, never drop a
  /// disaster notice or throw.
  static Event? fromJson(Map<String, dynamic> json, {String? regionCode}) {
    final sent = _asInt(_asMap(json['time'])['send']);
    if (sent == null) return null;

    final text = _asMap(json['text']);
    final heading = _asMap(_pick(_asMap(text['content']), regionCode));
    final title = _asString(heading['title']) ?? _asString(heading['subtitle']);
    final description = _asString(
      _pick(_asMap(text['description']), regionCode),
    );

    return Event(
      // `id` is empty on weather notices; `key` is the stable fallback, and the
      // send time keeps list keys unique when neither is present.
      id: _asString(json['id']) ?? _asString(json['key']) ?? '$sent',
      type: EventType.parse(_asString(json['type'])),
      time: DateTime.fromMillisecondsSinceEpoch(sent),
      title: title ?? '',
      description: description ?? '',
    );
  }

  /// The entry for [regionCode], else the `all` entry.
  ///
  /// `all` is a fallback only when it is the map's **only** key. In this feed it
  /// otherwise holds one arbitrary township's text — "新北市三峽區有局部大雨"
  /// sits under `all` on a notice covering 112 other areas — so using it for a
  /// township that has its own entry would name the wrong place to someone
  /// checking the hazard in their own area.
  static dynamic _pick(Map<String, dynamic> byRegion, String? regionCode) {
    if (byRegion.isEmpty) return null;
    if (regionCode != null) {
      final own = byRegion[regionCode];
      if (own != null) return own;
    }
    if (byRegion.length == 1) return byRegion.values.first;
    return byRegion['all'];
  }

  static Map<String, dynamic> _asMap(dynamic value) =>
      value is Map ? value.cast<String, dynamic>() : const {};

  static String? _asString(dynamic value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static int? _asInt(dynamic value) => value is num ? value.toInt() : null;

  /// Stable identifier (for detail navigation and list keys).
  final String id;

  /// The event kind.
  final EventType type;

  /// When the event was issued.
  final DateTime time;

  /// Short headline.
  final String title;

  /// One-to-two line summary.
  final String description;
}
