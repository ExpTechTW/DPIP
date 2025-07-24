import 'package:dpip/core/preference.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:dpip/utils/log.dart';

final talker = TalkerManager.instance;

Future<void> initializeInstallationData() async {
  talker.log('--- 開始檢查應用程式安裝狀態 ---');

  final PackageInfo packageInfo = await PackageInfo.fromPlatform();
  final int? installTime = packageInfo.installTime?.millisecondsSinceEpoch;
  final String currentVersion = packageInfo.version;

  if (installTime == null) {
    talker.warning('無法獲取目前的應用程式安裝時間，無法執行安裝狀態檢查。');
    return;
  }

  final String? storedVersion = Preference.version;
  final int? storedInstallTime = Preference.installTime;

  if (storedInstallTime == null || storedVersion == null) {
    talker.info('SharedPreferences 中未找到安裝時間或版本記錄。');
    talker.info('這是 App 首次安裝。');
    
    Preference.instance.clear();
    Preference.installTime = installTime;
    Preference.version = currentVersion;
    talker.info('已儲存新的安裝時間和版本，並執行了數據初始化/重置。');
  } else if (storedVersion != currentVersion) {
    talker.info('偵測到版本變更：$storedVersion → $currentVersion');
    
    if (storedInstallTime != installTime) {
      talker.info('安裝時間也已變更，這是版本升級。');
      Preference.installTime = installTime;
    }
    
    Preference.version = currentVersion;
    talker.info('已更新版本資訊，保留現有數據。');
  } else if (storedInstallTime != installTime) {
    talker.warning('偵測到相同版本但安裝時間不同。');
    talker.log('系統安裝時間: $installTime, 儲存的安裝時間: $storedInstallTime');
    talker.info('這是解除安裝後重新安裝相同版本。');
    
    Preference.instance.clear();
    Preference.installTime = installTime;
    Preference.version = currentVersion;
    talker.info('已執行數據重置。');
  } else {
    talker.info('應用程式未重新安裝也未升級。使用現有安裝資料。');
  }
  talker.log('--- 應用程式安裝狀態檢查結束 ---');
}
