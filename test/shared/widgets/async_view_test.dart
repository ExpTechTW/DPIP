import 'package:dpip/core/settings/locale_config.dart';

import 'dart:async';

import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/realtime/app_time.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/navigation/refresh_on_appear.dart';
import 'package:dpip/shared/widgets/async_view.dart';
import 'package:dpip/shared/widgets/freshness_banner.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(
  localizationsDelegates: appLocalizationsDelegates,
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

  testWidgets('refreshSignal re-runs the request', (tester) async {
    final signal = RefreshSignal();
    var calls = 0;
    await tester.pumpWidget(
      _wrap(
        AsyncView<int>(
          refreshSignal: signal,
          future: () async => Ok(++calls),
          builder: (_, value) => Text('v $value'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('v 1'), findsOneWidget);

    signal.fire();
    await tester.pumpAndSettle();
    expect(find.text('v 2'), findsOneWidget);
  });

  testWidgets('a refresh keeps the current content on screen', (tester) async {
    final signal = RefreshSignal();
    var calls = 0;
    late Completer<Result<int>> pending;
    await tester.pumpWidget(
      _wrap(
        AsyncView<int>(
          refreshSignal: signal,
          future: () {
            calls++;
            if (calls == 1) return Future.value(const Ok(1));
            return (pending = Completer<Result<int>>()).future;
          },
          builder: (_, value) => Text('v $value'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    signal.fire();
    await tester.pump();
    // Refreshing on every appearance would be intolerable if it blanked the
    // screen each time, so the old value stays until the new one lands.
    expect(find.text('v 1'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    pending.complete(const Ok(2));
    await tester.pumpAndSettle();
    expect(find.text('v 2'), findsOneWidget);
  });

  group('a saved copy', () {
    // Ages are built from AppTime, the clock the banner measures them with.
    testWidgets('renders under a banner with its age, never as current', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          AsyncView<int>(
            future: () => Future.value(
              Ok(
                5,
                stale: Staleness(
                  failure: const NetworkFailure('No connection'),
                  since: AppTime.utc.subtract(const Duration(minutes: 20)),
                ),
              ),
            ),
            builder: (_, value) => ListView(children: [Text('v $value')]),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('v 5'), findsOneWidget);
      expect(
        find.text("Can't connect · showing data from 20 minutes ago"),
        findsOneWidget,
      );
    });

    testWidgets('of unknown age still says it is saved', (tester) async {
      await tester.pumpWidget(
        _wrap(
          AsyncView<int>(
            future: () => Future.value(
              const Ok(
                5,
                stale: Staleness(failure: NetworkFailure('No connection')),
              ),
            ),
            builder: (_, value) => Text('v $value'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text("Can't connect · showing saved data"), findsOneWidget);
    });

    testWidgets('keeps its banner while a refresh is in flight', (
      tester,
    ) async {
      final refresh = ChangeNotifier();
      addTearDown(refresh.dispose);
      var calls = 0;
      final pending = Completer<Result<int>>();
      await tester.pumpWidget(
        _wrap(
          AsyncView<int>(
            refreshSignal: refresh,
            future: () => calls++ == 0
                ? Future.value(
                    const Ok(
                      5,
                      stale: Staleness(failure: NetworkFailure('down')),
                    ),
                  )
                : pending.future,
            builder: (_, value) => Text('v $value'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      refresh.notifyListeners();
      await tester.pump();
      expect(find.text('v 5'), findsOneWidget);
      expect(find.byType(FreshnessBanner), findsOneWidget);

      pending.complete(const Ok(6));
      await tester.pumpAndSettle();
      expect(find.text('v 6'), findsOneWidget);
      expect(find.byType(FreshnessBanner), findsNothing);
    });
  });

  group('pull to refresh', () {
    /// A list of one line, short enough that only always-scrollable physics
    /// lets it be pulled.
    Widget list(int value) => ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [Text('v $value')],
    );

    Future<void> pull(WidgetTester tester, Finder target) async {
      await tester.fling(target, const Offset(0, 400), 1000);
      // Past the drag and the indicator's snap, into its refresh phase.
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
    }

    testWidgets('re-runs the request and ends when the result lands', (
      tester,
    ) async {
      var calls = 0;
      late Completer<Result<int>> pending;
      await tester.pumpWidget(
        _wrap(
          AsyncView<int>(
            pullToRefresh: true,
            future: () {
              calls++;
              if (calls == 1) return Future.value(const Ok(1));
              return (pending = Completer<Result<int>>()).future;
            },
            builder: (_, value) => list(value),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await pull(tester, find.text('v 1'));
      expect(calls, 2);
      // The content stays under the indicator while the request is out.
      expect(find.text('v 1'), findsOneWidget);
      expect(find.byType(RefreshProgressIndicator), findsOneWidget);

      // The same value again, as a 304 served from the cache reads.
      pending.complete(const Ok(1));
      await tester.pumpAndSettle();
      expect(find.text('v 1'), findsOneWidget);
      expect(find.byType(RefreshProgressIndicator), findsNothing);
    });

    testWidgets('a failed pull still ends the indicator', (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        _wrap(
          AsyncView<int>(
            pullToRefresh: true,
            future: () async => ++calls == 1
                ? const Ok(1)
                : const Err<int>(NetworkFailure('offline')),
            builder: (_, value) => list(value),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await pull(tester, find.text('v 1'));
      await tester.pumpAndSettle();
      expect(calls, 2);
      expect(find.byType(RefreshProgressIndicator), findsNothing);
    });

    testWidgets('an empty result can be pulled', (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        _wrap(
          AsyncView<List<int>>(
            pullToRefresh: true,
            future: () async => Ok(++calls == 1 ? const <int>[] : const [7]),
            isEmpty: (value) => value.isEmpty,
            builder: (_, value) => list(value.single),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      expect(find.text(l10n.commonEmpty), findsOneWidget);

      await pull(tester, find.text(l10n.commonEmpty));
      await tester.pumpAndSettle();
      expect(calls, 2);
      expect(find.text('v 7'), findsOneWidget);
    });

    testWidgets('is off unless asked for', (tester) async {
      await tester.pumpWidget(
        _wrap(
          AsyncView<int>(
            future: () async => const Ok(1),
            builder: (_, value) => list(value),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(RefreshIndicator), findsNothing);
    });
  });
}
