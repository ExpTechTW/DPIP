/// Deletes the Android notification channels earlier builds created and this
/// one no longer registers.
///
/// Android keeps a channel until the app that created it deletes it, through
/// every upgrade. Each rename of the catalogue — `eew_alert` became
/// `eew_alert-important`, which became `eew_alert-important-v2` — left the old
/// channel behind on every device that had run the old build, so the system
/// settings page listed two of every alert: one live, and one dead toggle that
/// nothing posts to and that reads as the switch to turn the alert off.
///
/// Runs on every launch and is idempotent: one call lists what exists, and a
/// second deletes only what is both retired and present, so a device that has
/// already been swept costs a single platform call. A no-op off Android.
library;

import 'dart:io';

import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/notifications/notification_channels.dart';
import 'package:flutter/services.dart';

class RetiredChannels {
  RetiredChannels({MethodChannel? channel, bool? isAndroid})
    : _channel =
          channel ??
          const MethodChannel('com.exptech.dpip/plain_notification_channels'),
      _isAndroid = isAndroid ?? Platform.isAndroid;

  final MethodChannel _channel;
  final bool _isAndroid;

  /// Every channel key a shipped build has created and this one does not.
  ///
  /// Read off git history, not remembered: `lib/core/notify.dart` and
  /// `lib/core/service.dart` before the rewrite, and the rewrite's own native
  /// foreground service. **Append, never remove** — a key leaves this list
  /// only when no device could still have it, which is never. When a key is
  /// dropped from [NotificationChannels.channels] it belongs here.
  static const Set<String> keys = {
    // The first catalogue (2024-06 to 2024-09).
    'eew_alert',
    'eew',
    'eew_silent',
    'eew_silence',
    'int_report',
    'int_report_silence',
    'eq',
    'report',
    'report_silence',
    'thunderstorm',
    'weather',
    'weather_major',
    'weather_minor',
    'evacuation_major',
    'evacuation_minor',
    'tsunami_warn',
    'tsunami',
    'tsunami_pacific_silent',
    'announcement',
    'heat',
    'flood',
    'rain_1',
    'rain_2',
    'typhoon',
    'volcano',
    'other',
    'basic_channel',
    'custom_sound',
    // Renamed by importance (2024-09 to 2025-07), then given the `-v2` suffix
    // the catalogue still carries.
    'eew_alert-important',
    'eew_alert-general',
    'eew_alert-silent',
    'eew-important',
    'eew-general',
    'eew-silence',
    'int_report-general',
    'int_report-silence',
    'report-general',
    'report-silence',
    'thunderstorm-general',
    'weather_major-important',
    'weather_minor-general',
    'evacuation_major-important',
    'evacuation_minor-general',
    'tsunami-important',
    'tsunami-general',
    'tsunami-silent',
    'announcement-general',
    // Background-service notices, from before location went geofence-based.
    'foreground-general',
    'background-general',
    'my_foreground',
    'dpip_background_location',
  };

  /// awesome_notifications' other spelling of a channel id:
  /// `<key>_<32 hex digits>`, the MD5 of the channel model. It creates that
  /// form whenever it updates a channel without forcing it, so a retired key
  /// can survive under it as well as under the plain key.
  static final RegExp _hashed = RegExp(r'^(.+)_[0-9a-f]{32}$');

  /// The ids in [existing] that are retired channels — exactly those, and in
  /// no case one the current catalogue registers.
  ///
  /// The live check is redundant with how [keys] is maintained, and kept
  /// anyway: deleting a live alert channel would throw away the user's own
  /// settings for it, and that must not depend on nobody ever mistyping this
  /// list.
  static List<String> retiredAmong(Iterable<String> existing) {
    final live = {
      for (final channel in NotificationChannels.channels) channel.channelKey,
    };
    return [
      for (final id in existing)
        if (!live.contains(id) && keys.contains(_keyOf(id))) id,
    ];
  }

  static String _keyOf(String id) {
    if (keys.contains(id)) return id;
    return _hashed.firstMatch(id)?.group(1) ?? id;
  }

  /// Deletes every retired channel present on this device; returns how many
  /// were deleted.
  ///
  /// Best-effort, like the rest of channel setup: a failure is logged and
  /// leaves the dead toggles where they were, which is untidy, not harmful.
  Future<int> sweep() async {
    if (!_isAndroid) return 0;
    try {
      final existing =
          await _channel.invokeListMethod<String>('list') ?? const <String>[];
      final retired = retiredAmong(existing);
      if (retired.isEmpty) return 0;
      final deleted =
          await _channel.invokeMethod<int>('delete', {'ids': retired}) ?? 0;
      Log.info(
        'notifications: deleted $deleted retired channel(s) — '
        '${retired.join(', ')}',
      );
      return deleted;
    } on PlatformException catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'deleting retired notification channels');
      return 0;
    } on MissingPluginException {
      // An engine that never registered the channel (tests, hot restarts into
      // a fresh messenger) simply skips the sweep.
      return 0;
    }
  }
}
