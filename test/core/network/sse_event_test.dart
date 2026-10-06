import 'package:dpip/core/network/sse_event.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the default event is unnamed, empty, or message', () {
    expect(const SseEvent(data: '{}').isDefault, isTrue);
    expect(const SseEvent(name: '', data: '{}').isDefault, isTrue);
    expect(const SseEvent(name: 'message').isDefault, isTrue);
    expect(const SseEvent(name: 'info').isDefault, isFalse);
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
