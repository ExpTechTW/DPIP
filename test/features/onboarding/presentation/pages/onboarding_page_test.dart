/// Onboarding is the only door into the app. A next button that stays on the
/// intro, or a finish that never marks the store complete, would trap a
/// first launch or let someone through without accepting the terms.
library;

import 'package:awesome_notifications/awesome_notifications_platform_interface.dart';
import 'package:dpip/core/geo/location_service.dart';
import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/core/notifications/notification_service.dart';
import 'package:dpip/core/permissions/permission_health.dart';
import 'package:dpip/core/settings/locale_controller.dart';
import 'package:dpip/core/settings/onboarding_store.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:dpip/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/navigation/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

const Size _tall = Size(400, 4000);

const _awesome = MethodChannel('awesome_notifications');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  setUp(() {
    AwesomeNotificationsPlatform.operatingSystem = 'ios';
    AwesomeNotificationsPlatform.resetInstance();
    messenger.setMockMethodCallHandler(_awesome, (call) async => false);
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(_awesome, null);
    AwesomeNotificationsPlatform.operatingSystem = 'macos';
    AwesomeNotificationsPlatform.resetInstance();
  });

  testWidgets('next, agree, back, then skip finishes onboarding', (
    tester,
  ) async {
    tester.view.physicalSize = _tall;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final settings = SettingsStore.inMemory();
    final onboarding = OnboardingStore(settings);
    final notifications = NotificationService(settings);
    final location = LocationService(const TownDirectory({}));
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const OnboardingPage()),
        GoRoute(
          name: AppRoutes.home,
          path: '/home',
          builder: (_, _) => const Scaffold(body: Text('home-tab')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: onboarding),
          ChangeNotifierProvider(create: (_) => LocaleController(settings)),
          Provider.value(value: notifications),
          Provider.value(value: location),
          ChangeNotifierProvider(
            create: (_) => PermissionHealth(
              location: location,
              notifications: notifications,
            ),
          ),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l10n.onboardingIntroTitle), findsOneWidget);

    await tester.tap(find.text(l10n.onboardingNext));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text(l10n.onboardingTermsTitle), findsOneWidget);
    await tester.drag(find.byType(Scrollable).last, const Offset(0, -8000));
    await tester.pump();

    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await tester.tap(find.text(l10n.onboardingAgreeContinue));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text(l10n.onboardingPermsTitle), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text(l10n.onboardingTermsTitle), findsOneWidget);

    await tester.tap(find.text(l10n.onboardingAgreeContinue));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text(l10n.onboardingStart));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text(l10n.onboardingSkipTitle), findsOneWidget);
    await tester.tap(find.text(l10n.onboardingSkipLeave));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(onboarding.isComplete, isTrue);
    expect(find.text('home-tab'), findsOneWidget);
  });
}
