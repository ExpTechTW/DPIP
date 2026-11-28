/// Mirrors the notification catalogue to Android under plain channel keys.
///
/// FCM renders background pushes **itself** whenever the payload carries an
/// FCM `notification` block, and it resolves `android_channel_id` against
/// plain, un-hashed channel IDs. awesome's own channels are keyed by a hash
/// of their model — invisible to that lookup. Without this mirror, every
/// background push falls back to the system default channel: the system
/// sound, regardless of what the catalogue says.
///
/// Best-effort by design: a failure leaves background pushes on the fallback
/// channel rather than breaking the app, and the call is a no-op off Android.
library;

import 'dart:io';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:flutter/services.dart';

/// The Android audio stream a channel's sound plays on, which is also the
/// volume slider that controls it.
enum ChannelAudioUsage {
  /// `AudioAttributes.USAGE_ALARM` — the alarm volume.
  alarm(4),

  /// `AudioAttributes.USAGE_NOTIFICATION` — the notification volume.
  notification(5);

  const ChannelAudioUsage(this.android);

  /// The `AudioAttributes.USAGE_*` constant.
  final int android;

  /// The value for [android], or null for a usage no DPIP build creates.
  static ChannelAudioUsage? fromAndroid(int android) {
    for (final usage in values) {
      if (usage.android == android) return usage;
    }
    return null;
  }
}

/// A channel whose sound plays on another stream than the catalogue asks for.
///
/// Always an older build's doing — see [PlainChannels.usageMismatches].
class ChannelUsageMismatch {
  const ChannelUsageMismatch({
    required this.key,
    required this.name,
    required this.actual,
    required this.expected,
  });

  final String key;

  /// The name Android lists the channel under in the system settings.
  final String name;

  /// The stream it plays on.
  final ChannelAudioUsage actual;

  /// The stream [PlainChannels.usageOf] gives it.
  final ChannelAudioUsage expected;

  @override
  bool operator ==(Object other) =>
      other is ChannelUsageMismatch &&
      other.key == key &&
      other.name == name &&
      other.actual == actual &&
      other.expected == expected;

  @override
  int get hashCode => Object.hash(key, name, actual, expected);

  @override
  String toString() => '$key: ${actual.name} instead of ${expected.name}';
}

class PlainChannels {
  PlainChannels({MethodChannel? channel, bool? isAndroid})
    : _channel =
          channel ??
          const MethodChannel('com.exptech.dpip/plain_notification_channels'),
      _isAndroid = isAndroid ?? Platform.isAndroid;

  final MethodChannel _channel;
  final bool _isAndroid;

  /// The stream [channel] is meant to play on, or null when it plays nothing.
  ///
  /// The catalogue decides, through `defaultRingtoneType`: the alerts marked
  /// [DefaultRingtoneType.Alarm] are the ones that must be heard at the alarm
  /// volume, and everything else — reports, monitors, general weather — plays
  /// at the notification volume like any other app's notification, and goes
  /// quiet with it.
  static ChannelAudioUsage? usageOf(NotificationChannel channel) {
    if (!(channel.playSound ?? true)) return null;
    return channel.defaultRingtoneType == DefaultRingtoneType.Alarm
        ? ChannelAudioUsage.alarm
        : ChannelAudioUsage.notification;
  }

