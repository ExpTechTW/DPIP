import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dpip/utils/log.dart';


const String _installationTimeKey = 'appInstallationTime';

final talker = TalkerManager.instance;

/// 從 PackageInfo 獲取系統報告的應用程式安裝時間。
Future<DateTime?> getAppInstallationTime() async {
  talker.log('嘗試獲取應用程式安裝時間...');
  try {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    DateTime? installTime = packageInfo.installTime;
    if (installTime != null) {
      talker.log('成功獲取系統安裝時間: ${installTime.toIso8601String()}');
      return installTime;
    }
    talker.log('系統安裝時間為空。');
  } catch (e) {
    talker.handle(e, null, '獲取 PackageInfo 安裝時間時發生錯誤');
  }
  return null;
}

/// 將目前的安裝時間儲存到 SharedPreferences。
Future<void> _saveCurrentInstallationTime(SharedPreferences prefs, DateTime installTime) async {
  talker.log('正在儲存當前安裝時間: ${installTime.toIso8601String()}');
  await prefs.setString(_installationTimeKey, installTime.toIso8601String());
  talker.log('安裝時間已成功儲存。');
}

/// 從 SharedPreferences 獲取之前儲存的安裝時間。
Future<DateTime?> getSavedInstallationTime() async {
  talker.log('嘗試從 SharedPreferences 獲取已儲存的安裝時間...');
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final String? savedTimeStr = prefs.getString(_installationTimeKey);
  if (savedTimeStr != null) {
    talker.log('已儲存的安裝時間: $savedTimeStr');
    return DateTime.parse(savedTimeStr);
  }
  talker.log('SharedPreferences 中未找到已儲存的安裝時間。');
  return null;
}

Future<void> initializeInstallationData() async {
  talker.log('--- 開始檢查應用程式安裝狀態 ---');
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final DateTime? currentSystemInstallTime = await getAppInstallationTime();

  if (currentSystemInstallTime == null) {
    talker.warning("無法獲取目前的應用程式安裝時間，無法執行安裝狀態檢查。");
    return;
  }

  final String? savedInstallTimeStr = prefs.getString(_installationTimeKey);

  if (savedInstallTimeStr == null) {
    talker.info("SharedPreferences 中未找到安裝時間記錄。");
    talker.info("這可能是 App 首次安裝，或是重新安裝後的首次運行。");

    await clearAllAppData();

    await _saveCurrentInstallationTime(prefs, currentSystemInstallTime); // 儲存新的安裝時間
    talker.info("已儲存當前安裝時間，並執行了數據初始化/重置。");

  } else {
    final DateTime savedInstallTime = DateTime.parse(savedInstallTimeStr);

    if (currentSystemInstallTime.millisecondsSinceEpoch != savedInstallTime.millisecondsSinceEpoch) {
      talker.warning("偵測到系統安裝時間與儲存時間不符 (非典型重新安裝流程)。");
      talker.log("系統安裝時間: $currentSystemInstallTime, 儲存的安裝時間: $savedInstallTime");
      await clearAllAppData();
      await _saveCurrentInstallationTime(prefs, currentSystemInstallTime);
      talker.info("已儲存新的安裝時間，並執行了數據重置。");
    } else {
      talker.info("應用程式未重新安裝。使用現有安裝資料。");
    }
  }
  talker.log('--- 應用程式安裝狀態檢查結束 ---');
}

Future<void> clearAllAppData() async {
  talker.log('--- 開始清除所有應用程式相關資料 ---');
  final SharedPreferences prefs = await SharedPreferences.getInstance();

  await prefs.remove(_installationTimeKey);
  talker.log('已移除安裝時間標記: $_installationTimeKey');

  await prefs.remove('user_settings');
  talker.log('已移除用戶設定: user_settings');

  await prefs.clear();

  // 更多您希望清除的 SharedPreferences 鍵
  // 例如：
  // await prefs.remove('user_token');
  // talker.log('已移除用戶 token: user_token');
  // await prefs.remove('cached_data_version');
  // talker.log('已移除快取資料版本: cached_data_version');
  // await prefs.remove('last_sync_time');
  // talker.log('已移除上次同步時間: last_sync_time');

  // 慎用！這會清除所有 SharedPreferences 數據，包括您可能不想重置的。
  // await prefs.clear();
  // talker.log("所有 SharedPreferences 數據已通過 prefs.clear() 清除。");

  talker.log("--- 應用程式相關資料清除結束 ---");
}