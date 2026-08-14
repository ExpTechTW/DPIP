// Regression test for closing the earthquake replay when leaving the data tab.
//
// Uses a minimal StatefulShellRoute mirroring `MainShell`'s shape (a data
// branch with a report → replay stack) against the real go_router, because
// the dismissal is a battle against go_router's branch-navigator bookkeeping:
// `context.pop()` can't reach branch navigators ("There is nothing to pop"),
// `context.go()` to the parent resets the report page's state, and popping +
// `goBranch` in the same frame drops the data branch. The working recipe —
// pop the branch navigator like a back press, then switch branches next
// frame — is what `MainShell._onDestinationSelected` uses, so any change to
// go_router's branch behaviour that breaks it shows up here.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

GoRouter _router() => GoRouter(
  initialLocation: '/home',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          _HarnessShell(navigationShell: navigationShell),
      branches: [
        _branch('/home', 'home', 'HOME'),
        _branch('/events', 'events', 'EVENTS'),
        _branch('/map', 'map', 'MAP'),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/data',
              name: 'data',
              builder: (_, _) => const _Tag('DATA'),
              routes: [
                GoRoute(
                  path: 'earthquake',
                  name: 'earthquake',
                  builder: (_, _) => const _Tag('EQ'),
                  routes: [
                    GoRoute(
                      path: ':id',
                      name: 'report',
                      builder: (_, _) => const _Tag('REPORT'),
                      routes: [
                        GoRoute(
                          path: 'replay',
                          name: 'replay',
                          builder: (_, _) => const _Tag('REPLAY'),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        _branch('/more', 'more', 'MORE'),
      ],
    ),
  ],
);

StatefulShellBranch _branch(String path, String name, String label) =>
    StatefulShellBranch(
      routes: [GoRoute(path: path, name: name, builder: (_, _) => _Tag(label))],
    );

class _Tag extends StatelessWidget {
  const _Tag(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Center(child: Text(label));
}

/// The shell's tab-switch logic, mirroring `MainShell._onDestinationSelected`.
class _HarnessShell extends StatefulWidget {
  const _HarnessShell({required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  State<_HarnessShell> createState() => _HarnessShellState();
}

class _HarnessShellState extends State<_HarnessShell> {
  static const int _dataBranchIndex = 3;

  @override
  Widget build(BuildContext context) {
    final index = widget.navigationShell.currentIndex;
    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'home'),
          NavigationDestination(icon: Icon(Icons.warning), label: 'events'),
          NavigationDestination(icon: Icon(Icons.map), label: 'map'),
          NavigationDestination(icon: Icon(Icons.folder), label: 'data'),
          NavigationDestination(icon: Icon(Icons.menu), label: 'more'),
        ],
        onDestinationSelected: _onDestinationSelected,
      ),
    );
  }

  void _onDestinationSelected(int index) {
    final from = widget.navigationShell.currentIndex;
    if (index != from && from == _dataBranchIndex && _isReplayOnTop()) {
      // Pop the replay off the data branch's own navigator — the same code
      // path a system back press takes. Deferring the branch switch to the
      // next frame lets go_router settle the pop's configuration update first;
      // running them in the same frame drops the data branch's navigator.
      widget
          .navigationShell
          .route
          .branches[_dataBranchIndex]
          .navigatorKey
          .currentState!
          .pop();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        widget.navigationShell.goBranch(index);
      });
      return;
    }
    widget.navigationShell.goBranch(index, initialLocation: index == from);
  }

  bool _isReplayOnTop() {
    final navigator = widget
        .navigationShell
        .route
        .branches[_dataBranchIndex]
        .navigatorKey
        .currentState;
    final pages = navigator?.widget.pages;
    return pages != null && pages.isNotEmpty && pages.last.name == 'replay';
  }
}

List<String?> _dataBranchPageNames(WidgetTester tester) {
  // Find the data branch's Navigator and read its page stack.
  final navigators = find
      .byType(Navigator, skipOffstage: false)
      .evaluate()
      .map((e) => (e as StatefulElement).state as NavigatorState)
      .map((s) => s.widget.pages.map((p) => p.name).toList());
  for (final pages in navigators) {
    if (pages.contains('data')) return pages;
  }
  return const [];
}

Future<void> _pumpToReplay(WidgetTester tester) async {
  final router = _router();
  await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  await tester.pumpAndSettle();
  // Real flow: go to the report detail in the data branch, then push replay.
  router.goNamed('report', pathParameters: {'id': '123'});
  await tester.pumpAndSettle();
  expect(find.text('REPORT'), findsOneWidget);
  router.pushNamed('replay', pathParameters: {'id': '123'});
  await tester.pumpAndSettle();
  expect(find.text('REPLAY'), findsOneWidget);
}

void main() {
  testWidgets('pop alone is a clean back press', (tester) async {
    await _pumpToReplay(tester);

    // Simulate a system back press on the replay page.
    final router = GoRouter.of(tester.element(find.text('REPLAY')));
    router.pop();
    await tester.pumpAndSettle();

    // Replay gone, report kept.
    expect(find.text('REPLAY'), findsNothing);
    expect(find.text('REPORT'), findsOneWidget);
    expect(_dataBranchPageNames(tester), ['data', 'earthquake', 'report']);
  });

  testWidgets('leaving the data tab closes replay and keeps the report page', (
    tester,
  ) async {
    await _pumpToReplay(tester);
    expect(_dataBranchPageNames(tester).last, 'replay');

    // Tap the MORE tab.
    await tester.tap(find.text('more'));
    await tester.pumpAndSettle();

    // The MORE tab should now be on screen.
    expect(find.text('MORE'), findsOneWidget);

    // The data branch (offstage while on MORE): replay closed, report kept.
    final dataPages = _dataBranchPageNames(tester);
    expect(
      dataPages.contains('replay'),
      isFalse,
      reason: 'replay should be closed',
    );
    expect(dataPages.last, 'report', reason: 'report detail should remain');

    // Return to the data tab: report detail is still there, not "killed".
    await tester.tap(find.text('data'));
    await tester.pumpAndSettle();
    expect(find.text('REPORT'), findsOneWidget);
  });
}
