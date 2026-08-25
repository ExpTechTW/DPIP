/// The test notification must never be mistakable for a real one.
///
/// Every sample reproduces an actual CWA alert word for word — "花蓮縣壽豐鄉發生
/// 地震　強烈搖晃警戒" is what the real 緊急地震速報 says. Strip the markers and
/// what lands on a lock screen is an earthquake warning nobody issued, ready to
/// be photographed and forwarded. That is not a cosmetic regression, and it is
/// exactly the kind that survives review because the screen still looks right.
library;

import 'dart:io';

import 'package:dpip/core/notifications/notification_channels.dart';
import 'package:dpip/core/notifications/notification_samples.dart';
import 'package:dpip/core/notifications/notification_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every sample is marked as a test, in both the title and the body', () {
    for (final key in NotificationSamples.byChannel.keys) {
      final content = testNotificationContent(key);
      expect(content, isNotNull, reason: key);
      expect(
        content!.title,
        startsWith(testTitlePrefix),
        reason: '$key: an unmarked title is a real alert',
      );
      expect(
        content.body,
        startsWith(testBodyMarker),
        reason: '$key: an unmarked body is a real alert',
      );
    }
  });

  test('the sample survives the markers intact', () {
    final sample = NotificationSamples.of('eew_alert-important-v2')!;
    final content = testNotificationContent('eew_alert-important-v2')!;
    expect(content.title, '$testTitlePrefix${sample.title}');
    expect(content.body, endsWith(sample.body));
    // The sample's own newlines are deliberately untouched — a real push
    // renders through the same path, so converting them would make the test
    // read better than the alert it reproduces.
    expect(content.body, contains('\n〈預估強烈搖晃地區〉'));
  });

  test('the marker separator follows the platform that renders it', () {
    final body = testNotificationContent('announcement-general-v2')!.body!;
    // Android puts the body through `android.text.Html`, where a newline
    // collapses to a space; iOS takes the text literally.
    expect(
      body,
      startsWith('$testBodyMarker${Platform.isIOS ? '\n' : '<br>'} '),
    );
  });

  test('a channel with nothing to reproduce builds no notification', () {
    expect(testNotificationContent('mesh_message'), isNull);
    expect(testNotificationContent('background'), isNull);
    expect(testNotificationContent('not-a-channel'), isNull);
  });

  test('each channel gets its own id, clear of the backend range', () {
    final ids = <int>[];
    for (final key in NotificationSamples.byChannel.keys) {
      final id = testNotificationContent(key)!.id!;
      // Server alerts carry the backend's positive ids; a test must never
      // overwrite a real alert sitting in the shade.
      expect(id, lessThan(0), reason: key);
      ids.add(id);
    }
    expect(
      ids.toSet(),
      hasLength(ids.length),
      reason: 'a shared id would let one test replace another mid-comparison',
    );
  });

  test('the notification lands on the channel it is testing', () {
    for (final channel in NotificationChannels.channels) {
      final key = channel.channelKey!;
      final content = testNotificationContent(key);
      if (content == null) continue;
      expect(content.channelKey, key);
    }
  });
}
