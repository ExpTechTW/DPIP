/// The iOS notification entitlements, in both signing configurations.
///
/// Debug signs with `Runner.entitlements` and Release/Profile with
/// `RunnerRelease.entitlements`. They are split on purpose (`aps-environment`
/// differs), which is exactly what lets a key reach one and not the other: a
/// TestFlight build missing the time-sensitive key still installs, still
/// receives every push, and has every High/Max alert quietly held by Focus.
/// Nothing on a device says so.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _files = [
  'ios/Runner/Runner.entitlements',
  'ios/Runner/RunnerRelease.entitlements',
];

/// Whether [plist] sets [key] to `<true/>`, comments aside.
bool _enabled(String plist, String key) {
  final withoutComments = plist.replaceAll(
    RegExp(r'<!--.*?-->', dotAll: true),
    '',
  );
  return RegExp('<key>${RegExp.escape(key)}</key>\\s*<true\\s*/>')
      .hasMatch(withoutComments);
}

void main() {
  for (final path in _files) {
    group(path, () {
      final plist = File(path).readAsStringSync();

      test('allows critical alerts', () {
        expect(
          _enabled(
            plist,
            'com.apple.developer.usernotifications.critical-alerts',
          ),
          isTrue,
        );
      });

      test('allows time-sensitive notifications', () {
        expect(
          _enabled(
            plist,
            'com.apple.developer.usernotifications.time-sensitive',
          ),
          isTrue,
        );
      });
    });
  }

  test('a commented-out key does not count', () {
    const plist =
        '<!-- <key>com.apple.developer.usernotifications.time-sensitive</key>'
        '<true/> -->';
    expect(
      _enabled(plist, 'com.apple.developer.usernotifications.time-sensitive'),
      isFalse,
    );
  });
}
