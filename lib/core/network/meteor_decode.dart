/// Shared decoders for the meteor v5 API's compact encodings.
///
/// v5 trades JSON verbosity for three tricks the client must undo: **delta
/// seconds** (`/list`, `/trend` time axes), **field-arrays aligned to a station
/// directory** (weather/rain latest), and the **-99 missing sentinel**. These
/// helpers are the one place each is decoded, shared across weather / rain /
/// lightning / typhoon. See `meteor-server-ts/api.md` → 三個要會的解碼.
abstract final class MeteorDecode {
  const MeteorDecode._();

  /// Restores a delta-second list `[base, Δ, Δ, …]` to absolute Unix seconds,
  /// ascending (oldest first). Empty in → empty out.
  static List<int> deltaSeconds(List<dynamic> deltas) {
    if (deltas.isEmpty) return const [];
    var second = (deltas.first as num).toInt();
    final seconds = <int>[second];
    for (var i = 1; i < deltas.length; i++) {
      second += (deltas[i] as num).toInt();
      seconds.add(second);
    }
    return seconds;
  }

  /// Maps weather/rain's `-99` missing sentinel to null; passes other values
  /// through as a double. (`null` in → `null` out.)
  static double? real(Object? value) {
    if (value == null) return null;
    final n = (value as num).toDouble();
    return n == -99 ? null : n;
  }

  /// The integer form of [real] — for counts/degrees stored as whole numbers
  /// (e.g. humidity %, wind direction °) where `-99` means missing.
  static int? integer(Object? value) {
    if (value == null) return null;
    final n = (value as num).toInt();
    return n == -99 ? null : n;
  }
}
