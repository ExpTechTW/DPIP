/// Tests Android urgent notification channel status and settings integration.
library;

import 'package:dpip/core/notifications/notification_channels.dart';
import 'package:dpip/core/notifications/urgent_notification_settings.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('test.urgent_notification_settings');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('urgent catalogue contains only the six explicit major channels', () {
    expect(NotificationChannels.urgentChannelKeys, {
      'eew_alert-important-v2',
      'eew-important-v2',
      'thunderstorm-important-v2',
      'weather_major-important-v2',
      'evacuation_major-important-v2',
      'tsunami-important-v2',
    });
    expect(
      NotificationChannels.channels
          .map((channel) => channel.channelKey)
          .where(NotificationChannels.urgentChannelKeys.contains),
      containsAll(NotificationChannels.urgentChannelKeys),
    );
  });

  test('parses bypassing, DND-following, and missing channel states', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'urgentNotificationChannelStatus');
      final ids = (call.arguments as Map<Object?, Object?>)['channelIds']!;
      expect(ids, NotificationChannels.urgentChannelKeys.toList());
      return {
        'eew_alert-important-v2': {
          'id': 'native-eew-alert-channel',
          'name': 'Major EEW',
          'bypassesDnd': true,
        },
        'eew-important-v2': {
          'id': 'eew-important-v2',
          'name': 'Major earthquake alert',
          'bypassesDnd': false,
        },
      };
    });

    final status = await UrgentNotificationSettings(channel).status();

    expect(status.allBypass, isFalse);
    expect(
      status.channels.first.state,
      UrgentNotificationChannelState.bypasses,
    );
    expect(status.channels.first.name, 'Major EEW');
    expect(status.channels.first.channelId, 'native-eew-alert-channel');
    expect(
      status.channels[1].state,
      UrgentNotificationChannelState.doesNotBypass,
    );
    expect(
      status.channels
          .skip(2)
          .every(
            (channel) =>
                channel.state == UrgentNotificationChannelState.missing,
          ),
      isTrue,
    );
  });

  test('platform failures become unavailable states', () async {
    messenger.setMockMethodCallHandler(channel, (_) async {
      throw PlatformException(code: 'unavailable');
    });

    final status = await UrgentNotificationSettings(channel).status();

    expect(status.allBypass, isFalse);
    expect(
      status.channels.every(
        (channel) =>
            channel.state == UrgentNotificationChannelState.unavailable,
      ),
      isTrue,
    );
  });

  test(
    'opens settings using the channel id returned by the platform',
    () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'urgentNotificationChannelStatus') {
          return {
            'eew_alert-important-v2': {
              'id': 'native-eew-alert-channel',
              'name': 'Major EEW',
              'bypassesDnd': true,
            },
          };
        }
        expect(call.method, 'openNotificationChannelSettings');
        expect(call.arguments, {'channelId': 'native-eew-alert-channel'});
        return 'channel';
      });

      final settings = UrgentNotificationSettings(channel);
      final status = await settings.status();
      final channelId = status.channels.first.channelId;
      expect(channelId, isNotNull);
      expect(await settings.openChannelSettings(channelId!), 'channel');
    },
  );
}
