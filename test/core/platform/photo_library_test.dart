import 'package:dpip/core/platform/photo_library.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // The plugin's own channel — `gal` wraps every native call in it, so mocking
  // it here exercises the real permission logic without a device.
  const channel = MethodChannel('gal');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final calls = <MethodCall>[];

  /// Answers the plugin's three methods; [putError] is thrown from
  /// `putImageBytes` when set, which is how a native failure reaches Dart.
  void mockGal({
    required bool hasAccess,
    required bool grantsAccess,
    PlatformException? putError,
  }) {
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      switch (call.method) {
        case 'hasAccess':
          return hasAccess;
        case 'requestAccess':
          return grantsAccess;
        case 'putImageBytes':
          if (putError != null) throw putError;
          return null;
      }
      return null;
    });
  }

  setUp(calls.clear);

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('saves when access is already granted, without prompting', () async {
    mockGal(hasAccess: true, grantsAccess: true);
    final bytes = Uint8List.fromList([1, 2, 3]);

    final outcome = await PhotoLibrary.saveImage(bytes, name: 'report');

    expect(outcome, PhotoSaveOutcome.saved);
    // `putImageBytes` re-checks access inside the plugin itself, so the channel
    // sees a second `requestAccess` right before the write even here.
    expect(calls.map((c) => c.method), [
      'hasAccess',
      'requestAccess',
      'putImageBytes',
    ]);
    final put = calls.last.arguments as Map<Object?, Object?>;
    expect(put['name'], 'report');
    expect(put['bytes'], bytes);
  });

  test('prompts and saves when access is not granted yet', () async {
    mockGal(hasAccess: false, grantsAccess: true);

    final outcome = await PhotoLibrary.saveImage(
      Uint8List.fromList([1]),
      name: 'report',
    );

    expect(outcome, PhotoSaveOutcome.saved);
    expect(calls.map((c) => c.method), [
      'hasAccess',
      'requestAccess',
      'requestAccess',
      'putImageBytes',
    ]);
  });

  test('reports a refusal without attempting the write', () async {
    mockGal(hasAccess: false, grantsAccess: false);

    final outcome = await PhotoLibrary.saveImage(
      Uint8List.fromList([1]),
      name: 'report',
    );

    expect(outcome, PhotoSaveOutcome.permissionDenied);
    expect(calls.map((c) => c.method), ['hasAccess', 'requestAccess']);
  });

  test('maps a native ACCESS_DENIED to permissionDenied', () async {
    mockGal(
      hasAccess: true,
      grantsAccess: true,
      putError: PlatformException(code: 'ACCESS_DENIED'),
    );

    final outcome = await PhotoLibrary.saveImage(
      Uint8List.fromList([1]),
      name: 'report',
    );

    expect(outcome, PhotoSaveOutcome.permissionDenied);
  });

  test('maps any other native failure to failed', () async {
    mockGal(
      hasAccess: true,
      grantsAccess: true,
      putError: PlatformException(code: 'NOT_ENOUGH_SPACE'),
    );

    final outcome = await PhotoLibrary.saveImage(
      Uint8List.fromList([1]),
      name: 'report',
    );

    expect(outcome, PhotoSaveOutcome.failed);
  });
}
