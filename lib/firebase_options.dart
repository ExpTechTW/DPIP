/// Firebase project configuration per platform, so `Firebase.initializeApp` can
/// be given **explicit** options instead of relying on a bundled
/// `GoogleService-Info.plist` / `google-services.json`. The iOS plist lives in
/// `ios/Runner/` but is not added to the Xcode target's Copy Bundle Resources,
/// so bare native auto-configuration finds nothing and init fails with
/// `[core/no-app]` (no default app → no FCM/APNs). Passing these options makes
/// init independent of that bundling.
///
/// Values mirror the two native config files (Firebase project `dpip-a658c`). A
/// client API key is not a secret — it identifies the project and is restricted
/// by app/bundle id, so it lives in source like any other build config.
library;

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

/// The [FirebaseOptions] for whichever platform the app is running on.
class DefaultFirebaseOptions {
  const DefaultFirebaseOptions._();

  /// Options for the current platform; throws on an unsupported one.
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('DPIP does not target web.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.android:
        return android;
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        throw UnsupportedError(
          'Firebase is not configured for $defaultTargetPlatform.',
        );
    }
  }

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyALF1O3Celks5H6i3iY43sdMlC4FW9deHw',
    appId: '1:141632948166:ios:15ef51ceb6c19e5b9e14c7',
    messagingSenderId: '141632948166',
    projectId: 'dpip-a658c',
    storageBucket: 'dpip-a658c.appspot.com',
    iosBundleId: 'com.exptech.dpip.dpip',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDMgbvC0NWLL2CfRChypf3yy7OWxEO-I0w',
    appId: '1:141632948166:android:3cb29f28a0a04c589e14c7',
    messagingSenderId: '141632948166',
    projectId: 'dpip-a658c',
    storageBucket: 'dpip-a658c.appspot.com',
  );
}
