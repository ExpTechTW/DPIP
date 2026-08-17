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
/// Three sources, in order of how much they know:
///
/// 1. **CI's `--dart-define`** — the authority for a published build.
/// 2. **`lib/core/build_info.g.dart`** — written by the git hooks from the same
///    `tool/version.sh`, so a local `flutter run` names itself correctly too. A
///    debug build otherwise fell back to the pubspec placeholder and reported
///    `26.1.0 (1)`, a version that exists nowhere.
/// 3. **The platform's own version** — a build made outside a repository, where
///    neither of the above could be filled in.
///
/// Which is why [ensureLoaded] exists rather than a pair of constants: the
/// third source is asynchronous.
library;

import 'package:dpip/core/build_info.g.dart';
import 'package:package_info_plus/package_info_plus.dart';

abstract final class AppBuild {
  AppBuild._();

  /// What CI stamped in, empty on a local build.
  static const String _definedLabel = String.fromEnvironment('DPIP_LABEL');
  static const int _definedCode = int.fromEnvironment('DPIP_CODE');
  static const String _definedTrain = String.fromEnvironment('DPIP_TRAIN');

  /// What the git hooks wrote, empty outside a repository.
  static String get _generatedLabel => kBuildLabel;
  static int get _generatedCode => kBuildCode;

  /// The train number this build rides — the release a snapshot is heading
  /// toward, e.g. `26.1`. Apple is told this and never the label. The More
  /// page version card shows it as the big number, above the label.
  static String get train => _train;

  static String get _bestLabel =>
      _definedLabel.isNotEmpty ? _definedLabel : _generatedLabel;
  static int get _bestCode => _definedCode > 0 ? _definedCode : _generatedCode;

  static String? _label;
  static int? _code;
  static String _train = _definedTrain.isNotEmpty ? _definedTrain : kBuildTrain;

  /// Reads the platform's own version, for the builds CI did not stamp.
  ///
  /// Called once at bootstrap. Safe to call again; safe to skip, in which case
  /// [label] falls back to whatever was defined and [code] to 0.
  static Future<void> ensureLoaded() async {
    if (_label != null) return;
    if (_bestLabel.isNotEmpty && _bestCode > 0) {
      _label = _bestLabel;
      _code = _bestCode;
      return;
    }
    try {
      final info = await PackageInfo.fromPlatform();
      _label = _bestLabel.isNotEmpty ? _bestLabel : info.version;
      _code = _bestCode > 0 ? _bestCode : int.tryParse(info.buildNumber) ?? 0;
    } on Object {
      // A version readout is never worth failing a launch over.
      _label = _bestLabel.isNotEmpty ? _bestLabel : 'dev';
      _code = _bestCode;
    }
  }

  /// The name this build goes by — the only version a user is shown.
  static String get label =>
      _label ?? (_bestLabel.isEmpty ? 'dev' : _bestLabel);

  /// The ordinal. Higher is newer, always; nothing else about it means
  /// anything. 0 means "unknown", which no comparison may treat as oldest —
  /// see [isNewerThan].
  static int get code => _code ?? _bestCode;

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
  static void debugSet({
    required String label,
    required int code,
    String? train,
  }) {
    _label = label;
    _code = code;
    if (train != null) _train = train;
  }
}
