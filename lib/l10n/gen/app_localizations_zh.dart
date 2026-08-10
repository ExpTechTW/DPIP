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
  String get navData => '資料';

  @override
  String get navEarthquake => '地震';

  @override
  String get dataSectionSeismic => '地震';

  @override
  String get dataEarthquakeSubtitle => '地震報告';

  @override
  String get dataSectionWeather => '氣象';

  @override
  String get dataWeatherRankingSubtitle => '即時觀測排行';

  @override
  String get weatherRankingTitle => '觀測排行';

  @override
  String weatherRankingMeta(String time, int count) {
    return '資料時間：$time\n共 $count 觀測點';
  }

  @override
  String get weatherRankingEmpty => '目前沒有可排序的觀測';

  @override
  String get weatherRankingBy => '依';

  @override
  String get weatherRankingHighest => '最高';

  @override
  String get weatherRankingLowest => '最低';

  @override
  String get weatherRankingMergeTo => '合併至';

  @override
  String get weatherRankingMergeTown => '鄉鎮';

  @override
  String get weatherRankingMergeCounty => '縣市';

  @override
  String get weatherRankingWind => '風速';

  @override
  String get weatherRankingGust => '陣風';

  @override
  String get weatherRankingTempExtremes => '溫度極值';

  @override
  String get weatherRankingExtremeHigh => '今日最高';

  @override
  String get weatherRankingExtremeLow => '今日最低';

  @override
  String get weatherRankingExtremeRange => '日溫差';

  @override
  String weatherRankingRecordedAt(String time) {
    return '記錄於 $time';
  }

  @override
  String weatherRankingAnalysisCurrent(String value) {
    return '當下 $value°C';
  }

  @override
  String weatherRankingAnalysisHigh(String value) {
    return '最高 $value';
  }

  @override
  String weatherRankingAnalysisLow(String value) {
    return '最低 $value';
  }

  @override
  String weatherRankingAnalysisRange(String value) {
    return '溫差 $value°C';
  }

  @override
  String get reportListEmpty => '目前沒有地震報告';

  @override
  String get reportListEmptyFiltered => '沒有符合條件的地震報告';

  @override
  String reportListMeta(String magnitude, String depth) {
    return 'M$magnitude · $depth 公里';
  }

  @override
  String reportListMagnitude(String magnitude) {
    return 'M$magnitude';
  }

  @override
  String get reportListDepthUnit => '公里';

  @override
  String get reportListLocalFelt => '小區域有感';

  @override
  String get reportListToday => '今天';

  @override
  String get reportListYesterday => '昨天';

  @override
  String reportListDayCount(int count) {
    return '$count';
  }

  @override
  String get reportListEnd => '已到最後一頁';

  @override
  String get reportFilterTitle => '篩選';

  @override
  String get reportFilterSort => '排序方式';

  @override
  String get reportFilterSortTime => '時間';

  @override
  String get reportFilterSortIntensity => '震度';

  @override
  String get reportFilterSortMagnitude => '規模';

  @override
  String get reportFilterSortDepth => '深度';

  @override
  String get reportFilterOrderDesc => '降序';

  @override
  String get reportFilterOrderAsc => '升序';

  @override
  String get reportFilterIntensity => '震度';

  @override
  String get reportFilterIntensityInfoTitle => '震度新制與舊制';

  @override
  String get reportFilterIntensityInfoIntro =>
      '中央氣象署自 2020 年 1 月 1 日（臺北時間）起改用新制震度。';

  @override
  String get reportFilterIntensityInfoLegacyTitle => '舊制（2020 以前）';

  @override
  String get reportFilterIntensityInfoLegacyBody => '震度僅 0–7，沒有 5弱／5強／6弱／6強。';

  @override
  String get reportFilterIntensityInfoModernTitle => '新制（2020 起）';

  @override
  String get reportFilterIntensityInfoModernBody =>
      '震度為 0–4、5弱、5強、6弱、6強、7。篩選滑桿依新制；列表中較早的地震會以舊制標示顯示。';

  @override
  String get reportFilterMagnitude => '規模';

  @override
  String get reportFilterDepth => '深度';

  @override
  String reportFilterDepthKm(String depth) {
    return '$depth 公里';
  }

  @override
  String get reportFilterDate => '日期';

  @override
  String get reportFilterDatePick => '選擇日期';

  @override
  String get reportFilterDateStartNote => '開始日：當日 00:00（臺北時間）';

  @override
  String get reportFilterDateEndNote => '結束日：當日 24:00（臺北時間）';

  @override
  String reportFilterRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String get reportFilterLocation => '地點';

  @override
  String get reportFilterLocationHint => '例如：花蓮、東部海域';

  @override
  String get reportFilterAny => '不限';

  @override
  String get reportFilterApply => '套用';

  @override
  String get reportFilterReset => '重設';

  @override
  String get reportListSearch => '查詢';

  @override
  String get reportDetailTitle => '地震報告';

  @override
  String reportDetailNumbered(String number) {
    return '編號 $number 顯著有感地震';
  }

  @override
  String get reportDetailLocalFelt => '小區域有感地震';

  @override
  String get reportDetailInfo => '詳細資訊';

  @override
  String get reportDetailOriginTime => '發震時間';

  @override
  String get reportDetailEpicenter => '震央座標';

  @override
  String get reportDetailMagnitude => '地震規模';

  @override
  String get reportDetailDepth => '震源深度';

  @override
  String get reportDetailAreaIntensity => '各地震度';

  @override
  String get reportDetailLocalIntensity => '所在地的震度';

  @override
  String get reportDetailLocalIntensityUnavailable => '沒有震度訊息';

  @override
  String get reportDetailSortByIntensity => '依震度排序';

  @override
  String get reportDetailSortByCounty => '依縣市排序';

  @override
  String get reportDetailImage => '地震報告圖';

  @override
  String get reportDetailImageUnavailable => '報告圖尚未提供';

  @override
  String get reportDetailOpenReport => '報告頁面';

  @override
  String get reportDetailReplay => '重播';

  @override
  String get navMore => '更多';

  @override
  String get appLogs => 'App 日誌';

  @override
  String get changelogTitle => '更新日誌';

  @override
  String get changelogEmpty => '目前沒有更新日誌';

  @override
  String get changelogTypePrerelease => '公測';

  @override
  String get changelogTypeStable => '正式';

  @override
  String get changelogCurrentVersion => '目前版本';

  @override
  String get changelogVersionDetails => '版本資訊';

  @override
  String get changelogBodyEmpty => '此版本沒有說明。';

  @override
  String get mapPlaceholderDisabled => '地圖(暫時停用)';

  @override
  String get moreSectionRegion => '地區';

  @override
  String get moreSectionNotify => '通知';

  @override
  String get moreSectionDisplay => '顯示';

  @override
  String get regionManageTitle => '常用地區';

  @override
  String get regionAddButton => '新增地區';

  @override
  String get regionEmpty => '尚未新增常用地區';

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
  String get regionEdit => '修改';

  @override
  String get moreSectionAdvanced => '進階';

  @override
  String get moreDeveloper => '除錯資訊';

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
  String get regionCurrentUnavailable => '無法取得所在地位置資訊';

  @override
  String get weatherPrecipitation => '降水量';

  @override
  String get weatherHumidity => '濕度';

  @override
  String get homeForecastTitle => '24小時預報';

  @override
  String homeForecastHighLow(String high, String low) {
    return '高 $high° · 低 $low°';
  }

  @override
  String homeForecastPop(String pop) {
    return '$pop%';
  }

  @override
  String homeForecastFeelsLike(String temp) {
    return '體感 $temp°';
  }

  @override
  String homeForecastHumidity(String value) {
    return '濕度 $value%';
  }

  @override
  String homeForecastWind(String direction, String level) {
    return '$direction · $level 級';
  }

  @override
  String get homeForecastUnavailable => '選擇鄉鎮後可查看預報';

  @override
  String get homeForecastEmpty => '目前沒有預報資料';

  @override
  String get homeActiveEventsTitle => '生效中事件';

  @override
  String get homeActiveEventsEmpty => '目前沒有生效中的事件';

  @override
  String get homeRainTrendTitle => '近 1 小時降水趨勢';

  @override
  String homeRainTrendMinute(int minute) {
    return '$minute分';
  }

  @override
  String homeRainTrendUpdated(String time) {
    return '更新 $time';
  }

  @override
  String get homeRainTrendNoData => '無資料';

  @override
  String get homeRainTrendScattered => '可能會有零星降雨';

  @override
  String get homeRainTrendLightSustained => '未來 1 小時會有持續小雨';

  @override
  String homeRainTrendLightStopping(int minutes) {
    return '預計 $minutes 分鐘後停止下小雨';
  }

  @override
  String get homeRainTrendHeavySustained => '未來 1 小時會有持續大雨';

  @override
  String homeRainTrendHeavyStopping(int minutes) {
    return '預計 $minutes 分鐘後停止下大雨';
  }

  @override
  String get mapLayers => '圖層';

  @override
  String get mapLayerOrderTitle => '調整圖層順序';

  @override
  String get mapLayerOrderReset => '回復預設順序';

  @override
  String get mapLayerRadar => '雷達合成回波圖';

  @override
  String get mapLayerSatellite => 'ひまわり 紅外線圖';

  @override
  String get mapLayerQpesums => '未來 1 小時降水預報';

  @override
  String get mapLayerLightning => '閃電';

  @override
  String lightningLegendCg(int minutes) {
    return '對地 · $minutes 分內';
  }

  @override
  String lightningLegendCc(int minutes) {
    return '雲間 · $minutes 分內';
  }

  @override
  String get mapTimelineNow => '現在';

  @override
  String get mapTimelineObserved => '觀測';

  @override
  String get mapTimelineForecast => '預報';

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

  @override
  String get displaySettings => '顯示設定';

  @override
  String get defaultMapLayerSettings => '地圖預設圖層';

  @override
  String get defaultMapLayerSubtitle => '開啟地圖分頁時顯示此圖層，底部導覽列圖示與文字會一併更新。';

  @override
  String get mapNavRadar => '雷達';

  @override
  String get mapNavQpesums => '預報';

  @override
  String get mapNavSatellite => '衛星';

  @override
  String get mapNavLightning => '閃電';

  @override
  String get mapNavTyphoon => '颱風';

  @override
  String get mapNavEarthquake => '地震';

  @override
  String get mapNavTemperature => '溫度';

  @override
  String get mapNavHumidity => '濕度';

  @override
  String get mapNavPressure => '氣壓';

  @override
  String get mapNavWind => '風向';

  @override
  String get mapNavRain => '雨量';

  @override
  String get mapNavDisaster => '防災';

  @override
  String get displayTheme => '主題';

  @override
  String get themeSystem => '跟隨系統';

  @override
  String get themeLight => '淺色';

  @override
  String get themeDark => '深色';

  @override
  String get moreSectionAbout => '關於';

  @override
  String get termsOfService => '服務條款';

  @override
  String get faq => '常見問題';

  @override
  String get openSourceLicenses => '引用套件';

  @override
  String get sponsorTitle => '支持 DPIP';

  @override
  String get sponsorIntro =>
      'DPIP 致力於提供即時防災資訊，沒有廣告或其他營利模式。您的支持能幫助我們維持伺服器運作並持續開發。';

  @override
  String get sponsorSubscriptions => '訂閱制';

  @override
  String get sponsorRecommended => '推薦';

  @override
  String get sponsorOneTime => '單次支援';

  @override
  String sponsorPerMonth(String price) {
    return '$price / 月';
  }

  @override
  String get sponsorRestore => '恢復購買';

  @override
  String get sponsorTerms => '使用條款';

  @override
  String get sponsorPrivacy => '隱私權政策';

  @override
  String get sponsorRestoring => '正在恢復購買…';

  @override
  String get sponsorRestoreUnavailable => '無法連線至商店，請稍後再試';

  @override
  String get commonClose => '關閉';

  @override
  String get mapLayerTemperature => '溫度';

  @override
  String get trendRange24h => '24 小時';

  @override
  String get trendRange7d => '7 天';

  @override
  String get trendNoData => '沒有趨勢資料';

  @override
  String trendCumulativeTotal(String total) {
    return '累計 $total mm';
  }

  @override
  String chartHourLabel(int hour) {
    return '$hour時';
  }

  @override
  String get mapLayerHumidity => '濕度';

  @override
  String get mapLayerPressure => '氣壓';

  @override
  String get mapLayerWind => '風向';

  @override
  String get mapLayerRain => '雨量';

  @override
  String get rainIntervalMenu => '累積時段';

  @override
  String get rainIntervalNow => '今日';

  @override
  String get rainInterval10m => '10 分';

  @override
  String get rainInterval1h => '1 時';

  @override
  String get rainInterval3h => '3 時';

  @override
  String get rainInterval6h => '6 時';

  @override
  String get rainInterval12h => '12 時';

  @override
  String get rainInterval24h => '24 時';

  @override
  String get rainInterval2d => '2 日';

  @override
  String get rainInterval3d => '3 日';

  @override
  String get mapLayerTyphoon => '颱風';

  @override
  String get typhoonNoActive => '目前無颱風';

  @override
  String get typhoonWind => '風速';

  @override
  String get typhoonGust => '陣風';

  @override
  String get typhoonPressure => '氣壓';

  @override
  String get typhoonMotion => '移動';

  @override
  String get typhoonLabelPosition => '中心位置';

  @override
  String get typhoonLabelDirection => '過去移動方向';

  @override
  String get typhoonLabelSpeed => '過去移動時速';

  @override
  String get typhoonLabelPressure => '中心氣壓';

  @override
  String get typhoonLabelWind => '近中心最大風速';

  @override
  String get typhoonLabelGust => '瞬間最大陣風';

  @override
  String get typhoonLabelGaleAvg => '七級風平均暴風半徑';

  @override
  String get typhoonLabelStormAvg => '十級風平均暴風半徑';

  @override
  String get typhoonLabelProbCircle => '70%機率圓';

  @override
  String typhoonForecastLead(String hours) {
    return '預測 +$hours 小時';
  }

  @override
  String get typhoonLabelNw => '西北側';

  @override
  String get typhoonLabelNe => '東北側';

  @override
  String get typhoonLabelSw => '西南側';

  @override
  String get typhoonLabelSe => '東南側';

  @override
  String typhoonValueLat(String lat) {
    return '北緯 $lat 度';
  }

  @override
  String typhoonValueLon(String lon) {
    return '東經 $lon 度';
  }

  @override
  String typhoonValueKm(String n) {
    return '$n 公里';
  }

  @override
  String typhoonValueHpa(String n) {
    return '$n 百帕';
  }

  @override
  String typhoonValueMs(String n) {
    return '每秒 $n 公尺';
  }

  @override
  String typhoonDataTime(String time) {
    return '資料時間\n$time';
  }

  @override
  String get mapLayerMonitor => '強震監視器';

  @override
  String get mapLayerDisasterMap => '防災地圖';

  @override
  String get mapLayerAed => 'AED';

  @override
  String get disasterMapOverlayMenuTooltip => '防災地圖圖層';

  @override
  String get disasterMapOverlaySectionLayers => '圖層';

  @override
  String get disasterMapOverlayAedTooltip => '顯示 AED 位置';

  @override
  String get aedAddress => '地址';

  @override
  String get aedRegion => '縣市區域';

  @override
  String get aedCategory => '場所分類';

  @override
  String get aedType => '場所類型';

  @override
  String get aedPlaceDesc => '放置位置說明';

  @override
  String get aedDescription => '備註';

  @override
  String get aedHoursWeekday => '平日開放時間';

  @override
  String get aedHoursSaturday => '週六開放時間';

  @override
  String get aedHoursSunday => '週日開放時間';

  @override
  String get aedOpenRemark => '開放時間備註';

  @override
  String get aedEmergencyPhone => '緊急聯絡電話';

  @override
  String get mapLayerRestroom => '公廁';

  @override
  String get mapLayerShelter => '避難收容場所';

  @override
  String get disasterMapOverlayRestroomTooltip => '顯示公廁';

  @override
  String get disasterMapOverlayShelterTooltip => '顯示避難收容場所';

  @override
  String get dpmOpenInMaps => '開啟地圖';

  @override
  String get mapAppGoogleMaps => 'Google Maps';

  @override
  String get mapAppAppleMaps => 'Apple Maps';

  @override
  String mapAppDefault(String app) {
    return '$app（預設）';
  }

  @override
  String get mapAppCopyCoordinates => '複製座標';

  @override
  String get mapAppCoordinatesCopied => '已複製座標';

  @override
  String get mapOverlaySectionReference => '參考圖層';

  @override
  String get mapOverlaySectionMap => '地圖';

  @override
  String get rainIntervalSection => '統計時間';

  @override
  String get mapTownLabels => '鄉鎮名稱';

  @override
  String get mapTownLabelsHint => '放大時顯示鄉鎮名稱';

  @override
  String get dpmSheetEmpty => '點選地圖上的標記查看詳情';

  @override
  String get dpmAddress => '地址';

  @override
  String get restroomTypeLabel => '廁所類型';

  @override
  String get restroomCategoryLabel => '類別';

  @override
  String get restroomGradeLabel => '等級';

  @override
  String get restroomTypeFemale => '女廁所';

  @override
  String get restroomTypeMale => '男廁所';

  @override
  String get restroomTypeMixed => '混合廁所';

  @override
  String get restroomTypeAccessible => '無障礙廁所';

  @override
  String get restroomTypeGenderNeutral => '性別友善廁所';

  @override
  String get restroomTypeFamily => '親子廁所';

  @override
  String get restroomTypeUnspecified => '未設定';

  @override
  String get restroomCategoryTransport => '交通';

  @override
  String get restroomCategoryPark => '公園';

  @override
  String get restroomCategoryCommercial => '商業營業場所';

  @override
  String get restroomCategoryReligious => '宗教禮儀場所';

  @override
  String get restroomCategoryCultural => '文化育樂活動場所';

  @override
  String get restroomCategoryGovernment => '民眾洽公場所';

  @override
  String get restroomCategoryWelfare => '社福機構、集會場所';

  @override
  String get restroomCategoryTourist => '觀光地區及風景區';

  @override
  String get restroomCategoryLeisure => '休閒娛樂場所';

  @override
  String get restroomCategoryOther => '其他';

  @override
  String get restroomGradeExcellent => '特優級';

  @override
  String get restroomGradeGood => '優等級';

  @override
  String get restroomGradeAverage => '普通級';

  @override
  String get restroomGradePoor => '不合格';

  @override
  String get shelterAddressLabel => '地址';

  @override
  String get shelterCapacityLabel => '收容人數';

  @override
  String shelterCapacityValue(int n) {
    return '$n 人';
  }

  @override
  String get shelterCategoryLabel => '適用災害';

  @override
  String get shelterIndoorLabel => '室內收容';

  @override
  String get shelterOutdoorLabel => '室外收容';

  @override
  String get shelterVulnerableOkLabel => '適合避難弱者安置';

  @override
  String get dpmYes => '是';

  @override
  String get dpmNo => '否';

  @override
  String get stationSheetEmpty => '點選任一測站查看觀測值';

  @override
  String monitorDelay(String value) {
    return '延遲 $value s';
  }

  @override
  String get monitorWaiting => '等待資料…';

  @override
  String mapLegendUnit(String unit) {
    return '單位：$unit';
  }

  @override
  String get typhoonLegendPast => '實際路徑';

  @override
  String get typhoonIntensityTd => '熱帶性低氣壓';

  @override
  String typhoonPickerNamed(String no, String name) {
    return '$name TY $no';
  }

  @override
  String typhoonPickerTd(String no) {
    return '熱帶性低氣壓 TD $no';
  }

  @override
  String get typhoonIntensityMild => '輕度颱風';

  @override
  String get typhoonIntensityModerate => '中度颱風';

  @override
  String get typhoonIntensityIntense => '強烈颱風';

  @override
  String get typhoonLegendForecast => '預測路徑';

  @override
  String get typhoonLegendForecastPoint => '預測點';

  @override
  String get typhoonLegendCurrent => '目前中心';

  @override
  String get typhoonLegendCone => '預測圓錐';

  @override
  String get mapLegendExpand => '圖例';

  @override
  String get mapLegendCollapse => '收合圖例';

  @override
  String get mapMyLocation => '我的位置';

  @override
  String get mapResetNorth => '回到北方';

  @override
  String get typhoonLegendCircle15 => '七級風暴風圈';

  @override
  String get typhoonLegendCircleAvg => '平均圓';

  @override
  String get typhoonLegendCircle25 => '十級風暴風圈';

  @override
  String typhoonStormRadii(String ne, String se, String sw, String nw) {
    return '東北 $ne · 東南 $se · 西南 $sw · 西北 $nw km';
  }

  @override
  String typhoonTimeChip(String day, String hour) {
    return '$day日$hour時';
  }

  @override
  String get typhoonLegendProbability => '侵襲機率';

  @override
  String get typhoonLegendWarningAreas => '警報區域';

  @override
  String get typhoonOverlayMenuTooltip => '颱風圖層選項';

  @override
  String get typhoonOverlaySectionStorm => '暴風圈';

  @override
  String get typhoonOverlaySectionExtra => '覆蓋層';

  @override
  String get typhoonOverlayStormBandSubtitle => '含平均圓';

  @override
  String get typhoonOverlayProbabilityHint => '會隱藏預測圓錐';

  @override
  String get typhoonOverlayProbabilityTooltip => '顯示侵襲機率（會隱藏預測圓錐）';

  @override
  String get typhoonOverlayWarningTooltip => '標示警報區域縣市';

  @override
  String get typhoonOverlayStormL7Tooltip => '七級暴風圈＋平均圓（紫色）';

  @override
  String get typhoonOverlayStormL10Tooltip => '十級暴風圈＋平均圓（黃色）';

  @override
  String get typhoonOverlaySectionWeather => '天氣底圖';

  @override
  String get typhoonOverlayWeatherNone => '無';

  @override
  String get typhoonOverlayWeatherHint => '對齊報文時間';

  @override
  String get typhoonOverlayWeatherNoneTooltip => '不疊雷達或紅外線';

  @override
  String get typhoonOverlayWeatherRadarTooltip => '雷達回波（對齊颱風報文時間）';

  @override
  String get typhoonOverlayWeatherSatelliteTooltip => '紅外線（對齊颱風報文時間）';

  @override
  String get typhoonWarningTitle => '颱風警報';

  @override
  String typhoonWarningAreas(String areas) {
    return '警戒區域：$areas';
  }

  @override
  String get typhoonTrackDetail => '路徑詳情';

  @override
  String get typhoonHistoryTitle => '資料時間';

  @override
  String get typhoonHistoryLive => '即時';

  @override
  String get typhoonSatelliteTitle => '衛星雲圖';

  @override
  String get typhoonOverlayForecastCallouts => '預測點資訊';

  @override
  String get typhoonOverlayForecastCalloutsTooltip => '放大時顯示預測點詳細卡片';

  @override
  String get dpmFilterSectionRestroom => '場所類型';

  @override
  String get dpmFilterSectionRestroomType => '廁所類型';

  @override
  String get dpmFilterSectionShelter => '避難所災害類型';

  @override
  String get dpmDisasterFlood => '水災';

  @override
  String get dpmDisasterEarthquake => '震災';

  @override
  String get dpmDisasterLandslide => '土石流';

  @override
  String get dpmDisasterTsunami => '海嘯';

  @override
  String get dpmDisasterSlope => '坡地災害';

  @override
  String get dpmDisasterNuclear => '核子事故';

  @override
  String get skyTime => '天空時間';

  @override
  String get skyTimeAuto => '自動';

  @override
  String get skyTimeDawn => '黎明';

  @override
  String get skyTimeSunrise => '日出';

  @override
  String get skyTimeMorning => '上午';

  @override
  String get skyTimeNoon => '正午';

  @override
  String get skyTimeAfternoon => '下午';

  @override
  String get skyTimeGolden => '黃金時刻';

  @override
  String get skyTimeSunset => '日落';

  @override
  String get skyTimeDusk => '暮色';

  @override
  String get skyTimeNight => '夜晚';

  @override
  String get weatherModeCloudy => '多雲';

  @override
  String get weatherModeOvercast => '陰天';

  @override
  String get weatherModeSnow => '下雪';

  @override
  String get weatherModeSand => '沙塵';

  @override
  String get radarScanRange => '顯示掃描範圍';

  @override
  String get radarScanRangeSubtitle => '標示四座雷達實際觀測到的範圍。';

  @override
  String get radarScanRangeHint => '框外空白代表未觀測';

  @override
  String get radarOverlayMenuTooltip => '雷達圖層選項';

  @override
  String get radarCountyOutline => '縣市界線';

  @override
  String get radarCountyOutlineHint => '畫在回波之上';

  @override
  String get radarCountyOutlineSubtitle => '讓縣市界線在雷達回波下仍然清楚。';

  @override
  String get radarTownOutline => '鄉鎮界線';

  @override
  String get radarTownOutlineHint => '較細的分區';

  @override
  String get radarTownOutlineSubtitle => '讓鄉鎮界線在雷達回波下仍然清楚。';

  @override
  String get qpesumsOverlayMenuTooltip => '定量降水預報圖層選項';
}

