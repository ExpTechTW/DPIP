/// The plain-channel mirror exists only so Android's FCM-rendered background
/// pushes resolve a real channel instead of falling back to the noisy system
/// default — iOS has no such lookup, so [PlainChannels.ensure] must be an
/// unconditional no-op there.
///
/// The whole point of the `Platform.isAndroid` guard is that calling this on
/// every app start, on every platform, must never be able to throw, hang, or
/// touch a platform channel that does not exist off Android. That contract —
/// not the native mirroring itself, which needs a real Android host to
/// observe — is what this test can pin from a Dart VM test host.
///
/// Coverage gap, stated rather than worked around: `Platform.isAndroid` is a
/// `dart:io` static with no override seam anywhere in this codebase (see
/// `test/core/permissions/permission_health_test.dart`'s injectable-getter
/// pattern for the alternative this class does not offer, being a static-only
/// `abstract final class`). So the method-channel call, the `_payload`
/// mapping, and both catch branches inside [PlainChannels.ensure] cannot be
/// exercised from a test that runs on macOS/Linux, and are not covered here.
library;

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:dpip/core/notifications/plain_channels.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.exptech.dpip/plain_notification_channels');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  NotificationChannel notificationChannel({
    String key = 'alerts',
    String name = 'Alerts',
  }) => NotificationChannel(
    channelKey: key,
    channelName: name,
    channelDescription: null,
  );

  test('never reaches the platform channel off Android', () async {
    var invoked = false;
    messenger.setMockMethodCallHandler(channel, (call) async {
      invoked = true;
      return null;
    });

    await PlainChannels.ensure([notificationChannel()]);

    expect(invoked, isFalse);
  });

  test('an empty catalogue is also a no-op', () async {
    var invoked = false;
    messenger.setMockMethodCallHandler(channel, (call) async {
      invoked = true;
      return null;
    });

    await PlainChannels.ensure(const []);

    expect(invoked, isFalse);
  });

  test('completes without throwing even with no handler registered at all', () async {
    // No setMockMethodCallHandler call in this test — proves ensure() does not
    // depend on one being present, which it would if it reached the channel.
    await expectLater(
      PlainChannels.ensure([notificationChannel(key: 'other')]),
      completes,
    );
  });
}
