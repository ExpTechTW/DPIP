import 'package:dpip/core/platform/widget_home_intent.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(WidgetHomeIntent.reset);
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(WidgetHomeIntent.channel, null);
    WidgetHomeIntent.reset();
  });

  /// Stands in for `MainActivity`'s side of the channel.
  void mockNative({required bool launchedByWidget, Object? error}) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(WidgetHomeIntent.channel, (call) async {
          if (call.method != 'consumeInitialIntent') return null;
          if (error != null) throw error;
          return launchedByWidget;
        });
  }

  test('routes immediately once the app is ready', () {
    var opened = 0;
    WidgetHomeIntent.onOpen = () => opened++;
    WidgetHomeIntent.markReady();

    WidgetHomeIntent.route();

    expect(opened, 1);
  });

  test('a tap before the first frame is replayed on markReady, once', () {
    // The cold start: the router exists but has not drawn, so the tap must be
    // neither lost nor applied twice.
    var opened = 0;
    WidgetHomeIntent.onOpen = () => opened++;

    WidgetHomeIntent.route();
    expect(
      opened,
      0,
      reason: 'must not navigate before the app says it is ready',
    );

    WidgetHomeIntent.markReady();
    WidgetHomeIntent.markReady();

    expect(opened, 1);
  });

  test('becoming ready with nothing pending does not navigate', () {
    var opened = 0;
    WidgetHomeIntent.onOpen = () => opened++;

    WidgetHomeIntent.markReady();

    expect(opened, 0);
  });

  test('a cold-start launch intent is collected and routed', () async {
    // The regression: `MainActivity` builds this channel before the Dart
    // entrypoint runs, so it cannot push the tap that started the process. If
    // `listen` stops asking for it, the launch tap is silently dropped.
    mockNative(launchedByWidget: true);
    var opened = 0;
    WidgetHomeIntent.onOpen = () => opened++;

    await WidgetHomeIntent.listen();
    expect(opened, 0, reason: 'the collected tap waits for the first frame');

    WidgetHomeIntent.markReady();

    expect(opened, 1);
  });

  test('a launch that no Widget started routes nowhere', () async {
    mockNative(launchedByWidget: false);
    var opened = 0;
    WidgetHomeIntent.onOpen = () => opened++;

    await WidgetHomeIntent.listen();
    WidgetHomeIntent.markReady();

    expect(opened, 0);
  });

  test('a platform without the channel still starts', () async {
    mockNative(
      launchedByWidget: false,
      error: MissingPluginException('no widget here'),
    );
    var opened = 0;
    WidgetHomeIntent.onOpen = () => opened++;

    await WidgetHomeIntent.listen();
    WidgetHomeIntent.markReady();

    expect(opened, 0);
  });

  test('a failed collect does not take the app down', () async {
    mockNative(launchedByWidget: false, error: PlatformException(code: 'boom'));
    var opened = 0;
    WidgetHomeIntent.onOpen = () => opened++;

    await WidgetHomeIntent.listen();
    WidgetHomeIntent.markReady();

    expect(opened, 0);
  });

  test('the native openHome call reaches the router', () async {
    var opened = 0;
    WidgetHomeIntent.onOpen = () => opened++;
    WidgetHomeIntent.markReady();
    await WidgetHomeIntent.listen();

    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(
          WidgetHomeIntent.channel.name,
          const StandardMethodCodec().encodeMethodCall(
            const MethodCall('openHome'),
          ),
          (_) {},
        );

    expect(opened, 1);
  });

  test('a method this channel does not know is ignored', () async {
    var opened = 0;
    WidgetHomeIntent.onOpen = () => opened++;
    WidgetHomeIntent.markReady();
    await WidgetHomeIntent.listen();

    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(
          WidgetHomeIntent.channel.name,
          const StandardMethodCodec().encodeMethodCall(
            const MethodCall('other'),
          ),
          (_) {},
        );

    expect(opened, 0);
  });
}
