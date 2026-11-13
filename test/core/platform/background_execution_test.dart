import 'package:dpip/core/platform/background_execution.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the platform map is read key by key', () {
    final status = BackgroundExecutionStatus.fromMap({
      'restricted': true,
      'lockedByPolicy': false,
      'standbyBucket': 'restricted',
      'manufacturer': 'Samsung',
      'vendorManaged': true,
      'canOpenSettings': false,
    });

    expect(status.known, isTrue);
    expect(status.restricted, isTrue);
    expect(status.lockedByPolicy, isFalse);
    expect(status.standbyBucket, 'restricted');
    expect(status.manufacturer, 'Samsung');
    expect(status.vendorManaged, isTrue);
    expect(status.canOpenSettings, isFalse);
  });

  // The key arrived with the row-hiding change, so a native build that predates
  // it answers without it. Losing the row there would hide a state the user can
  // still fix, which is the worse error.
  test('a platform that does not answer keeps the row', () {
    expect(
      BackgroundExecutionStatus.fromMap({'restricted': false}).canOpenSettings,
      isTrue,
    );
    expect(const BackgroundExecutionStatus().canOpenSettings, isTrue);
  });
}
