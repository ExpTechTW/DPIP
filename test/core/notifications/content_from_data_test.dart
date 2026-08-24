/// The push payload → notification content contract.
///
/// Two shapes arrive over FCM and both must land on the right channel: the
/// flat keys the architecture describes, and the nested `data['content']`
/// JSON string the producer still sends. Getting this wrong does not fail
/// loudly — every message silently collapses onto the announcement fallback,
/// which is exactly how a wrong-sound report presents.
library;

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:dpip/core/notifications/notification_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// The shape production hands over: a bare data map, plus the text an FCM
/// `notification` block would have carried.
NotificationContent? _content(
  Map<String, dynamic> data, {
  String? title,
  String? body,
}) => contentFromData(data, fallbackTitle: title, fallbackBody: body);

void main() {
  test('the flat contract maps every field', () {
    final content = _content({
      'channel': 'eew_alert-important-v2',
      'title': '地震速報',
      'body': '花蓮縣近海',
      'id': '42',
    });

    expect(content?.channelKey, 'eew_alert-important-v2');
    expect(content?.title, '地震速報');
    expect(content?.body, '花蓮縣近海');
    expect(content?.id, 42);
  });

  test('the legacy nested payload lands on its own channel', () {
    // What the producer still sends: visible text in the FCM notification
    // block, structured fields inside data['content'] as one JSON string —
    // note channelKey spelled that way, and id as a number.
    final content = _content(
      {
        'content':
            '{"id": 305419896, "channelKey": "eq-v2", '
            '"body": "高雄市 能見度 ＜1 km", "notificationLayout": "BigText"}',
      },
      title: '測試通知',
      body: '高雄市(國一N361K) 能見度 ＜1 km，請注意安全。',
    );

    expect(content?.channelKey, 'eq-v2', reason: 'no announcement fallback');
    // The notification block's text wins over the nested body: the nested copy
    // carries `<br>` where the producer meant a newline.
    expect(content?.body, '高雄市(國一N361K) 能見度 ＜1 km，請注意安全。');
    expect(content?.title, '測試通知');
    expect(content?.id, 305419896);
  });

  test('an oversized id is dropped instead of killing the notification', () {
    // The producer's id is `parseInt(md5.slice(0, 10), 16)` — up to 40 bits,
    // routinely wider than the signed 32-bit range awesome validates. Before
    // the clamp this threw out of createNotification and the foreground push
    // simply never rendered.
    final content = _content(
      {
        'content':
            '{"id": ${0xF12345678}, "channelKey": "eq-v2", "body": "測試"}',
      },
      title: '地震速報',
      body: '花蓮縣近海',
    );

    expect(content?.id, 0, reason: 'out of 32-bit range → treated as absent');
    expect(
      content?.channelKey,
      'eq-v2',
      reason: 'the rest of the payload still applies',
    );
    expect(content?.title, '地震速報');
  });

  test('flat keys win where both shapes exist', () {
    final content = _content(
      {
        'channel': 'report-general-v2',
        'id': '7',
        'content': '{"channelKey": "announcement-general-v2", "id": 9}',
      },
      title: '報告',
      body: '內文',
    );

    expect(content?.channelKey, 'report-general-v2');
    expect(content?.payload?['id'], '7');
  });

  test('malformed nested JSON degrades to the fallback, never throws', () {
    final content = _content({'content': '{not json'}, title: '公告', body: '內容');

    expect(content?.channelKey, 'announcement-general-v2');
    expect(content?.title, '公告');
  });

  test('a message with nothing to show produces no content', () {
    // No flat keys, no nested payload, no notification block — there is
    // nothing to render, so asking for a channel would be meaningless.
    expect(_content(const {}), isNull);
  });

  test('the tap payload carries the resolved channel and id', () {
    final content = _content(
      {'content': '{"channelKey": "tsunami-important-v2", "id": 5}'},
      title: '海嘯警報',
      body: '沿海請注意',
    );

    expect(content?.payload?['channel'], 'tsunami-important-v2');
    expect(content?.payload?['id'], '5');
  });
}