/// The translations for Chinese, using the Han script (`zh_Hans`).
class AppLocalizationsZhHans extends AppLocalizationsZh {
  AppLocalizationsZhHans() : super('zh_Hans');

  @override
  String get languageName => '简体中文';

  @override
  String get navHome => '主页';

  @override
  String get navEvents => '事件';

  @override
  String get navMap => '地图';

  @override
  String get navData => '资料';

  @override
  String get navEarthquake => '地震';

  @override
  String get dataSectionSeismic => '地震';

  @override
  String get dataEarthquakeSubtitle => '地震报告';

  @override
  String get dataSectionWeather => '气象';

  @override
  String get dataWeatherRankingSubtitle => '即时观测排行';

  @override
  String get weatherRankingTitle => '观测排行';

  @override
  String weatherRankingMeta(String time, int count) {
    return '资料时间：$time\n共 $count 观测点';
  }

  @override
  String get weatherRankingEmpty => '目前没有可排序的观测';

  @override
  String get weatherRankingBy => '依';

  @override
  String get weatherRankingHighest => '最高';

  @override
  String get weatherRankingLowest => '最低';

  @override
  String get weatherRankingMergeTo => '合并至';

  @override
  String get weatherRankingMergeTown => '乡镇';

  @override
  String get weatherRankingMergeCounty => '县市';

