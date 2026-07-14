import 'package:dpip/core/settings/region_store.dart';
import 'package:dpip/features/home/presentation/widgets/home_content.dart';
import 'package:dpip/features/home/presentation/widgets/home_sheet_header.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dpip/core/settings/prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pumps [HomeContent] with everything it reads: a [RegionStore] to switch on
/// and localizations for the body.
Widget _wrap(RegionStore store) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('en'),
  home: ChangeNotifierProvider<RegionStore>.value(
    value: store,
    child: Scaffold(body: HomeContent(scrollController: ScrollController())),
  ),
);

/// A store with two saved regions → four areas (全國, 所在地, +2), so the
/// switch tests have room to move (select(2) / next twice).
Future<RegionStore> _store() async {
  SharedPreferences.setMockInitialValues({
    'home.savedRegionCodes': ['100', '200'],
  });
  return RegionStore(Prefs(await SharedPreferences.getInstance()));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('renders the active area panel', (tester) async {
    await tester.pumpWidget(_wrap(await _store()));
    expect(find.byType(HomeSheetHeader), findsOneWidget);
  });

  testWidgets('switching area forward slides without a layout error', (
    tester,
  ) async {
    final store = await _store()
      ..select(0);
    await tester.pumpWidget(_wrap(store));

    store.next(); // 0 → 1
    await tester.pump(); // kick off the transition
    // Both the outgoing and incoming panels are mounted while it slides.
    expect(find.byType(HomeSheetHeader), findsNWidgets(2));
    await tester.pump(
      const Duration(milliseconds: 100),
    ); // still mid-slide (220ms)
    expect(find.byType(HomeSheetHeader), findsNWidgets(2));
    await tester.pumpAndSettle();

    // Settled: the outgoing panel is dropped, one panel remains.
    expect(find.byType(HomeSheetHeader), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('switching area backward settles cleanly', (tester) async {
    final store = await _store()
      ..select(2);
    await tester.pumpWidget(_wrap(store));

    store.previous(); // 2 → 1
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.byType(HomeSheetHeader), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('rapid switches settle to one panel', (tester) async {
    final store = await _store()
      ..select(0);
    await tester.pumpWidget(_wrap(store));

    store.next(); // 0 → 1
    await tester.pump(const Duration(milliseconds: 40));
    store.next(); // 1 → 2, interrupting the first slide
    await tester.pumpAndSettle();

    expect(find.byType(HomeSheetHeader), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
