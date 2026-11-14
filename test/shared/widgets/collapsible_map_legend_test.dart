/// The legend starts as a chip so the top-left of the map stays clear. If a
/// tap does not expand it, or the collapse control leaves the body on screen,
/// the key the user asked for is either missing or stuck over the map.
library;

import 'package:dpip/core/settings/locale_config.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/widgets/collapsible_map_legend.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('expands to the body and collapses back to the chip', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: CollapsibleMapLegend(legend: Text('rainfall key')),
        ),
      ),
    );
    final l10n = AppLocalizations.of(
      tester.element(find.byType(CollapsibleMapLegend)),
    );
    expect(find.text(l10n.mapLegendExpand), findsOneWidget);
    expect(find.text('rainfall key'), findsNothing);

    await tester.tap(find.text(l10n.mapLegendExpand));
    await tester.pumpAndSettle();
    expect(find.text('rainfall key'), findsOneWidget);
    expect(find.byIcon(Icons.expand_less), findsOneWidget);

    await tester.tap(find.byIcon(Icons.expand_less));
    await tester.pumpAndSettle();
    expect(find.text('rainfall key'), findsNothing);
    expect(find.text(l10n.mapLegendExpand), findsOneWidget);
  });
}
