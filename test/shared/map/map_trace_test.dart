import 'package:dpip/shared/map/map_trace.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ids increase and a missing object is named none', () {
    final first = nextMapTraceId();
    expect(nextMapTraceId(), first + 1);
    expect(mapTraceObject(null), 'none');
    expect(mapTraceObject(Object()), isNot(equals('none')));
  });

  test('a disabled trace does not evaluate its message', () {
    var composed = false;
    mapTrace('scope', () {
      composed = true;
      return 'unused';
    });
    expect(composed, isFalse);
    expect(mapTraceEnabled, isFalse);
  });
}
