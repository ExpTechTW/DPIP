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
