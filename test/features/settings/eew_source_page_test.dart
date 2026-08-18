import 'package:dpip/core/settings/eew_cwa_only_settings.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:dpip/features/settings/presentation/pages/eew_source_page.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('shows the saved source and switches to all sources', (
    tester,
  ) async {
    final settings = EewCwaOnlySettings(SettingsStore.inMemory());
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: settings,
        child: MaterialApp(
          locale: const Locale('zh', 'TW'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const EewSourcePage(),
        ),
      ),
    );

    expect(settings.enabled, isTrue);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);

    await tester.tap(find.text('所有來源'));
    await tester.pump();

    expect(settings.enabled, isFalse);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });
}