  @override
  String get weatherRankingWind => '风速';

  @override
  String get weatherRankingGust => '阵风';

  @override
  String get weatherRankingTempExtremes => '温度极值';

  @override
  String get weatherRankingExtremeHigh => '今日最高';

  @override
  String get weatherRankingExtremeLow => '今日最低';

  @override
  String get weatherRankingExtremeRange => '日温差';

  @override
  String weatherRankingRecordedAt(String time) {
    return '记录于 $time';
  }

  @override
  String weatherRankingAnalysisCurrent(String value) {
    return '当下 $value°C';
  }

  @override
  String weatherRankingAnalysisHigh(String value) {
    return '最高 $value';
  }

  @override
  String weatherRankingAnalysisLow(String value) {
    return '最低 $value';
  }

  @override
  String weatherRankingAnalysisRange(String value) {
    return '温差 $value°C';
  }

  @override
  String get reportListEmpty => '当前没有地震报告';

  @override
  String get reportListEmptyFiltered => '没有符合条件的地震报告';

  @override
  String reportListMeta(String magnitude, String depth) {
    return 'M$magnitude · $depth 公里';
  }

  @override
  String reportListMagnitude(String magnitude) {
    return 'M$magnitude';
  }

  @override
  String get reportListDepthUnit => '公里';

  @override
  String get reportListLocalFelt => '小区域有感';

  @override
  String get reportListToday => '今天';

  @override
  String get reportListYesterday => '昨天';

  @override
  String reportListDayCount(int count) {
    return '$count';
  }

  @override
  String get reportListEnd => '已到最后一页';

  @override
  String get reportFilterTitle => '筛选';

  @override
  String get reportFilterSort => '排序方式';

  @override
  String get reportFilterSortTime => '时间';

  @override
  String get reportFilterSortIntensity => '震度';

  @override
  String get reportFilterSortMagnitude => '规模';

  @override
  String get reportFilterSortDepth => '深度';

  @override
  String get reportFilterOrderDesc => '降序';

  @override
  String get reportFilterOrderAsc => '升序';

  @override
  String get reportFilterIntensity => '震度';

  @override
  String get reportFilterIntensityInfoTitle => '震度新制与旧制';

  @override
  String get reportFilterIntensityInfoIntro =>
      '中央气象署自 2020 年 1 月 1 日（台北时间）起改用新制震度。';

  @override
  String get reportFilterIntensityInfoLegacyTitle => '旧制（2020 以前）';

  @override
  String get reportFilterIntensityInfoLegacyBody => '震度仅 0–7，没有 5弱／5强／6弱／6强。';

  @override
  String get reportFilterIntensityInfoModernTitle => '新制（2020 起）';

  @override
  String get reportFilterIntensityInfoModernBody =>
      '震度为 0–4、5弱、5强、6弱、6强、7。筛选滑杆依新制；列表中较早的地震会以旧制标示显示。';

  @override
  String get reportFilterMagnitude => '规模';

  @override
  String get reportFilterDepth => '深度';

  @override
  String reportFilterDepthKm(String depth) {
    return '$depth 公里';
  }

  @override
  String get reportFilterDate => '日期';

  @override
  String get reportFilterDatePick => '选择日期';

  @override
  String get reportFilterDateStartNote => '开始日：当日 00:00（台北时间）';

  @override
  String get reportFilterDateEndNote => '结束日：当日 24:00（台北时间）';

  @override
  String reportFilterRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String get reportFilterLocation => '地点';

  @override
  String get reportFilterLocationHint => '例如：花莲、东部海域';

  @override
  String get reportFilterAny => '不限';

  @override
  String get reportFilterApply => '应用';

  @override
  String get reportFilterReset => '重置';

  @override
  String get reportListSearch => '查询';

  @override
  String get reportDetailTitle => '地震报告';

  @override
  String reportDetailNumbered(String number) {
    return '编号 $number 显著有感地震';
  }

  @override
  String get reportDetailLocalFelt => '小区域有感地震';

  @override
  String get reportDetailInfo => '详细信息';

  @override
  String get reportDetailOriginTime => '发震时间';

  @override
  String get reportDetailEpicenter => '震中坐标';

  @override
  String get reportDetailMagnitude => '地震规模';

  @override
  String get reportDetailDepth => '震源深度';

  @override
  String get reportDetailAreaIntensity => '各地震度';

  @override
  String get reportDetailLocalIntensity => '所在地的震度';

  @override
  String get reportDetailLocalIntensityUnavailable => '没有震度信息';

  @override
  String get reportDetailSortByIntensity => '依震度排序';

  @override
  String get reportDetailSortByCounty => '依县市排序';

  @override
  String get reportDetailImage => '地震报告图';

  @override
  String get reportDetailImageUnavailable => '报告图尚未提供';

  @override
  String get reportDetailOpenReport => '报告页面';

  @override
  String get reportDetailReplay => '重播';

  @override
  String get navMore => '更多';

  @override
  String get appLogs => '应用日志';

  @override
  String get changelogTitle => '更新日志';

  @override
  String get changelogEmpty => '目前没有更新日志';

  @override
  String get changelogTypePrerelease => '公测';

  @override
  String get changelogTypeStable => '正式';

  @override
  String get changelogCurrentVersion => '当前版本';

  @override
  String get changelogVersionDetails => '版本信息';

  @override
  String get changelogBodyEmpty => '此版本没有说明。';

  @override
  String get mapPlaceholderDisabled => '地图（暂时禁用）';

  @override
  String get moreSectionRegion => '地区';

  @override
  String get moreSectionNotify => '通知';

  @override
  String get moreSectionDisplay => '显示';

  @override
  String get regionManageTitle => '常用地区';

  @override
  String get regionAddButton => '添加地区';

  @override
  String get regionEmpty => '尚未添加常用地区';

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
  String get regionEdit => '修改';

  @override
  String get moreSectionAdvanced => '高级';

  @override
  String get moreDeveloper => '调试信息';

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
  String get regionCurrentUnavailable => '无法获取所在地位置信息';

  @override
  String get weatherPrecipitation => '降水量';

  @override
  String get weatherHumidity => '湿度';

  @override
  String get homeForecastTitle => '24小时预报';

  @override
  String homeForecastHighLow(String high, String low) {
    return '高 $high° · 低 $low°';
  }

  @override
  String homeForecastPop(String pop) {
    return '$pop%';
  }

  @override
  String homeForecastFeelsLike(String temp) {
    return '体感 $temp°';
  }

  @override
  String homeForecastHumidity(String value) {
    return '湿度 $value%';
  }

  @override
  String homeForecastWind(String direction, String level) {
    return '$direction · $level 级';
  }

  @override
  String get homeForecastUnavailable => '选择乡镇后可查看预报';

  @override
  String get homeForecastEmpty => '目前没有预报数据';

  @override
  String get homeActiveEventsTitle => '生效中事件';

  @override
  String get homeActiveEventsEmpty => '目前没有生效中的事件';

  @override
  String get homeRainTrendTitle => '近 1 小时降水趋势';

  @override
  String homeRainTrendMinute(int minute) {
    return '$minute分';
  }

  @override
  String homeRainTrendUpdated(String time) {
    return '更新 $time';
  }

  @override
  String get homeRainTrendNoData => '无资料';

  @override
  String get homeRainTrendScattered => '可能会有零星降雨';

  @override
  String get homeRainTrendLightSustained => '未来 1 小时会有持续小雨';

  @override
  String homeRainTrendLightStopping(int minutes) {
    return '预计 $minutes 分钟后停止下小雨';
  }

  @override
  String get homeRainTrendHeavySustained => '未来 1 小时会有持续大雨';

  @override
  String homeRainTrendHeavyStopping(int minutes) {
    return '预计 $minutes 分钟后停止下大雨';
  }

  @override
  String get mapLayers => '图层';

  @override
  String get mapLayerOrderTitle => '调整图层顺序';

  @override
  String get mapLayerOrderReset => '恢复默认顺序';

  @override
  String get mapLayerRadar => '雷达合成回波图';

  @override
  String get mapLayerSatellite => 'ひまわり 红外线图';

  @override
  String get mapLayerQpesums => '未来 1 小时降水预报';

  @override
  String get mapLayerLightning => '闪电';

  @override
  String lightningLegendCg(int minutes) {
    return '对地 · $minutes 分钟内';
  }

  @override
  String lightningLegendCc(int minutes) {
    return '云间 · $minutes 分钟内';
  }

  @override
  String get mapTimelineNow => '现在';

  @override
  String get mapTimelineObserved => '观测';

  @override
  String get mapTimelineForecast => '预报';

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

  @override
  String get displaySettings => '显示设置';

  @override
  String get defaultMapLayerSettings => '地图默认图层';

  @override
  String get defaultMapLayerSubtitle => '打开地图标签页时显示此图层，底部导航栏图标与文字会一并更新。';

  @override
  String get mapNavRadar => '雷达';

  @override
  String get mapNavQpesums => '预报';

  @override
  String get mapNavSatellite => '卫星';

  @override
  String get mapNavLightning => '闪电';

  @override
  String get mapNavTyphoon => '台风';

  @override
  String get mapNavEarthquake => '地震';

  @override
  String get mapNavTemperature => '温度';

  @override
  String get mapNavHumidity => '湿度';

  @override
  String get mapNavPressure => '气压';

  @override
  String get mapNavWind => '风向';

  @override
  String get mapNavRain => '雨量';

  @override
  String get mapNavDisaster => '防灾';

  @override
  String get displayTheme => '主题';

  @override
  String get themeSystem => '跟随系统';

  @override
  String get themeLight => '浅色';

  @override
  String get themeDark => '深色';

  @override
  String get moreSectionAbout => '关于';

  @override
  String get termsOfService => '服务条款';

  @override
  String get faq => '常见问题';

  @override
  String get openSourceLicenses => '开源许可';

  @override
  String get sponsorTitle => '支持 DPIP';

  @override
  String get sponsorIntro =>
      'DPIP 致力于提供实时防灾信息，没有广告或其他盈利模式。您的支持能帮助我们维持服务器运行并持续开发。';

  @override
  String get sponsorSubscriptions => '订阅制';

  @override
  String get sponsorRecommended => '推荐';

  @override
  String get sponsorOneTime => '单次支持';

  @override
  String sponsorPerMonth(String price) {
    return '$price / 月';
  }

  @override
  String get sponsorRestore => '恢复购买';

  @override
  String get sponsorTerms => '使用条款';

  @override
  String get sponsorPrivacy => '隐私政策';

  @override
  String get sponsorRestoring => '正在恢复购买…';

  @override
  String get sponsorRestoreUnavailable => '无法连接到商店，请稍后再试';

  @override
  String get commonClose => '关闭';

  @override
  String get mapLayerTemperature => '温度';

  @override
  String get trendRange24h => '24 小时';

  @override
  String get trendRange7d => '7 天';

  @override
  String get trendNoData => '没有趋势数据';

  @override
  String trendCumulativeTotal(String total) {
    return '累计 $total mm';
  }

  @override
  String chartHourLabel(int hour) {
    return '$hour时';
  }

  @override
  String get mapLayerHumidity => '湿度';

  @override
  String get mapLayerPressure => '气压';

  @override
  String get mapLayerWind => '风向';

  @override
  String get mapLayerRain => '雨量';

  @override
  String get rainIntervalMenu => '累积时段';

  @override
  String get rainIntervalNow => '今日';

  @override
  String get rainInterval10m => '10 分';

