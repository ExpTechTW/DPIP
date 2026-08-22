/// The upload boundary must require an explicit privacy choice every time.
library;

import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/widgets/dump_upload_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<ValueNotifier<bool?>> open(WidgetTester tester) async {
    final result = ValueNotifier<bool?>(null);
    addTearDown(result.dispose);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () async {
                result.value = await showDumpUploadDialog(context);
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return result;
  }

  testWidgets('starts private and uploads without sensitive values', (
    tester,
  ) async {
    final result = await open(tester);

    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);
    await tester.tap(find.text('Upload'));
    await tester.pumpAndSettle();

    expect(result.value, isFalse);
    expect(find.byType(DumpUploadDialog), findsNothing);
  });

  testWidgets('including sensitive values requires an explicit check', (
    tester,
  ) async {
    final result = await open(tester);

    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
    await tester.tap(find.text('Upload'));
    await tester.pumpAndSettle();

    expect(result.value, isTrue);
  });

  testWidgets('cancel uploads nothing', (tester) async {
    final result = await open(tester);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(result.value, isNull);
  });

  testWidgets('remains usable on a small screen with large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await open(tester);

    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(find.text('Upload'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
