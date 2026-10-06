/// Four sheets share this chrome. A grip that stays visible when the sheet
/// is flush, or a flag that flips in the same frame as the drag, fights the
/// sheet's own layout.
library;

import 'package:dpip/shared/widgets/sheet_extent.dart';
import 'package:dpip/shared/widgets/sheet_surface.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('flush starts just under the top', () {
    expect(sheetExtentIsAtTop(1), isTrue);
    expect(sheetExtentIsAtTop(0.99), isTrue);
    expect(sheetExtentIsAtTop(0.97), isFalse);
  });

  testWidgets('the surface drops its radius and shadow when flush', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: SheetSurface(child: Text('card'))),
    );
    var box = tester.widget<DecoratedBox>(find.byType(DecoratedBox));
    expect((box.decoration as BoxDecoration).boxShadow, isNotNull);

    await tester.pumpWidget(
      const MaterialApp(
        home: SheetSurface(flushTop: true, child: Text('card')),
      ),
    );
    box = tester.widget<DecoratedBox>(find.byType(DecoratedBox));
    expect((box.decoration as BoxDecoration).boxShadow, isNull);
    expect((box.decoration as BoxDecoration).borderRadius, BorderRadius.zero);
  });

  testWidgets('the grip hides at the top, on the next frame', (tester) async {
    final extent = ValueNotifier(0.4);
    addTearDown(extent.dispose);
    await tester.pumpWidget(MaterialApp(home: SheetGrip(extent: extent)));
    expect(_grip, findsOneWidget);

    extent.value = 1;
    await tester.pump();
    await tester.pump();
    expect(_grip, findsNothing);
  });

  testWidgets('a flag derived from the extent flips after the frame', (
    tester,
  ) async {
    final extent = ValueNotifier(0.0);
    addTearDown(extent.dispose);
    await tester.pumpWidget(MaterialApp(home: _Flag(extent: extent)));
    expect(find.text('down'), findsOneWidget);

    extent.value = 0.9;
    await tester.pump();
    await tester.pump();
    expect(find.text('up'), findsOneWidget);

    final next = ValueNotifier(0.0);
    addTearDown(next.dispose);
    await tester.pumpWidget(MaterialApp(home: _Flag(extent: next)));
    await tester.pump();
    await tester.pump();
    expect(find.text('down'), findsOneWidget);
  });

  testWidgets('chrome tracks the sheet extent and restyles at the top', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final extent = ValueNotifier(0.3);
    addTearDown(extent.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(padding: EdgeInsets.only(top: 40)),
          child: ExtentSheetChrome(
            extent: extent,
            keyValue: 'a',
            initial: 0.4,
            min: 0.2,
            max: 1,
            snapSizes: const [0.4, 1],
            content: (context, controller) => ListView(
              controller: controller,
              children: const [Text('body')],
            ),
          ),
        ),
      ),
    );
    expect(find.text('body'), findsOneWidget);

    await tester.dragFrom(const Offset(200, 650), const Offset(0, -180));
    await tester.pump();
    expect(extent.value, greaterThan(0.3));

    extent.value = 1;
    await tester.pumpWidget(
      MaterialApp(
        home: ExtentSheetChrome(
          extent: extent,
          keyValue: 'b',
          initial: 1,
          min: 0.2,
          max: 1,
          snapSizes: const [],
          content: (_, _) => const Text('flush'),
        ),
      ),
    );
    expect(find.text('flush'), findsOneWidget);
  });
}

final _grip = find.byWidgetPredicate((widget) {
  if (widget is! Container) return false;
  final decoration = widget.decoration;
  return decoration is BoxDecoration &&
      decoration.borderRadius == BorderRadius.circular(2);
});

class _Flag extends StatefulWidget {
  const _Flag({required this.extent});

  final ValueNotifier<double> extent;

  @override
  State<_Flag> createState() => _FlagState();
}

class _FlagState extends State<_Flag> with SheetExtentFlag {
  @override
  ValueListenable<double> get sheetExtent => widget.extent;

  @override
  bool sheetFlagFrom(double extent) => extent > 0.5;

  @override
  Widget build(BuildContext context) => Text(sheetFlag ? 'up' : 'down');
}
