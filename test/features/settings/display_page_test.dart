/// The Display page's whole job is letting someone choose what they can read.
/// That puts two things under test that a settings page normally would not:
/// the options have to be *distinguishable* (a colour-vision picker whose four
/// swatches are the same picture actively tells the user the setting does
/// nothing), and the page has to survive its own largest text step — a preview
/// that overflows at 1.45 discredits the setting it is demonstrating.
library;

import 'package:dpip/core/a11y/color_vision.dart';
import 'package:dpip/core/settings/color_vision_controller.dart';
import 'package:dpip/core/settings/display_settings.dart';
import 'package:dpip/core/settings/setting_keys.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:dpip/core/settings/theme_controller.dart';
import 'package:dpip/features/settings/presentation/pages/display_page.dart';
import 'package:dpip/features/settings/presentation/widgets/display_preview.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/seismic/intensity_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// A small phone, in logical pixels — the width the option rows have to fit.
const Size _phone = Size(320, 568);

/// Portrait, and tall enough that the whole option list is laid out at once —
/// a `ListView` only builds what its viewport reaches, so a realistic height
/// would put the last setting outside the element tree and `find.text` would
/// report it missing rather than off-screen.
const Size _tall = Size(400, 3000);

Future<SettingsStore> _pump(
  WidgetTester tester, {
  Size size = _tall,
  double scale = 1,
}) async {
  tester.view.physicalSize = size;
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
        // Stands in for the ComposedTextScaler the real app installs at its
        // root, so the page is exercised at the sizes it offers.
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: const DisplayPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return settings;
}

Future<AppLocalizations> _en() =>
    AppLocalizations.delegate.load(const Locale('en'));

void main() {
  testWidgets('every setting offers each of its options', (tester) async {
    await _pump(tester);
    final l10n = await _en();

    for (final label in [
      l10n.themeSystem,
      l10n.themeLight,
      l10n.themeDark,
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

  testWidgets('the sample sits above the options and never scrolls away', (
    tester,
  ) async {
    // A real phone, where the options genuinely have somewhere to scroll to.
    await _pump(tester, size: _phone);
    final l10n = await _en();

    expect(find.byType(DisplayPreview), findsOneWidget);
    final previewTop = tester.getTopLeft(find.byType(DisplayPreview)).dy;
    expect(
      previewTop,
      lessThan(tester.getTopLeft(find.text(l10n.displayTheme)).dy),
      reason: 'the sample is the first thing on the page',
    );

    // Fling the options as hard as the list allows; the sample must not move.
    await tester.fling(
      find.text(l10n.displayTheme),
      const Offset(0, -600),
      3000,
    );
    await tester.pumpAndSettle();

    expect(find.byType(DisplayPreview), findsOneWidget);
    expect(
      tester.getTopLeft(find.byType(DisplayPreview)).dy,
      previewTop,
      reason: 'the sample is a sibling of the scrollable, not inside it',
    );
  });

  testWidgets('choosing an option persists it and takes effect', (
    tester,
  ) async {
    final settings = await _pump(tester);
    final l10n = await _en();

    await tester.tap(find.text(l10n.displayColorVisionDeutan).first);
    await tester.pumpAndSettle();
    expect(
      AppColorVision.current,
      ColorVision.deutan,
      reason: 'the global facade is what every colour definition reads',
    );
    expect(settings.getString(SettingKeys.colorVision), 'deutan');

    await tester.tap(find.text(l10n.displayScaleLarge).first);
    await tester.pumpAndSettle();
    expect(settings.getString(SettingKeys.textScale), 'large');

    await tester.tap(find.text(l10n.themeDark).first);
    await tester.pumpAndSettle();
    expect(settings.getString(SettingKeys.themeMode), 'dark');

    expect(
      find.byType(DisplayPreview),
      findsOneWidget,
      reason: 'the sample survives every setting changing under it',
    );
  });

  /// The setting this page exists for is the one whose effect is invisible on a
  /// settings page, so the swatches are the only thing carrying it. They must
  /// not be the same picture four times.
  testWidgets('the four colour-vision options paint four different swatches', (
    tester,
  ) async {
    await _pump(tester);

    Set<int> swatch(ColorVision vision) => {
      for (final level in [2, 3, 4, 7])
        ColorVisionFilter.transform(
          IntensityColors.published(level),
          vision,
        ).toARGB32(),
    };

    final swatches = {for (final v in ColorVision.values) v: swatch(v)};
    for (final a in ColorVision.values) {
      for (final b in ColorVision.values) {
        if (a == b) continue;
        expect(
          swatches[a],
          isNot(equals(swatches[b])),
          reason: '${a.name} and ${b.name} render an identical swatch',
        );
      }
    }
  });

  /// The bug this pins is invisible: with a correction already in force,
  /// `discrete` returns an *already* corrected colour, so a picker that
  /// transformed it again would daltonise a daltonised colour and every swatch
  /// would drift. The previous version of this page did exactly that, and the
  /// previous version of this test reproduced the same mistake — so it passed
  /// while asserting nothing.
  test('per-option swatches read the untransformed CWA table', () {
    addTearDown(() => AppColorVision.install(ColorVision.none));
    AppColorVision.install(ColorVision.deutan);

    expect(
      IntensityColors.published(4).toARGB32(),
      0xFFFFC800,
      reason: 'published must ignore whatever setting is in force',
    );
    expect(
      IntensityColors.discrete(4),
      isNot(IntensityColors.published(4)),
      reason: 'and discrete must still apply it, or the pin above is vacuous',
    );
  });

  /// A preview that overflows is worse than no preview, and it would overflow
  /// on exactly the setting whose users need it most.
  testWidgets('the page survives every text size on a small phone', (
    tester,
  ) async {
    for (final step in TextScaleStep.values) {
      await _pump(tester, size: _phone, scale: step.factor);
      expect(
        tester.takeException(),
        isNull,
        reason: 'overflow at text scale ${step.factor}',
      );
      expect(find.byType(DisplayPreview), findsOneWidget);
    }
  });

  testWidgets('landscape puts the sample beside the options, not above them', (
    tester,
  ) async {
    await _pump(tester, size: const Size(568, 320));
    final l10n = await _en();

    expect(tester.takeException(), isNull);
    final preview = tester.getTopLeft(find.byType(DisplayPreview));
    final options = tester.getTopLeft(find.text(l10n.displayTheme));
    expect(
      options.dx,
      greaterThan(preview.dx),
      reason: 'side by side, so the short screen keeps a full-size sample',
    );

    await tester.scrollUntilVisible(
      find.text(l10n.displayColorVisionTritan),
      120,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text(l10n.displayColorVisionTritan), findsOneWidget);
  });
}
