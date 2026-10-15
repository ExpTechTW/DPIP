/// The Android manifest's FCM default channel must name a channel this app
/// actually creates.
///
/// The value is a bare string in XML, read by Google Play services when it
/// draws a push whose own channel id is unknown. Nothing compiles it against
/// the catalogue, so a rename in `notification_channels.dart` would leave it
/// pointing at a channel that no longer exists — and FCM then falls back to
/// its own "Miscellaneous" channel, which is the exact outcome the entry is
/// there to prevent. Silent on a device; loud here.
library;

import 'dart:io';

import 'package:dpip/core/notifications/notification_channels.dart';
import 'package:flutter_test/flutter_test.dart';

const _manifest = 'android/app/src/main/AndroidManifest.xml';
const _key = 'com.google.firebase.messaging.default_notification_channel_id';

void main() {
  String? defaultChannel() {
    final manifest = File(_manifest).readAsStringSync();
    final match = RegExp(
      r'<meta-data\s+android:name="' +
          RegExp.escape(_key) +
          r'"\s+android:value="([^"]+)"\s*/>',
    ).firstMatch(manifest);
    return match?.group(1);
  }

  test('the manifest declares an FCM default notification channel', () {
    expect(defaultChannel(), isNotNull, reason: '$_key is missing');
  });

  test('the default is the general announcement channel', () {
    expect(defaultChannel(), 'announcement-general-v2');
  });

  test('the default is a channel the catalogue registers', () {
    final keys = [
      for (final channel in NotificationChannels.channels) channel.channelKey,
    ];
    expect(keys, contains(defaultChannel()));
  });
}
