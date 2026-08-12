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

/// A dependent that reads the scope in `didChangeDependencies`, the way the
/// home sheet's [TickerMode] gate does.
class _ScopeDependent extends StatefulWidget {
  const _ScopeDependent({required this.onDeps});

  final VoidCallback onDeps;

  @override
  State<_ScopeDependent> createState() => _ScopeDependentState();
}

class _ScopeDependentState extends State<_ScopeDependent> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    VisibleTabScope.of(context);
    widget.onDeps();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
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

  testWidgets('scope does not notify on value change — consumers subscribe to '
      'the notifier instead', (tester) async {
    // The shell hands the same notifier instance down for the page's whole
    // life, so updateShouldNotify can never fire on a value move (both sides
    // of the comparison read the same object). A consumer that only reads the
    // scope in didChangeDependencies — as the home sheet's TickerMode gate
    // once did — would freeze at its first value and keep animating behind
    // hidden tabs. The contract is: subscribe to the notifier itself.
    final tab = VisibleTab(0);
    var deps = 0;
    late StateSetter setParent;
    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) {
          setParent = setState;
          return VisibleTabScope(
            visibleTab: tab,
            child: _ScopeDependent(onDeps: () => deps++),
          );
        },
      ),
    );
    await tester.pumpAndSettle();
    expect(deps, 1, reason: 'first mount always reads the scope');

    tab.value = 2;
    setParent(() {});
    await tester.pumpAndSettle();
    expect(deps, 1, reason: 'a same-instance value move cannot notify');

    // A different notifier instance (never what the shell does, but what a
    // rebuild would need for the inherited mechanism to fire) does notify.
    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) {
          return VisibleTabScope(
            visibleTab: VisibleTab(2),
            child: _ScopeDependent(onDeps: () => deps++),
          );
        },
      ),
    );
    await tester.pumpAndSettle();
    expect(deps, 2, reason: 'a swapped instance notifies dependents');
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
