/// Pins how often the push path re-registers the notification catalogue.
///
/// `AwesomeNotifications().initialize` is taken on the **platform main thread**
/// natively, and it writes every channel through the plugin's own SQLite
/// (`SQLitePrimitivesDB`). The FCM handler used to call it per message, so an
/// earthquake — a burst of pushes seconds apart — rewrote the whole catalogue
/// on the main thread once per push. That is what Play's ANR reports name, with
/// "I/O on main thread" against that database.
///
/// The channels are process-wide native state; what an isolate needs is its own
/// one-time handshake. These tests pin that: once per isolate, retried only if
/// it failed.
library;

import 'package:dpip/core/notifications/notification_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late int handshakes;
  late bool failNext;

  /// Stands in for the plugin call — see [ensureAwesomeInitialized]'s seam.
  Future<void> initializer() async {
    handshakes++;
    if (failNext) throw Exception('channel rejected');
  }

  setUp(() {
    handshakes = 0;
    failNext = false;
    resetAwesomeInitializedForTest();
  });

  tearDown(resetAwesomeInitializedForTest);

  test('a second call does not re-register the catalogue', () async {
    await ensureAwesomeInitialized(initializer: initializer);
    await ensureAwesomeInitialized(initializer: initializer);
    await ensureAwesomeInitialized(initializer: initializer);

    expect(
      handshakes,
      1,
      reason:
          'every extra initialize is a whole-catalogue SQLite rewrite on the '
          'platform main thread',
    );
  });

  test('two pushes arriving together still handshake once', () async {
    await Future.wait([
      ensureAwesomeInitialized(initializer: initializer),
      ensureAwesomeInitialized(initializer: initializer),
    ]);

    expect(
      handshakes,
      1,
      reason: 'the guard is single-flight, not just a flag set after the await',
    );
  });

  test('a failed handshake is retried, not remembered as done', () async {
    failNext = true;
    await expectLater(
      ensureAwesomeInitialized(initializer: initializer),
      throwsA(isA<Exception>()),
    );

    failNext = false;
    await ensureAwesomeInitialized(initializer: initializer);

    expect(
      handshakes,
      2,
      reason:
          'remembering a failure would leave this isolate unable to draw any '
          'notification for the rest of its life',
    );
  });
}
