/// The colour key is what a painted pixel means. A gradient that prints units
/// on every stop, a banded scale that labels the below-threshold band, or a
/// line sample that drops its dash, would make the legend disagree with the
/// layer it is keyed to.
library;

import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/widgets/map_color_legend.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  testWidgets('a continuous scale labels every stop and the unit once', (
    tester,
  ) async {
    await _pump(
      tester,
      const MapLegendCard(
        child: ColorScaleLegend(
          unit: 'mm',
          stops: [(0, '#000000'), (10.5, '#ff0000'), (20, 'not-a-colour')],
        ),
      ),
    );
    expect(find.text('20'), findsOneWidget);
    expect(find.text('10.5'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
    final l10n = AppLocalizations.of(
      tester.element(find.byType(ColorScaleLegend)),
    );
    expect(find.text(l10n.mapLegendUnit('mm')), findsOneWidget);
  });

  testWidgets('a banded scale labels boundaries and skips the lowest band', (
    tester,
  ) async {
    await _pump(
      tester,
      const ColorScaleLegend(
        banded: true,
        stops: [(0, '#111111'), (40, '#888888'), (80, '#eeeeee')],
      ),
    );
    expect(find.text('80'), findsOneWidget);
    expect(find.text('40'), findsOneWidget);
    expect(find.text('0'), findsNothing);
    expect(find.byType(ColoredBox), findsAtLeastNWidgets(3));
  });

  testWidgets('symbol rows, a ringed dot, and solid, cased, and dashed lines', (
    tester,
  ) async {
    await _pump(
      tester,
      const SymbolLegend(
        unit: 'm/s',
        items: [
          SymbolLegendItem(
            swatch: LegendDot(color: Color(0xFF1565C0)),
            label: 'Light',
          ),
          SymbolLegendItem(
            swatch: LegendDot(color: Color(0xFFC62828), borderWidth: 1),
            label: 'Storm',
          ),
          SymbolLegendItem(
            swatch: LineSwatch(color: Color(0xFF212121)),
            label: 'Solid',
          ),
          SymbolLegendItem(
            swatch: LineSwatch(
              color: Color(0xFF212121),
              casingColor: Color(0xFFFFFFFF),
              casingWidth: 3,
              dash: [2, 1],
            ),
            label: 'Dashed',
          ),
        ],
      ),
    );
    expect(find.text('Light'), findsOneWidget);
    expect(find.text('Storm'), findsOneWidget);
    expect(find.text('Solid'), findsOneWidget);
    expect(find.text('Dashed'), findsOneWidget);
    expect(find.byType(CustomPaint), findsAtLeastNWidgets(2));
    final l10n = AppLocalizations.of(tester.element(find.byType(SymbolLegend)));
    expect(find.text(l10n.mapLegendUnit('m/s')), findsOneWidget);

    await _pump(
      tester,
      const SymbolLegend(
        items: [
          SymbolLegendItem(
            swatch: LegendDot(color: Color(0xFF000000)),
            label: 'Only',
          ),
        ],
      ),
    );
    expect(find.text('Only'), findsOneWidget);
    expect(find.textContaining('Unit'), findsNothing);
  });
}
