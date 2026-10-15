/// Retired channel ids, and the sweep that deletes them on Android.
///
/// Two ways this goes wrong, both silent on a device: a live alert channel
/// treated as retired — deleted on every launch, taking the user's own
/// settings for it — or a retired one missed, left in system settings as a
/// dead duplicate toggle. The list is pinned against the catalogue for the
/// first and spelled out in full for the second.
library;

import 'package:dpip/core/notifications/notification_channels.dart';
import 'package:dpip/core/notifications/retired_channels.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('test/retired_channels');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  final live = {
    for (final channel in NotificationChannels.channels) channel.channelKey!,
  };

  test('no retired key is a channel the catalogue still registers', () {
    expect(RetiredChannels.keys.intersection(live), isEmpty);
  });

  test('every alert channel ever renamed is retired', () {
    // Each live `-v2` alert key, minus the suffix, is a channel a shipped
    // build created under that name. `thunderstorm-important` is the one
    // exception: it was introduced already carrying the suffix.
    final previous = {
      for (final key in live)
        if (key.endsWith('-v2')) key.substring(0, key.length - 3),
    }..remove('thunderstorm-important');

    expect(RetiredChannels.keys, containsAll(previous));
    expect(RetiredChannels.keys, containsAll(['eew_alert-important', 'eq']));
  });

  test('the first catalogue and the service channels are retired too', () {
    expect(
      RetiredChannels.keys,
      containsAll([
        'eew_alert',
        'eew',
        'eew_silence',
        'int_report_silence',
        'tsunami_warn',
        'tsunami_pacific_silent',
        'announcement',
        'my_foreground',
        'dpip_background_location',
      ]),
    );
  });

  group('retiredAmong', () {
    test('picks the retired ids and leaves every live one', () {
      final existing = [...live, 'eew_alert-important', 'eq', 'miscellaneous'];

      expect(RetiredChannels.retiredAmong(existing), [
        'eew_alert-important',
        'eq',
      ]);
    });

    test('catches the hashed spelling awesome also creates', () {
      const digest = '0123456789abcdef0123456789abcdef';

      expect(
        RetiredChannels.retiredAmong([
          'eew_alert-important_$digest',
          'eew_alert-important-v2_$digest',
          'not-ours_$digest',
          'eq_tooshort',
        ]),
        ['eew_alert-important_$digest'],
      );
    });

    test('never names a live channel, whatever the list says', () {
      expect(RetiredChannels.retiredAmong(live), isEmpty);
    });
  });

  group('sweep', () {
    test('lists, then deletes only the retired ids present', () async {
      final calls = <MethodCall>[];
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        return switch (call.method) {
          'list' => ['eew_alert-important-v2', 'eew_alert-important', 'eq'],
          'delete' => (call.arguments as Map)['ids'].length,
          _ => null,
        };
      });

      final deleted = await RetiredChannels(
        channel: channel,
        isAndroid: true,
      ).sweep();

      expect(deleted, 2);
      expect(calls.map((c) => c.method), ['list', 'delete']);
      expect((calls.last.arguments as Map)['ids'], [
        'eew_alert-important',
        'eq',
      ]);
    });

    test('a swept device costs one call and deletes nothing', () async {
      final calls = <String>[];
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call.method);
        return call.method == 'list' ? live.toList() : 0;
      });

      final deleted = await RetiredChannels(
        channel: channel,
        isAndroid: true,
      ).sweep();

      expect(deleted, 0);
      expect(calls, ['list']);
    });

    test('never reaches the platform off Android', () async {
      var invoked = false;
      messenger.setMockMethodCallHandler(channel, (call) async {
        invoked = true;
        return null;
      });

      expect(
        await RetiredChannels(channel: channel, isAndroid: false).sweep(),
        0,
      );
      expect(invoked, isFalse);
    });

    test('a platform failure is swallowed, not thrown into init', () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        throw PlatformException(code: 'boom');
      });

      expect(
        await RetiredChannels(channel: channel, isAndroid: true).sweep(),
        0,
      );
    });

    test('a missing native handler is skipped', () async {
      expect(
        await RetiredChannels(channel: channel, isAndroid: true).sweep(),
        0,
      );
    });
  });
}
