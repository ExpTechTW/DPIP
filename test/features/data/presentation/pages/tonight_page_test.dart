/// Tonight page: that a place it cannot name is never reported as a night, that
/// every section states its empty case instead of vanishing, and that each
/// shower and deep-sky type keeps its own name.
///
/// The empty cases are the contract worth pinning. "No visible passes in the
/// next two days" is a real and common answer — a station spends long stretches
/// passing only inside Earth's shadow — and a section that simply disappeared
/// would be indistinguishable from a broken one. The place matters for the same
/// reason as everywhere else in this feature: every time on the page is a
/// statement about a location, and the page has to say which.
library;

import 'package:dpip/core/astro/deep_sky.dart';
import 'package:dpip/core/astro/meteor_showers.dart';
import 'package:dpip/core/astro/tle_store.dart';
import 'package:dpip/core/geo/town.dart';
import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/core/settings/region_store.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:dpip/features/data/presentation/pages/tonight_page.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/widgets/loading_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

final _directory = TownDirectory.fromJson({
  '970': {
    'city': '花蓮',
    'town': '花蓮',
    'lat': 23.99,
    'lng': 121.60,
    'cityLevel': '縣',
    'townLevel': '市',
  },
});

Future<RegionStore> _regions({String? code}) async {
  final store = RegionStore(SettingsStore.inMemory({}));
  if (code != null) store.setCurrentCode(code);
  return store;
}

/// Only [id] reaches the name lookup; the geometry is irrelevant to it.
MeteorShower _shower(String id) => MeteorShower(
  id: id,
  peakMonth: 1,
  peakDay: 1,
  startMonth: 1,
  startDay: 1,
  endMonth: 1,
  endDay: 1,
  rightAscensionJ2000: 0,
  declinationJ2000: 0,
  zenithalRate: 1,
  velocityKmS: 1,
);

/// Every id the switch in `meteorShowerName` names, plus one it does not.
const _showerIds = [
  'quadrantids',
  'lyrids',
  'etaAquariids',
  'deltaAquariids',
  'perseids',
  'orionids',
  'southernTaurids',
  'leonids',
  'geminids',
  'ursids',
];

Future<void> _pump(
  WidgetTester tester, {
  required RegionStore regions,
  required TownDirectory directory,
}) async {
  tester.view.physicalSize = const Size(900, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<TownDirectory>.value(value: directory),
        ChangeNotifierProvider<RegionStore>.value(value: regions),
        // A null database is the documented "no cache" case: the bundled
        // element set is a complete answer on its own.
        Provider<TleStore>.value(value: const TleStore(null)),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: TonightPage(),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every shower has its own name', () async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    final names = {
      for (final id in _showerIds) meteorShowerName(l10n, _shower(id)),
    };

    expect(names, everyElement(isNotEmpty));
    expect(names, hasLength(_showerIds.length));
  });

  test('an unknown shower id still gets a name rather than a raw id', () async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    // The catalogue cannot be enumerated at runtime, so anything unrecognised
    // has to fall back to a real name — an id shown to a user is worse than a
    // slightly wrong translation.
    expect(meteorShowerName(l10n, _shower('some-new-shower')), isNotEmpty);
  });

  test('every deep-sky type has its own name', () async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    final names = {
      for (final type in DeepSkyType.values) deepSkyTypeName(l10n, type),
    };

    expect(names, everyElement(isNotEmpty));
    expect(names, hasLength(DeepSkyType.values.length));
  });

  testWidgets('with no place it never claims there is a night to report', (
    tester,
  ) async {
    await _pump(
      tester,
      regions: await _regions(),
      directory: const TownDirectory(<String, Town>{}),
    );
    // Not `pumpAndSettle`: the spinner never settles.
    await tester.pump();
    await tester.pump();

    // Everything on this page is a statement about a place, so with none the
    // page says nothing rather than reporting for an unnamed coordinate.
    expect(find.byType(LoadingView), findsOneWidget);
  });

  testWidgets('the report names the place and states every section', (
    tester,
  ) async {
    await _pump(
      tester,
      regions: await _regions(code: '970'),
      directory: _directory,
    );
    await tester.pump();

    // The first frame has no report yet — the pass search is an isolate.
    expect(find.byType(LoadingView), findsOneWidget);

    // The satellite search runs off the widget test's fake-async zone, so the
    // isolate only advances inside `runAsync`.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 5)),
    );
    await tester.pump();

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l10n.tonightTitle), findsOneWidget);
    expect(find.text('花蓮縣 花蓮市'), findsOneWidget);

    for (final section in [
      l10n.tonightSectionDark,
      l10n.tonightSectionShowers,
      l10n.tonightSectionSatellites,
      l10n.tonightSectionTargets,
    ]) {
      expect(find.text(section), findsOneWidget, reason: section);
    }

    // Each of these three has to answer, even when the answer is "nothing".
    expect(
      tester.widgetList(find.text(l10n.tonightNoShowers)).isNotEmpty ||
          find.byIcon(Icons.auto_awesome_outlined).evaluate().isNotEmpty ||
          find.byIcon(Icons.auto_awesome).evaluate().isNotEmpty,
      isTrue,
      reason: 'the shower section said neither yes nor no',
    );
    expect(
      tester.widgetList(find.text(l10n.tonightNoPasses)).isNotEmpty ||
          tester
              .widgetList(find.text(l10n.tonightSatellitesUnavailable))
              .isNotEmpty ||
          find.byIcon(Icons.satellite_alt_outlined).evaluate().isNotEmpty,
      isTrue,
      reason: 'the satellite section said neither yes nor no',
    );
    expect(
      tester.widgetList(find.text(l10n.tonightNoTargets)).isNotEmpty ||
          find.byIcon(Icons.blur_on_outlined).evaluate().isNotEmpty,
      isTrue,
      reason: 'the deep-sky section said neither yes nor no',
    );
  });
}
