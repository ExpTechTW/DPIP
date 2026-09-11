/// Pins [EtagInterceptor.utf8Length] to `utf8.encode(s).length` — the number
/// the traffic meter used to obtain by encoding the whole body.
library;

import 'dart:convert';

import 'package:dpip/core/network/etag_interceptor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('utf8Length matches the encoder byte for byte', () {
    const cases = <String>[
      '',
      'plain ascii {"a":1}',
      'é ß ÿ', // 2-byte
      '台北 地震 速報', // 3-byte CJK
      '\u{1F600}\u{1F30F}', // 4-byte surrogate pairs
      'mixed 台北 \u{1F600} é end',
      // The boundaries: last 1-byte, first 2-byte, last 2-byte, first 3-byte,
      // last BMP code point.
      '\u007F\u0080\u07FF\u0800\uFFFF',
    ];
    for (final s in cases) {
      expect(
        EtagInterceptor.utf8Length(s),
        utf8.encode(s).length,
        reason: 'for ${jsonEncode(s)}',
      );
    }
  });

  test(
    'a lone surrogate counts as U+FFFD, exactly as the encoder writes it',
    () {
      final lone = [
        String.fromCharCode(0xD83D), // lead with nothing after
        '${String.fromCharCode(0xD83D)}x', // lead followed by a non-trail
        String.fromCharCode(0xDE00), // trail alone
        // Reversed pair: neither half completes the other.
        'a${String.fromCharCode(0xDE00)}${String.fromCharCode(0xD83D)}',
      ];
      for (final s in lone) {
        expect(EtagInterceptor.utf8Length(s), utf8.encode(s).length);
      }
    },
  );
}
