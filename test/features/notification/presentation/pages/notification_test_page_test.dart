/// The test page is supposed to ring a sample, not a live alert. A denied
/// grant that still enables the rows, or a failed post that stays silent,
/// would tell the user the phone will wake them when it will not.
library;

import 'package:awesome_notifications/awesome_notifications_platform_interface.dart';
import 'package:dpip/core/notifications/notification_service.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:dpip/features/notification/presentation/pages/notification_test_page.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

const Size _tall = Size(400, 4000);

const _awesome = MethodChannel('awesome_notifications');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  var allowed = false;
  bool? created;

  setUp(() {
    allowed = false;
    created = true;
    AwesomeNotificationsPlatform.operatingSystem = 'ios';
    AwesomeNotificationsPlatform.resetInstance();
    messenger.setMockMethodCallHandler(_awesome, (call) async {
      return switch (call.method) {
        'isNotificationAllowed' => allowed,
        'createNewNotification' => created,
        _ => null,
      };
    });
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(_awesome, null);
    AwesomeNotificationsPlatform.operatingSystem = 'macos';
    AwesomeNotificationsPlatform.resetInstance();
  });

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = _tall;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider(
            create: (_) => NotificationService(SettingsStore.inMemory()),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: KeyedSubtree(
            key: ValueKey(allowed),
            child: const NotificationTestPage(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a denied grant explains itself and disables every row', (
    tester,
  ) async {
    await pump(tester);
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));

    expect(find.text(l10n.notifyTestTitle), findsOneWidget);
    expect(find.text(l10n.notifyTestPermissionOff), findsOneWidget);
    expect(find.text(l10n.notifySectionEew), findsOneWidget);
    expect(find.text('緊急地震速報(重大)'), findsOneWidget);

    final tile = tester.widget<ListTile>(find.byType(ListTile).first);
    expect(tile.enabled, isFalse);

    await tester.tap(find.text(l10n.permissionOpenSettings));
    await tester.pumpAndSettle();
    expect(find.text(l10n.notifyTestPermissionOff), findsOneWidget);
  });

  testWidgets('an allowed grant fires a sample and reports a refusal', (
    tester,
  ) async {
    allowed = true;
    await pump(tester);
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));

    expect(find.text(l10n.notifyTestIntro), findsOneWidget);
    expect(find.text(l10n.notifySectionEarthquake), findsOneWidget);
    expect(find.text(l10n.notifySectionWeather), findsOneWidget);
    expect(find.text(l10n.notifySectionTsunami), findsOneWidget);
    expect(find.text(l10n.notifySectionOther), findsOneWidget);

    await tester.tap(find.byIcon(Icons.play_circle_outline).first);
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsWidgets);

    created = false;
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.play_circle_outline).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text(l10n.notifyTestFailed), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.play_circle_outline), findsWidgets);
  });
}
