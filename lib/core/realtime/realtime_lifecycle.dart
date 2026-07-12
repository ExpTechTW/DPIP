import 'package:dpip/core/realtime/realtime_service.dart';
import 'package:flutter/widgets.dart';

/// The single Flutter-facing seam of the realtime spine: translates app
/// lifecycle transitions into [RealtimeService] calls.
///
/// Kept trivial and separate so the service itself stays Flutter-free and
/// unit-testable. Foreground resumes polling (recompute → resync → refetch);
/// any non-resumed state pauses polling to save battery and data — background
/// alert delivery is push's job (FCM/APNs), not this foreground loop.
class RealtimeLifecycleObserver {
  RealtimeLifecycleObserver(this._service) {
    _listener = AppLifecycleListener(
      onResume: _service.onForeground,
      onPause: _service.onBackground,
      onHide: _service.onBackground,
      onInactive: _service.onBackground,
    );
  }

  final RealtimeService _service;
  late final AppLifecycleListener _listener;

  void dispose() => _listener.dispose();
}
