import 'package:dpip/core/preference.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:dpip/utils/log.dart';

final talker = TalkerManager.instance;

Future<void> initializeInstallationData() async {
  talker.log('--- 開始檢查應用程式安裝狀態 ---');

  final PackageInfo packageInfo = await PackageInfo.fromPlatform();
  final int? installTime = packageInfo.installTime?.millisecondsSinceEpoch;

  if (installTime == null) {
    talker.warning('無法獲取目前的應用程式安裝時間，無法執行安裝狀態檢查。');
    return;
  }

  if (Preference.installTime == null) {
    talker.info('SharedPreferences 中未找到安裝時間記錄。');
    talker.info('這可能是 App 首次安裝，或是重新安裝後的首次運行。');

    Preference.instance.clear();
    Preference.installTime = installTime;

    talker.info('已儲存當前安裝時間，並執行了數據初始化/重置。');
  } else {
    if (Preference.installTime != installTime) {
      talker.warning('偵測到系統安裝時間與儲存時間不符 (非典型重新安裝流程)。');
      talker.log('系統安裝時間: $installTime, 儲存的安裝時間: ${Preference.installTime}');
      Preference.instance.clear();
      Preference.installTime = installTime;
      talker.info('已儲存新的安裝時間，並執行了數據重置。');
    } else {
      talker.info('應用程式未重新安裝。使用現有安裝資料。');
    }
  }
  talker.log('--- 應用程式安裝狀態檢查結束 ---');
}
