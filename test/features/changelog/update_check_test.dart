/// The update check, pinned against DPIP's real tag history.
///
/// The history is the point. DPIP numbers a pre-release by inflating the patch
/// (`v3.1.4` → `v3.1.401`), so `v3.1.310` — which shipped *before* the stable
/// `v3.1.4` — compares *higher* than it. Any check that compares across
/// channels therefore tells a stable user on 3.1.4 to "update" to an older
/// beta. The channel filter is what makes the comparison sound, so these tests
/// use the actual tags rather than tidy invented ones.
library;

import 'package:dpip/core/platform/install_source.dart';
import 'package:dpip/features/changelog/domain/app_version.dart';
import 'package:dpip/features/changelog/domain/release_note.dart';
import 'package:dpip/features/changelog/domain/update_check.dart';
import 'package:dpip/features/changelog/domain/update_destination.dart';
import 'package:flutter_test/flutter_test.dart';

/// The published DPIP releases, newest first, exactly as GitHub lists them.
final _releases = <ReleaseNote>[
  _note('v3.9.9', pre: true),
  _note('v3.2.1', pre: false),
  _note('v3.2.0', pre: false),
  _note('v3.1.402', pre: true),
  _note('v3.1.401', pre: true),
  _note('v3.1.4', pre: false),
  _note('v3.1.310', pre: true),
  _note('v3.1.3', pre: false),
  _note('v3.1.2', pre: false),
  _note('v3.1.104', pre: true),
  _note('v3.1.103', pre: true),
  _note('v3.1.1', pre: false),
  _note('v3.1.001', pre: true),
  _note('v3.1.0', pre: false),
  _note('v3.0.2', pre: true),
];

var _day = 0;
ReleaseNote _note(String tag, {required bool pre}) => ReleaseNote(
  tagName: tag,
  name: tag,
  prerelease: pre,
  // Descending, matching the newest-first order above.
  publishedAt: DateTime.utc(2026, 1, 1).subtract(Duration(days: _day++)),
  htmlUrl: 'https://github.com/ExpTechTW/DPIP/releases/tag/$tag',
);

void main() {
  group('AppVersion', () {
    test('parses a tag, a plain version, and a build suffix alike', () {
      expect(AppVersion.tryParse('v3.9.9').toString(), '3.9.9');
      expect(AppVersion.tryParse('3.9.9').toString(), '3.9.9');
      expect(AppVersion.tryParse('3.9.9+1').toString(), '3.9.9');
      expect(AppVersion.tryParse('v3.1.401').toString(), '3.1.401');
    });

    test('has no number to rank in a non-version tag', () {
      expect(AppVersion.tryParse('nightly'), isNull);
      expect(AppVersion.tryParse(''), isNull);
    });

    test('treats a missing component as zero', () {
      expect(AppVersion.tryParse('3.2'), AppVersion.tryParse('3.2.0'));
    });

    test('orders the inflated patch after the stable it builds on', () {
      final stable = AppVersion.tryParse('v3.1.4')!;
      final beta = AppVersion.tryParse('v3.1.401')!;
      expect(beta > stable, isTrue);
      expect(AppVersion.tryParse('v3.1.402')! > beta, isTrue);
    });
  });

  group('channel', () {
    test('is read from the running version\'s own release', () {
      expect(
        channelFor(releases: _releases, currentVersion: '3.2.1'),
        UpdateChannel.stable,
      );
      // Identical in shape to a stable tag — only the release says otherwise.
      expect(
        channelFor(releases: _releases, currentVersion: '3.1.402'),
        UpdateChannel.preRelease,
      );
    });

    test('falls back to TestFlight for a version not in the list', () {
      expect(
        channelFor(
          releases: _releases,
          currentVersion: '4.0.0',
          installSource: InstallSource.testFlight,
        ),
        UpdateChannel.preRelease,
      );
      expect(
        channelFor(
          releases: _releases,
          currentVersion: '4.0.0',
          installSource: InstallSource.appStore,
        ),
        UpdateChannel.stable,
      );
    });
  });

  group('findUpdate', () {
    test('offers a stable user the newest stable', () {
      final update = findUpdate(releases: _releases, currentVersion: '3.2.0');
      expect(update?.tagName, 'v3.2.1');
    });

    test('never offers a stable user a pre-release', () {
      // v3.9.9 is the newest release overall, and a beta.
      final update = findUpdate(releases: _releases, currentVersion: '3.2.1');
      expect(update, isNull);
    });

    test('never offers a stable user an older beta that sorts higher', () {
      // The trap: 3.1.310 > 3.1.4 numerically, but it shipped earlier and is a
      // beta. A stable user on 3.1.4 is owed 3.2.1, not 3.1.310.
      final update = findUpdate(releases: _releases, currentVersion: '3.1.4');
      expect(update?.tagName, 'v3.2.1');
    });

    test('offers a beta user the newest beta, not the newest stable', () {
      final update = findUpdate(releases: _releases, currentVersion: '3.1.401');
      expect(update?.tagName, 'v3.9.9');
    });

    test(
      'says nothing when the newest of the channel is already installed',
      () {
        expect(
          findUpdate(releases: _releases, currentVersion: '3.9.9'),
          isNull,
        );
        expect(
          findUpdate(releases: _releases, currentVersion: '3.2.1'),
          isNull,
        );
      },
    );

    test('says nothing when running ahead of every release', () {
      expect(findUpdate(releases: _releases, currentVersion: '9.0.0'), isNull);
    });

    test('offers each version exactly once', () {
      const current = '3.2.0';
      final first = findUpdate(releases: _releases, currentVersion: current);
      expect(first?.tagName, 'v3.2.1');
      // Having been prompted for it, the next launch is silent…
      expect(
        findUpdate(
          releases: _releases,
          currentVersion: current,
          promptedVersion: first!.tagName,
        ),
        isNull,
      );
      // …but a newer one still speaks.
      expect(
        findUpdate(
          releases: [_note('v3.2.2', pre: false), ..._releases],
          currentVersion: current,
          promptedVersion: first.tagName,
        )?.tagName,
        'v3.2.2',
      );
    });

    test('stays quiet on a version it cannot parse', () {
      expect(findUpdate(releases: _releases, currentVersion: 'dev'), isNull);
      expect(findUpdate(releases: const [], currentVersion: '3.2.0'), isNull);
    });
  });

  group('destination', () {
    test('sends each install source somewhere it can actually update', () {
      expect(
        updateDestinationFor(InstallSource.appStore).scheme,
        contains('itms-apps://'),
      );
      // A tester sent to the App Store would only ever be offered the stable
      // build, so TestFlight gets its own scheme.
      expect(
        updateDestinationFor(InstallSource.testFlight).scheme,
        contains('itms-beta://'),
      );
      expect(
        updateDestinationFor(InstallSource.playStore).scheme,
        contains('market://'),
      );
    });

    test('every destination has an https fallback', () {
      for (final source in InstallSource.values) {
        expect(
          updateDestinationFor(source).web,
          startsWith('https://'),
          reason: '${source.name} has no browser fallback',
        );
      }
    });

    test('a sideload updates from the release page it came from', () {
      const url = 'https://github.com/ExpTechTW/DPIP/releases/tag/v3.9.9';
      final destination = updateDestinationFor(
        InstallSource.sideload,
        releaseUrl: url,
      );
      expect(destination.scheme, url);
      expect(destination.web, url);
      // With no release page, the listing still works.
      expect(
        updateDestinationFor(InstallSource.sideload).web,
        'https://github.com/ExpTechTW/DPIP/releases',
      );
    });
  });
}
