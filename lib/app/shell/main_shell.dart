import 'package:dpip/core/settings/default_map_layer_controller.dart';
import 'package:dpip/features/home/presentation/home_chrome.dart';
import 'package:dpip/features/home/presentation/home_sheet_extent.dart';
import 'package:dpip/features/home/presentation/home_reset_signal.dart';
import 'package:dpip/features/changelog/presentation/widgets/update_prompt.dart';
import 'package:dpip/core/meshtastic/mesh_unread.dart';
import 'package:dpip/core/network/endpoint_health.dart';
import 'package:dpip/core/permissions/permission_health.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/map/base_map.dart';
import 'package:dpip/shared/map/default_map_layer_ui.dart';
import 'package:dpip/shared/map/map_camera_handoff.dart';
import 'package:dpip/shared/map/map_trace.dart';
import 'package:dpip/shared/navigation/app_routes.dart';
import 'package:dpip/shared/navigation/refresh_on_appear.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// The app's persistent bottom-navigation shell.
///
/// Wraps the five top-level branches in an [IndexedStack] (via
/// [StatefulNavigationShell]) so each tab keeps its own navigation state. The
/// body extends behind the bar so, on Home, the weather backdrop shows through
/// it; the bar then slides down and fades out as the sheet climbs
/// ([HomeChrome.navDismiss]) — the first chrome to clear — leaving the weather
/// unobstructed instead of an opaque strip.
class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.navigationShell});

  /// The go_router shell that owns the five branches, in the same order as the
  /// destinations built in [build].
  final StatefulNavigationShell navigationShell;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with RouteAware {
  final int _traceId = nextMapTraceId();

  String get _traceScope => 'shell#$_traceId';

  void _trace(String Function() message) => mapTrace(_traceScope, message);

  /// Index of the data branch (see the destinations in [build]) — the only
  /// branch with nested routes, so leaving it while a replay is on screen
  /// needs the replay closed (see [_closeReplayOnBranchLeave]).
  static const int _dataBranchIndex = 3;

  int? _lastIndex;

  /// Which branch is on screen. The branches live in an IndexedStack and stay
  /// mounted while hidden, so this is how a page learns it was returned to
  /// (see [RefreshOnAppear]).
  final VisibleTab _visibleTab = VisibleTab();

  /// The shell's own route on the root navigator, while subscribed to
  /// [shellRouteObserver]. Held so the subscription can be dropped again.
  ModalRoute<void>? _shellRoute;

  @override
  void initState() {
    super.initState();
    _trace(() => 'init current=${widget.navigationShell.currentIndex}');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The shell is built by StatefulShellRoute, so this is the shell's route on
    // the *root* navigator — the one a full-screen page is pushed on top of.
    final route = ModalRoute.of<void>(context);
    if (identical(route, _shellRoute)) return;
    if (_shellRoute != null) shellRouteObserver.unsubscribe(this);
    _shellRoute = route;
    if (route != null) shellRouteObserver.subscribe(this, route);
    _trace(() => 'route-subscribe route=${route?.settings.name}');
  }

  @override
  void didPushNext() => _setShellOnTop(false);

  @override
  void didPopNext() => _setShellOnTop(true);

  @override
  void didPush() => _setShellOnTop(true);

  /// Publishes after the frame, for the same reason the branch index does: a
  /// subscription lands during `didChangeDependencies` (mid-build), and pages
  /// listening to this call `setState` on the edge.
  void _setShellOnTop(bool value) {
    if (_visibleTab.shellOnTop == value) return;
    _trace(() => 'shell-on-top schedule value=$value');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _visibleTab.shellOnTop = value;
      _trace(() => 'shell-on-top applied value=$value');
    });
  }

  @override
  void dispose() {
    _trace(() => 'dispose');
    if (_shellRoute != null) shellRouteObserver.unsubscribe(this);
    _visibleTab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final index = widget.navigationShell.currentIndex;
    if (_lastIndex != index) {
      _trace(
        () =>
            'build branch=${_lastIndex ?? 'none'}->$index '
            'visibleNotifier=${_visibleTab.value}',
      );
    }
    final mapLayer = context.watch<DefaultMapLayerController>().layer;
    // `select`, not `watch`: the whole shell (every mounted tab with it) must
    // not rebuild because an unrelated permission field moved.
    final needsPermissionAttention = context.select<PermissionHealth, bool>(
      (health) => health.needsAttention,
    );
    // Endpoint health joins the same dot: a service host the client has
    // stopped reaching is as much "something the More tab holds for you" as a
    // missing permission. Two dots on one icon say nothing more than one.
    final endpointAttention = context.select<EndpointHealthMonitor, bool>(
      (health) => health.needsAttention,
    );
    // Unread mesh messages ride the same dot.
    final hasMeshUnread = context.select<MeshUnread, bool>(
      (unread) => unread.hasUnread,
    );
    final moreAttention =
        needsPermissionAttention || endpointAttention || hasMeshUnread;

    // Reset Home's sheet as we *leave* Home — while it is hidden — so it is back
    // at rest (chrome shown) whenever Home is next shown, by a nav tap or a
    // programmatic route (e.g. a notification tap). Resetting on the way out,
    // not the way in, avoids both the stale full-extent flash and the chrome-
    // hidden dead-end a left-expanded sheet would otherwise cause.
    if (_lastIndex == 0 && index != 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.read<HomeResetSignal>().fire();
      });
    }
    _lastIndex = index;
    // Publish after the frame: pages listening to this rebuild on the edge, and
    // a notify during build would land mid-build for them.
    if (_visibleTab.value != index) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _visibleTab.value = index;
        _trace(() => 'visible-tab applied value=$index');
      });
    }

    // Bottom-navigation destinations, in branch order.
    final destinations = <NavigationDestination>[
      NavigationDestination(
        icon: const Icon(Icons.home_outlined),
        selectedIcon: const Icon(Icons.home),
        label: l10n.navHome,
      ),
      NavigationDestination(
        icon: const Icon(Icons.warning_amber_rounded),
        selectedIcon: const Icon(Icons.warning),
        label: l10n.navEvents,
      ),
      NavigationDestination(
        icon: Icon(mapLayer.icon),
        selectedIcon: Icon(mapLayer.selectedIcon),
        label: mapLayer.label(l10n),
      ),
      NavigationDestination(
        icon: const Icon(Icons.folder_outlined),
        selectedIcon: const Icon(Icons.folder),
        label: l10n.navData,
      ),
      NavigationDestination(
        // The dot is the only place the shell says anything is wrong, and what
        // is wrong is that an alert may not reach this user — so it rides the
        // tab that leads to the fix.
        // Both icons, not just the unselected one: NavigationBar fades to
        // selectedIcon on tap, so badging only `icon` made the dot vanish the
        // moment the user opened the tab it was pointing at.
        icon: _AttentionBadge(
          show: moreAttention,
          child: const Icon(Icons.menu),
        ),
        selectedIcon: _AttentionBadge(
          show: moreAttention,
          child: const Icon(Icons.menu),
        ),
        label: l10n.navMore,
      ),
    ];

    return Scaffold(
      // Let the Home weather backdrop show through behind the bar.
      extendBody: true,
      body: Column(
        children: [
          // Renders nothing; checks once after the first frame whether this
          // build's channel has a newer release, and says so once per version.
          const UpdatePrompt(),
          Expanded(
            child: VisibleTabScope(
              visibleTab: _visibleTab,
              child: widget.navigationShell,
            ),
          ),
        ],
      ),
      // Only Home dismisses the bar; every other tab keeps it (dismiss 0).
      bottomNavigationBar: ValueListenableBuilder<double>(
        valueListenable: context.read<HomeSheetExtent>(),
        builder: (context, extent, child) {
          final dismiss = index == 0 ? HomeChrome.navDismiss(extent) : 0.0;
          // Slide the bar down by its own height and fade it out; stop it
          // catching taps once it is mostly gone so the sheet behind gets them.
          return IgnorePointer(
            ignoring: dismiss > 0.5,
            child: Opacity(
              opacity: 1 - dismiss,
              child: FractionalTranslation(
                translation: Offset(0, dismiss),
                child: child,
              ),
            ),
          );
        },
        child: NavigationBar(
          selectedIndex: index,
          destinations: destinations,
          onDestinationSelected: _onDestinationSelected,
        ),
      ),
    );
  }

  void _onDestinationSelected(int index) {
    final from = widget.navigationShell.currentIndex;
    _trace(() => 'destination tap from=$from to=$index');
    // Re-entering Home (including re-tapping it while active) snaps its sheet
    // back to rest; the build-time guard above covers programmatic entry.
    if (index == 0) context.read<HomeResetSignal>().fire();
    // Opening / re-tapping the map tab: nationwide framing + the user's
    // configured default overlay (nav icon). Without the layerId, a session that
    // switched to radar (etc.) would stay there while the bar still shows 衛星.
    if (index == 2) {
      final layerId = context.read<DefaultMapLayerController>().layer.id;
      context.read<MapCameraHandoff>().request(
        BaseMap.taiwanBounds,
        layerId: layerId,
      );
    }
    // Leaving the data branch while its replay page is on top closes it first.
    // The industry-recognised way to clear a StatefulShellBranch's child
    // routes is to operate the branch's own navigator via its navigatorKey
    // (`navigatorKey.currentState?.pop()` — the same path a system back press
    // takes), not `context.pop()`, which cannot reach branch navigators and
    // throws "There is nothing to pop". go_router's onPopPage then syncs its
    // route-match bookkeeping and the report page beneath stays intact. The
    // branch switch is deferred one frame so the pop's configuration update
    // settles first; running both in the same frame drops the whole branch.
    if (index != from && from == _dataBranchIndex && _isReplayOnTop()) {
      widget
          .navigationShell
          .route
          .branches[_dataBranchIndex]
          .navigatorKey
          .currentState
          ?.pop();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _trace(() => 'go-branch deferred from=$from to=$index');
        widget.navigationShell.goBranch(index);
      });
      return;
    }
    _trace(() => 'go-branch from=$from to=$index initial=${index == from}');
    widget.navigationShell.goBranch(
      index,
      // Tapping the active tab returns it to its initial route.
      initialLocation: index == from,
    );
  }

  /// Whether the data branch's stack top is the replay page — the tell that a
  /// switch away must close it (see [_onDestinationSelected]). Inspects the
  /// branch's navigator pages only; navigation itself happens through the
  /// router.
  bool _isReplayOnTop() {
    final navigator = widget
        .navigationShell
        .route
        .branches[_dataBranchIndex]
        .navigatorKey
        .currentState;
    final pages = navigator?.widget.pages;
    return pages != null &&
        pages.isNotEmpty &&
        pages.last.name == AppRoutes.earthquakeReplay;
  }
}

/// A dot over [child] while a permission the app needs is missing.
///
/// [Badge] with no label is Material's small dot, which is the whole vocabulary
/// here: the shell does not say what is wrong, only that something is, and the
/// tab it sits on leads to the page that does. Announced for screen readers,
/// where a dot is otherwise silent.
class _AttentionBadge extends StatelessWidget {
  const _AttentionBadge({required this.show, required this.child});

  final bool show;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!show) return child;
    return Semantics(
      label: AppLocalizations.of(context).permissionsAttention,
      child: Badge(child: child),
    );
  }
}
