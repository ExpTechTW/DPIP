/// The overlay chip is how a layer's menu opens, and the dot is the only sign
/// that the options are no longer the defaults. A labelled chip that still
/// draws the dot covers the value, and a menu that cannot scroll drops the
/// last toggle off the bottom of the screen.
library;

import 'package:dpip/shared/widgets/map_chip_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'an active unlabelled chip draws the marker and reports the tap',
    (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final style = MapChipButton.menuStyle(context);
                expect(style.elevation?.resolve({}), 6);
                expect(
                  MapChipButton.rowStyle(const Color(0x11000000)).padding
                      ?.resolve({}),
                  EdgeInsets.zero,
                );
                return MapChipButton(
                  icon: Icons.tune,
                  tooltip: 'Layer options',
                  active: true,
                  onTap: () => taps++,
                );
              },
            ),
          ),
        ),
      );
      expect(find.byIcon(Icons.tune), findsOneWidget);
      final icon = tester.widget<Icon>(find.byIcon(Icons.tune));
      final primary = Theme.of(tester.element(find.byIcon(Icons.tune)))
          .colorScheme
          .primary;
      expect(icon.color, primary);
      expect(find.byType(Container), findsWidgets);
      await tester.tap(find.byIcon(Icons.tune));
      expect(taps, 1);
    },
  );

  testWidgets('a labelled chip shows the value and drops the marker dot', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MapChipButton(
            icon: Icons.water_drop_outlined,
            tooltip: 'Window',
            label: '1h',
            active: false,
            onTap: () {},
          ),
        ),
      ),
    );
    expect(find.text('1h'), findsOneWidget);
    final icon = tester.widget<Icon>(find.byIcon(Icons.water_drop_outlined));
    final colors = Theme.of(tester.element(find.byType(MapChipButton)))
        .colorScheme;
    expect(icon.color, colors.onSurfaceVariant);
    final dots = tester
        .widgetList<Container>(find.byType(Container))
        .where((container) => container.constraints?.maxWidth == 7);
    expect(dots, isEmpty);
  });

  testWidgets('a long menu scrolls and a divider separates the groups', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 200,
            child: MapMenuScrollView(
              children: [
                for (var i = 0; i < 12; i++) ...[
                  if (i == 4) const MapMenuDivider(),
                  SizedBox(height: 40, child: Text('row $i')),
                ],
              ],
            ),
          ),
        ),
      ),
    );
    expect(find.text('row 0'), findsOneWidget);
    expect(find.byType(Divider), findsOneWidget);
    await tester.scrollUntilVisible(find.text('row 11'), 80);
    expect(find.text('row 11'), findsOneWidget);
  });
}
