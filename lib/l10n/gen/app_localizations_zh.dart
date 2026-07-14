// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get languageName => '繁體中文(臺灣)';

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
  String get moreDeveloper => '除錯資訊';

  @override
  String get developerCopied => '已複製到剪貼簿';

  @override
  String get developerCopyAll => '全部複製';

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
  String get moreDiscord => 'Discord 社群';

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
  String get commonFetchFailed => '無法獲取資料,請稍後重試';

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
      '使用 DPIP 前,請詳閱以下注意事項:\n\n• 任何資訊應以中央氣象署發布之內容為準。\n\n• 根據網路狀態、伺服器狀態、應用程式狀態、上游資料來源狀態等,有收不到資訊的可能性,我們會盡力避免此類情況,但不保證一定不會發生。\n\n• 強烈搖晃有機率比通知早抵達使用者所在地。\n\n• 地震速報為快速計算之結果,可能存在較大誤差,應理解並謹慎使用。\n\n• 任何不被官方所認可的行為均有可能承擔法律風險,請務必遵守相關規範。\n\n此外,為提供在地化警報,本服務會在前景及背景蒐集並上傳您的概略位置與裝置推播識別碼,僅用於決定應向您推送之警報。\n\n點選下方「同意並繼續」即表示您已閱讀、理解並同意上述事項。';

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
  String get onboardingPermLocationDesc => '依你所在位置推送在地警報。';

  @override
  String get onboardingPermBackground => '背景定位';

  @override
  String get onboardingPermBackgroundDesc => '選擇「一律允許」,關閉 App 也能推送在地警報。';

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

  @override
  String get language => '語言';

  @override
  String get languageSettings => '語言設定';

  @override
  String get languageSystem => '系統預設';

  @override
  String get locationBannerServiceOff => '定位服務已關閉,無法針對你的所在地推送警報。';

  @override
  String get locationBannerPermission => '尚未授權定位,無法針對你的所在地推送警報。';

  @override
  String get locationBannerFix => '開啟設定';

  @override
  String get notifyBannerDisabled => '通知已關閉,將收不到災害警報。';

  @override
  String get onboardingSkipTitle => '尚未完成授權';

  @override
  String get onboardingSkipBody =>
      '未授權定位與通知,DPIP 將無法即時通知你所在地的地震與災害。你仍可稍後在設定中開啟。';

  @override
  String get onboardingSkipStay => '返回授權';

  @override
  String get onboardingSkipLeave => '仍要略過';

  @override
  String get moreYoutube => 'YouTube';

  @override
  String get moreGithub => 'ExpTech GitHub';

  @override
  String get moreSourceCode => '原始碼';

  @override
  String get moreSectionApp => '取得 App';

  @override
  String get moreGooglePlay => 'Google Play';

  @override
  String get moreAppStore => 'App Store';
}

/// The translations for Chinese, using the Han script (`zh_Hans`).
class AppLocalizationsZhHans extends AppLocalizationsZh {
  AppLocalizationsZhHans() : super('zh_Hans');

  @override
  String get languageName => '简体中文';

  @override
  String get navHome => '首页';

  @override
  String get navEvents => '事件';

  @override
  String get navMap => '地图';

  @override
  String get navEarthquake => '地震';

  @override
  String get navMore => '更多';

  @override
  String get appLogs => '应用日志';

  @override
  String get mapPlaceholderDisabled => '地图（暂时禁用）';

  @override
  String get moreSectionGeneral => '通用';

  @override
  String get regionManageTitle => '常用地区';

  @override
  String get regionSelectTitle => '选择地区';

  @override
  String regionSelectCount(int count, int max) {
    return '已选 $count/$max';
  }

  @override
  String regionSelectFull(int max) {
    return '最多只能选择 $max 个地区';
  }

  @override
  String get moreSectionAdvanced => '高级';

  @override
  String get moreDeveloper => '调试信息';

  @override
  String get developerCopied => '已复制到剪贴板';

  @override
  String get developerCopyAll => '全部复制';

  @override
  String get experimentalFeatures => '实验性功能';

  @override
  String get moreSectionLinks => '相关链接';

  @override
  String get moreCwaEew => '中央气象署地震预警';

  @override
  String get moreTremReport => 'TREM 检测报告';

  @override
  String get moreServerStatus => '服务器状态';

  @override
  String get moreAnnouncements => '公告';

  @override
  String get moreDiscord => 'Discord 社区';

