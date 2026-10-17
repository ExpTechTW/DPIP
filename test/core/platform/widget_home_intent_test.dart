import 'package:dpip/core/platform/widget_home_intent.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(WidgetHomeIntent.reset);
  tearDown(WidgetHomeIntent.reset);

  test('routes immediately once the router is listening', () {
    var opened = 0;
    WidgetHomeIntent.onOpen = () => opened++;

    WidgetHomeIntent.route();

    expect(opened, 1);
  });

  test('a tap before the router exists is replayed on drain, once', () {
    // This is the cold start: the Widget launched the process, the router is
    // not built yet, and the tap must be neither lost nor applied twice.
    WidgetHomeIntent.route();

    var opened = 0;
    WidgetHomeIntent.onOpen = () => opened++;
    WidgetHomeIntent.drainPending();
    WidgetHomeIntent.drainPending();

    expect(opened, 1);
  });

  test('draining with nothing pending does not navigate', () {
    var opened = 0;
    WidgetHomeIntent.onOpen = () => opened++;

    WidgetHomeIntent.drainPending();

    expect(opened, 0);
  });

  test('the native openHome call reaches the router', () async {
    var opened = 0;
    WidgetHomeIntent.onOpen = () => opened++;
    WidgetHomeIntent.listen();

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
    WidgetHomeIntent.listen();

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
