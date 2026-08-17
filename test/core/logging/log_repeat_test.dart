/// The loop that made "tap the log, the app freezes" possible.
///
/// Reporting an error is not consequence-free: it goes to Talker, whose stream
/// the log screen rebuilds on and the persister writes to disk from. A fault
/// raised *while rendering that screen* therefore re-enters through the
/// rebuild it just caused, and every turn adds a Crashlytics report and a
/// database write.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dpip/core/logging/log.dart';

void main() {
  // `flutter_test` installs its own `FlutterError.onError`, so the real wiring
  // has to be put back to be exercised at all.
  FlutterExceptionHandler? original;
  setUp(() {
    Log.resetErrorRepeats();
    original = FlutterError.onError;
    Log.installErrorHandlers();
  });
  tearDown(() => FlutterError.onError = original);

  FlutterErrorDetails overflow() => FlutterErrorDetails(
    exception: FlutterError('A RenderFlex overflowed by 42 pixels'),
    library: 'rendering library',
    context: ErrorDescription('during layout'),
  );

  test('the same fault is reported, then stops being reported', () {
    final before = Log.talker.history.length;
    // What a layout fault does: once per frame, forever.
    for (var i = 0; i < 200; i++) {
      FlutterError.onError!(overflow());
    }
    final logged = Log.talker.history.length - before;
    expect(
      logged,
      lessThan(200),
      reason: 'an unbounded loop is what freezes the screen',
    );
    expect(logged, greaterThan(0), reason: 'the first one is real');
  });

  test('a different fault is never suppressed by another', () {
    for (var i = 0; i < 50; i++) {
      FlutterError.onError!(overflow());
    }
    final before = Log.talker.history.length;
    FlutterError.onError!(
      FlutterErrorDetails(
        exception: StateError('something else entirely'),
        library: 'dpip',
        context: ErrorDescription('unrelated'),
      ),
    );
    expect(
      Log.talker.history.length,
      greaterThan(before),
      reason: 'suppression must be per fault, not global',
    );
  });

  test('the suppression notice cannot itself be the next turn', () {
    // It goes through `info`, so it is not an error and cannot re-enter
    // FlutterError.onError.
    final baseline = Log.talker.history.length;
    for (var i = 0; i < 40; i++) {
      FlutterError.onError!(overflow());
    }
    // Counted from a baseline: the Talker instance is a singleton, so its
    // history outlives the test that produced it.
    final notices = Log.talker.history
        .skip(baseline)
        .where((e) => e.generateTextMessage().contains('suppressing'))
        .length;
    expect(notices, 1, reason: 'said once, not once per frame');
  });
}
