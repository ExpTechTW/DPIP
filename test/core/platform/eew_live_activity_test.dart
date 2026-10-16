import 'package:dpip/core/platform/eew_live_activity.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('test/eew_live_activity');
  const bridge = EewLiveActivity(channel: channel);
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  final operations = <String, Future<EewLiveActivityStatus> Function()>{
    'getStatus': bridge.getStatus,
    'mockStart': bridge.mockStart,
    'mockStartGeneric': bridge.mockStartGeneric,
    'mockUpdate': () => bridge.mockUpdate(4),
    'mockWaveArrived': bridge.mockWaveArrived,
    'mockWaveArrivedWithAlert': bridge.mockWaveArrivedWithAlert,
    'mockScheduleDelayedArrivalAlert': bridge.mockScheduleDelayedArrivalAlert,
    'mockEnd': bridge.mockEnd,
  };

  for (final operation in operations.entries) {
    group(operation.key, () {
      test(
        'sends the native method and payload and parses the response',
        () async {
          final calls = <MethodCall>[];
          messenger.setMockMethodCallHandler(channel, (call) async {
            calls.add(call);
            return <String, Object?>{
              'supported': true,
              'enabled': true,
              'active': true,
              'reportNo': 4,
              'waveArrived': true,
              'generic': true,
              'delayedAlertStatus': 'Triggered',
            };
          });

          final status = await operation.value();
          expect(calls, hasLength(1));
          expect(calls.single.method, operation.key);
          expect(
            calls.single.arguments,
            operation.key == 'mockUpdate' ? {'reportNo': 4} : null,
          );
          expect(status.supported, isTrue);
          expect(status.enabled, isTrue);
          expect(status.active, isTrue);
          expect(status.reportNo, 4);
          expect(status.waveArrived, isTrue);
          expect(status.generic, isTrue);
          expect(status.delayedAlertStatus, 'Triggered');
        },
      );

      test('missing plugin returns an unsupported status', () async {
        messenger.setMockMethodCallHandler(channel, (_) async {
          throw MissingPluginException();
        });
        final status = await operation.value();
        expect(status.supported, isFalse);
        expect(status.enabled, isFalse);
        expect(status.active, isFalse);
        expect(status.reportNo, isNull);
        expect(status.waveArrived, isFalse);
        expect(status.generic, isFalse);
        expect(status.delayedAlertStatus, isNull);
      });

      test('propagates native errors with their details', () async {
        messenger.setMockMethodCallHandler(channel, (_) async {
          throw PlatformException(
            code: 'activity_error',
            message: 'Live Activities are disabled',
            details: {'reason': 'disabled'},
          );
        });
        await expectLater(
          operation.value(),
          throwsA(
            isA<PlatformException>()
                .having((e) => e.code, 'code', 'activity_error')
                .having(
                  (e) => e.message,
                  'message',
                  'Live Activities are disabled',
                )
                .having((e) => e.details, 'details', {'reason': 'disabled'}),
          ),
        );
      });

      test('rejects a null status', () async {
        messenger.setMockMethodCallHandler(channel, (_) async => null);
        await expectLater(
          operation.value(),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              'Missing EEW Live Activity status',
            ),
          ),
        );
      });
    });
  }

  test('missing optional fields and false flags use safe defaults', () async {
    messenger.setMockMethodCallHandler(
      channel,
      (_) async => {'supported': true},
    );
    final status = await bridge.getStatus();
    expect(status.supported, isTrue);
    expect(status.enabled, isFalse);
    expect(status.active, isFalse);
    expect(status.reportNo, isNull);
    expect(status.waveArrived, isFalse);
    expect(status.generic, isFalse);
    expect(status.delayedAlertStatus, isNull);
  });

  test('only literal true enables boolean flags', () async {
    messenger.setMockMethodCallHandler(
      channel,
      (_) async => {
        'supported': 'true',
        'enabled': 1,
        'active': false,
        'waveArrived': 'true',
        'generic': 1,
      },
    );
    final status = await bridge.getStatus();
    expect(status.supported, isFalse);
    expect(status.enabled, isFalse);
    expect(status.active, isFalse);
    expect(status.waveArrived, isFalse);
    expect(status.generic, isFalse);
  });

  for (final response in <Object>[
    {'reportNo': '4'},
    {'reportNo': 4.5},
    {'delayedAlertStatus': 8},
    ['not a status map'],
  ]) {
    test('rejects malformed status $response', () async {
      messenger.setMockMethodCallHandler(channel, (_) async => response);
      await expectLater(bridge.getStatus(), throwsA(isA<TypeError>()));
    });
  }
}
