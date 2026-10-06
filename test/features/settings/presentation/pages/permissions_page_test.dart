/// The permissions page is where a missed alert is diagnosed later. A row
/// that never asks, or a return from Settings that does not look again,
/// leaves the grant the user just changed invisible.
library;

import 'package:awesome_notifications/awesome_notifications_platform_interface.dart';
import 'package:dpip/core/geo/location_service.dart';
import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/core/notifications/notification_service.dart';
import 'package:dpip/core/permissions/permission_health.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:dpip/features/settings/presentation/pages/permissions_page.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

const Size _tall = Size(400, 2400);

const _awesome = MethodChannel('awesome_notifications');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  setUp(() {
    AwesomeNotificationsPlatform.operatingSystem = 'ios';
    AwesomeNotificationsPlatform.resetInstance();
    messenger.setMockMethodCallHandler(_awesome, (call) async {
      return switch (call.method) {
        'isNotificationAllowed' => false,
        'requestNotifications' => false,
        _ => null,
      };
    });
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(_awesome, null);
    AwesomeNotificationsPlatform.operatingSystem = 'macos';
    AwesomeNotificationsPlatform.resetInstance();
  });

  testWidgets('lists the grants and asking for notifications refreshes', (
    tester,
  ) async {
    tester.view.physicalSize = _tall;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final store = SettingsStore.inMemory();
    final notifications = NotificationService(store);
    final location = LocationService(const TownDirectory({}));

    await tester.pumpWidget(
      MultiProvider(
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
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const PermissionsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l10n.permissionsTitle), findsOneWidget);
    expect(find.text(l10n.permissionsBody), findsOneWidget);
    expect(find.text(l10n.onboardingPermNotify), findsOneWidget);
    expect(find.text(l10n.onboardingPermLocation), findsOneWidget);
    expect(find.text(l10n.onboardingPermBackground), findsOneWidget);

    await tester.tap(find.text(l10n.onboardingGrant).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text(l10n.commonCancel), findsOneWidget);
    await tester.tap(find.text(l10n.commonCancel));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text(l10n.onboardingPermNotify), findsOneWidget);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text(l10n.onboardingPermLocation), findsOneWidget);
  });
}