  @override
  String get rainInterval1h => '1 时';

  @override
  String get rainInterval3h => '3 时';

  @override
  String get rainInterval6h => '6 时';

  @override
  String get rainInterval12h => '12 时';

  @override
  String get rainInterval24h => '24 时';

  @override
  String get rainInterval2d => '2 日';

  @override
  String get rainInterval3d => '3 日';

  @override
  String get mapLayerTyphoon => '台风';

  @override
  String get typhoonNoActive => '目前无台风';

  @override
  String get typhoonWind => '风速';

  @override
  String get typhoonGust => '阵风';

  @override
  String get typhoonPressure => '气压';

  @override
  String get typhoonMotion => '移动';

  @override
  String get typhoonLabelPosition => '中心位置';

  @override
  String get typhoonLabelDirection => '过去移动方向';

  @override
  String get typhoonLabelSpeed => '过去移动时速';

  @override
  String get typhoonLabelPressure => '中心气压';

  @override
  String get typhoonLabelWind => '近中心最大风速';

  @override
  String get typhoonLabelGust => '瞬间最大阵风';

  @override
  String get typhoonLabelGaleAvg => '七级风平均暴风半径';

  @override
  String get typhoonLabelStormAvg => '十级风平均暴风半径';

  @override
  String get typhoonLabelProbCircle => '70%概率圆';

  @override
  String typhoonForecastLead(String hours) {
    return '预测 +$hours 小时';
  }

  @override
  String get typhoonLabelNw => '西北侧';

  @override
  String get typhoonLabelNe => '东北侧';

  @override
  String get typhoonLabelSw => '西南侧';

  @override
  String get typhoonLabelSe => '东南侧';

  @override
  String typhoonValueLat(String lat) {
    return '北纬 $lat 度';
  }

  @override
  String typhoonValueLon(String lon) {
    return '东经 $lon 度';
  }

  @override
  String typhoonValueKm(String n) {
    return '$n 公里';
  }

  @override
  String typhoonValueHpa(String n) {
    return '$n 百帕';
  }

  @override
  String typhoonValueMs(String n) {
    return '每秒 $n 公尺';
  }

  @override
  String typhoonDataTime(String time) {
    return '资料时间\n$time';
  }

  @override
  String get mapLayerMonitor => '强震监视器';

  @override
  String get mapLayerDisasterMap => '防灾地图';

  @override
  String get mapLayerAed => 'AED';

  @override
  String get disasterMapOverlayMenuTooltip => '防灾地图图层';

  @override
  String get disasterMapOverlaySectionLayers => '图层';

  @override
  String get disasterMapOverlayAedTooltip => '显示 AED 位置';

  @override
  String get aedAddress => '地址';

  @override
  String get aedRegion => '县市区域';

  @override
  String get aedCategory => '场所分类';

  @override
  String get aedType => '场所类型';

  @override
  String get aedPlaceDesc => '放置位置说明';

  @override
  String get aedDescription => '备注';

  @override
  String get aedHoursWeekday => '平日开放时间';

  @override
  String get aedHoursSaturday => '周六开放时间';

  @override
  String get aedHoursSunday => '周日开放时间';

  @override
  String get aedOpenRemark => '开放时间备注';

  @override
  String get aedEmergencyPhone => '紧急联络电话';

  @override
  String get mapLayerRestroom => '公厕';

  @override
  String get mapLayerShelter => '避难收容场所';

  @override
  String get disasterMapOverlayRestroomTooltip => '显示公厕';

  @override
  String get disasterMapOverlayShelterTooltip => '显示避难收容场所';

  @override
  String get dpmOpenInMaps => '打开地图';

  @override
  String get mapAppGoogleMaps => 'Google Maps';

  @override
  String get mapAppAppleMaps => 'Apple Maps';

  @override
  String mapAppDefault(String app) {
    return '$app（默认）';
  }

  @override
  String get mapAppCopyCoordinates => '复制坐标';

  @override
  String get mapAppCoordinatesCopied => '已复制坐标';

  @override
  String get mapOverlaySectionReference => '参考图层';

  @override
  String get mapOverlaySectionMap => '地图';

  @override
  String get rainIntervalSection => '统计时间';

  @override
  String get mapTownLabels => '乡镇名称';

  @override
  String get mapTownLabelsHint => '放大时显示乡镇名称';

  @override
  String get dpmSheetEmpty => '点击地图上的标记查看详情';

  @override
  String get dpmAddress => '地址';

  @override
  String get restroomTypeLabel => '厕所类型';

  @override
  String get restroomCategoryLabel => '类别';

  @override
  String get restroomGradeLabel => '等级';

  @override
  String get restroomTypeFemale => '女厕所';

  @override
  String get restroomTypeMale => '男厕所';

  @override
  String get restroomTypeMixed => '混合厕所';

  @override
  String get restroomTypeAccessible => '无障碍厕所';

  @override
  String get restroomTypeGenderNeutral => '性别友善厕所';

  @override
  String get restroomTypeFamily => '亲子厕所';

  @override
  String get restroomTypeUnspecified => '未设定';

  @override
  String get restroomCategoryTransport => '交通';

  @override
  String get restroomCategoryPark => '公园';

  @override
  String get restroomCategoryCommercial => '商业营业场所';

  @override
  String get restroomCategoryReligious => '宗教礼仪场所';

  @override
  String get restroomCategoryCultural => '文化育乐活动场所';

  @override
  String get restroomCategoryGovernment => '民众洽公场所';

  @override
  String get restroomCategoryWelfare => '社福机构、集会场所';

  @override
  String get restroomCategoryTourist => '观光地区及风景区';

  @override
  String get restroomCategoryLeisure => '休闲娱乐场所';

  @override
  String get restroomCategoryOther => '其他';

  @override
  String get restroomGradeExcellent => '特优级';

  @override
  String get restroomGradeGood => '优等级';

  @override
  String get restroomGradeAverage => '普通级';

  @override
  String get restroomGradePoor => '不合格';

  @override
  String get shelterAddressLabel => '地址';

  @override
  String get shelterCapacityLabel => '收容人数';

  @override
  String shelterCapacityValue(int n) {
    return '$n 人';
  }

  @override
  String get shelterCategoryLabel => '适用灾害';

  @override
  String get shelterIndoorLabel => '室内收容';

  @override
  String get shelterOutdoorLabel => '室外收容';

  @override
  String get shelterVulnerableOkLabel => '适合避难弱者安置';

  @override
  String get dpmYes => '是';

  @override
  String get dpmNo => '否';

  @override
  String get stationSheetEmpty => '点选任一测站查看观测值';

  @override
  String monitorDelay(String value) {
    return '延迟 $value s';
  }

  @override
  String get monitorWaiting => '等待数据…';

  @override
  String mapLegendUnit(String unit) {
    return '单位：$unit';
  }

  @override
  String get typhoonLegendPast => '实际路径';

  @override
  String get typhoonIntensityTd => '热带性低气压';

  @override
  String typhoonPickerNamed(String no, String name) {
    return '$name TY $no';
  }

  @override
  String typhoonPickerTd(String no) {
    return '热带性低气压 TD $no';
  }

  @override
  String get typhoonIntensityMild => '轻度台风';

  @override
  String get typhoonIntensityModerate => '中度台风';

  @override
  String get typhoonIntensityIntense => '强烈台风';

  @override
  String get typhoonLegendForecast => '预测路径';

  @override
  String get typhoonLegendForecastPoint => '预测点';

  @override
  String get typhoonLegendCurrent => '目前中心';

  @override
  String get typhoonLegendCone => '预测圆锥';

  @override
  String get mapLegendExpand => '图例';

  @override
  String get mapLegendCollapse => '收起图例';

  @override
  String get mapMyLocation => '我的位置';

  @override
  String get mapResetNorth => '回到正北';

  @override
  String get typhoonLegendCircle15 => '七级风暴风圈';

  @override
  String get typhoonLegendCircleAvg => '平均圆';

  @override
  String get typhoonLegendCircle25 => '十级风暴风圈';

  @override
  String typhoonStormRadii(String ne, String se, String sw, String nw) {
    return 'NE $ne · SE $se · SW $sw · NW $nw km';
  }

  @override
  String typhoonTimeChip(String day, String hour) {
    return '$day日$hour時';
  }

  @override
  String get typhoonLegendProbability => '侵袭概率';

  @override
  String get typhoonLegendWarningAreas => '警报区域';

  @override
  String get typhoonOverlayMenuTooltip => '台风图层选项';

  @override
  String get typhoonOverlaySectionStorm => '暴风圈';

  @override
  String get typhoonOverlaySectionExtra => '叠加层';

  @override
  String get typhoonOverlayStormBandSubtitle => '含平均圆';

  @override
  String get typhoonOverlayProbabilityHint => '会隐藏预测圆锥';

  @override
  String get typhoonOverlayProbabilityTooltip => '显示侵袭概率（隐藏预测圆锥）';

  @override
  String get typhoonOverlayWarningTooltip => '标示发布台风警报的县市';

  @override
  String get typhoonOverlayStormL7Tooltip => '七级风风场 + 平均圆（紫）';

  @override
  String get typhoonOverlayStormL10Tooltip => '十级风风场 + 平均圆（黄）';

  @override
  String get typhoonOverlaySectionWeather => '天气底图';

  @override
  String get typhoonOverlayWeatherNone => '无';

  @override
  String get typhoonOverlayWeatherHint => '对齐报文时间';

  @override
  String get typhoonOverlayWeatherNoneTooltip => '不显示雷达或红外线底图';

  @override
  String get typhoonOverlayWeatherRadarTooltip => '最接近台风报文时间的雷达回波';

  @override
  String get typhoonOverlayWeatherSatelliteTooltip => '最接近台风报文时间的红外线';

  @override
  String get typhoonWarningTitle => '台风警报';

  @override
  String typhoonWarningAreas(String areas) {
    return '警戒区域：$areas';
  }

  @override
  String get typhoonTrackDetail => '路径详情';

  @override
  String get typhoonHistoryTitle => '资料时间';

  @override
  String get typhoonHistoryLive => '实时';

  @override
  String get typhoonSatelliteTitle => '卫星云图';

  @override
  String get typhoonOverlayForecastCallouts => '预测点信息';

  @override
  String get typhoonOverlayForecastCalloutsTooltip => '放大时显示预测点详细卡片';

  @override
  String get dpmFilterSectionRestroom => '场所类型';

  @override
  String get dpmFilterSectionRestroomType => '厕所类型';

  @override
  String get dpmFilterSectionShelter => '避难所灾害类型';

  @override
  String get dpmDisasterFlood => '水灾';

  @override
  String get dpmDisasterEarthquake => '震灾';

  @override
  String get dpmDisasterLandslide => '土石流';

  @override
  String get dpmDisasterTsunami => '海啸';

  @override
  String get dpmDisasterSlope => '坡地灾害';

  @override
  String get dpmDisasterNuclear => '核子事故';

  @override
  String get skyTime => '天空时间';

  @override
  String get skyTimeAuto => '自动';

  @override
  String get skyTimeDawn => '黎明';

  @override
  String get skyTimeSunrise => '日出';

  @override
  String get skyTimeMorning => '上午';

  @override
  String get skyTimeNoon => '正午';

  @override
  String get skyTimeAfternoon => '下午';

  @override
  String get skyTimeGolden => '黄金时刻';

  @override
  String get skyTimeSunset => '日落';

  @override
  String get skyTimeDusk => '暮色';

  @override
  String get skyTimeNight => '夜晚';

  @override
  String get weatherModeCloudy => '多云';

  @override
  String get weatherModeOvercast => '阴天';

  @override
  String get weatherModeSnow => '下雪';

  @override
  String get weatherModeSand => '沙尘';

  @override
  String get radarScanRange => '显示扫描范围';

  @override
  String get radarScanRangeSubtitle => '标示四座雷达实际观测到的范围。';

  @override
  String get radarScanRangeHint => '框外空白代表未观测';

  @override
  String get radarOverlayMenuTooltip => '雷达图层选项';

  @override
  String get radarCountyOutline => '县市界线';

  @override
  String get radarCountyOutlineHint => '画在回波之上';

  @override
  String get radarCountyOutlineSubtitle => '让县市界线在雷达回波下仍然清楚。';

  @override
  String get radarTownOutline => '乡镇界线';

  @override
  String get radarTownOutlineHint => '较细的分区';

  @override
  String get radarTownOutlineSubtitle => '让乡镇界线在雷达回波下仍然清楚。';

  @override
  String get qpesumsOverlayMenuTooltip => '定量降水预报图层选项';
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
  String get navData => '資料';

  @override
  String get navEarthquake => '地震';

  @override
  String get dataSectionSeismic => '地震';

