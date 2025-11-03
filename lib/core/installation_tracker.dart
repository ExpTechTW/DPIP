import 'package:dpip/core/preference.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:dpip/utils/log.dart';
import 'package:uuid/uuid.dart';

final talker = TalkerManager.instance;
const _uuid = Uuid();

Future<void> initializeInstallationData() async {
  final PackageInfo packageInfo = await PackageInfo.fromPlatform();
  final String currentVersion = packageInfo.version;
  final String currentBuildNumber = packageInfo.buildNumber;
  final String? storedInstallId = Preference.installId;
  final String? storedVersion = Preference.version;
  final String? storedBuildNumber = Preference.buildNumber;

  if (storedInstallId == null || storedVersion == null) {
    talker.info('這是 App 首次安裝。');

    await Preference.instance.clear();
    final String newInstallId = _uuid.v4();
    Preference.installId = newInstallId;
    Preference.version = currentVersion;
    Preference.buildNumber = currentBuildNumber;
    talker.info('已儲存新的安裝 ID 和版本，並執行了數據初始化/重置。');
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
  talker.info('應用程式未重新安裝也未升級。使用現有安裝資料。');
}
