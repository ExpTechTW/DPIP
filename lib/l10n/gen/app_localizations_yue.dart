// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Yue Chinese Cantonese (`yue`).
class AppLocalizationsYue extends AppLocalizations {
  AppLocalizationsYue([String locale = 'yue']) : super(locale);

  @override
  String typhoonValueLat(String lat) {
    return '北緯 $lat 度';
  }

  @override
  String get onboardingSkipBody =>
      '未授權定位同通知,DPIP 將冇辦法即時通知你所在地嘅地震同災害。你仍可稍後喺設定中開啟。';

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
      'Android 會暫停你長期未開啟嘅 App 並撤銷佢哋嘅權限，噉會令災害警報冇辦法送到你所在地。';

  @override
  String get onboardingPermBackgroundExec => '背景執行';

  @override
  String get onboardingPermBackgroundExecDesc => '關閉時，App 唔會被喚醒回報你嘅位置。';

  @override
  String get onboardingPermVendorPower => '手機廠商省電設定';

  @override
  String onboardingPermVendorPowerDesc(String brand) {
    return '$brand 會停止你最近冇開過嘅 App 嘅背景作業。App 冇辦法偵測或變更，請手動允許。';
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
  String get mapTerrainReliefHint => '喺底圖上顯示立體地形陰影';

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
  String get permissionsBody => 'DPIP 需要呢些權限才能即時通知你。收唔到警報時，通常就係其中一項尚未開啟。';

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
  String get meshtasticExcludeMqttSubtitle => '經網際網路橋接、並非無線電聽到嘅節點';

  @override
  String get reportFilterIntensityInfoTitle => '震度新制同舊制';

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
  String get eewNone => '而家冇地震速報';

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
  String get moreLinkOpenFailed => '冇辦法開啟連結';

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
  String get mapLayerStyleBdTooltip => 'Dvorak BD 曲線——熱帶氣旋強度分析嘅階梯灰階';

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
  String get reportListEmpty => '而家冇地震報告';

  @override
  String get reportListEnd => '已到最後一頁';

  @override
  String get mapLayerSatelliteTruecolor => 'ひまわり 真彩色';

  @override
  String get typhoonOverlaySectionExtra => '覆蓋層';

  @override
  String get eewSWave => '震波';

  @override
  String get meshtasticBusyTitle => '另一個 App 正在使用呢台裝置';

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
  String get mapTimelineNow => '而家';

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
      'DPIP 致力於提供即時防災資訊，冇廣告或其他營利模式。你嘅支援能幫助我哋維持伺服器運作並持續開發。';

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
  String get defaultMapLayerSubtitle => '開啟地圖分頁時顯示此圖層，底部導覽列圖示同文字會一併更新。';

  @override
  String get aedDescription => '備註';

  @override
  String get typhoonOverlayWeatherRadarTooltip => '雷達回波（對齊颱風報文時間）';

  @override
  String get onboardingPermLocationDesc => '依你所在位置推送本地警報。';

  @override
  String get mapLayerSatelliteB16 => 'ひまわり 二氧化碳(B16)';

  @override
  String get homeActiveEventsEmpty => '而家冇生效中嘅事件';

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
  String get onboardingPermNotifyDesc => '在地震、天氣同災害發生時,即時傳遞警報通知。';

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
  String get weatherRankingEmpty => '而家冇可排序嘅觀測';

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
  String get meshtasticNoDevices => '找唔到 Meshtastic 裝置';

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
  String get dpmYes => '係';

  @override
  String get meshtasticNoHistory => '歷史紀錄還唔夠';

  @override
  String get reportDetailLocalIntensityUnavailable => '冇震度訊息';

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
      'DPIP 係同你並肩嘅防災夥伴,整合強震即時警報、地震報告、天氣同各類災害資訊,喺關鍵時刻即時通知你。\n\n• 地震:強震即時警報、震度速報同地震報告\n• 天氣:雷暴即時訊息、天氣警告及特報\n• 海嘯同防災資訊\n\n接下來,我哋會請你閱讀服務條款,並授權幾項讓 DPIP 能即時守護你嘅權限。';

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
  String get eewSourceSubtitle => '選擇要顯示哪些機構發布嘅地震速報。';

  @override
  String get eewSourceAll => '所有來源';

  @override
  String get eewSourceAllDescription => '顯示所有機構發布嘅地震速報。';

  @override
  String get eewSourceCwaOnly => '僅中央氣象署';

  @override
  String get eewSourceCwaOnlyDescription => '只顯示中央氣象署發布嘅地震速報。';

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
  String get morePartnersNote => '依合作時間先後排列。感謝呢些個人同公司對防災嘅貢獻，佢哋讓 DPIP 成為可能。';

  @override
  String get morePartnerGeoscience => '巨科資訊有限公司';

  @override
  String get morePartnerTwds => '台灣數位串流有限公司';

  @override
  String get reportFilterIntensityInfoLegacyBody => '震度僅 0–7，冇 5弱／5強／6弱／6強。';

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
  String get radarTownOutlineHint => '較細嘅分區';

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
  String get windForecastTownOutlineHint => '更細嘅網格';

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
  String get onboardingPermBackgroundDesc => '選擇「一律允許」,關閉 App 都能推送本地警報。';

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
  String get changelogCurrentVersion => '而家版本';

  @override
  String get typhoonLabelPressure => '中心氣壓';

  @override
  String get typhoonOverlayForecastCalloutsTooltip => '放大時顯示預測點詳細卡片';

  @override
  String get aedOpenRemark => '開放時間備註';

  @override
  String get onboardingPermsBody => '為咗喺災害發生嘅第一時間通知你,請授權以下權限。你隨時可以喺系統設定中更改。';

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
  String get commonEmpty => '冇資料';

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
  String get meshtasticChannelFailed => '冇辦法設定 DPIP 頻道';

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
  String get dpmSheetEmpty => '點選地圖上嘅標記查看詳情';

  @override
  String get onboardingSkipLeave => '仍要略過';

  @override
  String get aedPlaceDesc => '放置位置講明';

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
  String get mapLayerMeshtasticSubtitle => '電台聽到過嘅 LoRa 網狀網路節點';

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
  String get homeViewOnMap => '前往地圖查看';

  @override
  String get reportFilterIntensityInfoLegacyTitle => '舊制（2020 以前）';

  @override
  String get typhoonLabelSpeed => '過去移動時速';

  @override
  String mapAppOpenFailed(String app) {
    return '冇辦法開啟 $app';
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
  String get changelogBodyEmpty => '此版本冇講明。';

  @override
  String get changelogOpenOnGitHub => '喺 GitHub 查看';

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
  String get homeForecastEmpty => '而家冇預報資料';

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
  String get onboardingPermCriticalDesc => '讓危及生命嘅強震即時警報,即使喺靜音或勿擾模式下都能發出聲響。';

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
  String get sponsorRestoreUnavailable => '冇辦法連線至商店，請稍後再試';

  @override
  String homeForecastPop(String pop) {
    return '$pop%';
  }

  @override
  String get regionEmpty => '尚未新增常用地區';

  @override
  String get onboardingPermBatteryDesc => '允許 DPIP 喺背景持續運作,避免警報延遲或漏收。';

  @override
  String get mapNavDisaster => '防災';

  @override
  String get radarScanRangeSubtitle => '標示四座雷達實際觀測到嘅範圍。';

  @override
  String get aedHoursSunday => '週日開放時間';

  @override
  String get reportDetailOriginTime => '發震時間';

  @override
  String get trendNoData => '冇趨勢資料';

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
  String get changelogEmpty => '而家冇更新日誌';

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
  String get commonFetchFailed => '冇辦法獲取資料,請稍後重試';

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
  String get locationBannerPermission => '尚未授權定位,冇辦法針對你嘅所在地推送警報。';

  @override
  String get typhoonOverlayWeatherNoneTooltip => '唔疊雷達或紅外線';

  @override
  String get radarCountyOutlineHint => '畫喺回波上面';

  @override
  String get windForecastCountyOutlineHint => '繪製喺風場上面';

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
  String get mapAppCallFailed => '此裝置冇辦法撥打電話';

  @override
  String get reportFilterAny => '唔限';

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
      '使用 DPIP 前,請詳閱以下注意事項:\n\n• 任何資訊應以中央氣象署發布嘅內容為準。\n\n• 根據網絡狀態、伺服器狀態、應用程式狀態、上游資料來源狀態等,有收唔到資訊嘅可能性,我哋會盡力避免此類情況,但唔保證一定唔會發生。\n\n• 強烈搖晃有機會早過通知到達用戶所在地。\n\n• 地震速報係快速計算嘅結果,可能存在較大誤差,應該理解並謹慎使用。\n\n• 任何唔受官方認可嘅行為均有可能承擔法律風險,請務必遵守相關規範。\n\n此外,為提供本地化警報,本服務會喺前景及背景收集並上傳你嘅概略位置同裝置推送識別碼,僅用嚟決定應向你推送嘅警報。\n\n㩒下方「同意並繼續」就表示你已閱讀、理解並同意上述事項。';

  @override
  String get reportFilterTitle => '篩選';

  @override
  String get onboardingPermCritical => '重大通知';

  @override
  String trendCumulativeTotal(String total) {
    return '累計 $total mm';
  }

  @override
  String get languageName => '粵語';

  @override
  String get reportListEmptyFiltered => '冇符合條件嘅地震報告';

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
  String get reportDetailLocalIntensity => '所在地嘅震度';

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
  String get meshtasticSendHint => '要廣播嘅訊息';

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
  String get restroomGradePoor => '唔合格';

  @override
  String get restroomCategoryTourist => '觀光地區及風景區';

  @override
  String get locationBannerServiceOff => '定位服務已關閉,冇辦法針對你嘅所在地推送警報。';

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
      '伺服器指標來自控制台。下方係本機對多活端點（LB / Core 各區）嘅實際連線判斷：APP 只被動記錄本機實際播送嘅流量，若該端點從未被本機觸發，就會顯示未探測。';

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
  String get serverStatusCloudflareNone => '而家冇可顯示嘅區域。';

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
  String get endpointHealthDegraded => '有端點連線唔穩';

  @override
  String get endpointHealthDown => '本機連線異常';

  @override
  String get endpointHealthUnknown => '尚無觀測資料';

  @override
  String get endpointStateOk => '正常';

  @override
  String get endpointStateDegraded => '唔穩';

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
  String get notifyBannerDisabled => '通知已關閉,將收唔到災害警報。';

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
      '請先喺另一個 Meshtastic App 中斷線。兩個 App 同時連同一台裝置會互相搶走訊息，導致部分訊息遺失。';

  @override
  String get meshtasticChannelNoSlot => '冇可用嘅頻道空位 — 請先喺裝置上空出一個';

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
  String get moreVersionNotesHighlightsSubtitle => '呢個版本做咗哪些改變';

  @override
  String releaseHighlightsTitle(Object train) {
    return '$train 重點整理';
  }

  @override
  String get releaseHighlightsTabNormal => '做咗哪些改變';

  @override
  String get releaseHighlightsTabAdvanced => '深入技術';

  @override
  String get releaseHighlightsEmpty => '而家冇內容。';

  @override
  String get releaseHighlightsSeeNotes => '查看完整更新日誌';

  @override
  String get moreVersionNotesEmpty => '找唔到而家版本嘅更新日誌';

  @override
  String get reportNotFound => '搵唔到呢份地震報告';

  @override
  String get moreVersionSnapshot => '測試版';

  @override
  String get mapLayerSatelliteTransparentNoData => '無資料(陸地) = 透明';

  @override
  String get restroomCategoryGovernment => '民眾洽公場所';

  @override
  String get typhoonLegendCurrent => '而家中心';

  @override
  String get aedAddress => '地址';

  @override
  String get mapLayerAed => 'AED';

  @override
  String get changelogTypePrerelease => '測試版';

  @override
  String get reportFilterIntensityInfoModernBody =>
      '震度為 0–4、5弱、5強、6弱、6強、7。篩選滑桿依新制；列表中較早嘅地震會以舊制標示顯示。';

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
      '通知係以 GPS 所在地位置發送嘅，設定常用地區唔會改變或影響通知發送，常用地區只係用於首頁快速查看唔同區域狀態，所以務必授予 GPS 定位權限，否則通知冇辦法運作';

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
      '要將呢台裝置切換為 TW 地區嗎？裝置會重新啟動並短暫斷線，上面嘅其他頻道都會一齊改變。';

  @override
  String get dataEarthquakeSubtitle => '地震報告';

  @override
  String get typhoonNoActive => '而家無颱風';

  @override
  String get mapLayerSatelliteB11 => 'ひまわり 二氧化硫/雲相(B11)';

  @override
  String get navEvents => '事件';

  @override
  String get onboardingTermsTitle => '服務條款';

  @override
  String get mapOsmOverlay => '詳細地圖';

  @override
  String get mapOsmOverlayHint => '顯示更完整嘅道路、建物同地名';

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
  String get mapOsmSectionNatural => '地表同自然';

  @override
  String get mapOsmSectionRoadsAndBuildings => '道路同建物';

  @override
  String get mapOsmSectionLabelsAndPlaces => '地名同標示';

  @override
  String get mapTownLabels => '鄉鎮名稱';

  @override
  String get notifySetFailed => '設定失敗,請稍後再試。';

  @override
  String get meshtasticDisconnect => '斷線';

  @override
  String get meshtasticUndecoded => '冇辦法解密';

  @override
  String get notifyAnnouncement => '公告';

  @override
  String get onboardingIntroTitle => '歡迎使用 DPIP';

  @override
  String get regionCurrentUnavailable => '冇辦法取得所在地位置資訊';

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
  String get moonNow => '而家';

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
  String get sunSet => '日冇';

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
  String get tonightNeverDark => '整夜唔全暗';

  @override
  String get tonightDarkWindow => '暗窗';

  @override
  String get tonightMoonAllNight => '月亮整夜喺天上';

  @override
  String get tonightDarkTotal => '總暗時';

  @override
  String get tonightMoonlight => '月光';

  @override
  String get tonightSectionShowers => '流星雨';

  @override
  String get tonightRadiantDown => '輻射點唔升起';

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
  String get deepSkyIrregularGalaxy => '唔規則星系';

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
  String get tideDisclaimer => '僅為天文引潮力，非港口潮汐表。水位請參考氣象署公布嘅潮汐預報。';

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
  String get tonightNoShowers => '而家無流星雨';

  @override
  String get tonightNoPasses => '48 小時內無可見過境';

  @override
  String get tonightSatellitesUnavailable => '冇辦法讀取軌道資料';

  @override
  String get tonightNoTargets => '無足夠高度嘅目標';

  @override
  String get skyChartUnavailable => '冇辦法讀取星表';

  @override
  String get permissionSettingsTitle => '請到系統設定開啟';

  @override
  String get permissionSettingsHint => '返回 App 後會自動重新檢查。';

  @override
  String get permissionOpenSettings => '前往設定';

  @override
  String permissionSettingsMessage(String what) {
    return '「$what」已被拒絕，系統唔會再詢問。請到設定中開啟。';
  }

  @override
  String get permissionGuideNotification => '請到系統設定中開啟通知權限。';

  @override
  String get permissionGuideForegroundLocation => '請到系統設定中開啟精確位置權限。';

  @override
  String permissionGuideBackgroundLocation(Object option) {
    return '請喺「$option」中改為「允許所有時間」。';
  }

  @override
  String get permissionGuideBackgroundExecution =>
      '請到系統設定中允許背景執行,避免收到通知時被系統暫停。';

  @override
  String get permissionGuideUnusedPause => '若應用程式被標記為「未使用」,請喺系統設定中改為「允許」。';

  @override
  String get permissionGuideUnusedFreeSpace => '若應用程式因暫存空間唔夠被暫停,請清除暫存後重新開啟。';

  @override
  String get permissionGuideUnusedRevoke => '若應用程式權限被撤銷,請喺系統設定中重新授予。';

  @override
  String get permissionGuideUnusedPlayProtect =>
      '若被 Play 保護機制暫停,請到 Google Play 中檢查應用程式狀態。';

  @override
  String permissionGuideVendorPower(Object vendor) {
    return '請到「$vendor」嘅省電設定中,將本應用程式設為「唔限制」。';
  }

  @override
  String get permissionStillRequired => '仍然需要此權限,請到設定中開啟。';

  @override
  String get permissionVerifyManually => '請手動確認此權限已喺系統設定中開啟。';

  @override
  String get permissionBackgroundLocationOption => '「允許所有時間」';

  @override
  String get displayTextSize => '文字大小';

  @override
  String get displayTextSizeDesc => '只調整 App 介面嘅文字，地圖上嘅文字維持原本大小。';

  @override
  String get displayTextWeight => '文字粗細';

  @override
  String get displayTextWeightDesc => '文字較粗時可能更容易閱讀。';

  @override
  String get displayContrast => '對比度';

  @override
  String get displayContrastDesc => '對比越高，文字同背景越分明。';

  @override
  String get displayColorVision => '色覺調整';

  @override
  String get displayColorVisionDesc => '整個 App 嘅顏色都會一併調整，包括地圖。';

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
  String get meshtasticStatRelayShareHint => '佔本機發送量嘅比例';

  @override
  String get meshtasticStatRelayValue => '轉發成功率';

  @override
  String get meshtasticStatRelaySolePath => '經常係唯一路徑 — 網絡依賴此節點';

  @override
  String get meshtasticStatRelayRedundant => '其他節點都覆蓋同樣路徑';

  @override
  String get meshtasticStatRedundancy => '重複接收';

  @override
  String get meshtasticStatThinEdge => '備援路徑少 — 一個中繼失效就可能斷線';

  @override
  String get meshtasticStatWellCovered => '有多條路徑可達';

  @override
  String get meshtasticStatErrorRate => '接收錯誤率';

  @override
  String get meshtasticStatErrorRateHint => '空中時間唔變卻升高 = 干擾';

  @override
  String get meshtasticTraceRoute => '追蹤路由';

  @override
  String get meshtasticTracing => '追蹤中…';

  @override
  String get meshtasticTraceUnreadable => '冇辦法解讀嘅回覆';

  @override
  String get meshtasticTraceOffline => '未連線至電台';

  @override
  String get meshtasticTraceCooldown => '電台限制每 30 秒一次';

  @override
  String get meshtasticTraceNoReply => '冇回應 — 超出範圍或金鑰唔同';

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
  String get dumpIncludeSensitiveHint => '包含日誌同背景定位入面嘅座標；唔勾選就會以 null 取代';

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
  String get statusLegendUnsupported => '唔支援';

  @override
  String get rainScaleSection => '色階間距';

  @override
  String get rainScaleFine => '小間距';

  @override
  String get rainScaleCoarse => '大間距';

  @override
  String get notifyTestTitle => '測試通知';

  @override
  String get notifyTestIntro => '撳一下就會真係發送嗰則警報。重大警報會用最大音量播放，仲會穿透靜音同勿擾模式。';

  @override
  String get notifyTestCriticalDenied => '呢部裝置未允許「重要警告」，重大警報喺靜音時一樣唔會出聲。';

  @override
  String get notifyTestPermissionOff => '通知已關閉，測試唔會有任何反應。';

  @override
  String get notifyTestBehaviourOverrides => '會穿透靜音同勿擾模式';

  @override
  String get notifyTestBehaviourAlerts => '有聲音仲會彈橫幅，但手機靜音時唔會響';

  @override
  String get notifyTestBehaviourSounds => '有聲音、唔會彈橫幅，手機靜音時唔會響';

  @override
  String get notifyTestBehaviourSilent => '無聲，只會出現喺通知中心';

  @override
  String get notifyTestFailed => '無法發送測試通知。';

  @override
  String get moreBugReports => '已回報嘅錯誤';

  @override
  String get bugTrackerEmpty => '仲未有已回報嘅錯誤';

  @override
  String get bugTrackerReplies => '回覆';

  @override
  String get bugTrackerGoToDiscord => '搵唔到你嘅問題？快啲去 Discord 回報！';

  @override
  String get bugTrackerNoMatch => '冇符合所選標籤嘅錯誤回報';

  @override
  String get bugTrackerDeveloper => '開發人員';

  @override
  String get bugTrackerCannotDisplay => '無法顯示呢個內容，請去 Discord 查看';

  @override
  String get bugTrackerJoinDiscussion => '去 Discord 一齊傾';

  @override
  String get bugTrackerSortLast => '最後傾偈';

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