  @override
  String get dataEarthquakeSubtitle => '地震報告';

  @override
  String get dataSectionWeather => '氣象';

  @override
  String get dataWeatherRankingSubtitle => '即時觀測排行';

  @override
  String get weatherRankingTitle => '觀測排行';

  @override
  String weatherRankingMeta(String time, int count) {
    return '資料時間：$time\n共 $count 觀測點';
  }

  @override
  String get weatherRankingEmpty => '目前沒有可排序的觀測';

  @override
  String get weatherRankingBy => '依';

  @override
  String get weatherRankingHighest => '最高';

  @override
  String get weatherRankingLowest => '最低';

  @override
  String get weatherRankingMergeTo => '合併至';

  @override
  String get weatherRankingMergeTown => '鄉鎮';

  @override
  String get weatherRankingMergeCounty => '縣市';

  @override
  String get weatherRankingWind => '風速';

  @override
  String get weatherRankingGust => '陣風';

  @override
  String get weatherRankingTempExtremes => '溫度極值';

  @override
  String get weatherRankingExtremeHigh => '今日最高';

  @override
  String get weatherRankingExtremeLow => '今日最低';

  @override
  String get weatherRankingExtremeRange => '日溫差';

  @override
  String weatherRankingRecordedAt(String time) {
    return '記錄於 $time';
  }

  @override
  String weatherRankingAnalysisCurrent(String value) {
    return '當下 $value°C';
  }

  @override
  String weatherRankingAnalysisHigh(String value) {
    return '最高 $value';
  }

  @override
  String weatherRankingAnalysisLow(String value) {
    return '最低 $value';
  }

  @override
  String weatherRankingAnalysisRange(String value) {
    return '溫差 $value°C';
  }

  @override
  String get reportListEmpty => '目前沒有地震報告';

  @override
  String get reportListEmptyFiltered => '沒有符合條件的地震報告';

  @override
  String reportListMeta(String magnitude, String depth) {
    return 'M$magnitude · $depth 公里';
  }

  @override
  String reportListMagnitude(String magnitude) {
    return 'M$magnitude';
  }

  @override
  String get reportListDepthUnit => '公里';

  @override
  String get reportListLocalFelt => '小區域有感';

  @override
  String get reportListToday => '今天';

  @override
  String get reportListYesterday => '昨天';

  @override
  String reportListDayCount(int count) {
    return '$count';
  }

  @override
  String get reportListEnd => '已到最後一頁';

  @override
  String get reportFilterTitle => '篩選';

  @override
  String get reportFilterSort => '排序方式';

  @override
  String get reportFilterSortTime => '時間';

  @override
  String get reportFilterSortIntensity => '震度';

  @override
  String get reportFilterSortMagnitude => '規模';

  @override
  String get reportFilterSortDepth => '深度';

  @override
  String get reportFilterOrderDesc => '降序';

  @override
  String get reportFilterOrderAsc => '升序';

  @override
  String get reportFilterIntensity => '震度';

  @override
  String get reportFilterIntensityInfoTitle => '震度新制與舊制';

  @override
  String get reportFilterIntensityInfoIntro =>
      '中央氣象署自 2020 年 1 月 1 日（臺北時間）起改用新制震度。';

  @override
  String get reportFilterIntensityInfoLegacyTitle => '舊制（2020 以前）';

  @override
  String get reportFilterIntensityInfoLegacyBody => '震度僅 0–7，沒有 5弱／5強／6弱／6強。';

  @override
  String get reportFilterIntensityInfoModernTitle => '新制（2020 起）';

  @override
  String get reportFilterIntensityInfoModernBody =>
      '震度為 0–4、5弱、5強、6弱、6強、7。篩選滑桿依新制；列表中較早的地震會以舊制標示顯示。';

  @override
  String get reportFilterMagnitude => '規模';

  @override
  String get reportFilterDepth => '深度';

  @override
  String reportFilterDepthKm(String depth) {
    return '$depth 公里';
  }

  @override
  String get reportFilterDate => '日期';

  @override
  String get reportFilterDatePick => '選擇日期';

  @override
  String get reportFilterDateStartNote => '開始日：當日 00:00（台北時間）';

  @override
  String get reportFilterDateEndNote => '結束日：當日 24:00（台北時間）';

  @override
  String reportFilterRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String get reportFilterLocation => '地點';

  @override
  String get reportFilterLocationHint => '例如：花蓮、東部海域';

  @override
  String get reportFilterAny => '不限';

  @override
  String get reportFilterApply => '套用';

  @override
  String get reportFilterReset => '重設';

  @override
  String get reportListSearch => '查詢';

  @override
  String get reportDetailTitle => '地震報告';

  @override
  String reportDetailNumbered(String number) {
    return '編號 $number 顯著有感地震';
  }

  @override
  String get reportDetailLocalFelt => '小區域有感地震';

  @override
  String get reportDetailInfo => '詳細資訊';

  @override
  String get reportDetailOriginTime => '發震時間';

  @override
  String get reportDetailEpicenter => '震央座標';

  @override
  String get reportDetailMagnitude => '地震規模';

  @override
  String get reportDetailDepth => '震源深度';

  @override
  String get reportDetailAreaIntensity => '各地震度';

  @override
  String get reportDetailLocalIntensity => '所在地的震度';

  @override
  String get reportDetailLocalIntensityUnavailable => '沒有震度訊息';

  @override
  String get reportDetailSortByIntensity => '依震度排序';

  @override
  String get reportDetailSortByCounty => '依縣市排序';

  @override
  String get reportDetailImage => '地震報告圖';

  @override
  String get reportDetailImageUnavailable => '報告圖尚未提供';

  @override
  String get reportDetailOpenReport => '報告頁面';

  @override
  String get reportDetailReplay => '重播';

  @override
  String get navMore => '更多';

  @override
  String get appLogs => 'App 日誌';

  @override
  String get changelogTitle => '更新日誌';

  @override
  String get changelogEmpty => '目前沒有更新日誌';

  @override
  String get changelogTypePrerelease => '公測';

  @override
  String get changelogTypeStable => '正式';

  @override
  String get changelogCurrentVersion => '目前版本';

  @override
  String get changelogVersionDetails => '版本資訊';

  @override
  String get changelogBodyEmpty => '此版本沒有說明。';

  @override
  String get mapPlaceholderDisabled => '地圖(暫時停用)';

  @override
  String get moreSectionRegion => '地區';

  @override
  String get moreSectionNotify => '通知';

  @override
  String get moreSectionDisplay => '顯示';

  @override
  String get regionManageTitle => '常用地區';

  @override
  String get regionAddButton => '新增地區';

  @override
  String get regionEmpty => '尚未新增常用地區';

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
  String get regionEdit => '修改';

  @override
  String get moreSectionAdvanced => '進階';

  @override
  String get moreDeveloper => '偵錯資訊';

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
  String get regionCurrentUnavailable => '無法取得所在地位置資訊';

  @override
  String get weatherPrecipitation => '降水量';

  @override
  String get weatherHumidity => '濕度';

  @override
  String get homeForecastTitle => '24小時預報';

  @override
  String homeForecastHighLow(String high, String low) {
    return '高 $high° · 低 $low°';
  }

  @override
  String homeForecastPop(String pop) {
    return '$pop%';
  }

  @override
  String homeForecastFeelsLike(String temp) {
    return '體感 $temp°';
  }

  @override
  String homeForecastHumidity(String value) {
    return '濕度 $value%';
  }

  @override
  String homeForecastWind(String direction, String level) {
    return '$direction · $level 級';
  }

  @override
  String get homeForecastUnavailable => '選擇地區後可查看預報';

  @override
  String get homeForecastEmpty => '目前沒有預報資料';

  @override
  String get homeActiveEventsTitle => '生效中事件';

  @override
  String get homeActiveEventsEmpty => '目前沒有生效中的事件';

  @override
  String get homeRainTrendTitle => '近 1 小時降水趨勢';

  @override
  String homeRainTrendMinute(int minute) {
    return '$minute分';
  }

  @override
  String homeRainTrendUpdated(String time) {
    return '更新 $time';
  }

  @override
  String get homeRainTrendNoData => '無資料';

  @override
  String get homeRainTrendScattered => '可能會有零星降雨';

  @override
  String get homeRainTrendLightSustained => '未來 1 小時會有持續小雨';

  @override
  String homeRainTrendLightStopping(int minutes) {
    return '預計 $minutes 分鐘後停止下小雨';
  }

  @override
  String get homeRainTrendHeavySustained => '未來 1 小時會有持續大雨';

  @override
  String homeRainTrendHeavyStopping(int minutes) {
    return '預計 $minutes 分鐘後停止下大雨';
  }

  @override
  String get mapLayers => '圖層';

  @override
  String get mapLayerOrderTitle => '調整圖層順序';

  @override
  String get mapLayerOrderReset => '回復預設順序';

  @override
  String get mapLayerRadar => '雷達合成回波圖';

  @override
  String get mapLayerSatellite => 'ひまわり 紅外線圖';

  @override
  String get mapLayerQpesums => '未來 1 小時降水預報';

  @override
  String get mapLayerLightning => '閃電';

  @override
  String lightningLegendCg(int minutes) {
    return '對地 · $minutes 分內';
  }

  @override
  String lightningLegendCc(int minutes) {
    return '雲間 · $minutes 分內';
  }

  @override
  String get mapTimelineNow => '現在';

  @override
  String get mapTimelineObserved => '觀測';

  @override
  String get mapTimelineForecast => '預報';

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

  @override
  String get displaySettings => '顯示設定';

  @override
  String get defaultMapLayerSettings => '地圖預設圖層';

  @override
  String get defaultMapLayerSubtitle => '開啟地圖分頁時顯示此圖層，底部導覽列圖示與文字會一併更新。';

  @override
  String get mapNavRadar => '雷達';

  @override
  String get mapNavQpesums => '預報';

  @override
  String get mapNavSatellite => '衛星';

  @override
  String get mapNavLightning => '閃電';

  @override
  String get mapNavTyphoon => '颱風';

  @override
  String get mapNavEarthquake => '地震';

  @override
  String get mapNavTemperature => '溫度';

  @override
  String get mapNavHumidity => '濕度';

  @override
  String get mapNavPressure => '氣壓';

  @override
  String get mapNavWind => '風向';

  @override
  String get mapNavRain => '雨量';

  @override
  String get mapNavDisaster => '防災';

  @override
  String get displayTheme => '主題';

  @override
  String get themeSystem => '跟隨系統';

  @override
  String get themeLight => '淺色';

  @override
  String get themeDark => '深色';

  @override
  String get moreSectionAbout => '關於';

  @override
  String get termsOfService => '服務條款';

  @override
  String get faq => '常見問題';

  @override
  String get openSourceLicenses => '引用套件';

  @override
  String get sponsorTitle => '支持 DPIP';

  @override
  String get sponsorIntro =>
      'DPIP 致力於提供即時防災資訊，沒有廣告或其他營利模式。您的支持能幫助我們維持伺服器運作並持續開發。';

  @override
  String get sponsorSubscriptions => '訂閱制';

  @override
  String get sponsorRecommended => '推薦';

  @override
  String get sponsorOneTime => '單次支援';

  @override
  String sponsorPerMonth(String price) {
    return '$price / 月';
  }

  @override
  String get sponsorRestore => '恢復購買';

  @override
  String get sponsorTerms => '使用條款';

  @override
  String get sponsorPrivacy => '私隱權政策';

  @override
  String get sponsorRestoring => '正在恢復購買…';

  @override
  String get sponsorRestoreUnavailable => '無法連線至商店，請稍後再試';

  @override
  String get commonClose => '關閉';

  @override
  String get mapLayerTemperature => '溫度';

  @override
  String get trendRange24h => '24 小時';

  @override
  String get trendRange7d => '7 天';

  @override
  String get trendNoData => '沒有趨勢資料';

  @override
  String trendCumulativeTotal(String total) {
    return '累計 $total mm';
  }

  @override
  String chartHourLabel(int hour) {
    return '$hour時';
  }

  @override
  String get mapLayerHumidity => '濕度';

  @override
  String get mapLayerPressure => '氣壓';

  @override
  String get mapLayerWind => '風向';

  @override
  String get mapLayerRain => '雨量';

  @override
  String get rainIntervalMenu => '累積時段';

  @override
  String get rainIntervalNow => '今日';

  @override
  String get rainInterval10m => '10 分';

  @override
  String get rainInterval1h => '1 時';

  @override
  String get rainInterval3h => '3 時';

  @override
  String get rainInterval6h => '6 時';

  @override
  String get rainInterval12h => '12 時';

  @override
  String get rainInterval24h => '24 時';

  @override
  String get rainInterval2d => '2 日';

