/// A failed request that shows neither its reason nor a retry leaves the user
/// staring at a blank card they cannot recover. The default headline and a
/// caller-supplied one are different failures, so both have to render.
library;

import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/widgets/error_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, ErrorView view) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: view),
    ),
  );
}

void main() {
  testWidgets('default headline, no detail, and no retry', (tester) async {
    await _pump(tester, const ErrorView());
    final l10n = AppLocalizations.of(tester.element(find.byType(ErrorView)));
    expect(find.text(l10n.commonError), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);
  });

  testWidgets('custom headline, detail, and a retry that fires once', (
    tester,
  ) async {
    var retries = 0;
    await _pump(
      tester,
      ErrorView(
        headline: 'Feed down',
        detail: 'timeout',
        icon: Icons.cloud_off,
        onRetry: () => retries++,
      ),
    );
    final l10n = AppLocalizations.of(tester.element(find.byType(ErrorView)));
    expect(find.text('Feed down'), findsOneWidget);
    expect(find.text('timeout'), findsOneWidget);
    expect(find.byIcon(Icons.cloud_off), findsOneWidget);
    await tester.tap(find.text(l10n.commonRetry));
    expect(retries, 1);
  });
}
