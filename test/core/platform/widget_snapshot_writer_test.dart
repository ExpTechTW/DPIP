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

  test('writes current weather with a source identifier without exposing a file path', () async {
    final writer = IosWidgetSnapshotWriter(
      channel: channel,
      isSupportedPlatform: true,
    );

    const json = '{"schemaVersion":5}';

    final result = await writer.write(
      kind: WidgetSnapshotKind.currentWeather,
      json: json,
      sourceIdentifier: 'region:220',
    );

    expect(result.isOk, isTrue);
    expect(calls.single.method, 'write');
    expect(calls.single.arguments, {
      'kind': 'currentWeather',
      'json': json,
      'sourceIdentifier': 'region:220',
    });
  });

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

  test(
    'writes the location catalog kind without exposing a file path',
    () async {
      final writer = IosWidgetSnapshotWriter(
        channel: channel,
        isSupportedPlatform: true,
      );

      const json = '{"schemaVersion":1,"locations":[]}';

      final result = await writer.write(
        kind: WidgetSnapshotKind.locationCatalog,
        json: json,
      );

      expect(result.isOk, isTrue);
      expect(calls.single.method, 'write');
      expect(calls.single.arguments, {'kind': 'locationCatalog', 'json': json});
    },
  );

  group('AndroidWidgetSnapshotWriter', () {
    test('speaks the same protocol as the iOS writer', () async {
      final writer = AndroidWidgetSnapshotWriter(
        channel: channel,
        isSupportedPlatform: true,
      );

      const json = '{"schemaVersion":7}';

      final result = await writer.write(
        kind: WidgetSnapshotKind.currentWeather,
        json: json,
        sourceIdentifier: 'current-location',
      );

      expect(result.isOk, isTrue);
      // One protocol, two platforms: the same method, the same keys.
      expect(calls.single.method, 'write');
      expect(calls.single.arguments, {
        'kind': 'currentWeather',
        'json': json,
        'sourceIdentifier': 'current-location',
      });
    });

    test('maps the platform error codes the same way', () async {
      final writer = AndroidWidgetSnapshotWriter(
        channel: _ThrowingMethodChannel(
          PlatformException(code: 'invalid_payload'),
        ),
        isSupportedPlatform: true,
      );

      final result = await writer.write(
        kind: WidgetSnapshotKind.currentWeather,
        json: '{}',
      );

      expect(
        (result.failureOrNull as WidgetSnapshotFailure).reason,
        WidgetSnapshotFailureReason.invalidPayload,
      );
    });

    for (final method in ['write', 'clear']) {
      test('$method maps write_failed to writeFailed', () async {
        messenger.setMockMethodCallHandler(
          channel,
          (_) async => throw PlatformException(code: 'write_failed'),
        );
        final writer = AndroidWidgetSnapshotWriter(
          channel: channel,
          isSupportedPlatform: true,
        );

        final result = method == 'write'
            ? await writer.write(
                kind: WidgetSnapshotKind.currentWeather,
                json: '{}',
              )
            : await writer.clear(kind: WidgetSnapshotKind.currentWeather);

        expect(
          (result.failureOrNull as WidgetSnapshotFailure).reason,
          WidgetSnapshotFailureReason.writeFailed,
        );
      });
    }

    test('does not call a channel on a platform it is not on', () async {
      final writer = AndroidWidgetSnapshotWriter(
        channel: channel,
        isSupportedPlatform: false,
      );

      final result = await writer.clear(
        kind: WidgetSnapshotKind.currentWeather,
      );

      expect(result.failureOrNull, isA<WidgetSnapshotFailure>());
      expect(calls, isEmpty);
    });
  });

  group('createWidgetSnapshotWriter', () {
    test('answers a writer on every platform, never null', () {
      // The wiring sites call this unconditionally: bootstrap for the location
      // catalog and the weather providers for the current weather. On the test
      // host — neither iOS nor Android — it must still answer a writer, whose
      // calls fail the way an absent extension does rather than throwing.
      expect(createWidgetSnapshotWriter(), isA<WidgetSnapshotWriter>());
    });

    test('selects the Android writer for Android', () {
      expect(
        createWidgetSnapshotWriter(isIOS: false, isAndroid: true),
        isA<AndroidWidgetSnapshotWriter>(),
      );
    });

    test('selects the iOS writer for iOS', () {
      expect(
        createWidgetSnapshotWriter(isIOS: true, isAndroid: false),
        isA<IosWidgetSnapshotWriter>(),
      );
    });

    test('prefers iOS when a build somehow reports both', () {
      // `dart:io` cannot report both, but the branch order is a decision worth
      // pinning: the iOS writer is the one whose storage is the App Group.
      expect(
        createWidgetSnapshotWriter(isIOS: true, isAndroid: true),
        isA<IosWidgetSnapshotWriter>(),
      );
    });

    test('answers the unsupported writer anywhere else', () {
      expect(
        createWidgetSnapshotWriter(isIOS: false, isAndroid: false),
        isA<UnsupportedWidgetSnapshotWriter>(),
      );
    });

    test(
      'the unsupported writer reports unavailable rather than throwing',
      () async {
        const writer = UnsupportedWidgetSnapshotWriter();

        final result = await writer.write(
          kind: WidgetSnapshotKind.locationCatalog,
          json: '{}',
        );

        expect(
          (result.failureOrNull as WidgetSnapshotFailure).reason,
          WidgetSnapshotFailureReason.unavailable,
        );
      },
    );
  });
}

final class _ThrowingMethodChannel extends MethodChannel {
  const _ThrowingMethodChannel(this.error) : super('test/throwing');

  final Object error;

  @override
  Future<T?> invokeMethod<T>(String method, [dynamic arguments]) =>
      Future<T?>.error(error);
}
