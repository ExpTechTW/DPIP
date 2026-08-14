// Scratch. l10n-ignore-file: developer tool
import 'dart:io';
import 'package:dpip/core/astro/eclipse.dart';

String stamp(DateTime? t) => t == null ? '--' : t.toIso8601String().substring(0, 16);

void main() {
  stdout.writeln('Lunar eclipses 2025-2028');
  var at = DateTime.utc(2025);
  for (var i = 0; i < 8; i++) {
    final e = Eclipses.nextLunar(at);
    if (e == null) break;
    stdout.writeln('  ${stamp(e.peak)}  ${e.kind.name.padRight(10)} '
        'mag ${e.magnitude.toStringAsFixed(3)}  '
        'pen ${e.penumbralMagnitude?.toStringAsFixed(3)}  '
        '${stamp(e.begins)} - ${stamp(e.ends)}');
    at = e.peak.add(const Duration(days: 20));
  }
  stdout.writeln('\nSolar eclipses from Taipei 2025-2030');
  at = DateTime.utc(2025);
  for (var i = 0; i < 6; i++) {
    final e = Eclipses.nextSolar(at,
        latitude: 25.033, longitude: 121.5654, withinDays: 4000);
    if (e == null) break;
    stdout.writeln('  ${stamp(e.peak)}  ${e.kind.name.padRight(8)} '
        'mag ${e.magnitude.toStringAsFixed(3)}  '
        '${stamp(e.begins)} - ${stamp(e.ends)}');
    at = e.peak.add(const Duration(days: 20));
  }
  stdout.writeln('\nSolar eclipse 2026-08-12 from Reykjavik (NASA: total)');
  final ice = Eclipses.solarAt(DateTime.utc(2026, 8, 12, 17),
      latitude: 64.1466, longitude: -21.9426);
  stdout.writeln('  ${stamp(ice.peak)} ${ice.kind.name} '
      'mag ${ice.magnitude.toStringAsFixed(3)}');
  stdout.writeln('Solar eclipse 2027-08-02 from Luxor (NASA: total, ~6m23s)');
  final egypt = Eclipses.solarAt(DateTime.utc(2027, 8, 2, 10),
      latitude: 25.6872, longitude: 32.6396);
  stdout.writeln('  ${stamp(egypt.peak)} ${egypt.kind.name} '
      'mag ${egypt.magnitude.toStringAsFixed(3)}');
}
