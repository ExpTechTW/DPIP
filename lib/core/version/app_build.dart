/// This build's identity: the name people read, and the number that orders.
///
/// They are deliberately unrelated, because they answer different questions
/// and obey different rules.
///
/// * [label] is the **name** — `26.1` for a release, `26w33a` for a snapshot.
///   Free text. It exists to be recognised and quoted in a bug report, and it
///   is the only version a user is ever shown.
/// * [code] is the **ordinal** — a monotonic integer, meaningless to read.
///   Both stores order by it and by nothing else, and so does the in-app
///   update check.
///
/// Keeping them apart is what lets the label be styled however it likes. Apple
/// refuses a marketing version that is not "a period-separated list of at most
/// three non-negative integers" (`ERROR ITMS-90060`, enforced at upload, so
/// TestFlight is no way around it) — a rule that `26w33a` cannot satisfy and
/// never has to, because Apple is told the *train* number instead and never
/// sees the label at all.
///
/// Both are stamped in at build time by `tool/version.sh` through CI. A local
/// `flutter run` gets neither, and falls back to the platform's own values —
/// which is why [ensureLoaded] exists rather than a pair of constants.
library;

import 'package:package_info_plus/package_info_plus.dart';

abstract final class AppBuild {
  AppBuild._();

  /// What CI stamped in, empty on a local build.
  static const String _definedLabel = String.fromEnvironment('DPIP_LABEL');
  static const int _definedCode = int.fromEnvironment('DPIP_CODE');

  static String? _label;
  static int? _code;

  /// Reads the platform's own version, for the builds CI did not stamp.
  ///
  /// Called once at bootstrap. Safe to call again; safe to skip, in which case
  /// [label] falls back to whatever was defined and [code] to 0.
  static Future<void> ensureLoaded() async {
    if (_label != null) return;
    if (_definedLabel.isNotEmpty && _definedCode > 0) {
      _label = _definedLabel;
      _code = _definedCode;
      return;
    }
    try {
      final info = await PackageInfo.fromPlatform();
      _label = _definedLabel.isNotEmpty ? _definedLabel : info.version;
      _code = _definedCode > 0
          ? _definedCode
          : int.tryParse(info.buildNumber) ?? 0;
    } on Object {
      // A version readout is never worth failing a launch over.
      _label = _definedLabel.isNotEmpty ? _definedLabel : 'dev';
      _code = _definedCode;
    }
  }

  /// The name this build goes by — the only version a user is shown.
  static String get label =>
      _label ?? (_definedLabel.isEmpty ? 'dev' : _definedLabel);

  /// The ordinal. Higher is newer, always; nothing else about it means
  /// anything. 0 means "unknown", which no comparison may treat as oldest —
  /// see [isNewerThan].
  static int get code => _code ?? _definedCode;

  /// Whether [candidate] is a build worth updating to.
  ///
  /// A plain integer compare, which is the whole point of having an ordinal:
  /// there is no string to parse, no channel to reason about, and no way for a
  /// snapshot named after a later week to outrank the release it preceded.
  ///
  /// An unknown code on either side answers **false**. Not knowing is not
  /// evidence of being behind, and prompting an update on no evidence is how a
  /// user gets pushed off a build that works.
  static bool isNewerThan(int candidate, {int? current}) {
    final mine = current ?? code;
    if (mine <= 0 || candidate <= 0) return false;
    return candidate > mine;
  }

  /// Test seam — sets both halves directly.
  static void debugSet({required String label, required int code}) {
    _label = label;
    _code = code;
  }
}
