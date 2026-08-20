// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String typhoonValueLat(String lat) {
    return '北緯 $lat 度';
  }

  @override
  String get onboardingSkipBody =>
      '未授權定位與通知,DPIP 將無法即時通知你所在地的地震與災害。你仍可稍後在設定中開啟。';

  @override
  String get rainInterval24h => '24 時';

  @override
  String homeRainTrendHeavyStopping(int minutes) {
    return '預計 $minutes 分鐘後停止下大雨';
  }

  @override
  String get mapTimelineObserved => '觀測';

  @override
  String get mapTimelineScrubPaused => '拖動過快，影格更新已暫停；放慢速度即可恢復。';

  @override
  String get regionSelectTitle => '選擇地區';

  @override
  String get skyTimeNoon => '正午';

  @override
  String get radarCountyOutlineSubtitle => '讓縣市界線在雷達回波下仍然清楚。';

  @override
  String get mapLayerSatelliteB03 => 'ひまわり 可見光-紅(B03)';

  @override
  String get reportFilterIntensity => '震度';

  @override
  String get mapLayerLightning => '閃電';

  @override
  String get restroomTypeMale => '男廁所';

  @override
  String get meshtasticLastReceived => '最近接收';

  @override
  String get reportDetailSortByCounty => '依縣市排序';

  @override
  String get onboardingPermUnusedApp => '保持 App 啟用';

  @override
  String get onboardingPermUnusedAppDesc =>
      'Android 會暫停你長期未開啟的 App 並撤銷其權限，這會讓災害警報無法送達你所在地。';

  @override
  String get onboardingPermBackgroundExec => '背景執行';

  @override
  String get onboardingPermBackgroundExecDesc => '關閉時，App 不會被喚醒回報你的位置。';

  @override
  String get onboardingPermVendorPower => '手機廠商省電設定';

  @override
  String onboardingPermVendorPowerDesc(String brand) {
    return '$brand 會停止你最近沒開過的 App 的背景作業。App 無法偵測或變更，請手動允許。';
  }

  @override
  String get homeRainTrendScattered => '可能會有零星降雨';

  @override
  String get meshtasticUptime => '運行時間';

  @override
  String get weatherRankingTempExtremes => '溫度極值';

  @override
  String get themeLight => '淺色';

  @override
  String get mapTerrainReliefHint => '在底圖上顯示立體地形陰影';

  @override
  String get meshtasticEmptyMessage => '（空白訊息）';

  @override
  String get moreSectionRegion => '地區';

  @override
  String get mapLayerSatellite => 'ひまわり 紅外線(B13)';

  @override
  String get aedHoursSaturday => '週六開放時間';

  @override
  String get moonPhaseNew => '新月';

  @override
  String get notifySectionEew => '地震速報';

  @override
  String get mapResetNorth => '回到北方';

  @override
  String get rainInterval2d => '2 日';

  @override
  String get mapTownLabelsHint => '放大時顯示鄉鎮名稱';

  @override
  String get commonCancel => '取消';

  @override
  String get notifyOptTsunamiWarning => '只接收海嘯警報';

  @override
  String get mapLayerSatelliteBtdFog => 'ひまわり 夜間霧';

  @override
  String get moreSectionAdvanced => '進階';

  @override
  String get moreSectionMesh => 'Mesh 網路';

  @override
  String get weatherRankingExtremeRange => '日溫差';

  @override
  String get permissionsTitle => '權限檢查';

  @override
  String get permissionsAttention => '權限需要處理';

  @override
  String get permissionsBody => 'DPIP 需要這些權限才能即時通知你。收不到警報時，通常就是其中一項尚未開啟。';

  @override
  String get notifySettingsMenu => '通知設定';

  @override
  String mapAppDefault(String app) {
    return '$app（預設）';
  }

  @override
  String get trendRange24h => '24 小時';

  @override
  String get mapLayerStyleJmaTooltip => '灰階為底，−40 °C 以下上色，凸顯雲頂高度';

  @override
  String get mapLayerRain => '雨量';

  @override
  String get mapLayerQpesums => '未來 1 小時降水預報';

  @override
  String get mapOverlaySectionMap => '地圖';

  @override
  String get mapTerrainRelief => '地形立體感';

  @override
  String get mapLegendCollapse => '收合圖例';

  @override
  String get updateAvailableTitle => '有新版本';

  @override
  String updateAvailableBody(String version) {
    return '新版本 $version 已發布。';
  }

  @override
  String get updateSkip => '略過此次';

  @override
  String get updateViewChangelog => '前往查看';

  @override
  String get updateOpenAppStore => 'App Store';

  @override
  String get updateOpenTestFlight => 'TestFlight';

  @override
  String get updateOpenPlayStore => 'Play 商店';

  @override
  String get updateDownload => '下載更新';

  @override
  String get changelogShowSnapshots => '顯示測試版';

  @override
  String get changelogTitle => '更新日誌';

  @override
  String get reportFilterOrderDesc => '降序';

  @override
  String get meshtasticExcludeMqttSubtitle => '經網際網路橋接、並非無線電聽到的節點';

  @override
  String get reportFilterIntensityInfoTitle => '震度新制與舊制';

  @override
  String get mapLayerTyphoon => '颱風';

  @override
  String get radarOverlayMenuTooltip => '雷達圖層選項';

  @override
  String get meshtasticNodes => '節點';

  @override
  String get meshtasticSend => '傳送';

  @override
  String get typhoonOverlayStormL7Tooltip => '七級暴風圈＋平均圓（紫色）';

  @override
  String get aedType => '場所類型';

  @override
  String get termsOfService => '服務條款';

  @override
  String get typhoonLegendCircle25 => '十級風暴風圈';

  @override
  String get sponsorTitle => '支援 DPIP';

  @override
  String get mapNavSatellite => '衛星';

  @override
  String homeRainTrendUpdated(String time) {
    return '更新 $time';
  }

  @override
  String get onboardingNext => '下一步';

  @override
  String get weatherRankingMergeTown => '鄉鎮';

  @override
  String get mapLayerMonitor => '強震監視器';

  @override
  String get moreYoutube => 'YouTube';

  @override
  String get sponsorSubscriptions => '訂閱制';

  @override
  String typhoonValueLon(String lon) {
    return '東經 $lon 度';
  }

  @override
  String get skyTime => '天空時間';

  @override
  String get weatherModeCloudy => '多雲';

  @override
  String get skyTimeDusk => '暮色';

  @override
  String get meshtasticFirmware => '韌體';

  @override
  String get reportFilterDateEndNote => '結束日：當日 24:00（臺北時間）';

  @override
  String get reportFilterSortMagnitude => '規模';

  @override
  String get meshtasticSilent => '已靜默';

  @override
  String get mapLayerCategoryEarthquake => '地震';

  @override
  String get mapLayerSatelliteB12 => 'ひまわり 臭氧(B12)';

  @override
  String get restroomCategoryOther => '其他';

  @override
  String homeForecastHighLow(String high, String low) {
    return '高 $high° · 低 $low°';
  }

  @override
  String get locationBannerFix => '開啟設定';

  @override
  String get mapLegendExpand => '圖例';

  @override
  String get eewNone => '目前沒有地震速報';

  @override
  String typhoonTyNo(String no) {
    return 'TY $no';
  }

  @override
  String get notifyOptTsunamiAll => '海嘯消息、海嘯警報';

  @override
  String get meshtasticLayerOptions => '節點選項';

  @override
  String get onboardingAgreeContinue => '同意並繼續';

  @override
  String get commonRetry => '重試';

  @override
  String get meshtasticNodeId => '節點 ID';

  @override
  String reportDetailNumbered(String number) {
    return '編號 $number 顯著有感地震';
  }

  @override
  String get typhoonOverlayStormBandSubtitle => '含平均圓';

  @override
  String get disasterMapOverlayRestroomTooltip => '顯示公廁';

  @override
  String get weatherRankingTitle => '觀測排行';

  @override
  String get homeRainTrendHeavySustained => '未來 1 小時會有持續大雨';

  @override
  String get notifySectionTsunami => '海嘯';

  @override
  String get restroomCategoryPark => '公園';

  @override
  String get moreLinkOpenFailed => '無法開啟連結';

  @override
  String get themeDark => '深色';

  @override
  String get sponsorRestore => '恢復購買';

  @override
  String get meshtasticChannelWorking => '正在設定 DPIP 頻道…';

  @override
  String get meshtasticRegionSwitch => '切換為 TW';

  @override
  String get meshtasticTraffic => '流量';

  @override
  String get mapLayerStyleBdTooltip => 'Dvorak BD 曲線——熱帶氣旋強度分析的階梯灰階';

  @override
  String get disasterMapOverlayAedTooltip => '顯示 AED 位置';

  @override
  String get mapLayerHumidity => '濕度';

  @override
  String get mapLayerSatelliteTransparentNight => '夜間 = 透明,顯示底圖';

  @override
  String get meshtasticScanning => '掃描中…';

  @override
  String regionSelectFull(int max) {
    return '最多只能選擇 $max 個地區';
  }

  @override
  String get meshtasticNewMessages => '新訊息';

  @override
  String get meshtasticBatteryHistory => '電量歷史';

  @override
  String get meshtasticStatAvg => '平均';

  @override
  String get meshtasticStatPeak => '峰值';

  @override
  String get meshtasticStatDrain => '掉電';

  @override
  String get meshtasticStatEta => '預估可用';

  @override
  String get meshtasticStatFull => '充滿';

  @override
  String get meshtasticStatTrend => '趨勢';

  @override
  String get meshtasticStatCharging => '充電中';

  @override
  String get meshtasticStatStable => '穩定';

  @override
  String get meshtasticNodesTotal => '已知';

  @override
  String get meshtasticNodesOnline => '在線';

  @override
  String get meshtasticRx => '接收';

  @override
  String get meshtasticTx => '發送';

  @override
  String get meshtasticNodesHistory => '節點數歷史';

  @override
  String get meshtasticTrafficHistory => '流量歷史';

  @override
  String meshtasticEtaHours(int n) {
    return '約 $n 小時';
  }

  @override
  String meshtasticEtaDays(int n) {
    return '約 $n 天';
  }

  @override
  String get meshtasticTitle => 'Meshtastic';

  @override
  String get navMore => '更多';

  @override
  String get meshtasticDpipChannel => 'DPIP 頻道';

  @override
  String get disasterMapOverlaySectionLayers => '圖層';

  @override
  String get mapLayerSatelliteB05 => 'ひまわり 近紅外(B05)';

  @override
  String get typhoonLabelNe => '東北側';

  @override
  String get meshtasticCopied => '已複製訊息';

  @override
  String get reportListEmpty => '目前沒有地震報告';

  @override
  String get reportListEnd => '已到最後一頁';

  @override
  String get mapLayerSatelliteTruecolor => 'ひまわり 真彩色';

  @override
  String get typhoonOverlaySectionExtra => '覆蓋層';

  @override
  String get eewSWave => '震波';

  @override
  String get meshtasticBusyTitle => '另一個 App 正在使用這台裝置';

  @override
  String get restroomCategoryCultural => '文化育樂活動場所';

  @override
  String get typhoonLabelWind => '近中心最大風速';

  @override
  String get radarGlobalOutlineHint => '各國國界外框';

  @override
  String get notifyEvacuation => '防災資訊';

  @override
  String get typhoonLegendCircle15 => '七級風暴風圈';

  @override
  String get dataSectionAstronomy => '天文';

  @override
  String get homeRainTrendLightSustained => '未來 1 小時會有持續小雨';

  @override
  String get commonError => '發生錯誤';

  @override
  String get moonPhaseWaningCrescent => '殘月';

  @override
  String get meshtasticPower => '電力';

  @override
  String get mapTimelineNow => '現在';

  @override
  String reportFilterRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String get reportDetailOpenReport => '報告頁面';

  @override
  String get trendRange7d => '7 天';

  @override
  String typhoonWarningAreas(String areas) {
    return '警戒區域：$areas';
  }

  @override
  String get rainIntervalSection => '統計時間';

  @override
  String get notifyTitle => '通知';

  @override
  String get meshtasticTxPower => '發射功率';

  @override
  String get restroomCategoryLabel => '類別';

  @override
  String get sponsorRestoring => '正在恢復購買…';

  @override
  String get sponsorIntro =>
      'DPIP 致力於提供即時防災資訊，沒有廣告或其他營利模式。您的支援能幫助我們維持伺服器運作並持續開發。';

  @override
  String get typhoonLabelStormAvg => '十級風平均暴風半徑';

  @override
  String get restroomCategoryCommercial => '商業營業場所';

  @override
  String get aedRegion => '縣市區域';

  @override
  String homeRainTrendLightStopping(int minutes) {
    return '預計 $minutes 分鐘後停止下小雨';
  }

  @override
  String get reportDetailInfo => '詳細資訊';

  @override
  String get mapNavWind => '風向';

  @override
  String get windForecastOverlayMenuTooltip => '風場預報圖層選項';

  @override
  String homeRainTrendMinute(int minute) {
    return '$minute分';
  }

  @override
  String get rainInterval6h => '6 時';

  @override
  String get restroomTypeUnspecified => '未設定';

  @override
  String get typhoonOverlayProbabilityHint => '會隱藏預測圓錐';

  @override
  String get mapLayerSatelliteGlobalOutline => '國界';

  @override
  String get mapNavTemperature => '溫度';

  @override
  String get typhoonLegendForecastPoint => '預測點';

  @override
  String get reportListYesterday => '昨天';

  @override
  String get moreSectionLinks => '相關連結';

  @override
  String get feedOffline => '連線中斷';

  @override
  String get mapLayerStyleBd => 'Dvorak BD';

  @override
  String get moreSectionDisplay => '顯示';

  @override
  String get rainInterval3d => '3 日';

  @override
  String get defaultMapLayerSubtitle => '開啟地圖分頁時顯示此圖層，底部導覽列圖示與文字會一併更新。';

  @override
  String get aedDescription => '備註';

  @override
  String get typhoonOverlayWeatherRadarTooltip => '雷達回波（對齊颱風報文時間）';

  @override
  String get onboardingPermLocationDesc => '依你所在位置推送在地警報。';

  @override
  String get mapLayerSatelliteB16 => 'ひまわり 二氧化碳(B16)';

  @override
  String get homeActiveEventsEmpty => '目前沒有生效中的事件';

  @override
  String get typhoonLabelPosition => '中心位置';

  @override
  String get weatherRankingBy => '依';

  @override
  String get typhoonIntensityMild => '輕度颱風';

  @override
  String get windForecastGlobalOutlineHint => '各國國界外框';

  @override
  String get rainInterval1h => '1 時';

  @override
  String get eewLocalIntensity => '所在地預估';

  @override
  String get mapLayerRadar => '雷達合成回波圖';

  @override
  String get restroomCategoryReligious => '宗教禮儀場所';

  @override
  String get meshtasticRole => '角色';

  @override
  String get mapLayerSatelliteCloudCloudy => '有雲';

  @override
  String get skyTimeSunrise => '日出';

  @override
  String get meshtasticJumpToLatest => '跳到最新';

  @override
  String get meshtasticNoMessages => '尚無訊息';

  @override
  String get onboardingPermNotifyDesc => '在地震、天氣與災害發生時,即時傳遞警報通知。';

  @override
  String get radarTownOutline => '鄉鎮界線';

  @override
  String get mapLayerStyleSection => '顯示樣式';

  @override
  String get disasterMapOverlayMenuTooltip => '防災地圖圖層';

  @override
  String get moreGooglePlay => 'Google Play';

  @override
  String get meshtasticOnline => '近期聽到';

  @override
  String get typhoonLabelSw => '西南側';

  @override
  String typhoonForecastLead(String hours) {
    return '預測 +$hours 小時';
  }

  @override
  String get changelogTypeStable => '正式版';

  @override
  String get mapLayerSatelliteTransparentClear => '晴空 = 透明,顯示底圖';

  @override
  String get mapOverlaySectionReference => '參考圖層';

  @override
  String get mapLayerSatelliteB02 => 'ひまわり 可見光-綠(B02)';

  @override
  String get weatherRankingEmpty => '目前沒有可排序的觀測';

  @override
  String get notifySectionOther => '其他';

  @override
  String weatherRankingMeta(String time, int count) {
    return '資料時間：$time\n共 $count 觀測點';
  }

  @override
  String get onboardingTermsAgree => '我已閱讀並同意服務條款';

  @override
  String get mapLayerSatelliteTransparentNoVegetation => '< 0.1 = 透明(無植被)';

  @override
  String get notifyOptLocalIntensity4 => '所在地震度4以上';

  @override
  String get eewArrived => '已抵達';

  @override
  String get meshtasticNoDevices => '找不到 Meshtastic 裝置';

  @override
  String get mapLayerCategoryLife => '生活';

  @override
  String get reportFilterSortIntensity => '震度';

  @override
  String get meshtasticStateDisconnected => '未連線';

  @override
  String get typhoonIntensityIntense => '強烈颱風';

  @override
  String get mapLayerOrderTitle => '調整圖層順序';

  @override
  String get mapLayerShow => '顯示圖層';

  @override
  String get mapLayerHide => '隱藏圖層';

  @override
  String get mapLayerShowAll => '全部顯示';

  @override
  String get mapLayerHideAll => '全部隱藏';

  @override
  String get dpmYes => '是';

  @override
  String get meshtasticNoHistory => '歷史紀錄還不夠';

  @override
  String get reportDetailLocalIntensityUnavailable => '沒有震度訊息';

  @override
  String get mapLayerWindForecastGfs => 'GFS';

  @override
  String get reportFilterDepth => '深度';

  @override
  String get onboardingScrollHint => '往下捲動以繼續';

  @override
  String get mapNavQpesums => '預報';

  @override
  String get notifyAdvisory => '天氣警特報';

  @override
  String get reportFilterReset => '重設';

  @override
  String get mapLayerSatelliteMndwi => 'ひまわり 改良水體指數';

  @override
  String get typhoonOverlaySectionStorm => '暴風圈';

  @override
  String get moonPhaseFull => '滿月';

  @override
  String meshtasticBinaryPayload(String size) {
    return '二進位內容 · $size';
  }

  @override
  String get moonPhaseWaningGibbous => '虧凸月';

  @override
  String get reportFilterIntensityInfoModernTitle => '新制（2020 起）';

  @override
  String typhoonDataTime(String time) {
    return '資料時間\n$time';
  }

  @override
  String get restroomTypeAccessible => '無障礙廁所';

  @override
  String get moreSectionAbout => '關於';

  @override
  String get meshtasticSelectDevice => '選擇裝置';

  @override
  String get onboardingIntroBody =>
      'DPIP 是與你並肩的防災夥伴,整合強震即時警報、地震報告、天氣與各類災害資訊,在關鍵時刻即時通知你。\n\n• 地震:強震即時警報、震度速報與地震報告\n• 天氣:雷雨即時訊息、天氣警特報\n• 海嘯與防災資訊\n\n接下來,我們會請你閱讀服務條款,並授權幾項讓 DPIP 能即時守護你的權限。';

  @override
  String get shelterCapacityLabel => '收容人數';

  @override
  String get reportDetailImage => '地震報告圖';

  @override
  String get meshtasticStateConfiguring => '設定中…';

  @override
  String get typhoonLabelGaleAvg => '七級風平均暴風半徑';

  @override
  String get onboardingPermNotify => '通知';

  @override
  String get meshtasticClearMessages => '清除訊息';

  @override
  String get meshtasticNotifyMessages => '新訊息通知';

  @override
  String get defaultMapLayerSettings => '地圖預設圖層';

  @override
  String get eewSourceSettings => '地震速報來源';

  @override
  String get eewSourceSubtitle => '選擇要顯示哪些單位發布的地震速報。';

  @override
  String get eewSourceAll => '所有來源';

  @override
  String get eewSourceAllDescription => '顯示所有機構發布的地震速報。';

  @override
  String get eewSourceCwaOnly => '僅中央氣象署';

  @override
  String get eewSourceCwaOnlyDescription => '只顯示中央氣象署發布的地震速報。';

  @override
  String get moreSectionNotify => '通知';

  @override
  String get notifyUnavailable => '推播尚未就緒，請稍後再試。';

  @override
  String get mapLayerOrderReset => '回復預設順序';

  @override
  String get weatherRankingMergeCounty => '縣市';

  @override
  String get moreSectionApp => '取得 App';

  @override
  String get moreSectionBeta => '測試版';

  @override
  String get moreAndroidBeta => 'Android 測試版';

  @override
  String get moreTestFlight => 'iOS 測試版（TestFlight）';

  @override
  String get moreSectionPartners => '合作夥伴';

  @override
  String get morePartnersNote => '依合作時間先後排列。感謝這些個人與公司對防災的貢獻，他們讓 DPIP 成為可能。';

  @override
  String get morePartnerGeoscience => '巨科資訊有限公司';

  @override
  String get morePartnerTwds => '台灣數位串流有限公司';

  @override
  String get reportFilterIntensityInfoLegacyBody => '震度僅 0–7，沒有 5弱／5強／6弱／6強。';

  @override
  String get mapLayerSatelliteSst => 'ひまわり 海表溫度';

  @override
  String get qpesumsOverlayMenuTooltip => '定量降水預報圖層選項';

  @override
  String get mapTimelineFuture => '未來';

  @override
  String get typhoonLegendCircleAvg => '平均圓';

  @override
  String reportFilterDepthKm(String depth) {
    return '$depth 公里';
  }

  @override
  String get typhoonLabelSe => '東南側';

  @override
  String get radarTownOutlineHint => '較細的分區';

  @override
  String eewCountdown(int seconds) {
    return '$seconds 秒';
  }

  @override
  String get typhoonLabelGust => '瞬間最大陣風';

  @override
  String get mapAppGoogleMaps => 'Google Maps';

  @override
  String get sponsorTerms => '使用條款';

  @override
  String get restroomTypeGenderNeutral => '性別友善廁所';

  @override
  String get notifyThunderstorm => '雷雨即時訊息';

  @override
  String get skyTimeGolden => '黃金時刻';

  @override
  String get moonAge => '月齡';

  @override
  String get meshtasticRadioSettings => 'LoRa';

  @override
  String get moreGithub => 'ExpTech GitHub';

  @override
  String get homeForecastUnavailable => '選擇鄉鎮後可查看預報';

  @override
  String get mapLayers => '圖層';

  @override
  String get meshtasticHardware => '硬體';

  @override
  String get languageSettings => '語言設定';

  @override
  String get language => '語言';

  @override
  String homeForecastFeelsLike(String temp) {
    return '體感 $temp°';
  }

  @override
  String get typhoonOverlayWeatherHint => '對齊報文時間';

  @override
  String get skyTimeDawn => '黎明';

  @override
  String get skyTimeAfternoon => '下午';

  @override
  String get meshtasticLastHeard => '最後聽到';

  @override
  String get typhoonWarningTitle => '颱風警報';

  @override
  String get moreSourceCode => '原始碼';

  @override
  String get mapLayerCategoryWeather => '氣象觀測';

  @override
  String get mapLayerSatelliteB09 => 'ひまわり 中層水氣(B09)';

  @override
  String get windForecastTownOutlineHint => '更細的網格';

  @override
  String get mapLayerSatelliteCloudmask => 'ひまわり 雲遮罩';

  @override
  String get mapAppCopyCoordinates => '複製座標';

  @override
  String get reportFilterIntensityInfoIntro =>
      '中央氣象署自 2020 年 1 月 1 日（臺北時間）起改用新制震度。';

  @override
  String get mapNavEarthquake => '地震';

  @override
  String get restroomGradeAverage => '普通級';

  @override
  String get mapLayerSatelliteBtdCo2 => 'ひまわり 卷雲/雲高';

  @override
  String get onboardingPermBackgroundDesc => '選擇「一律允許」,關閉 App 也能推送在地警報。';

  @override
  String get mapTimelineForecast => '預報';

  @override
  String get restroomTypeLabel => '廁所類型';

  @override
  String get navEarthquake => '地震';

  @override
  String get typhoonOverlayStormL10Tooltip => '十級暴風圈＋平均圓（黃色）';

  @override
  String get moonPhaseWaxingGibbous => '盈凸月';

  @override
  String get reportDetailTitle => '地震報告';

  @override
  String get moreTremReport => 'TREM 檢知報告';

  @override
  String weatherDataTime(String station, String time) {
    return '$station ∙ 資料時間 $time';
  }

  @override
  String get meshtasticNoNodes => '尚未聽到任何節點';

  @override
  String get meshtasticViaMqtt => '經 MQTT（網際網路）';

  @override
  String get radarCountyOutline => '縣市界線';

  @override
  String get commonClose => '關閉';

  @override
  String get restroomGradeLabel => '等級';

  @override
  String get rainIntervalNow => '今日';

  @override
  String get changelogCurrentVersion => '目前版本';

  @override
  String get typhoonLabelPressure => '中心氣壓';

  @override
  String get typhoonOverlayForecastCalloutsTooltip => '放大時顯示預測點詳細卡片';

  @override
  String get aedOpenRemark => '開放時間備註';

  @override
  String get onboardingPermsBody => '為了在災害發生的第一時間通知你,請授權以下權限。你隨時可以在系統設定中變更。';

  @override
  String get typhoonOverlaySectionWeather => '天氣底圖';

  @override
  String get notifyOptWeatherLocal => '接收所在地';

  @override
  String get mapNavRain => '雨量';

  @override
  String get moonDays => '天';

  @override
  String mapLegendUnit(String unit) {
    return '單位：$unit';
  }

  @override
  String get weatherModeClear => '晴天';

  @override
  String get meshtasticRadio => '電台';

  @override
  String get commonEmpty => '沒有資料';

  @override
  String get mapLayerSatelliteB01 => 'ひまわり 可見光-藍(B01)';

  @override
  String get meshtasticExternalPower => '外部供電';

  @override
  String get moonPhaseLastQuarter => '下弦月';

  @override
  String get reportFilterOrderAsc => '升序';

  @override
  String get reportFilterApply => '套用';

  @override
  String get reportDetailImageUnavailable => '報告圖尚未提供';

  @override
  String get weatherRankingHighest => '最高';

  @override
  String get reportDetailReplay => '重播';

  @override
  String get mapLayerRestroom => '公廁';

  @override
  String get restroomCategoryWelfare => '社福機構、集會場所';

  @override
  String get restroomGradeExcellent => '特優級';

  @override
  String get meshtasticLastSent => '最近送出';

  @override
  String get meshtasticName => '名稱';

  @override
  String get meshtasticScan => '掃描';

  @override
  String get mapLayerCategoryForecast => '數值預報';

  @override
  String get meshtasticChannelFailed => '無法設定 DPIP 頻道';

  @override
  String get themeSystem => '跟隨系統';

  @override
  String get mapLayerSatelliteNdvi => 'ひまわり 植生指數';

  @override
  String get typhoonLegendForecast => '預測路徑';

  @override
  String typhoonValueHpa(String n) {
    return '$n 百帕';
  }

  @override
  String get weatherPrecipitation => '降水量';

  @override
  String get moonNextFullMoon => '下次滿月';

  @override
  String get dpmSheetEmpty => '點選地圖上的標記查看詳情';

  @override
  String get onboardingSkipLeave => '仍要略過';

  @override
  String get aedPlaceDesc => '放置位置說明';

  @override
  String get onboardingSkipTitle => '尚未完成授權';

  @override
  String get restroomTypeFamily => '親子廁所';

  @override
  String typhoonValueKm(String n) {
    return '$n 公里';
  }

  @override
  String get onboardingPermBattery => '省電白名單';

  @override
  String get typhoonLabelNw => '西北側';

  @override
  String get moonPhaseWaxingCrescent => '眉月';

  @override
  String get restroomCategoryLeisure => '休閒娛樂場所';

  @override
  String get mapLayerTemperature => '溫度';

  @override
  String get aedCategory => '場所分類';

  @override
  String get meshtasticChannels => '頻道';

  @override
  String get monitorWaiting => '等待資料…';

  @override
  String get typhoonOverlayForecastCallouts => '預測點資訊';

  @override
  String get reportDetailEpicenter => '震央座標';

  @override
  String get meshtasticVoltage => '電壓';

  @override
  String get mapLayerMeshtasticSubtitle => '電台聽到過的 LoRa 網狀網路節點';

  @override
  String get mapLayerWind => '風向';

  @override
  String get reportDetailMagnitude => '地震規模';

  @override
  String get reportDetailAreaIntensity => '各地震度';

  @override
  String get rainInterval12h => '12 時';

  @override
  String reportListMagnitude(String magnitude) {
    return 'M$magnitude';
  }

  @override
  String get notifyMonitor => '強震監視器';

  @override
  String get onboardingStart => '開始使用';

  @override
  String sponsorPerMonth(String price) {
    return '$price / 月';
  }

  @override
  String get mapLayerPressure => '氣壓';

  @override
  String get mapLayerSatelliteB04 => 'ひまわり 近紅外(B04)';

  @override
  String get mapLayerSatelliteTransparentZero => '零差值 = 透明(無訊號)';

  @override
  String get shelterIndoorLabel => '室內收容';

  @override
  String get notifyOptOff => '關閉';

  @override
  String get reportFilterSortTime => '時間';

  @override
  String get mapLayerSatelliteCloudProbablyClear => '可能晴空';

  @override
  String get weatherModeThunderstorm => '雷雨';

  @override
  String get homeViewOnMap => '前往地圖察看';

  @override
  String get reportFilterIntensityInfoLegacyTitle => '舊制（2020 以前）';

  @override
  String get typhoonLabelSpeed => '過去移動時速';

  @override
  String mapAppOpenFailed(String app) {
    return '無法開啟 $app';
  }

  @override
  String get mapLayerSatelliteRgbComposite => 'RGB 合成(JMA 配方)';

  @override
  String get meshtasticReceived => '已接收';

  @override
  String get weatherRankingExtremeLow => '今日最低';

  @override
  String get mapLayerSatelliteB10 => 'ひまわり 低層水氣(B10)';

  @override
  String get mapLayerSatelliteCloudProbablyCloudy => '可能有雲';

  @override
  String get mapLayerSatelliteTransparentNoWater => '≤ 0 = 透明(無水體)';

  @override
  String get shelterCategoryLabel => '適用災害';

  @override
  String get meshtasticStateConnecting => '連線中…';

  @override
  String get moonTitle => '月亮';

  @override
  String get weatherRankingGust => '陣風';

  @override
  String get moreAppStore => 'App Store';

  @override
  String get moreServerStatus => '伺服器狀態';

  @override
  String get notifySectionWeather => '天氣';

  @override
  String get meshtasticPreset => '調變預設';

  @override
  String get dataSectionSeismic => '地震';

  @override
  String get changelogBodyEmpty => '此版本沒有說明。';

  @override
  String get changelogOpenOnGitHub => '在 GitHub 查看';

  @override
  String get radarGlobalOutline => '國界';

  @override
  String get notifyEew => '緊急地震速報';

  @override
  String get regionNationwide => '全國';

  @override
  String get moreNotifyLog => 'DPIP 通知發送記錄';

  @override
  String get regionCurrent => '所在地';

  @override
  String get meshtasticNotConnected => '尚未連線至裝置';

  @override
  String get weatherModeSnow => '下雪';

  @override
  String get mapLayerMeshtastic => 'Meshtastic 節點';

  @override
  String get moreDeveloper => '除錯資訊';

  @override
  String get mapLayerSatelliteB14 => 'ひまわり 長波紅外線(B14)';

  @override
  String get meshtasticChannelUse => '頻道使用率';

  @override
  String get mapNavLightning => '閃電';

  @override
  String get homeForecastEmpty => '目前沒有預報資料';

  @override
  String get sponsorOneTime => '單次支援';

  @override
  String get mapLayerSatelliteBtdSplit => 'ひまわり 分割視窗';

  @override
  String get onboardingPermBackground => '背景定位';

  @override
  String get aedEmergencyPhone => '緊急聯絡電話';

  @override
  String get dpmOpenInMaps => '開啟地圖';

  @override
  String get meshtasticNotifyNodes => '新節點通知';

  @override
  String get onboardingPermCriticalDesc => '讓危及生命的強震即時警報,即使在靜音或勿擾模式下也能發出聲響。';

  @override
  String get mapLayerSatelliteTransparentWarm => '晴空(暖端) = 透明,顯示底圖';

  @override
  String get meshtasticSent => '已送出';

  @override
  String get homeForecastTitle => '24小時預報';

  @override
  String get typhoonLegendWarningAreas => '警報區域';

  @override
  String meshtasticExcludeMqttHidden(int count) {
    return '已隱藏 $count 個';
  }

  @override
  String get notifyOptLocalIntensity1 => '所在地震度1以上';

  @override
  String get mapTimelinePast => '歷史';

  @override
  String get restroomTypeFemale => '女廁所';

  @override
  String get reportListToday => '今天';

  @override
  String get meshtasticTapNode => '點選節點查看詳細資訊';

  @override
  String get commonLoading => '載入中…';

  @override
  String get typhoonIntensityModerate => '中度颱風';

  @override
  String get mapLayerSatelliteAsh => 'ひまわり 火山灰';

  @override
  String get rainInterval3h => '3 時';

  @override
  String get mapLayerCategorySatellite => '衛星';

  @override
  String get meshtasticChannelReady => 'DPIP 頻道已就緒';

  @override
  String get mapLayerSatelliteNightmicrophysics => 'ひまわり 夜間微物理';

  @override
  String get typhoonIntensityTd => '熱帶性低氣壓';

  @override
  String get reportFilterDate => '日期';

  @override
  String get sponsorRestoreUnavailable => '無法連線至商店，請稍後再試';

  @override
  String homeForecastPop(String pop) {
    return '$pop%';
  }

  @override
  String get regionEmpty => '尚未新增常用地區';

  @override
  String get onboardingPermBatteryDesc => '允許 DPIP 在背景持續運作,避免警報延遲或漏收。';

  @override
  String get mapNavDisaster => '防災';

  @override
  String get radarScanRangeSubtitle => '標示四座雷達實際觀測到的範圍。';

  @override
  String get aedHoursSunday => '週日開放時間';

  @override
  String get reportDetailOriginTime => '發震時間';

  @override
  String get trendNoData => '沒有趨勢資料';

  @override
  String get onboardingPermLocation => '定位';

  @override
  String get moreDiscord => 'Discord 社群';

  @override
  String get mapNavPressure => '氣壓';

  @override
  String get mapLayerSatelliteB13 => 'ひまわり 紅外線(B13)';

  @override
  String typhoonTdNo(String no) {
    return 'TD $no';
  }

  @override
  String get changelogEmpty => '目前沒有更新日誌';

  @override
  String get reportFilterDateStartNote => '開始日：當日 00:00（臺北時間）';

  @override
  String get eewTitle => '地震速報';

  @override
  String get mapLayerWindForecastEcmwf => 'ECMWF';

  @override
  String regionSelectCount(int count, int max) {
    return '已選 $count/$max';
  }

  @override
  String get mapLayerSatelliteBtdSo2 => 'ひまわり 二氧化硫/雲相';

  @override
  String get meshtasticStateError => '錯誤';

  @override
  String get weatherModeOvercast => '陰天';

  @override
  String get reportDetailDepth => '震源深度';

  @override
  String get typhoonOverlayWarningTooltip => '標示警報區域縣市';

  @override
  String get reportFilterDatePick => '選擇日期';

  @override
  String get onboardingSkipStay => '返回授權';

  @override
  String get commonFetchFailed => '無法獲取資料,請稍後重試';

  @override
  String get shelterOutdoorLabel => '室外收容';

  @override
  String get meshtasticStateConnected => '已連線';

  @override
  String get mapNavRadar => '雷達';

  @override
  String get mapLayerSatelliteCloudClear => '晴空';

  @override
  String eewSummary(String magnitude, String depth) {
    return '規模 $magnitude・深度 $depth 公里';
  }

  @override
  String get locationBannerPermission => '尚未授權定位,無法針對你的所在地推送警報。';

  @override
  String get typhoonOverlayWeatherNoneTooltip => '不疊雷達或紅外線';

  @override
  String get radarCountyOutlineHint => '畫在回波之上';

  @override
  String get windForecastCountyOutlineHint => '繪製於風場之上';

  @override
  String get homeRainTrendTitle => '近 1 小時降水趨勢';

  @override
  String get moonPhaseFirstQuarter => '上弦月';

  @override
  String get mapLayerCategoryTyphoon => '颱風';

  @override
  String get meshtasticUtilization => '空中工時（24 小時）';

  @override
  String get restroomTypeMixed => '混合廁所';

  @override
  String get restroomGradeGood => '優等級';

  @override
  String get notifyTsunami => '海嘯資訊';

  @override
  String get navData => '資料';

  @override
  String get mapLayerSatelliteBtdWvirw => 'ひまわり 過衝雲頂';

  @override
  String get meshtasticReadingAge => '數值時間';

  @override
  String get mapAppCallFailed => '此裝置無法撥打電話';

  @override
  String get reportFilterAny => '不限';

  @override
  String get weatherRankingMergeTo => '合併至';

  @override
  String get notifyIntensity => '震度速報';

  @override
  String get rainIntervalMenu => '累積時段';

  @override
  String get reportDetailLocalFelt => '小區域有感地震';

  @override
  String get meshtasticDevice => '裝置';

  @override
  String get onboardingGrant => '授權';

  @override
  String get weatherModeRain => '雨天';

  @override
  String get shelterVulnerableOkLabel => '適合避難弱者安置';

  @override
  String get stationSheetEmpty => '點選任一測站查看觀測值';

  @override
  String get typhoonLegendProbability => '侵襲機率';

  @override
  String get reportFilterMagnitude => '規模';

  @override
  String get skyTimeMorning => '上午';

  @override
  String get experimentalFeatures => '實驗性功能';

  @override
  String get onboardingTermsBody =>
      '使用 DPIP 前,請詳閱以下注意事項:\n\n• 任何資訊應以中央氣象署發布之內容為準。\n\n• 根據網路狀態、伺服器狀態、應用程式狀態、上游資料來源狀態等,有收不到資訊的可能性,我們會盡力避免此類情況,但不保證一定不會發生。\n\n• 強烈搖晃有機率比通知早抵達使用者所在地。\n\n• 地震速報為快速計算之結果,可能存在較大誤差,應理解並謹慎使用。\n\n• 任何不被官方所認可的行為均有可能承擔法律風險,請務必遵守相關規範。\n\n此外,為提供在地化警報,本服務會在前景及背景蒐集並上傳您的概略位置與裝置推播識別碼,僅用於決定應向您推送之警報。\n\n點選下方「同意並繼續」即表示您已閱讀、理解並同意上述事項。';

  @override
  String get reportFilterTitle => '篩選';

  @override
  String get onboardingPermCritical => '重大通知';

  @override
  String trendCumulativeTotal(String total) {
    return '累計 $total mm';
  }

  @override
  String get languageName => '繁體中文(臺灣)';

  @override
  String get reportListEmptyFiltered => '沒有符合條件的地震報告';

  @override
  String get meshtasticExcludeMqtt => '隱藏 MQTT 節點';

  @override
  String get mapNavTyphoon => '颱風';

  @override
  String get weatherModeSand => '沙塵';

  @override
  String get notifyReport => '地震報告';

  @override
  String get mapAppCoordinatesCopied => '已複製座標';

  @override
  String get skyTimeNight => '夜晚';

  @override
  String get sponsorRecommended => '推薦';

  @override
  String get mapLayerSatelliteB15 => 'ひまわり 長波紅外線(B15)';

  @override
  String get weatherRankingWind => '風速';

  @override
  String get feedStale => '資料可能已過期';

  @override
  String homeForecastWind(String direction, String level) {
    return '$direction · $level 級';
  }

  @override
  String get navHome => '首頁';

  @override
  String get meshtasticRegionLabel => '地區';

  @override
  String get mapLayerSatelliteCloudtop => 'ひまわり 雲頂溫度';

  @override
  String get moonTimelineCaption => '月相';

  @override
  String get openSourceLicenses => '引用套件';

  @override
  String get weatherRankingLowest => '最低';

  @override
  String get reportFilterSortDepth => '深度';

  @override
  String mapTimelineDataTime(String time) {
    return '資料時間 $time';
  }

  @override
  String get radarScanRange => '顯示掃描範圍';

  @override
  String get meshtasticHopLimit => '跳數上限';

  @override
  String get weatherRankingExtremeHigh => '今日最高';

  @override
  String get sponsorPrivacy => '隱私權政策';

  @override
  String get reportDetailLocalIntensity => '所在地的震度';

  @override
  String get mapLayerSatelliteNaturalcolor => 'ひまわり 自然色';

  @override
  String get meshtasticAirtime => '發射佔空比';

  @override
  String shelterCapacityValue(int n) {
    return '$n 人';
  }

  @override
  String lightningLegendCc(int minutes) {
    return '雲間 · $minutes 分內';
  }

  @override
  String get meshtasticSendHint => '要廣播的訊息';

  @override
  String monitorDelay(String value) {
    return '延遲 $value s';
  }

  @override
  String get dpmNo => '否';

  @override
  String get mapLayerSatelliteB08 => 'ひまわり 上層水氣(B08)';

  @override
  String get meshtasticReconnecting => '重新連線中…';

  @override
  String get radarTownOutlineSubtitle => '讓鄉鎮界線在雷達回波下仍然清楚。';

  @override
  String get typhoonOverlayWeatherSatelliteTooltip => '紅外線（對齊颱風報文時間）';

  @override
  String get radarScanRangeHint => '框外空白代表未觀測';

  @override
  String typhoonPickerTd(String no) {
    return '熱帶性低氣壓 TD $no';
  }

  @override
  String get mapLayerSatelliteWatervapor => 'ひまわり 水氣';

  @override
  String get regionAddButton => '新增地區';

  @override
  String get regionSearchHint => '搜尋縣市';

  @override
  String get regionSearchEmpty => '找不到符合的縣市';

  @override
  String get regionSearchTownHint => '搜尋鄉鎮市區';

  @override
  String get regionSearchTownEmpty => '找不到符合的鄉鎮市區';

  @override
  String get displaySettings => '顯示設定';

  @override
  String get restroomGradePoor => '不合格';

  @override
  String get restroomCategoryTourist => '觀光地區及風景區';

  @override
  String get locationBannerServiceOff => '定位服務已關閉,無法針對你的所在地推送警報。';

  @override
  String get mapLayerStyleTooltip => '顯示樣式';

  @override
  String lightningLegendCg(int minutes) {
    return '對地 · $minutes 分內';
  }

  @override
  String get skyTimeAuto => '自動';

  @override
  String get appLogs => 'App 日誌';

  @override
  String get serverStatusLocal => '本機狀態';

  @override
  String get serverStatusLocalBody =>
      '伺服器指標來自控制台。下方是本機對多活端點（LB / Core 各區）的實際連線判斷：APP 只被動記錄本機實際播送的流量，若該端點從未被本機觸發，就會顯示未探測。';

  @override
  String get serverStatusAllUp => '所有服務正常';

  @override
  String get serverStatusDegraded => '服務效能下降';

  @override
  String get serverStatusDown => '服務異常';

  @override
  String get serverStatusErrorRate => '5xx 錯誤率';

  @override
  String get serverStatusLatency => '平均延遲';

  @override
  String get serverStatusUpdated => '更新於';

  @override
  String get serverStatusWeb => '伺服器狀態';

  @override
  String get serverStatusWebUrl => 'status.exptech.dev';

  @override
  String get serverStatusExpTech => 'ExpTech 状态';

  @override
  String get serverStatusCloudflare => 'Cloudflare 状态';

  @override
  String get serverStatusCloudflareAllOperational => '所有区域正常';

  @override
  String get serverStatusCloudflareOutage => 'Cloudflare 部分区域异常';

  @override
  String get serverStatusCloudflareNone => '目前没有可显示的区域。';

  @override
  String get serverStatusCloudflareOperational => '正常';

  @override
  String get serverStatusCloudflareDegraded => '性能下降';

  @override
  String get serverStatusCloudflarePartial => '部分中断';

  @override
  String get serverStatusCloudflareMajor => '大规模中断';

  @override
  String get serverStatusCloudflareUnknown => '未知';

  @override
  String get endpointTierLbApi => 'LB API';

  @override
  String get endpointTierLbStatic => 'LB Static';

  @override
  String get endpointTierCoreApi => 'Core API';

  @override
  String get endpointTierCoreStatic => 'Core Static';

  @override
  String get endpointTierCoreExclusiveApi => 'Core 專屬 API（雷達 / 氣象 / 風場）';

  @override
  String get endpointTierCoreStaticExclusive => 'Core 專屬靜態資源';

  @override
  String get endpointTierLegacyApi => '舊版 API（api-1）';

  @override
  String get endpointHealthOk => '本機連線正常';

  @override
  String get endpointHealthDegraded => '有端點連線不穩';

  @override
  String get endpointHealthDown => '本機連線異常';

  @override
  String get endpointHealthUnknown => '尚無觀測資料';

  @override
  String get endpointStateOk => '正常';

  @override
  String get endpointStateDegraded => '不穩';

  @override
  String get endpointStateDown => '異常';

  @override
  String get endpointStateUnknown => '未知';

  @override
  String get endpointServiceEew => '地震速報';

  @override
  String get endpointServiceRts => '強震即時警報';

  @override
  String get endpointServiceRadar => '雷達';

  @override
  String get endpointServiceSatellite => '衛星';

  @override
  String get endpointServiceQpesums => '定量降水';

  @override
  String get endpointServiceWind => '風場';

  @override
  String get endpointServiceDpm => '災害點位';

  @override
  String get endpointServiceWeather => '天氣';

  @override
  String get endpointServiceRain => '降雨';

  @override
  String get endpointServiceLightning => '閃電';

  @override
  String get endpointServiceTyphoon => '颱風';

  @override
  String get endpointServiceReport => '地震報告';

  @override
  String get endpointServiceTremStation => '震度站';

  @override
  String get endpointServiceEvent => '事件';

  @override
  String get endpointServiceLocation => '定位';

  @override
  String get endpointServiceNotify => '通知';

  @override
  String get endpointServiceOther => '其他';

  @override
  String get feedConnecting => '連線中…';

  @override
  String get notifyBannerDisabled => '通知已關閉,將收不到災害警報。';

  @override
  String get weatherHumidity => '濕度';

  @override
  String typhoonValueMs(String n) {
    return '每秒 $n 公尺';
  }

  @override
  String homeForecastHumidity(String value) {
    return '濕度 $value%';
  }

  @override
  String get meshtasticBusyBody =>
      '請先在另一個 Meshtastic App 中斷線。兩個 App 同時連同一台裝置會互相搶走訊息，導致部分訊息遺失。';

  @override
  String get meshtasticChannelNoSlot => '沒有可用的頻道空位 — 請先在裝置上空出一個';

  @override
  String get restroomCategoryTransport => '交通';

  @override
  String get meshtasticBattery => '電量';

  @override
  String get meshtasticDistance => '距離';

  @override
  String get meshtasticSnrTrend => '訊號趨勢 (SNR)';

  @override
  String get meshtasticBatteryTrend => '電量趨勢';

  @override
  String get typhoonOverlayMenuTooltip => '颱風圖層選項';

  @override
  String get mapLayerSatelliteBtdOzone => 'ひまわり 對流層頂';

  @override
  String meshtasticRegionMismatch(String region) {
    return '裝置地區為 $region — DPIP 需要 TW';
  }

  @override
  String get notifySectionEarthquake => '地震';

  @override
  String get mapLayerDisasterMap => '防災地圖';

  @override
  String get weatherModeFog => '大霧';

  @override
  String typhoonPickerNamed(String no, String name) {
    return '$name TY $no';
  }

  @override
  String get mapLayerStyleGrayTooltip => '氣象廳灰階慣例：溫度越低越白';

  @override
  String get moreAnnouncements => '公告';

  @override
  String get moreTagline => '防災資訊整合平台';

  @override
  String get moreVersionStable => '正式版';

  @override
  String get moreVersionNotes => '本次更新';

  @override
  String get moreVersionNotesHighlightsSubtitle => '這個版本做了哪些改變';

  @override
  String releaseHighlightsTitle(Object train) {
    return '$train 重點整理';
  }

  @override
  String get releaseHighlightsTabNormal => '做了哪些改變';

  @override
  String get releaseHighlightsTabAdvanced => '深入技術';

  @override
  String get releaseHighlightsEmpty => '目前沒有內容。';

  @override
  String get releaseHighlightsSeeNotes => '查看完整更新日誌';

  @override
  String get moreVersionNotesEmpty => '找不到目前版本的更新日誌';

  @override
  String get reportNotFound => '找不到這份地震報告';

  @override
  String get moreVersionSnapshot => '測試版';

  @override
  String get mapLayerSatelliteTransparentNoData => '無資料(陸地) = 透明';

  @override
  String get restroomCategoryGovernment => '民眾洽公場所';

  @override
  String get typhoonLegendCurrent => '目前中心';

  @override
  String get aedAddress => '地址';

  @override
  String get mapLayerAed => 'AED';

  @override
  String get changelogTypePrerelease => '測試版';

  @override
  String get reportFilterIntensityInfoModernBody =>
      '震度為 0–4、5弱、5強、6弱、6強、7。篩選滑桿依新制；列表中較早的地震會以舊制標示顯示。';

  @override
  String get typhoonOverlayWeatherNone => '無';

  @override
  String get mapLayerStyleGray => '灰階（JMA）';

  @override
  String get weatherModeAuto => '自動';

  @override
  String get typhoonLabelProbCircle => '70%機率圓';

  @override
  String get notifyOptAll => '接收全部';

  @override
  String get displayTheme => '主題';

  @override
  String get mapLayerSatelliteB07 => 'ひまわり 短波紅外(B07)';

  @override
  String get typhoonLabelDirection => '過去移動方向';

  @override
  String get regionManageTitle => '常用地區';

  @override
  String get regionSaveNote =>
      '通知是以 GPS 所在地位置發送的，設定常用地區不會改變或影響通知發送，常用地區只是用於首頁快速查看不同區域狀態，所以務必授予 GPS 定位權限，否則通知無法運作';

  @override
  String get typhoonLegendCone => '預測圓錐';

  @override
  String get moreCwaEew => '中央氣象署強震即時警報';

  @override
  String get onboardingPermsTitle => '權限授權';

  @override
  String get mapLayerStyleJma => '雲頂強調（JMA）';

  @override
  String get rainInterval10m => '10 分';

  @override
  String get meshtasticConnectAnyway => '仍要連線';

  @override
  String reportListDayCount(int count) {
    return '$count';
  }

  @override
  String get mapLayerSatelliteB06 => 'ひまわり 近紅外(B06)';

  @override
  String get mapLayerSatelliteTransparentReflectance => '低反射率/夜間 = 透明,顯示底圖';

  @override
  String chartHourLabel(int hour) {
    return '$hour時';
  }

  @override
  String get mapLayerShelter => '避難收容場所';

  @override
  String get typhoonOverlayProbabilityTooltip => '顯示侵襲機率（會隱藏預測圓錐）';

  @override
  String get mapLayerSatelliteNdwi => 'ひまわり 水體指數';

  @override
  String get disasterMapOverlayShelterTooltip => '顯示避難收容場所';

  @override
  String get mapNavHumidity => '濕度';

  @override
  String get reportDetailSortByIntensity => '依震度排序';

  @override
  String get homeRainTrendNoData => '無資料';

  @override
  String get mapLayerCategoryRadar => '雷達';

  @override
  String get meshtasticShortName => '簡稱';

  @override
  String get mapLayerSatelliteAirmass => 'ひまわり 氣團';

  @override
  String get dataSectionWeather => '氣象';

  @override
  String get aedHoursWeekday => '平日開放時間';

  @override
  String get homeActiveEventsTitle => '生效中事件';

  @override
  String get faq => '常見問題';

  @override
  String eewSerial(int serial) {
    return '第 $serial 報';
  }

  @override
  String get reportFilterSort => '排序方式';

  @override
  String get meshtasticRegionConfirm =>
      '要將這台裝置切換為 TW 地區嗎？裝置會重新啟動並短暫斷線，上面的其他頻道也會一起改變。';

  @override
  String get dataEarthquakeSubtitle => '地震報告';

  @override
  String get typhoonNoActive => '目前無颱風';

  @override
  String get mapLayerSatelliteB11 => 'ひまわり 二氧化硫/雲相(B11)';

  @override
  String get navEvents => '事件';

  @override
  String get onboardingTermsTitle => '服務條款';

  @override
  String get mapOsmOverlay => '詳細地圖';

  @override
  String get mapOsmOverlayHint => '顯示更完整的道路、建物與地名';

  @override
  String get mapOsmDetails => '詳細設定';

  @override
  String get moreDataSources => '資料來源';

  @override
  String get dataSourceTremNet => '探索智慧科技有限公司 — TREM-Net';

  @override
  String get dataSourceCwa => '交通部中央氣象署 (CWA)';

  @override
  String get dataSourceJma => '気象庁 (JMA)';

  @override
  String get dataSourceNcdr => '國家災害防救科技中心 (NCDR)';

  @override
  String get dataSourceEcmwf =>
      'European Centre for Medium-Range Weather Forecasts (ECMWF)';

  @override
  String get dataSourceNoaaGfs =>
      'National Oceanic and Atmospheric Administration / National Centers for Environmental Prediction — Global Forecast System (NOAA/NCEP GFS)';

  @override
  String get dataSourceGovernmentOpenData => '政府資料開放平臺';

  @override
  String get dataSourceOpenStreetMap => '© OpenStreetMap contributors';

  @override
  String get dataSourceNasaMoon =>
      'National Aeronautics and Space Administration / Goddard Space Flight Center Scientific Visualization Studio — CGI Moon Kit (NASA/GSFC SVS)';

  @override
  String mapOsmDetailsHint(int enabled, int total) {
    return '已啟用 $enabled / 共 $total 個圖層';
  }

  @override
  String get mapOsmSurface => '地表';

  @override
  String get mapOsmParks => '公園';

  @override
  String get mapOsmLandUse => '土地利用';

  @override
  String get mapOsmAirportAreas => '機場區域';

  @override
  String get mapOsmWater => '水域';

  @override
  String get mapOsmRivers => '河川';

  @override
  String get mapOsmBoundaries => '邊界';

  @override
  String get mapOsmBuildings => '建物';

  @override
  String get mapOsmRoads => '道路';

  @override
  String get mapOsmRoadNames => '道路名稱';

  @override
  String get mapOsmWaterNames => '水域名稱';

  @override
  String get mapOsmPeaks => '山峰';

  @override
  String get mapOsmAirportNames => '機場名稱';

  @override
  String get mapOsmPlaceNames => '地名';

  @override
  String get mapOsmPoi => '地標';

  @override
  String get mapOsmHouseNumbers => '門牌號碼';

  @override
  String get mapOsmRestoreAll => '全部恢復';

  @override
  String get mapOsmSectionNatural => '地表與自然';

  @override
  String get mapOsmSectionRoadsAndBuildings => '道路與建物';

  @override
  String get mapOsmSectionLabelsAndPlaces => '地名與標示';

  @override
  String get mapTownLabels => '鄉鎮名稱';

  @override
  String get notifySetFailed => '設定失敗，請稍後再試。';

  @override
  String get meshtasticDisconnect => '斷線';

  @override
  String get meshtasticUndecoded => '無法解密';

  @override
  String get notifyAnnouncement => '公告';

  @override
  String get onboardingIntroTitle => '歡迎使用 DPIP';

  @override
  String get regionCurrentUnavailable => '無法取得所在地位置資訊';

  @override
  String get languageSystem => '系統預設';

  @override
  String get skyTimeSunset => '日落';

  @override
  String get mapLayerSatelliteDust => 'ひまわり 沙塵';

  @override
  String get mapAppAppleMaps => 'Apple Maps';

  @override
  String get regionEdit => '修改';

  @override
  String get weatherDynamicState => '天氣動態狀態';

  @override
  String get moonNow => '現在';

  @override
  String get moonSectionAppearance => '外觀';

  @override
  String get moonSectionRiseSet => '月出月沒';

  @override
  String get moonSectionUpcoming => '接下來';

  @override
  String get moonSectionCalendar => '月曆';

  @override
  String get moonDistance => '距離';

  @override
  String get moonKilometres => '公里';

  @override
  String get moonApparentSize => '視直徑';

  @override
  String get moonRise => '月出';

  @override
  String get moonSet => '月沒';

  @override
  String get moonNextNewMoon => '下次新月';

  @override
  String get moonAlwaysUp => '整日在地平線上';

  @override
  String get moonNoEvent => '當日無';

  @override
  String get sunTitle => '太陽';

  @override
  String get sunSectionDaylight => '日照';

  @override
  String get sunSectionTwilight => '曙暮光';

  @override
  String get sunSectionLight => '光線';

  @override
  String get sunSectionSundial => '日晷';

  @override
  String get sunSectionTerms => '節氣';

  @override
  String get sunRise => '日出';

  @override
  String get sunSet => '日沒';

  @override
  String get sunNoon => '正午';

  @override
  String get sunDayLength => '白晝長度';

  @override
  String get sunTwilightCivil => '民用';

  @override
  String get sunTwilightNautical => '航海';

  @override
  String get sunTwilightAstronomical => '天文';

  @override
  String get sunGoldenHourMorning => '晨間黃金時刻';

  @override
  String get sunGoldenHourEvening => '昏間黃金時刻';

  @override
  String get sunBlueHour => '藍調時刻';

  @override
  String get sunEquationOfTime => '均時差';

  @override
  String get sunMinutes => '分';

  @override
  String get solarTermNext => '下一個節氣';

  @override
  String get planetsTitle => '行星';

  @override
  String get planetsSectionTonight => '此刻';

  @override
  String get planetUp => '地平線上';

  @override
  String get planetDown => '地平線下';

  @override
  String get planetInGlare => '太近太陽';

  @override
  String get planetMagnitude => '亮度';

  @override
  String get planetElongation => '距日距角';

  @override
  String get planetSky => '時段';

  @override
  String get planetEvening => '昏星';

  @override
  String get planetMorning => '晨星';

  @override
  String get planetDistance => '距離';

  @override
  String get planetAu => '天文單位';

  @override
  String get planetAltitude => '仰角';

  @override
  String get planetMercury => '水星';

  @override
  String get planetVenus => '金星';

  @override
  String get planetMars => '火星';

  @override
  String get planetJupiter => '木星';

  @override
  String get planetSaturn => '土星';

  @override
  String get planetUranus => '天王星';

  @override
  String get planetNeptune => '海王星';

  @override
  String get solarTermVernalEquinox => '春分';

  @override
  String get solarTermPureBrightness => '清明';

  @override
  String get solarTermGrainRain => '穀雨';

  @override
  String get solarTermStartOfSummer => '立夏';

  @override
  String get solarTermGrainFull => '小滿';

  @override
  String get solarTermGrainInEar => '芒種';

  @override
  String get solarTermSummerSolstice => '夏至';

  @override
  String get solarTermMinorHeat => '小暑';

  @override
  String get solarTermMajorHeat => '大暑';

  @override
  String get solarTermStartOfAutumn => '立秋';

  @override
  String get solarTermEndOfHeat => '處暑';

  @override
  String get solarTermWhiteDew => '白露';

  @override
  String get solarTermAutumnalEquinox => '秋分';

  @override
  String get solarTermColdDew => '寒露';

  @override
  String get solarTermFrostDescent => '霜降';

  @override
  String get solarTermStartOfWinter => '立冬';

  @override
  String get solarTermMinorSnow => '小雪';

  @override
  String get solarTermMajorSnow => '大雪';

  @override
  String get solarTermWinterSolstice => '冬至';

  @override
  String get solarTermMinorCold => '小寒';

  @override
  String get solarTermMajorCold => '大寒';

  @override
  String get solarTermStartOfSpring => '立春';

  @override
  String get solarTermRainWater => '雨水';

  @override
  String get solarTermAwakeningOfInsects => '驚蟄';

  @override
  String get tonightTitle => '今夜';

  @override
  String get tonightSectionDark => '觀測窗口';

  @override
  String get tonightAstronomicalNight => '天文夜';

  @override
  String get tonightNeverDark => '整夜不全暗';

  @override
  String get tonightDarkWindow => '暗窗';

  @override
  String get tonightMoonAllNight => '月亮整夜在天上';

  @override
  String get tonightDarkTotal => '總暗時';

  @override
  String get tonightMoonlight => '月光';

  @override
  String get tonightSectionShowers => '流星雨';

  @override
  String get tonightRadiantDown => '輻射點不升起';

  @override
  String get tonightPerHour => '顆/時';

  @override
  String get tonightSectionSatellites => '衛星過境';

  @override
  String get tonightSectionTargets => '此刻可觀測目標';

  @override
  String get showerQuadrantids => '象限儀座';

  @override
  String get showerLyrids => '天琴座';

  @override
  String get showerEtaAquariids => '寶瓶座η';

  @override
  String get showerDeltaAquariids => '寶瓶座δ';

  @override
  String get showerPerseids => '英仙座';

  @override
  String get showerOrionids => '獵戶座';

  @override
  String get showerSouthernTaurids => '金牛座南';

  @override
  String get showerLeonids => '獅子座';

  @override
  String get showerGeminids => '雙子座';

  @override
  String get showerUrsids => '小熊座';

  @override
  String get deepSkyOpenCluster => '疏散星團';

  @override
  String get deepSkyGlobularCluster => '球狀星團';

  @override
  String get deepSkySpiralGalaxy => '螺旋星系';

  @override
  String get deepSkyEllipticalGalaxy => '橢圓星系';

  @override
  String get deepSkyIrregularGalaxy => '不規則星系';

  @override
  String get deepSkyPlanetaryNebula => '行星狀星雲';

  @override
  String get deepSkySupernovaRemnant => '超新星遺跡';

  @override
  String get deepSkyEmissionNebula => '發射星雲';

  @override
  String get deepSkyReflectionNebula => '反射星雲';

  @override
  String get deepSkyAsterism => '星群';

  @override
  String get almanacTitle => '曆法';

  @override
  String get almanacSectionToday => '今日';

  @override
  String get almanacGregorian => '西曆';

  @override
  String get almanacLunar => '農曆';

  @override
  String get almanacYear => '歲次';

  @override
  String get almanacMonthLength => '月大小';

  @override
  String get almanacLongMonth => '三十日';

  @override
  String get almanacShortMonth => '二十九日';

  @override
  String get almanacLeapPrefix => '閏';

  @override
  String get almanacSectionLunarEclipses => '月食';

  @override
  String get almanacSectionSolarEclipses => '日食';

  @override
  String get almanacNoSolarEclipse => '範圍內無';

  @override
  String get eclipseTotal => '全食';

  @override
  String get eclipsePartial => '偏食';

  @override
  String get eclipseAnnular => '環食';

  @override
  String get eclipsePenumbral => '半影食';

  @override
  String get zodiacRat => '鼠';

  @override
  String get zodiacOx => '牛';

  @override
  String get zodiacTiger => '虎';

  @override
  String get zodiacRabbit => '兔';

  @override
  String get zodiacDragon => '龍';

  @override
  String get zodiacSnake => '蛇';

  @override
  String get zodiacHorse => '馬';

  @override
  String get zodiacGoat => '羊';

  @override
  String get zodiacMonkey => '猴';

  @override
  String get zodiacRooster => '雞';

  @override
  String get zodiacDog => '狗';

  @override
  String get zodiacPig => '豬';

  @override
  String get tideTitle => '潮汐';

  @override
  String get tideDisclaimer => '僅為天文引潮力，非港口潮汐表。水位請參考氣象署公布之潮汐預報。';

  @override
  String get tideSectionNow => '此刻';

  @override
  String get tidePhase => '週期';

  @override
  String get tideSpring => '大潮';

  @override
  String get tideNeap => '小潮';

  @override
  String get tideMiddling => '中潮';

  @override
  String get tideLunarDistanceFactor => '月球引力';

  @override
  String get tideEquilibrium => '平衡潮高';

  @override
  String get tideMetres => '公尺';

  @override
  String get tidePerigeanSpring => '下次近地點大潮';

  @override
  String get tideSectionTurningPoints => '轉折點';

  @override
  String get tideHigh => '高';

  @override
  String get tideLow => '低';

  @override
  String get skyChartTitle => '星圖';

  @override
  String get skyChartNorth => '北';

  @override
  String get skyChartEast => '東';

  @override
  String get skyChartSouth => '南';

  @override
  String get skyChartWest => '西';

  @override
  String tonightElementAge(int days) {
    return '軌道資料 $days 天前';
  }

  @override
  String almanacLunarDate(String leap, int month, int day) {
    return '$leap$month 月 $day 日';
  }

  @override
  String get tonightNoShowers => '目前無流星雨';

  @override
  String get tonightNoPasses => '48 小時內無可見過境';

  @override
  String get tonightSatellitesUnavailable => '無法讀取軌道資料';

  @override
  String get tonightNoTargets => '無足夠高度的目標';

  @override
  String get skyChartUnavailable => '無法讀取星表';

  @override
  String get permissionSettingsTitle => '請到系統設定開啟';

  @override
  String get permissionSettingsHint => '返回 App 後會自動重新檢查。';

  @override
  String get permissionOpenSettings => '前往設定';

  @override
  String permissionSettingsMessage(String what) {
    return '「$what」已被拒絕，系統不會再詢問。請到設定中開啟。';
  }

  @override
  String get permissionGuideNotification => '請到系統設定中開啟通知權限。';

  @override
  String get permissionGuideForegroundLocation => '請到系統設定中開啟精確位置權限。';

  @override
  String permissionGuideBackgroundLocation(Object option) {
    return '請在「$option」中改為「允許所有時間」。';
  }

  @override
  String get permissionGuideBackgroundExecution =>
      '請到系統設定中允許背景執行,避免收到通知時被系統暫停。';

  @override
  String get permissionGuideUnusedPause => '若應用程式被標記為「未使用」,請在系統設定中改為「允許」。';

  @override
  String get permissionGuideUnusedFreeSpace => '若應用程式因暫存空間不足被暫停,請清除暫存後重新開啟。';

  @override
  String get permissionGuideUnusedRevoke => '若應用程式權限被撤銷,請在系統設定中重新授予。';

  @override
  String get permissionGuideUnusedPlayProtect =>
      '若被 Play 保護機制暫停,請到 Google Play 中檢查應用程式狀態。';

  @override
  String permissionGuideVendorPower(Object vendor) {
    return '請到「$vendor」的省電設定中,將本應用程式設為「不限制」。';
  }

  @override
  String get permissionStillRequired => '仍然需要此權限,請到設定中開啟。';

  @override
  String get permissionVerifyManually => '請手動確認此權限已在系統設定中開啟。';

  @override
  String get permissionBackgroundLocationOption => '「允許所有時間」';

  @override
  String get displayTextSize => '文字大小';

  @override
  String get displayTextSizeDesc => '只影響 App 介面，地圖上的文字大小不變。';

  @override
  String get displayTextWeight => '文字粗細';

  @override
  String get displayTextWeightDesc => '較粗的文字通常更容易閱讀。';

  @override
  String get displayContrast => '對比度';

  @override
  String get displayContrastDesc => '對比越高，文字與背景的差異越明顯。';

  @override
  String get displayColorVision => '色覺調整';

  @override
  String get displayColorVisionDesc => '整個 App 的顏色都會重新調整，地圖也一併改變。';

  @override
  String get displayColorVisionNone => '標準色彩';

  @override
  String get displayColorVisionProtan => '紅色弱';

  @override
  String get displayColorVisionDeutan => '綠色弱';

  @override
  String get displayColorVisionTritan => '藍黃色弱';

  @override
  String get displayPreviewSample => '地震報告範例';

  @override
  String get displayScaleSmall => '小';

  @override
  String get displayScaleDefault => '標準';

  @override
  String get displayScaleLarge => '大';

  @override
  String get displayScaleHuge => '特大';

  @override
  String get displayWeightNormal => '標準';

  @override
  String get displayWeightMedium => '中等';

  @override
  String get displayWeightBold => '粗體';

  @override
  String get displayContrastStandard => '標準';

  @override
  String get displayContrastMedium => '中等';

  @override
  String get displayContrastHigh => '高';

  @override
  String get meshtasticDirect => '直連';

  @override
  String meshtasticHopsAway(int n) {
    return '$n 跳';
  }

  @override
  String get meshtasticStatRelayShare => '為他人轉發';

  @override
  String get meshtasticStatRelayShareHint => '佔本機發送量的比例';

  @override
  String get meshtasticStatRelayValue => '轉發成功率';

  @override
  String get meshtasticStatRelaySolePath => '經常是唯一路徑 — 網路依賴此節點';

  @override
  String get meshtasticStatRelayRedundant => '其他節點也覆蓋同樣路徑';

  @override
  String get meshtasticStatRedundancy => '重複接收';

  @override
  String get meshtasticStatThinEdge => '備援路徑少 — 一個中繼失效就可能斷線';

  @override
  String get meshtasticStatWellCovered => '有多條路徑可達';

  @override
  String get meshtasticStatErrorRate => '接收錯誤率';

  @override
  String get meshtasticStatErrorRateHint => '空中時間不變卻升高 = 干擾';

  @override
  String get meshtasticTraceRoute => '追蹤路由';

  @override
  String get meshtasticTracing => '追蹤中…';

  @override
  String get meshtasticTraceUnreadable => '無法解讀的回覆';

  @override
  String get meshtasticTraceOffline => '未連線至電台';

  @override
  String get meshtasticTraceCooldown => '電台限制每 30 秒一次';

  @override
  String get meshtasticTraceNoReply => '沒有回應 — 超出範圍或金鑰不同';

  @override
  String get meshtasticTraceDirect => '直達 — 中間無中繼';

  @override
  String meshtasticTraceHops(int n) {
    return '$n 跳';
  }

  @override
  String get moreDumpDiagnostics => '傾印除錯資訊及日誌';

  @override
  String get moreDumpDiagnosticsHint => '上傳後複製連結';

  @override
  String get dumpIncludeSensitive => '包含精確位置';

  @override
  String get dumpIncludeSensitiveHint => '包含日誌與背景定位中的座標；未勾選時會以 null 取代';

  @override
  String get dumpUpload => '上傳';

  @override
  String get dumpUploaded => '已上傳';

  @override
  String get dumpLinkCopied => '連結已複製到剪貼簿';

  @override
  String get dumpCopyAgain => '再複製一次';

  @override
  String get dumpUploadFailed => '上傳失敗，請稍後再試';

  @override
  String get statusLegendUnprobed => '未探測';

  @override
  String get statusLegendUnsupported => '不支援';

  @override
  String get rainScaleSection => '色階間距';

  @override
  String get rainScaleFine => '小間距';

  @override
  String get rainScaleCoarse => '大間距';

  @override
  String get notifyTestTitle => '測試通知';

  @override
  String get notifyTestIntro => '點一下就會實際發送該則警報。重大警報會以最大音量播放，並穿透靜音與勿擾模式。';

  @override
  String get notifyTestCriticalDenied => '這台裝置未允許「重要警告」，重大警報在靜音時同樣不會發出聲音。';

  @override
  String get notifyTestPermissionOff => '通知已關閉，測試不會有任何反應。';

  @override
  String get notifyTestBehaviourOverrides => '會穿透靜音與勿擾模式';

  @override
  String get notifyTestBehaviourAlerts => '有聲音並跳出橫幅，但手機靜音時不會響';

  @override
  String get notifyTestBehaviourSounds => '有聲音、不跳出橫幅，手機靜音時不會響';

  @override
  String get notifyTestBehaviourSilent => '無聲，只出現在通知中心';

  @override
  String get notifyTestFailed => '無法發送測試通知。';

  @override
  String get moreBugReports => '已回报的错误';

  @override
  String get bugTrackerEmpty => '还没有已回报的错误';

  @override
  String get bugTrackerReplies => '回复';

  @override
  String get bugTrackerGoToDiscord => '找不到你的问题？快前往 Discord 回报！';

  @override
  String get bugTrackerNoMatch => '没有符合所选标签的错误回报';

  @override
  String get bugTrackerDeveloper => '开发人员';

  @override
  String get bugTrackerCannotDisplay => '无法显示此内容，请在 Discord 上查看';

  @override
  String get bugTrackerJoinDiscussion => '至 Discord 参与讨论';

  @override
  String get bugTrackerSortLast => '最后讨论';

  @override
  String get bugTrackerSortMostDiscussed => '最多讨论';

  @override
  String get bugTrackerStaff => '工作人员';

  @override
  String eewSpokenLocalIntensity(String intensity) {
    return '所在地預估震度，$intensity。';
  }

  @override
  String eewSpokenMaxIntensity(String intensity) {
    return '預估最大震度，$intensity。';
  }
}

