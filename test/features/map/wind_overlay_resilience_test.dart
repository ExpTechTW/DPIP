/// That the wind field keeps animating — through a bad frame, and through the
/// camera settles that used to rebuild it from scratch.
///
/// The freeze this pins is a property of [Ticker]: it reschedules itself
/// *after* the callback returns, so one throw inside the tick stops the
/// animation for the rest of the session. Worse, `isActive` still reports
/// `true` afterwards, so the overlay's own "start it if it isn't running"
/// check sees a healthy ticker and never restarts it. The field freezes and no
/// amount of panning, zooming or re-selecting the layer brings it back — which
/// is exactly what a user sees after holding the map a while.
library;

import 'dart:typed_data';

import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/features/map/presentation/layers/wind_forecast_layer.dart';
import 'package:dpip/features/map/presentation/widgets/wind_particle_overlay.dart';
import 'package:dpip/features/weather/domain/wind_field.dart';
import 'package:dpip/features/weather/domain/wind_forecast_model.dart';
import 'package:dpip/features/weather/domain/wind_forecast_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import 'raster_timeline_harness.dart';

class _Repo extends FakeRasterFrameSource implements WindForecastRepository {
  _Repo(super.frames);

  @override
  String tileUrl(String frame) => 'https://host/$frame/{z}/{x}/{y}.webp';

  @override
  Future<Result<WindField>> fetchWindField(String frame) async => Ok(
    WindField(
      width: 8,
      height: 5,
      lat0: 90,
      lon0: 0,
      dLat: -45,
      dLon: 45,
      uMin: -30,
      uMax: 30,
      vMin: -30,
      vMax: 30,
      timeMs: 0,
      model: 'gfs',
      u: Uint8List(40)..fillRange(0, 40, 220),
      v: Uint8List(40)..fillRange(0, 40, 40),
    ),
  );
}

/// A controller whose camera can be made to throw or to go missing, standing
/// in for the bad frame — in the app it is `context.size` during a
/// layout-dirty rebuild, or a controller detached from the layer.
class _FlakyController extends RecordingMapController {
  bool throwOnCamera = false;
  bool cameraMissing = false;

  /// How many times the tick asked for the camera — the proof it is still
  /// running.
  int reads = 0;

  @override
  CameraPosition? get cameraPosition {
    reads++;
    if (throwOnCamera) throw StateError('camera unavailable this frame');
    if (cameraMissing) return null;
    return const CameraPosition(target: LatLng(23.5, 121), zoom: 5);
  }
}

Future<(WindForecastMapLayer, _FlakyController)> _mount(
  WidgetTester tester,
) async {
  final layer = WindForecastMapLayer(
    _Repo(['1700000000']),
    model: WindForecastModel.gfs,
  );
  final controller = _FlakyController();
  final frames = (await layer.frames()).valueOrNull!;
  await layer.prepare(controller, frames);
  await layer.show(controller, frames.first);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 400,
          height: 800,
          child: WindParticleOverlay(layer: layer),
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 16));
  return (layer, controller);
}

void main() {
  testWidgets('a throwing frame does not stop the animation', (tester) async {
    final (_, controller) = await _mount(tester);
    await tester.pump(const Duration(milliseconds: 16));
    expect(controller.reads, greaterThan(0), reason: 'not ticking at all');

    // One bad frame.
    controller.throwOnCamera = true;
    await tester.pump(const Duration(milliseconds: 16));
    controller.throwOnCamera = false;

    // …and the next frames still arrive. Without the guard the ticker never
    // reschedules and this count stops moving for good.
    final after = controller.reads;
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(
      controller.reads,
      greaterThan(after),
      reason: 'the ticker died on the bad frame and never came back',
    );
    expect(tester.takeException(), isNull, reason: 'it must not surface');
  });

  testWidgets('a run of bad frames still recovers', (tester) async {
    final (_, controller) = await _mount(tester);
    controller.throwOnCamera = true;
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    controller.throwOnCamera = false;
    final after = controller.reads;
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(controller.reads, greaterThan(after));
  });

  testWidgets('a stall is diagnosed by name, and the field then resumes', (
    tester,
  ) async {
    Log.talker.history.clear();
    final (_, controller) = await _mount(tester);

    // Wedge it: frames stop being produced while the overlay still believes it
    // is animating — which is what every remaining unknown looks like from the
    // outside.
    controller.cameraMissing = true;
    for (var i = 0; i < 200; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }

    // The watchdog names the guard that is holding. Without this line a report
    // is "the particles froze", which is not something anyone can fix.
    final stalls = Log.talker.history
        .map((e) => e.message ?? '')
        .where((m) => m.contains('wind particles stalled'))
        .toList();
    expect(stalls, isNotEmpty, reason: 'a wedged field said nothing');
    expect(stalls.first, contains('no camera'));
    // Reported once per stall, not once a second for as long as it lasts.
    expect(stalls, hasLength(1));

    controller.cameraMissing = false;
    final after = controller.reads;
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(
      controller.reads,
      greaterThan(after),
      reason: 'the field stayed frozen after the stall cleared',
    );
  });

  testWidgets('a healthy field is never restarted', (tester) async {
    // The watchdog must not churn a working animation: it drops the trail
    // buffer, so a spurious restart would show as a visible flicker every
    // second.
    final (_, controller) = await _mount(tester);
    // At frame cadence: one `pump` is one frame however far it advances the
    // clock, so pumping in 300 ms steps would model a 3 fps device and the
    // watchdog would rightly call that a stall.
    for (var i = 0; i < 200; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    // Three seconds of healthy animation, and it was never restarted — a
    // restart clears the trail buffer, so this is what keeps the streaks from
    // blinking once a second.
    expect(controller.reads, greaterThan(150));
    expect(find.byType(WindParticleOverlay), findsOneWidget);
  });

  test('the particle overlay is not rebuilt on every camera settle', () {
    // The scaffold keys the overlay subtree by the camera epoch so a
    // screen-space callout reprojects. This overlay reads the live camera on
    // every tick instead, and re-keying it would tear down the ticker, the
    // simulation and the trail buffer on every pan, zoom and tap.
    final wind = WindForecastMapLayer(
      _Repo(const ['1']),
      model: WindForecastModel.gfs,
    );
    expect(wind.overlayFollowsCamera, isFalse);
  });
}
