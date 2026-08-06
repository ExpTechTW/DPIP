/// The one definition of "this screen is being looked at again", so every tab
/// refreshes on the same events instead of each inventing its own rule.
library;

import 'package:flutter/widgets.dart';

/// A "refresh now" broadcast a page hands to the views it owns.
///
/// A named type rather than a bare `ChangeNotifier` because `notifyListeners`
/// is protected — the owner needs a public way to fire it.
class RefreshSignal extends ChangeNotifier {
  /// Asks every listening view to re-fetch.
  void fire() => notifyListeners();
}

/// The index of the tab currently on screen.
///
/// The shell keeps this in step with the navigation branch. It exists because
/// the tabs live in an `IndexedStack`: every page stays **mounted** while hidden,
/// so a page never learns it was left or returned to from its own lifecycle —
/// `initState`/`dispose` fire once for the whole session.
class VisibleTab extends ValueNotifier<int> {
  VisibleTab([super.value = 0]);
}

/// Calls [onAppear] whenever this page comes back into view: its tab is selected
/// (from another tab, or re-tapped), or the app returns from the background
/// while this tab is the visible one.
///
/// Refreshing on appearance rather than on a pull is deliberate for a disaster
/// app: the data is only useful if it is current, and a user opening the app to
/// check on a hazard should not have to know to pull. A hidden tab stays idle —
/// [onAppear] never fires for a page the user cannot see, so background tabs
/// don't poll.
class RefreshOnAppear extends StatefulWidget {
  const RefreshOnAppear({
    super.key,
    required this.tabIndex,
    required this.onAppear,
    required this.child,
    this.refreshOnFirstBuild = false,
  });

  /// The shell branch index this page occupies.
  final int tabIndex;

  /// Invoked on every (re)appearance.
  final VoidCallback onAppear;

  final Widget child;

  /// Whether to also fire once when first built. Off by default: a page usually
  /// loads its own data on creation, and firing here as well would double every
  /// cold start.
  final bool refreshOnFirstBuild;

  @override
  State<RefreshOnAppear> createState() => _RefreshOnAppearState();
}

class _RefreshOnAppearState extends State<RefreshOnAppear>
    with WidgetsBindingObserver {
  VisibleTab? _visible;
  bool _wasVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.refreshOnFirstBuild) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onAppear();
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final visible = VisibleTabScope.of(context);
    if (visible == _visible) return;
    _visible?.removeListener(_onTabChanged);
    _visible = visible?..addListener(_onTabChanged);
    _wasVisible = _isVisible;
  }

  bool get _isVisible =>
      (_visible?.value ?? widget.tabIndex) == widget.tabIndex;

  void _onTabChanged() {
    final visible = _isVisible;
    // Only the hidden → visible edge is an appearance. Without this, every tab
    // switch anywhere would refresh every mounted page in the stack.
    if (visible && !_wasVisible) widget.onAppear();
    _wasVisible = visible;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Coming back from the background is the same event as re-entering the tab —
    // whatever is on screen has been sitting there unattended. Only the visible
    // page reacts; the others refresh when the user actually reaches them.
    if (state == AppLifecycleState.resumed && _isVisible) widget.onAppear();
  }

  @override
  void dispose() {
    _visible?.removeListener(_onTabChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Hands the shell's [VisibleTab] down to the pages inside it.
///
/// An [InheritedWidget] rather than a provider so a page can be pumped in a test
/// (or hosted outside the shell) without one: [of] returns null and
/// [RefreshOnAppear] then treats the page as always visible.
class VisibleTabScope extends InheritedWidget {
  const VisibleTabScope({
    super.key,
    required this.visibleTab,
    required super.child,
  });

  final VisibleTab visibleTab;

  static VisibleTab? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<VisibleTabScope>()?.visibleTab;

  @override
  bool updateShouldNotify(VisibleTabScope oldWidget) =>
      visibleTab != oldWidget.visibleTab;
}
