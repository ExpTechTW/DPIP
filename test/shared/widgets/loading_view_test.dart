/// A waiting row that draws a full-screen label, or a full-screen spinner that
/// forgets its label, makes every feature invent its own loading chrome. Both
/// sizes, and a caller colour, have to stay the shared widgets.
library;

import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/widgets/loading_view.dart';
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
  testWidgets('LoadingView uses the default label, or a caller one', (
    tester,
  ) async {
    await _pump(tester, const LoadingView());
    final l10n = AppLocalizations.of(tester.element(find.byType(LoadingView)));
    expect(find.text(l10n.commonLoading), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await _pump(tester, const LoadingView(label: 'Fetching radar'));
    expect(find.text('Fetching radar'), findsOneWidget);
    expect(find.text(l10n.commonLoading), findsNothing);
  });

  testWidgets('InlineLoading takes the given size and colour', (tester) async {
    await _pump(
      tester,
      const InlineLoading(size: 16, color: Color(0xFF112233)),
    );
    final box = tester.widget<SizedBox>(find.byType(SizedBox));
    expect(box.width, 16);
    expect(box.height, 16);
    final spinner = tester.widget<CircularProgressIndicator>(
      find.byType(CircularProgressIndicator),
    );
    expect(spinner.color, const Color(0xFF112233));
    expect(spinner.strokeWidth, 2);
  });
}
