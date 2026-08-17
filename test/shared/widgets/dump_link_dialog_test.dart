/// The dialog is the only place the uploaded link is ever shown. If it drops
/// the URL, truncates it, or closes itself, the dump that was just uploaded is
/// unreachable — the paste exists and nobody knows where. So the tests here are
/// about the link surviving: shown whole, re-copyable, and not dismissed by the
/// button that copies it.
library;

import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/widgets/dump_link_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const String _url = 'https://haste.exptech.dev/ZeGjHxfZ';

/// Opens the dialog over a throwaway page, and returns a live record of what
/// has been written to the clipboard.
Future<List<String>> _open(WidgetTester tester, {String url = _url}) async {
  final copied = <String>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      if (call.method == 'Clipboard.setData') {
        copied.add((call.arguments as Map)['text'] as String);
      }
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    ),
  );

  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: ElevatedButton(
            onPressed: () => showDumpLinkDialog(context, url),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return copied;
}

void main() {
  testWidgets('the link is shown in full', (tester) async {
    await _open(tester);

    // `find.text` matches the whole string, so this fails on any truncation —
    // an ellipsis in the middle of a URL gives somebody a link that resolves
    // to nothing and no way to tell it apart from one that works.
    expect(find.text(_url), findsOneWidget);
  });

  testWidgets('the link can be selected, for the screenshot case', (
    tester,
  ) async {
    await _open(tester);

    expect(find.byType(SelectableText), findsOneWidget);
  });

  testWidgets('copying again does not close the dialog', (tester) async {
    final copied = await _open(tester);

    await tester.tap(find.text('Copy again'));
    await tester.pumpAndSettle();

    expect(copied, [_url]);
    // Still open. Closing on copy would be the trap: the one reason to press
    // it is that the first copy was lost, and a dialog that leaves on the
    // press cannot be pressed twice.
    expect(find.text(_url), findsOneWidget);
  });

  testWidgets('closing dismisses it', (tester) async {
    await _open(tester);

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    expect(find.text(_url), findsNothing);
  });

  testWidgets('a long link is not cut', (tester) async {
    final long = 'https://haste.exptech.dev/${'A' * 64}';
    await _open(tester, url: long);

    expect(find.text(long), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
