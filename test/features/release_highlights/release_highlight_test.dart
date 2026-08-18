/// Release-highlight domain: multi-locale lookup and JSON decoding.
library;

import 'dart:convert';

import 'package:dpip/features/release_highlights/domain/release_highlight.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('localized', () {
    const t = {'zh_Hant': '台灣', 'en': 'Taiwan', 'ja': '台湾'};

    test('exact tag wins', () {
      expect(localized(t, 'ja'), '台湾');
      expect(localized(t, 'en'), 'Taiwan');
    });

    test('base language is a fallback for specific variants', () {
      expect(localized(t, 'zh_Hant_HK'), '台灣');
      expect(localized(t, 'en_US'), 'Taiwan');
    });

    test('authoring locale, then first value, as last resorts', () {
      expect(localized({'ja': '台湾'}, 'en'), '台湾');
    });

    test('unknown tag falls back to zh_Hant', () {
      expect(localized(t, 'th'), '台灣');
    });
  });

  group('ReleaseHighlightCard', () {
    test('decodes a full card with details and stats', () {
      final json = jsonDecode('''
      {
        "id": "networking-etag",
        "icon": "data_saver_on",
        "title": {"zh_Hant": "網路省電", "en": "Network"},
        "stat": {"zh_Hant": "98%", "en": "98%"},
        "statLabel": {"zh_Hant": "快取命中率", "en": "hit rate"},
        "highlights": [
          {"zh_Hant": "點一", "en": "one"},
          {"zh_Hant": "點二", "en": "two"}
        ],
        "details": [
          {
            "key": {"zh_Hant": "協定", "en": "protocol"},
            "value": {"zh_Hant": "ETag", "en": "ETag"}
          }
        ],
        "stats": [
          {"value": {"zh_Hant": "100", "en": "100"}, "label": {"zh_Hant": "節點", "en": "nodes"}}
        ]
      }
      ''') as Map<String, dynamic>;

      final card = ReleaseHighlightCard.fromJson(json);

      expect(card.id, 'networking-etag');
      expect(card.title['en'], 'Network');
      expect(card.highlights.length, 2);
      expect(card.details.single.key['en'], 'protocol');
      expect(card.stats.single.value['zh_Hant'], '100');
      expect(card.isTechnical, isTrue);
    });

    test('a card without details is not technical', () {
      final json = jsonDecode('''
      {"id": "a", "icon": "bolt", "title": {"zh_Hant": "甲", "en": "A"}}
      ''') as Map<String, dynamic>;

      final card = ReleaseHighlightCard.fromJson(json);
      expect(card.isTechnical, isFalse);
    });
  });
}
