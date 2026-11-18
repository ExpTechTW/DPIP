/// iPhone Duo's system rail: when it applies, and the vertical tab bar drawn
/// down it. Insets are the measured iOS 27.1 simulator values.
library;

import 'package:dpip/app/shell/system_rail.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

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
    expect(tester.getSize(find.byTooltip('map')).width, 48);

    await tester.tap(find.byTooltip('map'));
    await tester.pump();
    expect(selected, 1);
  });
}
