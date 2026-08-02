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
          future: () => completer.future,
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
          future: () => Future.value(const Ok(5)),
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
          future: () => Future.value(const Ok(<int>[])),
          isEmpty: (value) => value.isEmpty,
          builder: (_, _) => const Text('list'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Nothing to show'), findsOneWidget);
    expect(find.text('list'), findsNothing);
  });

  testWidgets('Err → friendly message + retry re-runs the request', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      _wrap(
        AsyncView<int>(
          future: () async {
            calls++;
            return calls == 1 ? const Err(NetworkFailure('boom')) : const Ok(7);
          },
          builder: (_, value) => Text('v $value'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text("Couldn't load data. Please try again."), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('boom'), findsNothing, reason: 'raw detail is not shown');

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(
      find.text('v 7'),
      findsOneWidget,
      reason: 'retry re-ran the factory',
    );
  });

  testWidgets('refreshable: a pull re-runs the request', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      _wrap(
        AsyncView<int>(
          refreshable: true,
          future: () async => Ok(++calls),
          builder: (_, value) => ListView(
            children: [SizedBox(height: 600, child: Text('v $value'))],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('v 1'), findsOneWidget);

    await tester.fling(find.byType(ListView), const Offset(0, 320), 1000);
    await tester.pumpAndSettle();

    expect(calls, 2, reason: 'the pull should re-run the request');
    expect(find.text('v 2'), findsOneWidget);
  });

  testWidgets('refreshable: content stays on screen while refreshing', (
    tester,
  ) async {
    var calls = 0;
    late Completer<Result<int>> pending;
    await tester.pumpWidget(
      _wrap(
        AsyncView<int>(
          refreshable: true,
          future: () {
            calls++;
            if (calls == 1) return Future.value(const Ok(1));
            return (pending = Completer<Result<int>>()).future;
          },
          builder: (_, value) => ListView(
            children: [SizedBox(height: 600, child: Text('v $value'))],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.fling(find.byType(ListView), const Offset(0, 320), 1000);
    // The indicator invokes onRefresh only after its snap settles, so pump
    // frames until the second request is actually in flight.
    for (var i = 0; i < 20 && calls < 2; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(calls, 2, reason: 'the pull should have started a second request');

    // Mid-refresh the old value is still shown — pulling to check for news must
    // not first take away the news you already had.
    expect(find.text('v 1'), findsOneWidget);

    pending.complete(const Ok(2));
    await tester.pumpAndSettle();
    expect(find.text('v 2'), findsOneWidget);
  });

  testWidgets('refreshable: the empty state can be pulled too', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      _wrap(
        AsyncView<List<int>>(
          refreshable: true,
          future: () async {
            calls++;
            return const Ok(<int>[]);
          },
          isEmpty: (v) => v.isEmpty,
          builder: (_, _) => const SizedBox.shrink(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // An empty feed after a dropped connection looks exactly like a quiet one,
    // so the gesture has to work here — the state is otherwise unscrollable.
    await tester.fling(
      find.byType(SingleChildScrollView),
      const Offset(0, 320),
      1000,
    );
    await tester.pumpAndSettle();
    expect(calls, 2);
  });

  testWidgets('not refreshable by default: no indicator, no pull', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      _wrap(
        AsyncView<int>(
          future: () async => Ok(++calls),
          builder: (_, value) => ListView(
            children: [SizedBox(height: 600, child: Text('v $value'))],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(RefreshIndicator), findsNothing);

    await tester.fling(find.byType(ListView), const Offset(0, 320), 1000);
    await tester.pumpAndSettle();
    expect(calls, 1);
  });
}
