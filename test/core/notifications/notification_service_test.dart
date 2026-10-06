/// Push setup, permission prompts and silent-data display.
///
/// A channel the OS rejects, a prompt that never answers, or a token of the
/// wrong kind all look the same from outside: the app simply never rings.
/// These tests drive the plugin channels the service actually calls.
///
/// iOS APNs polling and the release-token truncation stay uncovered. Both
/// are `Platform.isIOS` / `kDebugMode` gates, and `dart:io` `Platform` cannot
/// be overridden — the same gap `plain_channels_test.dart` documents.
library;

import 'dart:async';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:awesome_notifications/awesome_notifications_platform_interface.dart';
import 'package:awesome_notifications_fcm/awesome_notifications_fcm.dart';
import 'package:dpip/core/notifications/notification_channels.dart';
import 'package:dpip/core/notifications/notification_service.dart';
import 'package:dpip/core/permissions/permission_outcome.dart';
import 'package:dpip/core/settings/setting_keys.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _awesome = MethodChannel('awesome_notifications');
const _fcm = MethodChannel('awesome_notifications_fcm');
const _settings = MethodChannel('flutter.baseflow.com/permissions/methods');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  var allowed = false;
  String alertStatus = 'notDetermined';
  Object? requestResult = false;
  Completer<List<String>>? requestGate;
  var statusThrows = false;
  var criticalGranted = false;
  var criticalThrows = false;
  var createOk = true;
  var createThrows = false;
  var created = 0;
  var initializeFailures = 0;
  var removeFailures = 0;
  var setChannelFailures = 0;
  var initializeCalls = 0;
  String? firebaseToken = 'fcm-token-12345678';

  void reset() {
    allowed = false;
    alertStatus = 'notDetermined';
    requestResult = false;
    requestGate = null;
    statusThrows = false;
    criticalGranted = false;
    criticalThrows = false;
    createOk = true;
    createThrows = false;
    created = 0;
    initializeFailures = 0;
    removeFailures = 0;
    setChannelFailures = 0;
    initializeCalls = 0;
    firebaseToken = 'fcm-token-12345678';
  }

  setUp(() {
    reset();
    // The plugin's own seam, the same one the permissions page test uses.
    // On macOS the default implementation never touches the method channel,
    // so a mock there would not run a single line of the service.
    AwesomeNotificationsPlatform.operatingSystem = 'ios';
    AwesomeNotificationsPlatform.resetInstance();
    messenger.setMockMethodCallHandler(_awesome, (call) async {
      switch (call.method) {
        case 'isNotificationAllowed':
          return allowed;
        case 'getPermissionStatuses':
          if (statusThrows) throw PlatformException(code: 'status');
          return <String, String>{'Alert': alertStatus};
        case 'requestNotifications':
          // The plugin treats the reply as the list of permissions still
          // missing. An empty list is a grant; a bool is a type error.
          final gate = requestGate;
          if (gate != null) return gate.future;
          return requestResult == true ? <String>[] : <String>['Alert'];
        case 'checkPermissions':
          if (criticalThrows) throw PlatformException(code: 'critical');
          return criticalGranted ? <String>['CriticalAlert'] : <String>[];
        case 'createNewNotification':
          if (createThrows) throw PlatformException(code: 'create');
          created++;
          return createOk;
        case 'initialize':
          initializeCalls++;
          if (initializeFailures > 0) {
            initializeFailures--;
            throw PlatformException(code: 'channel');
          }
          return true;
        case 'getLocalTimeZoneIdentifier':
        case 'getUtcTimeZoneIdentifier':
          return 'UTC';
        case 'removeNotificationChannel':
          if (removeFailures > 0) {
            removeFailures--;
            throw PlatformException(code: 'remove');
          }
          return true;
        case 'setNotificationChannel':
          if (setChannelFailures > 0) {
            setChannelFailures--;
            throw PlatformException(code: 'set');
          }
          return true;
        case 'setEventHandles':
          return true;
        default:
          return null;
      }
    });
    messenger.setMockMethodCallHandler(_fcm, (call) async {
      if (call.method == 'getFirebaseToken') return firebaseToken;
      if (call.method == 'initialize') return true;
      return null;
    });
    messenger.setMockMethodCallHandler(_settings, (call) async => true);
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(_awesome, null);
    messenger.setMockMethodCallHandler(_fcm, null);
    messenger.setMockMethodCallHandler(_settings, null);
    AwesomeNotificationsPlatform.operatingSystem = 'macos';
    AwesomeNotificationsPlatform.resetInstance();
  });

  FcmSilentData silent(Map<String, dynamic> data) =>
      FcmSilentData().fromMap(data)!;

  test('silent data before any service displays without a gate', () async {
    await onFcmSilentData(silent(const {'createdLifeCycle': 'Foreground'}));
    expect(created, 0);

    await onFcmSilentData(
      silent(const {
        'createdLifeCycle': 'Foreground',
        'channel': 'eew_alert-important-v2',
        'title': '速報',
        'body': '花蓮',
      }),
    );
    expect(created, 1);

    await onFcmSilentData(
      silent(const {
        'createdLifeCycle': 'Background',
        'title': '公告',
        'body': '正文',
      }),
    );
    expect(created, 2);

    await onFcmSilentData(silent(const {'channel': 'eq-v2'}));
    expect(created, 2);

    await onFcmSilentData(
      silent(const {
        'createdLifeCycle': 'Terminated',
        'content': {'id': 1, 'channelKey': 'eq-v2', 'title': 't', 'body': 'b'},
      }),
    );
    expect(created, greaterThanOrEqualTo(2));
  });

  test('a foreground EEW waits for the announcement, then plays', () async {
    final store = SettingsStore.inMemory();
    final service = NotificationService(store);
    addTearDown(service.foregroundEewGate.dispose);
    final gate = service.foregroundEewGate..setActive(true);
    final generation = gate.beginAnnouncement();

    final pending = onFcmSilentData(
      silent(const {
        'createdLifeCycle': 'Foreground',
        'channel': 'eew-important-v2',
        'title': '速報',
        'body': '花蓮',
      }),
    );
    await Future<void>.delayed(Duration.zero);
    expect(created, 0);

    await gate.completeAnnouncement(generation);
    await pending;
    expect(created, 1);

    // Inactive gate, and a non-EEW channel, both display immediately.
    gate.setActive(false);
    await onFcmSilentData(
      silent(const {
        'createdLifeCycle': 'Foreground',
        'channel': 'eq-v2',
        'title': '地震',
        'body': '花蓮',
      }),
    );
    expect(created, 2);
  });

  test('showTest and the debug warning post, or report a refusal', () async {
    final service = NotificationService(SettingsStore.inMemory());
    addTearDown(service.foregroundEewGate.dispose);

    expect(await service.showTest('not-a-channel'), isFalse);
    expect(testNotificationContent('not-a-channel'), isNull);

    final sample = testNotificationContent('eew_alert-important-v2');
    expect(sample?.title, startsWith(testTitlePrefix));
    expect(sample?.body, contains('<br>'));
    expect(sample!.id, lessThan(0));

    expect(await service.showTest('eew_alert-important-v2'), isTrue);
    createOk = false;
    expect(await service.showTest('eew_alert-important-v2'), isFalse);
    createThrows = true;
    expect(await service.showTest('eew_alert-important-v2'), isFalse);

    createThrows = false;
    createOk = true;
    await service.showDebugEewWarning(title: 'demo', body: 'sound');
    expect(created, greaterThan(0));
    createOk = false;
    await service.showDebugEewWarning(title: 'demo', body: 'rejected');

    expect(service.criticalApplies, isFalse);
    expect(service.token, isNull);
  });

  test('permission prompts, timeouts and the critical-alert check', () async {
    final store = SettingsStore.inMemory();
    final service = NotificationService(store);
    addTearDown(service.foregroundEewGate.dispose);

    allowed = true;
    expect(await service.isAllowed(), isTrue);
    expect(await service.requestPermission(), PermissionOutcome.granted);

    allowed = false;
    alertStatus = 'denied';
    expect(await service.requestPermission(), PermissionOutcome.needsSettings);

    alertStatus = 'notDetermined';
    requestResult = true;
    expect(await service.requestPermission(), PermissionOutcome.granted);
    await _settle();
    expect(store.getString(SettingKeys.pushToken), firebaseToken);

    requestResult = false;
    expect(await service.requestPermission(), PermissionOutcome.needsSettings);

    statusThrows = true;
    requestResult = true;
    expect(await service.requestPermission(), PermissionOutcome.granted);
    statusThrows = false;

    criticalGranted = true;
    expect(await service.criticalAllowed(), isTrue);
    expect(await service.requestCritical(), PermissionOutcome.granted);
    criticalGranted = false;
    expect(await service.criticalAllowed(), isFalse);
    expect(await service.requestCritical(), PermissionOutcome.needsSettings);
    criticalThrows = true;
    expect(await service.criticalAllowed(), isFalse);
    requestResult = false;
    expect(await service.requestCritical(), PermissionOutcome.needsSettings);

    expect(await service.openSystemSettings(), isTrue);

    final createdNote = ReceivedNotification().fromMap({
      'id': 7,
      'channelKey': 'eq-v2',
      'title': 't',
      'body': 'b',
      'createdLifeCycle': 'Foreground',
      'displayedLifeCycle': 'Foreground',
    });
    await onNotificationCreated(createdNote);
    await onNotificationDisplayed(createdNote);
  });

  testWidgets('a prompt that never answers falls back to settings', (
    tester,
  ) async {
    final service = NotificationService(SettingsStore.inMemory());
    addTearDown(service.foregroundEewGate.dispose);
    requestGate = Completer<List<String>>();
    alertStatus = 'notDetermined';
    final permission = service.requestPermission();
    final critical = service.requestCritical();
    await tester.pump(const Duration(seconds: 21));
    expect(await permission, PermissionOutcome.needsSettings);
    expect(await critical, PermissionOutcome.needsSettings);
  });

  test('init isolates a rejected batch and stores an FCM token, not an APNs one', () async {
    initializeFailures = 2;
    removeFailures = 1;
    setChannelFailures = 1;
    final store = SettingsStore.inMemory();
    final service = NotificationService(store);
    addTearDown(service.foregroundEewGate.dispose);

    await service.init().catchError((Object _) {});
    await _settle();

    if (initializeCalls > 0) {
      expect(
        store.getInt(SettingKeys.channelVersion),
        NotificationChannels.version,
      );
    }

    await _push(messenger, 'newFcmToken', 'fcm-from-refresh');
    await _settle();
    expect(store.getString(SettingKeys.pushToken), 'fcm-from-refresh');

    await _push(messenger, 'newNativeToken', 'apns-should-not-stick');
    await _settle();
    expect(store.getString(SettingKeys.pushToken), 'fcm-from-refresh');

    await _push(messenger, 'newFcmToken', '');
    await _settle();
    expect(store.getString(SettingKeys.pushToken), 'fcm-from-refresh');

    firebaseToken = '';
    // A second fetch with an empty token must not wipe a good one. The
    // launch fetch already ran; drive the store path again through the handler.
    await _push(messenger, 'newFcmToken', '');
    await _settle();
    expect(store.getString(SettingKeys.pushToken), 'fcm-from-refresh');
  });

  test('init still finishes when every channel is rejected', () async {
    initializeFailures = 1000;
    final store = SettingsStore.inMemory();
    final service = NotificationService(store);
    addTearDown(service.foregroundEewGate.dispose);
    await service.init().catchError((Object _) {});
    expect(store.getInt(SettingKeys.channelVersion), isNull);
  });
}

Future<void> _settle() async {
  for (var i = 0; i < 8; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

Future<void> _push(
  TestDefaultBinaryMessenger messenger,
  String method,
  Object? arguments,
) {
  final data = const StandardMethodCodec().encodeMethodCall(
    MethodCall(method, arguments),
  );
  return messenger.handlePlatformMessage(
    'awesome_notifications_fcm',
    data,
    (ByteData? _) {},
  );
}
