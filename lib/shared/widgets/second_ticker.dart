/// A once-a-second rebuild that stops the moment nobody can see it.
///
/// The EEW countdown cards each ran a bare `Timer.periodic(1 s, setState)` for
/// their whole mounted life. Three problems, all shapes of the same one:
/// a `Timer` is not a `Ticker`, so neither `TickerMode` nor app lifecycle ever
/// reaches it — during an alert the countdowns kept waking the CPU once a
/// second behind other tabs and under the lock screen, exactly when the phone
/// should be coasting.
///
/// This mixin owns the timer and gates it on two inputs:
/// * the app being on screen (`AppLifecycleListener.onHide`/`onShow` — a
///   notification-shade pull or app-switcher glance keeps it ticking, the same
///   distinction `RealtimeService` draws);
/// * [secondTickerActive], the host's own visibility (a tab scope, TickerMode
///   — override it and call [syncSecondTicker] when the input changes).
///
/// On every visible edge it fires one immediate [setState], so a countdown
/// snaps straight to the correct `AppTime` value instead of showing a
/// seconds-old number until the next tick.
///
/// Ticks land on whole seconds of the calibrated clock ([AppTime]), not one
/// second after whenever the widget happened to mount. A periodic timer
/// started at mount put every card on its own random phase: a number derived
/// from the clock could sit up to a second behind it, and two cards showing
/// the same countdown disagreed by one. A host whose value changes on some
/// other second — an S-wave countdown changes on whole seconds *before its
/// arrival* — moves the ticks there with [secondTickerDelay], and calls
/// [realignSecondTicker] when that changes.
library;

import 'dart:async';

import 'package:dpip/core/realtime/app_time.dart';
import 'package:flutter/widgets.dart';

mixin SecondTicker<T extends StatefulWidget> on State<T> {
  Timer? _secondTimer;
  bool _foreground = true;
  late final AppLifecycleListener _secondTickerLifecycle;

  /// The host's own gate — e.g. `TickerMode.of(context)` or a visible-tab
  /// check. Re-read on every [syncSecondTicker].
  @protected
  bool get secondTickerActive => true;

  /// The clock the ticks are aligned to — the calibrated one by default; a
  /// host showing another timeline (a replay) returns that one's.
  @protected
  DateTime secondTickerNow() => AppTime.utc;

  /// How long after [now] the next tick lands: by default the next whole
  /// second of [secondTickerNow].
  @protected
  Duration secondTickerDelay(DateTime now) {
    final intoSecond = now.microsecondsSinceEpoch % _microsPerSecond;
    return Duration(microseconds: _microsPerSecond - intoSecond);
  }

  /// Re-aims the pending tick after whatever [secondTickerDelay] reads has
  /// changed — safe to call from `build`: it moves a timer, nothing more.
  @protected
  void realignSecondTicker() {
    if (_secondTimer == null) return;
    _secondTimer!.cancel();
    _armSecondTimer();
  }

  /// Re-evaluates the gates and starts/stops the timer accordingly.
  @protected
  void syncSecondTicker() {
    if (_wantSecondTicks && _secondTimer == null) {
      // Snap to the present first: the card may have been hidden for minutes.
      setState(() {});
      _armSecondTimer();
    } else if (!_wantSecondTicks) {
      _secondTimer?.cancel();
      _secondTimer = null;
    }
  }

  bool get _wantSecondTicks => mounted && _foreground && secondTickerActive;

  /// One-shot, re-armed on every tick rather than periodic: each delay is
  /// measured from the clock afresh, so the ticks cannot drift off the
  /// boundary however late a timer fires, and a clock resync is followed
  /// within one tick.
  void _armSecondTimer() {
    var delay = secondTickerDelay(secondTickerNow());
    // A boundary a hair away would otherwise fire back to back while the
    // clock catches up with the timer.
    if (delay < _minDelay) delay = _minDelay;
    _secondTimer = Timer(delay, () {
      _secondTimer = null;
      if (!mounted) return;
      setState(() {});
      if (_wantSecondTicks) _armSecondTimer();
    });
  }

  static const int _microsPerSecond = 1000000;
  static const Duration _minDelay = Duration(milliseconds: 1);

  @override
  void initState() {
    super.initState();
    _secondTickerLifecycle = AppLifecycleListener(
      onHide: () {
        _foreground = false;
        syncSecondTicker();
      },
      onShow: () {
        _foreground = true;
        syncSecondTicker();
      },
    );
    // The first sync runs in didChangeDependencies, where hosts that gate on
    // an inherited widget (TickerMode, a tab scope) can already read it.
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    syncSecondTicker();
  }

  @override
  void dispose() {
    _secondTickerLifecycle.dispose();
    _secondTimer?.cancel();
    _secondTimer = null;
    super.dispose();
  }
}