  @override
  String get rainInterval3d => '3 日';

  @override
  String get mapLayerTyphoon => '颱風';

  @override
  String get typhoonNoActive => '目前無颱風';

  @override
  String get typhoonWind => '風速';

  @override
  String get typhoonGust => '陣風';

  @override
  String get typhoonPressure => '氣壓';

  @override
  String get typhoonMotion => '移動';

  @override
  String get typhoonLabelPosition => '中心位置';

  @override
  String get typhoonLabelDirection => '過去移動方向';

  @override
  String get typhoonLabelSpeed => '過去移動時速';

  @override
  String get typhoonLabelPressure => '中心氣壓';

  @override
  String get typhoonLabelWind => '近中心最大風速';

  @override
  String get typhoonLabelGust => '瞬間最大陣風';

  @override
  String get typhoonLabelGaleAvg => '七級風平均暴風半徑';

  @override
  String get typhoonLabelStormAvg => '十級風平均暴風半徑';

  @override
  String get typhoonLabelProbCircle => '70%機率圓';

  @override
  String typhoonForecastLead(String hours) {
    return '預測 +$hours 小時';
  }

  @override
  String get typhoonLabelNw => '西北側';

  @override
  String get typhoonLabelNe => '東北側';

  @override
  String get typhoonLabelSw => '西南側';

  @override
  String get typhoonLabelSe => '東南側';

  @override
  String typhoonValueLat(String lat) {
    return '北緯 $lat 度';
  }

  @override
  String typhoonValueLon(String lon) {
    return '東經 $lon 度';
  }

  @override
  String typhoonValueKm(String n) {
    return '$n 公里';
  }

  @override
  String typhoonValueHpa(String n) {
    return '$n 百帕';
  }

  @override
  String typhoonValueMs(String n) {
    return '每秒 $n 公尺';
  }

  @override
  String typhoonDataTime(String time) {
    return '資料時間\n$time';
  }

  @override
  String get mapLayerMonitor => '強震監視器';

  @override
  String get mapLayerDisasterMap => '防災地圖';

  @override
  String get mapLayerAed => 'AED';

  @override
  String get disasterMapOverlayMenuTooltip => '防災地圖圖層';

  @override
  String get disasterMapOverlaySectionLayers => '圖層';

  @override
  String get disasterMapOverlayAedTooltip => '顯示 AED 位置';

  @override
  String get aedAddress => '地址';

  @override
  String get aedRegion => '縣市區域';

  @override
  String get aedCategory => '場所分類';

  @override
  String get aedType => '場所類型';

  @override
  String get aedPlaceDesc => '放置位置說明';

  @override
  String get aedDescription => '備註';

  @override
  String get aedHoursWeekday => '平日開放時間';

  @override
  String get aedHoursSaturday => '週六開放時間';

  @override
  String get aedHoursSunday => '週日開放時間';

  @override
  String get aedOpenRemark => '開放時間備註';

  @override
  String get aedEmergencyPhone => '緊急聯絡電話';

  @override
  String get mapLayerRestroom => '公廁';

  @override
  String get mapLayerShelter => '避難收容場所';

  @override
  String get disasterMapOverlayRestroomTooltip => '顯示公廁';

  @override
  String get disasterMapOverlayShelterTooltip => '顯示避難收容場所';

  @override
  String get dpmOpenInMaps => '開啟地圖';

  @override
  String get mapAppGoogleMaps => 'Google Maps';

  @override
  String get mapAppAppleMaps => 'Apple Maps';

  @override
  String mapAppDefault(String app) {
    return '$app（預設）';
  }

  @override
  String get mapAppCopyCoordinates => '複製座標';

  @override
  String get mapAppCoordinatesCopied => '已複製座標';

  @override
  String get mapOverlaySectionReference => '參考圖層';

  @override
  String get mapOverlaySectionMap => '地圖';

  @override
  String get rainIntervalSection => '統計時間';

  @override
  String get mapTownLabels => '鄉鎮名稱';

  @override
  String get mapTownLabelsHint => '放大時顯示鄉鎮名稱';

  @override
  String get dpmSheetEmpty => '點選地圖上的標記查看詳情';

  @override
  String get dpmAddress => '地址';

  @override
  String get restroomTypeLabel => '廁所類型';

  @override
  String get restroomCategoryLabel => '類別';

  @override
  String get restroomGradeLabel => '等級';

  @override
  String get restroomTypeFemale => '女廁所';

  @override
  String get restroomTypeMale => '男廁所';

  @override
  String get restroomTypeMixed => '混合廁所';

  @override
  String get restroomTypeAccessible => '無障礙廁所';

  @override
  String get restroomTypeGenderNeutral => '性別友善廁所';

  @override
  String get restroomTypeFamily => '親子廁所';

  @override
  String get restroomTypeUnspecified => '未設定';

  @override
  String get restroomCategoryTransport => '交通';

  @override
  String get restroomCategoryPark => '公園';

  @override
  String get restroomCategoryCommercial => '商業營業場所';

  @override
  String get restroomCategoryReligious => '宗教禮儀場所';

  @override
  String get restroomCategoryCultural => '文化育樂活動場所';

  @override
  String get restroomCategoryGovernment => '民眾洽公場所';

  @override
  String get restroomCategoryWelfare => '社福機構、集會場所';

  @override
  String get restroomCategoryTourist => '觀光地區及風景區';

  @override
  String get restroomCategoryLeisure => '休閒娛樂場所';

  @override
  String get restroomCategoryOther => '其他';

  @override
  String get restroomGradeExcellent => '特優級';

  @override
  String get restroomGradeGood => '優等級';

  @override
  String get restroomGradeAverage => '普通級';

  @override
  String get restroomGradePoor => '不合格';

  @override
  String get shelterAddressLabel => '地址';

  @override
  String get shelterCapacityLabel => '收容人數';

  @override
  String shelterCapacityValue(int n) {
    return '$n 人';
  }

  @override
  String get shelterCategoryLabel => '適用災害';

  @override
  String get shelterIndoorLabel => '室內收容';

  @override
  String get shelterOutdoorLabel => '室外收容';

  @override
  String get shelterVulnerableOkLabel => '適合避難弱者安置';

  @override
  String get dpmYes => '是';

  @override
  String get dpmNo => '否';

  @override
  String get stationSheetEmpty => '點選任一測站查看觀測值';

  @override
  String monitorDelay(String value) {
    return '延遲 $value s';
  }

  @override
  String get monitorWaiting => '等待資料…';

  @override
  String mapLegendUnit(String unit) {
    return '單位：$unit';
  }

  @override
  String get typhoonLegendPast => '實際路徑';

  @override
  String get typhoonIntensityTd => '熱帶性低氣壓';

  @override
  String typhoonPickerNamed(String no, String name) {
    return '$name TY $no';
  }

  @override
  String typhoonPickerTd(String no) {
    return '熱帶性低氣壓 TD $no';
  }

  @override
  String get typhoonIntensityMild => '輕度颱風';

  @override
  String get typhoonIntensityModerate => '中度颱風';

  @override
  String get typhoonIntensityIntense => '強烈颱風';

  @override
  String get typhoonLegendForecast => '預測路徑';

  @override
  String get typhoonLegendForecastPoint => '預測點';

  @override
  String get typhoonLegendCurrent => '目前中心';

  @override
  String get typhoonLegendCone => '預測圓錐';

  @override
  String get mapLegendExpand => '圖例';

  @override
  String get mapLegendCollapse => '收合圖例';

  @override
  String get mapMyLocation => '我的位置';

  @override
  String get mapResetNorth => '回到北方';

  @override
  String get typhoonLegendCircle15 => '七級風暴風圈';

  @override
  String get typhoonLegendCircleAvg => '平均圓';

  @override
  String get typhoonLegendCircle25 => '十級風暴風圈';

  @override
  String typhoonStormRadii(String ne, String se, String sw, String nw) {
    return '東北 $ne · 東南 $se · 西南 $sw · 西北 $nw km';
  }

  @override
  String typhoonTimeChip(String day, String hour) {
    return '$day日$hour時';
  }

  @override
  String get typhoonLegendProbability => '侵襲機率';

  @override
  String get typhoonLegendWarningAreas => '警報區域';

  @override
  String get typhoonOverlayMenuTooltip => '颱風圖層選項';

  @override
  String get typhoonOverlaySectionStorm => '暴風圈';

  @override
  String get typhoonOverlaySectionExtra => '覆蓋層';

  @override
  String get typhoonOverlayStormBandSubtitle => '含平均圓';

  @override
  String get typhoonOverlayProbabilityHint => '會隱藏預測圓錐';

  @override
  String get typhoonOverlayProbabilityTooltip => '顯示侵襲機率（會隱藏預測圓錐）';

  @override
  String get typhoonOverlayWarningTooltip => '標示警報區域縣市';

  @override
  String get typhoonOverlayStormL7Tooltip => '七級暴風圈＋平均圓（紫色）';

  @override
  String get typhoonOverlayStormL10Tooltip => '十級暴風圈＋平均圓（黃色）';

  @override
  String get typhoonOverlaySectionWeather => '天氣底圖';

  @override
  String get typhoonOverlayWeatherNone => '無';

  @override
  String get typhoonOverlayWeatherHint => '對齊報文時間';

  @override
  String get typhoonOverlayWeatherNoneTooltip => '不疊雷達或紅外線';

  @override
  String get typhoonOverlayWeatherRadarTooltip => '雷達回波（對齊颱風報文時間）';

  @override
  String get typhoonOverlayWeatherSatelliteTooltip => '紅外線（對齊颱風報文時間）';

  @override
  String get typhoonWarningTitle => '颱風警報';

  @override
  String typhoonWarningAreas(String areas) {
    return '警戒區域：$areas';
  }

  @override
  String get typhoonTrackDetail => '路徑詳情';

  @override
  String get typhoonHistoryTitle => '資料時間';

  @override
  String get typhoonHistoryLive => '即時';

  @override
  String get typhoonSatelliteTitle => '衛星雲圖';

  @override
  String get typhoonOverlayForecastCallouts => '預測點資訊';

  @override
  String get typhoonOverlayForecastCalloutsTooltip => '放大時顯示預測點詳細卡片';

  @override
  String get dpmFilterSectionRestroom => '場所類型';

  @override
  String get dpmFilterSectionRestroomType => '廁所類型';

  @override
  String get dpmFilterSectionShelter => '避難所災害類型';

  @override
  String get dpmDisasterFlood => '水災';

  @override
  String get dpmDisasterEarthquake => '震災';

  @override
  String get dpmDisasterLandslide => '土石流';

  @override
  String get dpmDisasterTsunami => '海嘯';

  @override
  String get dpmDisasterSlope => '坡地災害';

  @override
  String get dpmDisasterNuclear => '核子事故';

  @override
  String get skyTime => '天空時間';

  @override
  String get skyTimeAuto => '自動';

  @override
  String get skyTimeDawn => '黎明';

  @override
  String get skyTimeSunrise => '日出';

  @override
  String get skyTimeMorning => '上午';

  @override
  String get skyTimeNoon => '正午';

  @override
  String get skyTimeAfternoon => '下午';

  @override
  String get skyTimeGolden => '黃金時刻';

  @override
  String get skyTimeSunset => '日落';

  @override
  String get skyTimeDusk => '暮色';

  @override
  String get skyTimeNight => '夜晚';

  @override
  String get weatherModeCloudy => '多雲';

  @override
  String get weatherModeOvercast => '陰天';

  @override
  String get weatherModeSnow => '下雪';

  @override
  String get weatherModeSand => '沙塵';

  @override
  String get radarScanRange => '顯示掃描範圍';

  @override
  String get radarScanRangeSubtitle => '標示四座雷達實際觀測到的範圍。';

  @override
  String get radarScanRangeHint => '框外空白代表未觀測';

  @override
  String get radarOverlayMenuTooltip => '雷達圖層選項';

  @override
  String get radarCountyOutline => '縣市界線';

  @override
  String get radarCountyOutlineHint => '畫在回波之上';

  @override
  String get radarCountyOutlineSubtitle => '讓縣市界線在雷達回波下仍然清楚。';

  @override
  String get radarTownOutline => '鄉鎮界線';

  @override
  String get radarTownOutlineHint => '較細的分區';

  @override
  String get radarTownOutlineSubtitle => '讓鄉鎮界線在雷達回波下仍然清楚。';

  @override
  String get qpesumsOverlayMenuTooltip => '定量降水預報圖層選項';
}

/// The translations for Chinese, as used in Taiwan (`zh_TW`).
class AppLocalizationsZhTw extends AppLocalizationsZh {
  AppLocalizationsZhTw() : super('zh_TW');

  @override
  String get languageName => '繁體中文(臺灣)';