  @override
  String get moreNotifyLog => 'DPIP 通知发送记录';

  @override
  String get moreLinkOpenFailed => '无法打开链接';

  @override
  String get weatherDynamicState => '天气动画';

  @override
  String get weatherDynamicStateSubtitle => '覆盖首页背景天气';

  @override
  String get weatherModeAuto => '自动';

  @override
  String get weatherModeClear => '晴天';

  @override
  String get weatherModeRain => '雨天';

  @override
  String get weatherModeFog => '大雾';

  @override
  String get weatherModeThunderstorm => '雷雨';

  @override
  String get commonLoading => '加载中…';

  @override
  String get commonRetry => '重试';

  @override
  String get commonError => '出错了';

  @override
  String get commonFetchFailed => '无法获取数据,请稍后重试';

  @override
  String get commonEmpty => '暂无内容';

  @override
  String get feedConnecting => '连接中…';

  @override
  String get feedStale => '数据可能已过期';

  @override
  String get feedOffline => '连接中断';

  @override
  String get eewTitle => '地震预警';

  @override
  String get eewNone => '当前没有地震预警';

  @override
  String eewSummary(String magnitude, String depth) {
    return '震级 $magnitude·深度 $depth 公里';
  }

  @override
  String get regionNationwide => '全国';

  @override
  String get regionCurrent => '当前位置';

  @override
  String get regionCurrentUnavailable => '无法获取当前位置';

  @override
  String get weatherPrecipitation => '降水量';

  @override
  String get weatherHumidity => '湿度';

  @override
  String get mapLayers => '图层';

  @override
  String get mapLayerRadar => '雷达回波';

  @override
  String get mapTimelineNow => '现在';

  @override
  String get mapTimelineObserved => '观测';

  @override
  String get notifySettingsMenu => '通知设置';

  @override
  String get notifyTitle => '通知';

  @override
  String get notifyUnavailable => '推送通知尚未就绪，请稍后再试。';

  @override
  String get notifySetFailed => '设置失败，请稍后再试。';

  @override
  String get notifySectionEew => '地震预警';

  @override
  String get notifySectionEarthquake => '地震';

  @override
  String get notifySectionWeather => '天气';

  @override
  String get notifySectionTsunami => '海啸';

  @override
  String get notifySectionOther => '其他';

  @override
  String get notifyEew => '紧急地震预警';

  @override
  String get notifyMonitor => '强震监视器';

  @override
  String get notifyReport => '地震报告';

  @override
  String get notifyIntensity => '震度速报';

  @override
  String get notifyThunderstorm => '雷雨预警';

  @override
  String get notifyAdvisory => '气象预警';

  @override
  String get notifyEvacuation => '防灾信息';

  @override
  String get notifyTsunami => '海啸信息';

  @override
  String get notifyAnnouncement => '公告';

  @override
  String get notifyOptOff => '关闭';

  @override
  String get notifyOptAll => '接收全部';

  @override
  String get notifyOptLocalIntensity4 => '本地震度4以上';

  @override
  String get notifyOptLocalIntensity1 => '本地震度1以上';

  @override
  String get notifyOptWeatherLocal => '仅接收当前位置';

  @override
  String get notifyOptTsunamiWarning => '仅接收海啸警报';

  @override
  String get notifyOptTsunamiAll => '海啸消息、海啸警报';

  @override
  String get onboardingNext => '下一步';

  @override
  String get onboardingBack => '上一步';

  @override
  String get onboardingScrollHint => '向下滚动以继续';

  @override
  String get onboardingIntroTitle => '欢迎使用 DPIP';

  @override
  String get onboardingIntroBody =>
      'DPIP 是与你并肩的防灾伙伴，整合地震预警、地震报告、天气与各类灾害信息，在关键时刻即时通知你。\n\n• 地震：地震预警、震度速报与详细报告\n• 天气：实时雷雨消息与气象预警\n• 海啸与防灾信息\n\n接下来，我们会请你阅读服务条款，并授权几项权限，让 DPIP 能实时守护你。';

  @override
  String get onboardingTermsTitle => '服务条款';

