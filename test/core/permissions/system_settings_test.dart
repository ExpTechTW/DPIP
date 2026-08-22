import 'package:dpip/core/permissions/system_settings.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('test.permission_settings');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('reads Android localized background-location option label', () async {
    String? method;
    messenger.setMockMethodCallHandler(channel, (call) async {
      method = call.method;
      return 'Always allow';
    });

    final settings = AndroidPermissionSettings(channel);

    expect(await settings.backgroundLocationOptionLabel(), 'Always allow');
    expect(method, 'backgroundLocationOptionLabel');
  });

  test('opens the app-specific Android notification destination', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'openNotificationSettings');
      return 'notifications';
    });

    final settings = AndroidPermissionSettings(channel);

    expect(await settings.openNotificationSettings(), 'notifications');
  });

  test(
    'native failures degrade without trapping the permission flow',
    () async {
      messenger.setMockMethodCallHandler(channel, (_) async {
        throw PlatformException(code: 'settings_unavailable');
      });
      final settings = AndroidPermissionSettings(channel);

      expect(await settings.backgroundLocationOptionLabel(), isNull);
      expect(await settings.openNotificationSettings(), 'none');
    },
  );
}