/// The translations for Chinese, using the Han script (`zh_Hans`).
class AppLocalizationsZhHans extends AppLocalizationsZh {
  AppLocalizationsZhHans() : super('zh_Hans');

  @override
  String typhoonValueLat(String lat) {
    return '北纬 $lat 度';
  }

  @override
  String get onboardingSkipBody =>
      '未授权定位与通知,DPIP 将无法实时通知你所在地的地震与灾害。你仍可稍后在设置中开启。';

  @override
  String get rainInterval24h => '24 时';

  @override
  String homeRainTrendHeavyStopping(int minutes) {
    return '预计 $minutes 分钟后停止下大雨';
  }

  @override
  String get mapTimelineObserved => '观测';

  @override
  String get mapTimelineScrubPaused => '拖动过快，帧更新已暂停；放慢速度即可恢复。';

  @override
  String get regionSelectTitle => '选择地区';

  @override
  String get skyTimeNoon => '正午';

  @override
  String get radarCountyOutlineSubtitle => '让县市界线在雷达回波下仍然清楚。';

  @override
  String get mapLayerSatelliteB03 => 'ひまわり 可见光-红(B03)';

  @override
  String get reportFilterIntensity => '震度';

  @override
  String get mapLayerLightning => '闪电';

  @override
  String get restroomTypeMale => '男厕所';

