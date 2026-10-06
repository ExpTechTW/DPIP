/// Uncaught errors have to reach the crash sink, and a hot-restart view
/// recreation must not. The launch clock also has to start at bootstrap, not
/// at whoever first reads it — otherwise the first marker is always 0 ms.
library;

import 'package:dpip/core/logging/crash_sink.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/logging/log_store.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../storage/memory_db.dart';

class _Sink implements CrashSink {
  final fatal = <Object>[];
  final handled = <Object>[];

  @override
  void report(
    Object error,
    StackTrace stackTrace, {
    String? context,
    bool fatal = false,
  }) {
    (fatal ? this.fatal : handled).add(error);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the launch clock, history ceiling, and console flag are readable', () {
    Log.startClock();
    expect(Log.sinceStartMs, greaterThanOrEqualTo(0));
    expect(Log.historyLimit, greaterThan(0));
    expect(Log.enableConsoleColor, isA<bool>());
  });

  test(
    'persist copies new lines, flush does not throw, and reload trims',
    () async {
      final db = openMemoryDb();
      await LogStore.createSchema(db);
      final store = LogStore(db, now: () => DateTime.utc(2026, 10, 4));
      Log.persistTo(store);
      Log.info('handlers-test');
      await Log.flush();

      Log.reload([
        for (var i = 0; i < Log.historyLimit + 2; i++)
          TalkerData('old $i', logLevel: LogLevel.info, key: 'info'),
      ]);
      expect(Log.talker.history.length, lessThanOrEqualTo(Log.historyLimit));

      Log.store = null;
      await db.close();
    },
  );

  test(
    'handled and uncaught errors reach the sink, a recreated view does not',
    () {
      final sink = _Sink();
      final previousFlutter = FlutterError.onError;
      final previousPlatform = PlatformDispatcher.instance.onError;
      Log.crashSink = sink;
      Log.resetErrorRepeats();
      Log.installErrorHandlers();
      addTearDown(() {
        FlutterError.onError = previousFlutter;
        PlatformDispatcher.instance.onError = previousPlatform;
        Log.crashSink = null;
      });

      Log.handle(StateError('caught'), StackTrace.current, 'ctx');
      expect(sink.handled.single, isA<StateError>());

      FlutterError.reportError(
        FlutterErrorDetails(
          exception: PlatformException(code: 'recreating_view'),
        ),
      );
      expect(sink.fatal, isEmpty);

      FlutterError.reportError(
        FlutterErrorDetails(exception: StateError('layout')),
      );
      expect(sink.fatal, hasLength(1));

      PlatformDispatcher.instance.onError!.call(
        StateError('zone'),
        StackTrace.current,
      );
      expect(sink.fatal, hasLength(2));
    },
  );
}
