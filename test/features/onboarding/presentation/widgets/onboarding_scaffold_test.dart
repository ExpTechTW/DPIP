import 'package:dpip/features/onboarding/presentation/widgets/onboarding_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('gates the action until the content is scrolled to the end', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        OnboardingScaffold(
          // Taller than the viewport, so it must be scrolled.
          child: const SizedBox(height: 4000, child: Text('terms')),
          actionBuilder: (context, atEnd) => FilledButton(
            onPressed: atEnd ? () {} : null,
            child: Text(atEnd ? 'ready' : 'scroll'),
          ),
        ),
      ),
    );
    await tester.pump();

    // Not yet scrolled → disabled.
    expect(find.text('scroll'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );

    // Scroll to the bottom → the action unlocks.
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -5000),
    );
    await tester.pumpAndSettle();
    expect(find.text('ready'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
  });

  testWidgets('content that fits is immediately at the end', (tester) async {
    await tester.pumpWidget(
      _wrap(
        OnboardingScaffold(
          child: const Text('short'),
          actionBuilder: (context, atEnd) => FilledButton(
            onPressed: atEnd ? () {} : null,
            child: const Text('go'),
          ),
        ),
      ),
    );
    await tester.pump(); // let the post-frame scroll check run

    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
  });

  testWidgets('re-checks when content shrinks to fit (e.g. language switch)', (
    tester,
  ) async {
    Widget scaffold(double height) => _wrap(
      OnboardingScaffold(
        child: SizedBox(height: height, child: const Text('terms')),
        actionBuilder: (context, atEnd) => FilledButton(
          onPressed: atEnd ? () {} : null,
          child: const Text('go'),
        ),
      ),
    );

    // Tall content overflows the viewport → must scroll → locked.
    await tester.pumpWidget(scaffold(4000));
    await tester.pump();
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );

    // Content shrinks to fit (a shorter-language terms body). No scroll event
    // fires, so the scaffold must re-evaluate after layout and unlock.
    await tester.pumpWidget(scaffold(50));
    await tester.pumpAndSettle();
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
      reason: 'content that now fits must unlock without a scroll',
    );
  });

  testWidgets('a tablet keeps the body and the action to one measure', (
    tester,
  ) async {
    // An iPad in portrait. Unconstrained, the step's column and the call to
    // action each stretched the full 1032 pt: the permission cards put their
    // 授權 button half a screen from the sentence explaining it, and 開始使用
    // became a button wider than any thumb travels.
    tester.view.devicePixelRatio = 2;
    tester.view.physicalSize = const Size(2064, 2752);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      _wrap(
        OnboardingScaffold(
          child: const Text('body'),
          actionBuilder: (context, atEnd) =>
              FilledButton(onPressed: () {}, child: const Text('go')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final screen = tester.getSize(find.byType(OnboardingScaffold)).width;
    final action = tester.getRect(find.byType(FilledButton));
    expect(screen, greaterThan(1000), reason: 'the tablet width under test');
    expect(action.width, lessThanOrEqualTo(560));
    // Centred, not left-aligned against a sea of empty space.
    expect(action.center.dx, closeTo(screen / 2, 0.5));
  });

  testWidgets('re-checks when new window metrics make the content fit', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 2;
    tester.view.physicalSize = const Size(800, 1000);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      _wrap(
        OnboardingScaffold(
          child: const SizedBox(height: 700, child: Text('terms')),
          actionBuilder: (context, atEnd) => FilledButton(
            onPressed: atEnd ? () {} : null,
            child: const Text('go'),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );

    // Android can update logical window metrics after the first layout when
    // display size/DPI or system insets settle. This changes scroll extents
    // without changing the widget, and therefore does not call
    // didUpdateWidget or the ScrollController's pixel listener.
    tester.view.devicePixelRatio = 1;
    await tester.pumpAndSettle();

    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
      reason: 'an unscrollable body must never remain gated',
    );
  });
}
