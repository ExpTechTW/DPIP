/// The Experimental features page is built from a registry: each option says
/// which category it sits in, where it is offered, which sensors it needs, and
/// whether it waits for the Developer page's unlock.
///
/// Each of those is a way for an option to silently show up somewhere it does
/// not work — an Android-only switch on an iPhone, a seismometer on a phone
/// with no accelerometer, a debugging override in front of every user — or to
/// silently vanish, which nothing else notices.
library;

import 'dart:async';

import 'package:dpip/core/platform/device_sensors.dart';
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
  Set<DeviceSensor> requiredSensors = const {},
}) => ExperimentalOption(
  category: category,
  platforms: platforms,
  requiresUnlock: requiresUnlock,
  requiredSensors: requiredSensors,
  build: (_, _) => ListTile(title: Text(label)),
);

/// A device with every sensor there is.
const Set<DeviceSensor> _allSensors = {DeviceSensor.accelerometer};

/// Pumps the page over [options] (the real registry when null), on a device
/// with [sensors] (every one there is unless a test says otherwise).
Future<ExperimentalSettings> _pump(
  WidgetTester tester, {
  List<ExperimentalOption>? options,
  bool unlocked = false,
  DeviceSensors? sensors,
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
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider.value(
          value: sensors ?? DeviceSensors.known(_allSensors),
        ),
      ],
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
      sensors: _allSensors,
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
    expect(
      hidden.isOffered(TargetPlatform.iOS, unlocked: false, sensors: const {}),
      isFalse,
    );
    expect(
      hidden.isOffered(TargetPlatform.iOS, unlocked: true, sensors: const {}),
      isTrue,
    );
  });

  test('an option that needs a sensor is offered only where it is', () {
    final needy = _option(
      'needy',
      ExperimentalCategory.tools,
      requiredSensors: const {DeviceSensor.accelerometer},
    );
    final plain = _option('plain', ExperimentalCategory.tools);
    expect(
      needy.isOffered(
        TargetPlatform.android,
        unlocked: true,
        sensors: const {},
      ),
      isFalse,
    );
    expect(
      needy.isOffered(
        TargetPlatform.android,
        unlocked: true,
        sensors: _allSensors,
      ),
      isTrue,
    );
    // Needing nothing is satisfied by nothing.
    expect(
      plain.isOffered(
        TargetPlatform.android,
        unlocked: false,
        sensors: const {},
      ),
      isTrue,
    );
    // And the category it leaves empty goes with it.
    expect(
      experimentalSections(
        [needy],
        platform: TargetPlatform.android,
        unlocked: true,
        sensors: const {},
      ),
      isEmpty,
    );
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

  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
    testWidgets(
      'the seismometer switch is offered on ${platform.name} without unlock',
      (tester) async {
        await _on(platform, () async {
          final settings = await _pump(tester);
          final l10n = await _en();

          expect(settings.unlocked, isFalse);
          expect(find.text(l10n.experimentalCategoryTools), findsOneWidget);
          expect(find.text(l10n.experimentalSeismometer), findsOneWidget);
          expect(
            find.text(l10n.experimentalSeismometerSubtitle),
            findsOneWidget,
          );
          expect(
            _top(tester, l10n.experimentalSeismometer),
            greaterThan(_top(tester, l10n.experimentalCategoryTools)),
          );
          // Off until the user turns it on.
          final toggle = tester.widget<SwitchListTile>(
            find.byType(SwitchListTile),
          );
          expect(toggle.value, isFalse);
        });
      },
    );
  }

  testWidgets('a desktop sees nothing before the unlock', (tester) async {
    await _on(TargetPlatform.macOS, () async {
      await _pump(tester);
      final l10n = await _en();

      // The seismometer is phone-only and the backdrop overrides wait for the
      // unlock, so the real registry leaves the page empty here.
      expect(find.text(l10n.experimentalSeismometer), findsNothing);
      expect(find.byType(SectionHeader), findsNothing);
      expect(find.byType(ListTile), findsNothing);
    });
  });

  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
    testWidgets('a ${platform.name} phone with no accelerometer is offered no '
        'seismometer', (tester) async {
      await _on(platform, () async {
        await _pump(tester, sensors: DeviceSensors.known(const {}));
        final l10n = await _en();

        expect(find.text(l10n.experimentalSeismometer), findsNothing);
        // It was the only tool, so the Tools header goes with it; the
        // backdrop overrides still wait for the unlock, so nothing is left.
        expect(find.text(l10n.experimentalCategoryTools), findsNothing);
        expect(find.byType(SectionHeader), findsNothing);
        expect(find.byType(SwitchListTile), findsNothing);
      });
    });
  }

  testWidgets('the seismometer waits for the accelerometer answer', (
    tester,
  ) async {
    final answer = Completer<bool>();
    final sensors = DeviceSensors(
      probes: {DeviceSensor.accelerometer: () => answer.future},
    );
    unawaited(sensors.resolve());
    await _pump(tester, sensors: sensors);
    final l10n = await _en();

    // Not known yet, so not offered: it may arrive late, but it is never shown
    // and then taken back.
    expect(find.text(l10n.experimentalSeismometer), findsNothing);
    expect(find.text(l10n.experimentalCategoryTools), findsNothing);

    answer.complete(true);
    await tester.pumpAndSettle();
    expect(find.text(l10n.experimentalCategoryTools), findsOneWidget);
    expect(find.text(l10n.experimentalSeismometer), findsOneWidget);
  });

  testWidgets('a failed accelerometer probe offers no seismometer', (
    tester,
  ) async {
    final sensors = DeviceSensors(
      probes: {
        DeviceSensor.accelerometer: () async =>
            throw StateError('no sensor service'),
      },
    );
    await sensors.resolve();
    await _pump(tester, sensors: sensors);
    final l10n = await _en();

    expect(find.text(l10n.experimentalSeismometer), findsNothing);
    expect(find.text(l10n.experimentalCategoryTools), findsNothing);
  });

  testWidgets('the seismometer switch turns the option on and off', (
    tester,
  ) async {
    final settings = await _pump(tester);
    final l10n = await _en();

    await tester.tap(find.text(l10n.experimentalSeismometer));
    await tester.pumpAndSettle();
    expect(settings.seismometerEnabled, isTrue);
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
      isTrue,
    );

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(settings.seismometerEnabled, isFalse);
  });
}
