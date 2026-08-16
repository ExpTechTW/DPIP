import 'package:dpip/core/platform/device_info.dart';
import 'package:dpip/core/platform/render_tier.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  DeviceDetails device({int? totalMemoryMb, int? sdkInt = 33}) => DeviceDetails(
    manufacturer: 'Test',
    model: 'TestModel',
    osVersion: '14',
    sdkInt: sdkInt,
    totalMemoryMb: totalMemoryMb,
  );

  group('renderTierFor', () {
    test('a low-RAM Android phone is downgraded', () {
      expect(
        renderTierFor(device(totalMemoryMb: 3072), isAndroid: true),
        RenderTier.low,
        reason: '2–4 GB Android devices are the low-end GPU class',
      );
      expect(
        renderTierFor(device(totalMemoryMb: 4095), isAndroid: true),
        RenderTier.low,
      );
    });

    test('a mid/high-RAM Android phone keeps full quality', () {
      expect(
        renderTierFor(device(totalMemoryMb: 4096), isAndroid: true),
        RenderTier.high,
      );
      expect(
        renderTierFor(device(totalMemoryMb: 12288), isAndroid: true),
        RenderTier.high,
      );
    });

    test('an unknown RAM reading stays high — never degrade on a miss', () {
      expect(
        renderTierFor(device(totalMemoryMb: null), isAndroid: true),
        RenderTier.high,
      );
    });

    test('iOS is never downgraded, even on a low-RAM device', () {
      expect(
        renderTierFor(device(totalMemoryMb: 2048), isAndroid: false),
        RenderTier.high,
        reason: 'the oldest supported iPhones still outdraw low-end Androids',
      );
    });
  });
}
