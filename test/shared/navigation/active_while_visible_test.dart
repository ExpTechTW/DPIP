/// The gate that stops a page's work when the user is no longer looking at it.
///
/// Worth its own test because the failure it prevents is invisible: a page that
/// keeps polling behind another tab looks exactly like one that stopped, and
/// the reason `dispose` cannot be relied on (go_router freezing an inactive
/// branch's exit transition) is not reproducible in a unit test of the page.
library;

import 'package:dpip/shared/navigation/refresh_on_appear.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pumps the gate under [visibleTab] and returns every state it reported.
Future<List<bool>> _pump(
  WidgetTester tester, {
  required VisibleTab visibleTab,
  int? tabIndex = 2,
}) async {
  final reported = <bool>[];
  await tester.pumpWidget(
    MaterialApp(
      home: VisibleTabScope(
        visibleTab: visibleTab,
        child: ActiveWhileVisible(
          tabIndex: tabIndex,
          onActiveChanged: reported.add,
          child: const SizedBox(),
        ),
      ),
    ),
  );
  // The first report is deferred to a post-frame callback, so the page has a
  // built subtree to act on by the time it hears anything.
  await tester.pump();
  return reported;
}

void main() {
  testWidgets('a page born on its own tab is active', (tester) async {
    final reported = await _pump(tester, visibleTab: VisibleTab(2));
    expect(reported, [true]);
  });

  testWidgets('a page born behind another tab is told so, not left running', (
    tester,
  ) async {
    // The case the replay page hit: it is built while its branch is selected,
    // but a page can also be restored into a hidden branch — either way the
    // first thing it hears must be the truth, not a default.
    final reported = await _pump(tester, visibleTab: VisibleTab(0));
    expect(reported, [false]);
  });

  testWidgets('leaving the tab idles it and coming back wakes it', (
    tester,
  ) async {
    final visibleTab = VisibleTab(2);
    final reported = await _pump(tester, visibleTab: visibleTab);

    visibleTab.value = 0;
    await tester.pump();
    expect(reported, [true, false], reason: 'switched away → idle');

    visibleTab.value = 2;
    await tester.pump();
    expect(reported, [true, false, true]);
  });

  testWidgets('a full-screen route over the shell counts as hidden', (
    tester,
  ) async {
    // The tab index never changes when a page is pushed over the whole shell,
    // so a gate that only compared indices would keep the work running under
    // an opaque page.
    final visibleTab = VisibleTab(2);
    final reported = await _pump(tester, visibleTab: visibleTab);

    visibleTab.shellOnTop = false;
    await tester.pump();
    expect(reported, [true, false]);

    visibleTab.shellOnTop = true;
    await tester.pump();
    expect(reported, [true, false, true]);
  });

  testWidgets('backgrounding the app idles a page on the visible tab', (
    tester,
  ) async {
    final visibleTab = VisibleTab(2);
    final reported = await _pump(tester, visibleTab: visibleTab);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(reported, [true, false]);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(reported, [true, false, true]);
  });

  testWidgets('returning to the foreground on a hidden tab stays idle', (
    tester,
  ) async {
    // Both halves have to hold. Resuming the app while some *other* tab is on
    // screen must not restart a page the user still cannot see.
    final visibleTab = VisibleTab(0);
    final reported = await _pump(tester, visibleTab: visibleTab);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(reported, [false], reason: 'never active, so never reported again');
  });

  testWidgets('a page hosted without a shell scope is always active', (
    tester,
  ) async {
    // A test, a preview, or a page opened outside the shell has no tab to be
    // hidden behind — it must not gate itself off and do nothing.
    final reported = <bool>[];
    await tester.pumpWidget(
      MaterialApp(
        home: ActiveWhileVisible(
          tabIndex: 2,
          onActiveChanged: reported.add,
          child: const SizedBox(),
        ),
      ),
    );
    await tester.pump();
    expect(reported, [true]);
  });

  testWidgets('a page belonging to no branch only follows the shell', (
    tester,
  ) async {
    final visibleTab = VisibleTab(0);
    final reported = await _pump(
      tester,
      visibleTab: visibleTab,
      tabIndex: null,
    );
    expect(reported, [
      true,
    ], reason: 'no branch → the tab index is not its cue');

    visibleTab.shellOnTop = false;
    await tester.pump();
    expect(reported, [true, false]);
  });

  testWidgets('the listener is dropped when the page goes away', (
    tester,
  ) async {
    final visibleTab = VisibleTab(2);
    final reported = await _pump(tester, visibleTab: visibleTab);

    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    visibleTab.value = 0;
    await tester.pump();

    expect(reported, [true], reason: 'a disposed gate reports nothing');
  });
}
