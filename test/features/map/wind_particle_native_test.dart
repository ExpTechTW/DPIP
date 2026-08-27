import 'package:dpip/features/map/presentation/layers/wind_particle_native.dart';
import 'package:dpip/features/map/presentation/layers/wind_particle_sim.dart';
import 'package:dpip/features/weather/domain/wind_field.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// A WND1 body with a real header and two tiny planes, so the payload under
/// test is the one a decode actually produces rather than a hand-built stand-in.
Uint8List _wnd1({int width = 4, int height = 3, String model = 'ecmwf'}) {
  final name = model.codeUnits;
  final n = width * height;
  final bytes = Uint8List(67 + name.length + n * 2);
  final data = ByteData.sublistView(bytes);
  bytes.setRange(0, 4, 'WND1'.codeUnits);
  data.setUint16(4, 1, Endian.little);
  data.setUint16(6, width, Endian.little);
  data.setUint16(8, height, Endian.little);
  data.setFloat64(10, 90, Endian.little); // lat0
  data.setFloat64(18, 180, Endian.little); // lon0 — ECMWF starts at 180
  data.setFloat64(26, -0.5, Endian.little); // dLat
  data.setFloat64(34, 0.25, Endian.little); // dLon
  data.setFloat32(42, -30, Endian.little); // uMin
  data.setFloat32(46, 30, Endian.little); // uMax
  data.setFloat32(50, -20, Endian.little); // vMin
  data.setFloat32(54, 20, Endian.little); // vMax
  data.setUint64(58, 1787518800, Endian.little);
  data.setUint8(66, name.length);
  bytes.setRange(67, 67 + name.length, name);
  for (var i = 0; i < n * 2; i++) {
    bytes[67 + name.length + i] = i & 0xFF;
  }
  return bytes;
}