  @override
  String get meshtasticLastReceived => '最近接收';

  @override
  String get reportDetailSortByCounty => '依县市排序';

  @override
  String get onboardingPermUnusedApp => '保持 App 启用';

  @override
  String get onboardingPermUnusedAppDesc =>
      'Android 会暂停你长期未开启的 App 并撤销其权限，这会让灾害警报无法送达你所在地。';

  @override
  String get onboardingPermBackgroundExec => '后台执行';

  @override
  String get onboardingPermBackgroundExecDesc => '关闭时，App 不会被唤醒回报你的位置。';

  @override
  String get onboardingPermVendorPower => '手机厂商省电设置';

  @override
  String onboardingPermVendorPowerDesc(String brand) {
    return '$brand 会停止你最近没开过的 App 的后台作业。App 无法检测或更改，请手动允许。';
  }

  @override
  String get homeRainTrendScattered => '可能会有零星降雨';

  @override
  String get meshtasticUptime => '运行时间';

  @override
  String get weatherRankingTempExtremes => '温度极值';

  @override
  String get themeLight => '浅色';

  @override
  String get mapTerrainReliefHint => '在底图上显示立体地形阴影';

  @override
  String get meshtasticEmptyMessage => '（空白讯息）';

  @override
  String get moreSectionRegion => '地区';

  @override
  String get mapLayerSatellite => 'ひまわり 红外线(B13)';

  @override
  String get aedHoursSaturday => '周六开放时间';

  @override
  String get moonPhaseNew => '新月';

  @override
  String get notifySectionEew => '地震预警';

  @override
  String get mapResetNorth => '回到正北';

  @override
  String get rainInterval2d => '2 日';

  @override
  String get mapTownLabelsHint => '放大时显示乡镇名称';

  @override
  String get commonCancel => '取消';

  @override
  String get notifyOptTsunamiWarning => '仅接收海啸警报';

  @override
  String get mapLayerSatelliteBtdFog => 'ひまわり 夜间雾';

  @override
  String get moreSectionAdvanced => '高级';

  @override
  String get moreSectionMesh => 'Mesh 网络';

  @override
  String get weatherRankingExtremeRange => '日温差';

  @override
  String get permissionsTitle => '权限检查';

  @override
  String get permissionsAttention => '权限需要处理';

  @override
  String get permissionsBody => 'DPIP 需要这些权限才能即时通知你。收不到警报时，通常就是其中一项尚未开启。';

  @override
  String get notifySettingsMenu => '通知设置';

  @override
  String mapAppDefault(String app) {
    return '$app（默认）';
  }

  @override
  String get trendRange24h => '24 小时';

  @override
  String get mapLayerStyleJmaTooltip => '灰阶为底，−40 °C 以下上色，凸显云顶高度';

  @override
  String get mapLayerRain => '雨量';

  @override
  String get mapLayerQpesums => '未来 1 小时降水预报';

  @override
  String get mapOverlaySectionMap => '地图';

  @override
  String get mapTerrainRelief => '地形立体感';

  @override
  String get mapLegendCollapse => '收起图例';

  @override
  String get updateAvailableTitle => '有新版本';

  @override
  String updateAvailableBody(String version) {
    return '新版本 $version 已发布。';
  }

  @override
  String get updateSkip => '略过此次';

  @override
  String get updateViewChangelog => '前往查看';

  @override
  String get updateOpenAppStore => 'App Store';

  @override
  String get updateOpenTestFlight => 'TestFlight';

  @override
  String get updateOpenPlayStore => 'Play 商店';

  @override
  String get updateDownload => '下载更新';

  @override
  String get changelogShowSnapshots => '显示测试版';

  @override
  String get changelogTitle => '更新日志';

  @override
  String get reportFilterOrderDesc => '降序';

  @override
  String get meshtasticExcludeMqttSubtitle => '经互联网桥接、并非无线电听到的节点';

  @override
  String get reportFilterIntensityInfoTitle => '震度新制与旧制';

  @override
  String get mapLayerTyphoon => '台风';

  @override
  String get radarOverlayMenuTooltip => '雷达图层选项';

  @override
  String get meshtasticNodes => '節點';

  @override
  String get meshtasticSend => '傳送';

  @override
  String get typhoonOverlayStormL7Tooltip => '七级风风场 + 平均圆（紫）';

  @override
  String get aedType => '场所类型';

  @override
  String get termsOfService => '服务条款';

  @override
  String get typhoonLegendCircle25 => '十级风暴风圈';

  @override
  String get sponsorTitle => '支持 DPIP';

  @override
  String get mapNavSatellite => '卫星';

  @override
  String homeRainTrendUpdated(String time) {
    return '更新 $time';
  }

  @override
  String get onboardingNext => '下一步';

  @override
  String get weatherRankingMergeTown => '乡镇';

  @override
  String get mapLayerMonitor => '强震监视器';

  @override
  String get moreYoutube => 'YouTube';

  @override
  String get sponsorSubscriptions => '订阅制';

  @override
  String typhoonValueLon(String lon) {
    return '东经 $lon 度';
  }

  @override
  String get skyTime => '天空时间';

  @override
  String get weatherModeCloudy => '多云';

  @override
  String get skyTimeDusk => '暮色';

  @override
  String get meshtasticFirmware => '固件';

  @override
  String get reportFilterDateEndNote => '结束日：当日 24:00（台北时间）';

  @override
  String get reportFilterSortMagnitude => '规模';

  @override
  String get meshtasticSilent => '已静默';

  @override
  String get mapLayerCategoryEarthquake => '地震';

  @override
  String get mapLayerSatelliteB12 => 'ひまわり 臭氧(B12)';

  @override
  String get restroomCategoryOther => '其他';

  @override
  String homeForecastHighLow(String high, String low) {
    return '高 $high° · 低 $low°';
  }

  @override
  String get locationBannerFix => '打开设置';

  @override
  String get mapLegendExpand => '图例';

  @override
  String get eewNone => '当前没有地震预警';

  @override
  String typhoonTyNo(String no) {
    return 'TY $no';
  }

  @override
  String get notifyOptTsunamiAll => '海啸消息、海啸警报';

  @override
  String get meshtasticLayerOptions => '节点选项';

  @override
  String get onboardingAgreeContinue => '同意并继续';

  @override
  String get commonRetry => '重试';

  @override
  String get meshtasticNodeId => '节点 ID';

  @override
  String reportDetailNumbered(String number) {
    return '编号 $number 显著有感地震';
  }

  @override
  String get typhoonOverlayStormBandSubtitle => '含平均圆';

  @override
  String get disasterMapOverlayRestroomTooltip => '显示公厕';

  @override
  String get weatherRankingTitle => '观测排行';

  @override
  String get homeRainTrendHeavySustained => '未来 1 小时会有持续大雨';

  @override
  String get notifySectionTsunami => '海啸';

  @override
  String get restroomCategoryPark => '公园';

  @override
  String get moreLinkOpenFailed => '无法打开链接';

  @override
  String get themeDark => '深色';

  @override
  String get sponsorRestore => '恢复购买';

  @override
  String get meshtasticChannelWorking => '正在设定 DPIP 频道…';

  @override
  String get meshtasticRegionSwitch => '切换为 TW';

  @override
  String get meshtasticTraffic => '流量';

  @override
  String get mapLayerStyleBdTooltip => 'Dvorak BD 曲线——热带气旋强度分析的阶梯灰度';

  @override
  String get disasterMapOverlayAedTooltip => '显示 AED 位置';

  @override
  String get mapLayerHumidity => '湿度';

  @override
  String get mapLayerSatelliteTransparentNight => '夜间 = 透明,显示底图';

  @override
  String get meshtasticScanning => '掃描中…';

  @override
  String regionSelectFull(int max) {
    return '最多只能选择 $max 个地区';
  }

  @override
  String get meshtasticNewMessages => '新消息';

  @override
  String get meshtasticBatteryHistory => '电量历史';

  @override
  String get meshtasticStatAvg => '平均';

  @override
  String get meshtasticStatPeak => '峰值';

  @override
  String get meshtasticStatDrain => '掉电';

  @override
  String get meshtasticStatEta => '预估可用';

  @override
  String get meshtasticStatFull => '充满';

  @override
  String get meshtasticStatTrend => '趋势';

  @override
  String get meshtasticStatCharging => '充电中';

  @override
  String get meshtasticStatStable => '稳定';

  @override
  String get meshtasticNodesTotal => '已知';

  @override
  String get meshtasticNodesOnline => '在线';

  @override
  String get meshtasticRx => '接收';

  @override
  String get meshtasticTx => '发送';

  @override
  String get meshtasticNodesHistory => '节点数历史';

  @override
  String get meshtasticTrafficHistory => '流量历史';

  @override
  String meshtasticEtaHours(int n) {
    return '约 $n 小时';
  }

  @override
  String meshtasticEtaDays(int n) {
    return '约 $n 天';
  }

  @override
  String get meshtasticTitle => 'Meshtastic';

  @override
  String get navMore => '更多';

  @override
  String get meshtasticDpipChannel => 'DPIP 频道';

  @override
  String get disasterMapOverlaySectionLayers => '图层';

  @override
  String get mapLayerSatelliteB05 => 'ひまわり 近红外(B05)';

  @override
  String get typhoonLabelNe => '东北侧';

  @override
  String get meshtasticCopied => '已复制讯息';

  @override
  String get reportListEmpty => '当前没有地震报告';

  @override
  String get reportListEnd => '已到最后一页';

  @override
  String get mapLayerSatelliteTruecolor => 'ひまわり 真彩色';

  @override
  String get typhoonOverlaySectionExtra => '叠加层';

  @override
  String get eewSWave => '震波';

  @override
  String get meshtasticBusyTitle => '另一个 App 正在使用这台设备';

  @override
  String get restroomCategoryCultural => '文化育乐活动场所';

  @override
  String get typhoonLabelWind => '近中心最大风速';

  @override
  String get radarGlobalOutlineHint => '各国国界外框';

  @override
  String get notifyEvacuation => '防灾信息';

  @override
  String get typhoonLegendCircle15 => '七级风暴风圈';

  @override
  String get dataSectionAstronomy => '天文';

  @override
  String get homeRainTrendLightSustained => '未来 1 小时会有持续小雨';

  @override
  String get commonError => '出错了';

  @override
  String get moonPhaseWaningCrescent => '殘月';

  @override
  String get meshtasticPower => '电力';

  @override
  String get mapTimelineNow => '现在';

  @override
  String reportFilterRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String get reportDetailOpenReport => '报告页面';

  @override
  String get trendRange7d => '7 天';

  @override
  String typhoonWarningAreas(String areas) {
    return '警戒区域：$areas';
  }

  @override
  String get rainIntervalSection => '统计时间';

  @override
  String get notifyTitle => '通知';

  @override
  String get meshtasticTxPower => '发射功率';

  @override
  String get restroomCategoryLabel => '类别';

  @override
  String get sponsorRestoring => '正在恢复购买…';

  @override
  String get sponsorIntro =>
      'DPIP 致力于提供实时防灾信息，没有广告或其他盈利模式。您的支持能帮助我们维持服务器运行并持续开发。';

  @override
  String get typhoonLabelStormAvg => '十级风平均暴风半径';

  @override
  String get restroomCategoryCommercial => '商业营业场所';

  @override
  String get aedRegion => '县市区域';

  @override
  String homeRainTrendLightStopping(int minutes) {
    return '预计 $minutes 分钟后停止下小雨';
  }

  @override
  String get reportDetailInfo => '详细信息';

  @override
  String get mapNavWind => '风向';

  @override
  String get windForecastOverlayMenuTooltip => '风场预报图层选项';

  @override
  String homeRainTrendMinute(int minute) {
    return '$minute分';
  }

  @override
  String get rainInterval6h => '6 时';

  @override
  String get restroomTypeUnspecified => '未设定';

  @override
  String get typhoonOverlayProbabilityHint => '会隐藏预测圆锥';

  @override
  String get mapLayerSatelliteGlobalOutline => '国界';

  @override
  String get mapNavTemperature => '温度';

  @override
  String get typhoonLegendForecastPoint => '预测点';

  @override
  String get reportListYesterday => '昨天';

  @override
  String get moreSectionLinks => '相关链接';

  @override
  String get feedOffline => '连接中断';

  @override
  String get mapLayerStyleBd => 'Dvorak BD';

  @override
  String get moreSectionDisplay => '显示';

  @override
  String get rainInterval3d => '3 日';

  @override
  String get defaultMapLayerSubtitle => '打开地图标签页时显示此图层，底部导航栏图标与文字会一并更新。';

  @override
  String get aedDescription => '备注';

  @override
  String get typhoonOverlayWeatherRadarTooltip => '最接近台风报文时间的雷达回波';

  @override
  String get onboardingPermLocationDesc => '根据你所在的位置推送本地预警。';

  @override
  String get mapLayerSatelliteB16 => 'ひまわり 二氧化碳(B16)';

  @override
  String get homeActiveEventsEmpty => '目前没有生效中的事件';

  @override
  String get typhoonLabelPosition => '中心位置';

  @override
  String get weatherRankingBy => '依';

  @override
  String get typhoonIntensityMild => '轻度台风';

  @override
  String get windForecastGlobalOutlineHint => '各国国界外框';

  @override
  String get rainInterval1h => '1 时';

  @override
  String get eewLocalIntensity => '所在地预估';

  @override
  String get mapLayerRadar => '雷达合成回波图';

  @override
  String get restroomCategoryReligious => '宗教礼仪场所';

  @override
  String get meshtasticRole => '角色';

  @override
  String get mapLayerSatelliteCloudCloudy => '有云';

  @override
  String get skyTimeSunrise => '日出';

  @override
  String get meshtasticJumpToLatest => '跳到最新';

  @override
  String get meshtasticNoMessages => '尚无讯息';

  @override
  String get onboardingPermNotifyDesc => '在地震、天气与灾害发生时，即时推送预警通知。';

  @override
  String get radarTownOutline => '乡镇界线';

  @override
  String get mapLayerStyleSection => '显示样式';

  @override
  String get disasterMapOverlayMenuTooltip => '防灾地图图层';

  @override
  String get moreGooglePlay => 'Google Play';

  @override
  String get meshtasticOnline => '近期听到';

  @override
  String get typhoonLabelSw => '西南侧';

  @override
  String typhoonForecastLead(String hours) {
    return '预测 +$hours 小时';
  }

  @override
  String get changelogTypeStable => '正式版';

  @override
  String get mapLayerSatelliteTransparentClear => '晴空 = 透明,显示底图';

  @override
  String get mapOverlaySectionReference => '参考图层';

  @override
  String get mapLayerSatelliteB02 => 'ひまわり 可见光-绿(B02)';

  @override
  String get weatherRankingEmpty => '目前没有可排序的观测';

  @override
  String get notifySectionOther => '其他';

  @override
  String weatherRankingMeta(String time, int count) {
    return '资料时间：$time\n共 $count 观测点';
  }

  @override
  String get onboardingTermsAgree => '我已阅读并同意服务条款';

  @override
  String get mapLayerSatelliteTransparentNoVegetation => '< 0.1 = 透明(无植被)';

  @override
  String get notifyOptLocalIntensity4 => '本地震度4以上';

  @override
  String get eewArrived => '已抵达';

  @override
  String get meshtasticNoDevices => '找不到 Meshtastic 裝置';

  @override
  String get mapLayerCategoryLife => '生活';

  @override
  String get reportFilterSortIntensity => '震度';

  @override
  String get meshtasticStateDisconnected => '未連線';

  @override
  String get typhoonIntensityIntense => '强烈台风';

  @override
  String get mapLayerOrderTitle => '调整图层顺序';

  @override
  String get mapLayerShow => '显示图层';

  @override
  String get mapLayerHide => '隐藏图层';

  @override
  String get mapLayerShowAll => '全部显示';

  @override
  String get mapLayerHideAll => '全部隐藏';

  @override
  String get dpmYes => '是';

  @override
  String get meshtasticNoHistory => '历史纪录还不够';

  @override
  String get reportDetailLocalIntensityUnavailable => '没有震度信息';

  @override
  String get mapLayerWindForecastGfs => 'GFS';

  @override
  String get reportFilterDepth => '深度';

  @override
  String get onboardingScrollHint => '向下滚动以继续';

  @override
  String get mapNavQpesums => '预报';

  @override
  String get notifyAdvisory => '气象预警';

  @override
  String get reportFilterReset => '重置';

  @override
  String get mapLayerSatelliteMndwi => 'ひまわり 改良水体指数';

  @override
  String get typhoonOverlaySectionStorm => '暴风圈';

  @override
  String get moonPhaseFull => '滿月';

  @override
  String meshtasticBinaryPayload(String size) {
    return '二进制内容 · $size';
  }

  @override
  String get moonPhaseWaningGibbous => '虧凸月';

  @override
  String get reportFilterIntensityInfoModernTitle => '新制（2020 起）';

  @override
  String typhoonDataTime(String time) {
    return '资料时间\n$time';
  }

  @override
  String get restroomTypeAccessible => '无障碍厕所';

  @override
  String get moreSectionAbout => '关于';

  @override
  String get meshtasticSelectDevice => '选择装置';

  @override
  String get onboardingIntroBody =>
      'DPIP 是与你并肩的防灾伙伴，整合地震预警、地震报告、天气与各类灾害信息，在关键时刻即时通知你。\n\n• 地震：地震预警、震度速报与详细报告\n• 天气：实时雷雨消息与气象预警\n• 海啸与防灾信息\n\n接下来，我们会请你阅读服务条款，并授权几项权限，让 DPIP 能实时守护你。';

  @override
  String get shelterCapacityLabel => '收容人数';

  @override
  String get reportDetailImage => '地震报告图';

  @override
  String get meshtasticStateConfiguring => '設定中…';

  @override
  String get typhoonLabelGaleAvg => '七级风平均暴风半径';

  @override
  String get onboardingPermNotify => '通知';

  @override
  String get meshtasticClearMessages => '清除讯息';

  @override
  String get meshtasticNotifyMessages => '新讯息通知';

  @override
  String get defaultMapLayerSettings => '地图默认图层';

  @override
  String get eewSourceSettings => '地震速报来源';

  @override
  String get eewSourceSubtitle => '选择要显示哪些单位发布的地震速报。';

  @override
  String get eewSourceAll => '所有来源';

  @override
  String get eewSourceAllDescription => '显示所有机构发布的地震速报。';

  @override
  String get eewSourceCwaOnly => '仅中央气象署';

  @override
  String get eewSourceCwaOnlyDescription => '只显示中央气象署发布的地震速报。';

  @override
  String get moreSectionNotify => '通知';

  @override
  String get notifyUnavailable => '推送通知尚未就绪，请稍后再试。';

  @override
  String get mapLayerOrderReset => '恢复默认顺序';

  @override
  String get weatherRankingMergeCounty => '县市';

  @override
  String get moreSectionApp => '获取 App';

  @override
  String get moreSectionBeta => '测试版';

  @override
  String get moreAndroidBeta => 'Android 测试版';

  @override
  String get moreTestFlight => 'iOS 测试版（TestFlight）';

  @override
  String get moreSectionPartners => '合作伙伴';

  @override
  String get morePartnersNote => '按合作時間先後排列。感謝這些個人與公司對防災的貢獻，他們讓 DPIP 成為可能。';

  @override
  String get morePartnerGeoscience => '巨科资讯有限公司';

  @override
  String get morePartnerTwds => '台湾数位串流有限公司';

  @override
  String get reportFilterIntensityInfoLegacyBody => '震度仅 0–7，没有 5弱／5强／6弱／6强。';

  @override
  String get mapLayerSatelliteSst => 'ひまわり 海表温度';

  @override
  String get qpesumsOverlayMenuTooltip => '定量降水预报图层选项';

  @override
  String get mapTimelineFuture => '未来';

  @override
  String get typhoonLegendCircleAvg => '平均圆';

  @override
  String reportFilterDepthKm(String depth) {
    return '$depth 公里';
  }

  @override
  String get typhoonLabelSe => '东南侧';

  @override
  String get radarTownOutlineHint => '较细的分区';

  @override
  String eewCountdown(int seconds) {
    return '$seconds 秒';
  }

  @override
  String get typhoonLabelGust => '瞬间最大阵风';

  @override
  String get mapAppGoogleMaps => 'Google Maps';

  @override
  String get sponsorTerms => '使用条款';

  @override
  String get restroomTypeGenderNeutral => '性别友善厕所';

  @override
  String get notifyThunderstorm => '雷雨预警';

  @override
  String get skyTimeGolden => '黄金时刻';

  @override
  String get moonAge => '月齡';

  @override
  String get meshtasticRadioSettings => 'LoRa';

  @override
  String get moreGithub => 'ExpTech GitHub';

  @override
  String get homeForecastUnavailable => '选择乡镇后可查看预报';

  @override
  String get mapLayers => '图层';

  @override
  String get meshtasticHardware => '硬件';

  @override
  String get languageSettings => '语言设置';

  @override
  String get language => '语言';

  @override
  String homeForecastFeelsLike(String temp) {
    return '体感 $temp°';
  }

  @override
  String get typhoonOverlayWeatherHint => '对齐报文时间';

  @override
  String get skyTimeDawn => '黎明';

  @override
  String get skyTimeAfternoon => '下午';

  @override
  String get meshtasticLastHeard => '最后听到';

  @override
  String get typhoonWarningTitle => '台风警报';

  @override
  String get moreSourceCode => '源代码';

  @override
  String get mapLayerCategoryWeather => '气象观测';

  @override
  String get mapLayerSatelliteB09 => 'ひまわり 中层水气(B09)';

  @override
  String get windForecastTownOutlineHint => '更细的网格';

  @override
  String get mapLayerSatelliteCloudmask => 'ひまわり 云遮罩';

  @override
  String get mapAppCopyCoordinates => '复制坐标';

  @override
  String get reportFilterIntensityInfoIntro =>
      '中央气象署自 2020 年 1 月 1 日（台北时间）起改用新制震度。';

  @override
  String get mapNavEarthquake => '地震';

  @override
  String get restroomGradeAverage => '普通级';

  @override
  String get mapLayerSatelliteBtdCo2 => 'ひまわり 卷云/云高';

  @override
  String get onboardingPermBackgroundDesc => '选择“始终允许”，关闭应用后也能向你推送本地预警。';

  @override
  String get mapTimelineForecast => '预报';

  @override
  String get restroomTypeLabel => '厕所类型';

  @override
  String get navEarthquake => '地震';

  @override
  String get typhoonOverlayStormL10Tooltip => '十级风风场 + 平均圆（黄）';

  @override
  String get moonPhaseWaxingGibbous => '盈凸月';

  @override
  String get reportDetailTitle => '地震报告';

  @override
  String get moreTremReport => 'TREM 检测报告';

  @override
  String weatherDataTime(String station, String time) {
    return '$station ∙ 资料时间 $time';
  }

  @override
  String get meshtasticNoNodes => '尚未听到任何节点';

  @override
  String get meshtasticViaMqtt => '经 MQTT（互联网）';

  @override
  String get radarCountyOutline => '县市界线';

  @override
  String get commonClose => '关闭';

  @override
  String get restroomGradeLabel => '等级';

  @override
  String get rainIntervalNow => '今日';

  @override
  String get changelogCurrentVersion => '当前版本';

  @override
  String get typhoonLabelPressure => '中心气压';

  @override
  String get typhoonOverlayForecastCalloutsTooltip => '放大时显示预测点详细卡片';

  @override
  String get aedOpenRemark => '开放时间备注';

  @override
  String get onboardingPermsBody => '为了在灾害发生的第一时间通知你，请授权以下权限。你可以随时在系统设置中更改。';

  @override
  String get typhoonOverlaySectionWeather => '天气底图';

  @override
  String get notifyOptWeatherLocal => '仅接收当前位置';

  @override
  String get mapNavRain => '雨量';

  @override
  String get moonDays => '天';

  @override
  String mapLegendUnit(String unit) {
    return '单位：$unit';
  }

  @override
  String get weatherModeClear => '晴天';

  @override
  String get meshtasticRadio => '电台';

  @override
  String get commonEmpty => '暂无内容';

  @override
  String get mapLayerSatelliteB01 => 'ひまわり 可见光-蓝(B01)';

  @override
  String get meshtasticExternalPower => '外部供电';

  @override
  String get moonPhaseLastQuarter => '下弦月';

  @override
  String get reportFilterOrderAsc => '升序';

  @override
  String get reportFilterApply => '应用';

  @override
  String get reportDetailImageUnavailable => '报告图尚未提供';

  @override
  String get weatherRankingHighest => '最高';

  @override
  String get reportDetailReplay => '重播';

  @override
  String get mapLayerRestroom => '公厕';

  @override
  String get restroomCategoryWelfare => '社福机构、集会场所';

  @override
  String get restroomGradeExcellent => '特优级';

  @override
  String get meshtasticLastSent => '最近送出';

  @override
  String get meshtasticName => '名称';

  @override
  String get meshtasticScan => '掃描';

  @override
  String get mapLayerCategoryForecast => '数值预报';

  @override
  String get meshtasticChannelFailed => '无法设定 DPIP 频道';

  @override
  String get themeSystem => '跟随系统';

  @override
  String get mapLayerSatelliteNdvi => 'ひまわり 植被指数';

  @override
  String get typhoonLegendForecast => '预测路径';

  @override
  String typhoonValueHpa(String n) {
    return '$n 百帕';
  }

  @override
  String get weatherPrecipitation => '降水量';

  @override
  String get moonNextFullMoon => '下次滿月';

  @override
  String get dpmSheetEmpty => '点击地图上的标记查看详情';

  @override
  String get onboardingSkipLeave => '仍要跳过';

  @override
  String get aedPlaceDesc => '放置位置说明';

  @override
  String get onboardingSkipTitle => '尚未完成授权';

  @override
  String get restroomTypeFamily => '亲子厕所';

  @override
  String typhoonValueKm(String n) {
    return '$n 公里';
  }

  @override
  String get onboardingPermBattery => '电池优化白名单';

  @override
  String get typhoonLabelNw => '西北侧';

  @override
  String get moonPhaseWaxingCrescent => '眉月';

  @override
  String get restroomCategoryLeisure => '休闲娱乐场所';

  @override
  String get mapLayerTemperature => '温度';

  @override
  String get aedCategory => '场所分类';

  @override
  String get meshtasticChannels => '频道';

  @override
  String get monitorWaiting => '等待数据…';

  @override
  String get typhoonOverlayForecastCallouts => '预测点信息';

  @override
  String get reportDetailEpicenter => '震中坐标';

  @override
  String get meshtasticVoltage => '电压';

  @override
  String get mapLayerMeshtasticSubtitle => '电台听到过的 LoRa 网状网路节点';

  @override
  String get mapLayerWind => '风向';

  @override
  String get reportDetailMagnitude => '地震规模';

  @override
  String get reportDetailAreaIntensity => '各地震度';

  @override
  String get rainInterval12h => '12 时';

  @override
  String reportListMagnitude(String magnitude) {
    return 'M$magnitude';
  }

  @override
  String get notifyMonitor => '强震监视器';

  @override
  String get onboardingStart => '开始使用';

  @override
  String sponsorPerMonth(String price) {
    return '$price / 月';
  }

  @override
  String get mapLayerPressure => '气压';

  @override
  String get mapLayerSatelliteB04 => 'ひまわり 近红外(B04)';

  @override
  String get mapLayerSatelliteTransparentZero => '零差值 = 透明(无信号)';

  @override
  String get shelterIndoorLabel => '室内收容';

  @override
  String get notifyOptOff => '关闭';

  @override
  String get reportFilterSortTime => '时间';

  @override
  String get mapLayerSatelliteCloudProbablyClear => '可能晴空';

  @override
  String get weatherModeThunderstorm => '雷雨';

  @override
  String get homeViewOnMap => '前往地图察看';

  @override
  String get reportFilterIntensityInfoLegacyTitle => '旧制（2020 以前）';

  @override
  String get typhoonLabelSpeed => '过去移动时速';

  @override
  String mapAppOpenFailed(String app) {
    return '无法打开 $app';
  }

  @override
  String get mapLayerSatelliteRgbComposite => 'RGB 合成(JMA 配方)';

  @override
  String get meshtasticReceived => '已接收';

  @override
  String get weatherRankingExtremeLow => '今日最低';

  @override
  String get mapLayerSatelliteB10 => 'ひまわり 低层水气(B10)';

  @override
  String get mapLayerSatelliteCloudProbablyCloudy => '可能有云';

  @override
  String get mapLayerSatelliteTransparentNoWater => '≤ 0 = 透明(无水体)';

  @override
  String get shelterCategoryLabel => '适用灾害';

  @override
  String get meshtasticStateConnecting => '連線中…';

  @override
  String get moonTitle => '月亮';

  @override
  String get weatherRankingGust => '阵风';

  @override
  String get moreAppStore => 'App Store';

  @override
  String get moreServerStatus => '服务器状态';

  @override
  String get notifySectionWeather => '天气';

  @override
  String get meshtasticPreset => '调变预设';

  @override
  String get dataSectionSeismic => '地震';

  @override
  String get changelogBodyEmpty => '此版本没有说明。';

  @override
  String get changelogOpenOnGitHub => '在 GitHub 查看';

  @override
  String get radarGlobalOutline => '国界';

  @override
  String get notifyEew => '紧急地震预警';

  @override
  String get regionNationwide => '全国';

  @override
  String get moreNotifyLog => 'DPIP 通知发送记录';

  @override
  String get regionCurrent => '当前位置';

  @override
  String get meshtasticNotConnected => '尚未连线至装置';

  @override
  String get weatherModeSnow => '下雪';

  @override
  String get mapLayerMeshtastic => 'Meshtastic 节点';

  @override
  String get moreDeveloper => '调试信息';

  @override
  String get mapLayerSatelliteB14 => 'ひまわり 长波红外线(B14)';

  @override
  String get meshtasticChannelUse => '频道使用率';

  @override
  String get mapNavLightning => '闪电';

  @override
  String get homeForecastEmpty => '目前没有预报数据';

  @override
  String get sponsorOneTime => '单次支持';

  @override
  String get mapLayerSatelliteBtdSplit => 'ひまわり 分割视窗';

  @override
  String get onboardingPermBackground => '后台定位';

  @override
  String get aedEmergencyPhone => '紧急联络电话';

  @override
  String get dpmOpenInMaps => '打开地图';

  @override
  String get meshtasticNotifyNodes => '新节点通知';

  @override
  String get onboardingPermCriticalDesc => '让危及生命的地震预警，即使在静音或勿扰模式下也能发出声响。';

  @override
  String get mapLayerSatelliteTransparentWarm => '晴空(暖端) = 透明,显示底图';

  @override
  String get meshtasticSent => '已送出';

  @override
  String get homeForecastTitle => '24小时预报';

  @override
  String get typhoonLegendWarningAreas => '警报区域';

  @override
  String meshtasticExcludeMqttHidden(int count) {
    return '已隐藏 $count 个';
  }

  @override
  String get notifyOptLocalIntensity1 => '本地震度1以上';

  @override
  String get mapTimelinePast => '历史';

  @override
  String get restroomTypeFemale => '女厕所';

  @override
  String get reportListToday => '今天';

  @override
  String get meshtasticTapNode => '点选节点查看详细信息';

  @override
  String get commonLoading => '加载中…';

  @override
  String get typhoonIntensityModerate => '中度台风';

  @override
  String get mapLayerSatelliteAsh => 'ひまわり 火山灰';

  @override
  String get rainInterval3h => '3 时';

  @override
  String get mapLayerCategorySatellite => '卫星';

  @override
  String get meshtasticChannelReady => 'DPIP 频道已就绪';

  @override
  String get mapLayerSatelliteNightmicrophysics => 'ひまわり 夜间微物理';

  @override
  String get typhoonIntensityTd => '热带性低气压';

  @override
  String get reportFilterDate => '日期';

  @override
  String get sponsorRestoreUnavailable => '无法连接到商店，请稍后再试';

  @override
  String homeForecastPop(String pop) {
    return '$pop%';
  }

  @override
  String get regionEmpty => '尚未添加常用地区';

  @override
  String get onboardingPermBatteryDesc => '允许 DPIP 在后台持续运行，避免预警延迟或漏收。';

  @override
  String get mapNavDisaster => '防灾';

  @override
  String get radarScanRangeSubtitle => '标示四座雷达实际观测到的范围。';

  @override
  String get aedHoursSunday => '周日开放时间';

  @override
  String get reportDetailOriginTime => '发震时间';

  @override
  String get trendNoData => '没有趋势数据';

  @override
  String get onboardingPermLocation => '定位';

  @override
  String get moreDiscord => 'Discord 社区';

  @override
  String get mapNavPressure => '气压';

  @override
  String get mapLayerSatelliteB13 => 'ひまわり 红外线(B13)';

  @override
  String typhoonTdNo(String no) {
    return 'TD $no';
  }

  @override
  String get changelogEmpty => '目前没有更新日志';

  @override
  String get reportFilterDateStartNote => '开始日：当日 00:00（台北时间）';

  @override
  String get eewTitle => '地震预警';

  @override
  String get mapLayerWindForecastEcmwf => 'ECMWF';

  @override
  String regionSelectCount(int count, int max) {
    return '已选 $count/$max';
  }

  @override
  String get mapLayerSatelliteBtdSo2 => 'ひまわり 二氧化硫/云相';

  @override
  String get meshtasticStateError => '錯誤';

  @override
  String get weatherModeOvercast => '阴天';

  @override
  String get reportDetailDepth => '震源深度';

  @override
  String get typhoonOverlayWarningTooltip => '标示发布台风警报的县市';

  @override
  String get reportFilterDatePick => '选择日期';

  @override
  String get onboardingSkipStay => '返回授权';

  @override
  String get commonFetchFailed => '无法获取数据,请稍后重试';

  @override
  String get shelterOutdoorLabel => '室外收容';

  @override
  String get meshtasticStateConnected => '已連線';

  @override
  String get mapNavRadar => '雷达';

  @override
  String get mapLayerSatelliteCloudClear => '晴空';

  @override
  String eewSummary(String magnitude, String depth) {
    return '震级 $magnitude·深度 $depth 公里';
  }

  @override
  String get locationBannerPermission => '尚未授予定位权限，无法向你所在的区域推送本地预警。';

  @override
  String get typhoonOverlayWeatherNoneTooltip => '不显示雷达或红外线底图';

  @override
  String get radarCountyOutlineHint => '画在回波之上';

  @override
  String get windForecastCountyOutlineHint => '绘制于风场之上';

  @override
  String get homeRainTrendTitle => '近 1 小时降水趋势';

  @override
  String get moonPhaseFirstQuarter => '上弦月';

  @override
  String get mapLayerCategoryTyphoon => '台风';

  @override
  String get meshtasticUtilization => '空中工时（24 小时）';

  @override
  String get restroomTypeMixed => '混合厕所';

  @override
  String get restroomGradeGood => '优等级';

  @override
  String get notifyTsunami => '海啸信息';

  @override
  String get navData => '资料';

