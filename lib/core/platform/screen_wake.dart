/// Keeps the display from sleeping while a screen needs to stay readable.
///
/// A platform channel rather than a package, like the rest of `core/platform/`:
/// each side is two lines of native code (`FLAG_KEEP_SCREEN_ON` on Android,
/// `isIdleTimerDisabled` on iOS) and both are scoped to the foreground app, so
/// neither can leak a held screen into the background.
///
/// Every caller must pair [enable] with [disable] — use [ScreenWakeScope],
/// which does it for you around a widget's lifetime.
library;

import 'package:dpip/core/logging/log.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

abstract final class ScreenWake {
  const ScreenWake._();

  static const MethodChannel _channel = MethodChannel(
    'com.exptech.dpip/screen_wake',
  );

  /// Holds the screen on. Best-effort: a platform that can't do it logs and
  /// carries on rather than failing the screen that asked.
  static Future<void> enable() => _set(true);

  /// Releases the hold.
  static Future<void> disable() => _set(false);

  static Future<void> _set(bool keepAwake) async {
    try {
      await _channel.invokeMethod<void>(keepAwake ? 'enable' : 'disable');
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'screen wake');
    }
  }
}

/// Holds the screen awake for as long as [child] is mounted.
///
/// The pairing lives here so no screen can forget the release half — the
/// failure mode of a forgotten `disable` is a phone that never sleeps again,
/// which the user would have no way to connect back to this app.
class ScreenWakeScope extends StatefulWidget {
  const ScreenWakeScope({super.key, this.enabled = true, required this.child});

  /// Whether the hold is currently wanted. A scope that is mounted but
  /// disabled releases the screen — the mesh page uses this to hold the
  /// display only while a radio is actually connected, since with nothing
  /// connected no reply can arrive and the hold is pure battery.
  final bool enabled;

  final Widget child;

  @override
  State<ScreenWakeScope> createState() => _ScreenWakeScopeState();
}

class _ScreenWakeScopeState extends State<ScreenWakeScope> {
  @override
  void initState() {
    super.initState();
    if (widget.enabled) ScreenWake.enable();
  }

  @override
  void didUpdateWidget(ScreenWakeScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled != oldWidget.enabled) {
      widget.enabled ? ScreenWake.enable() : ScreenWake.disable();
    }
  }

  @override
  void dispose() {
    if (widget.enabled) ScreenWake.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
