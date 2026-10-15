/// Notification presets: one decision that sets every channel at once, instead
/// of nine separate ones on the per-channel page.
///
/// A preset is defined by the option *kind* it picks for each [NotifyChannel]
/// rather than by wire index, so the table below reads as what each channel
/// will do; the wire index is derived through [optionsFor], the same contract
/// the per-channel picker sends.
///
/// Why each channel lands where it does — every choice is the channel's
/// documented purpose (`NotificationChannels` in `core/notifications/`) read
/// against the defaults a fresh device starts from (every channel on at its
/// local threshold: EEW and the three earthquake channels at local intensity
/// 1+, the three weather channels at "my area", tsunami bulletins and
/// warnings, announcements on):
///
/// - **EEW is never off in any preset.** Its wire list has no "off" at all;
///   [NotifyPreset.emergencyOnly] narrows it to local intensity 4+, which is the
///   threshold the channel catalogue already routes to its urgent, critical
///   EEW channel (`eew-important-v2`) — the same line this app draws between a
///   major EEW and the rest. Turning EEW down further is only possible
///   channel by channel, i.e. by choosing [NotifyPreset.custom].
/// - **The three weather channels stay on in every preset.** The server
///   switches a whole channel, and each of them carries an urgent sub-channel
///   (山區暴雨, red-level 天氣警特報, 土石流/淹水/堰塞湖 警訊 — all in
///   `NotificationChannels.urgentChannelKeys`). Turning one off to drop its
///   routine messages would drop its life-safety ones with them.
/// - **Tsunami stays on in every preset**; only [NotifyPreset.emergencyOnly]
///   narrows it to warnings, dropping the distant-tsunami bulletins.
/// - **Recommended** is the fresh-device default minus one repeat: the
///   earthquake report restates, minutes later, what the intensity report
///   already said for the user's township, and stays readable in the app.
///   Everything about the shaking where the user is stays on — the real-time
///   monitor (the only alert when shaking outruns or never triggers an EEW)
///   and the intensity report — and so do announcements: they are rare, and
///   they are how the service says something like "alerts are delayed".
/// - **Emergency only** keeps exactly the channels with an urgent sub-channel
///   (EEW, the three weather channels, tsunami), each at the level that
///   sub-channel needs. The monitor, both earthquake reports and
///   announcements have none, so they are off.
/// - **All** is every channel at its broadest option, nationwide included.
library;

import 'package:dpip/features/notification/domain/notify_settings.dart';

/// One server write: set [channel] to wire option [option].
typedef NotifyChange = ({NotifyChannel channel, int option});

/// A named combination of channel options. Declaration order is display
/// order: [recommended] first because it is the preselected choice, [custom]
/// last because it is the way out to the per-channel controls.
enum NotifyPreset {
  /// 建議 — the alerts about the user's own location, minus the repeat.
  recommended,

  /// 全部 — every channel at its broadest option.
  all,

  /// 僅緊急 — only the channels that carry a life-safety alert.
  emergencyOnly,

  /// 自訂 — no fixed options; the name for every combination the other
  /// presets don't describe, and the way to the per-channel controls.
  custom;

  /// The option kind this preset selects for [channel], or null for [custom].
  NotifyOptionKind? kindFor(NotifyChannel channel) => switch (this) {
    // Broadest first is the documented display order of
    // [notifyOptionsForDisplay], so its head is "the most" for any channel.
    NotifyPreset.all => notifyOptionsForDisplay(channel).first.$2,
    NotifyPreset.recommended => switch (channel) {
      NotifyChannel.eew ||
      NotifyChannel.monitor ||
      NotifyChannel.intensity => NotifyOptionKind.localIntensity1,
      NotifyChannel.report => NotifyOptionKind.off,
      NotifyChannel.thunderstorm ||
      NotifyChannel.weatherAdvisory ||
      NotifyChannel.evacuation => NotifyOptionKind.weatherLocal,
      NotifyChannel.tsunami => NotifyOptionKind.tsunamiAll,
      NotifyChannel.announcement => NotifyOptionKind.all,
    },
    NotifyPreset.emergencyOnly => switch (channel) {
      NotifyChannel.eew => NotifyOptionKind.localIntensity4,
      NotifyChannel.monitor ||
      NotifyChannel.report ||
      NotifyChannel.intensity => NotifyOptionKind.off,
      NotifyChannel.thunderstorm ||
      NotifyChannel.weatherAdvisory ||
      NotifyChannel.evacuation => NotifyOptionKind.weatherLocal,
      NotifyChannel.tsunami => NotifyOptionKind.tsunamiWarning,
      NotifyChannel.announcement => NotifyOptionKind.off,
    },
    NotifyPreset.custom => null,
  };

  /// The wire option this preset selects for [channel], or null for [custom].
  int? optionFor(NotifyChannel channel) {
    final kind = kindFor(channel);
    if (kind == null) return null;
    final index = optionsFor(channel).indexOf(kind);
    // A kind the channel doesn't offer would be sent as -1 — a table typo
    // that must fail where it is written, not on the server.
    assert(index >= 0, '$name picks $kind, which ${channel.name} lacks');
    return index;
  }

  /// The preset [settings] is exactly, or [custom] when it is none of them.
  static NotifyPreset matching(NotifySettings settings) {
    for (final preset in values) {
      if (preset == custom) continue;
      final matches = NotifyChannel.values.every(
        (channel) => settings.optionOf(channel) == preset.optionFor(channel),
      );
      if (matches) return preset;
    }
    return custom;
  }

  /// The writes that turn [current] into this preset — one per channel that
  /// differs, none for [custom].
  ///
  /// Widening writes (towards more alerts) come before narrowing ones, each
  /// group in channel order, so EEW is always first in its group. Applying is
  /// one request at a time and can stop part-way; in this order a stop leaves
  /// the device hearing more than either the old or the new choice, never
  /// less. [optionsFor] runs narrowest to broadest (see
  /// [notifyOptionsForDisplay]), so a higher wire index is a wider option.
  List<NotifyChange> changesFrom(NotifySettings current) {
    final widening = <NotifyChange>[];
    final narrowing = <NotifyChange>[];
    for (final channel in NotifyChannel.values) {
      final target = optionFor(channel);
      if (target == null) continue;
      final from = current.optionOf(channel);
      if (target == from) continue;
      (target > from ? widening : narrowing).add((
        channel: channel,
        option: target,
      ));
    }
    return [...widening, ...narrowing];
  }
}
