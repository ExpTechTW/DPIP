import 'package:dpip/core/settings/area_selection.dart';
import 'package:dpip/features/home/presentation/widgets/home_content.dart';
import 'package:dpip/features/home/presentation/widgets/home_sheet_header.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// Pumps [HomeContent] with everything it reads: an [AreaSelection] to switch
/// on and localizations for the weather header.
Widget _wrap(AreaSelection areas) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('en'),
  home: ChangeNotifierProvider<AreaSelection>.value(
    value: areas,
    child: Scaffold(body: HomeContent(scrollController: ScrollController())),
  ),
);

void main() {
  testWidgets('renders the active area panel', (tester) async {
    await tester.pumpWidget(_wrap(AreaSelection()));
    expect(find.byType(HomeSheetHeader), findsOneWidget);
  });

  testWidgets('switching area forward slides without a layout error', (
    tester,
  ) async {
    final areas = AreaSelection();
    await tester.pumpWidget(_wrap(areas));

    areas.next(); // 0 → 1
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
    final areas = AreaSelection()..select(2);
    await tester.pumpWidget(_wrap(areas));

    areas.previous(); // 2 → 1
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.byType(HomeSheetHeader), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('rapid switches settle to one panel', (tester) async {
    final areas = AreaSelection();
    await tester.pumpWidget(_wrap(areas));

    areas.next(); // 0 → 1
    await tester.pump(const Duration(milliseconds: 40));
    areas.next(); // 1 → 2, interrupting the first slide
    await tester.pumpAndSettle();

    expect(find.byType(HomeSheetHeader), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
