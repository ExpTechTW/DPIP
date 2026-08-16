/// Decides whether a newer build exists — and whether to say so.
///
/// Two rules, both from the release process rather than from semver:
///
/// * **Newer is decided by an ordinal, not by a name.** Every build carries a
///   monotonic integer that the stores also sort by, and a release advertises
///   its own in the note body. Comparing names cannot work under the current
///   scheme: a snapshot is named for the week it was cut (`26w40a`) and the
///   release it leads to is named for the year (`26.1`), so the name of the
///   newer build is often the smaller one. Builds made before the ordinal
///   existed fall back to the old name comparison.
/// * **A channel only hears about itself.** Someone running a stable build is
///   offered stable releases; someone running a pre-release (TestFlight, or a
///   sideloaded beta APK) is offered pre-releases. A stable user is never
///   pushed onto a beta, and a beta tester is never told to "update" to an
///   older stable. This also keeps the comparison sound: DPIP's inflated-patch
///   pre-release numbering only orders correctly within one channel
///   ([AppVersion]).
/// * **One prompt per version.** The version last prompted for is persisted, so
///   the dialog appears once and never again for that release — whichever
///   button ended it.
///
/// The whole decision is a pure function of the release list, the running
/// version, and what was already prompted, so it is tested against DPIP's real
/// tag history instead of by launching the app.
library;

import 'package:dpip/core/platform/install_source.dart';
import 'package:dpip/features/changelog/domain/app_version.dart';
import 'package:dpip/features/changelog/domain/release_note.dart';

/// Which release track a build belongs to.
enum UpdateChannel {
  stable,
  preRelease;

  bool get isPreRelease => this == UpdateChannel.preRelease;
}

/// Which channel the running build belongs to.
///
/// The tag is the authority: the running version is looked up in the release
/// list and the release's own `prerelease` flag answers the question — the
/// version *string* cannot, because a DPIP pre-release looks exactly like a
/// stable one (`v3.1.402`).
///
/// When the running version is not in the list (a local build, a release too
/// old to still be listed), the install source decides: TestFlight is a
/// pre-release channel by construction. Everything else falls back to stable,
/// which is the conservative answer — the cost of guessing wrong is a missed
/// prompt, not an unwanted beta.
UpdateChannel channelFor({
  required List<ReleaseNote> releases,
  required String currentVersion,
  InstallSource installSource = InstallSource.unknown,
}) {
  final current = AppVersion.tryParse(currentVersion);
  if (current != null) {
    for (final release in releases) {
      if (AppVersion.tryParse(release.tagName) == current) {
        return release.prerelease
            ? UpdateChannel.preRelease
            : UpdateChannel.stable;
      }
    }
  }
  return installSource == InstallSource.testFlight
      ? UpdateChannel.preRelease
      : UpdateChannel.stable;
}

/// The build ordinal a release advertises, or null when it does not.
///
/// Published as an HTML comment in the release body, which GitHub renders as
/// nothing — the note stays a note, and the machine-readable half rides along
/// without appearing in it.
///
/// The ordinal is what the update check wants, because it is the only value
/// that orders correctly: a label may be styled however it likes, and a
/// snapshot named after a later week (`26w40a`) can legitimately precede the
/// release it led to (`26.1`). Comparing the names would call that a
/// downgrade; comparing the ordinals cannot.
int? buildCodeOf(ReleaseNote release) {
  final match = _buildMarker.firstMatch(release.body);
  return match == null ? null : int.tryParse(match.group(1)!);
}

final RegExp _buildMarker = RegExp(r'<!--\s*dpip-build:\s*(\d+)\s*-->');

/// A release note with only the half that matches [locale] left in.
///
/// The published note carries both languages: 中文 first, then the English
/// wrapped in `<details>` so GitHub folds it. That fold is HTML, and the
/// in-app Markdown renderer does not implement HTML — so on a phone the
/// `<summary>` text would print as a line of prose and the entire English
/// section would sit expanded under the Chinese, doubling the length of every
/// note.
///
/// The two halves are delimited by comment markers precisely so this can pick
/// one. A note that has neither marker (anything published before the scheme)
/// is returned untouched — better a bilingual note than an empty one.
String localizedReleaseBody(String body, String locale) {
  const open = '<!-- dpip-en -->';
  const close = '<!-- /dpip-en -->';
  final start = body.indexOf(open);
  final end = body.indexOf(close);
  if (start < 0 || end < start) return body;

  if (locale.toLowerCase().startsWith('zh')) {
    return (body.substring(0, start) + body.substring(end + close.length))
        .trim();
  }
  // The English half, with the fold's own tags stripped — they would otherwise
  // render as literal text.
  return body
      .substring(start + open.length, end)
      .replaceAll(RegExp(r'</?details>|<summary>.*?</summary>'), '')
      .trim();
}

/// The release to offer, or null when there is nothing to say.
///
/// Null covers every "stay quiet" case: already current, nothing newer in this
/// channel, the version was already prompted for, or the running version could
/// not be parsed (never nag a build we cannot reason about).
ReleaseNote? findUpdate({
  required List<ReleaseNote> releases,
  required String currentVersion,
  String? promptedVersion,
  int currentBuild = 0,
  int promptedBuild = 0,
  InstallSource installSource = InstallSource.unknown,
}) {
  final channel = channelFor(
    releases: releases,
    currentVersion: currentVersion,
    installSource: installSource,
  );

  // The ordinal path, for builds that carry one. It is preferred wherever both
  // sides have it because it is the only comparison that is always right:
  // there is no string to parse, and no way for a label to outrank the build
  // it preceded.
  if (currentBuild > 0) {
    ReleaseNote? best;
    var bestCode = currentBuild;
    for (final release in releases) {
      if (release.prerelease != channel.isPreRelease) continue;
      final code = buildCodeOf(release);
      // A release with no ordinal predates the scheme. It is skipped rather
      // than guessed at — an unnumbered release is not evidence of anything,
      // and offering one on a guess pushes a working build backwards.
      if (code == null || code <= bestCode) continue;
      best = release;
      bestCode = code;
    }
    if (best == null) return null;
    // Already offered — once per build, not once per launch.
    if (promptedBuild >= bestCode) return null;
    return best;
  }

  // The name path, kept for builds made before the ordinal existed. It orders
  // by DPIP's old inflated-patch numbering, which is only sound inside one
  // channel — hence the filter above.
  final current = AppVersion.tryParse(currentVersion);
  if (current == null) return null;

  ReleaseNote? best;
  AppVersion? bestVersion;
  for (final release in releases) {
    if (release.prerelease != channel.isPreRelease) continue;
    final version = AppVersion.tryParse(release.tagName);
    if (version == null) continue;
    if (bestVersion == null || version > bestVersion) {
      best = release;
      bestVersion = version;
    }
  }
  if (best == null || bestVersion == null) return null;
  if (!(bestVersion > current)) return null;

  final prompted = promptedVersion == null
      ? null
      : AppVersion.tryParse(promptedVersion);
  if (prompted != null && !(bestVersion > prompted)) return null;

  return best;
}
