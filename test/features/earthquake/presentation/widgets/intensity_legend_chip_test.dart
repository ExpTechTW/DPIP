/// The intensity legend as the replay page mounts it — inside
/// [CollapsibleMapLegend], with the RTS/EEW mode swap *under* the collapse
/// wrap rather than around it.
///
/// The replay page is a full-screen map with no [MapScaffold], so it wires the
/// chip itself; this pins the two things that wiring decides. An eleven-row
/// scale left pinned open sits over the north-west of the island for the whole
/// replay, so it has to start collapsed — and an alert arriving mid-replay
/// swaps which scale is drawn, which must not throw away the user's choice to
/// have the legend open.
library;

import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/widgets/collapsible_map_legend.dart';
import 'package:dpip/shared/widgets/intensity_legend.dart';
import 'package:dpip/shared/widgets/map_color_legend.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mirrors the replay page's own subtree: a top-left overlay whose
/// `AnimatedSize` lays the legend out with unbounded width, and a listenable
/// standing in for the EEW feed that flips the scale.
Future<void> _pumpLegend(WidgetTester tester, ValueNotifier<bool> hasEew) {
  return tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('zh'),
      home: Scaffold(
        body: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: CollapsibleMapLegend(
                    legend: ListenableBuilder(
                      listenable: hasEew,
                      builder: (context, _) => MapLegendCard(
                        child: IntensityLegend(
                          mode: hasEew.value
                              ? IntensityLegendMode.eew
                              : IntensityLegendMode.rts,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  testWidgets('the replay legend starts collapsed and opens on tap', (
    tester,
  ) async {
    final hasEew = ValueNotifier(false);
    addTearDown(hasEew.dispose);
    await _pumpLegend(tester, hasEew);

    expect(
      find.byType(IntensityLegend),
      findsNothing,
      reason: 'the scale must not cover the island before it is asked for',
    );
    expect(find.byIcon(Icons.legend_toggle), findsOneWidget);

    await tester.tap(find.byIcon(Icons.legend_toggle));
    await _settle(tester);

    expect(tester.takeException(), isNull);
    expect(find.byType(IntensityLegend), findsOneWidget);
    // The continuous instrumental scale runs down to −3, which the discrete
    // felt scale has no row for — so this is the mode, not just "a legend".
    expect(find.text('-3'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.expand_less));
    await _settle(tester);
    expect(find.byType(IntensityLegend), findsNothing);
  });

  testWidgets('an alert arriving mid-replay swaps the scale without closing '
      'the legend the user opened', (tester) async {
    final hasEew = ValueNotifier(false);
    addTearDown(hasEew.dispose);
    await _pumpLegend(tester, hasEew);

    await tester.tap(find.byIcon(Icons.legend_toggle));
    await _settle(tester);
    expect(find.text('-3'), findsOneWidget);

    hasEew.value = true;
    await _settle(tester);

    expect(tester.takeException(), isNull);
    expect(
      find.byType(IntensityLegend),
      findsOneWidget,
      reason: 'the mode swap must not collapse the legend back to the chip',
    );
    // Now the discrete felt scale: 6⁺ exists here and nowhere on the
    // instrumental ramp, whose lowest rows (−3) are gone.
    expect(find.text('6⁺'), findsOneWidget);
    expect(find.text('-3'), findsNothing);
  });
}
