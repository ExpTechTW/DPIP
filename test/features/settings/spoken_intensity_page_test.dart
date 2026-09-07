/// The spoken-intensity page.
///
/// The trade this setting makes — speech delays the warning sound — is stated
/// in the note under the switch and nowhere else, so a page that stopped
/// showing it while the switch is off would quietly turn an informed choice
/// into a blind one.
library;

import 'package:dpip/core/settings/eew_spoken_announcement_settings.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:dpip/features/settings/presentation/pages/spoken_intensity_page.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

Future<void> _pump(
  WidgetTester tester,
  EewSpokenAnnouncementSettings settings,
) => tester.pumpWidget(
  ChangeNotifierProvider.value(
    value: settings,
    child: MaterialApp(
      locale: const Locale('zh', 'TW'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const SpokenIntensityPage(),
    ),
  ),
);

void main() {
  testWidgets('opens off and the switch turns it on', (tester) async {
    final settings = EewSpokenAnnouncementSettings(SettingsStore.inMemory());
    await _pump(tester, settings);

    expect(settings.enabled, isFalse);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
    expect(find.text('關閉'), findsOneWidget);

    await tester.tap(find.byType(Switch));
    await tester.pump();

    expect(settings.enabled, isTrue);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
    expect(find.text('開啟'), findsOneWidget);
  });

  testWidgets('tapping the card toggles it too', (tester) async {
    final settings = EewSpokenAnnouncementSettings(SettingsStore.inMemory());
    await _pump(tester, settings);

    // The row is the target, not just the switch — hit the card's title (the
    // app bar carries the same text, so scope to the tappable surface).
    final cardTitle = find.descendant(
      of: find.byType(InkWell),
      matching: find.text('朗讀預估震度'),
    );
    await tester.tap(cardTitle);
    await tester.pump();
    expect(settings.enabled, isTrue);

    await tester.tap(cardTitle);
    await tester.pump();
    expect(settings.enabled, isFalse);
  });

  testWidgets('the delay note is shown while the switch is off', (
    tester,
  ) async {
    await _pump(
      tester,
      EewSpokenAnnouncementSettings(SettingsStore.inMemory()),
    );

    // The cost, not just the label: a user turning this on is accepting a
    // slower warning, and they have to be able to read that before they do.
    expect(find.textContaining('警示音會因此延後'), findsOneWidget);
  });
}
