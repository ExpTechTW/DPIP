/// Decides whether a newer build exists — and whether to say so.
///
/// Two rules, both from the release process rather than from semver:
///
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

/// The release to offer, or null when there is nothing to say.
///
/// Null covers every "stay quiet" case: already current, nothing newer in this
/// channel, the version was already prompted for, or the running version could
/// not be parsed (never nag a build we cannot reason about).
ReleaseNote? findUpdate({
  required List<ReleaseNote> releases,
  required String currentVersion,
  String? promptedVersion,
  InstallSource installSource = InstallSource.unknown,
}) {
  final current = AppVersion.tryParse(currentVersion);
  if (current == null) return null;

  final channel = channelFor(
    releases: releases,
    currentVersion: currentVersion,
    installSource: installSource,
  );

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

  // Already offered — the prompt is once per version, not once per launch.
  final prompted = promptedVersion == null
      ? null
      : AppVersion.tryParse(promptedVersion);
  if (prompted != null && !(bestVersion > prompted)) return null;

  return best;
}
