import 'package:dpip/core/logging/crash_sink.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeSink implements CrashSink {
  final List<({Object error, bool fatal, String? context})> reports = [];

  @override
  void report(
    Object error,
    StackTrace stackTrace, {
    String? context,
    bool fatal = false,
  }) {
    reports.add((error: error, fatal: fatal, context: context));
  }
}

void main() {
  tearDown(() => Log.crashSink = null);

  test('handle forwards to the crash sink as a non-fatal report', () {
    final sink = _FakeSink();
    Log.crashSink = sink;

    final error = StateError('boom');
    Log.handle(error, StackTrace.current, 'ctx');

    expect(sink.reports, hasLength(1));
    expect(sink.reports.single.error, same(error));
    expect(sink.reports.single.fatal, isFalse);
    expect(sink.reports.single.context, 'ctx');
  });

  test('with no sink set, handle still logs without throwing', () {
    Log.crashSink = null;
    expect(() => Log.handle(StateError('boom')), returnsNormally);
  });
}
