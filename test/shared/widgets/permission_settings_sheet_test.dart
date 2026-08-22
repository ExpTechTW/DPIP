import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/widgets/permission_settings_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('en'),
  home: Scaffold(body: child),
);

void main() {
  testWidgets('shows the exact instruction before opening Settings', (
    tester,
  ) async {
    var opens = 0;
    bool? result;
    await tester.pumpWidget(
      _wrap(
        Builder(
          builder: (context) => FilledButton(
            onPressed: () async {
              result = await promptForSystemSettings(
                context,
                what: 'Background location',
                guide: const PermissionSettingsGuide(
                  instruction: 'Permissions → Location → Always allow',
                ),
                openSettings: () async {
                  opens++;
                  return true;
                },
              );
            },
            child: const Text('Show'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Background location'), findsOneWidget);
    expect(find.text('Permissions → Location → Always allow'), findsOneWidget);
    expect(opens, 0, reason: 'settings must not open before confirmation');

    await tester.tap(find.text('Open Settings'));
    await tester.pumpAndSettle();

    expect(opens, 1);
    expect(result, isTrue);
  });

  testWidgets('cancel keeps the user in the app', (tester) async {
    var opens = 0;
    bool? result;
    await tester.pumpWidget(
      _wrap(
        Builder(
          builder: (context) => FilledButton(
            onPressed: () async {
              result = await promptForSystemSettings(
                context,
                what: 'Notifications',
                openSettings: () async {
                  opens++;
                  return true;
                },
              );
            },
            child: const Text('Show'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(opens, 0);
    expect(result, isFalse);
  });
}
