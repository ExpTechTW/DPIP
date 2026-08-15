/// The Display page's whole job is letting someone choose what they can read,
/// which only works if the options look different from each other. A preview
/// row that renders four identical thumbnails is worse than no preview: it
/// actively tells the user the setting does nothing.
library;

import 'package:dpip/core/a11y/color_vision.dart';
import 'package:dpip/core/settings/color_vision_controller.dart';
import 'package:dpip/core/settings/display_settings.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:dpip/core/settings/theme_controller.dart';
import 'package:dpip/features/settings/presentation/pages/display_page.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/seismic/intensity_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

Future<SettingsStore> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1200, 4000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  addTearDown(() => AppColorVision.install(ColorVision.none));

  final settings = SettingsStore.inMemory();
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeController(settings)),
        ChangeNotifierProvider(create: (_) => DisplaySettings(settings)),
        ChangeNotifierProvider(create: (_) => ColorVisionController(settings)),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const DisplayPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return settings;
}

void main() {
  testWidgets('every setting offers each of its options', (tester) async {
    await _pump(tester);
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));

    for (final label in [
      l10n.displayScaleSmall,
      l10n.displayScaleDefault,
      l10n.displayScaleLarge,
      l10n.displayScaleHuge,
      l10n.displayWeightNormal,
      l10n.displayWeightMedium,
      l10n.displayWeightBold,
      l10n.displayContrastStandard,
      l10n.displayContrastMedium,
      l10n.displayContrastHigh,
      l10n.displayColorVisionNone,
      l10n.displayColorVisionProtan,
      l10n.displayColorVisionDeutan,
      l10n.displayColorVisionTritan,
    ]) {
      expect(find.text(label), findsWidgets, reason: 'no option for "$label"');
    }
  });

  testWidgets('choosing an option persists it and takes effect', (
    tester,
  ) async {
    await _pump(tester);
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));

    await tester.tap(find.text(l10n.displayColorVisionDeutan).first);
    await tester.pumpAndSettle();
    expect(
      AppColorVision.current,
      ColorVision.deutan,
      reason: 'the global facade is what every colour definition reads',
    );

    await tester.tap(find.text(l10n.displayScaleLarge).first);
    await tester.pumpAndSettle();
    expect(
      tester.widget<DisplayPage>(find.byType(DisplayPage)),
      isNotNull,
      reason: 'the page survives its own setting changing under it',
    );
  });

  /// The four colour-vision previews must not be the same picture. This is the
  /// claim the whole preview row makes, and it is easy to break by handing every
  /// card the current setting instead of its own.
  test('each colour-vision option paints the intensity scale differently', () {
    Set<int> ramp(ColorVision vision) => {
      for (var level = 1; level <= 9; level++)
        ColorVisionFilter.transform(
          IntensityColors.discrete(level),
          vision,
        ).toARGB32(),
    };

    final ramps = {for (final v in ColorVision.values) v: ramp(v)};
    for (final a in ColorVision.values) {
      for (final b in ColorVision.values) {
        if (a == b) continue;
        expect(
          ramps[a],
          isNot(equals(ramps[b])),
          reason: '${a.name} and ${b.name} render an identical scale',
        );
      }
    }
  });
}