  @override
  String get onboardingTermsBody =>
      '使用 DPIP 前，请详细阅读以下注意事项：\n\n• 任何信息均应以中央气象署（CWA）发布的内容为准。\n\n• 受网络状态、服务器状态、应用程序状态、上游数据来源状态等因素影响，存在收不到信息的可能，我们会尽力避免此类情况，但不保证一定不会发生。\n\n• 强烈震动有可能比通知更早抵达您所在的位置。\n\n• 地震预警为快速计算的结果，可能存在较大误差，请理解并谨慎使用。\n\n• 任何未获官方认可的行为均可能承担法律风险，请务必遵守相关规定。\n\n此外，为提供本地化预警，本服务会在前台及后台收集并上传您的大致位置与设备推送标识符，仅用于决定应向您推送哪些预警。\n\n点击下方“同意并继续”即表示您已阅读、理解并同意上述事项。';

  @override
  String get onboardingTermsAgree => '我已阅读并同意服务条款';

  @override
  String get onboardingAgreeContinue => '同意并继续';

  @override
  String get onboardingPermsTitle => '权限授权';

  @override
  String get onboardingPermsBody => '为了在灾害发生的第一时间通知你，请授权以下权限。你可以随时在系统设置中更改。';

  @override
  String get onboardingPermNotify => '通知';

  @override
  String get onboardingPermNotifyDesc => '在地震、天气与灾害发生时，即时推送预警通知。';

  @override
  String get onboardingPermCritical => '重要警告';

  @override
  String get onboardingPermCriticalDesc => '让危及生命的地震预警，即使在静音或勿扰模式下也能发出声响。';

  @override
  String get onboardingPermLocation => '定位';

  @override
  String get onboardingPermLocationDesc => '根据你所在的位置推送本地预警。';

  @override
  String get onboardingPermBackground => '后台定位';

  @override
  String get onboardingPermBackgroundDesc => '选择“始终允许”，关闭应用后也能向你推送本地预警。';

  @override
  String get onboardingPermBattery => '电池优化白名单';

  @override
  String get onboardingPermBatteryDesc => '允许 DPIP 在后台持续运行，避免预警延迟或漏收。';

  @override
  String get onboardingGrant => '授权';

  @override
  String get onboardingGranted => '已授权';

  @override
  String get onboardingStart => '开始使用';

  @override
  String get language => '语言';

  @override
  String get languageSettings => '语言设置';

  @override
  String get languageSystem => '系统默认';

  @override
  String get locationBannerServiceOff => '定位服务已关闭，无法向你所在的区域推送本地预警。';

  @override
  String get locationBannerPermission => '尚未授予定位权限，无法向你所在的区域推送本地预警。';

  @override
  String get locationBannerFix => '打开设置';

  @override
  String get notifyBannerDisabled => '通知已关闭,将收不到灾害警报。';

  @override
  String get onboardingSkipTitle => '尚未完成授权';

  @override
  String get onboardingSkipBody =>
      '未授权定位与通知,DPIP 将无法实时通知你所在地的地震与灾害。你仍可稍后在设置中开启。';

  @override
  String get onboardingSkipStay => '返回授权';

  @override
  String get onboardingSkipLeave => '仍要跳过';

  @override
  String get moreYoutube => 'YouTube';

  @override
  String get moreGithub => 'ExpTech GitHub';

  @override
  String get moreSourceCode => '源代码';

  @override
  String get moreSectionApp => '获取 App';

  @override
  String get moreGooglePlay => 'Google Play';

  @override
  String get moreAppStore => 'App Store';
}

/// The translations for Chinese, as used in Hong Kong, using the Han script (`zh_Hant_HK`).
class AppLocalizationsZhHantHk extends AppLocalizationsZh {
  AppLocalizationsZhHantHk() : super('zh_Hant_HK');

  @override
  String get languageName => '繁體中文(香港)';

  @override
  String get navHome => '主頁';

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
  String get moreDeveloper => '偵錯資訊';

  @override
  String get developerCopied => '已複製到剪貼簿';

  @override
  String get developerCopyAll => '全部複製';

  @override
  String get experimentalFeatures => '實驗性功能';

  @override
  String get moreSectionLinks => '相關連結';

  @override
  String get moreCwaEew => '中央氣象署強震即時警報';

  @override
  String get moreTremReport => 'TREM 偵測報告';

  @override
  String get moreServerStatus => '伺服器狀態';

  @override
  String get moreAnnouncements => '公告';

  @override
  String get moreDiscord => 'Discord 社群';

  @override
  String get moreNotifyLog => 'DPIP 通知發送記錄';

  @override
  String get moreLinkOpenFailed => '無法開啟連結';

  @override
  String get weatherDynamicState => '天氣動態狀態';

  @override
  String get weatherDynamicStateSubtitle => '覆寫主頁背景天氣';

  @override
  String get weatherModeAuto => '自動';

