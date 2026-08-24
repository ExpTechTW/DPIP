/// The push payload → notification content contract.
///
/// Two shapes arrive over FCM and both must land on the right channel: the
/// flat keys the architecture describes, and the nested `data['content']`
/// JSON string the producer still sends. Getting this wrong does not fail
/// loudly — every message silently collapses onto the announcement fallback,
/// which is exactly how a wrong-sound report presents.
library;

import 'package:dpip/core/notifications/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';

RemoteMessage _message(
  Map<String, dynamic> data, {
  RemoteNotification? notification,
}) => RemoteMessage(data: data, notification: notification);

void main() {
  test('the flat contract maps every field', () {
    final content = contentFromMessage(
      _message({
        'channel': 'eew_alert-important-v2',
        'title': '地震速報',
        'body': '花蓮縣近海',
        'id': '42',
      }),
    );

    expect(content?.channelKey, 'eew_alert-important-v2');
    expect(content?.title, '地震速報');
    expect(content?.body, '花蓮縣近海');
    expect(content?.id, 42);
  });

  test('the legacy nested payload lands on its own channel', () {
    // What the producer still sends: visible text in the FCM notification
    // block, structured fields inside data['content'] as one JSON string —
    // note channelKey spelled that way, and id as a number.
    final content = contentFromMessage(
      _message(
        {
          'content':
              '{"id": ${0xF12345678}, "channelKey": "eq-v2", '
              '"body": "高雄市 能見度 ＜1 km", "notificationLayout": "BigText"}',
        },
        notification: const RemoteNotification(
          title: '測試通知',
          body: '高雄市(國一N361K) 能見度 ＜1 km，請注意安全。',
        ),
      ),
    );

    expect(content?.channelKey, 'eq-v2', reason: 'no announcement fallback');
    // The notification block's text wins over the nested body: the nested copy
    // carries `<br>` where the producer meant a newline.
    expect(content?.body, '高雄市(國一N361K) 能見度 ＜1 km，請注意安全。');
    expect(content?.title, '測試通知');
    expect(content?.id, 0xF12345678);
  });

  test('flat keys win where both shapes exist', () {
    final content = contentFromMessage(
      _message({
        'channel': 'report-general-v2',
        'id': '7',
        'content': '{"channelKey": "announcement-general-v2", "id": 9}',
      }, notification: const RemoteNotification(title: '報告', body: '內文')),
    );

    expect(content?.channelKey, 'report-general-v2');
    expect(content?.payload?['id'], '7');
  });

  test('malformed nested JSON degrades to the fallback, never throws', () {
    final content = contentFromMessage(
      _message({
        'content': '{not json',
      }, notification: const RemoteNotification(title: '公告', body: '內容')),
    );

    expect(content?.channelKey, 'announcement-general-v2');
    expect(content?.title, '公告');
  });

  test('a message with nothing to show produces no content', () {
    // No flat keys, no nested payload, no notification block — there is
    // nothing to render, so asking for a channel would be meaningless.
    expect(contentFromMessage(_message({})), isNull);
  });

  test('the tap payload carries the resolved channel and id', () {
    final content = contentFromMessage(
      _message({
        'content': '{"channelKey": "tsunami-important-v2", "id": 5}',
      }, notification: const RemoteNotification(title: '海嘯警報', body: '沿海請注意')),
    );

    expect(content?.payload?['channel'], 'tsunami-important-v2');
    expect(content?.payload?['id'], '5');
  });
}
