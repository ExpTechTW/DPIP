/// Where this build was installed from.
///
/// An update prompt has to send the user somewhere, and "somewhere" is not the
/// platform — it is the distributor. A TestFlight tester who is sent to the App
/// Store finds the *stable* build there and either downgrades or, more often,
/// finds nothing to tap; a sideloaded APK has no Play listing to update from at
/// all. So the destination follows the installer, not `Platform.isIOS`.
///
/// Native detection is cheap and definitive on both platforms: iOS reads the
/// App Store receipt's filename (`sandboxReceipt` **is** the pre-release
/// marker, narrowed to TestFlight by the absence of an embedded provisioning
/// profile — see `DeviceInfoPlugin.installSource`), Android reads the
/// installing package name.
library;

import 'package:dpip/core/logging/log.dart';
import 'package:flutter/services.dart';

/// The distributor a build came from.
enum InstallSource {
  /// iOS, shipped by the App Store.
  appStore,

  /// iOS, shipped by TestFlight — a pre-release channel by construction.
  testFlight,

  /// Android, installed by the Play Store.
  playStore,

  /// A local development build: `flutter run`, Xcode, an adb-installed debug
  /// APK. Detected by the DEBUG compilation condition on iOS and
  /// `FLAG_DEBUGGABLE` on Android — both are build facts, not installer
  /// records, so they work even though adb leaves no installer behind.
  development,

  /// Installed outside any store: a GitHub release APK/IPA, a re-signed IPA,
  /// another Android store. There is no store page to send it to.
  ///
  /// Named for the channel rather than the act: neither platform reveals
  /// *where* a manually installed package was downloaded from, only that no
  /// store did it — but every such install takes its updates from the same
  /// place, the GitHub release page, so that is what the name says.
  github,

  /// Detection failed or has not run. Treated as [github] for destinations,
  /// and as the stable channel for update checks.
  unknown;

  /// Whether this source distributes pre-release builds.
  bool get isBeta => this == InstallSource.testFlight;
}

/// Reads the install source from the platform. Never throws — a failure is
/// [InstallSource.unknown], which degrades to the GitHub release page rather
/// than to a broken button.
abstract final class InstallSourceService {
  static const MethodChannel _channel = MethodChannel(
    'com.exptech.dpip/device_info',
  );

  /// Cached for the process: the installer cannot change while the app runs.
  static InstallSource? _cached;

  static Future<InstallSource> load() async {
    final cached = _cached;
    if (cached != null) return cached;
    InstallSource source;
    try {
      final raw = await _channel.invokeMethod<String>('getInstallSource');
      source = _parse(raw);
      Log.info('install source: ${raw ?? 'null'} -> ${source.name}');
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'install source');
      source = InstallSource.unknown;
    }
    return _cached = source;
  }

  /// Overrides the cached value — tests only.
  static void debugSet(InstallSource? source) => _cached = source;

  static InstallSource _parse(String? raw) => switch (raw) {
    'appStore' => InstallSource.appStore,
    'testFlight' => InstallSource.testFlight,
    'playStore' => InstallSource.playStore,
    'development' => InstallSource.development,
    'sideload' || 'github' => InstallSource.github,
    _ => InstallSource.unknown,
  };
}
