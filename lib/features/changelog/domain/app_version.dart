/// The app's version number, and the ordering that decides "is this newer".
///
/// DPIP does **not** use semver pre-release suffixes. A pre-release is a plain
/// `vX.Y.Z` whose patch number is inflated instead — `v3.1.4` (stable) was
/// followed by `v3.1.401` and `v3.1.402` (pre), and `v3.1.3` by `v3.1.310`.
/// Two consequences shape everything here:
///
/// * Ordering is a plain numeric component compare — there is no suffix to
///   rank, and the inflated patch sorts a pre-release *after* the stable it
///   builds on, which is the real chronology.
/// * That ordering only holds **within one channel**. Across channels it is
///   wrong: `v3.1.4` shipped after `v3.1.310` yet compares lower. So an update
///   check must never compare a stable version against a pre-release one —
///   see `update_check.dart`, where the channel filter comes first.
library;

/// A parsed `X.Y.Z` version, comparable within its channel.
class AppVersion implements Comparable<AppVersion> {
  const AppVersion(this.parts);

  /// The numeric components, most significant first. Never empty.
  final List<int> parts;

  /// Parses a version or tag — `v3.9.9`, `3.9.9`, `3.9.9+1` all give `3.9.9`.
  ///
  /// A leading `v` and a `+build` suffix are stripped (the build number is the
  /// store's counter, not the version), and anything that is not a run of
  /// digits ends the parse. Returns null when there is no number at all, so a
  /// tag like `nightly` is skipped rather than treated as version zero.
  static AppVersion? tryParse(String raw) {
    final trimmed = raw.trim();
    final parts = <int>[];
    var digits = '';
    for (final code in trimmed.codeUnits) {
      if (code >= 0x30 && code <= 0x39) {
        digits += String.fromCharCode(code);
        continue;
      }
      if (digits.isNotEmpty) {
        parts.add(int.parse(digits));
        digits = '';
      }
      // `+` starts the build metadata and `-` a suffix we do not rank; both
      // end the version proper.
      if (code == 0x2B || code == 0x2D) break;
      // A dot continues the version; anything else (a letter mid-string) ends
      // it, so `v3.9.9-rc1` and `3.9.9 (beta)` both parse as 3.9.9.
      if (code != 0x2E && parts.isNotEmpty) break;
    }
    if (digits.isNotEmpty) parts.add(int.parse(digits));
    return parts.isEmpty ? null : AppVersion(parts);
  }

  /// Component-wise numeric compare; a missing component counts as 0, so
  /// `3.2` and `3.2.0` are equal.
  @override
  int compareTo(AppVersion other) {
    final length = parts.length > other.parts.length
        ? parts.length
        : other.parts.length;
    for (var i = 0; i < length; i++) {
      final mine = i < parts.length ? parts[i] : 0;
      final theirs = i < other.parts.length ? other.parts[i] : 0;
      if (mine != theirs) return mine.compareTo(theirs);
    }
    return 0;
  }

  bool operator >(AppVersion other) => compareTo(other) > 0;
  bool operator <(AppVersion other) => compareTo(other) < 0;

  @override
  bool operator ==(Object other) =>
      other is AppVersion && compareTo(other) == 0;

  @override
  int get hashCode => Object.hashAll(parts);

  @override
  String toString() => parts.join('.');
}