  @override
  String get mapLayerSatelliteBtdWvirw => 'ひまわり 过冲云顶';

  @override
  String get meshtasticReadingAge => '数值时间';

  @override
  String get mapAppCallFailed => '此设备无法拨打电话';

  @override
  String get reportFilterAny => '不限';

  @override
  String get weatherRankingMergeTo => '合并至';

  @override
  String get notifyIntensity => '震度速报';

  @override
  String get rainIntervalMenu => '累积时段';

  @override
  String get reportDetailLocalFelt => '小区域有感地震';

  @override
  String get meshtasticDevice => '设备';

  @override
  String get onboardingGrant => '授权';

  @override
  String get weatherModeRain => '雨天';

  @override
  String get shelterVulnerableOkLabel => '适合避难弱者安置';

  @override
  String get stationSheetEmpty => '点选任一测站查看观测值';

  @override
  String get typhoonLegendProbability => '侵袭概率';

  @override
  String get reportFilterMagnitude => '规模';

  @override
  String get skyTimeMorning => '上午';

  @override
  String get experimentalFeatures => '实验性功能';

  @override
  String get onboardingTermsBody =>
      '使用 DPIP 前，请详细阅读以下注意事项：\n\n• 任何信息均应以中央气象署（CWA）发布的内容为准。\n\n• 受网络状态、服务器状态、应用程序状态、上游数据来源状态等因素影响，存在收不到信息的可能，我们会尽力避免此类情况，但不保证一定不会发生。\n\n• 强烈震动有可能比通知更早抵达您所在的位置。\n\n• 地震预警为快速计算的结果，可能存在较大误差，请理解并谨慎使用。\n\n• 任何未获官方认可的行为均可能承担法律风险，请务必遵守相关规定。\n\n此外，为提供本地化预警，本服务会在前台及后台收集并上传您的大致位置与设备推送标识符，仅用于决定应向您推送哪些预警。\n\n点击下方“同意并继续”即表示您已阅读、理解并同意上述事项。';

  @override
  String get reportFilterTitle => '筛选';

  @override
  String get onboardingPermCritical => '重要警告';

  @override
  String trendCumulativeTotal(String total) {
    return '累计 $total mm';
  }

  @override
  String get languageName => '简体中文';

  @override
  String get reportListEmptyFiltered => '没有符合条件的地震报告';

  @override
  String get meshtasticExcludeMqtt => '隐藏 MQTT 节点';

  @override
  String get mapNavTyphoon => '台风';

  @override
  String get weatherModeSand => '沙尘';

  @override
  String get notifyReport => '地震报告';

  @override
  String get mapAppCoordinatesCopied => '已复制坐标';

  @override
  String get skyTimeNight => '夜晚';

  @override
  String get sponsorRecommended => '推荐';

  @override
  String get mapLayerSatelliteB15 => 'ひまわり 长波红外线(B15)';

  @override
  String get weatherRankingWind => '风速';

  @override
  String get feedStale => '数据可能已过期';

  @override
  String homeForecastWind(String direction, String level) {
    return '$direction · $level 级';
  }

  @override
  String get navHome => '主页';

  @override
  String get meshtasticRegionLabel => '地区';

  @override
  String get mapLayerSatelliteCloudtop => 'ひまわり 云顶温度';

  @override
  String get moonTimelineCaption => '月相';

  @override
  String get openSourceLicenses => '开源许可';

  @override
  String get weatherRankingLowest => '最低';

  @override
  String get reportFilterSortDepth => '深度';

  @override
  String mapTimelineDataTime(String time) {
    return '资料时间 $time';
  }

  @override
  String get radarScanRange => '显示扫描范围';

  @override
  String get meshtasticHopLimit => '跳数上限';

  @override
  String get weatherRankingExtremeHigh => '今日最高';

  @override
  String get sponsorPrivacy => '隐私政策';

  @override
  String get reportDetailLocalIntensity => '所在地的震度';

  @override
  String get mapLayerSatelliteNaturalcolor => 'ひまわり 自然色';

  @override
  String get meshtasticAirtime => '发射占空比';

  @override
  String shelterCapacityValue(int n) {
    return '$n 人';
  }

  @override
  String lightningLegendCc(int minutes) {
    return '云间 · $minutes 分钟内';
  }

  @override
  String get meshtasticSendHint => '要廣播的訊息';

  @override
  String monitorDelay(String value) {
    return '延迟 $value s';
  }

  @override
  String get dpmNo => '否';

  @override
  String get mapLayerSatelliteB08 => 'ひまわり 上层水气(B08)';

  @override
  String get meshtasticReconnecting => '重新连线中…';

  @override
  String get radarTownOutlineSubtitle => '让乡镇界线在雷达回波下仍然清楚。';

  @override
  String get typhoonOverlayWeatherSatelliteTooltip => '最接近台风报文时间的红外线';

  @override
  String get radarScanRangeHint => '框外空白代表未观测';

  @override
  String typhoonPickerTd(String no) {
    return '热带性低气压 TD $no';
  }

  @override
  String get mapLayerSatelliteWatervapor => 'ひまわり 水气';

  @override
  String get regionAddButton => '添加地区';

  @override
  String get regionSearchHint => '搜索县市';

  @override
  String get regionSearchEmpty => '找不到符合的县市';

  @override
  String get regionSearchTownHint => '搜索乡镇市区';

  @override
  String get regionSearchTownEmpty => '找不到符合的乡镇市区';

  @override
  String get displaySettings => '显示设置';

  @override
  String get restroomGradePoor => '不合格';

  @override
  String get restroomCategoryTourist => '观光地区及风景区';

  @override
  String get locationBannerServiceOff => '定位服务已关闭，无法向你所在的区域推送本地预警。';

  @override
  String get mapLayerStyleTooltip => '显示样式';

  @override
  String lightningLegendCg(int minutes) {
    return '对地 · $minutes 分钟内';
  }

  @override
  String get skyTimeAuto => '自动';

  @override
  String get appLogs => '应用日志';

  @override
  String get serverStatusLocal => '本机状态';

  @override
  String get serverStatusLocalBody =>
      '服务器指标来自控制台。下方是本机对多活端点（LB / Core 各区)的实际连接判断：APP 只被动记录本机实际播送的流量，若该端点从未被本机触发，就会显示未探测。';

  @override
  String get serverStatusAllUp => '所有服务正常';

  @override
  String get serverStatusDegraded => '服务性能下降';

  @override
  String get serverStatusDown => '服务异常';

  @override
  String get serverStatusErrorRate => '5xx 错误率';

  @override
  String get serverStatusLatency => '平均延迟';

  @override
  String get serverStatusUpdated => '更新于';

  @override
  String get serverStatusWeb => '服务器状态';

  @override
  String get serverStatusWebUrl => 'status.exptech.dev';

  @override
  String get serverStatusExpTech => 'ExpTech 状态';

  @override
  String get serverStatusCloudflare => 'Cloudflare 状态';

  @override
  String get serverStatusCloudflareAllOperational => '所有区域正常';

  @override
  String get serverStatusCloudflareOutage => 'Cloudflare 部分区域异常';

  @override
  String get serverStatusCloudflareNone => '目前没有可显示的区域。';

  @override
  String get serverStatusCloudflareOperational => '正常';

  @override
  String get serverStatusCloudflareDegraded => '性能下降';

  @override
  String get serverStatusCloudflarePartial => '部分中断';

  @override
  String get serverStatusCloudflareMajor => '大规模中断';

  @override
  String get serverStatusCloudflareUnknown => '未知';

  @override
  String get endpointTierLbApi => 'LB API';

  @override
  String get endpointTierLbStatic => 'LB Static';

  @override
  String get endpointTierCoreApi => 'Core API';

  @override
  String get endpointTierCoreStatic => 'Core Static';

  @override
  String get endpointTierCoreExclusiveApi => 'Core 专属 API（雷达 / 气象 / 风场）';

  @override
  String get endpointTierCoreStaticExclusive => 'Core 专属静态资源';

  @override
  String get endpointTierLegacyApi => '旧版 API（api-1）';

  @override
  String get endpointHealthOk => '本机连接正常';

  @override
  String get endpointHealthDegraded => '有端点连接不稳';

  @override
  String get endpointHealthDown => '本机连接异常';

  @override
  String get endpointHealthUnknown => '暂无观测数据';

  @override
  String get endpointStateOk => '正常';

  @override
  String get endpointStateDegraded => '不稳';

  @override
  String get endpointStateDown => '异常';

  @override
  String get endpointStateUnknown => '未知';

  @override
  String get endpointServiceEew => '地震速報';

  @override
  String get endpointServiceRts => '強震即時警報';

  @override
  String get endpointServiceRadar => '雷達';

  @override
  String get endpointServiceSatellite => '衛星';

  @override
  String get endpointServiceQpesums => '定量降水';

  @override
  String get endpointServiceWind => '風場';

  @override
  String get endpointServiceDpm => '災害點位';

  @override
  String get endpointServiceWeather => '天氣';

  @override
  String get endpointServiceRain => '降雨';

  @override
  String get endpointServiceLightning => '閃電';

  @override
  String get endpointServiceTyphoon => '颱風';

  @override
  String get endpointServiceReport => '地震報告';

  @override
  String get endpointServiceTremStation => '震度站';

  @override
  String get endpointServiceEvent => '事件';

  @override
  String get endpointServiceLocation => '定位';

  @override
  String get endpointServiceNotify => '通知';

  @override
  String get endpointServiceOther => '其他';

  @override
  String get feedConnecting => '连接中…';

  @override
  String get notifyBannerDisabled => '通知已关闭,将收不到灾害警报。';

  @override
  String get weatherHumidity => '湿度';

  @override
  String typhoonValueMs(String n) {
    return '每秒 $n 公尺';
  }

  @override
  String homeForecastHumidity(String value) {
    return '湿度 $value%';
  }

  @override
  String get meshtasticBusyBody =>
      '请先在另一个 Meshtastic App 中断线。两个 App 同时连同一台设备会互相抢走讯息，导致部分讯息遗失。';

  @override
  String get meshtasticChannelNoSlot => '没有可用的频道空位 — 请先在设备上空出一个';

  @override
  String get restroomCategoryTransport => '交通';

  @override
  String get meshtasticBattery => '电量';

  @override
  String get meshtasticDistance => '距离';

  @override
  String get meshtasticSnrTrend => '信号趋势 (SNR)';

  @override
  String get meshtasticBatteryTrend => '电量趋势';

  @override
  String get typhoonOverlayMenuTooltip => '台风图层选项';

  @override
  String get mapLayerSatelliteBtdOzone => 'ひまわり 对流层顶';

  @override
  String meshtasticRegionMismatch(String region) {
    return '设备地区为 $region — DPIP 需要 TW';
  }

  @override
  String get notifySectionEarthquake => '地震';

  @override
  String get mapLayerDisasterMap => '防灾地图';

  @override
  String get weatherModeFog => '大雾';

  @override
  String typhoonPickerNamed(String no, String name) {
    return '$name TY $no';
  }

  @override
  String get mapLayerStyleGrayTooltip => '气象厅灰度惯例：温度越低越白';

  @override
  String get moreAnnouncements => '公告';

  @override
  String get moreTagline => '防灾信息整合平台';

  @override
  String get moreVersionStable => '正式版';

  @override
  String get moreVersionNotes => '本次更新';

  @override
  String get moreVersionNotesHighlightsSubtitle => '这个版本做了哪些改变';

  @override
  String releaseHighlightsTitle(Object train) {
    return '$train 重点整理';
  }

  @override
  String get releaseHighlightsTabNormal => '做了哪些改变';

  @override
  String get releaseHighlightsTabAdvanced => '深入技术';

  @override
  String get releaseHighlightsEmpty => '目前没有内容。';

  @override
  String get releaseHighlightsSeeNotes => '查看完整更新日志';

  @override
  String get moreVersionNotesEmpty => '找不到当前版本的更新日志';

  @override
  String get reportNotFound => '找不到这份地震报告';

  @override
  String get moreVersionSnapshot => '測試版';

  @override
  String get mapLayerSatelliteTransparentNoData => '无资料(陆地) = 透明';

  @override
  String get restroomCategoryGovernment => '民众洽公场所';

  @override
  String get typhoonLegendCurrent => '目前中心';

  @override
  String get aedAddress => '地址';

  @override
  String get mapLayerAed => 'AED';

  @override
  String get changelogTypePrerelease => '测试版';

  @override
  String get reportFilterIntensityInfoModernBody =>
      '震度为 0–4、5弱、5强、6弱、6强、7。筛选滑杆依新制；列表中较早的地震会以旧制标示显示。';

  @override
  String get typhoonOverlayWeatherNone => '无';

  @override
  String get mapLayerStyleGray => '灰度（JMA）';

  @override
  String get weatherModeAuto => '自动';

  @override
  String get typhoonLabelProbCircle => '70%概率圆';

  @override
  String get notifyOptAll => '接收全部';

  @override
  String get displayTheme => '主题';

  @override
  String get mapLayerSatelliteB07 => 'ひまわり 短波红外(B07)';

  @override
  String get typhoonLabelDirection => '过去移动方向';

  @override
  String get regionManageTitle => '常用地区';

  @override
  String get regionSaveNote =>
      '通知是基于 GPS 所在位置发送的，设置常用地区不会改变或影响通知发送，常用地区仅用于在首页快速查看不同区域状态，所以请务必授予 GPS 定位权限，否则通知无法运作';

  @override
  String get typhoonLegendCone => '预测圆锥';

  @override
  String get moreCwaEew => '中央气象署地震预警';

  @override
  String get onboardingPermsTitle => '权限授权';

  @override
  String get mapLayerStyleJma => '云顶强调（JMA）';

  @override
  String get rainInterval10m => '10 分';

  @override
  String get meshtasticConnectAnyway => '仍要连线';

  @override
  String reportListDayCount(int count) {
    return '$count';
  }

  @override
  String get mapLayerSatelliteB06 => 'ひまわり 近红外(B06)';

  @override
  String get mapLayerSatelliteTransparentReflectance => '低反射率/夜间 = 透明,显示底图';

  @override
  String chartHourLabel(int hour) {
    return '$hour时';
  }

  @override
  String get mapLayerShelter => '避难收容场所';

  @override
  String get typhoonOverlayProbabilityTooltip => '显示侵袭概率（隐藏预测圆锥）';

  @override
  String get mapLayerSatelliteNdwi => 'ひまわり 水体指数';

  @override
  String get disasterMapOverlayShelterTooltip => '显示避难收容场所';

  @override
  String get mapNavHumidity => '湿度';

  @override
  String get reportDetailSortByIntensity => '依震度排序';

  @override
  String get homeRainTrendNoData => '无资料';

  @override
  String get mapLayerCategoryRadar => '雷达';

  @override
  String get meshtasticShortName => '简称';

  @override
  String get mapLayerSatelliteAirmass => 'ひまわり 气团';

  @override
  String get dataSectionWeather => '气象';

  @override
  String get aedHoursWeekday => '平日开放时间';

  @override
  String get homeActiveEventsTitle => '生效中事件';

  @override
  String get faq => '常见问题';

  @override
  String eewSerial(int serial) {
    return '第 $serial 报';
  }

  @override
  String get reportFilterSort => '排序方式';

  @override
  String get meshtasticRegionConfirm =>
      '要将这台设备切换为 TW 地区吗？设备会重新启动并短暂断线，上面的其他频道也会一起改变。';

  @override
  String get dataEarthquakeSubtitle => '地震报告';

  @override
  String get typhoonNoActive => '目前无台风';

  @override
  String get mapLayerSatelliteB11 => 'ひまわり 二氧化硫/云相(B11)';

  @override
  String get navEvents => '事件';

  @override
  String get onboardingTermsTitle => '服务条款';

  @override
  String get mapOsmOverlay => '详细地图';

  @override
  String get mapOsmOverlayHint => '显示更完整的道路、建筑和地名';

  @override
  String get mapOsmDetails => '详细设置';

  @override
  String get moreDataSources => '数据来源';

  @override
  String get dataSourceTremNet => '探索智慧科技有限公司 — TREM-Net';

  @override
  String get dataSourceCwa => '交通部中央氣象署 (CWA)';

  @override
  String get dataSourceJma => '気象庁 (JMA)';

  @override
  String get dataSourceNcdr => '國家災害防救科技中心 (NCDR)';

  @override
  String get dataSourceEcmwf =>
      'European Centre for Medium-Range Weather Forecasts (ECMWF)';

  @override
  String get dataSourceNoaaGfs =>
      'National Oceanic and Atmospheric Administration / National Centers for Environmental Prediction — Global Forecast System (NOAA/NCEP GFS)';

  @override
  String get dataSourceGovernmentOpenData => '政府資料開放平臺';

  @override
  String get dataSourceOpenStreetMap => '© OpenStreetMap contributors';

  @override
  String get dataSourceNasaMoon =>
      'National Aeronautics and Space Administration / Goddard Space Flight Center Scientific Visualization Studio — CGI Moon Kit (NASA/GSFC SVS)';

  @override
  String mapOsmDetailsHint(int enabled, int total) {
    return '已启用 $enabled / 共 $total 个图层';
  }

  @override
  String get mapOsmSurface => '地表';

  @override
  String get mapOsmParks => '公园';

  @override
  String get mapOsmLandUse => '土地利用';

  @override
  String get mapOsmAirportAreas => '机场区域';

  @override
  String get mapOsmWater => '水域';

  @override
  String get mapOsmRivers => '河川';

  @override
  String get mapOsmBoundaries => '边界';

  @override
  String get mapOsmBuildings => '建筑物';

  @override
  String get mapOsmRoads => '道路';

  @override
  String get mapOsmRoadNames => '道路名称';

  @override
  String get mapOsmWaterNames => '水域名称';

  @override
  String get mapOsmPeaks => '山峰';

  @override
  String get mapOsmAirportNames => '机场名称';

  @override
  String get mapOsmPlaceNames => '地名';

  @override
  String get mapOsmPoi => '地标';

  @override
  String get mapOsmHouseNumbers => '门牌号码';

  @override
  String get mapOsmRestoreAll => '全部恢复';

  @override
  String get mapOsmSectionNatural => '地表与自然';

  @override
  String get mapOsmSectionRoadsAndBuildings => '道路与建筑';

  @override
  String get mapOsmSectionLabelsAndPlaces => '地名与标注';

  @override
  String get mapTownLabels => '乡镇名称';

  @override
  String get notifySetFailed => '设置失败，请稍后再试。';

  @override
  String get meshtasticDisconnect => '斷線';

  @override
  String get meshtasticUndecoded => '无法解密';

  @override
  String get notifyAnnouncement => '公告';

  @override
  String get onboardingIntroTitle => '欢迎使用 DPIP';

  @override
  String get regionCurrentUnavailable => '无法获取所在地位置信息';

  @override
  String get languageSystem => '系统默认';

  @override
  String get skyTimeSunset => '日落';

  @override
  String get mapLayerSatelliteDust => 'ひまわり 沙尘';

  @override
  String get mapAppAppleMaps => 'Apple Maps';

  @override
  String get regionEdit => '修改';

  @override
  String get weatherDynamicState => '天气动画';

  @override
  String get moonNow => '现在';

  @override
  String get moonSectionAppearance => '外观';

  @override
  String get moonSectionRiseSet => '月出月落';

  @override
  String get moonSectionUpcoming => '接下来';

  @override
  String get moonSectionCalendar => '月历';

  @override
  String get moonDistance => '距离';

  @override
  String get moonKilometres => '公里';

  @override
  String get moonApparentSize => '视直径';

  @override
  String get moonRise => '月出';

  @override
  String get moonSet => '月落';

  @override
  String get moonNextNewMoon => '下次新月';

  @override
  String get moonAlwaysUp => '整日在地平线上';

  @override
  String get moonNoEvent => '当日无';

  @override
  String get sunTitle => '太阳';

  @override
  String get sunSectionDaylight => '日照';

  @override
  String get sunSectionTwilight => '曙暮光';

  @override
  String get sunSectionLight => '光线';

  @override
  String get sunSectionSundial => '日晷';

  @override
  String get sunSectionTerms => '节气';

  @override
  String get sunRise => '日出';

  @override
  String get sunSet => '日落';

  @override
  String get sunNoon => '正午';

  @override
  String get sunDayLength => '白昼长度';

  @override
  String get sunTwilightCivil => '民用';

  @override
  String get sunTwilightNautical => '航海';

  @override
  String get sunTwilightAstronomical => '天文';

  @override
  String get sunGoldenHourMorning => '晨间黄金时刻';

  @override
  String get sunGoldenHourEvening => '昏间黄金时刻';

  @override
  String get sunBlueHour => '蓝调时刻';

  @override
  String get sunEquationOfTime => '均时差';

  @override
  String get sunMinutes => '分';

  @override
  String get solarTermNext => '下一个节气';

  @override
  String get planetsTitle => '行星';

  @override
  String get planetsSectionTonight => '此刻';

  @override
  String get planetUp => '地平线上';

  @override
  String get planetDown => '地平线下';

  @override
  String get planetInGlare => '太近太阳';

  @override
  String get planetMagnitude => '亮度';

  @override
  String get planetElongation => '距日距角';

  @override
  String get planetSky => '时段';

  @override
  String get planetEvening => '昏星';

  @override
  String get planetMorning => '晨星';

  @override
  String get planetDistance => '距离';

  @override
  String get planetAu => '天文单位';

  @override
  String get planetAltitude => '仰角';

  @override
  String get planetMercury => '水星';

  @override
  String get planetVenus => '金星';

  @override
  String get planetMars => '火星';

  @override
  String get planetJupiter => '木星';

  @override
  String get planetSaturn => '土星';

  @override
  String get planetUranus => '天王星';

  @override
  String get planetNeptune => '海王星';

  @override
  String get solarTermVernalEquinox => '春分';

  @override
  String get solarTermPureBrightness => '清明';

  @override
  String get solarTermGrainRain => '谷雨';

  @override
  String get solarTermStartOfSummer => '立夏';

  @override
  String get solarTermGrainFull => '小满';

  @override
  String get solarTermGrainInEar => '芒种';

  @override
  String get solarTermSummerSolstice => '夏至';

  @override
  String get solarTermMinorHeat => '小暑';

  @override
  String get solarTermMajorHeat => '大暑';

  @override
  String get solarTermStartOfAutumn => '立秋';

  @override
  String get solarTermEndOfHeat => '处暑';

  @override
  String get solarTermWhiteDew => '白露';

  @override
  String get solarTermAutumnalEquinox => '秋分';

  @override
  String get solarTermColdDew => '寒露';

  @override
  String get solarTermFrostDescent => '霜降';

  @override
  String get solarTermStartOfWinter => '立冬';

  @override
  String get solarTermMinorSnow => '小雪';

  @override
  String get solarTermMajorSnow => '大雪';

  @override
  String get solarTermWinterSolstice => '冬至';

  @override
  String get solarTermMinorCold => '小寒';

  @override
  String get solarTermMajorCold => '大寒';

  @override
  String get solarTermStartOfSpring => '立春';

  @override
  String get solarTermRainWater => '雨水';

  @override
  String get solarTermAwakeningOfInsects => '惊蛰';

  @override
  String get tonightTitle => '今夜';

  @override
  String get tonightSectionDark => '观测窗口';

  @override
  String get tonightAstronomicalNight => '天文夜';

  @override
  String get tonightNeverDark => '整夜不全暗';

  @override
  String get tonightDarkWindow => '暗窗';

  @override
  String get tonightMoonAllNight => '月亮整夜在天上';

  @override
  String get tonightDarkTotal => '總暗时';

  @override
  String get tonightMoonlight => '月光';

  @override
  String get tonightSectionShowers => '流星雨';

  @override
  String get tonightRadiantDown => '輻射点不升起';

  @override
  String get tonightPerHour => '颗/时';

  @override
  String get tonightSectionSatellites => '卫星过境';

  @override
  String get tonightSectionTargets => '此刻可观测目標';

  @override
  String get showerQuadrantids => '象限儀座';

  @override
  String get showerLyrids => '天琴座';

  @override
  String get showerEtaAquariids => '寶瓶座η';

  @override
  String get showerDeltaAquariids => '寶瓶座δ';

  @override
  String get showerPerseids => '英仙座';

  @override
  String get showerOrionids => '獵戶座';

  @override
  String get showerSouthernTaurids => '金牛座南';

  @override
  String get showerLeonids => '獅子座';

  @override
  String get showerGeminids => '雙子座';

  @override
  String get showerUrsids => '小熊座';

  @override
  String get deepSkyOpenCluster => '疏散星团';

  @override
  String get deepSkyGlobularCluster => '球狀星团';

  @override
  String get deepSkySpiralGalaxy => '螺旋星系';

  @override
  String get deepSkyEllipticalGalaxy => '椭圆星系';

  @override
  String get deepSkyIrregularGalaxy => '不規则星系';

  @override
  String get deepSkyPlanetaryNebula => '行星狀星云';

  @override
  String get deepSkySupernovaRemnant => '超新星遗迹';

  @override
  String get deepSkyEmissionNebula => '发射星云';

  @override
  String get deepSkyReflectionNebula => '反射星云';

  @override
  String get deepSkyAsterism => '星群';

  @override
  String get almanacTitle => '历法';

  @override
  String get almanacSectionToday => '今日';

  @override
  String get almanacGregorian => '西历';

  @override
  String get almanacLunar => '农历';

  @override
  String get almanacYear => '岁次';

  @override
  String get almanacMonthLength => '月大小';

  @override
  String get almanacLongMonth => '三十日';

  @override
  String get almanacShortMonth => '二十九日';

  @override
  String get almanacLeapPrefix => '闰';

  @override
  String get almanacSectionLunarEclipses => '月食';

  @override
  String get almanacSectionSolarEclipses => '日食';

  @override
  String get almanacNoSolarEclipse => '范围內無';

  @override
  String get eclipseTotal => '全食';

  @override
  String get eclipsePartial => '偏食';

  @override
  String get eclipseAnnular => '环食';

  @override
  String get eclipsePenumbral => '半影食';

  @override
  String get zodiacRat => '鼠';

  @override
  String get zodiacOx => '牛';

  @override
  String get zodiacTiger => '虎';

  @override
  String get zodiacRabbit => '兔';

  @override
  String get zodiacDragon => '龙';

  @override
  String get zodiacSnake => '蛇';

  @override
  String get zodiacHorse => '马';

  @override
  String get zodiacGoat => '羊';

  @override
  String get zodiacMonkey => '猴';

  @override
  String get zodiacRooster => '鸡';

  @override
  String get zodiacDog => '狗';

  @override
  String get zodiacPig => '猪';

  @override
  String get tideTitle => '潮汐';

  @override
  String get tideDisclaimer => '仅为天文引潮力，非港口潮汐表。水位請参考气象署公布之潮汐预报。';

  @override
  String get tideSectionNow => '此刻';

  @override
  String get tidePhase => '周期';

  @override
  String get tideSpring => '大潮';

  @override
  String get tideNeap => '小潮';

  @override
  String get tideMiddling => '中潮';

  @override
  String get tideLunarDistanceFactor => '月球引力';

  @override
  String get tideEquilibrium => '平衡潮高';

  @override
  String get tideMetres => '公尺';

  @override
  String get tidePerigeanSpring => '下次近地点大潮';

  @override
  String get tideSectionTurningPoints => '转折点';

  @override
  String get tideHigh => '高';

  @override
  String get tideLow => '低';

  @override
  String get skyChartTitle => '星图';

  @override
  String get skyChartNorth => '北';

  @override
  String get skyChartEast => '东';

  @override
  String get skyChartSouth => '南';

  @override
  String get skyChartWest => '西';

  @override
  String tonightElementAge(int days) {
    return '轨道数据 $days 天前';
  }

  @override
  String almanacLunarDate(String leap, int month, int day) {
    return '$leap$month 月 $day 日';
  }

  @override
  String get tonightNoShowers => '目前无流星雨';

  @override
  String get tonightNoPasses => '48 小时内无可见过境';

  @override
  String get tonightSatellitesUnavailable => '无法读取轨道数据';

  @override
  String get tonightNoTargets => '无足够高度的目标';

  @override
  String get skyChartUnavailable => '无法读取星表';

  @override
  String get permissionSettingsTitle => '请到系统设置开启';

  @override
  String get permissionSettingsHint => '返回 App 后会自动重新检查。';

  @override
  String get permissionOpenSettings => '前往设置';

  @override
  String permissionSettingsMessage(String what) {
    return '「$what」已被拒绝，系统不会再询问。请到设置中开启。';
  }

  @override
  String get permissionGuideNotification => '请到系统设置中开启通知权限。';

  @override
  String get permissionGuideForegroundLocation => '请到系统设置中开启精确位置权限。';

  @override
  String permissionGuideBackgroundLocation(Object option) {
    return '请在「$option」中改为「允许所有时间」。';
  }

  @override
  String get permissionGuideBackgroundExecution =>
      '请到系统设置中允许后台执行,避免收到通知时被系统暂停。';

  @override
  String get permissionGuideUnusedPause => '若应用被标记为「未使用」,请在系统设置中改为「允许」。';

  @override
  String get permissionGuideUnusedFreeSpace => '若应用因缓存空间不足被暂停,请清除缓存后重新打开。';

  @override
  String get permissionGuideUnusedRevoke => '若应用权限被撤销,请在系统设置中重新授予。';

  @override
  String get permissionGuideUnusedPlayProtect =>
      '若被 Play 保护机制暂停,请到 Google Play 中检查应用状态。';

  @override
  String permissionGuideVendorPower(Object vendor) {
    return '请到「$vendor」的省电设置中,将本应用设为「不限制」。';
  }

  @override
  String get permissionStillRequired => '仍然需要此权限,请到设置中打开。';

  @override
  String get permissionVerifyManually => '请手动确认此权限已在系统设置中打开。';

  @override
  String get permissionBackgroundLocationOption => '「允许所有时间」';

  @override
  String get displayTextSize => '文字大小';

  @override
  String get displayTextSizeDesc => '只调整应用界面的文字，地图上的文字大小不变。';

  @override
  String get displayTextWeight => '文字粗细';

  @override
  String get displayTextWeightDesc => '文字加粗后通常更容易阅读。';

  @override
  String get displayContrast => '对比度';

  @override
  String get displayContrastDesc => '提高对比度可以让文字与背景分得更清楚。';

  @override
  String get displayColorVision => '色觉调整';

  @override
  String get displayColorVisionDesc => '应用与地图的颜色都会一起调整。';

  @override
  String get displayColorVisionNone => '不调整';

  @override
  String get displayColorVisionProtan => '红色弱';

  @override
  String get displayColorVisionDeutan => '绿色弱';

  @override
  String get displayColorVisionTritan => '蓝黄色弱';

  @override
  String get displayPreviewSample => '地震报告范例';

  @override
  String get displayScaleSmall => '小';

  @override
  String get displayScaleDefault => '默认';

  @override
  String get displayScaleLarge => '大';

  @override
  String get displayScaleHuge => '特大';

  @override
  String get displayWeightNormal => '标准';

  @override
  String get displayWeightMedium => '中等';

  @override
  String get displayWeightBold => '粗体';

  @override
  String get displayContrastStandard => '标准';

  @override
  String get displayContrastMedium => '中等';

  @override
  String get displayContrastHigh => '高';

  @override
  String get meshtasticDirect => '直连';

  @override
  String meshtasticHopsAway(int n) {
    return '$n 跳';
  }

  @override
  String get meshtasticStatRelayShare => '为他人转发';

  @override
  String get meshtasticStatRelayShareHint => '占本机发送量的比例';

  @override
  String get meshtasticStatRelayValue => '转发成功率';

  @override
  String get meshtasticStatRelaySolePath => '经常是唯一路径 — 网络依赖此节点';

  @override
  String get meshtasticStatRelayRedundant => '其他节点也覆盖同样路径';

  @override
  String get meshtasticStatRedundancy => '重复接收';

  @override
  String get meshtasticStatThinEdge => '备援路径少 — 一个中继失效就可能断线';

  @override
  String get meshtasticStatWellCovered => '有多条路径可达';

  @override
  String get meshtasticStatErrorRate => '接收错误率';

  @override
  String get meshtasticStatErrorRateHint => '空中时间不变却升高 = 干扰';

  @override
  String get meshtasticTraceRoute => '追蹤路由';

  @override
  String get meshtasticTracing => '追蹤中…';

  @override
  String get meshtasticTraceUnreadable => '无法解读的回复';

  @override
  String get meshtasticTraceOffline => '未连接至电台';

  @override
  String get meshtasticTraceCooldown => '电台限制每 30 秒一次';

  @override
  String get meshtasticTraceNoReply => '沒有回應 — 超出範圍或金鑰不同';

  @override
  String get meshtasticTraceDirect => '直達 — 中間無中繼';

  @override
  String meshtasticTraceHops(int n) {
    return '$n 跳';
  }

  @override
  String get moreDumpDiagnostics => '转储调试信息及日志';

  @override
  String get moreDumpDiagnosticsHint => '上传后复制链接，附在反馈里就不用贴一整页';

  @override
  String get dumpIncludeSensitive => '包含精确位置';

  @override
  String get dumpIncludeSensitiveHint => '包含日志和后台定位中的坐标；未勾选时将以 null 替代';

  @override
  String get dumpUpload => '上传';

  @override
  String get dumpUploaded => '已上传';

  @override
  String get dumpLinkCopied => '链接已复制到剪贴板';

  @override
  String get dumpCopyAgain => '再复制一次';

  @override
  String get dumpUploadFailed => '上传失败，请稍后再试';

  @override
  String get statusLegendUnprobed => '未探测';

  @override
  String get statusLegendUnsupported => '不支持';

  @override
  String get rainScaleSection => '色阶间距';

  @override
  String get rainScaleFine => '小间距';

  @override
  String get rainScaleCoarse => '大间距';

  @override
  String get notifyTestTitle => '测试通知';

  @override
  String get notifyTestIntro => '点一下就会实际发送该则警报。重大警报会以最大音量播放，并穿透静音与勿扰模式。';

  @override
  String get notifyTestCriticalDenied => '这台设备未允许「重要警告」，重大警报在静音时同样不会发出声音。';

  @override
  String get notifyTestPermissionOff => '通知已关闭，测试不会有任何反应。';

  @override
  String get notifyTestBehaviourOverrides => '会穿透静音与勿扰模式';

  @override
  String get notifyTestBehaviourAlerts => '有声音并弹出横幅，但手机静音时不会响';

  @override
  String get notifyTestBehaviourSounds => '有声音、不弹出横幅，手机静音时不会响';

  @override
  String get notifyTestBehaviourSilent => '无声，只出现在通知中心';

  @override
  String get notifyTestFailed => '无法发送测试通知。';

  @override
  String get moreBugReports => '已回报的错误';

  @override
  String get bugTrackerEmpty => '还没有已回报的错误';

  @override
  String get bugTrackerReplies => '回复';

  @override
  String get bugTrackerGoToDiscord => '找不到你的问题？快前往 Discord 回报！';

  @override
  String get bugTrackerNoMatch => '没有符合所选标签的错误回报';

  @override
  String get bugTrackerDeveloper => '开发人员';

  @override
  String get bugTrackerCannotDisplay => '无法显示此内容，请在 Discord 上查看';

  @override
  String get bugTrackerJoinDiscussion => '至 Discord 参与讨论';

  @override
  String get bugTrackerSortLast => '最后讨论';

  @override
  String get bugTrackerSortMostDiscussed => '最多讨论';

  @override
  String get bugTrackerStaff => '工作人员';

  @override
  String eewSpokenLocalIntensity(String intensity) {
    return '所在地预估烈度，$intensity。';
  }

  @override
  String eewSpokenMaxIntensity(String intensity) {
    return '预估最大烈度，$intensity。';
  }
}

/// The translations for Chinese, as used in Hong Kong, using the Han script (`zh_Hant_HK`).
class AppLocalizationsZhHantHk extends AppLocalizationsZh {
  AppLocalizationsZhHantHk() : super('zh_Hant_HK');

  @override
  String typhoonValueLat(String lat) {
    return '北緯 $lat 度';
  }

  @override
  String get onboardingSkipBody =>
      '未授權定位與通知,DPIP 將無法即時通知你所在地的地震與災害。你仍可稍後在設定中開啟。';

  @override
  String get rainInterval24h => '24 時';

  @override
  String homeRainTrendHeavyStopping(int minutes) {
    return '預計 $minutes 分鐘後停止下大雨';
  }

