import 'package:dpip/shared/navigation/refresh_on_appear.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(
  VisibleTab tab, {
  required int tabIndex,
  required VoidCallback on,
}) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: VisibleTabScope(
      visibleTab: tab,
      child: RefreshOnAppear(
        tabIndex: tabIndex,
        onAppear: on,
        child: const SizedBox(),
      ),
    ),
  );
}

void main() {
  testWidgets('does not fire on first build', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      _host(VisibleTab(), tabIndex: 0, on: () => calls++),
    );
    await tester.pumpAndSettle();
    // The page loads its own data on creation; firing here would double it.
    expect(calls, 0);
  });

  testWidgets('fires when its tab becomes visible', (tester) async {
    final tab = VisibleTab();
    var calls = 0;
    await tester.pumpWidget(_host(tab, tabIndex: 1, on: () => calls++));
    await tester.pumpAndSettle();

    tab.value = 1;
    await tester.pumpAndSettle();
    expect(calls, 1);
  });

  testWidgets('does not fire for a switch between two other tabs', (
    tester,
  ) async {
    final tab = VisibleTab();
    var calls = 0;
    await tester.pumpWidget(_host(tab, tabIndex: 1, on: () => calls++));
    await tester.pumpAndSettle();

    // Only the hidden → visible edge counts; otherwise every mounted page in
    // the IndexedStack would refresh on any navigation.
    tab.value = 2;
    tab.value = 3;
    await tester.pumpAndSettle();
    expect(calls, 0);
  });

  testWidgets('fires again on every re-entry', (tester) async {
    final tab = VisibleTab();
    var calls = 0;
    await tester.pumpWidget(_host(tab, tabIndex: 1, on: () => calls++));
    await tester.pumpAndSettle();

    tab.value = 1;
    tab.value = 0;
    tab.value = 1;
    await tester.pumpAndSettle();
    expect(calls, 2);
  });

  testWidgets('fires when the app resumes while visible', (tester) async {
    final tab = VisibleTab();
    var calls = 0;
    await tester.pumpWidget(_host(tab, tabIndex: 0, on: () => calls++));
    await tester.pumpAndSettle();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(calls, 1);
  });

  testWidgets('a hidden page stays idle when the app resumes', (tester) async {
    final tab = VisibleTab(2);
    var calls = 0;
    await tester.pumpWidget(_host(tab, tabIndex: 0, on: () => calls++));
    await tester.pumpAndSettle();

    // A background tab must not fetch on resume; it refreshes when reached.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(calls, 0);
  });

  testWidgets('works with no scope (treated as always visible)', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: RefreshOnAppear(
          tabIndex: 3,
          onAppear: () => calls++,
          child: const SizedBox(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(calls, 1, reason: 'a page hosted outside the shell still refreshes');
  });
}
