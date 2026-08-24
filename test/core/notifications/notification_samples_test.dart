/// The test-notification catalogue's two silent failure modes.
///
/// Neither of these breaks anything loudly. A sample whose channel key was
/// renamed simply stops being reachable; a pushed channel added without a
/// sample simply never appears on the test page — the list still renders, the
/// other rows still work, and the missing one looks like a channel nobody
/// thought to include. Both are exactly the kind of thing this app cannot
/// afford to discover from a user saying "I never heard that one".
library;

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:dpip/core/notifications/notification_channels.dart';
import 'package:dpip/core/notifications/notification_samples.dart';
import 'package:flutter_test/flutter_test.dart';

/// The groups whose channels arrive from the backend, and therefore have a
/// server message worth reproducing. `group_mesh` is raised locally from the
/// LoRa link and `background` carries no group at all.
const _pushedGroups = {
  'group_eew',
  'group_eq',
  'group_info',
  'group_tsunami',
  'group_other',
};

NotificationChannel _channel(String key) => NotificationChannels.channels
    .firstWhere((channel) => channel.channelKey == key);

void main() {
  group('sample coverage', () {
    test('every pushed channel has a sample', () {
      final missing = [
        for (final channel in NotificationChannels.channels)
          if (_pushedGroups.contains(channel.channelGroupKey) &&
              NotificationSamples.of(channel.channelKey!) == null)
            channel.channelKey,
      ];
      expect(
        missing,
        isEmpty,
        reason:
            'these channels would silently vanish from the test page: $missing',
      );
    });

    test('every sample belongs to a real channel', () {
      final keys = {
        for (final channel in NotificationChannels.channels) channel.channelKey,
      };
      final orphans = NotificationSamples.byChannel.keys
          .where((key) => !keys.contains(key))
          .toList();
      expect(
        orphans,
        isEmpty,
        reason: 'samples that can never be fired: $orphans',
      );
    });

    test('the locally-raised and service channels are left out', () {
      // Asserted rather than assumed: if mesh ever gains a sample, the page's
      // "testable means pushed" rule has quietly changed and its doc is wrong.
      expect(NotificationSamples.of('mesh_message'), isNull);
      expect(NotificationSamples.of('mesh_node'), isNull);
      expect(NotificationSamples.of('background'), isNull);
    });

    test('no sample is blank', () {
      for (final entry in NotificationSamples.byChannel.entries) {
        expect(entry.value.title, isNotEmpty, reason: entry.key);
        expect(entry.value.body, isNotEmpty, reason: entry.key);
      }
    });
  });

  group('behaviourOf', () {
    test('a critical alert outranks everything else', () {
      // Max importance and a sound too — the point is that `criticalAlerts`
      // decides, because it is the only one of the three that pierces the
      // silent switch.
      expect(
        NotificationChannels.behaviourOf(_channel('eew_alert-important-v2')),
        NotificationBehaviour.overrides,
      );
    });

    test('no sound reads as silent whatever the importance says', () {
      expect(
        NotificationChannels.behaviourOf(_channel('eew_alert-silent-v2')),
        NotificationBehaviour.silent,
      );
      expect(
        NotificationChannels.behaviourOf(_channel('report-silence-v2')),
        NotificationBehaviour.silent,
      );
    });

    test('High and above earns a banner, Default does not', () {
      expect(
        NotificationChannels.behaviourOf(_channel('int_report-general-v2')),
        NotificationBehaviour.alerts,
        reason: 'High importance shows a heads-up banner',
      );
      expect(
        NotificationChannels.behaviourOf(_channel('report-general-v2')),
        NotificationBehaviour.sounds,
        reason: 'Default importance is audible but stays in the shade',
      );
    });

    test('every pushed channel resolves to some behaviour', () {
      for (final channel in NotificationChannels.channels) {
        expect(
          () => NotificationChannels.behaviourOf(channel),
          returnsNormally,
          reason: channel.channelKey,
        );
      }
    });
  });
}
