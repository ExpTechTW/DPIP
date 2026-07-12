/// The kind of a disaster event, which drives its timeline icon.
enum EventType {
  earthquake,
  report,
  intensity,
  thunderstorm,
  heavyRain,
  weatherWarning,
  tsunami,
  other,
}

/// One item in the events timeline — an earthquake report, weather warning, etc.
///
/// A clean value type for the feed, mapped from the DPIP history API when that
/// is wired (the legacy `History` model's `content`/`description` per-area maps
/// collapse to a single [title]/[description] here). Holds placeholder data for
/// now.
class Event {
  const Event({
    required this.id,
    required this.type,
    required this.time,
    required this.title,
    required this.description,
  });

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
