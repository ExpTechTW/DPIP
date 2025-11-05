import 'package:dpip/core/preference.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:dpip/utils/log.dart';
import 'package:uuid/uuid.dart';

final talker = TalkerManager.instance;
const _uuid = Uuid();

// Guard future to prevent concurrent initializations from racing.
Future<void>? _initializationFuture;

/// Public entry point. Multiple callers will await the same initialization
/// future so we avoid generating / writing multiple installIds concurrently.
Future<void> initializeInstallationData() {
  if (_initializationFuture != null) return _initializationFuture!;
  _initializationFuture = _initializeInstallationDataInternal();
  return _initializationFuture!;
}

Future<void> _initializeInstallationDataInternal() async {
  try {
    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;
    final currentBuildNumber = packageInfo.buildNumber;

    String? installId;
    try {
      installId = await Preference.installId;
    } catch (e, s) {
      // Secure storage read failed; log and continue with a null installId so
      // we generate a new one locally and attempt to persist it.
      talker.error('Failed to read installId from secure storage', e, s);
      installId = null;
    }

    final storedVersion = Preference.version;
    final storedBuildNumber = Preference.buildNumber;

    if (installId == null) {
      talker.info('首次安裝或資料重置，建立新的 installId');

      installId = _uuid.v4();
      try {
        await Preference.setInstallId(installId);
      } catch (e, s) {
        // If we cannot write to secure storage, log the error but continue.
        talker.error('Failed to write installId to secure storage', e, s);
      }

      Preference.version = currentVersion;
      Preference.buildNumber = currentBuildNumber;
      talker.info(
        '已建立新的 installId 並儲存版本資訊',
        'version: $currentVersion | buildNumber: $currentBuildNumber\n'
        'installId: $installId'
      );
      return;
    }

    if (storedVersion != currentVersion || storedBuildNumber != currentBuildNumber) {
      talker.info('偵測到版本變更：$storedVersion → $currentVersion');

      if (storedBuildNumber != currentBuildNumber) {
        talker.info('Build 號也已變更，這是版本升級。');
      }
      Preference.version = currentVersion;
      Preference.buildNumber = currentBuildNumber;
      talker.info('已更新版本資訊，保留現有數據。');
      return;
    }

    talker.info(
      '應用程式未重新安裝也未升級，使用現有的安裝資料。\n'
      'version: $currentVersion | buildNumber: $currentBuildNumber\n'
      'installId: $installId'
    );
  } catch (e, s) {
    talker.error('初始化安裝資料時發生錯誤', e, s);
  }
}