  @override
  String get mapTimelineObserved => '觀測';

  @override
  String get mapTimelineScrubPaused => '拖動過快，影格更新已暫停；放慢速度即可恢復。';

  @override
  String get regionSelectTitle => '選擇地區';

  @override
  String get skyTimeNoon => '正午';

  @override
  String get radarCountyOutlineSubtitle => '讓縣市界線在雷達回波下仍然清楚。';

  @override
  String get mapLayerSatelliteB03 => 'ひまわり 可見光-紅(B03)';

  @override
  String get reportFilterIntensity => '震度';

  @override
  String get mapLayerLightning => '閃電';

  @override
  String get restroomTypeMale => '男廁所';

  @override
  String get meshtasticLastReceived => '最近接收';

  @override
  String get reportDetailSortByCounty => '依縣市排序';

  @override
  String get onboardingPermUnusedApp => '保持 App 啟用';

  @override
  String get onboardingPermUnusedAppDesc =>
      'Android 會暫停你長期未開啟嘅 App 並撤銷佢哋嘅權限，噉會令災害警報無法送到你所在地。';

  @override
  String get onboardingPermBackgroundExec => '背景執行';

  @override
  String get onboardingPermBackgroundExecDesc => '關閉時，App 不會被喚醒回報你的位置。';

  @override
  String get onboardingPermVendorPower => '手機廠商省電設定';

  @override
  String onboardingPermVendorPowerDesc(String brand) {
    return '$brand 會停止你最近沒開過的 App 的背景作業。App 無法偵測或變更，請手動允許。';
  }

  @override
  String get homeRainTrendScattered => '可能會有零星降雨';

  @override
  String get meshtasticUptime => '運行時間';

  @override
  String get weatherRankingTempExtremes => '溫度極值';

  @override
  String get themeLight => '淺色';

  @override
  String get mapTerrainReliefHint => '在底圖上顯示立體地形陰影';

  @override
  String get meshtasticEmptyMessage => '（空白訊息）';

  @override
  String get moreSectionRegion => '地區';

  @override
  String get mapLayerSatellite => 'ひまわり 紅外線(B13)';

  @override
  String get aedHoursSaturday => '週六開放時間';

  @override
  String get moonPhaseNew => '新月';

  @override
  String get notifySectionEew => '地震速報';

  @override
  String get mapResetNorth => '回到北方';

  @override
  String get rainInterval2d => '2 日';

  @override
  String get mapTownLabelsHint => '放大時顯示鄉鎮名稱';

  @override
  String get commonCancel => '取消';

  @override
  String get notifyOptTsunamiWarning => '只接收海嘯警報';

  @override
  String get mapLayerSatelliteBtdFog => 'ひまわり 夜間霧';

  @override
  String get moreSectionAdvanced => '進階';

  @override
  String get moreSectionMesh => 'Mesh 網絡';

  @override
  String get weatherRankingExtremeRange => '日溫差';

  @override
  String get permissionsTitle => '權限檢查';

  @override
  String get permissionsAttention => '權限需要處理';

  @override
  String get permissionsBody => 'DPIP 需要這些權限才能即時通知你。收不到警報時，通常就是其中一項尚未開啟。';

  @override
  String get notifySettingsMenu => '通知設定';

  @override
  String mapAppDefault(String app) {
    return '$app（預設）';
  }

  @override
  String get trendRange24h => '24 小時';

  @override
  String get mapLayerStyleJmaTooltip => '灰階為底，−40 °C 以下上色，凸顯雲頂高度';

  @override
  String get mapLayerRain => '雨量';

  @override
  String get mapLayerQpesums => '未來 1 小時降水預報';

  @override
  String get mapOverlaySectionMap => '地圖';

  @override
  String get mapTerrainRelief => '地形立體感';

  @override
  String get mapLegendCollapse => '收合圖例';

  @override
  String get updateAvailableTitle => '有新版本';

  @override
  String updateAvailableBody(String version) {
    return '新版本 $version 已發佈。';
  }

  @override
  String get updateSkip => '略過此次';

  @override
  String get updateViewChangelog => '前往查看';

  @override
  String get updateOpenAppStore => 'App Store';

  @override
  String get updateOpenTestFlight => 'TestFlight';

  @override
  String get updateOpenPlayStore => 'Play 商店';

  @override
  String get updateDownload => '下載更新';

  @override
  String get changelogShowSnapshots => '顯示測試版';

  @override
  String get changelogTitle => '更新日誌';

  @override
  String get reportFilterOrderDesc => '降序';

  @override
  String get meshtasticExcludeMqttSubtitle => '經網際網路橋接、並非無線電聽到的節點';

  @override
  String get reportFilterIntensityInfoTitle => '震度新制與舊制';

  @override
  String get mapLayerTyphoon => '颱風';

  @override
  String get radarOverlayMenuTooltip => '雷達圖層選項';

  @override
  String get meshtasticNodes => '節點';

  @override
  String get meshtasticSend => '傳送';

  @override
  String get typhoonOverlayStormL7Tooltip => '七級暴風圈＋平均圓（紫色）';

  @override
  String get aedType => '場所類型';

  @override
  String get termsOfService => '服務條款';

  @override
  String get typhoonLegendCircle25 => '十級風暴風圈';

  @override
  String get sponsorTitle => '支援 DPIP';

  @override
  String get mapNavSatellite => '衛星';

  @override
  String homeRainTrendUpdated(String time) {
    return '更新 $time';
  }

  @override
  String get onboardingNext => '下一步';

  @override
  String get weatherRankingMergeTown => '鄉鎮';

  @override
  String get mapLayerMonitor => '強震監視器';

  @override
  String get moreYoutube => 'YouTube';

  @override
  String get sponsorSubscriptions => '訂閱制';

  @override
  String typhoonValueLon(String lon) {
    return '東經 $lon 度';
  }

  @override
  String get skyTime => '天空時間';

  @override
  String get weatherModeCloudy => '多雲';

  @override
  String get skyTimeDusk => '暮色';

  @override
  String get meshtasticFirmware => '韌體';

  @override
  String get reportFilterDateEndNote => '結束日：當日 24:00（台北時間）';

  @override
  String get reportFilterSortMagnitude => '規模';

  @override
  String get meshtasticSilent => '已靜默';

  @override
  String get mapLayerCategoryEarthquake => '地震';

  @override
  String get mapLayerSatelliteB12 => 'ひまわり 臭氧(B12)';

  @override
  String get restroomCategoryOther => '其他';

  @override
  String homeForecastHighLow(String high, String low) {
    return '高 $high° · 低 $low°';
  }

  @override
  String get locationBannerFix => '開啟設定';

  @override
  String get mapLegendExpand => '圖例';

  @override
  String get eewNone => '目前沒有地震速報';

  @override
  String typhoonTyNo(String no) {
    return 'TY $no';
  }

  @override
  String get notifyOptTsunamiAll => '海嘯消息、海嘯警報';

  @override
  String get meshtasticLayerOptions => '節點選項';

  @override
  String get onboardingAgreeContinue => '同意並繼續';

  @override
  String get commonRetry => '重試';

  @override
  String get meshtasticNodeId => '節點 ID';

  @override
  String reportDetailNumbered(String number) {
    return '編號 $number 顯著有感地震';
  }

  @override
  String get typhoonOverlayStormBandSubtitle => '含平均圓';

  @override
  String get disasterMapOverlayRestroomTooltip => '顯示公廁';

  @override
  String get weatherRankingTitle => '觀測排行';

  @override
  String get homeRainTrendHeavySustained => '未來 1 小時會有持續大雨';

  @override
  String get notifySectionTsunami => '海嘯';

  @override
  String get restroomCategoryPark => '公園';

  @override
  String get moreLinkOpenFailed => '無法開啟連結';

  @override
  String get themeDark => '深色';

  @override
  String get sponsorRestore => '恢復購買';

  @override
  String get meshtasticChannelWorking => '正在設定 DPIP 頻道…';

  @override
  String get meshtasticRegionSwitch => '切換為 TW';

  @override
  String get meshtasticTraffic => '流量';

  @override
  String get mapLayerStyleBdTooltip => 'Dvorak BD 曲線——熱帶氣旋強度分析的階梯灰階';

  @override
  String get disasterMapOverlayAedTooltip => '顯示 AED 位置';

  @override
  String get mapLayerHumidity => '濕度';

  @override
  String get mapLayerSatelliteTransparentNight => '夜間 = 透明,顯示底圖';

  @override
  String get meshtasticScanning => '掃描中…';

  @override
  String regionSelectFull(int max) {
    return '最多只能選擇 $max 個地區';
  }

  @override
  String get meshtasticNewMessages => '新訊息';

  @override
  String get meshtasticBatteryHistory => '電量歷史';

  @override
  String get meshtasticStatAvg => '平均';

  @override
  String get meshtasticStatPeak => '峰值';

  @override
  String get meshtasticStatDrain => '掉電';

  @override
  String get meshtasticStatEta => '預估可用';

  @override
  String get meshtasticStatFull => '充滿';

  @override
  String get meshtasticStatTrend => '趨勢';

  @override
  String get meshtasticStatCharging => '充電中';

  @override
  String get meshtasticStatStable => '穩定';

  @override
  String get meshtasticNodesTotal => '已知';

  @override
  String get meshtasticNodesOnline => '在線';

  @override
  String get meshtasticRx => '接收';

  @override
  String get meshtasticTx => '發送';

  @override
  String get meshtasticNodesHistory => '節點數歷史';

  @override
  String get meshtasticTrafficHistory => '流量歷史';

  @override
  String meshtasticEtaHours(int n) {
    return '約 $n 小時';
  }

  @override
  String meshtasticEtaDays(int n) {
    return '約 $n 天';
  }

  @override
  String get meshtasticTitle => 'Meshtastic';

  @override
  String get navMore => '更多';

  @override
  String get meshtasticDpipChannel => 'DPIP 頻道';

  @override
  String get disasterMapOverlaySectionLayers => '圖層';

  @override
  String get mapLayerSatelliteB05 => 'ひまわり 近紅外(B05)';

  @override
  String get typhoonLabelNe => '東北側';

  @override
  String get meshtasticCopied => '已複製訊息';

  @override
  String get reportListEmpty => '目前沒有地震報告';

  @override
  String get reportListEnd => '已到最後一頁';

  @override
  String get mapLayerSatelliteTruecolor => 'ひまわり 真彩色';

  @override
  String get typhoonOverlaySectionExtra => '覆蓋層';

  @override
  String get eewSWave => '震波';

  @override
  String get meshtasticBusyTitle => '另一個 App 正在使用這台裝置';

  @override
  String get restroomCategoryCultural => '文化育樂活動場所';

  @override
  String get typhoonLabelWind => '近中心最大風速';

  @override
  String get radarGlobalOutlineHint => '各國國界外框';

  @override
  String get notifyEvacuation => '防災資訊';

  @override
  String get typhoonLegendCircle15 => '七級風暴風圈';

  @override
  String get dataSectionAstronomy => '天文';

  @override
  String get homeRainTrendLightSustained => '未來 1 小時會有持續小雨';

  @override
  String get commonError => '發生錯誤';

  @override
  String get moonPhaseWaningCrescent => '殘月';

  @override
  String get meshtasticPower => '電力';

  @override
  String get mapTimelineNow => '現在';

  @override
  String reportFilterRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String get reportDetailOpenReport => '報告頁面';

  @override
  String get trendRange7d => '7 天';

  @override
  String typhoonWarningAreas(String areas) {
    return '警戒區域：$areas';
  }

  @override
  String get rainIntervalSection => '統計時間';

  @override
  String get notifyTitle => '通知';

  @override
  String get meshtasticTxPower => '發射功率';

  @override
  String get restroomCategoryLabel => '類別';

  @override
  String get sponsorRestoring => '正在恢復購買…';

  @override
  String get sponsorIntro =>
      'DPIP 致力於提供即時防災資訊，沒有廣告或其他營利模式。您的支援能幫助我們維持伺服器運作並持續開發。';

  @override
  String get typhoonLabelStormAvg => '十級風平均暴風半徑';

  @override
  String get restroomCategoryCommercial => '商業營業場所';

  @override
  String get aedRegion => '縣市區域';

  @override
  String homeRainTrendLightStopping(int minutes) {
    return '預計 $minutes 分鐘後停止下小雨';
  }

  @override
  String get reportDetailInfo => '詳細資訊';

  @override
  String get mapNavWind => '風向';

  @override
  String get windForecastOverlayMenuTooltip => '風場預報圖層選項';

  @override
  String homeRainTrendMinute(int minute) {
    return '$minute分';
  }

  @override
  String get rainInterval6h => '6 時';

  @override
  String get restroomTypeUnspecified => '未設定';

  @override
  String get typhoonOverlayProbabilityHint => '會隱藏預測圓錐';

  @override
  String get mapLayerSatelliteGlobalOutline => '國界';

  @override
  String get mapNavTemperature => '溫度';

  @override
  String get typhoonLegendForecastPoint => '預測點';

  @override
  String get reportListYesterday => '昨天';

  @override
  String get moreSectionLinks => '相關連結';

  @override
  String get feedOffline => '連接中斷';

  @override
  String get mapLayerStyleBd => 'Dvorak BD';

  @override
  String get moreSectionDisplay => '顯示';

  @override
  String get rainInterval3d => '3 日';

  @override
  String get defaultMapLayerSubtitle => '開啟地圖分頁時顯示此圖層，底部導覽列圖示與文字會一併更新。';

  @override
  String get aedDescription => '備註';

  @override
  String get typhoonOverlayWeatherRadarTooltip => '雷達回波（對齊颱風報文時間）';

  @override
  String get onboardingPermLocationDesc => '依你所在位置推送本地警報。';

  @override
  String get mapLayerSatelliteB16 => 'ひまわり 二氧化碳(B16)';

  @override
  String get homeActiveEventsEmpty => '目前沒有生效中的事件';

  @override
  String get typhoonLabelPosition => '中心位置';

  @override
  String get weatherRankingBy => '依';

  @override
  String get typhoonIntensityMild => '輕度颱風';

  @override
  String get windForecastGlobalOutlineHint => '各國國界外框';

  @override
  String get rainInterval1h => '1 時';

  @override
  String get eewLocalIntensity => '所在地預估';

  @override
  String get mapLayerRadar => '雷達合成回波圖';

  @override
  String get restroomCategoryReligious => '宗教禮儀場所';

  @override
  String get meshtasticRole => '角色';

  @override
  String get mapLayerSatelliteCloudCloudy => '有雲';

  @override
  String get skyTimeSunrise => '日出';

  @override
  String get meshtasticJumpToLatest => '跳到最新';

  @override
  String get meshtasticNoMessages => '尚無訊息';

  @override
  String get onboardingPermNotifyDesc => '在地震、天氣與災害發生時,即時傳遞警報通知。';

  @override
  String get radarTownOutline => '鄉鎮界線';

  @override
  String get mapLayerStyleSection => '顯示樣式';

  @override
  String get disasterMapOverlayMenuTooltip => '防災地圖圖層';

  @override
  String get moreGooglePlay => 'Google Play';

  @override
  String get meshtasticOnline => '近期聽到';

  @override
  String get typhoonLabelSw => '西南側';

  @override
  String typhoonForecastLead(String hours) {
    return '預測 +$hours 小時';
  }

  @override
  String get changelogTypeStable => '正式版';

  @override
  String get mapLayerSatelliteTransparentClear => '晴空 = 透明,顯示底圖';

  @override
  String get mapOverlaySectionReference => '參考圖層';

  @override
  String get mapLayerSatelliteB02 => 'ひまわり 可見光-綠(B02)';

  @override
  String get weatherRankingEmpty => '目前沒有可排序的觀測';

  @override
  String get notifySectionOther => '其他';

  @override
  String weatherRankingMeta(String time, int count) {
    return '資料時間：$time\n共 $count 觀測點';
  }

  @override
  String get onboardingTermsAgree => '我已閱讀並同意服務條款';

  @override
  String get mapLayerSatelliteTransparentNoVegetation => '< 0.1 = 透明(無植被)';

  @override
  String get notifyOptLocalIntensity4 => '所在地震度4以上';

  @override
  String get eewArrived => '已抵達';

  @override
  String get meshtasticNoDevices => '找不到 Meshtastic 裝置';

  @override
  String get mapLayerCategoryLife => '生活';

  @override
  String get reportFilterSortIntensity => '震度';

  @override
  String get meshtasticStateDisconnected => '未連線';

  @override
  String get typhoonIntensityIntense => '強烈颱風';

  @override
  String get mapLayerOrderTitle => '調整圖層順序';

  @override
  String get mapLayerShow => '顯示圖層';

  @override
  String get mapLayerHide => '隱藏圖層';

  @override
  String get mapLayerShowAll => '全部顯示';

  @override
  String get mapLayerHideAll => '全部隱藏';

  @override
  String get dpmYes => '是';

  @override
  String get meshtasticNoHistory => '歷史紀錄還不夠';

  @override
  String get reportDetailLocalIntensityUnavailable => '沒有震度訊息';

  @override
  String get mapLayerWindForecastGfs => 'GFS';

  @override
  String get reportFilterDepth => '深度';

  @override
  String get onboardingScrollHint => '向下捲動以繼續';

  @override
  String get mapNavQpesums => '預報';

  @override
  String get notifyAdvisory => '天氣警告及特報';

  @override
  String get reportFilterReset => '重設';

  @override
  String get mapLayerSatelliteMndwi => 'ひまわり 改良水體指數';

  @override
  String get typhoonOverlaySectionStorm => '暴風圈';

  @override
  String get moonPhaseFull => '滿月';

  @override
  String meshtasticBinaryPayload(String size) {
    return '二進位內容 · $size';
  }

  @override
  String get moonPhaseWaningGibbous => '虧凸月';

  @override
  String get reportFilterIntensityInfoModernTitle => '新制（2020 起）';

  @override
  String typhoonDataTime(String time) {
    return '資料時間\n$time';
  }

  @override
  String get restroomTypeAccessible => '無障礙廁所';

  @override
  String get moreSectionAbout => '關於';

  @override
  String get meshtasticSelectDevice => '選擇裝置';

  @override
  String get onboardingIntroBody =>
      'DPIP 是與你並肩的防災夥伴,整合強震即時警報、地震報告、天氣與各類災害資訊,在關鍵時刻即時通知你。\n\n• 地震:強震即時警報、震度速報與地震報告\n• 天氣:雷暴即時訊息、天氣警告及特報\n• 海嘯與防災資訊\n\n接下來,我們會請你閱讀服務條款,並授權幾項讓 DPIP 能即時守護你的權限。';

  @override
  String get shelterCapacityLabel => '收容人數';

  @override
  String get reportDetailImage => '地震報告圖';

  @override
  String get meshtasticStateConfiguring => '設定中…';

  @override
  String get typhoonLabelGaleAvg => '七級風平均暴風半徑';

  @override
  String get onboardingPermNotify => '通知';

  @override
  String get meshtasticClearMessages => '清除訊息';

  @override
  String get meshtasticNotifyMessages => '新訊息通知';

  @override
  String get defaultMapLayerSettings => '地圖預設圖層';

  @override
  String get eewSourceSettings => '地震速報來源';

  @override
  String get eewSourceSubtitle => '選擇要顯示哪些機構發布的地震速報。';

  @override
  String get eewSourceAll => '所有來源';

  @override
  String get eewSourceAllDescription => '顯示所有機構發布的地震速報。';

  @override
  String get eewSourceCwaOnly => '僅中央氣象署';

  @override
  String get eewSourceCwaOnlyDescription => '只顯示中央氣象署發布的地震速報。';

  @override
  String get moreSectionNotify => '通知';

  @override
  String get notifyUnavailable => '推送尚未就緒,請稍後再試。';

  @override
  String get mapLayerOrderReset => '回復預設順序';

  @override
  String get weatherRankingMergeCounty => '縣市';

  @override
  String get moreSectionApp => '取得 App';

  @override
  String get moreSectionBeta => '測試版';

  @override
  String get moreAndroidBeta => 'Android 測試版';

  @override
  String get moreTestFlight => 'iOS 測試版（TestFlight）';

  @override
  String get moreSectionPartners => '合作夥伴';

  @override
  String get morePartnersNote => '依合作時間先後排列。感謝這些個人與公司對防災的貢獻，他們讓 DPIP 成為可能。';

  @override
  String get morePartnerGeoscience => '巨科資訊有限公司';

  @override
  String get morePartnerTwds => '台灣數位串流有限公司';

  @override
  String get reportFilterIntensityInfoLegacyBody => '震度僅 0–7，沒有 5弱／5強／6弱／6強。';

  @override
  String get mapLayerSatelliteSst => 'ひまわり 海表溫度';

  @override
  String get qpesumsOverlayMenuTooltip => '定量降水預報圖層選項';

  @override
  String get mapTimelineFuture => '未來';

  @override
  String get typhoonLegendCircleAvg => '平均圓';

  @override
  String reportFilterDepthKm(String depth) {
    return '$depth 公里';
  }

  @override
  String get typhoonLabelSe => '東南側';

  @override
  String get radarTownOutlineHint => '較細的分區';

  @override
  String eewCountdown(int seconds) {
    return '$seconds 秒';
  }

  @override
  String get typhoonLabelGust => '瞬間最大陣風';

  @override
  String get mapAppGoogleMaps => 'Google Maps';

  @override
  String get sponsorTerms => '使用條款';

  @override
  String get restroomTypeGenderNeutral => '性別友善廁所';

  @override
  String get notifyThunderstorm => '雷暴即時訊息';

  @override
  String get skyTimeGolden => '黃金時刻';

  @override
  String get moonAge => '月齡';

  @override
  String get meshtasticRadioSettings => 'LoRa';

  @override
  String get moreGithub => 'ExpTech GitHub';

  @override
  String get homeForecastUnavailable => '選擇地區後可查看預報';

  @override
  String get mapLayers => '圖層';

  @override
  String get meshtasticHardware => '硬體';

  @override
  String get languageSettings => '語言設定';

  @override
  String get language => '語言';

  @override
  String homeForecastFeelsLike(String temp) {
    return '體感 $temp°';
  }

  @override
  String get typhoonOverlayWeatherHint => '對齊報文時間';

  @override
  String get skyTimeDawn => '黎明';

  @override
  String get skyTimeAfternoon => '下午';

  @override
  String get meshtasticLastHeard => '最後聽到';

  @override
  String get typhoonWarningTitle => '颱風警報';

  @override
  String get moreSourceCode => '原始碼';

  @override
  String get mapLayerCategoryWeather => '氣象觀測';

  @override
  String get mapLayerSatelliteB09 => 'ひまわり 中層水氣(B09)';

  @override
  String get windForecastTownOutlineHint => '更細的網格';

  @override
  String get mapLayerSatelliteCloudmask => 'ひまわり 雲遮罩';

  @override
  String get mapAppCopyCoordinates => '複製座標';

  @override
  String get reportFilterIntensityInfoIntro =>
      '中央氣象署自 2020 年 1 月 1 日（臺北時間）起改用新制震度。';

  @override
  String get mapNavEarthquake => '地震';

  @override
  String get restroomGradeAverage => '普通級';

  @override
  String get mapLayerSatelliteBtdCo2 => 'ひまわり 卷雲/雲高';

  @override
  String get onboardingPermBackgroundDesc => '選擇「一律允許」,關閉 App 也能推送本地警報。';

  @override
  String get mapTimelineForecast => '預報';

  @override
  String get restroomTypeLabel => '廁所類型';

  @override
  String get navEarthquake => '地震';

  @override
  String get typhoonOverlayStormL10Tooltip => '十級暴風圈＋平均圓（黃色）';

  @override
  String get moonPhaseWaxingGibbous => '盈凸月';

  @override
  String get reportDetailTitle => '地震報告';

  @override
  String get moreTremReport => 'TREM 偵測報告';

  @override
  String weatherDataTime(String station, String time) {
    return '$station ∙ 資料時間 $time';
  }

  @override
  String get meshtasticNoNodes => '尚未聽到任何節點';

  @override
  String get meshtasticViaMqtt => '經 MQTT（網際網路）';

  @override
  String get radarCountyOutline => '縣市界線';

  @override
  String get commonClose => '關閉';

  @override
  String get restroomGradeLabel => '等級';

  @override
  String get rainIntervalNow => '今日';

  @override
  String get changelogCurrentVersion => '目前版本';

  @override
  String get typhoonLabelPressure => '中心氣壓';

  @override
  String get typhoonOverlayForecastCalloutsTooltip => '放大時顯示預測點詳細卡片';

  @override
  String get aedOpenRemark => '開放時間備註';

  @override
  String get onboardingPermsBody => '為了在災害發生的第一時間通知你,請授權以下權限。你隨時可以在系統設定中更改。';

  @override
  String get typhoonOverlaySectionWeather => '天氣底圖';

  @override
  String get notifyOptWeatherLocal => '接收所在地';

  @override
  String get mapNavRain => '雨量';

  @override
  String get moonDays => '天';

  @override
  String mapLegendUnit(String unit) {
    return '單位：$unit';
  }

  @override
  String get weatherModeClear => '晴天';

  @override
  String get meshtasticRadio => '電台';

  @override
  String get commonEmpty => '沒有資料';

  @override
  String get mapLayerSatelliteB01 => 'ひまわり 可見光-藍(B01)';

  @override
  String get meshtasticExternalPower => '外部供電';

  @override
  String get moonPhaseLastQuarter => '下弦月';

  @override
  String get reportFilterOrderAsc => '升序';

  @override
  String get reportFilterApply => '套用';

  @override
  String get reportDetailImageUnavailable => '報告圖尚未提供';

  @override
  String get weatherRankingHighest => '最高';

  @override
  String get reportDetailReplay => '重播';

  @override
  String get mapLayerRestroom => '公廁';

  @override
  String get restroomCategoryWelfare => '社福機構、集會場所';

  @override
  String get restroomGradeExcellent => '特優級';

  @override
  String get meshtasticLastSent => '最近送出';

  @override
  String get meshtasticName => '名稱';

  @override
  String get meshtasticScan => '掃描';

  @override
  String get mapLayerCategoryForecast => '數值預報';

  @override
  String get meshtasticChannelFailed => '無法設定 DPIP 頻道';

  @override
  String get themeSystem => '跟隨系統';

  @override
  String get mapLayerSatelliteNdvi => 'ひまわり 植生指數';

  @override
  String get typhoonLegendForecast => '預測路徑';

  @override
  String typhoonValueHpa(String n) {
    return '$n 百帕';
  }

  @override
  String get weatherPrecipitation => '降水量';

  @override
  String get moonNextFullMoon => '下次滿月';

  @override
  String get dpmSheetEmpty => '點選地圖上的標記查看詳情';

  @override
  String get onboardingSkipLeave => '仍要略過';

  @override
  String get aedPlaceDesc => '放置位置說明';

  @override
  String get onboardingSkipTitle => '尚未完成授權';

  @override
  String get restroomTypeFamily => '親子廁所';

  @override
  String typhoonValueKm(String n) {
    return '$n 公里';
  }

  @override
  String get onboardingPermBattery => '省電白名單';

  @override
  String get typhoonLabelNw => '西北側';

  @override
  String get moonPhaseWaxingCrescent => '眉月';

  @override
  String get restroomCategoryLeisure => '休閒娛樂場所';

  @override
  String get mapLayerTemperature => '溫度';

  @override
  String get aedCategory => '場所分類';

  @override
  String get meshtasticChannels => '頻道';

  @override
  String get monitorWaiting => '等待資料…';

  @override
  String get typhoonOverlayForecastCallouts => '預測點資訊';

  @override
  String get reportDetailEpicenter => '震央座標';

  @override
  String get meshtasticVoltage => '電壓';

  @override
  String get mapLayerMeshtasticSubtitle => '電台聽到過的 LoRa 網狀網路節點';

  @override
  String get mapLayerWind => '風向';

  @override
  String get reportDetailMagnitude => '地震規模';

  @override
  String get reportDetailAreaIntensity => '各地震度';

  @override
  String get rainInterval12h => '12 時';

  @override
  String reportListMagnitude(String magnitude) {
    return 'M$magnitude';
  }

  @override
  String get notifyMonitor => '強震監視器';

  @override
  String get onboardingStart => '開始使用';

  @override
  String sponsorPerMonth(String price) {
    return '$price / 月';
  }

  @override
  String get mapLayerPressure => '氣壓';

  @override
  String get mapLayerSatelliteB04 => 'ひまわり 近紅外(B04)';

  @override
  String get mapLayerSatelliteTransparentZero => '零差值 = 透明(無訊號)';

  @override
  String get shelterIndoorLabel => '室內收容';

  @override
  String get notifyOptOff => '關閉';

  @override
  String get reportFilterSortTime => '時間';

  @override
  String get mapLayerSatelliteCloudProbablyClear => '可能晴空';

  @override
  String get weatherModeThunderstorm => '雷暴';

  @override
  String get homeViewOnMap => '前往地圖察看';

  @override
  String get reportFilterIntensityInfoLegacyTitle => '舊制（2020 以前）';

  @override
  String get typhoonLabelSpeed => '過去移動時速';

  @override
  String mapAppOpenFailed(String app) {
    return '無法開啟 $app';
  }

  @override
  String get mapLayerSatelliteRgbComposite => 'RGB 合成(JMA 配方)';

  @override
  String get meshtasticReceived => '已接收';

  @override
  String get weatherRankingExtremeLow => '今日最低';

  @override
  String get mapLayerSatelliteB10 => 'ひまわり 低層水氣(B10)';

  @override
  String get mapLayerSatelliteCloudProbablyCloudy => '可能有雲';

  @override
  String get mapLayerSatelliteTransparentNoWater => '≤ 0 = 透明(無水體)';

  @override
  String get shelterCategoryLabel => '適用災害';

  @override
  String get meshtasticStateConnecting => '連線中…';

  @override
  String get moonTitle => '月亮';

  @override
  String get weatherRankingGust => '陣風';

  @override
  String get moreAppStore => 'App Store';

  @override
  String get moreServerStatus => '伺服器狀態';

  @override
  String get notifySectionWeather => '天氣';

  @override
  String get meshtasticPreset => '調變預設';

  @override
  String get dataSectionSeismic => '地震';

  @override
  String get changelogBodyEmpty => '此版本沒有說明。';

  @override
  String get changelogOpenOnGitHub => '在 GitHub 查看';

  @override
  String get radarGlobalOutline => '國界';

  @override
  String get notifyEew => '緊急地震速報';

  @override
  String get regionNationwide => '全國';

  @override
  String get moreNotifyLog => 'DPIP 通知發送記錄';

  @override
  String get regionCurrent => '所在地';

  @override
  String get meshtasticNotConnected => '尚未連線至裝置';

  @override
  String get weatherModeSnow => '下雪';

  @override
  String get mapLayerMeshtastic => 'Meshtastic 節點';

  @override
  String get moreDeveloper => '偵錯資訊';

  @override
  String get mapLayerSatelliteB14 => 'ひまわり 長波紅外線(B14)';

  @override
  String get meshtasticChannelUse => '頻道使用率';

  @override
  String get mapNavLightning => '閃電';

  @override
  String get homeForecastEmpty => '目前沒有預報資料';

  @override
  String get sponsorOneTime => '單次支援';

  @override
  String get mapLayerSatelliteBtdSplit => 'ひまわり 分割視窗';

  @override
  String get onboardingPermBackground => '背景定位';

  @override
  String get aedEmergencyPhone => '緊急聯絡電話';

  @override
  String get dpmOpenInMaps => '開啟地圖';

  @override
  String get meshtasticNotifyNodes => '新節點通知';

  @override
  String get onboardingPermCriticalDesc => '讓危及生命的強震即時警報,即使在靜音或勿擾模式下也能發出聲響。';

  @override
  String get mapLayerSatelliteTransparentWarm => '晴空(暖端) = 透明,顯示底圖';

  @override
  String get meshtasticSent => '已送出';

  @override
  String get homeForecastTitle => '24小時預報';

  @override
  String get typhoonLegendWarningAreas => '警報區域';

  @override
  String meshtasticExcludeMqttHidden(int count) {
    return '已隱藏 $count 個';
  }

  @override
  String get notifyOptLocalIntensity1 => '所在地震度1以上';

  @override
  String get mapTimelinePast => '歷史';

  @override
  String get restroomTypeFemale => '女廁所';

  @override
  String get reportListToday => '今天';

  @override
  String get meshtasticTapNode => '點選節點查看詳細資訊';

  @override
  String get commonLoading => '載入中…';

  @override
  String get typhoonIntensityModerate => '中度颱風';

  @override
  String get mapLayerSatelliteAsh => 'ひまわり 火山灰';

  @override
  String get rainInterval3h => '3 時';

  @override
  String get mapLayerCategorySatellite => '衛星';

  @override
  String get meshtasticChannelReady => 'DPIP 頻道已就緒';

  @override
  String get mapLayerSatelliteNightmicrophysics => 'ひまわり 夜間微物理';

  @override
  String get typhoonIntensityTd => '熱帶性低氣壓';

  @override
  String get reportFilterDate => '日期';

  @override
  String get sponsorRestoreUnavailable => '無法連線至商店，請稍後再試';

  @override
  String homeForecastPop(String pop) {
    return '$pop%';
  }

  @override
  String get regionEmpty => '尚未新增常用地區';

  @override
  String get onboardingPermBatteryDesc => '允許 DPIP 在背景持續運作,避免警報延遲或漏收。';

  @override
  String get mapNavDisaster => '防災';

  @override
  String get radarScanRangeSubtitle => '標示四座雷達實際觀測到的範圍。';

  @override
  String get aedHoursSunday => '週日開放時間';

  @override
  String get reportDetailOriginTime => '發震時間';

  @override
  String get trendNoData => '沒有趨勢資料';

  @override
  String get onboardingPermLocation => '定位';

  @override
  String get moreDiscord => 'Discord 社群';

  @override
  String get mapNavPressure => '氣壓';

  @override
  String get mapLayerSatelliteB13 => 'ひまわり 紅外線(B13)';

  @override
  String typhoonTdNo(String no) {
    return 'TD $no';
  }

  @override
  String get changelogEmpty => '目前沒有更新日誌';

  @override
  String get reportFilterDateStartNote => '開始日：當日 00:00（台北時間）';

  @override
  String get eewTitle => '地震速報';

  @override
  String get mapLayerWindForecastEcmwf => 'ECMWF';

  @override
  String regionSelectCount(int count, int max) {
    return '已選 $count/$max';
  }

  @override
  String get mapLayerSatelliteBtdSo2 => 'ひまわり 二氧化硫/雲相';

  @override
  String get meshtasticStateError => '錯誤';

  @override
  String get weatherModeOvercast => '陰天';

  @override
  String get reportDetailDepth => '震源深度';

  @override
  String get typhoonOverlayWarningTooltip => '標示警報區域縣市';

  @override
  String get reportFilterDatePick => '選擇日期';

  @override
  String get onboardingSkipStay => '返回授權';

  @override
  String get commonFetchFailed => '無法獲取資料,請稍後重試';

  @override
  String get shelterOutdoorLabel => '室外收容';

  @override
  String get meshtasticStateConnected => '已連線';

  @override
  String get mapNavRadar => '雷達';

  @override
  String get mapLayerSatelliteCloudClear => '晴空';

  @override
  String eewSummary(String magnitude, String depth) {
    return '規模 $magnitude・深度 $depth 公里';
  }

  @override
  String get locationBannerPermission => '尚未授權定位,無法針對你的所在地推送警報。';

  @override
  String get typhoonOverlayWeatherNoneTooltip => '不疊雷達或紅外線';

  @override
  String get radarCountyOutlineHint => '畫在回波之上';

  @override
  String get windForecastCountyOutlineHint => '繪製於風場之上';

  @override
  String get homeRainTrendTitle => '近 1 小時降水趨勢';

  @override
  String get moonPhaseFirstQuarter => '上弦月';

  @override
  String get mapLayerCategoryTyphoon => '颱風';

  @override
  String get meshtasticUtilization => '空中工時（24 小時）';

  @override
  String get restroomTypeMixed => '混合廁所';

  @override
  String get restroomGradeGood => '優等級';

  @override
  String get notifyTsunami => '海嘯資訊';

  @override
  String get navData => '資料';

  @override
  String get mapLayerSatelliteBtdWvirw => 'ひまわり 過衝雲頂';

  @override
  String get meshtasticReadingAge => '數值時間';

