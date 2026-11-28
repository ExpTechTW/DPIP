import 'package:dpip/core/platform/eew_live_activity_data.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('test/eew_live_activity_data');
  const data = EewLiveActivityData(channel: channel);
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('speaks the native method names and argument keys', () async {
    final calls = <MethodCall>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return call.method == 'travelTimeVersion' ? 426000897 : true;
    });

    expect(await data.travelTimeVersion(), 426000897);
    expect(
      await data.writeTravelTime(Uint8List.fromList([1, 2, 3]), version: 7),
      isTrue,
    );
    expect(await data.writeFix(lat: 23.97, lng: 121.6), isTrue);
    expect(await data.writeTown((code: '970', lat: 23.98, lng: 121.6)), isTrue);
    expect(await data.writeTown(null), isTrue);

    expect(calls.map((call) => call.method), [
      'travelTimeVersion',
      'writeTravelTime',
      'writeFix',
      'writeTown',
      'writeTown',
    ]);
    expect(calls[1].arguments, {
      'table': Uint8List.fromList([1, 2, 3]),
      'version': 7,
    });
    expect(calls[2].arguments, {'lat': 23.97, 'lng': 121.6});
    expect(calls[3].arguments, {'code': '970', 'lat': 23.98, 'lng': 121.6});
    expect(calls[4].arguments, {'code': null, 'lat': null, 'lng': null});
  });

  test('a missing plugin is a quiet no-op', () async {
    // No handler: the call throws MissingPluginException underneath.
    expect(await data.travelTimeVersion(), isNull);
    expect(await data.writeTravelTime(Uint8List(0), version: 1), isFalse);
    expect(await data.writeFix(lat: 0, lng: 0), isFalse);
    expect(await data.writeTown(null), isFalse);
  });

  test('a native failure is reported as not written, never thrown', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      throw PlatformException(code: 'app_group_unavailable');
    });

    expect(await data.travelTimeVersion(), isNull);
    expect(await data.writeTravelTime(Uint8List(0), version: 1), isFalse);
    expect(await data.writeFix(lat: 0, lng: 0), isFalse);
    expect(await data.writeTown(null), isFalse);
  });
}
