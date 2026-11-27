import 'package:dpip/core/geo/location_mode.dart';
import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/core/settings/locale_config.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:dpip/features/location/presentation/pages/location_mode_page.dart';
import 'package:dpip/features/location/presentation/pages/location_town_picker_page.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/navigation/app_routes.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

final TownDirectory _towns = TownDirectory.fromJson({
  '100': {
    'city': '臺北',
    'town': '中正',
    'lat': 25.03,
    'lng': 121.52,
    'cityLevel': '市',
    'townLevel': '區',
  },
  '970': {
    'city': '花蓮',
    'town': '花蓮',
    'lat': 23.99,
    'lng': 121.60,
    'cityLevel': '縣',
    'townLevel': '市',
  },
});

late AppLocalizations _l10n;

Future<LocationMode> _pump(WidgetTester tester, {LocationMode? mode}) async {
  tester.view.physicalSize = const Size(800, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final locationMode = mode ?? LocationMode(SettingsStore.inMemory({}), _towns);
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const LocationModePage(),
        routes: [
          GoRoute(
            name: AppRoutes.locationModeTown,
            path: 'town',
            builder: (_, _) => const LocationTownPickerPage(),
          ),
        ],
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<TownDirectory>.value(value: _towns),
        ChangeNotifierProvider<LocationMode>.value(value: locationMode),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        locale: const Locale('en'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return locationMode;
}

/// The continue button of the warning, which only works once acknowledged.
Finder _continue() =>
    find.widgetWithText(TextButton, _l10n.locationModeWarningContinue);

/// A township set by hand decides every alert the device gets, so it sits
/// behind a warning the user has to acknowledge, and the way back to automatic
/// is never more than a tap away.
void main() {
  setUpAll(() async {
    _l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  testWidgets(
    'choosing manual warns first; keeping automatic changes nothing',
    (tester) async {
      final mode = await _pump(tester);
      expect(mode.isManual, isFalse);

      await tester.tap(find.text(_l10n.locationModeManual));
      await tester.pumpAndSettle();
      expect(find.text(_l10n.locationModeWarningTitle), findsOneWidget);
      expect(
        tester.widget<TextButton>(_continue()).onPressed,
        isNull,
        reason: 'it must not proceed before the warning is acknowledged',
      );

      await tester.tap(find.text(_l10n.locationModeKeepAuto));
      await tester.pumpAndSettle();
      expect(find.text(_l10n.locationModeWarningTitle), findsNothing);
      expect(find.text(_l10n.locationModePickTownTitle), findsNothing);
      expect(mode.isManual, isFalse);
    },
  );

  testWidgets(
    'an acknowledged warning leads to the picker, which pins a town',
    (tester) async {
      final mode = await _pump(tester);

      await tester.tap(find.text(_l10n.locationModeManual));
      await tester.pumpAndSettle();
      await tester.tap(find.text(_l10n.locationModeWarningAcknowledge));
      await tester.pumpAndSettle();
      await tester.tap(_continue());
      await tester.pumpAndSettle();

      expect(find.text(_l10n.locationModePickTownTitle), findsOneWidget);
      await tester.tap(find.text('花蓮縣'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('花蓮市'));
      await tester.pumpAndSettle();

      expect(mode.manualTown?.code, '970');
      expect(
        find.text(_l10n.locationModeManualBanner('花蓮縣 花蓮市')),
        findsOneWidget,
      );
      expect(find.text(_l10n.locationModeSwitchToAuto), findsOneWidget);
    },
  );

  testWidgets('the banner switches back to automatic', (tester) async {
    final mode = LocationMode(SettingsStore.inMemory({}), _towns);
    await mode.setManual(_towns.byCode('100')!);
    await _pump(tester, mode: mode);

    await tester.tap(find.text(_l10n.locationModeSwitchToAuto));
    await tester.pumpAndSettle();

    expect(mode.isManual, isFalse);
    expect(find.text(_l10n.locationModeSwitchedToAuto), findsOneWidget);
    expect(find.text(_l10n.locationModeSwitchToAuto), findsNothing);
  });

  testWidgets('the picker finds a township by search', (tester) async {
    final mode = LocationMode(SettingsStore.inMemory({}), _towns);
    await mode.setManual(_towns.byCode('100')!);
    await _pump(tester, mode: mode);

    // Already manual: changing the township needs no second warning.
    await tester.tap(find.text(_l10n.locationModeChangeTown));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '花蓮市');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, '花蓮市'));
    await tester.pumpAndSettle();

    expect(mode.manualTown?.code, '970');
  });
}
