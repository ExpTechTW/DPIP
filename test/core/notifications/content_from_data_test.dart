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

  test('an oversized id keeps its low 31 bits instead of being dropped', () {
    // The producer's id is `parseInt(md5.slice(0, 10), 16)` — up to 40 bits,
    // routinely wider than the signed 32-bit range awesome validates. Treating
    // that as "no id" gave every such push the same fallback slot, so three
    // different alerts arriving together left only the last one in the shade.
    final content = _content(
      {
        'content':
            '{"id": ${0xF12345678}, "channelKey": "eq-v2", "body": "測試"}',
      },
      title: '地震速報',
      body: '花蓮縣近海',
    );

    expect(content?.id, 0xF12345678 & 0x7FFFFFFF);
    expect(
      content?.channelKey,
      'eq-v2',
      reason: 'the rest of the payload still applies',
    );
    expect(content?.title, '地震速報');
    // The tap still carries what the producer sent, not the folded id.
    expect(content?.payload?['id'], '${0xF12345678}');
  });

  test('different oversized alerts get different shade slots', () {
    // The three ids a real burst produced — an EEW, a 震度速報 and a weather
    // alert — every one of them outside 32 bits.
    const ids = [0xA1B2C3D4E5, 0x0F00BA9876, 0x9C8D7E6F50];
    final resolved = {
      for (final id in ids) _content({'id': '$id'}, title: 'T', body: 'B')!.id,
    };

    expect(resolved, hasLength(ids.length));
    expect(resolved, everyElement(inInclusiveRange(1, 0x7FFFFFFF)));
  });

  test('the same alert sent twice resolves to the same slot', () {
    final first = _content({'id': '${0xA1B2C3D4E5}'}, title: 'T', body: 'B');
    final again = _content({'id': '${0xA1B2C3D4E5}'}, title: 'T', body: 'B');

    expect(first?.id, again?.id);
  });

  test('a missing or non-numeric id is derived, never a shared default', () {
    final eew = _content(
      {'channel': 'eew-important-v2'},
      title: '速報',
      body: 'A',
    );
    final report = _content(
      {'channel': 'int_report-general-v2'},
      title: '震度',
      body: 'B',
    );
    final named = _content({'id': 'eq-2026-1016'}, title: 'T', body: 'B');

    expect(eew?.id, isNot(report?.id));
    expect(eew?.id, isPositive);
    expect(report?.id, isPositive);
    expect(named?.id, isPositive);
    // Derived from the text, so the same alert resent replaces itself.
    expect(
      _content({'channel': 'eew-important-v2'}, title: '速報', body: 'A')?.id,
      eew?.id,
    );
    expect(
      _content({'id': 'eq-2026-1016'}, title: 'X', body: 'Y')?.id,
      named?.id,
    );
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

  test('a nested numeric field is read as text', () {
    final content = _content({
      'content': '{"channelKey": "eq-v2", "title": 7, "body": 8, "id": -5}',
    });
    expect(content?.title, '7');
    expect(content?.body, '8');
    // Folded to positive: negative ids belong to test notifications, and a
    // server alert must never be able to replace one or be replaced by it.
    expect(content?.id, -5 & 0x7FFFFFFF);
    expect(content?.payload?['id'], '-5');
  });

  test('nested content that is not an object is ignored', () {
    expect(
      _content({'content': '[1, 2]'}, title: 'T', body: 'B')?.channelKey,
      'announcement-general-v2',
    );
    expect(
      _content({'content': ''}, title: 'T', body: 'B')?.channelKey,
      'announcement-general-v2',
    );
    expect(
      _content({'content': '{'}, title: 'T', body: 'B')?.channelKey,
      'announcement-general-v2',
    );
  });

  test('every id lands in the positive 31-bit range', () {
    int? id(Object value) => _content({'id': value}, title: 'T', body: 'B')?.id;

    expect(id('2147483647'), 2147483647);
    expect(id('42'), 42);
    expect(id('2147483649'), 1);
    expect(id('-1'), 0x7FFFFFFF);
    expect(id('${0xFFFFFFFFFF}'), 0x7FFFFFFF);
    expect(id('nope'), isPositive);
    // Wider than 64 bits: not an int at all, so it is hashed like any text.
    expect(id('123456789012345678901234567890'), isPositive);
    expect(
      _content({'content': '{"title":"T","body":"B","id":2147483649}'})?.id,
      1,
    );
  });

  group('jsonDataWithNotificationId', () {
    test('folds an oversized content id the terminated path would reject', () {
      final data = jsonDataWithNotificationId({
        'content':
            '{"id": ${0xF12345678}, "channelKey": "eq-v2", "body": "測試"}',
      });

      final content = data['content'] as Map<String, dynamic>;
      expect(content['id'], 0xF12345678 & 0x7FFFFFFF);
      expect(content['channelKey'], 'eq-v2');
      expect(content['body'], '測試');
    });

    test('gives a content with no id one derived from what it says', () {
      Map<String, dynamic> content(String body) =>
          jsonDataWithNotificationId({
                'content': '{"channelKey": "eq-v2", "body": "$body"}',
              })['content']
              as Map<String, dynamic>;

      expect(content('A')['id'], isPositive);
      expect(content('A')['id'], content('A')['id']);
      expect(content('A')['id'], isNot(content('B')['id']));
    });

    test('a flat id wins, as it does for every other field', () {
      final data = jsonDataWithNotificationId({
        'id': '7',
        'content': '{"id": 9, "channelKey": "eq-v2"}',
      });

      expect((data['content'] as Map<String, dynamic>)['id'], 7);
      expect(data['id'], '7');
    });

    test('accepts content that already arrived decoded', () {
      final data = jsonDataWithNotificationId({
        'content': <dynamic, dynamic>{'id': 0xF12345678, 'channelKey': 'eq-v2'},
      });

      expect(
        (data['content'] as Map<String, dynamic>)['id'],
        0xF12345678 & 0x7FFFFFFF,
      );
    });

    test('leaves a payload with no usable content alone', () {
      for (final data in <Map<String, dynamic>>[
        {},
        {'content': '{not json'},
        {'content': '[1, 2]'},
        {'channel': 'eq-v2', 'title': 'T'},
      ]) {
        expect(jsonDataWithNotificationId(data), same(data));
      }
    });
  });
}
