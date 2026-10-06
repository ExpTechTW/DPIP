import 'dart:async';

import 'package:awesome_notifications/awesome_notifications_platform_interface.dart';
import 'package:dpip/core/geo/location_service.dart';
import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/core/notifications/notification_service.dart';
import 'package:dpip/core/notifications/urgent_notification_settings.dart';
import 'package:dpip/core/permissions/permission_health.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/widgets/permission_checklist.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

Widget _wrap(Widget child, {TextScaler? textScaler}) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('en'),
  builder: textScaler == null
      ? null
      : (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: textScaler),
          child: child!,
        ),
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

UrgentNotificationChannelStatus _channel(
  String id,
  UrgentNotificationChannelState state,
) => UrgentNotificationChannelStatus(
  requestedId: id,
  channelId: id,
  name: id,
  state: state,
);

Widget _urgentSection(List<UrgentNotificationChannelStatus> channels) =>
    UrgentNotificationSection(
      status: UrgentNotificationStatus(
        channelSettingsSupported: true,
        channels: channels,
      ),
      title: 'Major alerts in Do Not Disturb',
      description: 'Choose which channels may interrupt.',
      loadingChannelId: null,
      unchangedChannelId: null,
      blocked: false,
      onOpen: (_) async {},
    );

void main() {
  testWidgets('loading state is visible and disables its action', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        PermissionRow(
          icon: Icons.location_on_outlined,
          title: 'Location',
          description: 'Used for local alerts',
          granted: false,
          loading: true,
          onGrant: () async {},
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('returning without a grant shows actionable feedback', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        PermissionRow(
          icon: Icons.notifications_outlined,
          title: 'Notifications',
          description: 'Used for alerts',
          granted: false,
          settingsAction: true,
          feedback: PermissionRowFeedback.stillNeeded,
          onGrant: () async {},
        ),
      ),
    );

    expect(
      find.text(
        'Still needs attention. Check the highlighted option in Settings.',
      ),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    expect(find.text('Open Settings'), findsOneWidget);
  });

  testWidgets('a channel still under Do Not Disturb marks the closed header', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _wrap(
        _urgentSection([
          _channel('tsunami', UrgentNotificationChannelState.bypasses),
          _channel('eew', UrgentNotificationChannelState.doesNotBypass),
        ]),
      ),
    );

    // The row saying so is inside the collapsed section, so the dot on the
    // header is the only thing the user has to go on.
    expect(find.text('Follows Do Not Disturb'), findsNothing);
    expect(find.byType(Badge), findsOneWidget);
    // The header tile merges its parts into one node, so the dot's label is
    // read out with the title rather than on its own.
    expect(
      find.bySemanticsLabel(RegExp('Permissions need attention')),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('every channel allowed leaves the header unmarked', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        _urgentSection([
          _channel('tsunami', UrgentNotificationChannelState.bypasses),
          _channel('eew', UrgentNotificationChannelState.bypasses),
        ]),
      ),
    );

    expect(find.byType(Badge), findsNothing);
  });

  testWidgets('long guidance remains usable on a narrow large-text display', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _wrap(
        PermissionRow(
          icon: Icons.factory_outlined,
          title: 'Manufacturer background manager',
          description:
              'Allow automatic startup and background activity for DPIP.',
          granted: false,
          advisory: true,
          settingsAction: true,
          feedback: PermissionRowFeedback.verifyManually,
          onGrant: () async {},
        ),
        textScaler: const TextScaler.linear(2),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Open Settings'), findsOneWidget);
  });

  testWidgets('a settled preference drops its settings action', (tester) async {
    await tester.pumpWidget(
      _wrap(
        PermissionRow(
          icon: Icons.notifications_active_outlined,
          title: 'Major EEW',
          description: 'Allowed during Do Not Disturb',
          granted: true,
          settingsAction: true,
          onGrant: () async {},
        ),
      ),
    );

    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(find.text('Open Settings'), findsNothing);
    expect(find.byType(OutlinedButton), findsNothing);
  });

  group('PermissionChecklist', () {
    const awesome = MethodChannel('awesome_notifications');
    const settingsChannel = MethodChannel(
      'flutter.baseflow.com/permissions/methods',
    );
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

    late GeolocatorPlatform original;
    late _ChecklistGeo geo;
    var allowed = false;
    var alertStatus = 'notDetermined';
    Object? requestResult = false;
    Completer<List<String>>? requestGate;
    var settingsOpened = true;

    setUp(() {
      AwesomeNotificationsPlatform.operatingSystem = 'ios';
      AwesomeNotificationsPlatform.resetInstance();
      original = GeolocatorPlatform.instance;
      geo = _ChecklistGeo();
      GeolocatorPlatform.instance = geo;
      allowed = false;
      alertStatus = 'notDetermined';
      requestResult = false;
      requestGate = null;
      settingsOpened = true;
      messenger.setMockMethodCallHandler(awesome, (call) async {
        return switch (call.method) {
          'isNotificationAllowed' => allowed,
          'getPermissionStatuses' => {'Alert': alertStatus},
          'requestNotifications' =>
            requestGate?.future ??
                (requestResult == true ? <String>[] : <String>['Alert']),
          'checkPermissions' => <String>[],
          _ => null,
        };
      });
      messenger.setMockMethodCallHandler(settingsChannel, (call) async {
        if (!settingsOpened) return false;
        return true;
      });
    });

    tearDown(() {
      GeolocatorPlatform.instance = original;
      messenger.setMockMethodCallHandler(awesome, null);
      messenger.setMockMethodCallHandler(settingsChannel, null);
      AwesomeNotificationsPlatform.operatingSystem = 'macos';
      AwesomeNotificationsPlatform.resetInstance();
    });

    Widget host({ValueChanged<PermissionState>? onChanged}) {
      final notifications = NotificationService(SettingsStore.inMemory());
      final location = LocationService(const TownDirectory({}));
      return MultiProvider(
        providers: [
          Provider.value(value: notifications),
          Provider.value(value: location),
          ChangeNotifierProvider(
            create: (_) => PermissionHealth(
              location: location,
              notifications: notifications,
            ),
          ),
        ],
        child: _wrap(PermissionChecklist(onChanged: onChanged)),
      );
    }

    testWidgets('a grant in flight blocks the other rows', (tester) async {
      requestGate = Completer<List<String>>();
      var changes = 0;
      await tester.pumpWidget(host(onChanged: (_) => changes++));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Location'), findsOneWidget);
      expect(find.text('Background location'), findsOneWidget);
      expect(changes, greaterThan(0));

      await tester.tap(find.text('Grant').first);
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      final buttons = tester.widgetList<FilledButton>(
        find.byType(FilledButton),
      );
      expect(buttons.last.onPressed, isNull);

      requestGate!.complete(<String>[]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets(
      'a decided denial explains settings, and coming back rechecks',
      (tester) async {
        tester.view.physicalSize = const Size(400, 1200);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        alertStatus = 'denied';
        await tester.pumpWidget(host());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        await tester.tap(find.text('Grant').first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('Grant it in Settings'), findsOneWidget);
        await tester.tap(find.text('Cancel'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('Grant it in Settings'), findsNothing);

        await tester.tap(find.text('Grant').first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.tap(find.text('Open Settings'));
        await tester.pump();
        expect(find.byType(CircularProgressIndicator), findsWidgets);

        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        expect(find.text('Notifications'), findsOneWidget);

        settingsOpened = false;
        await tester.tap(find.text('Grant').first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.tap(find.text('Open Settings'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        expect(
          find.text(
            'Still needs attention. Check the highlighted option in Settings.',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('granting location reveals the background request', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      alertStatus = 'denied';
      geo.permission = LocationPermission.denied;
      geo.afterRequest = LocationPermission.whileInUse;
      await tester.pumpWidget(host());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.text('Grant').at(1));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('Grant'), findsWidgets);

      geo.afterRequest = LocationPermission.whileInUse;
      await tester.tap(find.text('Grant').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Grant it in Settings'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    });
  });
}

class _ChecklistGeo extends GeolocatorPlatform {
  LocationPermission permission = LocationPermission.denied;
  LocationPermission? afterRequest;

  @override
  Future<bool> isLocationServiceEnabled() async => true;

  @override
  Future<LocationPermission> checkPermission() async => permission;

  @override
  Future<LocationPermission> requestPermission() async {
    final next = afterRequest;
    if (next != null) permission = next;
    return permission;
  }

  @override
  Future<Position?> getLastKnownPosition({
    bool forceLocationManager = false,
  }) async => null;

  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async => Position(
    latitude: 0,
    longitude: 0,
    timestamp: DateTime.now(),
    accuracy: 1,
    altitude: 0,
    altitudeAccuracy: 0,
    heading: 0,
    headingAccuracy: 0,
    speed: 0,
    speedAccuracy: 0,
  );

  @override
  Stream<ServiceStatus> getServiceStatusStream() => const Stream.empty();

  @override
  Stream<Position> getPositionStream({LocationSettings? locationSettings}) =>
      const Stream.empty();
}
