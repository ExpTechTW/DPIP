/// The Experimental features page is built from a registry: each option says
/// which category it sits in, where it is offered, and whether it waits for the
/// Developer page's unlock.
///
/// Each of those is a way for an option to silently show up somewhere it does
/// not work — an Android-only switch on an iPhone, a debugging override in
/// front of every user — or to silently vanish, which nothing else notices.
library;

import 'package:dpip/core/settings/experimental_settings.dart';
import 'package:dpip/core/settings/locale_config.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:dpip/features/settings/presentation/experimental/experimental_option.dart';
import 'package:dpip/features/settings/presentation/pages/experimental_page.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/widgets/section_header.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

const Size _tall = Size(400, 4000);

/// An option whose tile is a single row reading [label].
ExperimentalOption _option(
  String label,
  ExperimentalCategory category, {
  Set<TargetPlatform> platforms = everyPlatform,
  bool requiresUnlock = false,
}) => ExperimentalOption(
  category: category,
  platforms: platforms,
  requiresUnlock: requiresUnlock,
  build: (_, _) => ListTile(title: Text(label)),
);

/// Pumps the page over [options] (the real registry when null).
Future<ExperimentalSettings> _pump(
  WidgetTester tester, {
  List<ExperimentalOption>? options,
  bool unlocked = false,
}) async {
  tester.view.physicalSize = _tall;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final settings = ExperimentalSettings(SettingsStore.inMemory());
  if (unlocked) await settings.unlock();
  final page = options == null
      ? ExperimentalPage(watchWeatherCode: (_) => null)
      : ExperimentalPage(watchWeatherCode: (_) => null, options: options);
  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: settings,
      child: MaterialApp(
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: page,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return settings;
}

/// Runs [body] with `defaultTargetPlatform` forced to [platform], and puts it
/// back before the test ends — the binding fails a test that leaves the
/// override set.
Future<void> _on(TargetPlatform platform, Future<void> Function() body) async {
  debugDefaultTargetPlatformOverride = platform;
  try {
    await body();
  } finally {
    debugDefaultTargetPlatformOverride = null;
  }
}

double _top(WidgetTester tester, String text) =>
    tester.getTopLeft(find.text(text)).dy;

Future<AppLocalizations> _en() =>
    AppLocalizations.delegate.load(const Locale('en'));

void main() {
  test('everyPlatform names every TargetPlatform', () {
    expect(everyPlatform, TargetPlatform.values.toSet());
  });

  test('sections follow category order and drop the empty ones', () {
    final tools = _option('tool', ExperimentalCategory.tools);
    final sound = _option('sound', ExperimentalCategory.sound);
    final sections = experimentalSections(
      [tools, sound],
      platform: TargetPlatform.android,
      unlocked: false,
    );
    expect(sections.map((s) => s.$1), [
      ExperimentalCategory.sound,
      ExperimentalCategory.tools,
    ]);
    expect(sections.first.$2, [sound]);
    expect(sections.last.$2, [tools]);
  });

  test('an unlock-only option is offered only once unlocked', () {
    final hidden = _option(
      'hidden',
      ExperimentalCategory.graphics,
      requiresUnlock: true,
    );
    expect(hidden.isOffered(TargetPlatform.iOS, unlocked: false), isFalse);
    expect(hidden.isOffered(TargetPlatform.iOS, unlocked: true), isTrue);
  });

  testWidgets('groups options by category in the fixed order', (tester) async {
    // Registered out of order on purpose: the page orders by category, and
    // keeps registry order within one.
    await _pump(
      tester,
      options: [
        _option('Tool A', ExperimentalCategory.tools),
        _option('Sound A', ExperimentalCategory.sound),
        _option('Graphics A', ExperimentalCategory.graphics),
        _option('Sound B', ExperimentalCategory.sound),
      ],
    );
    final l10n = await _en();

    expect(find.byType(SectionHeader), findsNWidgets(3));
    final order = [
      l10n.experimentalCategorySound,
      'Sound A',
      'Sound B',
      l10n.experimentalCategoryGraphics,
      'Graphics A',
      l10n.experimentalCategoryTools,
      'Tool A',
    ];
    for (var i = 1; i < order.length; i++) {
      expect(
        _top(tester, order[i]),
        greaterThan(_top(tester, order[i - 1])),
        reason: '"${order[i]}" should sit below "${order[i - 1]}"',
      );
    }
  });

  testWidgets('a category with no option has no header', (tester) async {
    await _pump(
      tester,
      options: [
        _option('Sound A', ExperimentalCategory.sound),
        _option('Tool A', ExperimentalCategory.tools),
      ],
    );
    final l10n = await _en();

    expect(find.text(l10n.experimentalCategorySound), findsOneWidget);
    expect(find.text(l10n.experimentalCategoryGraphics), findsNothing);
    expect(find.text(l10n.experimentalCategoryTools), findsOneWidget);
  });

  testWidgets('lists only what the current platform offers', (tester) async {
    final options = [
      _option(
        'Android only',
        ExperimentalCategory.sound,
        platforms: const {TargetPlatform.android},
      ),
      _option(
        'iOS only',
        ExperimentalCategory.tools,
        platforms: const {TargetPlatform.iOS},
      ),
      _option('Everywhere', ExperimentalCategory.tools),
    ];
    final l10n = await _en();

    await _on(TargetPlatform.android, () async {
      await _pump(tester, options: options);
      expect(find.text('Android only'), findsOneWidget);
      expect(find.text('iOS only'), findsNothing);
      expect(find.text('Everywhere'), findsOneWidget);
      expect(find.text(l10n.experimentalCategorySound), findsOneWidget);
    });

    await _on(TargetPlatform.iOS, () async {
      await _pump(tester, options: options);
      expect(find.text('Android only'), findsNothing);
      expect(find.text('iOS only'), findsOneWidget);
      expect(find.text('Everywhere'), findsOneWidget);
      // Its only option is Android's, so on iOS the category goes with it.
      expect(find.text(l10n.experimentalCategorySound), findsNothing);
    });
  });

  testWidgets('weather and sky stay hidden until the unlock, then show', (
    tester,
  ) async {
    final settings = await _pump(tester);
    final l10n = await _en();

    expect(settings.unlocked, isFalse);
    expect(find.text(l10n.experimentalCategoryGraphics), findsNothing);
    expect(find.text(l10n.weatherDynamicState), findsNothing);
    expect(find.text(l10n.skyTime), findsNothing);
    expect(find.text(l10n.weatherModeRain), findsNothing);

    await settings.unlock();
    await tester.pumpAndSettle();

    expect(find.text(l10n.experimentalCategoryGraphics), findsOneWidget);
    expect(find.text(l10n.weatherDynamicState), findsOneWidget);
    expect(find.text(l10n.skyTime), findsOneWidget);
    expect(find.text(l10n.weatherModeRain), findsOneWidget);
    expect(
      _top(tester, l10n.weatherDynamicState),
      greaterThan(_top(tester, l10n.experimentalCategoryGraphics)),
    );
  });

  testWidgets('with nothing offered the page body is empty', (tester) async {
    await _pump(
      tester,
      options: [
        _option(
          'Elsewhere',
          ExperimentalCategory.sound,
          platforms: const {TargetPlatform.iOS},
        ),
        _option('Locked', ExperimentalCategory.graphics, requiresUnlock: true),
      ],
    );
    final l10n = await _en();

    // The app bar still names the page; under it there is nothing — no
    // header, no row, and no placeholder message either.
    expect(find.text(l10n.experimentalFeatures), findsOneWidget);
    expect(find.byType(SectionHeader), findsNothing);
    expect(find.byType(ListTile), findsNothing);
    final list = tester.widget<ListView>(find.byType(ListView));
    expect(list.childrenDelegate.estimatedChildCount, 0);
  });
}
