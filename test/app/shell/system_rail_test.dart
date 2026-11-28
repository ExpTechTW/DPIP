/// iPhone Duo's system rail: when it applies, the tab bar drawn down it, and
/// the same pill floated along the bottom edge. Insets are the measured iOS
/// 27.1 simulator values.
library;

import 'package:dpip/app/shell/system_rail.dart';
import 'package:dpip/shared/widgets/frosted_surface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// A pill cell by the label it carries in its tooltip. `find.byTooltip` only
/// matches `flutter/material`'s [Tooltip], and there are two Tooltip classes in
/// this app since the Material widgets come from `material_ui`.
Finder _cell(String label) => find.byWidgetPredicate(
  (widget) => widget is Tooltip && widget.message == label,
);

void main() {
  group('systemRailEdgeFor', () {
    test('outer display portrait: rail on the right', () {
      expect(
        systemRailEdgeFor(const EdgeInsets.only(right: 84, bottom: 34)),
        AxisDirection.right,
      );
    });

    test('outer display landscape: rail on the left', () {
      expect(
        systemRailEdgeFor(const EdgeInsets.only(left: 84, bottom: 21)),
        AxisDirection.left,
      );
    });

    test('a landscape phone notch is symmetric, not a rail', () {
      expect(
        systemRailEdgeFor(
          const EdgeInsets.only(left: 62, right: 62, bottom: 21),
        ),
        isNull,
      );
    });

    test('a top inset means the status bar is where it always is', () {
      expect(
        systemRailEdgeFor(const EdgeInsets.only(top: 59, right: 84)),
        isNull,
      );
    });
  });

  group('systemRailEdge', () {
    tearDown(() => debugAssumeFoldable = null);

    Future<AxisDirection?> edgeFor(WidgetTester tester) async {
      AxisDirection? edge;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(466, 678),
            viewPadding: EdgeInsets.only(right: 84, bottom: 34),
          ),
          child: Builder(
            builder: (context) {
              edge = systemRailEdge(context);
              return const SizedBox();
            },
          ),
        ),
      );
      return edge;
    }

    testWidgets('a foldable with the rail inset gets the rail', (tester) async {
      debugAssumeFoldable = true;
      expect(await edgeFor(tester), AxisDirection.right);
    });

    testWidgets('the same inset without a hinge does not', (tester) async {
      debugAssumeFoldable = false;
      expect(await edgeFor(tester), isNull);
    });

    testWidgets('no FoldableProvider reads as no hinge', (tester) async {
      expect(await edgeFor(tester), isNull);
    });
  });

  testWidgets('the tab bar sits at the bottom of the rail and switches tabs', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(84, 678);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(bottom: 34);
    tester.view.viewPadding = const FakeViewPadding(bottom: 34);
    addTearDown(tester.view.reset);

    var selected = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) => SystemRailTabBar(
            selectedIndex: selected,
            onDestinationSelected: (i) => setState(() => selected = i),
            destinations: const [
              NavigationDestination(icon: Icon(Icons.home), label: 'home'),
              NavigationDestination(icon: Icon(Icons.map), label: 'map'),
              NavigationDestination(icon: Icon(Icons.menu), label: 'more'),
            ],
          ),
        ),
      ),
    );

    // Pinned to the bottom, above the home indicator.
    final last = tester.getBottomLeft(find.byIcon(Icons.menu));
    expect(last.dy, greaterThan(678 - 34 - kSystemRailControlExtent));
    expect(last.dy, lessThan(678 - 34));
    expect(tester.getSize(_cell('map')).width, kSystemRailControlExtent);

    await tester.tap(_cell('map'));
    await tester.pump();
    expect(selected, 1);
  });

  testWidgets('the same pill along the bottom edge keeps its labels', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(bottom: 34);
    tester.view.viewPadding = const FakeViewPadding(bottom: 34);
    addTearDown(tester.view.reset);

    var selected = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: StatefulBuilder(
            builder: (context, setState) => FloatingTabBar(
              selectedIndex: selected,
              onDestinationSelected: (i) => setState(() => selected = i),
              destinations: const [
                NavigationDestination(icon: Icon(Icons.home), label: 'home'),
                NavigationDestination(icon: Icon(Icons.map), label: 'map'),
                NavigationDestination(icon: Icon(Icons.menu), label: 'more'),
              ],
            ),
          ),
        ),
      ),
    );

    // Floating, centred, and dipped 12 pt into the home-indicator strip.
    final pill = tester.getRect(find.byType(FrostedSurface));
    expect(pill.center.dx, closeTo(160, 0.01));
    expect(pill.bottom, closeTo(568 - 22, 0.01));
    expect(pill.top, greaterThan(568 / 2), reason: 'a pill, not a bar');

    // The bar reserves 8 pt above the pill — that is the gap the map's
    // observation card sits in, since the shell extends the body behind it.
    expect(
      tester.getTopLeft(find.byType(FloatingTabBar)).dy,
      closeTo(pill.top - 8, 0.01),
    );

    // No labels on screen — they are the tooltip and the semantics only.
    expect(find.text('home'), findsNothing);
    expect(tester.getSize(_cell('map')).width, kFloatingTabCellExtent);

    await tester.tap(_cell('map'));
    await tester.pump();
    expect(selected, 1);
  });
}
