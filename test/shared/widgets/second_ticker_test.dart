/// The countdown used to keep a Timer running behind other tabs and under
/// the lock screen. This ticker has to stop when the host or the app is
/// hidden, and tick again the moment either comes back.
library;

import 'package:dpip/shared/widgets/second_ticker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ticks while visible and stops when the host or app hides', (
    tester,
  ) async {
    var active = true;
    late _HostState host;
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) => Column(
            children: [
              _Host(active: active, onState: (state) => host = state),
              TextButton(
                onPressed: () => setState(() => active = false),
                child: const Text('hide'),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    final built = host.builds;

    await tester.pump(const Duration(seconds: 1));
    expect(host.builds, greaterThan(built));

    await tester.tap(find.text('hide'));
    await tester.pump();
    final hidden = host.builds;
    await tester.pump(const Duration(seconds: 2));
    expect(host.builds, hidden);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    // The host is still inactive, so coming back to the foreground does not
    // resume the timer.
    expect(host.builds, hidden);
  });

  testWidgets('ticks land on whole seconds of the clock, not of the mount', (
    tester,
  ) async {
    final stamps = <DateTime>[];
    // Mount at an arbitrary fraction of a second.
    await tester.pump(const Duration(milliseconds: 370));
    await tester.pumpWidget(
      MaterialApp(
        home: _AlignedHost(
          now: () => tester.binding.clock.now().toUtc(),
          onTick: stamps.add,
        ),
      ),
    );
    expect(
      stamps.single.microsecondsSinceEpoch % 1000000,
      isNot(0),
      reason:
          'the mount itself must be off the second for this to test '
          'anything — a periodic timer from an on-second mount would pass too',
    );
    stamps.clear();
    await tester.pump(const Duration(milliseconds: 3500));

    expect(stamps.length, greaterThanOrEqualTo(3));
    for (final stamp in stamps) {
      expect(
        stamp.microsecondsSinceEpoch % 1000000,
        0,
        reason: 'tick at $stamp is off the second',
      );
    }
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a host can move the ticks to its own phase and re-aim them', (
    tester,
  ) async {
    final stamps = <DateTime>[];
    final key = GlobalKey<_AlignedHostState>();
    await tester.pumpWidget(
      MaterialApp(
        home: _AlignedHost(
          key: key,
          now: () => tester.binding.clock.now().toUtc(),
          onTick: stamps.add,
          phase: const Duration(milliseconds: 340),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 1));
    stamps.clear();
    await tester.pump(const Duration(milliseconds: 2500));
    expect(stamps, isNotEmpty);
    for (final stamp in stamps) {
      expect(stamp.microsecondsSinceEpoch % 1000000, 340000);
    }

    key.currentState!.movePhase(const Duration(milliseconds: 800));
    stamps.clear();
    await tester.pump(const Duration(milliseconds: 2500));
    expect(stamps, isNotEmpty);
    for (final stamp in stamps) {
      expect(stamp.microsecondsSinceEpoch % 1000000, 800000);
    }
    await tester.pumpWidget(const SizedBox());
  });
}

class _Host extends StatefulWidget {
  const _Host({required this.active, required this.onState});

  final bool active;
  final ValueChanged<_HostState> onState;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> with SecondTicker {
  int builds = 0;

  @override
  bool get secondTickerActive => widget.active;

  @override
  void didUpdateWidget(_Host oldWidget) {
    super.didUpdateWidget(oldWidget);
    syncSecondTicker();
  }

  @override
  Widget build(BuildContext context) {
    builds++;
    widget.onState(this);
    return Text('ticks $builds');
  }
}

/// Records the clock reading of every tick, on a phase it can move.
class _AlignedHost extends StatefulWidget {
  const _AlignedHost({
    super.key,
    required this.now,
    required this.onTick,
    this.phase,
  });

  final DateTime Function() now;
  final ValueChanged<DateTime> onTick;
  final Duration? phase;

  @override
  State<_AlignedHost> createState() => _AlignedHostState();
}

class _AlignedHostState extends State<_AlignedHost> with SecondTicker {
  late Duration? _phase = widget.phase;

  void movePhase(Duration phase) {
    _phase = phase;
    realignSecondTicker();
  }

  @override
  DateTime secondTickerNow() => widget.now();

  @override
  Duration secondTickerDelay(DateTime now) {
    final phase = _phase;
    if (phase == null) return super.secondTickerDelay(now);
    final into = (now.microsecondsSinceEpoch - phase.inMicroseconds) % 1000000;
    return Duration(microseconds: 1000000 - into);
  }

  /// Stamped where the tick lands, not at the frame that follows it — a
  /// test pump renders one frame at its end, however many ticks it spans.
  @override
  void setState(VoidCallback fn) {
    widget.onTick(secondTickerNow());
    super.setState(fn);
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}
