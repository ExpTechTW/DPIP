import 'package:dpip/core/network/sse_event.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the default event is unnamed, empty, or message', () {
    expect(const SseEvent(data: '{}').isDefault, isTrue);
    expect(const SseEvent(name: '', data: '{}').isDefault, isTrue);
    expect(const SseEvent(name: 'message').isDefault, isTrue);
    expect(const SseEvent(name: 'info').isDefault, isFalse);
  });

  test('a comment is never the payload event', () {
    const ping = SseEvent.comment('ping');
    expect(ping.isComment, isTrue);
    expect(ping.isDefault, isFalse, reason: 'unnamed, yet not a payload');
    expect(ping.name, isNull);
    expect(const SseEvent(data: '{}').isComment, isFalse);
    expect(ping.toString(), 'SseEvent.comment(ping)');
  });

  test('toString names the fields a log line needs', () {
    expect(
      const SseEvent(
        name: 'info',
        data: 'x',
        retry: Duration(seconds: 3),
      ).toString(),
      'SseEvent(name: info, data: x, retry: 0:00:03.000000)',
    );
  });
}
