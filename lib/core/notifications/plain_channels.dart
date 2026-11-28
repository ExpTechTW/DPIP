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
