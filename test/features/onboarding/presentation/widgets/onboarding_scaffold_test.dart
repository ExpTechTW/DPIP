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
}
