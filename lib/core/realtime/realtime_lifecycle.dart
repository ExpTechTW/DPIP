import 'package:dpip/core/realtime/realtime_service.dart';
import 'package:flutter/widgets.dart';

/// The single Flutter-facing seam of the realtime spine: translates app
/// lifecycle transitions into [RealtimeService] calls.
///
/// Kept trivial and separate so the service itself stays Flutter-free and
/// unit-testable. Foreground resumes polling (recompute → resync → refetch);
/// any non-resumed state pauses polling to save battery and data — background
/// alert delivery is push's job (FCM/APNs), not this foreground loop.
///
/// `inactive` is routed to [RealtimeService.onInterrupted] rather than
/// [RealtimeService.onBackground]: it fires for a notification shade, the app
/// switcher, an incoming call and every permission dialog, so it is both
/// frequent and usually momentary. Both stop polling; only a real background
/// (`paused`/`hidden`) also releases a source's held-open connection, because
/// reconnecting on each of those interruptions would cost more than it saves.
class RealtimeLifecycleObserver {
  RealtimeLifecycleObserver(this._service) {
    _listener = AppLifecycleListener(
      onResume: _service.onForeground,
      onPause: _service.onBackground,
      onHide: _service.onBackground,
      onInactive: _service.onInterrupted,
    );
  }

  final RealtimeService _service;
  late final AppLifecycleListener _listener;

  void dispose() => _listener.dispose();
}
