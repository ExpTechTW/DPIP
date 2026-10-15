/// Malformed deep links: every parameterised route turns a link it cannot
/// honour into the nearest page that can, instead of throwing from its builder.
///
/// The router here mirrors the shape of `appRouter`'s parameterised routes —
/// same names, same paths, the same redirect functions — with stand-in pages,
/// so a test can follow a real navigation without bootstrapping every feature.
/// `app_router_test.dart` separately runs the real table's builders and
/// redirects against malformed parameters.
library;

import 'package:dpip/app/router/route_params.dart';
import 'package:dpip/shared/navigation/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

GoRouter _router(String initialLocation) => GoRouter(
  initialLocation: initialLocation,
  routes: [
    GoRoute(
      path: AppRoutes.dataPath,
      name: AppRoutes.data,
      builder: (_, _) => const Text('data'),
      routes: [
        GoRoute(
          path: AppRoutes.earthquakePath,
          name: AppRoutes.earthquake,
          builder: (_, _) => const Text('reports'),
          routes: [
            GoRoute(
              path: AppRoutes.earthquakeReportPath,
              name: AppRoutes.earthquakeReport,
              redirect: reportRedirect,
              builder: (_, state) =>
                  Text('report ${state.pathParameters['id']}'),
              routes: [
                GoRoute(
                  path: AppRoutes.earthquakeReplayPath,
                  name: AppRoutes.earthquakeReplay,
                  redirect: replayRedirect,
                  builder: (_, state) =>
                      Text('replay ${replayTimestampOf(state)}'),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: AppRoutes.regionSelectPath,
      name: AppRoutes.regionSelect,
      builder: (_, state) => Text('cities ${state.uri.query}'),
      routes: [
        GoRoute(
          path: AppRoutes.regionSelectCityPath,
          name: AppRoutes.regionSelectCity,
          redirect: regionCityRedirect,
          builder: (_, state) => Text('city ${state.pathParameters['city']}'),
        ),
      ],
    ),
    GoRoute(
      path: AppRoutes.bugTrackerPath,
      name: AppRoutes.bugTracker,
      builder: (_, _) => const Text('threads'),
      routes: [
        GoRoute(
          path: AppRoutes.bugThreadPath,
          name: AppRoutes.bugThread,
          redirect: bugThreadRedirect,
          builder: (_, state) => Text('thread ${bugThreadIdOf(state)}'),
        ),
      ],
    ),
  ],
);

Future<void> _open(WidgetTester tester, String location) async {
  await tester.pumpWidget(MaterialApp.router(routerConfig: _router(location)));
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

void main() {
  group('positiveIntParam', () {
    test('reads a positive integer, ignoring surrounding space', () {
      expect(positiveIntParam('1700000000000'), 1700000000000);
      expect(positiveIntParam(' 42 '), 42);
    });

    test('is null for anything that is not one', () {
      for (final raw in [null, '', '  ', 'abc', '12abc', '1.5', '0', '-3']) {
        expect(positiveIntParam(raw), isNull, reason: '"$raw"');
      }
      // Beyond 64 bits: tryParse refuses it rather than wrapping around.
      expect(positiveIntParam('99999999999999999999999'), isNull);
    });
  });

  test('nonBlankParam keeps text and drops blanks', () {
    expect(nonBlankParam('臺北市'), '臺北市');
    expect(nonBlankParam(null), isNull);
    expect(nonBlankParam(''), isNull);
    expect(nonBlankParam(' \t'), isNull);
  });

  group('the replay link', () {
    testWidgets('with a start instant opens the replay', (tester) async {
      await _open(tester, '/data/earthquake/114001/replay?t=1700000000000');
      expect(find.text('replay 1700000000000'), findsOneWidget);
    });

    for (final query in ['', '?t=', '?t=abc', '?t=-5', '?t=0', '?t=1.5']) {
      testWidgets('without a usable t ("$query") opens its report', (
        tester,
      ) async {
        await _open(tester, '/data/earthquake/114001/replay$query');
        expect(find.text('report 114001'), findsOneWidget);
      });
    }
  });

  testWidgets('a blank report id opens the catalogue', (tester) async {
    await _open(tester, '/data/earthquake/%20');
    expect(find.text('reports'), findsOneWidget);
  });

  group('the bug thread link', () {
    testWidgets('with a thread number opens the thread', (tester) async {
      await _open(tester, '/bug-tracker/thread/17');
      expect(find.text('thread 17'), findsOneWidget);
    });

    for (final id in ['abc', '0', '-1', '%20']) {
      testWidgets('with "$id" opens the thread list', (tester) async {
        await _open(tester, '/bug-tracker/thread/$id');
        expect(find.text('threads'), findsOneWidget);
      });
    }
  });

  testWidgets('a blank city opens the city list and keeps the flow', (
    tester,
  ) async {
    await _open(tester, '/region-select/%20?replace=100&returnToMore=1');
    expect(find.text('cities replace=100&returnToMore=1'), findsOneWidget);
  });

  testWidgets('a city opens its townships', (tester) async {
    await _open(tester, '/region-select/${Uri.encodeComponent('臺北市')}');
    expect(find.text('city 臺北市'), findsOneWidget);
  });
}
