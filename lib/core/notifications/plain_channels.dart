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

abstract final class PlainChannels {
  static const _channel = MethodChannel(
    'com.exptech.dpip/plain_notification_channels',
  );

  /// Creates any plain-key channel from [channels] that does not exist yet.
  ///
  /// Existing channels are never rewritten: Android freezes created channels'
  /// behaviour, and the user may have tuned them in the OS UI. Sound refreshes
  /// ride the catalogue-version gate instead, which deletes and re-registers.
  static Future<void> ensure(List<NotificationChannel> channels) async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<int>('ensure', {
        'channels': [for (final channel in channels) _payload(channel)],
      });
    } on PlatformException catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'mirroring plain notification channels');
    } on MissingPluginException {
      // An engine that never registered the channel (tests, hot restarts
      // into a fresh messenger) simply skips the mirror.
    }
  }

  static Map<String, Object?> _payload(NotificationChannel channel) => {
    'id': channel.channelKey,
    'name': channel.channelName,
    if (channel.channelDescription != null)
      'description': channel.channelDescription,
    // awesome's importance enum is declared in Android's IMPORTANCE_* order,
    // so the index is the constant the native side expects.
    'importance': channel.importance?.index ?? 3,
    if (channel.channelGroupKey != null) 'group': channel.channelGroupKey,
    if (channel.soundSource != null)
      'sound': channel.soundSource!.replaceAll('resource://raw/', ''),
    if (channel.vibrationPattern != null)
      'vibrationPattern': channel.vibrationPattern,
    if (channel.ledColor != null) 'ledColor': channel.ledColor!.toARGB32(),
  };
}
