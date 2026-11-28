/// The plain-channel mirror is what FCM's background renderer finds, and on a
/// fresh install it is what creates every plain id — so what it sends is what
/// each alert sounds like for the life of the install. Android freezes a
/// channel at creation; nothing sent later can correct it.
///
/// What is pinned here is the Dart half: off Android it never reaches the
/// platform, and on Android every catalogue channel goes out on the stream the
/// catalogue asks for. The native half — that a channel is created with what it
/// is sent — is `PlainChannelsChannelTest.kt`.
library;

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:dpip/core/notifications/notification_channels.dart';
import 'package:dpip/core/notifications/plain_channels.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('test/plain_notification_channels');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  /// The arguments of every call [PlainChannels] makes, by method name.
  Map<String, Object?> record() {
    final calls = <String, Object?>{};
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls[call.method] = call.arguments;
      return 0;
    });
    return calls;
  }

  /// What [PlainChannels.ensure] sends for each channel of the catalogue.
  Future<Map<String, Map<Object?, Object?>>> sentForCatalogue() async {
    final calls = record();
    await PlainChannels(channel: channel, isAndroid: true).ensure(
      NotificationChannels.channels,
      groups: NotificationChannels.groups,
    );
    final arguments = calls['ensure']! as Map<Object?, Object?>;
    return {
      for (final entry in arguments['channels']! as List<Object?>)
        (entry! as Map<Object?, Object?>)['id']! as String:
            entry as Map<Object?, Object?>,
    };
  }

  group('off Android', () {
    test('never reaches the platform channel', () async {
      final calls = record();

      await PlainChannels(
        channel: channel,
        isAndroid: false,
      ).ensure(NotificationChannels.channels);

      expect(calls, isEmpty);
    });

    test('completes with no handler registered at all', () async {
      await expectLater(
        PlainChannels(isAndroid: false).ensure(NotificationChannels.channels),
        completes,
      );
    });
  });

  test('an empty catalogue is a no-op', () async {
    final calls = record();

    await PlainChannels(channel: channel, isAndroid: true).ensure(const []);

    expect(calls, isEmpty);
  });

  test('a native failure is logged, not thrown', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      throw PlatformException(code: 'boom');
    });

    await expectLater(
      PlainChannels(
        channel: channel,
        isAndroid: true,
      ).ensure(NotificationChannels.channels),
      completes,
    );
  });

  group('the stream each channel is created on', () {
    test(
      'the three general channels from #660 use the notification volume',
      () async {
        final sent = await sentForCatalogue();

        for (final key in [
          'int_report-general-v2',
          'eq-v2',
          'report-general-v2',
        ]) {
          expect(sent[key]!['usage'], 5, reason: key); // USAGE_NOTIFICATION
          expect(sent[key]!['playSound'], isTrue, reason: key);
        }
      },
    );

    test('exactly the channels marked Alarm use the alarm volume', () async {
      final sent = await sentForCatalogue();

      for (final channel in NotificationChannels.channels) {
        final key = channel.channelKey!;
        final sound = channel.playSound ?? true;
        final alarm = channel.defaultRingtoneType == DefaultRingtoneType.Alarm;
        expect(
          sent[key]!['usage'],
          !sound ? isNull : (alarm ? 4 : 5),
          reason: key,
        );
      }
      // Not vacuous: the catalogue has both kinds.
      expect(sent.values.where((entry) => entry['usage'] == 4), isNotEmpty);
      expect(sent.values.where((entry) => entry['usage'] == 5), isNotEmpty);
    });

    test('a silent channel is sent without any sound', () async {
      final sent = await sentForCatalogue();

      expect(sent['eew_alert-silent-v2']!['playSound'], isFalse);
      expect(sent['eew_alert-silent-v2']!.containsKey('sound'), isFalse);
      expect(sent['eew_alert-silent-v2']!.containsKey('usage'), isFalse);
    });

    test('usageOf follows defaultRingtoneType and playSound', () {
      NotificationChannel make({
        bool? playSound,
        DefaultRingtoneType? ringtone,
      }) => NotificationChannel(
        channelKey: 'k',
        channelName: 'n',
        channelDescription: 'd',
        playSound: playSound,
        defaultRingtoneType: ringtone,
      );

      expect(
        PlainChannels.usageOf(make(ringtone: DefaultRingtoneType.Alarm)),
        ChannelAudioUsage.alarm,
      );
      expect(PlainChannels.usageOf(make()), ChannelAudioUsage.notification);
      expect(
        PlainChannels.usageOf(make(ringtone: DefaultRingtoneType.Ringtone)),
        ChannelAudioUsage.notification,
      );
      expect(
        PlainChannels.usageOf(
          make(playSound: false, ringtone: DefaultRingtoneType.Alarm),
        ),
        isNull,
      );
    });
  });

  group('the rest of the channel, as awesome would build it', () {
    test(
      'every group is sent, so a fresh install can file its channels',
      () async {
        final calls = record();
        await PlainChannels(channel: channel, isAndroid: true).ensure(
          NotificationChannels.channels,
          groups: NotificationChannels.groups,
        );

        final groups =
            (calls['ensure']! as Map<Object?, Object?>)['groups']!
                as List<Object?>;
        expect(
          [for (final group in groups) (group! as Map<Object?, Object?>)['id']],
          [
            for (final group in NotificationChannels.groups)
              group.channelGroupKey,
          ],
        );
      },
    );

    test('sound file, vibration, lights, badge and DND are carried', () async {
      final sent = await sentForCatalogue();
      final channel = NotificationChannels.channels.firstWhere(
        (channel) => channel.channelKey == 'eew_alert-important-v2',
      );
      final entry = sent['eew_alert-important-v2']!;

      expect(entry['sound'], 'eew_alert');
      expect(entry['vibrationPattern'], channel.vibrationPattern);
      expect(entry['enableVibration'], isTrue);
      expect(entry['enableLights'], isTrue);
      expect(entry['ledColor'], channel.ledColor!.toARGB32());
      expect(entry['bypassDnd'], isTrue);
      expect(entry['showBadge'], isFalse);
      expect(entry['group'], 'group_eew');
      expect(entry['importance'], NotificationImportance.Max.index);
    });
  });

  group('channels an older build left on the wrong stream', () {
    /// Every sound channel of the catalogue on the stream it asks for.
    Map<String, int> matching() => {
      for (final channel in NotificationChannels.channels)
        if (PlainChannels.usageOf(channel) case final usage?)
          channel.channelKey!: usage.android,
    };

    test('a fresh install has none', () {
      expect(
        PlainChannels.mismatchesAmong(
          NotificationChannels.channels,
          matching(),
        ),
        isEmpty,
      );
    });

    test('the general channels an old mirror put on the alarm stream', () {
      final actual = matching()
        ..['int_report-general-v2'] = 4
        ..['eq-v2'] = 4
        ..['report-general-v2'] = 4;

      final found = PlainChannels.mismatchesAmong(
        NotificationChannels.channels,
        actual,
      );

      expect(
        [for (final m in found) m.key],
        ['int_report-general-v2', 'eq-v2', 'report-general-v2'],
      );
      for (final m in found) {
        expect(m.actual, ChannelAudioUsage.alarm);
        expect(m.expected, ChannelAudioUsage.notification);
      }
      // Named the way Android lists it, which is where the user will look.
      expect(found.first.name, '震度速報(一般)');
    });

    test('and the other way: a major alert on the notification stream', () {
      final actual = matching()..['eew_alert-important-v2'] = 5;

      expect(
        PlainChannels.mismatchesAmong(NotificationChannels.channels, actual),
        [
          const ChannelUsageMismatch(
            key: 'eew_alert-important-v2',
            name: '緊急地震速報(重大)',
            actual: ChannelAudioUsage.notification,
            expected: ChannelAudioUsage.alarm,
          ),
        ],
      );
    });

    test('nothing that cannot be judged is reported', () {
      final actual = matching()
        // Missing: the channel does not exist, or plays nothing.
        ..remove('eq-v2')
        // A silent catalogue channel has no stream to be wrong about.
        ..['eew_alert-silent-v2'] = 4
        // A usage no DPIP build has ever created.
        ..['report-general-v2'] = 6;

      expect(
        PlainChannels.mismatchesAmong(NotificationChannels.channels, actual),
        isEmpty,
      );
    });

    test('is read from the native side on Android', () async {
      Object? asked;
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method != 'usages') return null;
        asked = call.arguments;
        return matching()..['eq-v2'] = 4;
      });

      final found = await PlainChannels(
        channel: channel,
        isAndroid: true,
      ).usageMismatches(NotificationChannels.channels);

      expect([for (final m in found) m.key], ['eq-v2']);
      expect((asked! as Map<Object?, Object?>)['ids'], [
        for (final channel in NotificationChannels.channels) channel.channelKey,
      ]);
    });

    test('is empty, without asking, off Android', () async {
      final calls = record();

      final found = await PlainChannels(
        channel: channel,
        isAndroid: false,
      ).usageMismatches(NotificationChannels.channels);

      expect(found, isEmpty);
      expect(calls, isEmpty);
    });

    test('is empty when the native side fails', () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        throw PlatformException(code: 'boom');
      });

      final found = await PlainChannels(
        channel: channel,
        isAndroid: true,
      ).usageMismatches(NotificationChannels.channels);

      expect(found, isEmpty);
    });
  });
}