  @override
  String get mapAppCallFailed => '此裝置無法撥打電話';

  @override
  String get reportFilterAny => '不限';

  @override
  String get weatherRankingMergeTo => '合併至';

  @override
  String get notifyIntensity => '震度速報';

  @override
  String get rainIntervalMenu => '累積時段';

  @override
  String get reportDetailLocalFelt => '小區域有感地震';

  @override
  String get meshtasticDevice => '裝置';

  @override
  String get onboardingGrant => '授權';

  @override
  String get weatherModeRain => '雨天';

  @override
  String get shelterVulnerableOkLabel => '適合避難弱者安置';

  @override
  String get stationSheetEmpty => '點選任一測站查看觀測值';

  @override
  String get typhoonLegendProbability => '侵襲機率';

  @override
  String get reportFilterMagnitude => '規模';

  @override
  String get skyTimeMorning => '上午';

  @override
  String get experimentalFeatures => '實驗性功能';

  @override
  String get onboardingTermsBody =>
      '使用 DPIP 前,請詳閱以下注意事項:\n\n• 任何資訊應以中央氣象署發布之內容為準。\n\n• 根據網絡狀態、伺服器狀態、應用程式狀態、上游資料來源狀態等,有收不到資訊的可能性,我們會盡力避免此類情況,但不保證一定不會發生。\n\n• 強烈搖晃有機會比通知早抵達用戶所在地。\n\n• 地震速報為快速計算之結果,可能存在較大誤差,應理解並謹慎使用。\n\n• 任何不被官方所認可的行為均有可能承擔法律風險,請務必遵守相關規範。\n\n此外,為提供本地化警報,本服務會在前景及背景收集並上傳您的概略位置與裝置推送識別碼,僅用於決定應向您推送之警報。\n\n點按下方「同意並繼續」即表示您已閱讀、理解並同意上述事項。';

  @override
  String get reportFilterTitle => '篩選';

  @override
  String get onboardingPermCritical => '重大通知';

  @override
  String trendCumulativeTotal(String total) {
    return '累計 $total mm';
  }

  @override
  String get languageName => '繁體中文(香港)';

  @override
  String get reportListEmptyFiltered => '沒有符合條件的地震報告';

  @override
  String get meshtasticExcludeMqtt => '隱藏 MQTT 節點';

  @override
  String get mapNavTyphoon => '颱風';

  @override
  String get weatherModeSand => '沙塵';

  @override
  String get notifyReport => '地震報告';

  @override
  String get mapAppCoordinatesCopied => '已複製座標';

  @override
  String get skyTimeNight => '夜晚';

  @override
  String get sponsorRecommended => '推薦';

  @override
  String get mapLayerSatelliteB15 => 'ひまわり 長波紅外線(B15)';

  @override
  String get weatherRankingWind => '風速';

  @override
  String get feedStale => '資料可能已過期';

  @override
  String homeForecastWind(String direction, String level) {
    return '$direction · $level 級';
  }

  @override
  String get navHome => '主頁';

  @override
  String get meshtasticRegionLabel => '地區';

  @override
  String get mapLayerSatelliteCloudtop => 'ひまわり 雲頂溫度';

  @override
  String get moonTimelineCaption => '月相';

  @override
  String get openSourceLicenses => '引用套件';

  @override
  String get weatherRankingLowest => '最低';

  @override
  String get reportFilterSortDepth => '深度';

  @override
  String mapTimelineDataTime(String time) {
    return '資料時間 $time';
  }

  @override
  String get radarScanRange => '顯示掃描範圍';

  @override
  String get meshtasticHopLimit => '跳數上限';

  @override
  String get weatherRankingExtremeHigh => '今日最高';

  @override
  String get sponsorPrivacy => '私隱權政策';

  @override
  String get reportDetailLocalIntensity => '所在地的震度';

  @override
  String get mapLayerSatelliteNaturalcolor => 'ひまわり 自然色';

  @override
  String get meshtasticAirtime => '發射佔空比';

  @override
  String shelterCapacityValue(int n) {
    return '$n 人';
  }

  @override
  String lightningLegendCc(int minutes) {
    return '雲間 · $minutes 分內';
  }

  @override
  String get meshtasticSendHint => '要廣播的訊息';

  @override
  String monitorDelay(String value) {
    return '延遲 $value s';
  }

  @override
  String get dpmNo => '否';

  @override
  String get mapLayerSatelliteB08 => 'ひまわり 上層水氣(B08)';

  @override
  String get meshtasticReconnecting => '重新連線中…';

  @override
  String get radarTownOutlineSubtitle => '讓鄉鎮界線在雷達回波下仍然清楚。';

  @override
  String get typhoonOverlayWeatherSatelliteTooltip => '紅外線（對齊颱風報文時間）';

  @override
  String get radarScanRangeHint => '框外空白代表未觀測';

  @override
  String typhoonPickerTd(String no) {
    return '熱帶性低氣壓 TD $no';
  }

  @override
  String get mapLayerSatelliteWatervapor => 'ひまわり 水氣';

  @override
  String get regionAddButton => '新增地區';

  @override
  String get regionSearchHint => '搜尋縣市';

  @override
  String get regionSearchEmpty => '搵唔到符合嘅縣市';

  @override
  String get regionSearchTownHint => '搜尋鄉鎮';

  @override
  String get regionSearchTownEmpty => '搵唔到符合嘅鄉鎮';

  @override
  String get displaySettings => '顯示設定';

  @override
  String get restroomGradePoor => '不合格';

  @override
  String get restroomCategoryTourist => '觀光地區及風景區';

  @override
  String get locationBannerServiceOff => '定位服務已關閉,無法針對你的所在地推送警報。';

  @override
  String get mapLayerStyleTooltip => '顯示樣式';

  @override
  String lightningLegendCg(int minutes) {
    return '對地 · $minutes 分內';
  }

  @override
  String get skyTimeAuto => '自動';

  @override
  String get appLogs => 'App 日誌';

  @override
  String get serverStatusLocal => '本機狀態';

  @override
  String get serverStatusLocalBody =>
      '伺服器指標來自控制台。下方是本機對多活端點（LB / Core 各區）的實際連線判斷：APP 只被動記錄本機實際播送的流量，若該端點從未被本機觸發，就會顯示未探測。';

  @override
  String get serverStatusAllUp => '所有服務正常';

  @override
  String get serverStatusDegraded => '服務效能下降';

  @override
  String get serverStatusDown => '服務異常';

  @override
  String get serverStatusErrorRate => '5xx 錯誤率';

  @override
  String get serverStatusLatency => '平均延遲';

  @override
  String get serverStatusUpdated => '更新於';

  @override
  String get serverStatusWeb => '伺服器狀態';

  @override
  String get serverStatusWebUrl => 'status.exptech.dev';

  @override
  String get serverStatusExpTech => 'ExpTech 狀態';

  @override
  String get serverStatusCloudflare => 'Cloudflare 狀態';

  @override
  String get serverStatusCloudflareAllOperational => '所有區域正常';

  @override
  String get serverStatusCloudflareOutage => 'Cloudflare 部分區域異常';

  @override
  String get serverStatusCloudflareNone => '目前沒有可顯示的區域。';

  @override
  String get serverStatusCloudflareOperational => '正常';

  @override
  String get serverStatusCloudflareDegraded => '效能下降';

  @override
  String get serverStatusCloudflarePartial => '部分中斷';

  @override
  String get serverStatusCloudflareMajor => '大規模中斷';

  @override
  String get serverStatusCloudflareUnknown => '未知';

  @override
  String get endpointTierLbApi => 'LB API';

  @override
  String get endpointTierLbStatic => 'LB Static';

  @override
  String get endpointTierCoreApi => 'Core API';

  @override
  String get endpointTierCoreStatic => 'Core Static';

  @override
  String get endpointTierCoreExclusiveApi => 'Core 專屬 API（雷達 / 氣象 / 風場）';

  @override
  String get endpointTierCoreStaticExclusive => 'Core 專屬靜態資源';

  @override
  String get endpointTierLegacyApi => '舊版 API（api-1）';

  @override
  String get endpointHealthOk => '本機連線正常';

  @override
  String get endpointHealthDegraded => '有端點連線不穩';

  @override
  String get endpointHealthDown => '本機連線異常';

  @override
  String get endpointHealthUnknown => '尚無觀測資料';

  @override
  String get endpointStateOk => '正常';

  @override
  String get endpointStateDegraded => '不穩';

  @override
  String get endpointStateDown => '異常';

  @override
  String get endpointStateUnknown => '未知';

  @override
  String get endpointServiceEew => '地震速報';

  @override
  String get endpointServiceRts => '強震即時警報';

  @override
  String get endpointServiceRadar => '雷達';

  @override
  String get endpointServiceSatellite => '衛星';

  @override
  String get endpointServiceQpesums => '定量降水';

  @override
  String get endpointServiceWind => '風場';

  @override
  String get endpointServiceDpm => '災害點位';

  @override
  String get endpointServiceWeather => '天氣';

  @override
  String get endpointServiceRain => '降雨';

  @override
  String get endpointServiceLightning => '閃電';

  @override
  String get endpointServiceTyphoon => '颱風';

  @override
  String get endpointServiceReport => '地震報告';

  @override
  String get endpointServiceTremStation => '震度站';

  @override
  String get endpointServiceEvent => '事件';

  @override
  String get endpointServiceLocation => '定位';

  @override
  String get endpointServiceNotify => '通知';

  @override
  String get endpointServiceOther => '其他';

  @override
  String get feedConnecting => '連接中…';

  @override
  String get notifyBannerDisabled => '通知已關閉,將收不到災害警報。';

  @override
  String get weatherHumidity => '濕度';

  @override
  String typhoonValueMs(String n) {
    return '每秒 $n 公尺';
  }

  @override
  String homeForecastHumidity(String value) {
    return '濕度 $value%';
  }

  @override
  String get meshtasticBusyBody =>
      '請先在另一個 Meshtastic App 中斷線。兩個 App 同時連同一台裝置會互相搶走訊息，導致部分訊息遺失。';

  @override
  String get meshtasticChannelNoSlot => '沒有可用的頻道空位 — 請先在裝置上空出一個';

  @override
  String get restroomCategoryTransport => '交通';

  @override
  String get meshtasticBattery => '電量';

  @override
  String get meshtasticDistance => '距離';

  @override
  String get meshtasticSnrTrend => '訊號趨勢 (SNR)';

  @override
  String get meshtasticBatteryTrend => '電量趨勢';

  @override
  String get typhoonOverlayMenuTooltip => '颱風圖層選項';

  @override
  String get mapLayerSatelliteBtdOzone => 'ひまわり 對流層頂';

  @override
  String meshtasticRegionMismatch(String region) {
    return '裝置地區為 $region — DPIP 需要 TW';
  }

  @override
  String get notifySectionEarthquake => '地震';

  @override
  String get mapLayerDisasterMap => '防災地圖';

  @override
  String get weatherModeFog => '大霧';

  @override
  String typhoonPickerNamed(String no, String name) {
    return '$name TY $no';
  }

  @override
  String get mapLayerStyleGrayTooltip => '氣象廳灰階慣例：溫度越低越白';

  @override
  String get moreAnnouncements => '公告';

  @override
  String get moreTagline => '防災資訊整合平台';

  @override
  String get moreVersionStable => '正式版';

  @override
  String get moreVersionNotes => '本次更新';

  @override
  String get moreVersionNotesHighlightsSubtitle => '這個版本做了哪些改變';

  @override
  String releaseHighlightsTitle(Object train) {
    return '$train 重點整理';
  }

  @override
  String get releaseHighlightsTabNormal => '做了哪些改變';

  @override
  String get releaseHighlightsTabAdvanced => '深入技術';

  @override
  String get releaseHighlightsEmpty => '目前沒有內容。';

  @override
  String get releaseHighlightsSeeNotes => '查看完整更新日誌';

  @override
  String get moreVersionNotesEmpty => '找不到目前版本的更新日誌';

  @override
  String get reportNotFound => '搵唔到呢份地震報告';

  @override
  String get moreVersionSnapshot => '測試版';

  @override
  String get mapLayerSatelliteTransparentNoData => '無資料(陸地) = 透明';

  @override
  String get restroomCategoryGovernment => '民眾洽公場所';

  @override
  String get typhoonLegendCurrent => '目前中心';

  @override
  String get aedAddress => '地址';

  @override
  String get mapLayerAed => 'AED';

  @override
  String get changelogTypePrerelease => '測試版';

  @override
  String get reportFilterIntensityInfoModernBody =>
      '震度為 0–4、5弱、5強、6弱、6強、7。篩選滑桿依新制；列表中較早的地震會以舊制標示顯示。';

  @override
  String get typhoonOverlayWeatherNone => '無';

  @override
  String get mapLayerStyleGray => '灰階（JMA）';

  @override
  String get weatherModeAuto => '自動';

  @override
  String get typhoonLabelProbCircle => '70%機率圓';

  @override
  String get notifyOptAll => '接收全部';

  @override
  String get displayTheme => '主題';

  @override
  String get mapLayerSatelliteB07 => 'ひまわり 短波紅外(B07)';

  @override
  String get typhoonLabelDirection => '過去移動方向';

  @override
  String get regionManageTitle => '常用地區';

  @override
  String get regionSaveNote =>
      '通知是以 GPS 所在地位置發送的，設定常用地區不會改變或影響通知發送，常用地區只是用於首頁快速查看不同區域狀態，所以務必授予 GPS 定位權限，否則通知無法運作';

  @override
  String get typhoonLegendCone => '預測圓錐';

  @override
  String get moreCwaEew => '中央氣象署強震即時警報';

  @override
  String get onboardingPermsTitle => '權限授權';

  @override
  String get mapLayerStyleJma => '雲頂強調（JMA）';

  @override
  String get rainInterval10m => '10 分';

  @override
  String get meshtasticConnectAnyway => '仍要連線';

  @override
  String reportListDayCount(int count) {
    return '$count';
  }

  @override
  String get mapLayerSatelliteB06 => 'ひまわり 近紅外(B06)';

  @override
  String get mapLayerSatelliteTransparentReflectance => '低反射率/夜間 = 透明,顯示底圖';

  @override
  String chartHourLabel(int hour) {
    return '$hour時';
  }

  @override
  String get mapLayerShelter => '避難收容場所';

  @override
  String get typhoonOverlayProbabilityTooltip => '顯示侵襲機率（會隱藏預測圓錐）';

  @override
  String get mapLayerSatelliteNdwi => 'ひまわり 水體指數';

  @override
  String get disasterMapOverlayShelterTooltip => '顯示避難收容場所';

  @override
  String get mapNavHumidity => '濕度';

  @override
  String get reportDetailSortByIntensity => '依震度排序';

  @override
  String get homeRainTrendNoData => '無資料';

  @override
  String get mapLayerCategoryRadar => '雷達';

  @override
  String get meshtasticShortName => '簡稱';

  @override
  String get mapLayerSatelliteAirmass => 'ひまわり 氣團';

  @override
  String get dataSectionWeather => '氣象';

  @override
  String get aedHoursWeekday => '平日開放時間';

  @override
  String get homeActiveEventsTitle => '生效中事件';

  @override
  String get faq => '常見問題';

  @override
  String eewSerial(int serial) {
    return '第 $serial 報';
  }

  @override
  String get reportFilterSort => '排序方式';

  @override
  String get meshtasticRegionConfirm =>
      '要將這台裝置切換為 TW 地區嗎？裝置會重新啟動並短暫斷線，上面的其他頻道也會一起改變。';

  @override
  String get dataEarthquakeSubtitle => '地震報告';

  @override
  String get typhoonNoActive => '目前無颱風';

  @override
  String get mapLayerSatelliteB11 => 'ひまわり 二氧化硫/雲相(B11)';

  @override
  String get navEvents => '事件';

  @override
  String get onboardingTermsTitle => '服務條款';

  @override
  String get mapOsmOverlay => '詳細地圖';

  @override
  String get mapOsmOverlayHint => '顯示更完整的道路、建物與地名';

  @override
  String get mapOsmDetails => '詳細設定';

  @override
  String get moreDataSources => '資料來源';

  @override
  String get dataSourceTremNet => '探索智慧科技有限公司 — TREM-Net';

  @override
  String get dataSourceCwa => '交通部中央氣象署 (CWA)';

  @override
  String get dataSourceJma => '気象庁 (JMA)';

  @override
  String get dataSourceNcdr => '國家災害防救科技中心 (NCDR)';

  @override
  String get dataSourceEcmwf =>
      'European Centre for Medium-Range Weather Forecasts (ECMWF)';

  @override
  String get dataSourceNoaaGfs =>
      'National Oceanic and Atmospheric Administration / National Centers for Environmental Prediction — Global Forecast System (NOAA/NCEP GFS)';

  @override
  String get dataSourceGovernmentOpenData => '政府資料開放平臺';

  @override
  String get dataSourceOpenStreetMap => '© OpenStreetMap contributors';

  @override
  String get dataSourceNasaMoon =>
      'National Aeronautics and Space Administration / Goddard Space Flight Center Scientific Visualization Studio — CGI Moon Kit (NASA/GSFC SVS)';

  @override
  String mapOsmDetailsHint(int enabled, int total) {
    return '已啟用 $enabled / 共 $total 個圖層';
  }

  @override
  String get mapOsmSurface => '地表';

  @override
  String get mapOsmParks => '公園';

  @override
  String get mapOsmLandUse => '土地利用';

  @override
  String get mapOsmAirportAreas => '機場區域';

  @override
  String get mapOsmWater => '水域';

  @override
  String get mapOsmRivers => '河川';

  @override
  String get mapOsmBoundaries => '邊界';

  @override
  String get mapOsmBuildings => '建物';

  @override
  String get mapOsmRoads => '道路';

  @override
  String get mapOsmRoadNames => '道路名稱';

  @override
  String get mapOsmWaterNames => '水域名稱';

  @override
  String get mapOsmPeaks => '山峰';

  @override
  String get mapOsmAirportNames => '機場名稱';

  @override
  String get mapOsmPlaceNames => '地名';

  @override
  String get mapOsmPoi => '地標';

  @override
  String get mapOsmHouseNumbers => '門牌號碼';

  @override
  String get mapOsmRestoreAll => '全部恢復';

  @override
  String get mapOsmSectionNatural => '地表與自然';

  @override
  String get mapOsmSectionRoadsAndBuildings => '道路與建物';

  @override
  String get mapOsmSectionLabelsAndPlaces => '地名與標示';

  @override
  String get mapTownLabels => '鄉鎮名稱';

  @override
  String get notifySetFailed => '設定失敗,請稍後再試。';

  @override
  String get meshtasticDisconnect => '斷線';

  @override
  String get meshtasticUndecoded => '無法解密';

  @override
  String get notifyAnnouncement => '公告';

  @override
  String get onboardingIntroTitle => '歡迎使用 DPIP';

  @override
  String get regionCurrentUnavailable => '無法取得所在地位置資訊';

  @override
  String get languageSystem => '系統預設';

  @override
  String get skyTimeSunset => '日落';

  @override
  String get mapLayerSatelliteDust => 'ひまわり 沙塵';

  @override
  String get mapAppAppleMaps => 'Apple Maps';

  @override
  String get regionEdit => '修改';

  @override
  String get weatherDynamicState => '天氣動態狀態';

  @override
  String get moonNow => '現在';

  @override
  String get moonSectionAppearance => '外觀';

  @override
  String get moonSectionRiseSet => '月出月落';

  @override
  String get moonSectionUpcoming => '接下來';

  @override
  String get moonSectionCalendar => '月曆';

  @override
  String get moonDistance => '距離';

  @override
  String get moonKilometres => '公里';

  @override
  String get moonApparentSize => '視直徑';

  @override
  String get moonRise => '月出';

  @override
  String get moonSet => '月落';

  @override
  String get moonNextNewMoon => '下次新月';

  @override
  String get moonAlwaysUp => '整日在地平線上';

  @override
  String get moonNoEvent => '當日無';

  @override
  String get sunTitle => '太陽';

  @override
  String get sunSectionDaylight => '日照';

  @override
  String get sunSectionTwilight => '曙暮光';

  @override
  String get sunSectionLight => '光線';

  @override
  String get sunSectionSundial => '日晷';

  @override
  String get sunSectionTerms => '節氣';

  @override
  String get sunRise => '日出';

  @override
  String get sunSet => '日沒';

  @override
  String get sunNoon => '正午';

  @override
  String get sunDayLength => '白晝長度';

  @override
  String get sunTwilightCivil => '民用';

  @override
  String get sunTwilightNautical => '航海';

  @override
  String get sunTwilightAstronomical => '天文';

  @override
  String get sunGoldenHourMorning => '晨間黃金時刻';

  @override
  String get sunGoldenHourEvening => '昏間黃金時刻';

  @override
  String get sunBlueHour => '藍調時刻';

  @override
  String get sunEquationOfTime => '均時差';

  @override
  String get sunMinutes => '分';

  @override
  String get solarTermNext => '下一個節氣';

  @override
  String get planetsTitle => '行星';

  @override
  String get planetsSectionTonight => '此刻';

  @override
  String get planetUp => '地平線上';

  @override
  String get planetDown => '地平線下';

  @override
  String get planetInGlare => '太近太陽';

  @override
  String get planetMagnitude => '亮度';

  @override
  String get planetElongation => '距日距角';

  @override
  String get planetSky => '時段';

  @override
  String get planetEvening => '昏星';

  @override
  String get planetMorning => '晨星';

  @override
  String get planetDistance => '距離';

  @override
  String get planetAu => '天文單位';

  @override
  String get planetAltitude => '仰角';

  @override
  String get planetMercury => '水星';

  @override
  String get planetVenus => '金星';

  @override
  String get planetMars => '火星';

  @override
  String get planetJupiter => '木星';

  @override
  String get planetSaturn => '土星';

  @override
  String get planetUranus => '天王星';

  @override
  String get planetNeptune => '海王星';

  @override
  String get solarTermVernalEquinox => '春分';

  @override
  String get solarTermPureBrightness => '清明';

  @override
  String get solarTermGrainRain => '穀雨';

  @override
  String get solarTermStartOfSummer => '立夏';

  @override
  String get solarTermGrainFull => '小滿';

  @override
  String get solarTermGrainInEar => '芒種';

  @override
  String get solarTermSummerSolstice => '夏至';

  @override
  String get solarTermMinorHeat => '小暑';

  @override
  String get solarTermMajorHeat => '大暑';

  @override
  String get solarTermStartOfAutumn => '立秋';

  @override
  String get solarTermEndOfHeat => '處暑';

  @override
  String get solarTermWhiteDew => '白露';

  @override
  String get solarTermAutumnalEquinox => '秋分';

  @override
  String get solarTermColdDew => '寒露';

  @override
  String get solarTermFrostDescent => '霜降';

  @override
  String get solarTermStartOfWinter => '立冬';

  @override
  String get solarTermMinorSnow => '小雪';

  @override
  String get solarTermMajorSnow => '大雪';

  @override
  String get solarTermWinterSolstice => '冬至';

  @override
  String get solarTermMinorCold => '小寒';

  @override
  String get solarTermMajorCold => '大寒';

  @override
  String get solarTermStartOfSpring => '立春';

  @override
  String get solarTermRainWater => '雨水';

  @override
  String get solarTermAwakeningOfInsects => '驚蟄';

  @override
  String get tonightTitle => '今夜';

  @override
  String get tonightSectionDark => '觀測窗口';

  @override
  String get tonightAstronomicalNight => '天文夜';

  @override
  String get tonightNeverDark => '整夜不全暗';

  @override
  String get tonightDarkWindow => '暗窗';

  @override
  String get tonightMoonAllNight => '月亮整夜在天上';

  @override
  String get tonightDarkTotal => '總暗時';

  @override
  String get tonightMoonlight => '月光';

  @override
  String get tonightSectionShowers => '流星雨';

  @override
  String get tonightRadiantDown => '輻射點不升起';

  @override
  String get tonightPerHour => '顆/時';

  @override
  String get tonightSectionSatellites => '衛星過境';

  @override
  String get tonightSectionTargets => '此刻可觀測目標';

  @override
  String get showerQuadrantids => '象限儀座';

  @override
  String get showerLyrids => '天琴座';

  @override
  String get showerEtaAquariids => '寶瓶座η';

  @override
  String get showerDeltaAquariids => '寶瓶座δ';

  @override
  String get showerPerseids => '英仙座';

  @override
  String get showerOrionids => '獵戶座';

  @override
  String get showerSouthernTaurids => '金牛座南';

  @override
  String get showerLeonids => '獅子座';

  @override
  String get showerGeminids => '雙子座';

  @override
  String get showerUrsids => '小熊座';

  @override
  String get deepSkyOpenCluster => '疏散星團';

  @override
  String get deepSkyGlobularCluster => '球狀星團';

  @override
  String get deepSkySpiralGalaxy => '螺旋星系';

  @override
  String get deepSkyEllipticalGalaxy => '橢圓星系';

  @override
  String get deepSkyIrregularGalaxy => '不規則星系';

  @override
  String get deepSkyPlanetaryNebula => '行星狀星雲';

  @override
  String get deepSkySupernovaRemnant => '超新星遺跡';

  @override
  String get deepSkyEmissionNebula => '發射星雲';

  @override
  String get deepSkyReflectionNebula => '反射星雲';

  @override
  String get deepSkyAsterism => '星群';

  @override
  String get almanacTitle => '曆法';

  @override
  String get almanacSectionToday => '今日';

  @override
  String get almanacGregorian => '西曆';

  @override
  String get almanacLunar => '農曆';

  @override
  String get almanacYear => '歲次';

  @override
  String get almanacMonthLength => '月大小';

  @override
  String get almanacLongMonth => '三十日';

  @override
  String get almanacShortMonth => '二十九日';

  @override
  String get almanacLeapPrefix => '閏';

  @override
  String get almanacSectionLunarEclipses => '月食';

  @override
  String get almanacSectionSolarEclipses => '日食';

  @override
  String get almanacNoSolarEclipse => '範圍內無';

  @override
  String get eclipseTotal => '全食';

  @override
  String get eclipsePartial => '偏食';

  @override
  String get eclipseAnnular => '環食';

  @override
  String get eclipsePenumbral => '半影食';

  @override
  String get zodiacRat => '鼠';

  @override
  String get zodiacOx => '牛';

  @override
  String get zodiacTiger => '虎';

  @override
  String get zodiacRabbit => '兔';

  @override
  String get zodiacDragon => '龍';

  @override
  String get zodiacSnake => '蛇';

  @override
  String get zodiacHorse => '馬';

  @override
  String get zodiacGoat => '羊';

  @override
  String get zodiacMonkey => '猴';

  @override
  String get zodiacRooster => '雞';

  @override
  String get zodiacDog => '狗';

  @override
  String get zodiacPig => '豬';

  @override
  String get tideTitle => '潮汐';

  @override
  String get tideDisclaimer => '僅為天文引潮力，非港口潮汐表。水位請參考氣象署公布之潮汐預報。';

  @override
  String get tideSectionNow => '此刻';

  @override
  String get tidePhase => '週期';

  @override
  String get tideSpring => '大潮';

  @override
  String get tideNeap => '小潮';

  @override
  String get tideMiddling => '中潮';

  @override
  String get tideLunarDistanceFactor => '月球引力';

  @override
  String get tideEquilibrium => '平衡潮高';

  @override
  String get tideMetres => '公尺';

  @override
  String get tidePerigeanSpring => '下次近地點大潮';

  @override
  String get tideSectionTurningPoints => '轉折點';

  @override
  String get tideHigh => '高';

  @override
  String get tideLow => '低';

  @override
  String get skyChartTitle => '星圖';

  @override
  String get skyChartNorth => '北';

  @override
  String get skyChartEast => '東';

  @override
  String get skyChartSouth => '南';

  @override
  String get skyChartWest => '西';

  @override
  String tonightElementAge(int days) {
    return '軌道資料 $days 天前';
  }

  @override
  String almanacLunarDate(String leap, int month, int day) {
    return '$leap$month 月 $day 日';
  }

  @override
  String get tonightNoShowers => '目前無流星雨';

  @override
  String get tonightNoPasses => '48 小時內無可見過境';

  @override
  String get tonightSatellitesUnavailable => '無法讀取軌道資料';

  @override
  String get tonightNoTargets => '無足夠高度的目標';

  @override
  String get skyChartUnavailable => '無法讀取星表';

  @override
  String get permissionSettingsTitle => '請到系統設定開啟';

  @override
  String get permissionSettingsHint => '返回 App 後會自動重新檢查。';

  @override
  String get permissionOpenSettings => '前往設定';

  @override
  String permissionSettingsMessage(String what) {
    return '「$what」已被拒絕，系統不會再詢問。請到設定中開啟。';
  }

  @override
  String get permissionGuideNotification => '請到系統設定中開啟通知權限。';

  @override
  String get permissionGuideForegroundLocation => '請到系統設定中開啟精確位置權限。';

  @override
  String permissionGuideBackgroundLocation(Object option) {
    return '請在「$option」中改為「允許所有時間」。';
  }

  @override
  String get permissionGuideBackgroundExecution =>
      '請到系統設定中允許背景執行,避免收到通知時被系統暫停。';

  @override
  String get permissionGuideUnusedPause => '若應用程式被標記為「未使用」,請在系統設定中改為「允許」。';

  @override
  String get permissionGuideUnusedFreeSpace => '若應用程式因暫存空間不足被暫停,請清除暫存後重新開啟。';

  @override
  String get permissionGuideUnusedRevoke => '若應用程式權限被撤銷,請在系統設定中重新授予。';

  @override
  String get permissionGuideUnusedPlayProtect =>
      '若被 Play 保護機制暫停,請到 Google Play 中檢查應用程式狀態。';

  @override
  String permissionGuideVendorPower(Object vendor) {
    return '請到「$vendor」的省電設定中,將本應用程式設為「不限制」。';
  }

  @override
  String get permissionStillRequired => '仍然需要此權限,請到設定中開啟。';

  @override
  String get permissionVerifyManually => '請手動確認此權限已在系統設定中開啟。';

  @override
  String get permissionBackgroundLocationOption => '「允許所有時間」';

  @override
  String get displayTextSize => '文字大小';

  @override
  String get displayTextSizeDesc => '只調整 App 介面的文字，地圖上的文字維持原本大小。';

  @override
  String get displayTextWeight => '文字粗細';

  @override
  String get displayTextWeightDesc => '文字較粗時可能更容易閱讀。';

  @override
  String get displayContrast => '對比度';

  @override
  String get displayContrastDesc => '對比越高，文字與背景越分明。';

  @override
  String get displayColorVision => '色覺調整';

  @override
  String get displayColorVisionDesc => '整個 App 的顏色都會一併調整，包括地圖。';

  @override
  String get displayColorVisionNone => '標準';

  @override
  String get displayColorVisionProtan => '紅色弱';

  @override
  String get displayColorVisionDeutan => '綠色弱';

  @override
  String get displayColorVisionTritan => '藍黃色弱';

  @override
  String get displayPreviewSample => '地震報告範例';

  @override
  String get displayScaleSmall => '小';

  @override
  String get displayScaleDefault => '預設';

  @override
  String get displayScaleLarge => '大';

  @override
  String get displayScaleHuge => '特大';

  @override
  String get displayWeightNormal => '一般';

  @override
  String get displayWeightMedium => '中等';

  @override
  String get displayWeightBold => '粗體';

  @override
  String get displayContrastStandard => '標準';

  @override
  String get displayContrastMedium => '中等';

  @override
  String get displayContrastHigh => '高';

  @override
  String get meshtasticDirect => '直連';

  @override
  String meshtasticHopsAway(int n) {
    return '$n 跳';
  }

  @override
  String get meshtasticStatRelayShare => '為他人轉發';

  @override
  String get meshtasticStatRelayShareHint => '佔本機發送量的比例';

  @override
  String get meshtasticStatRelayValue => '轉發成功率';

  @override
  String get meshtasticStatRelaySolePath => '經常是唯一路徑 — 網絡依賴此節點';

  @override
  String get meshtasticStatRelayRedundant => '其他節點也覆蓋同樣路徑';

  @override
  String get meshtasticStatRedundancy => '重複接收';

  @override
  String get meshtasticStatThinEdge => '備援路徑少 — 一個中繼失效就可能斷線';

  @override
  String get meshtasticStatWellCovered => '有多條路徑可達';

  @override
  String get meshtasticStatErrorRate => '接收錯誤率';

  @override
  String get meshtasticStatErrorRateHint => '空中時間不變卻升高 = 干擾';

  @override
  String get meshtasticTraceRoute => '追蹤路由';

  @override
  String get meshtasticTracing => '追蹤中…';

  @override
  String get meshtasticTraceUnreadable => '無法解讀的回覆';

  @override
  String get meshtasticTraceOffline => '未連線至電台';

  @override
  String get meshtasticTraceCooldown => '電台限制每 30 秒一次';

  @override
  String get meshtasticTraceNoReply => '沒有回應 — 超出範圍或金鑰不同';

  @override
  String get meshtasticTraceDirect => '直達 — 中間無中繼';

  @override
  String meshtasticTraceHops(int n) {
    return '$n 跳';
  }

  @override
  String get moreDumpDiagnostics => '傾印除錯資訊及日誌';

  @override
  String get moreDumpDiagnosticsHint => '上載後複製連結';

  @override
  String get dumpIncludeSensitive => '包含精確位置';

  @override
  String get dumpIncludeSensitiveHint => '包含日誌及背景定位中的座標；未勾選時會以 null 取代';

  @override
  String get dumpUpload => '上載';

  @override
  String get dumpUploaded => '已上載';

  @override
  String get dumpLinkCopied => '連結已複製到剪貼簿';

  @override
  String get dumpCopyAgain => '再複製一次';

  @override
  String get dumpUploadFailed => '上載失敗，請稍後再試';

  @override
  String get statusLegendUnprobed => '未探測';

  @override
  String get statusLegendUnsupported => '不支援';

  @override
  String get rainScaleSection => '色階間距';

  @override
  String get rainScaleFine => '小間距';

  @override
  String get rainScaleCoarse => '大間距';

  @override
  String get notifyTestTitle => '測試通知';

  @override
  String get notifyTestIntro => '點一下就會實際發送該則警報。重大警報會以最大音量播放，並穿透靜音與勿擾模式。';

  @override
  String get notifyTestCriticalDenied => '這台裝置未允許「重要警告」，重大警報在靜音時同樣不會發出聲音。';

  @override
  String get notifyTestPermissionOff => '通知已關閉，測試不會有任何反應。';

  @override
  String get notifyTestBehaviourOverrides => '會穿透靜音與勿擾模式';

  @override
  String get notifyTestBehaviourAlerts => '有聲音並跳出橫幅，但手機靜音時不會響';

  @override
  String get notifyTestBehaviourSounds => '有聲音、不跳出橫幅，手機靜音時不會響';

  @override
  String get notifyTestBehaviourSilent => '無聲，只出現在通知中心';

  @override
  String get notifyTestFailed => '無法發送測試通知。';

  @override
  String get moreBugReports => '已回報的錯誤';

  @override
  String get bugTrackerEmpty => '還沒有已回報的錯誤';

  @override
  String get bugTrackerReplies => '回覆';

  @override
  String get bugTrackerGoToDiscord => '找不到你的問題？快前往 Discord 回報！';

  @override
  String get bugTrackerNoMatch => '沒有符合所選標籤的錯誤回報';

  @override
  String get bugTrackerDeveloper => '開發人員';

  @override
  String get bugTrackerCannotDisplay => '無法顯示此內容，請在 Discord 上查看';

  @override
  String get bugTrackerJoinDiscussion => '至 Discord 參與討論';

  @override
  String get bugTrackerSortLast => '最後討論';

  @override
  String get bugTrackerSortMostDiscussed => '最多討論';

  @override
  String get bugTrackerStaff => '工作人員';

  @override
  String eewSpokenLocalIntensity(String intensity) {
    return '所在地預估震度，$intensity。';
  }

  @override
  String eewSpokenMaxIntensity(String intensity) {
    return '預估最大震度，$intensity。';
  }
}

/// The translations for Chinese, as used in Taiwan (`zh_TW`).
class AppLocalizationsZhTw extends AppLocalizationsZh {
  AppLocalizationsZhTw() : super('zh_TW');

  @override
  String typhoonValueLat(String lat) {
    return '北緯 $lat 度';
  }

