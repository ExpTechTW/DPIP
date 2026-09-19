import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/platform/widget_snapshot_writer.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('test/widget_snapshot');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return null;
    });
  });
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test(
    'writes a typed kind and encoded JSON without exposing a file path',
    () async {
      final writer = IosWidgetSnapshotWriter(
        channel: channel,
        isSupportedPlatform: true,
      );
      const json = '{"schemaVersion":1}';

      final result = await writer.write(
        kind: WidgetSnapshotKind.weatherForecast,
        json: json,
      );

      expect(result.isOk, isTrue);
      expect(calls.single.method, 'write');
      expect(calls.single.arguments, {'kind': 'weatherForecast', 'json': json});
    },
  );

  test('unsupported platform does not call the native channel', () async {
    final writer = IosWidgetSnapshotWriter(
      channel: channel,
      isSupportedPlatform: false,
    );

    final result = await writer.write(
      kind: WidgetSnapshotKind.weatherForecast,
      json: '{}',
    );

    expect(
      (result.failureOrNull as WidgetSnapshotFailure).reason,
      WidgetSnapshotFailureReason.unavailable,
    );
    expect(calls, isEmpty);
  });

  test('missing plugin is a typed unavailable failure', () async {
    messenger.setMockMethodCallHandler(channel, null);
    final writer = IosWidgetSnapshotWriter(
      channel: channel,
      isSupportedPlatform: true,
    );

    final result = await writer.write(
      kind: WidgetSnapshotKind.weatherForecast,
      json: '{}',
    );

    expect(
      (result.failureOrNull as WidgetSnapshotFailure).reason,
      WidgetSnapshotFailureReason.unavailable,
    );
  });

  test('unexpected write error maps to writeFailed', () async {
    final writer = IosWidgetSnapshotWriter(
      channel: _ThrowingMethodChannel(StateError('unexpected')),
      isSupportedPlatform: true,
    );

    final result = await writer.write(
      kind: WidgetSnapshotKind.weatherForecast,
      json: '{}',
    );

    final failure = result.failureOrNull as WidgetSnapshotFailure;
    expect(failure.reason, WidgetSnapshotFailureReason.writeFailed);
    expect(failure.message, 'Widget snapshot could not be written.');
  });

  test('clears a typed kind without exposing a file path', () async {
    final writer = IosWidgetSnapshotWriter(
      channel: channel,
      isSupportedPlatform: true,
    );

    final result = await writer.clear(kind: WidgetSnapshotKind.currentWeather);

    expect(result.isOk, isTrue);
    expect(calls.single.method, 'clear');
    expect(calls.single.arguments, {'kind': 'currentWeather'});
  });

  test('clear on an unsupported platform does not call the channel', () async {
    final writer = IosWidgetSnapshotWriter(
      channel: channel,
      isSupportedPlatform: false,
    );

    final result = await writer.clear(kind: WidgetSnapshotKind.currentWeather);

    expect(
      (result.failureOrNull as WidgetSnapshotFailure).reason,
      WidgetSnapshotFailureReason.unavailable,
    );
    expect(calls, isEmpty);
  });

  test('clear maps a missing plugin to unavailable', () async {
    messenger.setMockMethodCallHandler(channel, null);
    final writer = IosWidgetSnapshotWriter(
      channel: channel,
      isSupportedPlatform: true,
    );

    final result = await writer.clear(kind: WidgetSnapshotKind.currentWeather);

    expect(
      (result.failureOrNull as WidgetSnapshotFailure).reason,
      WidgetSnapshotFailureReason.unavailable,
    );
  });

  test('unexpected clear error maps to writeFailed', () async {
    final writer = IosWidgetSnapshotWriter(
      channel: _ThrowingMethodChannel(StateError('unexpected')),
      isSupportedPlatform: true,
    );

    final result = await writer.clear(kind: WidgetSnapshotKind.currentWeather);

    final failure = result.failureOrNull as WidgetSnapshotFailure;
    expect(failure.reason, WidgetSnapshotFailureReason.writeFailed);
    expect(failure.message, 'Widget snapshot could not be cleared.');
  });

  for (final entry in <String, WidgetSnapshotFailureReason>{
    'invalid_kind': WidgetSnapshotFailureReason.invalidKind,
    'app_group_unavailable': WidgetSnapshotFailureReason.appGroupUnavailable,
    'write_failed': WidgetSnapshotFailureReason.writeFailed,
  }.entries) {
    test('clear ${entry.key} maps to a typed failure', () async {
      messenger.setMockMethodCallHandler(
        channel,
        (_) async => throw PlatformException(code: entry.key),
      );
      final writer = IosWidgetSnapshotWriter(
        channel: channel,
        isSupportedPlatform: true,
      );

      final result = await writer.clear(
        kind: WidgetSnapshotKind.currentWeather,
      );

      expect(
        (result.failureOrNull as WidgetSnapshotFailure).reason,
        entry.value,
      );
    });
  }

  for (final entry in <String, WidgetSnapshotFailureReason>{
    'invalid_kind': WidgetSnapshotFailureReason.invalidKind,
    'invalid_payload': WidgetSnapshotFailureReason.invalidPayload,
    'app_group_unavailable': WidgetSnapshotFailureReason.appGroupUnavailable,
    'write_failed': WidgetSnapshotFailureReason.writeFailed,
  }.entries) {
    test('${entry.key} maps to a typed failure', () async {
      messenger.setMockMethodCallHandler(
        channel,
        (_) async => throw PlatformException(code: entry.key),
      );
      final writer = IosWidgetSnapshotWriter(
        channel: channel,
        isSupportedPlatform: true,
      );

      final result = await writer.write(
        kind: WidgetSnapshotKind.weatherForecast,
        json: '{}',
      );

      expect(
        (result.failureOrNull as WidgetSnapshotFailure).reason,
        entry.value,
      );
    });
  }
}

final class _ThrowingMethodChannel extends MethodChannel {
  const _ThrowingMethodChannel(this.error) : super('test/throwing');

  final Object error;

  @override
  Future<T?> invokeMethod<T>(String method, [dynamic arguments]) =>
      Future<T?>.error(error);
}
