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
library;

import 'dart:async';

import 'package:flutter/widgets.dart';

mixin SecondTicker<T extends StatefulWidget> on State<T> {
  Timer? _secondTimer;
  bool _foreground = true;
  late final AppLifecycleListener _secondTickerLifecycle;

  /// The host's own gate — e.g. `TickerMode.of(context)` or a visible-tab
  /// check. Re-read on every [syncSecondTicker].
  @protected
  bool get secondTickerActive => true;

  /// Re-evaluates the gates and starts/stops the timer accordingly.
  @protected
  void syncSecondTicker() {
    final want = mounted && _foreground && secondTickerActive;
    if (want && _secondTimer == null) {
      // Snap to the present first: the card may have been hidden for minutes.
      setState(() {});
      _secondTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    } else if (!want) {
      _secondTimer?.cancel();
      _secondTimer = null;
    }
  }

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