void main() {
  group('the tuning wire', () {
    test('carries every curve the simulation defines', () {
      final tuning = windParticleTuning();
      expect(tuning['zoomLo'], kWindZoomLo);
      expect(tuning['zoomHi'], kWindZoomHi);
      expect(tuning['particlesLo'], kWindParticles.$1);
      expect(tuning['particlesHi'], kWindParticles.$2);
      for (var i = 0; i < kWindLineWidths.length; i++) {
        expect(tuning['lineWidthZ${i + 3}'], kWindLineWidths[i]);
      }
      expect(tuning['particleWidth'], kWindParticleWidth);
      expect(tuning['speedFactorLo'], kWindSpeedFactor.$1);
      expect(tuning['speedFactorHi'], kWindSpeedFactor.$2);
      expect(tuning['fadeOpacityLo'], kWindFadeOpacity.$1);
      expect(tuning['fadeOpacityHi'], kWindFadeOpacity.$2);
      expect(tuning['dropRate'], kWindDropRate);
      expect(tuning['densityCalm'], kWindDensityCalm);
      expect(tuning['densityStrong'], kWindDensityStrong);
      expect(tuning['speedScale'], kWindSpeedScale);
    });

    test('sends endpoints, never a per-zoom evaluation', () {
      final tuning = windParticleTuning();
      // Every curve must arrive as its two ends. A single value would mean
      // Dart evaluated it — which puts a platform call on the camera path and
      // leaves two copies of the curve to drift apart.
      for (final base in const ['particles', 'speedFactor', 'fadeOpacity']) {
        expect(tuning, contains('${base}Lo'), reason: base);
        expect(tuning, contains('${base}Hi'), reason: base);
        expect(
          tuning.containsKey(base),
          isFalse,
          reason: '$base must not be pre-evaluated',
        );
      }
    });

    test('every value is finite — a NaN would silently stop the field', () {
      for (final entry in windParticleTuning().entries) {
        expect(entry.value.isFinite, isTrue, reason: entry.key);
      }
    });

    test('the point size scales with the device pixel ratio', () {
      expect(windParticleTuning(pixelRatio: 3)['pixelRatio'], 3);
      expect(windParticleTuning()['pixelRatio'], 1);
    });
  });

  group('the field wire', () {
    test('hands over the undecoded body and the header beside it', () {
      final bytes = _wnd1();
      final field = WindField.fromWnd1(bytes);
      final payload = windFieldPayload(field)!;

      expect(
        identical(payload['bytes'], bytes),
        isTrue,
        reason:
            'the WND1 body goes over untouched — re-serialising 2 MB to send '
            'back the same bytes is pure loss, and a second parser is a second '
            'place for the format to drift',
      );
      expect(payload['planeOffset'], 67 + 'ecmwf'.length);
      expect(payload['width'], 4);
      expect(payload['height'], 3);
      expect(payload['lat0'], 90.0);
      expect(payload['lon0'], 180.0);
      expect(payload['dLat'], -0.5);
      expect(payload['uMin'], -30.0);
      expect(payload['uMax'], 30.0);
      expect(payload['vMin'], -20.0);
      expect(payload['vMax'], 20.0);
    });

    test('the plane offset points at the u plane the decoder used', () {
      final bytes = _wnd1();
      final field = WindField.fromWnd1(bytes);
      final payload = windFieldPayload(field)!;
      final offset = payload['planeOffset']! as int;
      final n = field.width * field.height;
      expect(
        bytes.sublist(offset, offset + n),
        field.u,
        reason: 'native reads u from this offset; it must be the same plane',
      );
      expect(bytes.sublist(offset + n, offset + n * 2), field.v);
    });

    test('a field built in code has no payload and is skipped', () {
      final field = WindField(
        width: 2,
        height: 2,
        lat0: 90,
        lon0: 0,
        dLat: -1,
        dLon: 1,
        uMin: -1,
        uMax: 1,
        vMin: -1,
        vMax: 1,
        timeMs: 0,
        model: 'test',
        u: Uint8List(4),
        v: Uint8List(4),
      );
      expect(
        windFieldPayload(field),
        isNull,
        reason: 'there is no WND1 body to upload — do not invent one',
      );
    });
  });

  group('platform support', () {
    WindParticleNative build(TargetPlatform platform) => WindParticleNative(
      field: ValueNotifier<WindField?>(null),
      interacting: ValueNotifier<bool>(false),
      platform: platform,
    );

    test('Android and iOS are the platforms this exists for', () {
      expect(build(TargetPlatform.android).isSupported, isTrue);
      expect(build(TargetPlatform.iOS).isSupported, isTrue);
    });

    test('nowhere else, and nothing is active before it attaches', () {
      for (final platform in const [
        TargetPlatform.macOS,
        TargetPlatform.windows,
        TargetPlatform.linux,
        TargetPlatform.fuchsia,
      ]) {
        final native = build(platform);
        expect(native.isSupported, isFalse, reason: '$platform');
        expect(native.isActive, isFalse, reason: '$platform');
      }
      expect(
        build(TargetPlatform.android).isActive,
        isFalse,
        reason:
            'the caller keeps its own overlay until the device has actually '
            'accepted the layer',
      );
    });

    test('detaching without ever attaching is a no-op, not a crash', () async {
      await expectLater(build(TargetPlatform.iOS).detach(), completes);
      await expectLater(build(TargetPlatform.android).detach(), completes);
    });
  });

  group('render-loop gating', () {
    final field = WindField.fromWnd1(_wnd1());

    test('runs only for a visible decoded field with a stable camera', () {
      expect(
        windParticleShouldPlay(visible: true, interacting: false, field: field),
        isTrue,
      );
      expect(
        windParticleShouldPlay(visible: true, interacting: true, field: field),
        isFalse,
        reason: 'camera gestures pause GPU state and prevent projection jumps',
      );
      expect(
        windParticleShouldPlay(
          visible: false,
          interacting: false,
          field: field,
        ),
        isFalse,
      );
      expect(
        windParticleShouldPlay(visible: true, interacting: false, field: null),
        isFalse,
      );
    });
  });
}