  @override
  String get onboardingSkipBody =>
      '未授權定位與通知,DPIP 將無法即時通知你所在地的地震與災害。你仍可稍後在設定中開啟。';

  @override
  String get rainInterval24h => '24 時';

  @override
  String homeRainTrendHeavyStopping(int minutes) {
    return '預計 $minutes 分鐘後停止下大雨';
  }

  @override
  String get mapTimelineObserved => '觀測';

  @override
  String get mapTimelineScrubPaused => '拖動過快，影格更新已暫停；放慢速度即可恢復。';

  @override
  String get regionSelectTitle => '選擇地區';

  @override
  String get skyTimeNoon => '正午';

  @override
  String get radarCountyOutlineSubtitle => '讓縣市界線在雷達回波下仍然清楚。';

  @override
  String get mapLayerSatelliteB03 => 'ひまわり 可見光-紅(B03)';

  @override
  String get reportFilterIntensity => '震度';

  @override
  String get mapLayerLightning => '閃電';

  @override
  String get restroomTypeMale => '男廁所';

  @override
  String get meshtasticLastReceived => '最近接收';

  @override
  String get reportDetailSortByCounty => '依縣市排序';

  @override
  String get onboardingPermUnusedApp => '保持 App 啟用';

  @override
  String get onboardingPermUnusedAppDesc =>
      'Android 會暫停你長期未開啟的 App 並撤銷其權限，這會讓災害警報無法送達你所在地。';

  @override
  String get onboardingPermBackgroundExec => '背景執行';

  @override
  String get onboardingPermBackgroundExecDesc => '關閉時，App 不會被喚醒回報你的位置。';

  @override
  String get onboardingPermVendorPower => '手機廠商省電設定';

  @override
  String onboardingPermVendorPowerDesc(String brand) {
    return '$brand 會停止你最近沒開過的 App 的背景作業。App 無法偵測或變更，請手動允許。';
  }

  @override
  String get homeRainTrendScattered => '可能會有零星降雨';

  @override
  String get meshtasticUptime => '運行時間';

  @override
  String get weatherRankingTempExtremes => '溫度極值';

  @override
  String get themeLight => '淺色';

  @override
  String get mapTerrainReliefHint => '在底圖上顯示立體地形陰影';

  @override
  String get meshtasticEmptyMessage => '（空白訊息）';

  @override
  String get moreSectionRegion => '地區';

  @override
  String get mapLayerSatellite => 'ひまわり 紅外線(B13)';

  @override
  String get aedHoursSaturday => '週六開放時間';

  @override
  String get moonPhaseNew => '新月';

  @override
  String get notifySectionEew => '地震速報';

  @override
  String get mapResetNorth => '回到北方';

  @override
  String get rainInterval2d => '2 日';

  @override
  String get mapTownLabelsHint => '放大時顯示鄉鎮名稱';

  @override
  String get commonCancel => '取消';

  @override
  String get notifyOptTsunamiWarning => '只接收海嘯警報';

  @override
  String get mapLayerSatelliteBtdFog => 'ひまわり 夜間霧';

  @override
  String get moreSectionAdvanced => '進階';

  @override
  String get moreSectionMesh => 'Mesh 網路';

  @override
  String get weatherRankingExtremeRange => '日溫差';

  @override
  String get permissionsTitle => '權限檢查';

  @override
  String get permissionsAttention => '權限需要處理';

  @override
  String get permissionsBody => 'DPIP 需要這些權限才能即時通知你。收不到警報時，通常就是其中一項尚未開啟。';

  @override
  String get notifySettingsMenu => '通知設定';

  @override
  String mapAppDefault(String app) {
    return '$app（預設）';
  }

  @override
  String get trendRange24h => '24 小時';

  @override
  String get mapLayerStyleJmaTooltip => '灰階為底，−40 °C 以下上色，凸顯雲頂高度';

  @override
  String get mapLayerRain => '雨量';

  @override
  String get mapLayerQpesums => '未來 1 小時降水預報';

  @override
  String get mapOverlaySectionMap => '地圖';

  @override
  String get mapTerrainRelief => '地形立體感';

  @override
  String get mapLegendCollapse => '收合圖例';

  @override
  String get updateAvailableTitle => '有新版本';

  @override
  String updateAvailableBody(String version) {
    return '新版本 $version 已發布。';
  }

  @override
  String get updateSkip => '略過此次';

  @override
  String get updateViewChangelog => '前往查看';

  @override
  String get updateOpenAppStore => 'App Store';

  @override
  String get updateOpenTestFlight => 'TestFlight';

  @override
  String get updateOpenPlayStore => 'Play 商店';

  @override
  String get updateDownload => '下載更新';

  @override
  String get changelogShowSnapshots => '顯示測試版';

  @override
  String get changelogTitle => '更新日誌';

  @override
  String get reportFilterOrderDesc => '降序';

  @override
  String get meshtasticExcludeMqttSubtitle => '經網際網路橋接、並非無線電聽到的節點';

  @override
  String get reportFilterIntensityInfoTitle => '震度新制與舊制';

  @override
  String get mapLayerTyphoon => '颱風';

  @override
  String get radarOverlayMenuTooltip => '雷達圖層選項';

  @override
  String get meshtasticNodes => '節點';

  @override
  String get meshtasticSend => '傳送';

  @override
  String get typhoonOverlayStormL7Tooltip => '七級暴風圈＋平均圓（紫色）';

  @override
  String get aedType => '場所類型';

  @override
  String get termsOfService => '服務條款';

  @override
  String get typhoonLegendCircle25 => '十級風暴風圈';

  @override
  String get sponsorTitle => '支援 DPIP';

  @override
  String get mapNavSatellite => '衛星';

  @override
  String homeRainTrendUpdated(String time) {
    return '更新 $time';
  }

  @override
  String get onboardingNext => '下一步';

  @override
  String get weatherRankingMergeTown => '鄉鎮';

  @override
  String get mapLayerMonitor => '強震監視器';

  @override
  String get moreYoutube => 'YouTube';

  @override
  String get sponsorSubscriptions => '訂閱制';

  @override
  String typhoonValueLon(String lon) {
    return '東經 $lon 度';
  }

  @override
  String get skyTime => '天空時間';

  @override
  String get weatherModeCloudy => '多雲';

  @override
  String get skyTimeDusk => '暮色';

  @override
  String get meshtasticFirmware => '韌體';

  @override
  String get reportFilterDateEndNote => '結束日：當日 24:00（臺北時間）';

  @override
  String get reportFilterSortMagnitude => '規模';

  @override
  String get meshtasticSilent => '已靜默';

  @override
  String get mapLayerCategoryEarthquake => '地震';

  @override
  String get mapLayerSatelliteB12 => 'ひまわり 臭氧(B12)';

  @override
  String get restroomCategoryOther => '其他';

  @override
  String homeForecastHighLow(String high, String low) {
    return '高 $high° · 低 $low°';
  }

  @override
  String get locationBannerFix => '開啟設定';

  @override
  String get mapLegendExpand => '圖例';

  @override
  String get eewNone => '目前沒有地震速報';

  @override
  String typhoonTyNo(String no) {
    return 'TY $no';
  }

  @override
  String get notifyOptTsunamiAll => '海嘯消息、海嘯警報';

  @override
  String get meshtasticLayerOptions => '節點選項';

  @override
  String get onboardingAgreeContinue => '同意並繼續';

  @override
  String get commonRetry => '重試';

  @override
  String get meshtasticNodeId => '節點 ID';

  @override
  String reportDetailNumbered(String number) {
    return '編號 $number 顯著有感地震';
  }

  @override
  String get typhoonOverlayStormBandSubtitle => '含平均圓';

  @override
  String get disasterMapOverlayRestroomTooltip => '顯示公廁';

  @override
  String get weatherRankingTitle => '觀測排行';

  @override
  String get homeRainTrendHeavySustained => '未來 1 小時會有持續大雨';

  @override
  String get notifySectionTsunami => '海嘯';

  @override
  String get restroomCategoryPark => '公園';

  @override
  String get moreLinkOpenFailed => '無法開啟連結';

  @override
  String get themeDark => '深色';

  @override
  String get sponsorRestore => '恢復購買';

  @override
  String get meshtasticChannelWorking => '正在設定 DPIP 頻道…';

  @override
  String get meshtasticRegionSwitch => '切換為 TW';

  @override
  String get meshtasticTraffic => '流量';

  @override
  String get mapLayerStyleBdTooltip => 'Dvorak BD 曲線——熱帶氣旋強度分析的階梯灰階';

  @override
  String get disasterMapOverlayAedTooltip => '顯示 AED 位置';

  @override
  String get mapLayerHumidity => '濕度';

  @override
  String get mapLayerSatelliteTransparentNight => '夜間 = 透明,顯示底圖';

  @override
  String get meshtasticScanning => '掃描中…';

  @override
  String regionSelectFull(int max) {
    return '最多只能選擇 $max 個地區';
  }

  @override
  String get meshtasticNewMessages => '新訊息';

  @override
  String get meshtasticBatteryHistory => '電量歷史';

  @override
  String get meshtasticStatAvg => '平均';

  @override
  String get meshtasticStatPeak => '峰值';

  @override
  String get meshtasticStatDrain => '掉電';

  @override
  String get meshtasticStatEta => '預估可用';

  @override
  String get meshtasticStatFull => '充滿';

  @override
  String get meshtasticStatTrend => '趨勢';

  @override
  String get meshtasticStatCharging => '充電中';

  @override
  String get meshtasticStatStable => '穩定';

  @override
  String get meshtasticNodesTotal => '已知';

  @override
  String get meshtasticNodesOnline => '在線';

  @override
  String get meshtasticRx => '接收';

  @override
  String get meshtasticTx => '發送';

  @override
  String get meshtasticNodesHistory => '節點數歷史';

  @override
  String get meshtasticTrafficHistory => '流量歷史';

  @override
  String meshtasticEtaHours(int n) {
    return '約 $n 小時';
  }

  @override
  String meshtasticEtaDays(int n) {
    return '約 $n 天';
  }

  @override
  String get meshtasticTitle => 'Meshtastic';

  @override
  String get navMore => '更多';

  @override
  String get meshtasticDpipChannel => 'DPIP 頻道';

  @override
  String get disasterMapOverlaySectionLayers => '圖層';

  @override
  String get mapLayerSatelliteB05 => 'ひまわり 近紅外(B05)';

  @override
  String get typhoonLabelNe => '東北側';

  @override
  String get meshtasticCopied => '已複製訊息';

  @override
  String get reportListEmpty => '目前沒有地震報告';

  @override
  String get reportListEnd => '已到最後一頁';

  @override
  String get mapLayerSatelliteTruecolor => 'ひまわり 真彩色';

  @override
  String get typhoonOverlaySectionExtra => '覆蓋層';

  @override
  String get eewSWave => '震波';

  @override
  String get meshtasticBusyTitle => '另一個 App 正在使用這台裝置';

  @override
  String get restroomCategoryCultural => '文化育樂活動場所';

  @override
  String get typhoonLabelWind => '近中心最大風速';

  @override
  String get radarGlobalOutlineHint => '各國國界外框';

  @override
  String get notifyEvacuation => '防災資訊';

  @override
  String get typhoonLegendCircle15 => '七級風暴風圈';

  @override
  String get dataSectionAstronomy => '天文';

  @override
  String get homeRainTrendLightSustained => '未來 1 小時會有持續小雨';

  @override
  String get commonError => '發生錯誤';

  @override
  String get moonPhaseWaningCrescent => '殘月';

  @override
  String get meshtasticPower => '電力';

  @override
  String get mapTimelineNow => '現在';

  @override
  String reportFilterRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String get reportDetailOpenReport => '報告頁面';

  @override
  String get trendRange7d => '7 天';

  @override
  String typhoonWarningAreas(String areas) {
    return '警戒區域：$areas';
  }

  @override
  String get rainIntervalSection => '統計時間';

  @override
  String get notifyTitle => '通知';

  @override
  String get meshtasticTxPower => '發射功率';

  @override
  String get restroomCategoryLabel => '類別';

  @override
  String get sponsorRestoring => '正在恢復購買…';

  @override
  String get sponsorIntro =>
      'DPIP 致力於提供即時防災資訊，沒有廣告或其他營利模式。您的支援能幫助我們維持伺服器運作並持續開發。';

  @override
  String get typhoonLabelStormAvg => '十級風平均暴風半徑';

  @override
  String get restroomCategoryCommercial => '商業營業場所';

  @override
  String get aedRegion => '縣市區域';

  @override
  String homeRainTrendLightStopping(int minutes) {
    return '預計 $minutes 分鐘後停止下小雨';
  }

  @override
  String get reportDetailInfo => '詳細資訊';

  @override
  String get mapNavWind => '風向';

  @override
  String get windForecastOverlayMenuTooltip => '風場預報圖層選項';

  @override
  String homeRainTrendMinute(int minute) {
    return '$minute分';
  }

  @override
  String get rainInterval6h => '6 時';

  @override
  String get restroomTypeUnspecified => '未設定';

  @override
  String get typhoonOverlayProbabilityHint => '會隱藏預測圓錐';

  @override
  String get mapLayerSatelliteGlobalOutline => '國界';

  @override
  String get mapNavTemperature => '溫度';

  @override
  String get typhoonLegendForecastPoint => '預測點';

  @override
  String get reportListYesterday => '昨天';

  @override
  String get moreSectionLinks => '相關連結';

  @override
  String get feedOffline => '連線中斷';

  @override
  String get mapLayerStyleBd => 'Dvorak BD';

  @override
  String get moreSectionDisplay => '顯示';

  @override
  String get rainInterval3d => '3 日';

  @override
  String get defaultMapLayerSubtitle => '開啟地圖分頁時顯示此圖層，底部導覽列圖示與文字會一併更新。';

  @override
  String get aedDescription => '備註';

  @override
  String get typhoonOverlayWeatherRadarTooltip => '雷達回波（對齊颱風報文時間）';

  @override
  String get onboardingPermLocationDesc => '依你所在位置推送在地警報。';

  @override
  String get mapLayerSatelliteB16 => 'ひまわり 二氧化碳(B16)';

  @override
  String get homeActiveEventsEmpty => '目前沒有生效中的事件';

  @override
  String get typhoonLabelPosition => '中心位置';

  @override
  String get weatherRankingBy => '依';

  @override
  String get typhoonIntensityMild => '輕度颱風';

  @override
  String get windForecastGlobalOutlineHint => '各國國界外框';

  @override
  String get rainInterval1h => '1 時';

  @override
  String get eewLocalIntensity => '所在地預估';

  @override
  String get mapLayerRadar => '雷達合成回波圖';

  @override
  String get restroomCategoryReligious => '宗教禮儀場所';

  @override
  String get meshtasticRole => '角色';

  @override
  String get mapLayerSatelliteCloudCloudy => '有雲';

  @override
  String get skyTimeSunrise => '日出';

  @override
  String get meshtasticJumpToLatest => '跳到最新';

  @override
  String get meshtasticNoMessages => '尚無訊息';

  @override
  String get onboardingPermNotifyDesc => '在地震、天氣與災害發生時,即時傳遞警報通知。';

  @override
  String get radarTownOutline => '鄉鎮界線';

  @override
  String get mapLayerStyleSection => '顯示樣式';

  @override
  String get disasterMapOverlayMenuTooltip => '防災地圖圖層';

  @override
  String get moreGooglePlay => 'Google Play';

  @override
  String get meshtasticOnline => '近期聽到';

  @override
  String get typhoonLabelSw => '西南側';

  @override
  String typhoonForecastLead(String hours) {
    return '預測 +$hours 小時';
  }

  @override
  String get changelogTypeStable => '正式版';

  @override
  String get mapLayerSatelliteTransparentClear => '晴空 = 透明,顯示底圖';

  @override
  String get mapOverlaySectionReference => '參考圖層';

  @override
  String get mapLayerSatelliteB02 => 'ひまわり 可見光-綠(B02)';

  @override
  String get weatherRankingEmpty => '目前沒有可排序的觀測';

  @override
  String get notifySectionOther => '其他';

  @override
  String weatherRankingMeta(String time, int count) {
    return '資料時間：$time\n共 $count 觀測點';
  }

  @override
  String get onboardingTermsAgree => '我已閱讀並同意服務條款';

  @override
  String get mapLayerSatelliteTransparentNoVegetation => '< 0.1 = 透明(無植被)';

  @override
  String get notifyOptLocalIntensity4 => '所在地震度4以上';

  @override
  String get eewArrived => '已抵達';

  @override
  String get meshtasticNoDevices => '找不到 Meshtastic 裝置';

  @override
  String get mapLayerCategoryLife => '生活';

  @override
  String get reportFilterSortIntensity => '震度';

  @override
  String get meshtasticStateDisconnected => '未連線';

  @override
  String get typhoonIntensityIntense => '強烈颱風';

  @override
  String get mapLayerOrderTitle => '調整圖層順序';

  @override
  String get mapLayerShow => '顯示圖層';

  @override
  String get mapLayerHide => '隱藏圖層';

  @override
  String get mapLayerShowAll => '全部顯示';

  @override
  String get mapLayerHideAll => '全部隱藏';

  @override
  String get dpmYes => '是';

  @override
  String get meshtasticNoHistory => '歷史紀錄還不夠';

  @override
  String get reportDetailLocalIntensityUnavailable => '沒有震度訊息';

  @override
  String get mapLayerWindForecastGfs => 'GFS';

  @override
  String get reportFilterDepth => '深度';

  @override
  String get onboardingScrollHint => '往下捲動以繼續';

  @override
  String get mapNavQpesums => '預報';

  @override
  String get notifyAdvisory => '天氣警特報';

  @override
  String get reportFilterReset => '重設';

  @override
  String get mapLayerSatelliteMndwi => 'ひまわり 改良水體指數';

  @override
  String get typhoonOverlaySectionStorm => '暴風圈';

  @override
  String get moonPhaseFull => '滿月';

  @override
  String meshtasticBinaryPayload(String size) {
    return '二進位內容 · $size';
  }

  @override
  String get moonPhaseWaningGibbous => '虧凸月';

  @override
  String get reportFilterIntensityInfoModernTitle => '新制（2020 起）';

  @override
  String typhoonDataTime(String time) {
    return '資料時間\n$time';
  }

  @override
  String get restroomTypeAccessible => '無障礙廁所';

  @override
  String get moreSectionAbout => '關於';

  @override
  String get meshtasticSelectDevice => '選擇裝置';

  @override
  String get onboardingIntroBody =>
      'DPIP 是與你並肩的防災夥伴,整合強震即時警報、地震報告、天氣與各類災害資訊,在關鍵時刻即時通知你。\n\n• 地震:強震即時警報、震度速報與地震報告\n• 天氣:雷雨即時訊息、天氣警特報\n• 海嘯與防災資訊\n\n接下來,我們會請你閱讀服務條款,並授權幾項讓 DPIP 能即時守護你的權限。';

  @override
  String get shelterCapacityLabel => '收容人數';

  @override
  String get reportDetailImage => '地震報告圖';

  @override
  String get meshtasticStateConfiguring => '設定中…';

  @override
  String get typhoonLabelGaleAvg => '七級風平均暴風半徑';

  @override
  String get onboardingPermNotify => '通知';

  @override
  String get meshtasticClearMessages => '清除訊息';

  @override
  String get meshtasticNotifyMessages => '新訊息通知';

  @override
  String get defaultMapLayerSettings => '地圖預設圖層';

  @override
  String get eewSourceSettings => '地震速報來源';

  @override
  String get eewSourceSubtitle => '選擇要顯示哪些單位發布的地震速報。';

  @override
  String get eewSourceAll => '所有來源';

  @override
  String get eewSourceAllDescription => '顯示所有機構發布的地震速報。';

  @override
  String get eewSourceCwaOnly => '僅中央氣象署';

  @override
  String get eewSourceCwaOnlyDescription => '只顯示中央氣象署發布的地震速報。';

  @override
  String get moreSectionNotify => '通知';

  @override
  String get notifyUnavailable => '推播尚未就緒，請稍後再試。';

  @override
  String get mapLayerOrderReset => '回復預設順序';

  @override
  String get weatherRankingMergeCounty => '縣市';

  @override
  String get moreSectionApp => '取得 App';

  @override
  String get moreSectionBeta => '測試版';

  @override
  String get moreAndroidBeta => 'Android 測試版';

  @override
  String get moreTestFlight => 'iOS 測試版（TestFlight）';

  @override
  String get moreSectionPartners => '合作夥伴';

  @override
  String get morePartnersNote => '依合作時間先後排列。感謝這些個人與公司對防災的貢獻，他們讓 DPIP 成為可能。';

  @override
  String get morePartnerGeoscience => '巨科資訊有限公司';

  @override
  String get morePartnerTwds => '台灣數位串流有限公司';

  @override
  String get reportFilterIntensityInfoLegacyBody => '震度僅 0–7，沒有 5弱／5強／6弱／6強。';

  @override
  String get mapLayerSatelliteSst => 'ひまわり 海表溫度';

  @override
  String get qpesumsOverlayMenuTooltip => '定量降水預報圖層選項';

  @override
  String get mapTimelineFuture => '未來';

  @override
  String get typhoonLegendCircleAvg => '平均圓';

  @override
  String reportFilterDepthKm(String depth) {
    return '$depth 公里';
  }

  @override
  String get typhoonLabelSe => '東南側';

  @override
  String get radarTownOutlineHint => '較細的分區';

  @override
  String eewCountdown(int seconds) {
    return '$seconds 秒';
  }

  @override
  String get typhoonLabelGust => '瞬間最大陣風';

  @override
  String get mapAppGoogleMaps => 'Google Maps';

  @override
  String get sponsorTerms => '使用條款';

  @override
  String get restroomTypeGenderNeutral => '性別友善廁所';

  @override
  String get notifyThunderstorm => '雷雨即時訊息';

  @override
  String get skyTimeGolden => '黃金時刻';

  @override
  String get moonAge => '月齡';

  @override
  String get meshtasticRadioSettings => 'LoRa';

  @override
  String get moreGithub => 'ExpTech GitHub';

  @override
  String get homeForecastUnavailable => '選擇鄉鎮後可查看預報';

  @override
  String get mapLayers => '圖層';

  @override
  String get meshtasticHardware => '硬體';

  @override
  String get languageSettings => '語言設定';

  @override
  String get language => '語言';

  @override
  String homeForecastFeelsLike(String temp) {
    return '體感 $temp°';
  }

  @override
  String get typhoonOverlayWeatherHint => '對齊報文時間';

  @override
  String get skyTimeDawn => '黎明';

  @override
  String get skyTimeAfternoon => '下午';

  @override
  String get meshtasticLastHeard => '最後聽到';

  @override
  String get typhoonWarningTitle => '颱風警報';

  @override
  String get moreSourceCode => '原始碼';

  @override
  String get mapLayerCategoryWeather => '氣象觀測';

  @override
  String get mapLayerSatelliteB09 => 'ひまわり 中層水氣(B09)';

  @override
  String get windForecastTownOutlineHint => '更細的網格';

  @override
  String get mapLayerSatelliteCloudmask => 'ひまわり 雲遮罩';

  @override
  String get mapAppCopyCoordinates => '複製座標';

  @override
  String get reportFilterIntensityInfoIntro =>
      '中央氣象署自 2020 年 1 月 1 日（臺北時間）起改用新制震度。';

  @override
  String get mapNavEarthquake => '地震';

  @override
  String get restroomGradeAverage => '普通級';

  @override
  String get mapLayerSatelliteBtdCo2 => 'ひまわり 卷雲/雲高';

  @override
  String get onboardingPermBackgroundDesc => '選擇「一律允許」,關閉 App 也能推送在地警報。';

  @override
  String get mapTimelineForecast => '預報';

  @override
  String get restroomTypeLabel => '廁所類型';

  @override
  String get navEarthquake => '地震';

  @override
  String get typhoonOverlayStormL10Tooltip => '十級暴風圈＋平均圓（黃色）';

  @override
  String get moonPhaseWaxingGibbous => '盈凸月';

  @override
  String get reportDetailTitle => '地震報告';

  @override
  String get moreTremReport => 'TREM 檢知報告';

  @override
  String weatherDataTime(String station, String time) {
    return '$station ∙ 資料時間 $time';
  }

  @override
  String get meshtasticNoNodes => '尚未聽到任何節點';

  @override
  String get meshtasticViaMqtt => '經 MQTT（網際網路）';

  @override
  String get radarCountyOutline => '縣市界線';

  @override
  String get commonClose => '關閉';

  @override
  String get restroomGradeLabel => '等級';

  @override
  String get rainIntervalNow => '今日';

  @override
  String get changelogCurrentVersion => '目前版本';

  @override
  String get typhoonLabelPressure => '中心氣壓';

  @override
  String get typhoonOverlayForecastCalloutsTooltip => '放大時顯示預測點詳細卡片';

  @override
  String get aedOpenRemark => '開放時間備註';

  @override
  String get onboardingPermsBody => '為了在災害發生的第一時間通知你,請授權以下權限。你隨時可以在系統設定中變更。';

  @override
  String get typhoonOverlaySectionWeather => '天氣底圖';

  @override
  String get notifyOptWeatherLocal => '接收所在地';

  @override
  String get mapNavRain => '雨量';

  @override
  String get moonDays => '天';

  @override
  String mapLegendUnit(String unit) {
    return '單位：$unit';
  }

  @override
  String get weatherModeClear => '晴天';

  @override
  String get meshtasticRadio => '電台';

  @override
  String get commonEmpty => '沒有資料';

  @override
  String get mapLayerSatelliteB01 => 'ひまわり 可見光-藍(B01)';

  @override
  String get meshtasticExternalPower => '外部供電';

  @override
  String get moonPhaseLastQuarter => '下弦月';

  @override
  String get reportFilterOrderAsc => '升序';

  @override
  String get reportFilterApply => '套用';

  @override
  String get reportDetailImageUnavailable => '報告圖尚未提供';

  @override
  String get weatherRankingHighest => '最高';

  @override
  String get reportDetailReplay => '重播';

  @override
  String get mapLayerRestroom => '公廁';

  @override
  String get restroomCategoryWelfare => '社福機構、集會場所';

  @override
  String get restroomGradeExcellent => '特優級';

  @override
  String get meshtasticLastSent => '最近送出';

  @override
  String get meshtasticName => '名稱';

  @override
  String get meshtasticScan => '掃描';

  @override
  String get mapLayerCategoryForecast => '數值預報';

  @override
  String get meshtasticChannelFailed => '無法設定 DPIP 頻道';

  @override
  String get themeSystem => '跟隨系統';

  @override
  String get mapLayerSatelliteNdvi => 'ひまわり 植生指數';

  @override
  String get typhoonLegendForecast => '預測路徑';

  @override
  String typhoonValueHpa(String n) {
    return '$n 百帕';
  }

  @override
  String get weatherPrecipitation => '降水量';

  @override
  String get moonNextFullMoon => '下次滿月';

  @override
  String get dpmSheetEmpty => '點選地圖上的標記查看詳情';

  @override
  String get onboardingSkipLeave => '仍要略過';

  @override
  String get aedPlaceDesc => '放置位置說明';

  @override
  String get onboardingSkipTitle => '尚未完成授權';

  @override
  String get restroomTypeFamily => '親子廁所';

  @override
  String typhoonValueKm(String n) {
    return '$n 公里';
  }

  @override
  String get onboardingPermBattery => '省電白名單';

  @override
  String get typhoonLabelNw => '西北側';

  @override
  String get moonPhaseWaxingCrescent => '眉月';

  @override
  String get restroomCategoryLeisure => '休閒娛樂場所';

  @override
  String get mapLayerTemperature => '溫度';

  @override
  String get aedCategory => '場所分類';

  @override
  String get meshtasticChannels => '頻道';

  @override
  String get monitorWaiting => '等待資料…';

  @override
  String get typhoonOverlayForecastCallouts => '預測點資訊';

  @override
  String get reportDetailEpicenter => '震央座標';

  @override
  String get meshtasticVoltage => '電壓';

  @override
  String get mapLayerMeshtasticSubtitle => '電台聽到過的 LoRa 網狀網路節點';

  @override
  String get mapLayerWind => '風向';

  @override
  String get reportDetailMagnitude => '地震規模';

  @override
  String get reportDetailAreaIntensity => '各地震度';

  @override
  String get rainInterval12h => '12 時';

  @override
  String reportListMagnitude(String magnitude) {
    return 'M$magnitude';
  }

  @override
  String get notifyMonitor => '強震監視器';

  @override
  String get onboardingStart => '開始使用';

  @override
  String sponsorPerMonth(String price) {
    return '$price / 月';
  }

  @override
  String get mapLayerPressure => '氣壓';

  @override
  String get mapLayerSatelliteB04 => 'ひまわり 近紅外(B04)';

  @override
  String get mapLayerSatelliteTransparentZero => '零差值 = 透明(無訊號)';

  @override
  String get shelterIndoorLabel => '室內收容';

  @override
  String get notifyOptOff => '關閉';

  @override
  String get reportFilterSortTime => '時間';

  @override
  String get mapLayerSatelliteCloudProbablyClear => '可能晴空';

  @override
  String get weatherModeThunderstorm => '雷雨';

  @override
  String get homeViewOnMap => '前往地圖察看';

  @override
  String get reportFilterIntensityInfoLegacyTitle => '舊制（2020 以前）';

  @override
  String get typhoonLabelSpeed => '過去移動時速';

  @override
  String mapAppOpenFailed(String app) {
    return '無法開啟 $app';
  }

  @override
  String get mapLayerSatelliteRgbComposite => 'RGB 合成(JMA 配方)';

  @override
  String get meshtasticReceived => '已接收';

  @override
  String get weatherRankingExtremeLow => '今日最低';

  @override
  String get mapLayerSatelliteB10 => 'ひまわり 低層水氣(B10)';

  @override
  String get mapLayerSatelliteCloudProbablyCloudy => '可能有雲';

  @override
  String get mapLayerSatelliteTransparentNoWater => '≤ 0 = 透明(無水體)';

  @override
  String get shelterCategoryLabel => '適用災害';

  @override
  String get meshtasticStateConnecting => '連線中…';

  @override
  String get moonTitle => '月亮';

  @override
  String get weatherRankingGust => '陣風';

  @override
  String get moreAppStore => 'App Store';

  @override
  String get moreServerStatus => '伺服器狀態';

  @override
  String get notifySectionWeather => '天氣';

  @override
  String get meshtasticPreset => '調變預設';

  @override
  String get dataSectionSeismic => '地震';

  @override
  String get changelogBodyEmpty => '此版本沒有說明。';

  @override
  String get changelogOpenOnGitHub => '在 GitHub 查看';

  @override
  String get radarGlobalOutline => '國界';

  @override
  String get notifyEew => '緊急地震速報';

  @override
  String get regionNationwide => '全國';

  @override
  String get moreNotifyLog => 'DPIP 通知發送記錄';

  @override
  String get regionCurrent => '所在地';

  @override
  String get meshtasticNotConnected => '尚未連線至裝置';

  @override
  String get weatherModeSnow => '下雪';

  @override
  String get mapLayerMeshtastic => 'Meshtastic 節點';

  @override
  String get moreDeveloper => '除錯資訊';

  @override
  String get mapLayerSatelliteB14 => 'ひまわり 長波紅外線(B14)';

  @override
  String get meshtasticChannelUse => '頻道使用率';

  @override
  String get mapNavLightning => '閃電';

  @override
  String get homeForecastEmpty => '目前沒有預報資料';

  @override
  String get sponsorOneTime => '單次支援';

  @override
  String get mapLayerSatelliteBtdSplit => 'ひまわり 分割視窗';

  @override
  String get onboardingPermBackground => '背景定位';

  @override
  String get aedEmergencyPhone => '緊急聯絡電話';

  @override
  String get dpmOpenInMaps => '開啟地圖';

  @override
  String get meshtasticNotifyNodes => '新節點通知';

  @override
  String get onboardingPermCriticalDesc => '讓危及生命的強震即時警報,即使在靜音或勿擾模式下也能發出聲響。';

  @override
  String get mapLayerSatelliteTransparentWarm => '晴空(暖端) = 透明,顯示底圖';

  @override
  String get meshtasticSent => '已送出';

  @override
  String get homeForecastTitle => '24小時預報';

  @override
  String get typhoonLegendWarningAreas => '警報區域';

  @override
  String meshtasticExcludeMqttHidden(int count) {
    return '已隱藏 $count 個';
  }

  @override
  String get notifyOptLocalIntensity1 => '所在地震度1以上';

  @override
  String get mapTimelinePast => '歷史';

  @override
  String get restroomTypeFemale => '女廁所';

  @override
  String get reportListToday => '今天';

  @override
  String get meshtasticTapNode => '點選節點查看詳細資訊';

  @override
  String get commonLoading => '載入中…';

  @override
  String get typhoonIntensityModerate => '中度颱風';

  @override
  String get mapLayerSatelliteAsh => 'ひまわり 火山灰';

  @override
  String get rainInterval3h => '3 時';

  @override
  String get mapLayerCategorySatellite => '衛星';

  @override
  String get meshtasticChannelReady => 'DPIP 頻道已就緒';

  @override
  String get mapLayerSatelliteNightmicrophysics => 'ひまわり 夜間微物理';

  @override
  String get typhoonIntensityTd => '熱帶性低氣壓';

  @override
  String get reportFilterDate => '日期';

  @override
  String get sponsorRestoreUnavailable => '無法連線至商店，請稍後再試';

  @override
  String homeForecastPop(String pop) {
    return '$pop%';
  }

  @override
  String get regionEmpty => '尚未新增常用地區';

  @override
  String get onboardingPermBatteryDesc => '允許 DPIP 在背景持續運作,避免警報延遲或漏收。';

  @override
  String get mapNavDisaster => '防災';

  @override
  String get radarScanRangeSubtitle => '標示四座雷達實際觀測到的範圍。';

  @override
  String get aedHoursSunday => '週日開放時間';

  @override
  String get reportDetailOriginTime => '發震時間';

  @override
  String get trendNoData => '沒有趨勢資料';

  @override
  String get onboardingPermLocation => '定位';

  @override
  String get moreDiscord => 'Discord 社群';

  @override
  String get mapNavPressure => '氣壓';

  @override
  String get mapLayerSatelliteB13 => 'ひまわり 紅外線(B13)';

  @override
  String typhoonTdNo(String no) {
    return 'TD $no';
  }

  @override
  String get changelogEmpty => '目前沒有更新日誌';

  @override
  String get reportFilterDateStartNote => '開始日：當日 00:00（臺北時間）';

  @override
  String get eewTitle => '地震速報';

  @override
  String get mapLayerWindForecastEcmwf => 'ECMWF';

  @override
  String regionSelectCount(int count, int max) {
    return '已選 $count/$max';
  }

  @override
  String get mapLayerSatelliteBtdSo2 => 'ひまわり 二氧化硫/雲相';

  @override
  String get meshtasticStateError => '錯誤';

  @override
  String get weatherModeOvercast => '陰天';

  @override
  String get reportDetailDepth => '震源深度';

  @override
  String get typhoonOverlayWarningTooltip => '標示警報區域縣市';

  @override
  String get reportFilterDatePick => '選擇日期';

  @override
  String get onboardingSkipStay => '返回授權';

  @override
  String get commonFetchFailed => '無法獲取資料,請稍後重試';

  @override
  String get shelterOutdoorLabel => '室外收容';

  @override
  String get meshtasticStateConnected => '已連線';

  @override
  String get mapNavRadar => '雷達';

  @override
  String get mapLayerSatelliteCloudClear => '晴空';

  @override
  String eewSummary(String magnitude, String depth) {
    return '規模 $magnitude・深度 $depth 公里';
  }

  @override
  String get locationBannerPermission => '尚未授權定位,無法針對你的所在地推送警報。';

  @override
  String get typhoonOverlayWeatherNoneTooltip => '不疊雷達或紅外線';

  @override
  String get radarCountyOutlineHint => '畫在回波之上';

  @override
  String get windForecastCountyOutlineHint => '繪製於風場之上';

  @override
  String get homeRainTrendTitle => '近 1 小時降水趨勢';

  @override
  String get moonPhaseFirstQuarter => '上弦月';

  @override
  String get mapLayerCategoryTyphoon => '颱風';

  @override
  String get meshtasticUtilization => '空中工時（24 小時）';

  @override
  String get restroomTypeMixed => '混合廁所';

