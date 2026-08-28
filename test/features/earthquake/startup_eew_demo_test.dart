import 'package:dpip/features/earthquake/data/monitor_demo.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('startup demo always exposes the same single EEW', () async {
    final source = StartupEewDemoSource(
      clock: () => DateTime.utc(2026, 8, 28, 10),
    );

    final first = (await source.fetch()).valueOrNull!;
    final second = (await source.fetch()).valueOrNull!;

    expect(first, hasLength(1));
    expect(first.single.id, 'startup-demo');
    expect(first.single.serial, 1);
    expect(second, hasLength(1));
    expect(source.sameData(first, second), isTrue);
  });
}
