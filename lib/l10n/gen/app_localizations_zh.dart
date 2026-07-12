// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get navHome => '首頁';

  @override
  String get navEvents => '事件';

  @override
  String get navMap => '地圖';

  @override
  String get navEarthquake => '地震';

  @override
  String get navMore => '更多';

  @override
  String get appLogs => 'App 日誌';

  @override
  String get mapPlaceholderDisabled => '地圖(暫時停用)';

  @override
  String get moreSectionAdvanced => '進階';

  @override
  String get experimentalFeatures => '實驗性功能';

  @override
  String get weatherDynamicState => '天氣動態狀態';

  @override
  String get weatherDynamicStateSubtitle => '覆寫首頁背景天氣';

  @override
  String get weatherModeAuto => '自動';

  @override
  String get weatherModeClear => '晴天';

  @override
  String get weatherModeRain => '雨天';

  @override
  String get weatherModeFog => '大霧';

  @override
  String get weatherModeThunderstorm => '雷雨';
}
