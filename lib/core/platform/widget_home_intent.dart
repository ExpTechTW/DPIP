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
  static bool _ready = false;

  /// Routes now, or stashes the tap until [markReady].
  ///
  /// Readiness is a separate question from whether [onOpen] is set. A cold-start
  /// tap is collected during the app's `initState`, where the router exists but
  /// has not laid out a frame; the app says when navigating is safe, and until it
  /// does the tap waits rather than being pushed into a router mid-build.
  static void route() {
    final handler = onOpen;
    if (_ready && handler != null) {
      Log.info('Widget tap: opening home');
      handler();
    } else {
      Log.info('Widget tap: app not ready, stashing home');
      _pending = true;
    }
  }

  /// Declares the router navigable and replays a stashed tap, at most once.
  ///
  /// The app calls this after its first frame. Both paths lead here: a cold-start
  /// tap collected by [listen] is always stashed, and a warm tap that somehow
  /// lands during startup is too.
  static void markReady() {
    _ready = true;
    if (!_pending) return;
    _pending = false;
    Log.info('Widget tap: replaying home after cold start');
    onOpen?.call();
  }

  /// Installs the native handler and collects a tap that already happened.
  ///
  /// The collect is the cold start. `MainActivity` cannot push that tap: its
  /// channel is built in `configureFlutterEngine`, which runs before this
  /// entrypoint, so a push from there arrives at a channel nobody is listening
  /// on and is dropped. Native therefore holds the flag and this asks for it,
  /// once, after the handler above is in place — a tap that launched the process
  /// is then routed exactly like a warm one.
  ///
  /// Safe to call once; the app does it at launch. Off Android the channel has
  /// no implementation and the collect is a no-op.
  static Future<void> listen() async {
    channel.setMethodCallHandler((call) async {
      if (call.method == 'openHome') {
        route();
      }
    });

    try {
      if (await channel.invokeMethod<bool>('consumeInitialIntent') ?? false) {
        Log.info('Widget tap: collected the launch intent');
        route();
      }
    } on MissingPluginException {
      // No Widget on this platform — nothing launched us.
    } on Object catch (error) {
      Log.warning('Widget tap: launch intent unavailable: $error');
    }
  }

  /// Clears the stashed intent and stops listening. For tests, and for a
  /// teardown that would otherwise route into a disposed router.
  static void reset() {
    _pending = false;
    _ready = false;
    onOpen = null;
    channel.setMethodCallHandler(null);
  }
}
