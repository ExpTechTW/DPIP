/// Reading an App API v2 report's `addition`: the source's raw JSON, passed
/// through untyped and sometimes mistyped. Every reader returns null (or an
/// empty list) instead of throwing, so one bad field drops one value, never
/// the report.
///
/// The headline facts and every type family's detail read through these, so
/// a station, a wave height or a time reads the same everywhere it appears.
library;

import 'package:dpip/core/realtime/app_time.dart';

/// [v] when it is a JSON object.
Map<Object?, Object?>? additionMap(Object? v) =>
    v is Map<Object?, Object?> ? v : null;

/// The JSON objects in [v] when it is a list, skipping anything else in it.
List<Map<Object?, Object?>> additionMaps(Object? v) => v is List<Object?>
    ? v.whereType<Map<Object?, Object?>>().toList()
    : const [];

/// [v] trimmed, when it is a string with something in it.
String? additionText(Object? v) {
  if (v is! String) return null;
  final text = v.trim();
  return text.isEmpty ? null : text;
}

/// Largest whole number a double holds exactly.
const _maxExactDouble = 9007199254740992;

/// A whole number, also when the JSON wrote it as `4.0`.
int? additionInt(Object? v) => switch (v) {
  final int i => i,
  final double d
      when d.isFinite &&
          d.abs() <= _maxExactDouble &&
          d == d.truncateToDouble() =>
    d.toInt(),
  _ => null,
};

/// A quantity that cannot be negative; the sources' `-99` (no reading) and
/// every other negative value read as missing.
double? additionAmount(Object? v) =>
    v is num && v.isFinite && v >= 0 ? v.toDouble() : null;

/// A river stage, which may be below the datum; `-99` and below read as
/// missing.
double? additionStage(Object? v) =>
    v is num && v.isFinite && v > -99 ? v.toDouble() : null;

/// Latest instant [DateTime] can hold, in ms.
const _maxEpochMs = 8640000000000000;

/// A positive Unix time in ms that [DateTime] can hold.
int? additionEpochMs(Object? v) {
  final ms = additionInt(v);
  return ms != null && ms > 0 && ms <= _maxEpochMs ? ms : null;
}

/// The source's visibility text with full-width `＜` `＞` as ASCII and a space
/// after a leading bound: `<1` → `< 1`.
String? additionVisibilityText(Object? v) {
  // l10n-ignore: source characters mapped to ASCII, not display text
  final text = additionText(v)?.replaceAll('＜', '<').replaceAll('＞', '>');
  if (text == null) return null;
  if (text.startsWith('<') || text.startsWith('>')) {
    final rest = text.substring(1).trimLeft();
    return rest.isEmpty ? null : '${text[0]} $rest';
  }
  return text;
}

/// [v] with at most [digits] decimals and no trailing zeros: `50.5`, `21`.
String eventDecimal(double v, int digits) {
  var s = v.toStringAsFixed(digits);
  if (s.contains('.')) {
    s = s.replaceFirst(RegExp(r'0+$'), '');
    if (s.endsWith('.')) s = s.substring(0, s.length - 1);
  }
  return s == '-0' ? '0' : s;
}

/// Taipei wall-clock `HH:mm` of the Unix time [ms].
String eventClock(int ms) {
  final t = AppTime.taipei(
    DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true),
  );
  return '${t.hour.toString().padLeft(2, '0')}:'
      '${t.minute.toString().padLeft(2, '0')}';
}
