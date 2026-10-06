/// A forgotten disable leaves the phone awake after the mesh page is gone.
/// The scope has to take the hold when it appears and give it back when the
/// hold is no longer wanted, including when the platform call itself fails.
library;

import 'package:dpip/core/platform/screen_wake.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.exptech.dpip/screen_wake');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final calls = <String>[];
  var fail = false;

  setUp(() {
    calls.clear();
    fail = false;
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method);
      if (fail) throw PlatformException(code: 'wake');
      return null;
    });
  });

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('enable and disable name the matching methods', () async {
    await ScreenWake.enable();
    await ScreenWake.disable();
    expect(calls, ['enable', 'disable']);
  });

  test('a platform failure is swallowed', () async {
    fail = true;
    await ScreenWake.enable();
    expect(calls, ['enable']);
  });

  testWidgets('the scope holds only while it is enabled and mounted', (
    tester,
  ) async {
    var enabled = true;
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) => Column(
            children: [
              ScreenWakeScope(enabled: enabled, child: const Text('mesh')),
              TextButton(
                onPressed: () => setState(() => enabled = !enabled),
                child: const Text('toggle'),
              ),
            ],
          ),
        ),
      ),
    );
    expect(calls, ['enable']);

    await tester.tap(find.text('toggle'));
    await tester.pump();
    expect(calls, ['enable', 'disable']);

    await tester.tap(find.text('toggle'));
    await tester.pump();
    expect(calls, ['enable', 'disable', 'enable']);

    await tester.pumpWidget(const SizedBox());
    expect(calls, ['enable', 'disable', 'enable', 'disable']);
  });
}
