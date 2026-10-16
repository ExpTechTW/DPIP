import 'package:dpip/core/logging/log.dart';
import 'package:flutter/services.dart';

/// Carries a home-screen Widget tap into the app's router.
///
/// The Widget's surface tap launches `MainActivity` with an explicit action
/// (`WidgetRenderer.ACTION_OPEN_HOME`), and Android is what decides whether that
/// creates a process, brings an existing task forward or delivers `onNewIntent`
/// to a live one. On a **cold** start the router does not exist yet, so this
/// mirrors `NotificationTaps`: a tap either routes immediately or is stashed for
/// `drainPending` to replay once the app is ready.
///
/// Why it exists at all: without it a warm tap shows whatever screen the session
/// was on, which for a widget that says "open the app" is a tap that appears to
/// do nothing. The route mapping stays in the app layer (which owns the router);
/// `core` only carries the intent.
abstract final class WidgetHomeIntent {
  WidgetHomeIntent._();

  /// The channel the Android activity delivers the action on.
  static const MethodChannel channel = MethodChannel(
    'com.exptech.dpip/widget_home',
  );

  /// Set by the app layer to navigate Home. Null before the router is live.
  static void Function()? onOpen;

  static bool _pending = false;

  /// Routes now via [onOpen], or stashes it if the router is not ready yet.
  static void route() {
    final handler = onOpen;
    if (handler != null) {
      Log.info('Widget tap: opening home');
      handler();
    } else {
      Log.info('Widget tap: router not ready, stashing home');
      _pending = true;
    }
  }

  /// Replays a tap that arrived before [onOpen] was registered (cold start).
  static void drainPending() {
    if (!_pending) return;
    _pending = false;
    Log.info('Widget tap: replaying home after cold start');
    onOpen?.call();
  }

  /// Installs the native handler. Safe to call once; the app does it at launch.
  static void listen() {
    channel.setMethodCallHandler((call) async {
      if (call.method == 'openHome') {
        route();
      }
    });
  }

  /// Clears the stashed intent and stops listening. For tests, and for a
  /// teardown that would otherwise route into a disposed router.
  static void reset() {
    _pending = false;
    onOpen = null;
    channel.setMethodCallHandler(null);
  }
}