  @override
  String get weatherModeClear => '晴天';

  @override
  String get weatherModeRain => '雨天';

  @override
  String get weatherModeFog => '大霧';

  @override
  String get weatherModeThunderstorm => '雷暴';

  @override
  String get commonLoading => '載入中…';

  @override
  String get commonRetry => '重試';

  @override
  String get commonError => '發生錯誤';

  @override
  String get commonFetchFailed => '無法獲取資料,請稍後重試';

  @override
  String get commonEmpty => '沒有資料';

  @override
  String get feedConnecting => '連接中…';

  @override
  String get feedStale => '資料可能已過期';

  @override
  String get feedOffline => '連接中斷';

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
  String get notifyUnavailable => '推送尚未就緒,請稍後再試。';

  @override
  String get notifySetFailed => '設定失敗,請稍後再試。';

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
  String get notifyThunderstorm => '雷暴即時訊息';

  @override
  String get notifyAdvisory => '天氣警告及特報';

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
  String get onboardingScrollHint => '向下捲動以繼續';

  @override
  String get onboardingIntroTitle => '歡迎使用 DPIP';

  @override
  String get onboardingIntroBody =>
      'DPIP 是與你並肩的防災夥伴,整合強震即時警報、地震報告、天氣與各類災害資訊,在關鍵時刻即時通知你。\n\n• 地震:強震即時警報、震度速報與地震報告\n• 天氣:雷暴即時訊息、天氣警告及特報\n• 海嘯與防災資訊\n\n接下來,我們會請你閱讀服務條款,並授權幾項讓 DPIP 能即時守護你的權限。';

  @override
  String get onboardingTermsTitle => '服務條款';

  @override
  String get onboardingTermsBody =>
      '使用 DPIP 前,請詳閱以下注意事項:\n\n• 任何資訊應以中央氣象署發布之內容為準。\n\n• 根據網絡狀態、伺服器狀態、應用程式狀態、上游資料來源狀態等,有收不到資訊的可能性,我們會盡力避免此類情況,但不保證一定不會發生。\n\n• 強烈搖晃有機會比通知早抵達用戶所在地。\n\n• 地震速報為快速計算之結果,可能存在較大誤差,應理解並謹慎使用。\n\n• 任何不被官方所認可的行為均有可能承擔法律風險,請務必遵守相關規範。\n\n此外,為提供本地化警報,本服務會在前景及背景收集並上傳您的概略位置與裝置推送識別碼,僅用於決定應向您推送之警報。\n\n點按下方「同意並繼續」即表示您已閱讀、理解並同意上述事項。';

  @override
  String get onboardingTermsAgree => '我已閱讀並同意服務條款';

  @override
  String get onboardingAgreeContinue => '同意並繼續';

  @override
  String get onboardingPermsTitle => '權限授權';

  @override
  String get onboardingPermsBody => '為了在災害發生的第一時間通知你,請授權以下權限。你隨時可以在系統設定中更改。';

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
  String get onboardingPermLocationDesc => '依你所在位置推送本地警報。';

  @override
  String get onboardingPermBackground => '背景定位';

  @override
  String get onboardingPermBackgroundDesc => '選擇「一律允許」,關閉 App 也能推送本地警報。';

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

  @override
  String get language => '語言';

  @override
  String get languageSettings => '語言設定';

  @override
  String get languageSystem => '系統預設';

  @override
  String get locationBannerServiceOff => '定位服務已關閉,無法針對你的所在地推送警報。';

  @override
  String get locationBannerPermission => '尚未授權定位,無法針對你的所在地推送警報。';

  @override
  String get locationBannerFix => '開啟設定';

  @override
  String get notifyBannerDisabled => '通知已關閉,將收不到災害警報。';

  @override
  String get onboardingSkipTitle => '尚未完成授權';

  @override
  String get onboardingSkipBody =>
      '未授權定位與通知,DPIP 將無法即時通知你所在地的地震與災害。你仍可稍後在設定中開啟。';

  @override
  String get onboardingSkipStay => '返回授權';

  @override
  String get onboardingSkipLeave => '仍要略過';

  @override
  String get moreYoutube => 'YouTube';

  @override
  String get moreGithub => 'ExpTech GitHub';

  @override
  String get moreSourceCode => '原始碼';

  @override
  String get moreSectionApp => '取得 App';

  @override
  String get moreGooglePlay => 'Google Play';

  @override
  String get moreAppStore => 'App Store';
}
