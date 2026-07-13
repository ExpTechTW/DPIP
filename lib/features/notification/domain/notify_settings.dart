/// The user's per-channel push-notification filters and the value model behind
/// them.
///
/// The backend represents all settings as a flat list of integers — one per
/// [NotifyChannel], in enum order — where each integer is the selected option's
/// position in that channel's [optionsFor] list. Keeping that wire shape here
/// (rather than nine typed enums) lets the settings page render every channel
/// through one generic row + option sheet, and lets [setChannel] echo the whole
/// list straight back into a new [NotifySettings].
library;

/// The notification channels, in server (wire) order — the index of each is the
/// position it occupies in the settings list.
enum NotifyChannel {
  /// Earthquake early warning (緊急地震速報).
  eew,

  /// Strong-motion monitor (強震監視器).
  monitor,

  /// Earthquake report (地震報告).
  report,

  /// Intensity report (震度速報).
  intensity,

  /// Real-time thunderstorm alerts (雷雨即時訊息).
  thunderstorm,

  /// Weather advisories (天氣警特報).
  weatherAdvisory,

  /// Disaster / evacuation info (防災資訊).
  evacuation,

  /// Tsunami info (海嘯資訊).
  tsunami,

  /// General announcements (公告).
  announcement,
}

/// The kinds of option a channel can offer. The *label* is resolved in the UI
/// (localized); this is just the semantic identity so the page can render a
/// radio list without knowing each channel's specifics.
enum NotifyOptionKind {
  /// Off.
  off,

  /// Receive everything.
  all,

  /// Local intensity 4 or above (EEW only).
  localIntensity4,

  /// Local intensity 1 or above.
  localIntensity1,

  /// The local area only (weather channels).
  weatherLocal,

  /// Tsunami warnings only.
  tsunamiWarning,

  /// Tsunami advisories and warnings.
  tsunamiAll,
}

/// The ordered options for [channel]. **The list index is the wire value** sent
/// to the server and stored in [NotifySettings], so order is part of the
/// contract and mirrors the legacy enums.
List<NotifyOptionKind> optionsFor(NotifyChannel channel) => switch (channel) {
  NotifyChannel.eew => const [
    NotifyOptionKind.localIntensity4,
    NotifyOptionKind.localIntensity1,
    NotifyOptionKind.all,
  ],
  NotifyChannel.monitor ||
  NotifyChannel.report ||
  NotifyChannel.intensity => const [
    NotifyOptionKind.off,
    NotifyOptionKind.localIntensity1,
    NotifyOptionKind.all,
  ],
  NotifyChannel.thunderstorm ||
  NotifyChannel.weatherAdvisory ||
  NotifyChannel.evacuation => const [
    NotifyOptionKind.off,
    NotifyOptionKind.weatherLocal,
  ],
  NotifyChannel.tsunami => const [
    NotifyOptionKind.tsunamiWarning,
    NotifyOptionKind.tsunamiAll,
  ],
  NotifyChannel.announcement => const [
    NotifyOptionKind.off,
    NotifyOptionKind.all,
  ],
};

/// An immutable snapshot of all channel selections, backed by the wire list.
class NotifySettings {
  const NotifySettings(this._values);

  /// One option index per [NotifyChannel], in enum order.
  final List<int> _values;

  /// Builds settings from the server's flat integer list, clamping each value
  /// into its channel's valid option range so a malformed index can't crash the
  /// picker. Throws [FormatException] if the list isn't one entry per channel.
  factory NotifySettings.fromWire(List<int> wire) {
    if (wire.length != NotifyChannel.values.length) {
      throw FormatException(
        'notify settings need ${NotifyChannel.values.length} channels, '
        'got ${wire.length}',
      );
    }
    return NotifySettings([
      for (final channel in NotifyChannel.values)
        wire[channel.index].clamp(0, optionsFor(channel).length - 1),
    ]);
  }

  /// The selected option index for [channel].
  int optionOf(NotifyChannel channel) => _values[channel.index];

  /// The selected option kind for [channel].
  NotifyOptionKind kindOf(NotifyChannel channel) =>
      optionsFor(channel)[optionOf(channel)];

  /// A copy with [channel] set to option [index].
  NotifySettings withChannel(NotifyChannel channel, int index) {
    final next = List.of(_values);
    next[channel.index] = index;
    return NotifySettings(next);
  }
}
