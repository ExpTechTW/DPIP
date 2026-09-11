/// The moon page's wiring: which instant it shows, and which place the rise
/// and set times belong to.
///
/// The astronomy is pinned in `test/core/astro/`; what is checked here is
/// everything between it and the screen — that the calendar and the timeline
/// address the same selection, and that a page which names a township names
/// the one it actually computed for.
library;

import 'package:dpip/core/astro/moon_phase.dart';
import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/core/realtime/app_time.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:dpip/core/settings/region_store.dart';
import 'package:dpip/features/data/presentation/pages/moon_page.dart';
import 'package:dpip/features/data/presentation/widgets/moon_calendar.dart';
import 'package:dpip/features/data/presentation/widgets/moon_glyph.dart';
import 'package:dpip/shared/map/map_timeline.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

final _directory = TownDirectory.fromJson({
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

Future<RegionStore> _regions({String? currentCode}) async {
  final store = RegionStore(SettingsStore.inMemory({}));
  if (currentCode != null) store.setCurrentCode(currentCode);
  return store;
}

Future<void> _pumpPage(WidgetTester tester, RegionStore regions) async {
  // Tall enough that the whole page is laid out — the sections and the
  // calendar live below a 400 px hero, and a lazy list would not build them.
  tester.view.physicalSize = const Size(800, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<TownDirectory>.value(value: _directory),
        ChangeNotifierProvider<RegionStore>.value(value: regions),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MoonPage(),
      ),
    ),
  );
  // The shader and the NASA maps load asynchronously; the rest of the page
  // does not wait on them, which is the point of pumping rather than settling.
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('opens on today and offers no jump-to-now', (tester) async {
    await _pumpPage(tester, await _regions(currentCode: '100'));

    final today = AppTime.utc8;
    expect(find.text('${today.day}'), findsWidgets);
    // The jump-back-to-now action only appears once the selection has left it.
    expect(find.byTooltip('Now'), findsNothing);
  });

  testWidgets('names the township the rise and set times are for', (
    tester,
  ) async {
    await _pumpPage(tester, await _regions(currentCode: '970'));
    expect(find.text('花蓮縣 花蓮市'), findsOneWidget);
  });

  testWidgets('falls back to a named township when location is unknown', (
    tester,
  ) async {
    // No GPS township: the page still has to say *where* the times apply, or
    // a rise time is just a number. The fallback is the nearest township to
    // Taipei, and it is named like any other.
    await _pumpPage(tester, await _regions());
    expect(find.text('臺北市 中正區'), findsOneWidget);
  });

  testWidgets('a calendar day moves the selection, and offers a way back', (
    tester,
  ) async {
    await _pumpPage(tester, await _regions(currentCode: '100'));

    final today = AppTime.utc8;
    // A day in the same month that is definitely not today.
    final other = today.day == 1 ? 2 : 1;
    await tester.tap(
      find.descendant(
        of: find.byType(MoonCalendar),
        matching: find.text('$other'),
      ),
    );
    await tester.pump();

    expect(
      find.byTooltip('Now'),
      findsOneWidget,
      reason: 'the selection left the present, so a way back appears',
    );

    await tester.tap(find.byTooltip('Now'));
    await tester.pump();
    expect(find.byTooltip('Now'), findsNothing);
  });

  testWidgets('shows distance, rise and set', (tester) async {
    await _pumpPage(tester, await _regions(currentCode: '100'));
    for (final label in ['Distance', 'Apparent size', 'Moonrise', 'Moonset']) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    // The distance is a grouped number of kilometres, never a bare double.
    //
    // Six digits, not "starts with a 3". The Moon's distance runs from about
    // 356,500 km at perigee to about 406,700 km at apogee, so a leading 3 is
    // true for most of a lunar month and false near apogee — which is a test
    // that passes for three weeks and fails in the fourth, on nobody's change.
    expect(find.textContaining(RegExp(r'^\d\d\d,\d\d\d km$')), findsOneWidget);
  });

  // The page memoises its astronomy — the calendar's per-day phase and the
  // two "next" searches — so a scrub tick stops re-solving a month of
  // ephemerides. Memoised must still mean *correct*: a glyph must carry its
  // own day's phase, and the readouts must follow the selection rather than
  // the first answer they cached.
  testWidgets('a calendar glyph carries its own day\'s noon phase', (
    tester,
  ) async {
    await _pumpPage(tester, await _regions(currentCode: '100'));

    final today = AppTime.utc8;
    // A day the page did not build first (the selected one), so a cache that
    // handed every cell the same value would be caught.
    final day = today.day == 15 ? 16 : 15;
    final cell = find.ancestor(
      of: find.descendant(
        of: find.byType(MoonCalendar),
        matching: find.text('$day'),
      ),
      matching: find.byType(Column),
    );
    final glyph = tester.widget<MoonGlyph>(
      find.descendant(of: cell.first, matching: find.byType(MoonGlyph)),
    );
    // Noon Taipei of that day, as the page defines a day's phase.
    final noon = DateTime.utc(
      today.year,
      today.month,
      day,
      12,
    ).subtract(const Duration(hours: 8));
    expect(glyph.angle, MoonPhase.angleAt(noon));
  });

  testWidgets('the next full moon follows the timeline selection', (
    tester,
  ) async {
    await _pumpPage(tester, await _regions(currentCode: '100'));

    final timeline = tester.widget<MapTimeline>(find.byType(MapTimeline));
    String stamp(DateTime utc) {
      final local = AppTime.taipei(utc);
      return '${DateFormat('M/d').format(local)} '
          '${DateFormat('HH:mm').format(local)}';
    }

    final before = stamp(
      MoonPhase.nextFullMoon(timeline.frames[timeline.selectedIndex].time),
    );
    expect(find.text(before), findsOneWidget);

    // Thirty days on — past one synodic month, so the answer must change.
    final target = timeline.selectedIndex + 30 * 12;
    timeline.onSelected(target);
    await tester.pump();

    final after = stamp(MoonPhase.nextFullMoon(timeline.frames[target].time));
    expect(after, isNot(before));
    expect(find.text(after), findsOneWidget);
    expect(find.text(before), findsNothing);
  });
}
