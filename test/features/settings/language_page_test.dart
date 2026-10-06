/// The language list is "follow system" plus every ARB's own name. A missing
/// row, or a check that stays on the old locale after a tap, would leave the
/// app speaking a language the user just rejected.
library;

import 'package:dpip/core/settings/locale_controller.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:dpip/features/settings/presentation/pages/language_page.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

const Size _tall = Size(400, 3000);

Future<LocaleController> _pump(WidgetTester tester) async {
  tester.view.physicalSize = _tall;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final controller = LocaleController(SettingsStore.inMemory());
  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: controller,
      child: MaterialApp(
        locale: controller.locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const LanguagePage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return controller;
}

void main() {
  testWidgets('follow-system is checked until a language is chosen', (
    tester,
  ) async {
    final controller = await _pump(tester);
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));

    expect(find.text(l10n.languageSettings), findsOneWidget);
    expect(find.text(l10n.languageSystem), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('繁體中文(臺灣)'), findsWidgets);
    expect(find.text('日本語'), findsOneWidget);
    expect(controller.locale, isNull);
    expect(find.byIcon(Icons.check), findsOneWidget);

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    expect(controller.locale, const Locale('en'));

    await tester.tap(find.text(l10n.languageSystem));
    await tester.pumpAndSettle();
    expect(controller.locale, isNull);
  });
}
