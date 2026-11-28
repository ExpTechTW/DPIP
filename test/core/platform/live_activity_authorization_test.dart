/// The one-shot Live Activities read. Its only rule worth pinning is that a
/// switch nobody could read comes back null — "nothing to show" — and never
/// false, which the permission page would render as a switch to go and turn on.
library;

import 'package:dpip/core/platform/live_activity_authorization.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _channel = MethodChannel('com.exptech.dpip/live_activity_authorization');

/// The iOS branch, reachable on the host. Built on the real channel name, so
/// a rename on either side fails here rather than on a device.
class _OnIos extends LiveActivityAuthorization {
  _OnIos() : super(_channel);

  @override
  bool get applies => true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(_channel, null));

  void answer(Object? Function(MethodCall call) handler) => messenger
      .setMockMethodCallHandler(_channel, (call) async => handler(call));

  test('where it does not apply, the platform is not asked', () async {
    var asked = false;
    answer((_) {
      asked = true;
      return true;
    });

    // The host is neither iOS nor Android, so this is the Android answer too.
    expect(await LiveActivityAuthorization(_channel).isEnabled(), isNull);
    expect(asked, isFalse);
  });

  test('the switch is passed through, on and off', () async {
    final methods = <String>[];
    var on = true;
    answer((call) {
      methods.add(call.method);
      return on;
    });

    expect(await _OnIos().isEnabled(), isTrue);
    on = false;
    expect(await _OnIos().isEnabled(), isFalse);
    expect(methods, ['isEnabled', 'isEnabled']);
  });

  test('below iOS 18 the native side answers nil, which stays null', () async {
    answer((_) => null);

    expect(await _OnIos().isEnabled(), isNull);
  });

  test('a failed or missing channel is unknown, not off', () async {
    answer((_) => throw PlatformException(code: 'boom'));
    expect(await _OnIos().isEnabled(), isNull);

    // No handler at all: an older build without the native method.
    messenger.setMockMethodCallHandler(_channel, null);
    expect(await _OnIos().isEnabled(), isNull);
  });
}
