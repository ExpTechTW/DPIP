import 'dart:async';

import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/widgets/async_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('en'),
  home: Scaffold(body: child),
);

void main() {
  testWidgets('pending → loading', (tester) async {
    final completer = Completer<Result<int>>();
    await tester.pumpWidget(
      _wrap(
        AsyncView<int>(
          future: completer.future,
          builder: (_, value) => Text('v $value'),
        ),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    completer.complete(const Ok(0)); // settle for a clean teardown
    await tester.pumpAndSettle();
  });

  testWidgets('Ok → builder', (tester) async {
    await tester.pumpWidget(
      _wrap(
        AsyncView<int>(
          future: Future.value(const Ok(5)),
          builder: (_, value) => Text('v $value'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('v 5'), findsOneWidget);
  });

  testWidgets('Ok but empty → empty state', (tester) async {
    await tester.pumpWidget(
      _wrap(
        AsyncView<List<int>>(
          future: Future.value(const Ok(<int>[])),
          isEmpty: (value) => value.isEmpty,
          builder: (_, _) => const Text('list'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Nothing to show'), findsOneWidget);
    expect(find.text('list'), findsNothing);
  });

  testWidgets('Err → error with a working retry', (tester) async {
    var retried = false;
    await tester.pumpWidget(
      _wrap(
        AsyncView<int>(
          future: Future.value(const Err(NetworkFailure('boom'))),
          builder: (_, value) => Text('v $value'),
          onRetry: () => retried = true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('boom'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    expect(retried, isTrue);
  });
}
