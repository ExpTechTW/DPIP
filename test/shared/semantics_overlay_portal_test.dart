// The regression guard for `tool/patches/0001-semantics-attach-stale-children.patch`.
//
// Nothing in DPIP is under test here — this is the framework, reproduced at the
// smallest shape that reaches the bug. It lives in the suite because the patch
// has to be kept honest by something that runs on every machine and in CI, and
// a test that fails on an unpatched SDK does that without a check script: the
// patch is applied by `require_mise`, so a run that skipped it fails here.
//
// When upstream fixes flutter#189902 and mise.toml moves to a version that
// carries the fix, the patch stops applying (and says so, loudly) — this test
// should then pass on its own. Keep it. It is the thing that says the fix is
// really in.
//
// Shape credit: the reduction in the upstream issue. Each of the three oddities
// below is load-bearing; drop any one and the assert does not fire.
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Two tooltips, one of which is rigged to reach the bug.
///
/// Every [Tooltip] is an [OverlayPortal] — `RawTooltip` is built on
/// `OverlayPortal.overlayChildLayoutBuilder` — which is why an app that never
/// names `OverlayPortal` (DPIP does not) still hits an OverlayPortal defect.
class _TwoTooltips extends StatelessWidget {
  const _TwoTooltips();

  /// A border, so the two rows do not collapse into one render object and the
  /// semantics subtree has an interior node to lose track of.
  Widget _decorate(Widget child) => DecoratedBox(
    decoration: BoxDecoration(border: Border.all()),
    child: child,
  );

  Widget _tooltip(String label) => Tooltip(
    message: '$label tooltip',
    // `explicitChildNodes` is what stops the child folding into the tooltip's
    // own node, so there is a separate SemanticsNode available to be stolen.
    child: Semantics(explicitChildNodes: true, child: Text('$label text')),
  );

  @override
  Widget build(BuildContext context) {
    Widget bad = _tooltip('bad');
    // The second Overlay is what lets one node end up parented under a subtree
    // that a later pass rebuilds from the bottom up — the "stealing".
    bad = Overlay.wrap(child: ExcludeSemantics(child: bad));
    // A tight box: it stops the enclosing node being rebuilt on the pass that
    // would otherwise refresh the stale `_children` list and hide the bug.
    bad = SizedBox(width: 200, height: 100, child: bad);

    return Dialog(
      child: Column(
        spacing: 20,
        children: [_decorate(_tooltip('good')), _decorate(bad)],
      ),
    );
  }
}

void main() {
  testWidgets('a tooltip shown and dismissed twice keeps the semantics tree '
      'consistent (flutter#189902)', (tester) async {
    // Semantics is only built when something asks for it — a screen reader on
    // a device, this handle in a test. Without it `flushSemantics` does no work
    // and the bug cannot be reached.
    final handle = tester.ensureSemantics();

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: _TwoTooltips())),
    );

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);

    final target = tester.getCenter(find.text('bad text'));
    const away = Offset(5, 5);

    // Twice is the whole test. The first show/dismiss leaves a SemanticsNode
    // with `attached == true` and `parent == null`; the second dismiss walks
    // into it and trips `assert(!child.attached)` in `_replaceChildren`.
    for (var pass = 1; pass <= 2; pass++) {
      await gesture.moveTo(target);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      await gesture.moveTo(away);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
    }

    // Disposed in the body, not `addTearDown`: the binding's own end-of-test
    // check for leaked handles runs before tear-downs do.
    handle.dispose();
  });
}
