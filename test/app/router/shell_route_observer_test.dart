/// Pins the one assumption the shell's idle-when-covered gate rests on: that a
/// [RouteObserver] handed to `GoRouter.observers` actually reaches the **root**
/// navigator, and therefore sees a full-screen route pushed over a
/// [StatefulShellRoute].
///
/// Without this the gate is a silent no-op: `VisibleTab.shellOnTop` would stay
/// `true` forever, every consumer would keep believing it is on screen, and
/// nothing would fail — not a test, not the analyzer, not the app. The rest of
/// the visibility tests drive `shellOnTop` directly, so they would all still
/// pass while the feature did nothing.
library;

import 'package:dpip/shared/navigation/refresh_on_appear.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Subscribes to [shellRouteObserver] exactly the way `MainShell` does, and
/// records the callbacks instead of republishing them.
class _ShellProbe extends StatefulWidget {
  const _ShellProbe({required this.events});

  final List<String> events;

  @override
  State<_ShellProbe> createState() => _ShellProbeState();
}

class _ShellProbeState extends State<_ShellProbe> with RouteAware {
  ModalRoute<void>? _route;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of<void>(context);
    if (identical(route, _route)) return;
    if (_route != null) shellRouteObserver.unsubscribe(this);
    _route = route;
    if (route != null) shellRouteObserver.subscribe(this, route);
  }

  @override
  void didPush() => widget.events.add('push');

  @override
  void didPushNext() => widget.events.add('pushNext');

  @override
  void didPopNext() => widget.events.add('popNext');

  @override
  void dispose() {
    if (_route != null) shellRouteObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

void main() {
  testWidgets('a route pushed over the shell reaches the shell as pushNext', (
    tester,
  ) async {
    final events = <String>[];
    final router = GoRouter(
      initialLocation: '/tab',
      observers: [shellRouteObserver],
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (_, _, _) => _ShellProbe(events: events),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(path: '/tab', builder: (_, _) => const Text('tab')),
              ],
            ),
          ],
        ),
        // The shape every settings/log/mesh page in AppRoutes has: a sibling of
        // the shell on the root navigator, not a child of a branch.
        GoRoute(path: '/over', builder: (_, _) => const Text('over')),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    expect(events, ['push'], reason: 'subscribing reports the current route');

    // `pushNamed` is how every one of those pages is opened (goNamed is only
    // used for tab switches), so this is the real motion.
    router.push('/over');
    await tester.pumpAndSettle();
    expect(events, [
      'push',
      'pushNext',
    ], reason: 'the shell must learn it was covered');

    router.pop();
    await tester.pumpAndSettle();
    expect(events, ['push', 'pushNext', 'popNext']);
  });

  testWidgets('a second page over the first does not re-notify the shell', (
    tester,
  ) async {
    final events = <String>[];
    final router = GoRouter(
      initialLocation: '/tab',
      observers: [shellRouteObserver],
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (_, _, _) => _ShellProbe(events: events),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(path: '/tab', builder: (_, _) => const Text('tab')),
              ],
            ),
          ],
        ),
        GoRoute(path: '/over', builder: (_, _) => const Text('over')),
        GoRoute(path: '/deeper', builder: (_, _) => const Text('deeper')),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    router.push('/over');
    await tester.pumpAndSettle();
    router.push('/deeper');
    await tester.pumpAndSettle();
    expect(events, [
      'push',
      'pushNext',
    ], reason: 'the second push lands on /over, not on the shell');

    // Unwinding one level leaves the shell still covered — it must not be told
    // it is back on screen until the last page is gone.
    router.pop();
    await tester.pumpAndSettle();
    expect(events, ['push', 'pushNext'], reason: 'still covered by /over');

    router.pop();
    await tester.pumpAndSettle();
    expect(events, ['push', 'pushNext', 'popNext']);
  });
}
