import 'package:dpip/features/events/data/event_repository_impl.dart';
import 'package:dpip/features/events/domain/event.dart';
import 'package:flutter_test/flutter_test.dart';

/// A heavy-rain notice shaped exactly like the live v1 feed: `id` empty, a
/// `key` fallback, and per-township text maps in which `all` is NOT a generic
/// fallback but one arbitrary township's sentence.
Map<String, dynamic> _heavyRain() => {
  'id': '',
  'key': '1785490200000-heavy-rain',
  'status': 1,
  'type': 'heavy-rain',
  'author': 'cwa',
  'time': {
    'send': 1785490200000,
    'expires': {'all': 1785510000000},
  },
  'text': {
    'content': {
      'all': {'title': '大雨特報', 'subtitle': '大雨特報'},
    },
    'description': {
      'all': '受對流雲系影響，新北市三峽區有局部大雨，請注意雷擊及強陣風。',
      '237': '受對流雲系影響，新北市三峽區有局部大雨，請注意雷擊及強陣風。',
      '710': '受對流雲系影響，臺南市永康區有局部大雨，請注意雷擊及強陣風。',
    },
  },
  'area': [237, 710],
  'icon': 'rainy_rounded',
};

void main() {
  group('Event.fromJson', () {
    test('uses the viewed township\'s own description', () {
      final event = Event.fromJson(_heavyRain(), regionCode: '710')!;
      expect(event.description, contains('臺南市永康區'));
      expect(event.title, '大雨特報');
      expect(event.type, EventType.heavyRain);
      expect(event.time.millisecondsSinceEpoch, 1785490200000);
    });

    test('never shows another township\'s text via the "all" entry', () {
      // `all` holds 三峽區's sentence on this notice. Falling back to it for a
      // township that has its own entry would tell a 永康 user about 三峽.
      final event = Event.fromJson(_heavyRain(), regionCode: '710')!;
      expect(event.description, isNot(contains('三峽')));
    });

    test('a township with no entry of its own gets no borrowed description', () {
      // 999 is not in the map; `all` is one specific township here, so naming it
      // would be wrong. The row degrades to its title instead.
      final event = Event.fromJson(_heavyRain(), regionCode: '999')!;
      expect(event.description, isNot(contains('永康')));
      expect(event.title, '大雨特報');
    });

    test('a genuinely global entry is still used as the fallback', () {
      final json = _heavyRain();
      (json['text'] as Map)['description'] = {'all': '全國性訊息'};
      expect(Event.fromJson(json, regionCode: '710')!.description, '全國性訊息');
    });

    test('falls back to `key` when `id` is empty', () {
      expect(Event.fromJson(_heavyRain())!.id, '1785490200000-heavy-rain');
    });

    test('an undated entry is dropped, not rendered at an epoch date', () {
      final json = _heavyRain()..remove('time');
      expect(Event.fromJson(json), isNull);
    });

    test('an unknown type still renders rather than vanishing', () {
      final json = _heavyRain()..['type'] = 'some-new-warning';
      expect(Event.fromJson(json)!.type, EventType.weatherWarning);
    });

    test('missing text degrades to empty strings, never throws', () {
      final json = _heavyRain()..remove('text');
      final event = Event.fromJson(json)!;
      expect(event.title, isEmpty);
      expect(event.description, isEmpty);
    });
  });

  group('EventRepositoryImpl.parseEvents', () {
    test('sorts newest first and skips unmappable entries', () {
      final older = _heavyRain();
      (older['time'] as Map)['send'] = 1785400000000;
      older['key'] = 'older';

      final events = EventRepositoryImpl.parseEvents([
        older,
        _heavyRain(),
        'not a map',
        {'no': 'time'},
      ], regionCode: '710');

      expect(events.map((e) => e.id), ['1785490200000-heavy-rain', 'older']);
    });

    test('an empty feed is an empty list, not an error', () {
      expect(EventRepositoryImpl.parseEvents(const []), isEmpty);
    });
  });
}
