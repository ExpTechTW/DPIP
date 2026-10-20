import 'package:dpip/core/platform/render_tier.dart';
import 'package:dpip/shared/map/wavefront_cadence.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a capable phone redraws the rings at about display rate', () {
    expect(wavefrontTick(RenderTier.high), const Duration(milliseconds: 16));
  });

  test('a low-end phone redraws them at 5 Hz', () {
    expect(wavefrontTick(RenderTier.low), const Duration(milliseconds: 200));
  });

  const latitude = 23.0;
  const zoom = 8.0;

  WavefrontRing ring(String id, double p, double s) =>
      WavefrontRing(id: id, pMetres: p, sMetres: s, latitude: latitude);

  test('a sub-pixel step is held and a later step uploads that radius', () {
    final pixel = metresPerPixel(latitude: latitude, zoom: zoom);
    final onMap = {'a': ring('a', 10000, 20000)};
    final held = [ring('a', 10000 + pixel * 0.5, 20000 + pixel * 0.5)];
    expect(
      wavefrontUploadDue(next: held, onMap: onMap, zoom: zoom),
      isFalse,
      reason: 'half a pixel is the same ring on screen',
    );

    final later = [ring('a', 10000 + pixel * 1.5, 20000 + pixel * 1.5)];
    expect(wavefrontUploadDue(next: later, onMap: onMap, zoom: zoom), isTrue);
    expect(later.single.sMetres, greaterThan(onMap['a']!.sMetres));
    expect(later.single.pMetres, greaterThan(onMap['a']!.pMetres));
  });

  test('a shrink of a pixel or more uploads the smaller current radius', () {
    final pixel = metresPerPixel(latitude: latitude, zoom: zoom);
    final onMap = {'a': ring('a', 20000, 40000)};
    final now = [ring('a', 20000 - pixel * 2, 40000 - pixel * 2)];
    expect(wavefrontUploadDue(next: now, onMap: onMap, zoom: zoom), isTrue);
    expect(now.single.pMetres, lessThan(onMap['a']!.pMetres));
    expect(now.single.sMetres, lessThan(onMap['a']!.sMetres));
  });

  test('a missing camera, a bad zoom, or a new alert always uploads', () {
    final ringA = ring('a', 1, 1);
    final same = {'a': ringA};
    expect(wavefrontUploadDue(next: [ringA], onMap: same, zoom: null), isTrue);
    expect(
      wavefrontUploadDue(next: [ringA], onMap: same, zoom: double.nan),
      isTrue,
    );
    expect(
      wavefrontUploadDue(next: [ringA], onMap: const {}, zoom: zoom),
      isTrue,
    );
    expect(
      wavefrontUploadDue(next: [ring('b', 1, 1)], onMap: same, zoom: zoom),
      isTrue,
    );
  });

  test('box coverage runs on the first look and then every 200 ms', () {
    final start = DateTime.utc(2026, 8, 12, 12);
    expect(boxCoverageDue(null, start), isTrue);
    expect(
      boxCoverageDue(start, start.add(const Duration(milliseconds: 199))),
      isFalse,
    );
    expect(boxCoverageDue(start, start.add(kBoxCoverageInterval)), isTrue);
  });
}
