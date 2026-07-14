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
  String get moreSectionGeneral => '一般';

  @override
  String get regionManageTitle => '常用地區';

  @override
  String get regionSelectTitle => '選擇地區';

  @override
  String regionSelectCount(int count, int max) {
    return '已選 $count/$max';
  }

  @override
  String regionSelectFull(int max) {
    return '最多只能選擇 $max 個地區';
  }

  @override
  String get moreSectionAdvanced => '進階';

  @override
  String get experimentalFeatures => '實驗性功能';

  @override
  String get moreSectionLinks => '相關連結';

  @override
  String get moreCwaEew => '中央氣象署強震即時警報';

  @override
  String get moreTremReport => 'TREM 檢知報告';

  @override
  String get moreServerStatus => '伺服器狀態';

  @override
  String get moreAnnouncements => '公告';

  @override
  String get moreNotifyLog => 'DPIP 通知發送記錄';

  @override
  String get moreLinkOpenFailed => '無法開啟連結';

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

  @override
  String get commonLoading => '載入中…';

  @override
  String get commonRetry => '重試';

  @override
  String get commonError => '發生錯誤';

  @override
  String get commonEmpty => '沒有資料';

  @override
  String get feedConnecting => '連線中…';

  @override
  String get feedStale => '資料可能已過期';

  @override
  String get feedOffline => '連線中斷';

  @override
  String get eewTitle => '地震速報';

  @override
  String get eewNone => '目前沒有地震速報';

  @override
  String eewSummary(String magnitude, String depth) {
    return '規模 $magnitude・深度 $depth 公里';
  }

  @override
  String get regionNationwide => '全國';

  @override
  String get regionCurrent => '所在地';

  @override
  String get regionCurrentUnavailable => '無法取得所在地位置';

  @override
  String get weatherPrecipitation => '降水量';

  @override
  String get weatherHumidity => '濕度';

  @override
  String get mapLayers => '圖層';

  @override
  String get mapLayerRadar => '雷達回波';

  @override
  String get mapTimelineNow => '現在';

  @override
  String get mapTimelineObserved => '觀測';

  @override
  String get notifySettingsMenu => '通知設定';

  @override
  String get notifyTitle => '通知';

  @override
  String get notifyUnavailable => '推播尚未就緒，請稍後再試。';

  @override
  String get notifySetFailed => '設定失敗，請稍後再試。';

  @override
  String get notifySectionEew => '地震速報';

  @override
  String get notifySectionEarthquake => '地震';

  @override
  String get notifySectionWeather => '天氣';

  @override
  String get notifySectionTsunami => '海嘯';

  @override
  String get notifySectionOther => '其他';

  @override
  String get notifyEew => '緊急地震速報';

  @override
  String get notifyMonitor => '強震監視器';

  @override
  String get notifyReport => '地震報告';

  @override
  String get notifyIntensity => '震度速報';

  @override
  String get notifyThunderstorm => '雷雨即時訊息';

  @override
  String get notifyAdvisory => '天氣警特報';

  @override
  String get notifyEvacuation => '防災資訊';

  @override
  String get notifyTsunami => '海嘯資訊';

  @override
  String get notifyAnnouncement => '公告';

  @override
  String get notifyOptOff => '關閉';

  @override
  String get notifyOptAll => '接收全部';

  @override
  String get notifyOptLocalIntensity4 => '所在地震度4以上';

  @override
  String get notifyOptLocalIntensity1 => '所在地震度1以上';

  @override
  String get notifyOptWeatherLocal => '接收所在地';

  @override
  String get notifyOptTsunamiWarning => '只接收海嘯警報';

  @override
  String get notifyOptTsunamiAll => '海嘯消息、海嘯警報';

  @override
  String get onboardingNext => '下一步';

  @override
  String get onboardingBack => '上一步';

  @override
  String get onboardingScrollHint => '往下捲動以繼續';

  @override
  String get onboardingIntroTitle => '歡迎使用 DPIP';

  @override
  String get onboardingIntroBody =>
      'DPIP 是與你並肩的防災夥伴,整合強震即時警報、地震報告、天氣與各類災害資訊,在關鍵時刻即時通知你。\n\n• 地震:強震即時警報、震度速報與地震報告\n• 天氣:雷雨即時訊息、天氣警特報\n• 海嘯與防災資訊\n\n接下來,我們會請你閱讀服務條款,並授權幾項讓 DPIP 能即時守護你的權限。';

  @override
  String get onboardingTermsTitle => '服務條款';

  @override
  String get onboardingTermsBody =>
      '歡迎使用 DPIP(防災資訊平台)。使用本應用程式前,請詳閱以下條款。\n\n一、服務性質:DPIP 彙整中央氣象署(CWA)、ExpTech 及其他來源之地震、天氣與防災資訊,以盡力方式即時提供。本服務僅供參考,不得取代政府官方警報與指示;實際災害應變請以中央氣象署及各級主管機關發布之資訊為準。\n\n二、即時性與準確性:資訊之傳遞可能因網路、裝置、系統或第三方服務而延遲、中斷或不完整。強震即時警報等具有先天不確定性,可能誤報或漏報,請勿完全依賴本服務作為唯一之防災依據。\n\n三、位置與資料:為提供在地化警報,本服務會在前景及背景蒐集並上傳您的概略位置與裝置推播識別碼,僅用於決定應向您推送之警報。\n\n四、責任限制:於法律允許之最大範圍內,ExpTech 及其開發者對於因使用或無法使用本服務所致之任何直接或間接損害,不負賠償責任。\n\n五、條款變更:本條款得隨時更新,恕不另行個別通知;繼續使用即視為同意最新條款。\n\n點選下方「同意並繼續」即表示您已閱讀、理解並同意本服務條款。';

  @override
  String get onboardingTermsAgree => '我已閱讀並同意服務條款';

  @override
  String get onboardingAgreeContinue => '同意並繼續';

  @override
  String get onboardingPermsTitle => '權限授權';

  @override
  String get onboardingPermsBody => '為了在災害發生的第一時間通知你,請授權以下權限。你隨時可以在系統設定中變更。';

  @override
  String get onboardingPermNotify => '通知';

  @override
  String get onboardingPermNotifyDesc => '在地震、天氣與災害發生時,即時傳遞警報通知。';

  @override
  String get onboardingPermCritical => '重大通知';

  @override
  String get onboardingPermCriticalDesc => '讓危及生命的強震即時警報,即使在靜音或勿擾模式下也能發出聲響。';

  @override
  String get onboardingPermLocation => '定位';

  @override
  String get onboardingPermLocationDesc => '自動依你所在位置推送在地警報,包含背景更新。';

  @override
  String get onboardingPermBattery => '省電白名單';

  @override
  String get onboardingPermBatteryDesc => '允許 DPIP 在背景持續運作,避免警報延遲或漏收。';

  @override
  String get onboardingGrant => '授權';

  @override
  String get onboardingGranted => '已授權';

  @override
  String get onboardingStart => '開始使用';
}
