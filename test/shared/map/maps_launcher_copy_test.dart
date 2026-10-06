/// Copying coordinates from the map-app picker writes `lat,lng` and confirms
/// it with a snackbar, without launching a map app.
library;

import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/map/maps_launcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('copy coordinates leaves the clipboard and a snackbar', (
    tester,
  ) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    const target = MapLaunchTarget(lat: 25.033, lng: 121.5654, label: '點');
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
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
        locale: const Locale('en'),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showMapAppPicker(context, target),
              child: const Text('pick'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('pick'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.mapAppCopyCoordinates));
    await tester.pumpAndSettle();
    expect(copied, '25.033,121.5654');
    expect(find.text(l10n.mapAppCoordinatesCopied), findsOneWidget);
  });
}
