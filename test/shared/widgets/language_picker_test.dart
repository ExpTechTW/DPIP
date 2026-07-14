/// Regression test for the language picker: selecting "system default" must
/// clear the override. `PopupMenuButton` reports a null-valued selection as a
/// dismissal and swallows it, so the picker uses a non-null sentinel for the
/// "follow system" entry; this pins that selecting it actually clears the
/// override (the reported "switching back to default fails" bug).
library;

import 'package:dpip/core/settings/locale_controller.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/widgets/language_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dpip/core/settings/prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('selecting 系統預設 clears an existing override', (tester) async {
    // A tall surface so the whole menu fits (PopupMenuButton scrolls to
    // `initialValue`, which can push earlier items off a small window).
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({'app.locale': 'ja'});
    final controller = LocaleController(
      Prefs(await SharedPreferences.getInstance()),
    );
    expect(controller.locale, const Locale('ja'));

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: controller,
        child: const MaterialApp(
          locale: Locale('zh'),
          localizationsDelegates: [
            ...AppLocalizations.localizationsDelegates,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: Center(child: LanguagePicker())),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.language));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('系統預設'));
    await tester.tap(find.text('系統預設'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(
      controller.locale,
      isNull,
      reason: 'selecting system default must clear the override',
    );
  });
}
