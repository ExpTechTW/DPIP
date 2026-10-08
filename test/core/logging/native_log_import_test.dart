/// The native buffer is imported through [Log] without starting the app.
library;

import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/logging/native_log_import.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talker_flutter/talker_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('test/native_log');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    Log.talker.cleanHistory();
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
    Log.talker.cleanHistory();
  });

  test('a batch is written at its own times and taken once', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return <Object?>[
        <String, Object>{
          'level': 'warning',
          'tag': 'widget',
          'message': 'refresh failed',
          'time': 1725000000000,
        },
        <String, Object>{
          'level': 'debug',
          'tag': '',
          'message': 'cache after',
          'time': 1725000000500,
        },
        <String, Object>{
          'level': 'nope',
          'tag': 'bg',
          'message': 'unknown level',
          'time': 1725000000900,
        },
        <String, Object>{'level': 'info', 'message': 'missing time'},
        'not a row',
      ];
    });

    await importNativeLogs(channel: channel);

    expect(calls, hasLength(1));
    expect(calls.single.method, 'take');
    expect(Log.talker.history, hasLength(3));

    final warning = Log.talker.history[0];
    expect(warning.logLevel, LogLevel.warning);
    expect(warning.message, '[widget] refresh failed');
    expect(warning.time.millisecondsSinceEpoch, 1725000000000);

    final debug = Log.talker.history[1];
    expect(debug.logLevel, LogLevel.debug);
    expect(debug.message, 'cache after');
    expect(debug.time.millisecondsSinceEpoch, 1725000000500);

    final unknown = Log.talker.history[2];
    expect(unknown.logLevel, LogLevel.info);
    expect(unknown.message, '[bg] unknown level');
    expect(unknown.time.millisecondsSinceEpoch, 1725000000900);
  });

  test('a failed handoff writes nothing and asks only once', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      throw PlatformException(code: 'native_log_io');
    });

    await expectLater(importNativeLogs(channel: channel), completes);

    expect(calls, hasLength(1));
    expect(calls.single.method, 'take');
    expect(Log.talker.history, isEmpty);
  });

  test('a missing channel is a no-op', () async {
    messenger.setMockMethodCallHandler(channel, null);

    await expectLater(importNativeLogs(channel: channel), completes);

    expect(Log.talker.history, isEmpty);
  });
}