  @override
  String get navHome => '首頁';

  @override
  String get navEvents => '事件';

  @override
  String get navMap => '地圖';

  @override
  String get navData => '資料';

  @override
  String get navEarthquake => '地震';

  @override
  String get dataSectionSeismic => '地震';

  @override
  String get dataEarthquakeSubtitle => '地震報告';

  @override
  String get dataSectionWeather => '氣象';

  @override
  String get dataWeatherRankingSubtitle => '即時觀測排行';

  @override
  String get weatherRankingTitle => '觀測排行';

  @override
  String weatherRankingMeta(String time, int count) {
    return '資料時間：$time\n共 $count 觀測點';
  }

  @override
  String get weatherRankingEmpty => '目前沒有可排序的觀測';

  @override
  String get weatherRankingBy => '依';

  @override
  String get weatherRankingHighest => '最高';

  @override
  String get weatherRankingLowest => '最低';

  @override
  String get weatherRankingMergeTo => '合併至';

  @override
  String get weatherRankingMergeTown => '鄉鎮';

  @override
  String get weatherRankingMergeCounty => '縣市';

  @override
  String get weatherRankingWind => '風速';

  @override
  String get weatherRankingGust => '陣風';

  @override
  String get weatherRankingTempExtremes => '溫度極值';

  @override
  String get weatherRankingExtremeHigh => '今日最高';

  @override
  String get weatherRankingExtremeLow => '今日最低';

  @override
  String get weatherRankingExtremeRange => '日溫差';

  @override
  String weatherRankingRecordedAt(String time) {
    return '記錄於 $time';
  }

  @override
  String weatherRankingAnalysisCurrent(String value) {
    return '當下 $value°C';
  }

  @override
  String weatherRankingAnalysisHigh(String value) {
    return '最高 $value';
  }

  @override
  String weatherRankingAnalysisLow(String value) {
    return '最低 $value';
  }

  @override
  String weatherRankingAnalysisRange(String value) {
    return '溫差 $value°C';
  }

  @override
  String get reportListEmpty => '目前沒有地震報告';

  @override
  String get reportListEmptyFiltered => '沒有符合條件的地震報告';

  @override
  String reportListMeta(String magnitude, String depth) {
    return 'M$magnitude · $depth 公里';
  }

  @override
  String reportListMagnitude(String magnitude) {
    return 'M$magnitude';
  }

  @override
  String get reportListDepthUnit => '公里';

  @override
  String get reportListLocalFelt => '小區域有感';

  @override
  String get reportListToday => '今天';

  @override
  String get reportListYesterday => '昨天';

  @override
  String reportListDayCount(int count) {
    return '$count';
  }

  @override
  String get reportListEnd => '已到最後一頁';

  @override
  String get reportFilterTitle => '篩選';

  @override
  String get reportFilterSort => '排序方式';

  @override
  String get reportFilterSortTime => '時間';

  @override
  String get reportFilterSortIntensity => '震度';

  @override
  String get reportFilterSortMagnitude => '規模';

  @override
  String get reportFilterSortDepth => '深度';

  @override
  String get reportFilterOrderDesc => '降序';

  @override
  String get reportFilterOrderAsc => '升序';

  @override
  String get reportFilterIntensity => '震度';

  @override
  String get reportFilterIntensityInfoTitle => '震度新制與舊制';

  @override
  String get reportFilterIntensityInfoIntro =>
      '中央氣象署自 2020 年 1 月 1 日（臺北時間）起改用新制震度。';

  @override
  String get reportFilterIntensityInfoLegacyTitle => '舊制（2020 以前）';

  @override
  String get reportFilterIntensityInfoLegacyBody => '震度僅 0–7，沒有 5弱／5強／6弱／6強。';

  @override
  String get reportFilterIntensityInfoModernTitle => '新制（2020 起）';

  @override
  String get reportFilterIntensityInfoModernBody =>
      '震度為 0–4、5弱、5強、6弱、6強、7。篩選滑桿依新制；列表中較早的地震會以舊制標示顯示。';

  @override
  String get reportFilterMagnitude => '規模';

  @override
  String get reportFilterDepth => '深度';

  @override
  String reportFilterDepthKm(String depth) {
    return '$depth 公里';
  }

  @override
  String get reportFilterDate => '日期';

  @override
  String get reportFilterDatePick => '選擇日期';

  @override
  String get reportFilterDateStartNote => '開始日：當日 00:00（臺北時間）';

  @override
  String get reportFilterDateEndNote => '結束日：當日 24:00（臺北時間）';

  @override
  String reportFilterRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String get reportFilterLocation => '地點';

  @override
  String get reportFilterLocationHint => '例如：花蓮、東部海域';

  @override
  String get reportFilterAny => '不限';

  @override
  String get reportFilterApply => '套用';

  @override
  String get reportFilterReset => '重設';

  @override
  String get reportListSearch => '查詢';

  @override
  String get reportDetailTitle => '地震報告';

  @override
  String reportDetailNumbered(String number) {
    return '編號 $number 顯著有感地震';
  }

  @override
  String get reportDetailLocalFelt => '小區域有感地震';

  @override
  String get reportDetailInfo => '詳細資訊';

  @override
  String get reportDetailOriginTime => '發震時間';

  @override
  String get reportDetailEpicenter => '震央座標';

  @override
  String get reportDetailMagnitude => '地震規模';

  @override
  String get reportDetailDepth => '震源深度';

  @override
  String get reportDetailAreaIntensity => '各地震度';

  @override
  String get reportDetailLocalIntensity => '所在地的震度';

  @override
  String get reportDetailLocalIntensityUnavailable => '沒有震度訊息';

  @override
  String get reportDetailSortByIntensity => '依震度排序';

  @override
  String get reportDetailSortByCounty => '依縣市排序';

  @override
  String get reportDetailImage => '地震報告圖';

  @override
  String get reportDetailImageUnavailable => '報告圖尚未提供';

  @override
  String get reportDetailOpenReport => '報告頁面';

  @override
  String get reportDetailReplay => '重播';

  @override
  String get navMore => '更多';

  @override
  String get appLogs => 'App 日誌';

  @override
  String get changelogTitle => '更新日誌';

  @override
  String get changelogEmpty => '目前沒有更新日誌';

  @override
  String get changelogTypePrerelease => '公測';

  @override
  String get changelogTypeStable => '正式';

  @override
  String get changelogCurrentVersion => '目前版本';

  @override
  String get changelogVersionDetails => '版本資訊';

  @override
  String get changelogBodyEmpty => '此版本沒有說明。';

  @override
  String get mapPlaceholderDisabled => '地圖(暫時停用)';

  @override
  String get moreSectionRegion => '地區';

  @override
  String get moreSectionNotify => '通知';

  @override
  String get moreSectionDisplay => '顯示';

  @override
  String get regionManageTitle => '常用地區';

  @override
  String get regionAddButton => '新增地區';

  @override
  String get regionEmpty => '尚未新增常用地區';

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
  String get regionEdit => '修改';

  @override
  String get moreSectionAdvanced => '進階';

  @override
  String get moreDeveloper => '除錯資訊';

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
  String get regionCurrentUnavailable => '無法取得所在地位置資訊';

  @override
  String get weatherPrecipitation => '降水量';

  @override
  String get weatherHumidity => '濕度';

  @override
  String get homeForecastTitle => '24小時預報';

  @override
  String homeForecastHighLow(String high, String low) {
    return '高 $high° · 低 $low°';
  }

  @override
  String homeForecastPop(String pop) {
    return '$pop%';
  }

  @override
  String homeForecastFeelsLike(String temp) {
    return '體感 $temp°';
  }

  @override
  String homeForecastHumidity(String value) {
    return '濕度 $value%';
  }

  @override
  String homeForecastWind(String direction, String level) {
    return '$direction · $level 級';
  }

  @override
  String get homeForecastUnavailable => '選擇鄉鎮後可查看預報';

  @override
  String get homeForecastEmpty => '目前沒有預報資料';

  @override
  String get homeActiveEventsTitle => '生效中事件';

  @override
  String get homeActiveEventsEmpty => '目前沒有生效中的事件';

  @override
  String get homeRainTrendTitle => '近 1 小時降水趨勢';

  @override
  String homeRainTrendMinute(int minute) {
    return '$minute分';
  }

  @override
  String homeRainTrendUpdated(String time) {
    return '更新 $time';
  }

  @override
  String get homeRainTrendNoData => '無資料';

  @override
  String get homeRainTrendScattered => '可能會有零星降雨';

  @override
  String get homeRainTrendLightSustained => '未來 1 小時會有持續小雨';

  @override
  String homeRainTrendLightStopping(int minutes) {
    return '預計 $minutes 分鐘後停止下小雨';
  }

  @override
  String get homeRainTrendHeavySustained => '未來 1 小時會有持續大雨';

  @override
  String homeRainTrendHeavyStopping(int minutes) {
    return '預計 $minutes 分鐘後停止下大雨';
  }

  @override
  String get mapLayers => '圖層';

  @override
  String get mapLayerOrderTitle => '調整圖層順序';

  @override
  String get mapLayerOrderReset => '回復預設順序';

  @override
  String get mapLayerRadar => '雷達合成回波圖';

  @override
  String get mapLayerSatellite => 'ひまわり 紅外線圖';

  @override
  String get mapLayerQpesums => '未來 1 小時降水預報';

  @override
  String get mapLayerLightning => '閃電';

  @override
  String lightningLegendCg(int minutes) {
    return '對地 · $minutes 分內';
  }

  @override
  String lightningLegendCc(int minutes) {
    return '雲間 · $minutes 分內';
  }

  @override
  String get mapTimelineNow => '現在';

  @override
  String get mapTimelineObserved => '觀測';

  @override
  String get mapTimelineForecast => '預報';

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

  @override
  String get displaySettings => '顯示設定';

  @override
  String get defaultMapLayerSettings => '地圖預設圖層';

  @override
  String get defaultMapLayerSubtitle => '開啟地圖分頁時顯示此圖層，底部導覽列圖示與文字會一併更新。';

  @override
  String get mapNavRadar => '雷達';

  @override
  String get mapNavQpesums => '預報';

  @override
  String get mapNavSatellite => '衛星';

  @override
  String get mapNavLightning => '閃電';

  @override
  String get mapNavTyphoon => '颱風';

  @override
  String get mapNavEarthquake => '地震';

  @override
  String get mapNavTemperature => '溫度';

  @override
  String get mapNavHumidity => '濕度';

  @override
  String get mapNavPressure => '氣壓';

  @override
  String get mapNavWind => '風向';

  @override
  String get mapNavRain => '雨量';

  @override
  String get mapNavDisaster => '防災';

  @override
  String get displayTheme => '主題';

  @override
  String get themeSystem => '跟隨系統';

  @override
  String get themeLight => '淺色';

  @override
  String get themeDark => '深色';

  @override
  String get moreSectionAbout => '關於';

  @override
  String get termsOfService => '服務條款';

  @override
  String get faq => '常見問題';

  @override
  String get openSourceLicenses => '引用套件';

  @override
  String get sponsorTitle => '支持 DPIP';

  @override
  String get sponsorIntro =>
      'DPIP 致力於提供即時防災資訊，沒有廣告或其他營利模式。您的支持能幫助我們維持伺服器運作並持續開發。';

  @override
  String get sponsorSubscriptions => '訂閱制';

  @override
  String get sponsorRecommended => '推薦';

  @override
  String get sponsorOneTime => '單次支援';

  @override
  String sponsorPerMonth(String price) {
    return '$price / 月';
  }

  @override
  String get sponsorRestore => '恢復購買';

  @override
  String get sponsorTerms => '使用條款';

  @override
  String get sponsorPrivacy => '隱私權政策';

  @override
  String get sponsorRestoring => '正在恢復購買…';

  @override
  String get sponsorRestoreUnavailable => '無法連線至商店，請稍後再試';

  @override
  String get commonClose => '關閉';

  @override
  String get mapLayerTemperature => '溫度';

  @override
  String get trendRange24h => '24 小時';

  @override
  String get trendRange7d => '7 天';

  @override
  String get trendNoData => '沒有趨勢資料';

  @override
  String trendCumulativeTotal(String total) {
    return '累計 $total mm';
  }

  @override
  String chartHourLabel(int hour) {
    return '$hour時';
  }

  @override
  String get mapLayerHumidity => '濕度';

  @override
  String get mapLayerPressure => '氣壓';

  @override
  String get mapLayerWind => '風向';

  @override
  String get mapLayerRain => '雨量';

  @override
  String get rainIntervalMenu => '累積時段';

  @override
  String get rainIntervalNow => '今日';

  @override
  String get rainInterval10m => '10 分';

  @override
  String get rainInterval1h => '1 時';

