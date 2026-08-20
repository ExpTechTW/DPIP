/// Tests foreground EEW notification sequencing and its safety fallback.
library;

import 'package:dpip/core/notifications/foreground_eew_announcement_gate.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'holds only the newest notification until latest speech completes',
    () async {
      final gate = ForegroundEewAnnouncementGate();
      var displayed = <String>[];
      gate.setActive(true);
      final first = gate.beginAnnouncement();

      await gate.submit(() async => displayed.add('first'));
      final second = gate.beginAnnouncement();
      await gate.submit(() async => displayed.add('second'));

      await gate.completeAnnouncement(first);
      expect(
        displayed,
        isEmpty,
        reason: 'obsolete speech cannot release sound',
      );
      await gate.completeAnnouncement(second);
      expect(displayed, ['second']);
    },
  );

  test('inactive gate displays immediately', () async {
    final gate = ForegroundEewAnnouncementGate();
    var displayed = false;

    await gate.submit(() async => displayed = true);

    expect(displayed, isTrue);
  });

  test('default fallback does not overlap the eight-second speech budget', () {
    fakeAsync((async) {
      final gate = ForegroundEewAnnouncementGate();
      var displayed = false;
      gate.setActive(true);
      gate.beginAnnouncement();
      gate.submit(() async => displayed = true);

      async.elapse(const Duration(seconds: 8));
      async.flushMicrotasks();
      expect(displayed, isFalse);

      async.elapse(const Duration(seconds: 2));
      async.flushMicrotasks();
      expect(displayed, isTrue);
    });
  });

  test('timeout releases a warning when speech never completes', () {
    fakeAsync((async) {
      final gate = ForegroundEewAnnouncementGate(
        maxHold: const Duration(seconds: 2),
      );
      var displayed = false;
      gate.setActive(true);
      gate.beginAnnouncement();
      gate.submit(() async => displayed = true);

      async.elapse(const Duration(seconds: 1));
      expect(displayed, isFalse);
      async.elapse(const Duration(seconds: 1));
      async.flushMicrotasks();
      expect(displayed, isTrue);
    });
  });
}
