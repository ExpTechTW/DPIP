import 'package:dpip/features/map/presentation/layers/satellite_layer.dart';
import 'package:dpip/features/map/presentation/widgets/satellite_style_menu.dart';
import 'package:dpip/features/weather/domain/satellite_channel.dart';
import 'package:dpip/features/weather/domain/satellite_repository.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/widgets/map_chip_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'raster_timeline_harness.dart';

class _FakeSatelliteRepository extends FakeRasterFrameSource
    implements SatelliteRepository {
  _FakeSatelliteRepository() : super(const []);

  String? style;

  @override
  String tileUrl(String frame) => 'https://host/$frame/{z}/{x}/{y}.webp';

  @override
  void setStyle(String? value) => style = value;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // The menu opens a dropdown that needs vertical room; default 800×600 crops
  // the bottom rows so a tap on them fails as "not hittable".
  void useTallSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<AppLocalizations> loadL10n() =>
      AppLocalizations.delegate.load(const Locale('en'));

  Widget wrap(SatelliteStyleMenu menu) => MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: Scaffold(
      body: Align(alignment: Alignment.topRight, child: menu),
    ),
  );

  testWidgets('a raw band offers the three colour styles, gray selected', (
    tester,
  ) async {
    useTallSurface(tester);
    final layer = SatelliteMapLayer(
      _FakeSatelliteRepository(),
      channel: SatelliteChannel.irClean,
    );
    await tester.pumpWidget(
      wrap(
        SatelliteStyleMenu(
          layer: layer,
          onReloadActive: () async {},
          showTownLabels: ValueNotifier(true),
          onShowTownLabelsChanged: (_) {},
        ),
      ),
    );

    await tester.tap(find.byType(MapChipButton));
    await tester.pumpAndSettle();

    final l10n = await loadL10n();
    expect(find.text(l10n.mapLayerStyleSection), findsOneWidget);
    expect(find.text(l10n.mapLayerStyleGray), findsOneWidget);
    expect(find.text(l10n.mapLayerStyleJma), findsOneWidget);
    expect(find.text(l10n.mapLayerStyleBd), findsOneWidget);
    // Default is grayscale — JMA's standard is the no-wire-value default.
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });

  testWidgets(
    'picking a style updates the layer, the repository, and reloads',
    (tester) async {
      useTallSurface(tester);
      final repository = _FakeSatelliteRepository();
      final layer = SatelliteMapLayer(
        repository,
        channel: SatelliteChannel.irClean,
      );
      var reloads = 0;
      await tester.pumpWidget(
        wrap(
          SatelliteStyleMenu(
            layer: layer,
            onReloadActive: () async => reloads++,
            showTownLabels: ValueNotifier(true),
            onShowTownLabelsChanged: (_) {},
          ),
        ),
      );

      await tester.tap(find.byType(MapChipButton));
      await tester.pumpAndSettle();
      final l10n = await loadL10n();
      await tester.tap(find.text(l10n.mapLayerStyleJma));
      await tester.pumpAndSettle();

      expect(layer.style.value, SatelliteStyle.jma);
      expect(repository.style, 'jma');
      expect(reloads, 1);
      // The chip marks non-default style as active.
      expect(layer.style.value, isNot(SatelliteStyle.gray));
    },
  );

  testWidgets('a named product offers the reference menu, not the style menu', (
    tester,
  ) async {
    useTallSurface(tester);
    final layer = SatelliteMapLayer(
      _FakeSatelliteRepository(),
      channel: SatelliteChannel.truecolor,
    );
    await tester.pumpWidget(const MaterialApp(home: Scaffold()));
    final chrome = layer.buildTopTrailingChrome(
      tester.element(find.byType(Scaffold)),
      showTownLabels: ValueNotifier(true),
      onShowTownLabelsChanged: (_) {},
      onReloadActive: () async {},
    );
    expect(chrome, isA<SatelliteReferenceMenu>());
  });

  testWidgets(
    'a reflectance band offers the reference menu, not the style menu',
    (tester) async {
      useTallSurface(tester);
      final layer = SatelliteMapLayer(
        _FakeSatelliteRepository(),
        channel: SatelliteChannel.visibleBlue,
      );
      await tester.pumpWidget(const MaterialApp(home: Scaffold()));
      final chrome = layer.buildTopTrailingChrome(
        tester.element(find.byType(Scaffold)),
        showTownLabels: ValueNotifier(true),
        onShowTownLabelsChanged: (_) {},
        onReloadActive: () async {},
      );
      expect(chrome, isA<SatelliteReferenceMenu>());
    },
  );

  testWidgets('a thermal band offers the style menu', (tester) async {
    useTallSurface(tester);
    final layer = SatelliteMapLayer(
      _FakeSatelliteRepository(),
      channel: SatelliteChannel.irLong, // B14 — thermal
    );
    await tester.pumpWidget(const MaterialApp(home: Scaffold()));
    final chrome = layer.buildTopTrailingChrome(
      tester.element(find.byType(Scaffold)),
      showTownLabels: ValueNotifier(true),
      onShowTownLabelsChanged: (_) {},
      onReloadActive: () async {},
    );
    expect(chrome, isNot(isA<SizedBox>()));
    expect(chrome, isA<SatelliteStyleMenu>());
  });

  testWidgets('setStyle rejects temperature styles on a reflectance band', (
    tester,
  ) async {
    useTallSurface(tester);
    final layer = SatelliteMapLayer(
      _FakeSatelliteRepository(),
      channel: SatelliteChannel.visibleBlue, // B01 — grayscale only
    );
    var reloads = 0;
    layer.setStyle(SatelliteStyle.jma, onReloadActive: () async => reloads++);
    expect(layer.style.value, SatelliteStyle.gray);
    expect(reloads, 0);
  });
}