  @override
  String get rainInterval3h => '3 時';

  @override
  String get rainInterval6h => '6 時';

  @override
  String get rainInterval12h => '12 時';

  @override
  String get rainInterval24h => '24 時';

  @override
  String get rainInterval2d => '2 日';

  @override
  String get rainInterval3d => '3 日';

  @override
  String get mapLayerTyphoon => '颱風';

  @override
  String get typhoonNoActive => '目前無颱風';

  @override
  String get typhoonWind => '風速';

  @override
  String get typhoonGust => '陣風';

  @override
  String get typhoonPressure => '氣壓';

  @override
  String get typhoonMotion => '移動';

  @override
  String get typhoonLabelPosition => '中心位置';

  @override
  String get typhoonLabelDirection => '過去移動方向';

  @override
  String get typhoonLabelSpeed => '過去移動時速';

  @override
  String get typhoonLabelPressure => '中心氣壓';

  @override
  String get typhoonLabelWind => '近中心最大風速';

  @override
  String get typhoonLabelGust => '瞬間最大陣風';

  @override
  String get typhoonLabelGaleAvg => '七級風平均暴風半徑';

  @override
  String get typhoonLabelStormAvg => '十級風平均暴風半徑';

  @override
  String get typhoonLabelProbCircle => '70%機率圓';

  @override
  String typhoonForecastLead(String hours) {
    return '預測 +$hours 小時';
  }

  @override
  String get typhoonLabelNw => '西北側';

  @override
  String get typhoonLabelNe => '東北側';

  @override
  String get typhoonLabelSw => '西南側';

  @override
  String get typhoonLabelSe => '東南側';

  @override
  String typhoonValueLat(String lat) {
    return '北緯 $lat 度';
  }

  @override
  String typhoonValueLon(String lon) {
    return '東經 $lon 度';
  }

  @override
  String typhoonValueKm(String n) {
    return '$n 公里';
  }

  @override
  String typhoonValueHpa(String n) {
    return '$n 百帕';
  }

  @override
  String typhoonValueMs(String n) {
    return '每秒 $n 公尺';
  }

  @override
  String typhoonDataTime(String time) {
    return '資料時間\n$time';
  }

  @override
  String get mapLayerMonitor => '強震監視器';

  @override
  String get mapLayerDisasterMap => '防災地圖';

  @override
  String get mapLayerAed => 'AED';

  @override
  String get disasterMapOverlayMenuTooltip => '防災地圖圖層';

  @override
  String get disasterMapOverlaySectionLayers => '圖層';

  @override
  String get disasterMapOverlayAedTooltip => '顯示 AED 位置';

  @override
  String get aedAddress => '地址';

  @override
  String get aedRegion => '縣市區域';

  @override
  String get aedCategory => '場所分類';

  @override
  String get aedType => '場所類型';

  @override
  String get aedPlaceDesc => '放置位置說明';

  @override
  String get aedDescription => '備註';

  @override
  String get aedHoursWeekday => '平日開放時間';

  @override
  String get aedHoursSaturday => '週六開放時間';

  @override
  String get aedHoursSunday => '週日開放時間';

  @override
  String get aedOpenRemark => '開放時間備註';

  @override
  String get aedEmergencyPhone => '緊急聯絡電話';

  @override
  String get mapLayerRestroom => '公廁';

  @override
  String get mapLayerShelter => '避難收容場所';

  @override
  String get disasterMapOverlayRestroomTooltip => '顯示公廁';

  @override
  String get disasterMapOverlayShelterTooltip => '顯示避難收容場所';

  @override
  String get dpmOpenInMaps => '開啟地圖';

  @override
  String get mapAppGoogleMaps => 'Google Maps';

  @override
  String get mapAppAppleMaps => 'Apple Maps';

  @override
  String mapAppDefault(String app) {
    return '$app（預設）';
  }

  @override
  String get mapAppCopyCoordinates => '複製座標';

  @override
  String get mapAppCoordinatesCopied => '已複製座標';

  @override
  String get mapOverlaySectionReference => '參考圖層';

  @override
  String get mapOverlaySectionMap => '地圖';

  @override
  String get rainIntervalSection => '統計時間';

  @override
  String get mapTownLabels => '鄉鎮名稱';

  @override
  String get mapTownLabelsHint => '放大時顯示鄉鎮名稱';

  @override
  String get dpmSheetEmpty => '點選地圖上的標記查看詳情';

  @override
  String get dpmAddress => '地址';

  @override
  String get restroomTypeLabel => '廁所類型';

  @override
  String get restroomCategoryLabel => '類別';

  @override
  String get restroomGradeLabel => '等級';

  @override
  String get restroomTypeFemale => '女廁所';

  @override
  String get restroomTypeMale => '男廁所';

  @override
  String get restroomTypeMixed => '混合廁所';

  @override
  String get restroomTypeAccessible => '無障礙廁所';

  @override
  String get restroomTypeGenderNeutral => '性別友善廁所';

  @override
  String get restroomTypeFamily => '親子廁所';

  @override
  String get restroomTypeUnspecified => '未設定';

  @override
  String get restroomCategoryTransport => '交通';

  @override
  String get restroomCategoryPark => '公園';

  @override
  String get restroomCategoryCommercial => '商業營業場所';

  @override
  String get restroomCategoryReligious => '宗教禮儀場所';

  @override
  String get restroomCategoryCultural => '文化育樂活動場所';

  @override
  String get restroomCategoryGovernment => '民眾洽公場所';

  @override
  String get restroomCategoryWelfare => '社福機構、集會場所';

  @override
  String get restroomCategoryTourist => '觀光地區及風景區';

  @override
  String get restroomCategoryLeisure => '休閒娛樂場所';

  @override
  String get restroomCategoryOther => '其他';

  @override
  String get restroomGradeExcellent => '特優級';

  @override
  String get restroomGradeGood => '優等級';

  @override
  String get restroomGradeAverage => '普通級';

  @override
  String get restroomGradePoor => '不合格';

  @override
  String get shelterAddressLabel => '地址';

  @override
  String get shelterCapacityLabel => '收容人數';

  @override
  String shelterCapacityValue(int n) {
    return '$n 人';
  }

  @override
  String get shelterCategoryLabel => '適用災害';

  @override
  String get shelterIndoorLabel => '室內收容';

  @override
  String get shelterOutdoorLabel => '室外收容';

  @override
  String get shelterVulnerableOkLabel => '適合避難弱者安置';

  @override
  String get dpmYes => '是';

  @override
  String get dpmNo => '否';

  @override
  String get stationSheetEmpty => '點選任一測站查看觀測值';

  @override
  String monitorDelay(String value) {
    return '延遲 $value s';
  }

  @override
  String get monitorWaiting => '等待資料…';

  @override
  String mapLegendUnit(String unit) {
    return '單位：$unit';
  }

  @override
  String get typhoonLegendPast => '實際路徑';

  @override
  String get typhoonIntensityTd => '熱帶性低氣壓';

  @override
  String typhoonPickerNamed(String no, String name) {
    return '$name TY $no';
  }

  @override
  String typhoonPickerTd(String no) {
    return '熱帶性低氣壓 TD $no';
  }

  @override
  String get typhoonIntensityMild => '輕度颱風';

  @override
  String get typhoonIntensityModerate => '中度颱風';

  @override
  String get typhoonIntensityIntense => '強烈颱風';

  @override
  String get typhoonLegendForecast => '預測路徑';

  @override
  String get typhoonLegendForecastPoint => '預測點';

  @override
  String get typhoonLegendCurrent => '目前中心';

  @override
  String get typhoonLegendCone => '預測圓錐';

  @override
  String get mapLegendExpand => '圖例';

  @override
  String get mapLegendCollapse => '收合圖例';

  @override
  String get mapMyLocation => '我的位置';

  @override
  String get mapResetNorth => '回到北方';

  @override
  String get typhoonLegendCircle15 => '七級風暴風圈';

  @override
  String get typhoonLegendCircleAvg => '平均圓';

  @override
  String get typhoonLegendCircle25 => '十級風暴風圈';

  @override
  String typhoonStormRadii(String ne, String se, String sw, String nw) {
    return '東北 $ne · 東南 $se · 西南 $sw · 西北 $nw km';
  }

  @override
  String typhoonTimeChip(String day, String hour) {
    return '$day日$hour時';
  }

  @override
  String get typhoonLegendProbability => '侵襲機率';

  @override
  String get typhoonLegendWarningAreas => '警報區域';

  @override
  String get typhoonOverlayMenuTooltip => '颱風圖層選項';

  @override
  String get typhoonOverlaySectionStorm => '暴風圈';

  @override
  String get typhoonOverlaySectionExtra => '覆蓋層';

  @override
  String get typhoonOverlayStormBandSubtitle => '含平均圓';

  @override
  String get typhoonOverlayProbabilityHint => '會隱藏預測圓錐';

  @override
  String get typhoonOverlayProbabilityTooltip => '顯示侵襲機率（會隱藏預測圓錐）';

  @override
  String get typhoonOverlayWarningTooltip => '標示警報區域縣市';

  @override
  String get typhoonOverlayStormL7Tooltip => '七級暴風圈＋平均圓（紫色）';

  @override
  String get typhoonOverlayStormL10Tooltip => '十級暴風圈＋平均圓（黃色）';

  @override
  String get typhoonOverlaySectionWeather => '天氣底圖';

  @override
  String get typhoonOverlayWeatherNone => '無';

  @override
  String get typhoonOverlayWeatherHint => '對齊報文時間';

  @override
  String get typhoonOverlayWeatherNoneTooltip => '不疊雷達或紅外線';

  @override
  String get typhoonOverlayWeatherRadarTooltip => '雷達回波（對齊颱風報文時間）';

  @override
  String get typhoonOverlayWeatherSatelliteTooltip => '紅外線（對齊颱風報文時間）';

  @override
  String get typhoonWarningTitle => '颱風警報';

  @override
  String typhoonWarningAreas(String areas) {
    return '警戒區域：$areas';
  }

  @override
  String get typhoonTrackDetail => '路徑詳情';

  @override
  String get typhoonHistoryTitle => '資料時間';

  @override
  String get typhoonHistoryLive => '即時';

  @override
  String get typhoonSatelliteTitle => '衛星雲圖';

  @override
  String get typhoonOverlayForecastCallouts => '預測點資訊';

  @override
  String get typhoonOverlayForecastCalloutsTooltip => '放大時顯示預測點詳細卡片';

  @override
  String get dpmFilterSectionRestroom => '場所類型';

  @override
  String get dpmFilterSectionRestroomType => '廁所類型';

  @override
  String get dpmFilterSectionShelter => '避難所災害類型';

  @override
  String get dpmDisasterFlood => '水災';

  @override
  String get dpmDisasterEarthquake => '震災';

  @override
  String get dpmDisasterLandslide => '土石流';

  @override
  String get dpmDisasterTsunami => '海嘯';

  @override
  String get dpmDisasterSlope => '坡地災害';

  @override
  String get dpmDisasterNuclear => '核子事故';

  @override
  String get skyTime => '天空時間';

  @override
  String get skyTimeAuto => '自動';

  @override
  String get skyTimeDawn => '黎明';

  @override
  String get skyTimeSunrise => '日出';

  @override
  String get skyTimeMorning => '上午';

  @override
  String get skyTimeNoon => '正午';

  @override
  String get skyTimeAfternoon => '下午';

  @override
  String get skyTimeGolden => '黃金時刻';

  @override
  String get skyTimeSunset => '日落';

  @override
  String get skyTimeDusk => '暮色';

  @override
  String get skyTimeNight => '夜晚';

  @override
  String get weatherModeCloudy => '多雲';

  @override
  String get weatherModeOvercast => '陰天';

  @override
  String get weatherModeSnow => '下雪';

  @override
  String get weatherModeSand => '沙塵';

  @override
  String get radarScanRange => '顯示掃描範圍';

  @override
  String get radarScanRangeSubtitle => '標示四座雷達實際觀測到的範圍。';

  @override
  String get radarScanRangeHint => '框外空白代表未觀測';

  @override
  String get radarOverlayMenuTooltip => '雷達圖層選項';

  @override
  String get radarCountyOutline => '縣市界線';

  @override
  String get radarCountyOutlineHint => '畫在回波之上';

  @override
  String get radarCountyOutlineSubtitle => '讓縣市界線在雷達回波下仍然清楚。';

  @override
  String get radarTownOutline => '鄉鎮界線';

  @override
  String get radarTownOutlineHint => '較細的分區';

  @override
  String get radarTownOutlineSubtitle => '讓鄉鎮界線在雷達回波下仍然清楚。';

  @override
  String get qpesumsOverlayMenuTooltip => '定量降水預報圖層選項';
}
