// Scratch. l10n-ignore-file: developer tool
import 'dart:io';
import 'dart:math' as math;
import 'package:dpip/core/astro/satellite.dart';

void main() {
  final sgp4 = Sgp4(TleSet.parse(
    'TEST',
    '1 88888U          80275.98708465  .00073094  13844-3  66816-4 0    8',
    '2 88888  72.8435 115.9689 0086731  52.6988 110.5714 16.05824518  105',
  ));
  // Spacetrack Report #3, appendix: position only (the values I am sure of).
  const positions = <(double, List<double>)>[
    (0, [2328.97048951, -5995.22076416, 1719.97067261]),
    (360, [2456.10705566, -6071.93853760, 1222.89727783]),
    (720, [2601.61924952, -6117.53984880, 674.32309443]),
    (1080, [2748.66144001, -6132.51817928, 114.13276474]),
    (1440, [2895.36400837, -6116.10902739, -446.87231761]),
  ];
  for (final (minutes, want) in positions) {
    final s = sgp4.propagate(minutes);
    final p = s.position;
    final d = math.sqrt(math.pow(p.$1 - want[0], 2) +
        math.pow(p.$2 - want[1], 2) + math.pow(p.$3 - want[2], 2));
    // Velocity checked against the numerical derivative of the position — an
    // independent check that the two formulas describe the same motion.
    const h = 1 / 600; // 0.1 s in minutes
    final before = sgp4.propagate(minutes - h).position;
    final after = sgp4.propagate(minutes + h).position;
    final numeric = (
      (after.$1 - before.$1) / (2 * h * 60),
      (after.$2 - before.$2) / (2 * h * 60),
      (after.$3 - before.$3) / (2 * h * 60),
    );
    final v = s.velocity;
    final dv = math.sqrt(math.pow(v.$1 - numeric.$1, 2) +
        math.pow(v.$2 - numeric.$2, 2) + math.pow(v.$3 - numeric.$3, 2));
    final speed = math.sqrt(v.$1 * v.$1 + v.$2 * v.$2 + v.$3 * v.$3);
    stdout.writeln('t=${minutes.toStringAsFixed(0).padLeft(5)}  '
        'pos err ${d.toStringAsFixed(4)} km   '
        'v vs d(pos)/dt ${dv.toStringAsFixed(6)} km/s   '
        '|v| ${speed.toStringAsFixed(4)} km/s');
  }
}