  /// Creates any plain-key channel from [channels], and any group from
  /// [groups], that does not exist yet.
  ///
  /// Existing channels are never rewritten: Android freezes created channels'
  /// behaviour, and the user may have tuned them in the OS UI. So whatever
  /// creates a plain id first decides how it sounds for good — which is why
  /// `NotificationService` calls this before awesome registers anything (see
  /// `PlainChannelsChannel.kt`).
  Future<void> ensure(
    List<NotificationChannel> channels, {
    List<NotificationChannelGroup> groups = const [],
  }) async {
    if (!_isAndroid || channels.isEmpty) return;
    try {
      await _channel.invokeMethod<int>('ensure', {
        'groups': [
          for (final group in groups)
            {'id': group.channelGroupKey, 'name': group.channelGroupName},
        ],
        'channels': [for (final channel in channels) _payload(channel)],
      });
    } on PlatformException catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'mirroring plain notification channels');
    } on MissingPluginException {
      // An engine that never registered the channel (tests, hot restarts
      // into a fresh messenger) simply skips the mirror.
    }
  }

  /// The channels of [catalogue] whose sound plays on another stream than
  /// [usageOf] asks for, by what Android says each one was created with.
  ///
  /// Android freezes a channel's audio attributes at creation, and deleting it
  /// and creating the same id again brings the old one back — so an install
  /// whose plain ids an older build created keeps that build's volumes through
  /// every update, and the app cannot change them. Only the user can, by
  /// clearing DPIP's storage or reinstalling it, both of which reset every
  /// channel. This is how the notification settings page knows to say so.
  ///
  /// Empty off Android, and whenever the answer cannot be read: a channel that
  /// cannot be checked is not reported as wrong.
  Future<List<ChannelUsageMismatch>> usageMismatches(
    List<NotificationChannel> catalogue,
  ) async {
    if (!_isAndroid || catalogue.isEmpty) return const [];
    try {
      final usages = await _channel.invokeMapMethod<String, int>('usages', {
        'ids': [for (final channel in catalogue) channel.channelKey],
      });
      final found = mismatchesAmong(catalogue, usages ?? const {});
      if (found.isNotEmpty) {
        Log.info(
          'notifications: ${found.length} channel(s) on another stream than '
          'the catalogue asks for — ${found.join(', ')}',
        );
      }
      return found;
    } on PlatformException catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'reading notification channel usages');
      return const [];
    } on MissingPluginException {
      return const [];
    }
  }

  /// The channels of [catalogue] whose entry in [actual] — `AudioAttributes`
  /// usages keyed by channel id — differs from [usageOf], in either direction.
  ///
  /// A channel missing from [actual] (it does not exist, or plays nothing), a
  /// silent catalogue channel, and a usage no DPIP build creates are all left
  /// out: none of them is a volume this app put in the wrong place.
  static List<ChannelUsageMismatch> mismatchesAmong(
    Iterable<NotificationChannel> catalogue,
    Map<String, int> actual,
  ) => [
    for (final channel in catalogue)
      if ((
            usageOf(channel),
            switch (actual[channel.channelKey]) {
              final int usage => ChannelAudioUsage.fromAndroid(usage),
              null => null,
            },
          )
          case (final expected?, final current?) when current != expected)
        ChannelUsageMismatch(
          key: channel.channelKey!,
          name: channel.channelName ?? channel.channelKey!,
          actual: current,
          expected: expected,
        ),
  ];

  /// Everything awesome's `setAndroidChannel` reads from the model, so the
  /// native side can build the same channel — plus the audio usage, which
  /// awesome does not take from it.
  static Map<String, Object?> _payload(NotificationChannel channel) {
    final usage = usageOf(channel);
    return {
      'id': channel.channelKey,
      'name': channel.channelName,
      if (channel.channelDescription != null)
        'description': channel.channelDescription,
      // awesome's importance enum is declared in Android's IMPORTANCE_* order,
      // so the index is the constant the native side expects.
      'importance': channel.importance?.index ?? 3,
      if (channel.channelGroupKey != null) 'group': channel.channelGroupKey,
      'playSound': usage != null,
      if (usage != null) 'usage': usage.android,
      if (usage != null && channel.soundSource != null)
        'sound': channel.soundSource!.replaceAll('resource://raw/', ''),
      'enableVibration': channel.enableVibration ?? true,
      if (channel.vibrationPattern != null)
        'vibrationPattern': channel.vibrationPattern,
      'enableLights': channel.enableLights ?? true,
      if (channel.ledColor != null) 'ledColor': channel.ledColor!.toARGB32(),
      'bypassDnd': channel.criticalAlerts ?? false,
      'showBadge': channel.channelShowBadge ?? false,
    };
  }
}
