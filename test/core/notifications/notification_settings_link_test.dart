/// The iOS Settings → DPIP → Notifications link: asking for it, and carrying
/// its tap into the app exactly once.
///
/// The native half (`NotificationSettingsLinkPlugin.swift`) holds the request
/// as a flag that `take` reads and clears; these tests stand in for it, so
/// what they pin is the Dart contract — a tap that arrived before Dart was
/// listening is replayed, a nudge with nothing pending opens nothing, and the
/// whole thing is inert off iOS.
library;

import 'package:dpip/core/notifications/notification_settings_link.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('test/notification_settings_link');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  var pending = false;
  var provided = true;
  final calls = <String>[];

  setUp(() {
    pending = false;
    provided = true;
    calls.clear();
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method);
      switch (call.method) {
        case 'take':
          final was = pending;
          pending = false;
          return was;
        case 'provide':
          return provided;
      }
      return null;
    });
  });
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  NotificationSettingsLink link({bool isIOS = true}) =>
      NotificationSettingsLink(channel: channel, isIOS: isIOS);

  /// What the native side does when iOS calls `openSettingsFor`.
  Future<void> nudge() => messenger.handlePlatformMessage(
    channel.name,
    const StandardMethodCodec().encodeMethodCall(const MethodCall('open')),
    (_) {},
  );

  test(
    'a tap that launched the app is replayed when listening starts',
    () async {
      pending = true;
      var opened = 0;

      await link().listen(() => opened++);

      expect(opened, 1);
      expect(pending, isFalse);
    },
  );

  test('a tap while running opens the page once', () async {
    var opened = 0;
    final subject = link();
    await subject.listen(() => opened++);
    expect(opened, 0);

    pending = true;
    await nudge();
    expect(opened, 1);

    // A nudge with nothing pending — the flag already taken — opens nothing.
    await nudge();
    expect(opened, 1);
    subject.stop();
  });

  test('stop ends delivery', () async {
    var opened = 0;
    final subject = link();
    await subject.listen(() => opened++);
    subject.stop();

    pending = true;
    await nudge();

    expect(opened, 0);
    expect(pending, isTrue, reason: 'left for whoever listens next');
  });

  test('provide reports what the native side answered', () async {
    expect(await link().provide(), isTrue);
    provided = false;
    expect(await link().provide(), isFalse);
  });

  test('a native failure is swallowed', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      throw PlatformException(code: 'boom');
    });

    expect(await link().provide(), isFalse);
    var opened = 0;
    await link().listen(() => opened++);
    expect(opened, 0);
  });

  test('no native side at all is skipped', () async {
    messenger.setMockMethodCallHandler(channel, null);

    expect(await link().provide(), isFalse);
    await expectLater(link().listen(() {}), completes);
  });

  test('never reaches the platform off iOS', () async {
    pending = true;
    var opened = 0;
    final subject = link(isIOS: false);

    expect(await subject.provide(), isFalse);
    await subject.listen(() => opened++);
    subject.stop();

    expect(opened, 0);
    expect(calls, isEmpty);
  });
}
