/// Home and Events both follow the region bar through this mixin. A selection
/// change that never moves the page, or an off-screen change that is not
/// caught up when the page comes back, leaves the two tabs on different towns.
library;

import 'package:dpip/core/settings/region_store.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:dpip/shared/widgets/area_page_sync.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _Host extends StatefulWidget {
  const _Host({required this.attached});

  final bool attached;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> with AreaPageSyncMixin {
  @override
  Widget build(BuildContext context) {
    final index = context.watch<RegionStore>().selectedIndex;
    syncAreaPageOffscreen(index);
    if (!widget.attached) return Text('page ${areaPage.round()}');
    return PageView(
      controller: areaPageController,
      children: const [Text('nationwide'), Text('here'), Text('saved')],
    );
  }
}

class _Peek extends StatefulWidget {
  const _Peek();

  @override
  State<_Peek> createState() => _PeekState();
}

class _PeekState extends State<_Peek> with AreaPageSyncMixin {
  @override
  double get areaViewportFraction => 0.5;

  @override
  Widget build(BuildContext context) {
    return PageView(
      controller: areaPageController,
      children: const [Text('a'), Text('b')],
    );
  }
}

void main() {
  testWidgets('animates to a new selection and jumps when it missed one', (
    tester,
  ) async {
    final regions = RegionStore(SettingsStore.inMemory())..addSaved('6300100');
    var attached = true;
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: regions,
        child: MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  children: [
                    TextButton(
                      onPressed: () => setState(() => attached = !attached),
                      child: const Text('toggle'),
                    ),
                    Expanded(child: _Host(attached: attached)),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('here'), findsOneWidget);

    regions.select(2);
    await tester.pumpAndSettle();
    expect(find.text('saved'), findsOneWidget);

    await tester.tap(find.text('toggle'));
    await tester.pumpAndSettle();
    regions.select(0);
    await tester.tap(find.text('toggle'));
    await tester.pump();
    await tester.pump();
    expect(find.text('nationwide'), findsOneWidget);
  });

  testWidgets('a peeking carousel uses the overridden viewport fraction', (
    tester,
  ) async {
    final regions = RegionStore(SettingsStore.inMemory());
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: regions,
        child: const MaterialApp(home: Scaffold(body: _Peek())),
      ),
    );
    final state = tester.state<_PeekState>(find.byType(_Peek));
    expect(state.areaPageController.viewportFraction, 0.5);
    expect(state.areaPage, 1);
  });
}
