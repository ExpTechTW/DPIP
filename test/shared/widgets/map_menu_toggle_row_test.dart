/// Overlay menus are settings panels: a row tap has to flip the overlay and
/// leave the menu open so the next row can be changed while the map updates.
/// A row that closes the menu makes the user reopen it for every toggle.
library;

import 'package:dpip/shared/widgets/map_chip_button.dart';
import 'package:dpip/shared/widgets/map_menu_toggle_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'a toggle keeps the menu open and a subtitle only shows when set',
    (tester) async {
      var borders = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return MenuAnchor(
                  style: MapChipButton.menuStyle(context),
                  menuChildren: [
                    MapMenuToggleRow(
                      selected: borders,
                      icon: Icons.border_outer,
                      title: 'Town borders',
                      subtitle: 'Draw the township outline',
                      tooltip: 'Town borders',
                      onTap: () => setState(() => borders = !borders),
                    ),
                    MapMenuToggleRow(
                      selected: false,
                      icon: Icons.radar,
                      title: 'Radar',
                      tooltip: 'Radar',
                      onTap: _noop,
                    ),
                  ],
                  builder: (context, controller, child) {
                    return MapChipButton(
                      icon: Icons.tune,
                      tooltip: 'Options',
                      active: borders,
                      onTap: () {
                        if (controller.isOpen) {
                          controller.close();
                        } else {
                          controller.open();
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.tune));
      await tester.pumpAndSettle();
      expect(find.text('Town borders'), findsOneWidget);
      expect(find.text('Draw the township outline'), findsOneWidget);
      expect(find.text('Radar'), findsOneWidget);

      await tester.tap(find.text('Town borders'));
      await tester.pumpAndSettle();
      expect(borders, isTrue);
      expect(find.text('Town borders'), findsOneWidget);
      expect(find.text('Radar'), findsOneWidget);
      expect(find.byIcon(Icons.check_box), findsOneWidget);
      expect(find.byIcon(Icons.check_box_outline_blank), findsWidgets);
    },
  );
}

void _noop() {}
