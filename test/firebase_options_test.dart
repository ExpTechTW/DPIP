/// `DefaultFirebaseOptions.currentPlatform` is what stands in for the native
/// `GoogleService-Info.plist` / `google-services.json` auto-configuration
/// this app deliberately does not rely on (see the library doc on
/// `firebase_options.dart`) — so picking the wrong branch here does not fail
/// loudly with a bad value, it fails at app start with Firebase's own
/// `[core/no-app]`, on whichever platform the mismatch lands on.
///
/// Pins: iOS and Android each resolve to their own const [FirebaseOptions]
/// (by identity — they are static consts, so returning the right one *is*
/// returning the same object), and every desktop platform this app does not
/// ship for throws [UnsupportedError] rather than silently handing back
/// either mobile config.
///
/// Coverage gap, stated rather than worked around: the `if (kIsWeb) throw
/// ...` branch guards a compile-time constant that is `false` for every
/// target this test suite runs on (the Dart VM / native test host, never
/// `dart compile js`/wasm), so it cannot be driven `true` from here — unlike
/// `defaultTargetPlatform`, which `debugDefaultTargetPlatformOverride` can
/// freely swap for the rest of this file's cases.
library;

import 'package:dpip/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  test('iOS resolves to the iOS options', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

    expect(
      DefaultFirebaseOptions.currentPlatform,
      same(DefaultFirebaseOptions.ios),
    );
  });

  test('Android resolves to the Android options', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;

    expect(
      DefaultFirebaseOptions.currentPlatform,
      same(DefaultFirebaseOptions.android),
    );
  });

  for (final platform in [
    TargetPlatform.fuchsia,
    TargetPlatform.linux,
    TargetPlatform.macOS,
    TargetPlatform.windows,
  ]) {
    test('$platform is not configured and throws UnsupportedError', () {
      debugDefaultTargetPlatformOverride = platform;

      expect(
        () => DefaultFirebaseOptions.currentPlatform,
        throwsA(
          isA<UnsupportedError>().having(
            (e) => e.message,
            'message',
            contains('$platform'),
          ),
        ),
      );
    });
  }

  test('the iOS and Android options both name the shared Firebase project', () {
    // Both native config files (see the library doc) point at one Firebase
    // project — a mismatch here would mean a build silently talking to the
    // wrong backend on one platform.
    expect(DefaultFirebaseOptions.ios.projectId, 'dpip-a658c');
    expect(DefaultFirebaseOptions.android.projectId, 'dpip-a658c');
    expect(
      DefaultFirebaseOptions.ios.messagingSenderId,
      DefaultFirebaseOptions.android.messagingSenderId,
    );
  });
}