  @override
  String get restroomGradeGood => '優等級';

  @override
  String get notifyTsunami => '海嘯資訊';

  @override
  String get navData => '資料';

  @override
  String get mapLayerSatelliteBtdWvirw => 'ひまわり 過衝雲頂';

  @override
  String get meshtasticReadingAge => '數值時間';

  @override
  String get mapAppCallFailed => '此裝置無法撥打電話';

  @override
  String get reportFilterAny => '不限';

  @override
  String get weatherRankingMergeTo => '合併至';

  @override
  String get notifyIntensity => '震度速報';

  @override
  String get rainIntervalMenu => '累積時段';

  @override
  String get reportDetailLocalFelt => '小區域有感地震';

  @override
  String get meshtasticDevice => '裝置';

  @override
  String get onboardingGrant => '授權';

  @override
  String get weatherModeRain => '雨天';

  @override
  String get shelterVulnerableOkLabel => '適合避難弱者安置';

  @override
  String get stationSheetEmpty => '點選任一測站查看觀測值';

  @override
  String get typhoonLegendProbability => '侵襲機率';

  @override
  String get reportFilterMagnitude => '規模';

  @override
  String get skyTimeMorning => '上午';

  @override
  String get experimentalFeatures => '實驗性功能';

  @override
  String get onboardingTermsBody =>
      '使用 DPIP 前,請詳閱以下注意事項:\n\n• 任何資訊應以中央氣象署發布之內容為準。\n\n• 根據網路狀態、伺服器狀態、應用程式狀態、上游資料來源狀態等,有收不到資訊的可能性,我們會盡力避免此類情況,但不保證一定不會發生。\n\n• 強烈搖晃有機率比通知早抵達使用者所在地。\n\n• 地震速報為快速計算之結果,可能存在較大誤差,應理解並謹慎使用。\n\n• 任何不被官方所認可的行為均有可能承擔法律風險,請務必遵守相關規範。\n\n此外,為提供在地化警報,本服務會在前景及背景蒐集並上傳您的概略位置與裝置推播識別碼,僅用於決定應向您推送之警報。\n\n點選下方「同意並繼續」即表示您已閱讀、理解並同意上述事項。';

  @override
  String get reportFilterTitle => '篩選';

  @override
  String get onboardingPermCritical => '重大通知';

  @override
  String trendCumulativeTotal(String total) {
    return '累計 $total mm';
  }

  @override
  String get languageName => '繁體中文(臺灣)';

  @override
  String get reportListEmptyFiltered => '沒有符合條件的地震報告';

  @override
  String get meshtasticExcludeMqtt => '隱藏 MQTT 節點';

  @override
  String get mapNavTyphoon => '颱風';

  @override
  String get weatherModeSand => '沙塵';

  @override
  String get notifyReport => '地震報告';

  @override
  String get mapAppCoordinatesCopied => '已複製座標';

  @override
  String get skyTimeNight => '夜晚';

  @override
  String get sponsorRecommended => '推薦';

  @override
  String get mapLayerSatelliteB15 => 'ひまわり 長波紅外線(B15)';

  @override
  String get weatherRankingWind => '風速';

  @override
  String get feedStale => '資料可能已過期';

  @override
  String homeForecastWind(String direction, String level) {
    return '$direction · $level 級';
  }

  @override
  String get navHome => '首頁';

  @override
  String get meshtasticRegionLabel => '地區';

  @override
  String get mapLayerSatelliteCloudtop => 'ひまわり 雲頂溫度';

  @override
  String get moonTimelineCaption => '月相';

  @override
  String get openSourceLicenses => '引用套件';

  @override
  String get weatherRankingLowest => '最低';

  @override
  String get reportFilterSortDepth => '深度';

  @override
  String mapTimelineDataTime(String time) {
    return '資料時間 $time';
  }

  @override
  String get radarScanRange => '顯示掃描範圍';

  @override
  String get meshtasticHopLimit => '跳數上限';

  @override
  String get weatherRankingExtremeHigh => '今日最高';

  @override
  String get sponsorPrivacy => '隱私權政策';

  @override
  String get reportDetailLocalIntensity => '所在地的震度';

  @override
  String get mapLayerSatelliteNaturalcolor => 'ひまわり 自然色';

  @override
  String get meshtasticAirtime => '發射佔空比';

  @override
  String shelterCapacityValue(int n) {
    return '$n 人';
  }

  @override
  String lightningLegendCc(int minutes) {
    return '雲間 · $minutes 分內';
  }

  @override
  String get meshtasticSendHint => '要廣播的訊息';

  @override
  String monitorDelay(String value) {
    return '延遲 $value s';
  }

  @override
  String get dpmNo => '否';

  @override
  String get mapLayerSatelliteB08 => 'ひまわり 上層水氣(B08)';

  @override
  String get meshtasticReconnecting => '重新連線中…';

  @override
  String get radarTownOutlineSubtitle => '讓鄉鎮界線在雷達回波下仍然清楚。';

  @override
  String get typhoonOverlayWeatherSatelliteTooltip => '紅外線（對齊颱風報文時間）';

  @override
  String get radarScanRangeHint => '框外空白代表未觀測';

  @override
  String typhoonPickerTd(String no) {
    return '熱帶性低氣壓 TD $no';
  }

  @override
  String get mapLayerSatelliteWatervapor => 'ひまわり 水氣';

  @override
  String get regionAddButton => '新增地區';

  @override
  String get regionSearchHint => '搜尋縣市';

  @override
  String get regionSearchEmpty => '找不到符合的縣市';

  @override
  String get regionSearchTownHint => '搜尋鄉鎮市區';

  @override
  String get regionSearchTownEmpty => '找不到符合的鄉鎮市區';

  @override
  String get displaySettings => '顯示設定';

  @override
  String get restroomGradePoor => '不合格';

  @override
  String get restroomCategoryTourist => '觀光地區及風景區';

  @override
  String get locationBannerServiceOff => '定位服務已關閉,無法針對你的所在地推送警報。';

  @override
  String get mapLayerStyleTooltip => '顯示樣式';

  @override
  String lightningLegendCg(int minutes) {
    return '對地 · $minutes 分內';
  }

  @override
  String get skyTimeAuto => '自動';

  @override
  String get appLogs => 'App 日誌';

  @override
  String get serverStatusLocal => '本機狀態';

  @override
  String get serverStatusLocalBody =>
      '伺服器指標來自控制台。下方是本機對多活端點（LB / Core 各區）的實際連線判斷：APP 只被動記錄本機實際播送的流量，若該端點從未被本機觸發，就會顯示未探測。';

  @override
  String get serverStatusAllUp => '所有服務正常';

  @override
  String get serverStatusDegraded => '服務效能下降';

  @override
  String get serverStatusDown => '服務異常';

  @override
  String get serverStatusErrorRate => '5xx 錯誤率';

  @override
  String get serverStatusLatency => '平均延遲';

  @override
  String get serverStatusUpdated => '更新於';

  @override
  String get serverStatusWeb => '伺服器狀態';

  @override
  String get serverStatusWebUrl => 'status.exptech.dev';

  @override
  String get serverStatusExpTech => 'ExpTech 狀態';

  @override
  String get serverStatusCloudflare => 'Cloudflare 狀態';

  @override
  String get serverStatusCloudflareAllOperational => '所有區域正常';

  @override
  String get serverStatusCloudflareOutage => 'Cloudflare 部分區域異常';

  @override
  String get serverStatusCloudflareNone => '目前沒有可顯示的區域。';

  @override
  String get serverStatusCloudflareOperational => '正常';

  @override
  String get serverStatusCloudflareDegraded => '效能下降';

  @override
  String get serverStatusCloudflarePartial => '部分中斷';

  @override
  String get serverStatusCloudflareMajor => '大規模中斷';

  @override
  String get serverStatusCloudflareUnknown => '未知';

  @override
  String get endpointTierLbApi => 'LB API';

  @override
  String get endpointTierLbStatic => 'LB Static';

  @override
  String get endpointTierCoreApi => 'Core API';

  @override
  String get endpointTierCoreStatic => 'Core Static';

  @override
  String get endpointTierCoreExclusiveApi => 'Core 專屬 API（雷達 / 氣象 / 風場）';

  @override
  String get endpointTierCoreStaticExclusive => 'Core 專屬靜態資源';

  @override
  String get endpointTierLegacyApi => '舊版 API（api-1）';

  @override
  String get endpointHealthOk => '本機連線正常';

  @override
  String get endpointHealthDegraded => '有端點連線不穩';

  @override
  String get endpointHealthDown => '本機連線異常';

  @override
  String get endpointHealthUnknown => '尚無觀測資料';

  @override
  String get endpointStateOk => '正常';

  @override
  String get endpointStateDegraded => '不穩';

  @override
  String get endpointStateDown => '異常';

  @override
  String get endpointStateUnknown => '未知';

  @override
  String get endpointServiceEew => '地震速報';

  @override
  String get endpointServiceRts => '強震即時警報';

  @override
  String get endpointServiceRadar => '雷達';

  @override
  String get endpointServiceSatellite => '衛星';

  @override
  String get endpointServiceQpesums => '定量降水';

  @override
  String get endpointServiceWind => '風場';

  @override
  String get endpointServiceDpm => '災害點位';

  @override
  String get endpointServiceWeather => '天氣';

  @override
  String get endpointServiceRain => '降雨';

  @override
  String get endpointServiceLightning => '閃電';

  @override
  String get endpointServiceTyphoon => '颱風';

  @override
  String get endpointServiceReport => '地震報告';

  @override
  String get endpointServiceTremStation => '震度站';

  @override
  String get endpointServiceEvent => '事件';

  @override
  String get endpointServiceLocation => '定位';

  @override
  String get endpointServiceNotify => '通知';

  @override
  String get endpointServiceOther => '其他';

  @override
  String get feedConnecting => '連線中…';

  @override
  String get notifyBannerDisabled => '通知已關閉,將收不到災害警報。';

  @override
  String get weatherHumidity => '濕度';

  @override
  String typhoonValueMs(String n) {
    return '每秒 $n 公尺';
  }

  @override
  String homeForecastHumidity(String value) {
    return '濕度 $value%';
  }

  @override
  String get meshtasticBusyBody =>
      '請先在另一個 Meshtastic App 中斷線。兩個 App 同時連同一台裝置會互相搶走訊息，導致部分訊息遺失。';

  @override
  String get meshtasticChannelNoSlot => '沒有可用的頻道空位 — 請先在裝置上空出一個';

  @override
  String get restroomCategoryTransport => '交通';

  @override
  String get meshtasticBattery => '電量';

  @override
  String get meshtasticDistance => '距離';

  @override
  String get meshtasticSnrTrend => '訊號趨勢 (SNR)';

  @override
  String get meshtasticBatteryTrend => '電量趨勢';

  @override
  String get typhoonOverlayMenuTooltip => '颱風圖層選項';

  @override
  String get mapLayerSatelliteBtdOzone => 'ひまわり 對流層頂';

  @override
  String meshtasticRegionMismatch(String region) {
    return '裝置地區為 $region — DPIP 需要 TW';
  }

  @override
  String get notifySectionEarthquake => '地震';

  @override
  String get mapLayerDisasterMap => '防災地圖';

  @override
  String get weatherModeFog => '大霧';

  @override
  String typhoonPickerNamed(String no, String name) {
    return '$name TY $no';
  }

  @override
  String get mapLayerStyleGrayTooltip => '氣象廳灰階慣例：溫度越低越白';

  @override
  String get moreAnnouncements => '公告';

  @override
  String get moreTagline => '防災資訊整合平台';

  @override
  String get moreVersionStable => '正式版';

  @override
  String get moreVersionNotes => '本次更新';

  @override
  String get moreVersionNotesHighlightsSubtitle => '這個版本做了哪些改變';

  @override
  String releaseHighlightsTitle(Object train) {
    return '$train 重點整理';
  }

  @override
  String get releaseHighlightsTabNormal => '做了哪些改變';

  @override
  String get releaseHighlightsTabAdvanced => '深入技術';

  @override
  String get releaseHighlightsEmpty => '目前沒有內容。';

  @override
  String get releaseHighlightsSeeNotes => '查看完整更新日誌';

  @override
  String get moreVersionNotesEmpty => '找不到目前版本的更新日誌';

  @override
  String get reportNotFound => '找不到這份地震報告';

  @override
  String get moreVersionSnapshot => '測試版';

  @override
  String get mapLayerSatelliteTransparentNoData => '無資料(陸地) = 透明';

  @override
  String get restroomCategoryGovernment => '民眾洽公場所';

  @override
  String get typhoonLegendCurrent => '目前中心';

  @override
  String get aedAddress => '地址';

  @override
  String get mapLayerAed => 'AED';

  @override
  String get changelogTypePrerelease => '測試版';

  @override
  String get reportFilterIntensityInfoModernBody =>
      '震度為 0–4、5弱、5強、6弱、6強、7。篩選滑桿依新制；列表中較早的地震會以舊制標示顯示。';

  @override
  String get typhoonOverlayWeatherNone => '無';

  @override
  String get mapLayerStyleGray => '灰階（JMA）';

  @override
  String get weatherModeAuto => '自動';

  @override
  String get typhoonLabelProbCircle => '70%機率圓';

  @override
  String get notifyOptAll => '接收全部';

  @override
  String get displayTheme => '主題';

  @override
  String get mapLayerSatelliteB07 => 'ひまわり 短波紅外(B07)';

  @override
  String get typhoonLabelDirection => '過去移動方向';

  @override
  String get regionManageTitle => '常用地區';

  @override
  String get regionSaveNote =>
      '通知是以 GPS 所在地位置發送的，設定常用地區不會改變或影響通知發送，常用地區只是用於首頁快速查看不同區域狀態，所以務必授予 GPS 定位權限，否則通知無法運作';

  @override
  String get typhoonLegendCone => '預測圓錐';

  @override
  String get moreCwaEew => '中央氣象署強震即時警報';

  @override
  String get onboardingPermsTitle => '權限授權';

  @override
  String get mapLayerStyleJma => '雲頂強調（JMA）';

  @override
  String get rainInterval10m => '10 分';

  @override
  String get meshtasticConnectAnyway => '仍要連線';

  @override
  String reportListDayCount(int count) {
    return '$count';
  }

  @override
  String get mapLayerSatelliteB06 => 'ひまわり 近紅外(B06)';

  @override
  String get mapLayerSatelliteTransparentReflectance => '低反射率/夜間 = 透明,顯示底圖';

  @override
  String chartHourLabel(int hour) {
    return '$hour時';
  }

  @override
  String get mapLayerShelter => '避難收容場所';

  @override
  String get typhoonOverlayProbabilityTooltip => '顯示侵襲機率（會隱藏預測圓錐）';

  @override
  String get mapLayerSatelliteNdwi => 'ひまわり 水體指數';

  @override
  String get disasterMapOverlayShelterTooltip => '顯示避難收容場所';

  @override
  String get mapNavHumidity => '濕度';

  @override
  String get reportDetailSortByIntensity => '依震度排序';

  @override
  String get homeRainTrendNoData => '無資料';

  @override
  String get mapLayerCategoryRadar => '雷達';

  @override
  String get meshtasticShortName => '簡稱';

  @override
  String get mapLayerSatelliteAirmass => 'ひまわり 氣團';

  @override
  String get dataSectionWeather => '氣象';

  @override
  String get aedHoursWeekday => '平日開放時間';

  @override
  String get homeActiveEventsTitle => '生效中事件';

  @override
  String get faq => '常見問題';

  @override
  String eewSerial(int serial) {
    return '第 $serial 報';
  }

  @override
  String get reportFilterSort => '排序方式';

  @override
  String get meshtasticRegionConfirm =>
      '要將這台裝置切換為 TW 地區嗎？裝置會重新啟動並短暫斷線，上面的其他頻道也會一起改變。';

  @override
  String get dataEarthquakeSubtitle => '地震報告';

  @override
  String get typhoonNoActive => '目前無颱風';

  @override
  String get mapLayerSatelliteB11 => 'ひまわり 二氧化硫/雲相(B11)';

  @override
  String get navEvents => '事件';

  @override
  String get onboardingTermsTitle => '服務條款';

  @override
  String get mapOsmOverlay => '詳細地圖';

  @override
  String get mapOsmOverlayHint => '顯示更完整的道路、建物與地名';

  @override
  String get mapOsmDetails => '詳細設定';

  @override
  String get moreDataSources => '資料來源';

  @override
  String get dataSourceTremNet => '探索智慧科技有限公司 — TREM-Net';

  @override
  String get dataSourceCwa => '交通部中央氣象署 (CWA)';

  @override
  String get dataSourceJma => '気象庁 (JMA)';

  @override
  String get dataSourceNcdr => '國家災害防救科技中心 (NCDR)';

  @override
  String get dataSourceEcmwf =>
      'European Centre for Medium-Range Weather Forecasts (ECMWF)';

  @override
  String get dataSourceNoaaGfs =>
      'National Oceanic and Atmospheric Administration / National Centers for Environmental Prediction — Global Forecast System (NOAA/NCEP GFS)';

  @override
  String get dataSourceGovernmentOpenData => '政府資料開放平臺';

  @override
  String get dataSourceOpenStreetMap => '© OpenStreetMap contributors';

  @override
  String get dataSourceNasaMoon =>
      'National Aeronautics and Space Administration / Goddard Space Flight Center Scientific Visualization Studio — CGI Moon Kit (NASA/GSFC SVS)';

  @override
  String mapOsmDetailsHint(int enabled, int total) {
    return '已啟用 $enabled / 共 $total 個圖層';
  }

  @override
  String get mapOsmSurface => '地表';

  @override
  String get mapOsmParks => '公園';

  @override
  String get mapOsmLandUse => '土地利用';

  @override
  String get mapOsmAirportAreas => '機場區域';

  @override
  String get mapOsmWater => '水域';

  @override
  String get mapOsmRivers => '河川';

  @override
  String get mapOsmBoundaries => '邊界';

  @override
  String get mapOsmBuildings => '建物';

  @override
  String get mapOsmRoads => '道路';

  @override
  String get mapOsmRoadNames => '道路名稱';

  @override
  String get mapOsmWaterNames => '水域名稱';

  @override
  String get mapOsmPeaks => '山峰';

  @override
  String get mapOsmAirportNames => '機場名稱';

  @override
  String get mapOsmPlaceNames => '地名';

  @override
  String get mapOsmPoi => '地標';

  @override
  String get mapOsmHouseNumbers => '門牌號碼';

  @override
  String get mapOsmRestoreAll => '全部恢復';

  @override
  String get mapOsmSectionNatural => '地表與自然';

  @override
  String get mapOsmSectionRoadsAndBuildings => '道路與建物';

  @override
  String get mapOsmSectionLabelsAndPlaces => '地名與標示';

  @override
  String get mapTownLabels => '鄉鎮名稱';

  @override
  String get notifySetFailed => '設定失敗，請稍後再試。';

  @override
  String get meshtasticDisconnect => '斷線';

  @override
  String get meshtasticUndecoded => '無法解密';

  @override
  String get notifyAnnouncement => '公告';

  @override
  String get onboardingIntroTitle => '歡迎使用 DPIP';

  @override
  String get regionCurrentUnavailable => '無法取得所在地位置資訊';

  @override
  String get languageSystem => '系統預設';

  @override
  String get skyTimeSunset => '日落';

  @override
  String get mapLayerSatelliteDust => 'ひまわり 沙塵';

  @override
  String get mapAppAppleMaps => 'Apple Maps';

  @override
  String get regionEdit => '修改';

  @override
  String get weatherDynamicState => '天氣動態狀態';

  @override
  String get moonNow => '現在';

  @override
  String get moonSectionAppearance => '外觀';

  @override
  String get moonSectionRiseSet => '月出月沒';

  @override
  String get moonSectionUpcoming => '接下來';

  @override
  String get moonSectionCalendar => '月曆';

  @override
  String get moonDistance => '距離';

  @override
  String get moonKilometres => '公里';

  @override
  String get moonApparentSize => '視直徑';

  @override
  String get moonRise => '月出';

  @override
  String get moonSet => '月沒';

  @override
  String get moonNextNewMoon => '下次新月';

  @override
  String get moonAlwaysUp => '整日在地平線上';

  @override
  String get moonNoEvent => '當日無';

  @override
  String get sunTitle => '太陽';

  @override
  String get sunSectionDaylight => '日照';

  @override
  String get sunSectionTwilight => '曙暮光';

  @override
  String get sunSectionLight => '光線';

  @override
  String get sunSectionSundial => '日晷';

  @override
  String get sunSectionTerms => '節氣';

  @override
  String get sunRise => '日出';

  @override
  String get sunSet => '日沒';

  @override
  String get sunNoon => '正午';

  @override
  String get sunDayLength => '白晝長度';

  @override
  String get sunTwilightCivil => '民用';

  @override
  String get sunTwilightNautical => '航海';

  @override
  String get sunTwilightAstronomical => '天文';

  @override
  String get sunGoldenHourMorning => '晨間黃金時刻';

  @override
  String get sunGoldenHourEvening => '昏間黃金時刻';

  @override
  String get sunBlueHour => '藍調時刻';

  @override
  String get sunEquationOfTime => '均時差';

  @override
  String get sunMinutes => '分';

  @override
  String get solarTermNext => '下一個節氣';

  @override
  String get planetsTitle => '行星';

  @override
  String get planetsSectionTonight => '此刻';

  @override
  String get planetUp => '地平線上';

  @override
  String get planetDown => '地平線下';

  @override
  String get planetInGlare => '太近太陽';

  @override
  String get planetMagnitude => '亮度';

  @override
  String get planetElongation => '距日距角';

  @override
  String get planetSky => '時段';

  @override
  String get planetEvening => '昏星';

  @override
  String get planetMorning => '晨星';

  @override
  String get planetDistance => '距離';

  @override
  String get planetAu => '天文單位';

  @override
  String get planetAltitude => '仰角';

  @override
  String get planetMercury => '水星';

  @override
  String get planetVenus => '金星';

  @override
  String get planetMars => '火星';

  @override
  String get planetJupiter => '木星';

  @override
  String get planetSaturn => '土星';

  @override
  String get planetUranus => '天王星';

  @override
  String get planetNeptune => '海王星';

  @override
  String get solarTermVernalEquinox => '春分';

  @override
  String get solarTermPureBrightness => '清明';

  @override
  String get solarTermGrainRain => '穀雨';

  @override
  String get solarTermStartOfSummer => '立夏';

  @override
  String get solarTermGrainFull => '小滿';

  @override
  String get solarTermGrainInEar => '芒種';

  @override
  String get solarTermSummerSolstice => '夏至';

  @override
  String get solarTermMinorHeat => '小暑';

  @override
  String get solarTermMajorHeat => '大暑';

  @override
  String get solarTermStartOfAutumn => '立秋';

  @override
  String get solarTermEndOfHeat => '處暑';

  @override
  String get solarTermWhiteDew => '白露';

  @override
  String get solarTermAutumnalEquinox => '秋分';

  @override
  String get solarTermColdDew => '寒露';

  @override
  String get solarTermFrostDescent => '霜降';

  @override
  String get solarTermStartOfWinter => '立冬';

  @override
  String get solarTermMinorSnow => '小雪';

  @override
  String get solarTermMajorSnow => '大雪';

  @override
  String get solarTermWinterSolstice => '冬至';

  @override
  String get solarTermMinorCold => '小寒';

  @override
  String get solarTermMajorCold => '大寒';

  @override
  String get solarTermStartOfSpring => '立春';

  @override
  String get solarTermRainWater => '雨水';

  @override
  String get solarTermAwakeningOfInsects => '驚蟄';

  @override
  String get tonightTitle => '今夜';

  @override
  String get tonightSectionDark => '觀測窗口';

  @override
  String get tonightAstronomicalNight => '天文夜';

  @override
  String get tonightNeverDark => '整夜不全暗';

  @override
  String get tonightDarkWindow => '暗窗';

  @override
  String get tonightMoonAllNight => '月亮整夜在天上';

  @override
  String get tonightDarkTotal => '總暗時';

  @override
  String get tonightMoonlight => '月光';

  @override
  String get tonightSectionShowers => '流星雨';

  @override
  String get tonightRadiantDown => '輻射點不升起';

  @override
  String get tonightPerHour => '顆/時';

  @override
  String get tonightSectionSatellites => '衛星過境';

  @override
  String get tonightSectionTargets => '此刻可觀測目標';

  @override
  String get showerQuadrantids => '象限儀座';

  @override
  String get showerLyrids => '天琴座';

  @override
  String get showerEtaAquariids => '寶瓶座η';

  @override
  String get showerDeltaAquariids => '寶瓶座δ';

  @override
  String get showerPerseids => '英仙座';

  @override
  String get showerOrionids => '獵戶座';

  @override
  String get showerSouthernTaurids => '金牛座南';

  @override
  String get showerLeonids => '獅子座';

  @override
  String get showerGeminids => '雙子座';

  @override
  String get showerUrsids => '小熊座';

  @override
  String get deepSkyOpenCluster => '疏散星團';

  @override
  String get deepSkyGlobularCluster => '球狀星團';

  @override
  String get deepSkySpiralGalaxy => '螺旋星系';

  @override
  String get deepSkyEllipticalGalaxy => '橢圓星系';

  @override
  String get deepSkyIrregularGalaxy => '不規則星系';

  @override
  String get deepSkyPlanetaryNebula => '行星狀星雲';

  @override
  String get deepSkySupernovaRemnant => '超新星遺跡';

  @override
  String get deepSkyEmissionNebula => '發射星雲';

  @override
  String get deepSkyReflectionNebula => '反射星雲';

  @override
  String get deepSkyAsterism => '星群';

  @override
  String get almanacTitle => '曆法';

  @override
  String get almanacSectionToday => '今日';

  @override
  String get almanacGregorian => '西曆';

  @override
  String get almanacLunar => '農曆';

  @override
  String get almanacYear => '歲次';

  @override
  String get almanacMonthLength => '月大小';

  @override
  String get almanacLongMonth => '三十日';

  @override
  String get almanacShortMonth => '二十九日';

  @override
  String get almanacLeapPrefix => '閏';

  @override
  String get almanacSectionLunarEclipses => '月食';

  @override
  String get almanacSectionSolarEclipses => '日食';

  @override
  String get almanacNoSolarEclipse => '範圍內無';

  @override
  String get eclipseTotal => '全食';

  @override
  String get eclipsePartial => '偏食';

  @override
  String get eclipseAnnular => '環食';

  @override
  String get eclipsePenumbral => '半影食';

  @override
  String get zodiacRat => '鼠';

  @override
  String get zodiacOx => '牛';

  @override
  String get zodiacTiger => '虎';

  @override
  String get zodiacRabbit => '兔';

  @override
  String get zodiacDragon => '龍';

  @override
  String get zodiacSnake => '蛇';

  @override
  String get zodiacHorse => '馬';

  @override
  String get zodiacGoat => '羊';

  @override
  String get zodiacMonkey => '猴';

  @override
  String get zodiacRooster => '雞';

  @override
  String get zodiacDog => '狗';

  @override
  String get zodiacPig => '豬';

  @override
  String get tideTitle => '潮汐';

  @override
  String get tideDisclaimer => '僅為天文引潮力，非港口潮汐表。水位請參考氣象署公布之潮汐預報。';

  @override
  String get tideSectionNow => '此刻';

  @override
  String get tidePhase => '週期';

  @override
  String get tideSpring => '大潮';

  @override
  String get tideNeap => '小潮';

  @override
  String get tideMiddling => '中潮';

  @override
  String get tideLunarDistanceFactor => '月球引力';

  @override
  String get tideEquilibrium => '平衡潮高';

  @override
  String get tideMetres => '公尺';

  @override
  String get tidePerigeanSpring => '下次近地點大潮';

  @override
  String get tideSectionTurningPoints => '轉折點';

  @override
  String get tideHigh => '高';

  @override
  String get tideLow => '低';

  @override
  String get skyChartTitle => '星圖';

  @override
  String get skyChartNorth => '北';

  @override
  String get skyChartEast => '東';

  @override
  String get skyChartSouth => '南';

  @override
  String get skyChartWest => '西';

  @override
  String tonightElementAge(int days) {
    return '軌道資料 $days 天前';
  }

  @override
  String almanacLunarDate(String leap, int month, int day) {
    return '$leap$month 月 $day 日';
  }

  @override
  String get tonightNoShowers => '目前無流星雨';

  @override
  String get tonightNoPasses => '48 小時內無可見過境';

  @override
  String get tonightSatellitesUnavailable => '無法讀取軌道資料';

  @override
  String get tonightNoTargets => '無足夠高度的目標';

  @override
  String get skyChartUnavailable => '無法讀取星表';

  @override
  String get permissionSettingsTitle => '請到系統設定開啟';

  @override
  String get permissionSettingsHint => '返回 App 後會自動重新檢查。';

  @override
  String get permissionOpenSettings => '前往設定';

  @override
  String permissionSettingsMessage(String what) {
    return '「$what」已被拒絕，系統不會再詢問。請到設定中開啟。';
  }

  @override
  String get permissionGuideNotification => '請到系統設定中開啟通知權限。';

  @override
  String get permissionGuideForegroundLocation => '請到系統設定中開啟精確位置權限。';

  @override
  String permissionGuideBackgroundLocation(Object option) {
    return '請在「$option」中改為「允許所有時間」。';
  }

  @override
  String get permissionGuideBackgroundExecution =>
      '請到系統設定中允許背景執行,避免收到通知時被系統暫停。';

  @override
  String get permissionGuideUnusedPause => '若應用程式被標記為「未使用」,請在系統設定中改為「允許」。';

  @override
  String get permissionGuideUnusedFreeSpace => '若應用程式因暫存空間不足被暫停,請清除暫存後重新開啟。';

  @override
  String get permissionGuideUnusedRevoke => '若應用程式權限被撤銷,請在系統設定中重新授予。';

  @override
  String get permissionGuideUnusedPlayProtect =>
      '若被 Play 保護機制暫停,請到 Google Play 中檢查應用程式狀態。';

  @override
  String permissionGuideVendorPower(Object vendor) {
    return '請到「$vendor」的省電設定中,將本應用程式設為「不限制」。';
  }

  @override
  String get permissionStillRequired => '仍然需要此權限,請到設定中開啟。';

  @override
  String get permissionVerifyManually => '請手動確認此權限已在系統設定中開啟。';

  @override
  String get permissionBackgroundLocationOption => '「允許所有時間」';

  @override
  String get displayTextSize => '文字大小';

  @override
  String get displayTextSizeDesc => '只影響 App 介面，地圖上的文字大小不變。';

  @override
  String get displayTextWeight => '文字粗細';

  @override
  String get displayTextWeightDesc => '較粗的文字通常更容易閱讀。';

  @override
  String get displayContrast => '對比度';

  @override
  String get displayContrastDesc => '對比越高，文字與背景的差異越明顯。';

  @override
  String get displayColorVision => '色覺調整';

  @override
  String get displayColorVisionDesc => '整個 App 的顏色都會重新調整，地圖也一併改變。';

  @override
  String get displayColorVisionNone => '標準色彩';

  @override
  String get displayColorVisionProtan => '紅色弱';

  @override
  String get displayColorVisionDeutan => '綠色弱';

  @override
  String get displayColorVisionTritan => '藍黃色弱';

  @override
  String get displayPreviewSample => '地震報告範例';

  @override
  String get displayScaleSmall => '小';

  @override
  String get displayScaleDefault => '標準';

  @override
  String get displayScaleLarge => '大';

  @override
  String get displayScaleHuge => '特大';

  @override
  String get displayWeightNormal => '標準';

  @override
  String get displayWeightMedium => '中等';

  @override
  String get displayWeightBold => '粗體';

  @override
  String get displayContrastStandard => '標準';

  @override
  String get displayContrastMedium => '中等';

  @override
  String get displayContrastHigh => '高';

  @override
  String get meshtasticDirect => '直連';

  @override
  String meshtasticHopsAway(int n) {
    return '$n 跳';
  }

  @override
  String get meshtasticStatRelayShare => '為他人轉發';

  @override
  String get meshtasticStatRelayShareHint => '佔本機發送量的比例';

  @override
  String get meshtasticStatRelayValue => '轉發成功率';

  @override
  String get meshtasticStatRelaySolePath => '經常是唯一路徑 — 網路依賴此節點';

  @override
  String get meshtasticStatRelayRedundant => '其他節點也覆蓋同樣路徑';

  @override
  String get meshtasticStatRedundancy => '重複接收';

  @override
  String get meshtasticStatThinEdge => '備援路徑少 — 一個中繼失效就可能斷線';

  @override
  String get meshtasticStatWellCovered => '有多條路徑可達';

  @override
  String get meshtasticStatErrorRate => '接收錯誤率';

  @override
  String get meshtasticStatErrorRateHint => '空中時間不變卻升高 = 干擾';

  @override
  String get meshtasticTraceRoute => '追蹤路由';

  @override
  String get meshtasticTracing => '追蹤中…';

  @override
  String get meshtasticTraceUnreadable => '無法解讀的回覆';

  @override
  String get meshtasticTraceOffline => '未連線至電台';

  @override
  String get meshtasticTraceCooldown => '電台限制每 30 秒一次';

  @override
  String get meshtasticTraceNoReply => '沒有回應 — 超出範圍或金鑰不同';

  @override
  String get meshtasticTraceDirect => '直達 — 中間無中繼';

  @override
  String meshtasticTraceHops(int n) {
    return '$n 跳';
  }

  @override
  String get moreDumpDiagnostics => '傾印除錯資訊及日誌';

  @override
  String get moreDumpDiagnosticsHint => '上傳後複製連結';

  @override
  String get dumpIncludeSensitive => '包含精確位置';

  @override
  String get dumpIncludeSensitiveHint => '包含日誌與背景定位中的座標；未勾選時會以 null 取代';

  @override
  String get dumpUpload => '上傳';

  @override
  String get dumpUploaded => '已上傳';

  @override
  String get dumpLinkCopied => '連結已複製到剪貼簿';

  @override
  String get dumpCopyAgain => '再複製一次';

  @override
  String get dumpUploadFailed => '上傳失敗，請稍後再試';

  @override
  String get statusLegendUnprobed => '未探測';

  @override
  String get statusLegendUnsupported => '不支援';

  @override
  String get rainScaleSection => '色階間距';

  @override
  String get rainScaleFine => '小間距';

  @override
  String get rainScaleCoarse => '大間距';

  @override
  String get notifyTestTitle => '測試通知';

  @override
  String get notifyTestIntro => '點一下就會實際發送該則警報。重大警報會以最大音量播放，並穿透靜音與勿擾模式。';

  @override
  String get notifyTestCriticalDenied => '這台裝置未允許「重要警告」，重大警報在靜音時同樣不會發出聲音。';

  @override
  String get notifyTestPermissionOff => '通知已關閉，測試不會有任何反應。';

  @override
  String get notifyTestBehaviourOverrides => '會穿透靜音與勿擾模式';

  @override
  String get notifyTestBehaviourAlerts => '有聲音並跳出橫幅，但手機靜音時不會響';

  @override
  String get notifyTestBehaviourSounds => '有聲音、不跳出橫幅，手機靜音時不會響';

  @override
  String get notifyTestBehaviourSilent => '無聲，只出現在通知中心';

  @override
  String get notifyTestFailed => '無法發送測試通知。';

  @override
  String get moreBugReports => '已回報的錯誤';

  @override
  String get bugTrackerEmpty => '還沒有已回報的錯誤';

  @override
  String get bugTrackerReplies => '回覆';

  @override
  String get bugTrackerGoToDiscord => '找不到你的問題？快前往 Discord 回報！';

  @override
  String get bugTrackerNoMatch => '沒有符合所選標籤的錯誤回報';

  @override
  String get bugTrackerDeveloper => '開發人員';

  @override
  String get bugTrackerCannotDisplay => '無法顯示此內容，請在 Discord 上查看';

  @override
  String get bugTrackerJoinDiscussion => '至 Discord 參與討論';

  @override
  String get bugTrackerSortLast => '最後討論';

  @override
  String get bugTrackerSortMostDiscussed => '最多討論';

  @override
  String get bugTrackerStaff => '工作人員';

  @override
  String eewSpokenLocalIntensity(String intensity) {
    return '所在地預估震度，$intensity。';
  }

  @override
  String eewSpokenMaxIntensity(String intensity) {
    return '預估最大震度，$intensity。';
  }
}
