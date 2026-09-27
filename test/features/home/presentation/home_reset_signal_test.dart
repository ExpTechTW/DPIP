/// A bare event bus: `main_shell.dart` calls `fire()` when the Home tab is
/// re-tapped while already active, and both `home_page.dart` and
/// `home_map_backdrop.dart` listen for it to snap their view back to the
/// default state. There is no payload and no guard — the entire contract is
/// "every listener gets notified every time `fire()` runs" — so the one thing
/// worth pinning down is that repeated fires keep reaching a listener that
/// stays subscribed, and a removed listener stops hearing them.
library;

import 'package:dpip/features/home/presentation/home_reset_signal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fire notifies a listener every time, not just once', () {
    final signal = HomeResetSignal();
    var count = 0;
    signal.addListener(() => count++);

    signal.fire();
    signal.fire();
    signal.fire();

    expect(count, 3);
  });

  test('a removed listener no longer hears fire', () {
    final signal = HomeResetSignal();
    var count = 0;
    void listener() => count++;

    signal
      ..addListener(listener)
      ..fire();
    expect(count, 1);

    signal
      ..removeListener(listener)
      ..fire();
    expect(count, 1);
  });
}
