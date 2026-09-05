// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String typhoonValueLat(String lat) {
    return '北緯 $lat 度';
  }

  @override
  String get onboardingSkipBody =>
      '位置情報と通知を許可しないと、DPIP はお近くの地震や災害をリアルタイムでお知らせできません。設定から後で許可することもできます。';

  @override
  String get rainInterval24h => '24時間';

  @override
  String homeRainTrendHeavyStopping(int minutes) {
    return '$minutes分後に大雨が止む見込みです';
  }

  @override
  String get mapTimelineObserved => '観測';

  @override
  String get mapTimelineScrubPaused =>
      '操作が速すぎるため、フレーム更新を一時停止しました。速度を落とすと再開します。';

  @override
  String get regionSelectTitle => '地域を選択';

  @override
  String get skyTimeNoon => '正午';

  @override
  String get radarCountyOutlineSubtitle => 'レーダーエコーの下でも県市境界が見えるようにします。';

  @override
  String get mapLayerSatelliteB03 => 'ひまわり 可視赤(B03)';

  @override
  String get reportFilterIntensity => '震度';

  @override
  String get mapLayerLightning => '雷';

  @override
  String get restroomTypeMale => '男性用トイレ';

  @override
  String get meshtasticLastReceived => '最終受信';

  @override
  String get reportDetailSortByCounty => '地域順に並べ替え';

  @override
  String get onboardingPermUnusedApp => 'アプリを有効に保つ';

  @override
  String get onboardingPermUnusedAppDesc =>
      'Android はしばらく開いていないアプリを一時停止し、権限を取り消します。その結果、災害警報が現在地に届かなくなります。';

  @override
  String get onboardingPermBackgroundExec => 'バックグラウンド動作';

  @override
  String get onboardingPermBackgroundExecDesc =>
      'オフにすると、位置を報告するためのアプリ起動が行われません。';

  @override
  String get onboardingPermVendorPower => 'メーカーの電池設定';

  @override
  String onboardingPermVendorPowerDesc(String brand) {
    return '$brand は最近開いていないアプリのバックグラウンド動作を停止します。アプリからは検出も変更もできないため、手動で許可してください。';
  }

  @override
  String get homeRainTrendScattered => 'にわか雨の可能性があります';

  @override
  String get meshtasticUptime => '稼働時間';

  @override
  String get weatherRankingTempExtremes => '気温極値';

  @override
  String get themeLight => 'ライト';

  @override
  String get mapTerrainReliefHint => 'ベースマップに地形の陰影を表示';

  @override
  String get meshtasticEmptyMessage => '(空メッセージ)';

  @override
  String get moreSectionRegion => '地域';

  @override
  String get mapLayerSatellite => 'ひまわり 赤外線(B13)';

  @override
  String get aedHoursSaturday => '土曜の開館時間';

  @override
  String get moonPhaseNew => '新月';

  @override
  String get notifySectionEew => '緊急地震速報';

  @override
  String get mapResetNorth => '北を上にする';

  @override
  String get rainInterval2d => '2日';

  @override
  String get mapTownLabelsHint => '拡大すると郷鎮名を表示';

  @override
  String get commonCancel => 'キャンセル';

  @override
  String get notifyOptTsunamiWarning => '津波警報のみ';

  @override
  String get mapLayerSatelliteBtdFog => 'ひまわり 夜間霧';

  @override
  String get moreSectionAdvanced => '詳細設定';

  @override
  String get moreSectionMesh => 'メッシュネットワーク';

  @override
  String get weatherRankingExtremeRange => '日較差';

  @override
  String get permissionsTitle => '権限チェック';

  @override
  String get permissionsAttention => '権限の確認が必要です';

  @override
  String get permissionsBody =>
      'DPIP がすぐに通知するには、これらの権限が必要です。通知が届かない場合、たいていはいずれかが未許可です。';

  @override
  String get notifySettingsMenu => '通知設定';

  @override
  String mapAppDefault(String app) {
    return '$app（デフォルト）';
  }

  @override
  String get trendRange24h => '24時間';

  @override
  String get mapLayerStyleJmaTooltip => 'グレースケールをベースに −40 °C 以下を着色し、雲頂高度を強調';

  @override
  String get mapLayerRain => '降水量';

  @override
  String get mapLayerQpesums => '1時間降水量予報';

  @override
  String get mapOverlaySectionMap => '地図';

  @override
  String get mapTerrainRelief => '地形の立体感';

  @override
  String get mapLegendCollapse => '凡例を閉じる';

  @override
  String get updateAvailableTitle => '新しいバージョン';

  @override
  String updateAvailableBody(String version) {
    return 'バージョン $version が公開されました。';
  }

  @override
  String get updateSkip => '今回はスキップ';

  @override
  String get updateViewChangelog => '内容を見る';

  @override
  String get updateOpenAppStore => 'App Store';

  @override
  String get updateOpenTestFlight => 'TestFlight';

  @override
  String get updateOpenPlayStore => 'Play ストア';

  @override
  String get updateDownload => 'ダウンロード';

  @override
  String get changelogShowSnapshots => 'スナップショットを表示';

  @override
  String get changelogTitle => '更新履歴';

  @override
  String get reportFilterOrderDesc => '降順';

  @override
  String get meshtasticExcludeMqttSubtitle =>
      'インターネット経由で橋渡しされたノード(無線では受信していません)';

  @override
  String get reportFilterIntensityInfoTitle => '震度の新制と旧制';

  @override
  String get mapLayerTyphoon => '台風';

  @override
  String get radarOverlayMenuTooltip => 'レーダーレイヤー設定';

  @override
  String get meshtasticNodes => 'ノード';

  @override
  String get meshtasticSend => '送信';

  @override
  String get typhoonOverlayStormL7Tooltip => '強風域 + 平均円（紫）';

  @override
  String get aedType => '種類';

  @override
  String get termsOfService => '利用規約';

  @override
  String get typhoonLegendCircle25 => '暴風域（50kt）';

  @override
  String get sponsorTitle => 'DPIP を支援';

  @override
  String get mapNavSatellite => '衛星';

  @override
  String homeRainTrendUpdated(String time) {
    return '更新 $time';
  }

  @override
  String get onboardingNext => '次へ';

  @override
  String get weatherRankingMergeTown => '町村';

  @override
  String get mapLayerMonitor => '強震モニタ';

  @override
  String get moreYoutube => 'YouTube';

  @override
  String get sponsorSubscriptions => 'サブスクリプション';

  @override
  String typhoonValueLon(String lon) {
    return '東経 $lon 度';
  }

  @override
  String get skyTime => '空の時刻';

  @override
  String get weatherModeCloudy => '曇り';

  @override
  String get skyTimeDusk => '薄暮';

  @override
  String get meshtasticFirmware => 'ファームウェア';

  @override
  String get reportFilterDateEndNote => '終了日：当日 24:00（台北時間）';

  @override
  String get reportFilterSortMagnitude => '規模';

  @override
  String get meshtasticSilent => 'サイレント';

  @override
  String get mapLayerCategoryEarthquake => '地震';

  @override
  String get mapLayerSatelliteB12 => 'ひまわり オゾン(B12)';

  @override
  String get restroomCategoryOther => 'その他';

  @override
  String homeForecastHighLow(String high, String low) {
    return '高 $high° · 低 $low°';
  }

  @override
  String get locationBannerFix => '設定を開く';

  @override
  String get mapLegendExpand => '凡例';

  @override
  String get eewNone => '現在、緊急地震速報はありません';

  @override
  String typhoonTyNo(String no) {
    return 'TY $no';
  }

  @override
  String get notifyOptTsunamiAll => '津波情報・津波警報';

  @override
  String get meshtasticLayerOptions => 'ノードオプション';

  @override
  String get onboardingAgreeContinue => '同意して続行';

  @override
  String get commonRetry => '再試行';

  @override
  String get meshtasticNodeId => 'ノード ID';

  @override
  String reportDetailNumbered(String number) {
    return 'No.$number 顕著有感地震';
  }

  @override
  String get typhoonOverlayStormBandSubtitle => '平均円付き';

  @override
  String get disasterMapOverlayRestroomTooltip => 'トイレを表示';

  @override
  String get weatherRankingTitle => '観測ランキング';

  @override
  String get homeRainTrendHeavySustained => '今後1時間は大雨が続きます';

  @override
  String get notifySectionTsunami => '津波';

  @override
  String get restroomCategoryPark => '公園';

  @override
  String get moreLinkOpenFailed => 'リンクを開けませんでした';

  @override
  String get themeDark => 'ダーク';

  @override
  String get sponsorRestore => '購入を復元';

  @override
  String get meshtasticChannelWorking => 'DPIP チャンネルを設定中…';

  @override
  String get meshtasticRegionSwitch => 'TW 地域に切り替え';

  @override
  String get meshtasticTraffic => 'トラフィック';

  @override
  String get mapLayerStyleBdTooltip => 'Dvorak BD カーブ——熱帯低気圧の強度解析に使う階段グレースケール';

  @override
  String get disasterMapOverlayAedTooltip => 'AEDの位置を表示';

  @override
  String get mapLayerHumidity => '湿度';

  @override
  String get mapLayerSatelliteTransparentNight => '夜間 = 透明、地図が透ける';

  @override
  String get meshtasticScanning => 'スキャン中…';

  @override
  String regionSelectFull(int max) {
    return '地域は最大 $max 件まで登録できます';
  }

  @override
  String get meshtasticNewMessages => '新着';

  @override
  String get meshtasticBatteryHistory => 'バッテリー履歴';

  @override
  String get meshtasticStatAvg => '平均';

  @override
  String get meshtasticStatPeak => 'ピーク';

  @override
  String get meshtasticStatDrain => '消費';

  @override
  String get meshtasticStatEta => '残り目安';

  @override
  String get meshtasticStatFull => '満充電まで';

  @override
  String get meshtasticStatTrend => '傾向';

  @override
  String get meshtasticStatCharging => '充電中';

  @override
  String get meshtasticStatStable => '安定';

  @override
  String get meshtasticNodesTotal => '既知';

  @override
  String get meshtasticNodesOnline => 'オンライン';

  @override
  String get meshtasticRx => '受信';

  @override
  String get meshtasticTx => '送信';

  @override
  String get meshtasticNodesHistory => 'ノード数履歴';

  @override
  String get meshtasticTrafficHistory => 'トラフィック履歴';

  @override
  String meshtasticEtaHours(int n) {
    return '約$n時間';
  }

  @override
  String meshtasticEtaDays(int n) {
    return '約$n日';
  }

  @override
  String get meshtasticTitle => 'Meshtastic';

  @override
  String get navMore => 'その他';

  @override
  String get meshtasticDpipChannel => 'DPIP チャンネル';

  @override
  String get disasterMapOverlaySectionLayers => 'レイヤー';

  @override
  String get mapLayerSatelliteB05 => 'ひまわり 近赤外(B05)';

  @override
  String get typhoonLabelNe => '北東';

  @override
  String get meshtasticCopied => 'メッセージをコピーしました';

  @override
  String get reportListEmpty => '地震報告はありません';

  @override
  String get reportListEnd => 'これ以上ありません';

  @override
  String get mapLayerSatelliteTruecolor => 'ひまわり トゥルーカラー';

  @override
  String get typhoonOverlaySectionExtra => 'オーバーレイ';

  @override
  String get eewSWave => 'S波';

  @override
  String get meshtasticBusyTitle => '別のアプリがこの無線機を使用中です';

  @override
  String get restroomCategoryCultural => '文化・娯楽施設';

  @override
  String get typhoonLabelWind => '中心付近の最大風速';

  @override
  String get radarGlobalOutlineHint => '各国の国境外枠';

  @override
  String get notifyEvacuation => '防災情報';

  @override
  String get typhoonLegendCircle15 => '強風域（30kt）';

  @override
  String get dataSectionAstronomy => '天文';

  @override
  String get homeRainTrendLightSustained => '今後1時間は小雨が続きます';

  @override
  String get commonError => '問題が発生しました';

  @override
  String get moonPhaseWaningCrescent => '下弦の月';

  @override
  String get meshtasticPower => '電源';

  @override
  String get mapTimelineNow => '現在';

  @override
  String reportFilterRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String get reportDetailOpenReport => 'レポートページ';

  @override
  String get trendRange7d => '7日間';

  @override
  String typhoonWarningAreas(String areas) {
    return '対象地域：$areas';
  }

  @override
  String get rainIntervalSection => '集計時間';

  @override
  String get notifyTitle => '通知';

  @override
  String get meshtasticTxPower => 'TX 出力';

  @override
  String get restroomCategoryLabel => '区分';

  @override
  String get sponsorRestoring => '購入を復元しています…';

  @override
  String get sponsorIntro =>
      'DPIP はリアルタイムの防災情報の提供に取り組んでおり、広告やその他の収益モデルはありません。皆さまのご支援はサーバーの運用と継続的な開発に役立ちます。';

  @override
  String get typhoonLabelStormAvg => '暴風域の平均半径';

  @override
  String get restroomCategoryCommercial => '商業・営業施設';

  @override
  String get aedRegion => '地域';

  @override
  String homeRainTrendLightStopping(int minutes) {
    return '$minutes分後に小雨が止む見込みです';
  }

  @override
  String get reportDetailInfo => '詳細情報';

  @override
  String get mapNavWind => '風向';

  @override
  String get windForecastOverlayMenuTooltip => '風予報レイヤー設定';

  @override
  String homeRainTrendMinute(int minute) {
    return '$minute分';
  }

  @override
  String get rainInterval6h => '6時間';

  @override
  String get restroomTypeUnspecified => '未設定';

  @override
  String get typhoonOverlayProbabilityHint => '予報円を隠します';

  @override
  String get mapLayerSatelliteGlobalOutline => '国境線';

  @override
  String get mapNavTemperature => '気温';

  @override
  String get typhoonLegendForecastPoint => '予報点';

  @override
  String get reportListYesterday => '昨日';

  @override
  String get moreSectionLinks => '関連リンク';

  @override
  String get feedOffline => '接続が切断されました';

  @override
  String get mapLayerStyleBd => 'Dvorak BD';

  @override
  String get moreSectionDisplay => '表示';

  @override
  String get rainInterval3d => '3日';

  @override
  String get defaultMapLayerSubtitle =>
      '地図タブを開いたときに表示するレイヤーです。下部ナビのアイコンとラベルもこれに合わせます。';

  @override
  String get aedDescription => '備考';

  @override
  String get typhoonOverlayWeatherRadarTooltip => '通報時刻に最も近いレーダー';

  @override
  String get onboardingPermLocationDesc => 'あなたの所在地に合わせて警報を配信します。';

  @override
  String get mapLayerSatelliteB16 => 'ひまわり 二酸化炭素(B16)';

  @override
  String get homeActiveEventsEmpty => '発生中の事象はありません';

  @override
  String get typhoonLabelPosition => '中心位置';

  @override
  String get weatherRankingBy => '並び';

  @override
  String get typhoonIntensityMild => '弱い台風';

  @override
  String get windForecastGlobalOutlineHint => '各国の国境外枠';

  @override
  String get rainInterval1h => '1時間';

  @override
  String get eewLocalIntensity => '現在地の推定';

  @override
  String get mapLayerRadar => 'レーダー合成エコー図';

  @override
  String get restroomCategoryReligious => '宗教・礼拝施設';

  @override
  String get meshtasticRole => 'ロール';

  @override
  String get mapLayerSatelliteCloudCloudy => '雲';

  @override
  String get skyTimeSunrise => '日の出';

  @override
  String get meshtasticJumpToLatest => '最新へ移動';

  @override
  String get meshtasticNoMessages => 'まだメッセージがありません';

  @override
  String get onboardingPermNotifyDesc => '地震、天気、災害の発生時に、警報をすぐお届けします。';

  @override
  String get radarTownOutline => '市町村境界';

  @override
  String get mapLayerStyleSection => '色調';

  @override
  String get disasterMapOverlayMenuTooltip => '防災マップのレイヤー';

  @override
  String get moreGooglePlay => 'Google Play';

  @override
  String get meshtasticOnline => '最近受信あり';

  @override
  String get typhoonLabelSw => '南西';

  @override
  String typhoonForecastLead(String hours) {
    return '予報 +$hours 時間';
  }

  @override
  String get changelogTypeStable => '正式';

  @override
  String get mapLayerSatelliteTransparentClear => '晴れ = 透明、地図が透ける';

  @override
  String get mapOverlaySectionReference => '参照レイヤー';

  @override
  String get mapLayerSatelliteB02 => 'ひまわり 可視緑(B02)';

  @override
  String get weatherRankingEmpty => '並べ替え可能な観測がありません';

  @override
  String get notifySectionOther => 'その他';

  @override
  String weatherRankingMeta(String time, int count) {
    return 'データ時刻：$time\n観測点 $count';
  }

  @override
  String get onboardingTermsAgree => 'サービス利用規約を読み、同意します';

  @override
  String get mapLayerSatelliteTransparentNoVegetation => '< 0.1 = 透明(植生なし)';

  @override
  String get notifyOptLocalIntensity4 => '所在地の震度4以上';

  @override
  String get eewArrived => '到達';

  @override
  String get meshtasticNoDevices => 'Meshtastic デバイスが見つかりません';

  @override
  String get mapLayerCategoryLife => '生活';

  @override
  String get reportFilterSortIntensity => '震度';

  @override
  String get meshtasticStateDisconnected => '切断済み';

  @override
  String get typhoonIntensityIntense => '強い台風';

  @override
  String get mapLayerOrderTitle => 'レイヤーの順番';

  @override
  String get mapLayerShow => 'レイヤーを表示';

  @override
  String get mapLayerHide => 'レイヤーを非表示';

  @override
  String get mapLayerShowAll => 'すべて表示';

  @override
  String get mapLayerHideAll => 'すべて非表示';

  @override
  String get dpmYes => 'はい';

  @override
  String get meshtasticNoHistory => '履歴がまだ足りません';

  @override
  String get reportDetailLocalIntensityUnavailable => '震度情報なし';

  @override
  String get mapLayerWindForecastGfs => 'GFS';

  @override
  String get reportFilterDepth => '深さ';

  @override
  String get onboardingScrollHint => '下にスクロールして続行してください';

  @override
  String get mapNavQpesums => '予報';

  @override
  String get notifyAdvisory => '気象警報・注意報';

  @override
  String get reportFilterReset => 'リセット';

  @override
  String get mapLayerSatelliteMndwi => 'ひまわり MNDWI';

  @override
  String get typhoonOverlaySectionStorm => '暴風域';

  @override
  String get moonPhaseFull => '満月';

  @override
  String meshtasticBinaryPayload(String size) {
    return 'バイナリデータ · $size';
  }

  @override
  String get moonPhaseWaningGibbous => '下弦の月(虧)';

  @override
  String get reportFilterIntensityInfoModernTitle => '新制（2020 年以降）';

  @override
  String typhoonDataTime(String time) {
    return '資料時刻\n$time';
  }

  @override
  String get restroomTypeAccessible => 'バリアフリートイレ';

  @override
  String get moreSectionAbout => '情報';

  @override
  String get meshtasticSelectDevice => '無線機を選択';

  @override
  String get onboardingIntroBody =>
      'DPIP はあなたと共にある防災パートナーです。緊急地震速報、地震報告、天気、各種災害情報を統合し、重要な瞬間にすぐお知らせします。\n\n• 地震:緊急地震速報、震度速報、地震報告\n• 天気:雷雨即時情報、気象警報・注意報\n• 津波・防災情報\n\n次に、サービス利用規約をご確認いただき、DPIP がリアルタイムであなたを守れるよう、いくつかの権限の許可をお願いします。';

  @override
  String get shelterCapacityLabel => '収容人数';

  @override
  String get reportDetailImage => '地震レポート画像';

  @override
  String get meshtasticStateConfiguring => '設定中…';

  @override
  String get typhoonLabelGaleAvg => '強風域の平均半径';

  @override
  String get onboardingPermNotify => '通知';

  @override
  String get meshtasticClearMessages => 'メッセージを消去';

  @override
  String get meshtasticNotifyMessages => '新しいメッセージで通知';

  @override
  String get defaultMapLayerSettings => '地図の初期レイヤー';

  @override
  String get eewSourceSettings => '緊急地震速報の情報源';

  @override
  String get eewSourceSubtitle => '表示する緊急地震速報の発表機関を選択します。';

  @override
  String get eewSourceAll => 'すべての情報源';

  @override
  String get eewSourceAllDescription => 'すべての発表機関の緊急地震速報を表示します。';

  @override
  String get eewSourceCwaOnly => '中央気象署のみ';

  @override
  String get eewSourceCwaOnlyDescription => '台湾中央気象署（CWA）が発表した緊急地震速報のみを表示します。';

  @override
  String get moreSectionNotify => '通知';

  @override
  String get notifyUnavailable => 'プッシュ通知はまだ準備できていません。しばらくしてから再度お試しください。';

  @override
  String get mapLayerOrderReset => '既定の順序に戻す';

  @override
  String get weatherRankingMergeCounty => '県市';

  @override
  String get moreSectionApp => 'アプリを入手';

  @override
  String get moreSectionBeta => 'テスト版';

  @override
  String get moreAndroidBeta => 'Android テスト版';

  @override
  String get moreTestFlight => 'iOS テスト版（TestFlight）';

  @override
  String get moreSectionPartners => 'パートナー';

  @override
  String get morePartnersNote =>
      '提携順に表示しています。防災への貢献で DPIP を支えてくださった個人・企業の皆様に感謝します。';

  @override
  String get morePartnerGeoscience => 'Geoscience';

  @override
  String get morePartnerTwds => 'TWDS';

  @override
  String get reportFilterIntensityInfoLegacyBody =>
      '震度は 0–7 のみ。5弱／5強／6弱／6強の区分はありません。';

  @override
  String get mapLayerSatelliteSst => 'ひまわり 海面水温';

  @override
  String get qpesumsOverlayMenuTooltip => '定量降水予報レイヤー設定';

  @override
  String get mapTimelineFuture => '未来';

  @override
  String get typhoonLegendCircleAvg => '平均円';

  @override
  String reportFilterDepthKm(String depth) {
    return '$depth km';
  }

  @override
  String get typhoonLabelSe => '南東';

  @override
  String get radarTownOutlineHint => 'より細かい区分';

  @override
  String eewCountdown(int seconds) {
    return 'あと $seconds 秒';
  }

  @override
  String get typhoonLabelGust => '最大瞬間風速';

  @override
  String get mapAppGoogleMaps => 'Google Maps';

  @override
  String get sponsorTerms => '利用規約';

  @override
  String get restroomTypeGenderNeutral => 'ジェンダーニュートラルトイレ';

  @override
  String get notifyThunderstorm => '雷雨情報';

  @override
  String get skyTimeGolden => 'ゴールデンアワー';

  @override
  String get moonAge => '月齢';

  @override
  String get meshtasticRadioSettings => 'LoRa';

  @override
  String get moreGithub => 'ExpTech GitHub';

  @override
  String get homeForecastUnavailable => '地域を選ぶと予報を表示します';

  @override
  String get mapLayers => 'レイヤー';

  @override
  String get meshtasticHardware => 'ハードウェア';

  @override
  String get languageSettings => '言語設定';

  @override
  String get language => '言語';

  @override
  String homeForecastFeelsLike(String temp) {
    return '体感 $temp°';
  }

  @override
  String get typhoonOverlayWeatherHint => '通報時刻に合わせる';

  @override
  String get skyTimeDawn => '夜明け前';

  @override
  String get skyTimeAfternoon => '午後';

  @override
  String get meshtasticLastHeard => '最終受信';

  @override
  String get typhoonWarningTitle => '台風警報';

  @override
  String get moreSourceCode => 'ソースコード';

  @override
  String get mapLayerCategoryWeather => '気象観測';

  @override
  String get mapLayerSatelliteB09 => 'ひまわり 中層水蒸気(B09)';

  @override
  String get windForecastTownOutlineHint => 'より細かいメッシュ';

  @override
  String get mapLayerSatelliteCloudmask => 'ひまわり 雲マスク';

  @override
  String get mapAppCopyCoordinates => '座標をコピー';

  @override
  String get reportFilterIntensityInfoIntro =>
      '気象署は 2020 年 1 月 1 日（台北時間）から新制震度を採用しています。';

  @override
  String get mapNavEarthquake => '地震';

  @override
  String get restroomGradeAverage => '普通';

  @override
  String get mapLayerSatelliteBtdCo2 => 'ひまわり 巻雲/雲頂高度';

  @override
  String get onboardingPermBackgroundDesc =>
      '「常に許可」を選択すると、アプリを閉じていても所在地に合わせて警報を配信できます。';

  @override
  String get mapTimelineForecast => '予報';

  @override
  String get restroomTypeLabel => '種別';

  @override
  String get navEarthquake => '地震';

  @override
  String get typhoonOverlayStormL10Tooltip => '暴風域 + 平均円（黄）';

  @override
  String get moonPhaseWaxingGibbous => '上弦の月(盈)';

  @override
  String get reportDetailTitle => '地震レポート';

  @override
  String get moreTremReport => 'TREM 検知レポート';

  @override
  String weatherDataTime(String station, String time) {
    return '$station · データ時刻 $time';
  }

  @override
  String get meshtasticNoNodes => 'まだノードを検出していません';

  @override
  String get meshtasticViaMqtt => 'MQTT 経由(インターネット)';

  @override
  String get radarCountyOutline => '県市境界';

  @override
  String get commonClose => '閉じる';

  @override
  String get restroomGradeLabel => '等級';

  @override
  String get rainIntervalNow => '今日';

  @override
  String get changelogCurrentVersion => '現行';

  @override
  String get typhoonLabelPressure => '中心気圧';

  @override
  String get typhoonOverlayForecastCalloutsTooltip => '拡大時に予報点の詳細カードを表示';

  @override
  String get aedOpenRemark => '開館時間メモ';

  @override
  String get onboardingPermsBody =>
      '災害が発生した瞬間に DPIP がお知らせできるよう、以下の権限を許可してください。これらはシステム設定でいつでも変更できます。';

  @override
  String get typhoonOverlaySectionWeather => '天気下敷き';

  @override
  String get notifyOptWeatherLocal => '現在地のみ';

  @override
  String get mapNavRain => '雨量';

  @override
  String get moonDays => '日';

  @override
  String mapLegendUnit(String unit) {
    return '単位：$unit';
  }

  @override
  String get weatherModeClear => '晴れ';

  @override
  String get meshtasticRadio => '無線機';

  @override
  String get commonEmpty => '表示する項目がありません';

  @override
  String get mapLayerSatelliteB01 => 'ひまわり 可視青(B01)';

  @override
  String get meshtasticExternalPower => '外部電源';

  @override
  String get moonPhaseLastQuarter => '下弦';

  @override
  String get reportFilterOrderAsc => '昇順';

  @override
  String get reportFilterApply => '適用';

  @override
  String get reportDetailImageUnavailable => 'レポート画像はまだありません';

  @override
  String get weatherRankingHighest => '最高';

  @override
  String get reportDetailReplay => 'リプレイ';

  @override
  String get mapLayerRestroom => 'トイレ';

  @override
  String get restroomCategoryWelfare => '社会福祉施設・集会所';

  @override
  String get restroomGradeExcellent => '最上級';

  @override
  String get meshtasticLastSent => '最終送信';

  @override
  String get meshtasticName => '名前';

  @override
  String get meshtasticScan => 'スキャン';

  @override
  String get mapLayerCategoryForecast => '数値予報';

  @override
  String get meshtasticChannelFailed => 'DPIP チャンネルの設定に失敗しました';

  @override
  String get themeSystem => 'システム';

  @override
  String get mapLayerSatelliteNdvi => 'ひまわり NDVI';

  @override
  String get typhoonLegendForecast => '予報経路';

  @override
  String typhoonValueHpa(String n) {
    return '$n hPa';
  }

  @override
  String get weatherPrecipitation => '降水量';

  @override
  String get moonNextFullMoon => '次の満月';

  @override
  String get dpmSheetEmpty => '地図上のマーカーをタップして詳細を表示';

  @override
  String get onboardingSkipLeave => 'このままスキップ';

  @override
  String get aedPlaceDesc => '設置場所';

  @override
  String get onboardingSkipTitle => '権限が許可されていません';

  @override
  String get restroomTypeFamily => '親子トイレ';

  @override
  String typhoonValueKm(String n) {
    return '$n km';
  }

  @override
  String get onboardingPermBattery => 'バッテリー最適化の除外';

  @override
  String get typhoonLabelNw => '北西';

  @override
  String get moonPhaseWaxingCrescent => '上弦';

  @override
  String get restroomCategoryLeisure => 'レジャー・娯楽施設';

  @override
  String get mapLayerTemperature => '気温';

  @override
  String get aedCategory => '分類';

  @override
  String get meshtasticChannels => 'チャンネル';

  @override
  String get monitorWaiting => 'データ待機中…';

  @override
  String get typhoonOverlayForecastCallouts => '予報点の情報';

  @override
  String get reportDetailEpicenter => '震央座標';

  @override
  String get meshtasticVoltage => '電圧';

  @override
  String get mapLayerMeshtasticSubtitle => '無線機で受信した LoRa メッシュノード';

  @override
  String get mapLayerWind => '風向';

  @override
  String get reportDetailMagnitude => '地震規模';

  @override
  String get reportDetailAreaIntensity => '地域別震度';

  @override
  String get rainInterval12h => '12時間';

  @override
  String reportListMagnitude(String magnitude) {
    return 'M$magnitude';
  }

  @override
  String get notifyMonitor => '強震モニタ';

  @override
  String get onboardingStart => 'はじめる';

  @override
  String sponsorPerMonth(String price) {
    return '$price / 月';
  }

  @override
  String get mapLayerPressure => '気圧';

  @override
  String get mapLayerSatelliteB04 => 'ひまわり 近赤外(B04)';

  @override
  String get mapLayerSatelliteTransparentZero => '差ゼロ = 透明(信号なし)';

  @override
  String get shelterIndoorLabel => '屋内収容';

  @override
  String get notifyOptOff => 'オフ';

  @override
  String get reportFilterSortTime => '時間';

  @override
  String get mapLayerSatelliteCloudProbablyClear => 'おそらく晴れ';

  @override
  String get weatherModeThunderstorm => '雷雨';

  @override
  String get homeViewOnMap => '地図で見る';

  @override
  String get reportFilterIntensityInfoLegacyTitle => '旧制（2020 年より前）';

  @override
  String get typhoonLabelSpeed => 'これまでの移動速度';

  @override
  String mapAppOpenFailed(String app) {
    return '$app を開けませんでした';
  }

  @override
  String get mapLayerSatelliteRgbComposite => 'RGB 合成(JMA レシピ)';

  @override
  String get meshtasticReceived => '受信';

  @override
  String get weatherRankingExtremeLow => '今日の最低';

  @override
  String get mapLayerSatelliteB10 => 'ひまわり 下層水蒸気(B10)';

  @override
  String get mapLayerSatelliteCloudProbablyCloudy => 'おそらく雲';

  @override
  String get mapLayerSatelliteTransparentNoWater => '≤ 0 = 透明(水域なし)';

  @override
  String get shelterCategoryLabel => '対象災害';

  @override
  String get meshtasticStateConnecting => '接続中…';

  @override
  String get moonTitle => '月';

  @override
  String get weatherRankingGust => '突風';

  @override
  String get moreAppStore => 'App Store';

  @override
  String get moreServerStatus => 'サーバー状態';

  @override
  String get notifySectionWeather => '天気';

  @override
  String get meshtasticPreset => 'モデムプリセット';

  @override
  String get dataSectionSeismic => '地震';

  @override
  String get changelogBodyEmpty => 'このリリースの説明はありません。';

  @override
  String get changelogOpenOnGitHub => 'GitHub で見る';

  @override
  String get radarGlobalOutline => '国境線';

  @override
  String get notifyEew => '緊急地震速報';

  @override
  String get regionNationwide => '全国';

  @override
  String get moreNotifyLog => 'DPIP 通知送信履歴';

  @override
  String get regionCurrent => '現在地';

  @override
  String get meshtasticNotConnected => '無線機に接続されていません';

  @override
  String get weatherModeSnow => '雪';

  @override
  String get mapLayerMeshtastic => 'Meshtastic ノード';

  @override
  String get moreDeveloper => 'デバッグ情報';

  @override
  String get mapLayerSatelliteB14 => 'ひまわり 長波長赤外線(B14)';

  @override
  String get meshtasticChannelUse => 'チャンネル使用率';

  @override
  String get mapNavLightning => '稲妻';

  @override
  String get homeForecastEmpty => '予報データがありません';

  @override
  String get sponsorOneTime => '一回限りの支援';

  @override
  String get mapLayerSatelliteBtdSplit => 'ひまわり スプリットウィンドウ';

  @override
  String get onboardingPermBackground => 'バックグラウンドの位置情報';

  @override
  String get aedEmergencyPhone => '緊急連絡先';

  @override
  String get dpmOpenInMaps => '地図アプリで開く';

  @override
  String get meshtasticNotifyNodes => '新しいノードで通知';

  @override
  String get onboardingPermCriticalDesc =>
      '生命に関わる緊急地震速報を、消音モードやおやすみモードでも鳴らせるようにします。';

  @override
  String get mapLayerSatelliteTransparentWarm => '晴れ(暖域) = 透明、地図が透ける';

  @override
  String get meshtasticSent => '送信済み';

  @override
  String get homeForecastTitle => '24時間予報';

  @override
  String get typhoonLegendWarningAreas => '警報区域';

  @override
  String meshtasticExcludeMqttHidden(int count) {
    return '$count 件を非表示';
  }

  @override
  String get notifyOptLocalIntensity1 => '所在地の震度1以上';

  @override
  String get mapTimelinePast => '過去';

  @override
  String get restroomTypeFemale => '女性用トイレ';

  @override
  String get reportListToday => '今日';

  @override
  String get meshtasticTapNode => 'ノードをタップして詳細を表示';

  @override
  String get commonLoading => '読み込み中…';

  @override
  String get typhoonIntensityModerate => '並の台風';

  @override
  String get mapLayerSatelliteAsh => 'ひまわり 火山灰';

  @override
  String get rainInterval3h => '3時間';

  @override
  String get mapLayerCategorySatellite => '衛星';

  @override
  String get meshtasticChannelReady => 'DPIP チャンネルの準備ができました';

  @override
  String get mapLayerSatelliteNightmicrophysics => 'ひまわり 夜間微物理';

  @override
  String get typhoonIntensityTd => '熱帯低気圧';

  @override
  String get reportFilterDate => '日付';

  @override
  String get sponsorRestoreUnavailable => 'ストアに接続できません。しばらくしてからもう一度お試しください。';

  @override
  String homeForecastPop(String pop) {
    return '$pop%';
  }

  @override
  String get regionEmpty => '登録地域がありません';

  @override
  String get onboardingPermBatteryDesc =>
      'DPIP がバックグラウンドで動作し続けられるようにして、警報の遅延や取りこぼしを防ぎます。';

  @override
  String get mapNavDisaster => '防災';

  @override
  String get radarScanRangeSubtitle => '4基のレーダーが実際に観測する範囲を示します。';

  @override
  String get aedHoursSunday => '日曜の開館時間';

  @override
  String get reportDetailOriginTime => '発震時刻';

  @override
  String get trendNoData => 'トレンドデータがありません';

  @override
  String get onboardingPermLocation => '位置情報';

  @override
  String get moreDiscord => 'Discord コミュニティ';

  @override
  String get mapNavPressure => '気圧';

  @override
  String get mapLayerSatelliteB13 => 'ひまわり 赤外線(B13)';

  @override
  String typhoonTdNo(String no) {
    return 'TD $no';
  }

  @override
  String get changelogEmpty => 'リリースノートはまだありません';

  @override
  String get reportFilterDateStartNote => '開始日：当日 00:00（台北時間）';

  @override
  String get eewTitle => '緊急地震速報';

  @override
  String get mapLayerWindForecastEcmwf => 'ECMWF';

  @override
  String regionSelectCount(int count, int max) {
    return '$count/$max 件選択中';
  }

  @override
  String get mapLayerSatelliteBtdSo2 => 'ひまわり 二酸化硫黄/雲相';

  @override
  String get meshtasticStateError => 'エラー';

  @override
  String get weatherModeOvercast => '本曇り';

  @override
  String get reportDetailDepth => '震源の深さ';

  @override
  String get typhoonOverlayWarningTooltip => '台風警報対象の県を強調';

  @override
  String get reportFilterDatePick => '日付を選択';

  @override
  String get onboardingSkipStay => '戻って許可';

  @override
  String get commonFetchFailed => 'データを取得できませんでした。しばらくしてから再度お試しください。';

  @override
  String get shelterOutdoorLabel => '屋外収容';

  @override
  String get meshtasticStateConnected => '接続済み';

  @override
  String get mapNavRadar => 'レーダー';

  @override
  String get mapLayerSatelliteCloudClear => '晴れ';

  @override
  String eewSummary(String magnitude, String depth) {
    return 'M$magnitude・深さ $depth km';
  }

  @override
  String get locationBannerPermission => '位置情報の許可がオフです。所在地に合わせた警報を配信できません。';

  @override
  String get typhoonOverlayWeatherNoneTooltip => 'レーダー／赤外線なし';

  @override
  String get radarCountyOutlineHint => 'エコーの上に描画';

  @override
  String get windForecastCountyOutlineHint => '風場の上に描画';

  @override
  String get homeRainTrendTitle => '今後1時間の雨';

  @override
  String get moonPhaseFirstQuarter => '上弦の月';

  @override
  String get mapLayerCategoryTyphoon => '台風';

  @override
  String get meshtasticUtilization => 'エアタイム(24h)';

  @override
  String get restroomTypeMixed => '男女共用トイレ';

  @override
  String get restroomGradeGood => '優良';

  @override
  String get notifyTsunami => '津波情報';

  @override
  String get navData => 'データ';

  @override
  String get mapLayerSatelliteBtdWvirw => 'ひまわり オーバーシューティングトップ';

  @override
  String get meshtasticReadingAge => '計測時刻';

  @override
  String get mapAppCallFailed => 'この端末では通話できません';

  @override
  String get reportFilterAny => '指定なし';

  @override
  String get weatherRankingMergeTo => '統合';

  @override
  String get notifyIntensity => '震度速報';

  @override
  String get rainIntervalMenu => '累積期間';

  @override
  String get reportDetailLocalFelt => '局地的な有感地震';

  @override
  String get meshtasticDevice => 'デバイス';

  @override
  String get onboardingGrant => '許可';

  @override
  String get weatherModeRain => '雨';

  @override
  String get shelterVulnerableOkLabel => '要配慮者向け収容';

  @override
  String get stationSheetEmpty => '観測点をタップして値を表示';

  @override
  String get typhoonLegendProbability => '接近確率';

  @override
  String get reportFilterMagnitude => 'マグニチュード';

  @override
  String get skyTimeMorning => '午前';

  @override
  String get experimentalFeatures => '実験的機能';

  @override
  String get onboardingTermsBody =>
      'DPIP をご利用になる前に、以下の注意事項を必ずお読みください:\n\n• すべての情報は、台湾中央気象署(CWA)が発表する内容を優先してください。\n\n• ネットワーク、サーバー、アプリ、上流のデータソースの状態によっては、情報を受信できない場合があります。可能な限り回避に努めますが、決して発生しないことを保証するものではありません。\n\n• 強い揺れが、通知より先にあなたの所在地へ到達する場合があります。\n\n• 緊急地震速報は高速に計算された結果であり、大きな誤差を含む可能性があります。この点を理解したうえで、慎重にご利用ください。\n\n• 公的機関に認められていない行為には法的リスクが伴う可能性があります。関連する規定を必ずお守りください。\n\nまた、地域に応じた警報を提供するため、本サービスは、どの警報をあなたに送信するかを判断する目的にのみ、あなたのおおよその位置情報とプッシュ識別子を、フォアグラウンドおよびバックグラウンドで収集・アップロードします。\n\n下部の「同意して続行」をタップすることで、上記を読み、理解し、同意したものとみなされます。';

  @override
  String get reportFilterTitle => '絞り込み';

  @override
  String get onboardingPermCritical => '重大な通知';

  @override
  String trendCumulativeTotal(String total) {
    return '累計 $total mm';
  }

  @override
  String get languageName => '日本語';

  @override
  String get reportListEmptyFiltered => '条件に一致する地震報告はありません';

  @override
  String get meshtasticExcludeMqtt => 'MQTT ノードを隠す';

  @override
  String get mapNavTyphoon => '台風';

  @override
  String get weatherModeSand => '砂じん';

  @override
  String get notifyReport => '地震報告';

  @override
  String get mapAppCoordinatesCopied => '座標をコピーしました';

  @override
  String get skyTimeNight => '夜';

  @override
  String get sponsorRecommended => 'おすすめ';

  @override
  String get mapLayerSatelliteB15 => 'ひまわり 長波長赤外線(B15)';

  @override
  String get weatherRankingWind => '風速';

  @override
  String get feedStale => 'データが最新でない可能性があります';

  @override
  String homeForecastWind(String direction, String level) {
    return '$direction · 風力$level';
  }

  @override
  String get navHome => 'ホーム';

  @override
  String get meshtasticRegionLabel => '地域';

  @override
  String get mapLayerSatelliteCloudtop => 'ひまわり 雲頂温度';

  @override
  String get moonTimelineCaption => '月相';

  @override
  String get openSourceLicenses => 'オープンソースライセンス';

  @override
  String get weatherRankingLowest => '最低';

  @override
  String get reportFilterSortDepth => '深さ';

  @override
  String mapTimelineDataTime(String time) {
    return 'データ時刻 $time';
  }

  @override
  String get radarScanRange => '走査範囲を表示';

  @override
  String get meshtasticHopLimit => 'ホップ数上限';

  @override
  String get weatherRankingExtremeHigh => '今日の最高';

  @override
  String get sponsorPrivacy => 'プライバシーポリシー';

  @override
  String get reportDetailLocalIntensity => '現在地の震度';

  @override
  String get mapLayerSatelliteNaturalcolor => 'ひまわり ナチュラルカラー';

  @override
  String get meshtasticAirtime => 'エアタイム(TX)';

  @override
  String shelterCapacityValue(int n) {
    return '$n 人';
  }

  @override
  String lightningLegendCc(int minutes) {
    return '雲間 · $minutes 分以内';
  }

  @override
  String get meshtasticSendHint => '送信するメッセージ';

  @override
  String monitorDelay(String value) {
    return '遅延 $value s';
  }

  @override
  String get dpmNo => 'いいえ';

  @override
  String get mapLayerSatelliteB08 => 'ひまわり 上層水蒸気(B08)';

  @override
  String get meshtasticReconnecting => '再接続中…';

  @override
  String get radarTownOutlineSubtitle => 'レーダーエコーの下でも市町村境界が見えるようにします。';

  @override
  String get typhoonOverlayWeatherSatelliteTooltip => '通報時刻に最も近い赤外線';

  @override
  String get radarScanRangeHint => '枠外の空白は未観測';

  @override
  String typhoonPickerTd(String no) {
    return '熱帯低気圧 TD $no';
  }

  @override
  String get mapLayerSatelliteWatervapor => 'ひまわり 水蒸気';

  @override
  String get regionAddButton => '地域を追加';

  @override
  String get regionSearchHint => '都道府県・市区を検索';

  @override
  String get regionSearchEmpty => '一致する地域がありません';

  @override
  String get regionSearchTownHint => '町村を検索';

  @override
  String get regionSearchTownEmpty => '該当する町村がありません';

  @override
  String get displaySettings => '表示';

  @override
  String get restroomGradePoor => '不合格';

  @override
  String get restroomCategoryTourist => '観光地・景勝地';

  @override
  String get locationBannerServiceOff => '位置情報サービスがオフです。所在地に合わせた警報を配信できません。';

  @override
  String get mapLayerStyleTooltip => '色調';

  @override
  String lightningLegendCg(int minutes) {
    return '対地 · $minutes 分以内';
  }

  @override
  String get skyTimeAuto => '自動';

  @override
  String get appLogs => 'アプリログ';

  @override
  String get serverStatusLocal => 'デバイスの状態';

  @override
  String get serverStatusLocalBody =>
      'サーバー指標はダッシュボードからのものです。以下は本機のマルチアクティブエンドポイント（LB / Core 各リージョン）への実際の接続判断です：本機が実際に送受信したトラフィックだけを受動的に記録するため、まだ触れていないエンドポイントは「未探知」と表示されます。';

  @override
  String get serverStatusAllUp => 'すべて正常';

  @override
  String get serverStatusDegraded => 'パフォーマンス低下';

  @override
  String get serverStatusDown => 'サービス異常';

  @override
  String get serverStatusErrorRate => '5xx エラー率';

  @override
  String get serverStatusLatency => '平均遅延';

  @override
  String get serverStatusUpdated => '更新';

  @override
  String get serverStatusWeb => 'サーバー状態';

  @override
  String get serverStatusWebUrl => 'status.exptech.dev';

  @override
  String get serverStatusExpTech => 'ExpTech ステータス';

  @override
  String get serverStatusCloudflare => 'Cloudflare ステータス';

  @override
  String get serverStatusCloudflareAllOperational => '全リージョン正常';

  @override
  String get serverStatusCloudflareOutage => 'Cloudflare の一部リージョンで異常';

  @override
  String get serverStatusCloudflareNone => '表示できるリージョンがありません。';

  @override
  String get serverStatusCloudflareOperational => '正常';

  @override
  String get serverStatusCloudflareDegraded => '性能低下';

  @override
  String get serverStatusCloudflarePartial => '部分停止';

  @override
  String get serverStatusCloudflareMajor => '大規模停止';

  @override
  String get serverStatusCloudflareUnknown => '不明';

  @override
  String get endpointTierLbApi => 'LB API';

  @override
  String get endpointTierLbStatic => 'LB Static';

  @override
  String get endpointTierCoreApi => 'Core API';

  @override
  String get endpointTierCoreStatic => 'Core Static';

  @override
  String get endpointTierCoreExclusiveApi => 'Core 専用 API（レーダー / 気象 / 風）';

  @override
  String get endpointTierCoreStaticExclusive => 'Core 専用静的リソース';

  @override
  String get endpointTierLegacyApi => 'レガシー API（api-1）';

  @override
  String get endpointHealthOk => '接続正常';

  @override
  String get endpointHealthDegraded => '不安定なエンドポイントあり';

  @override
  String get endpointHealthDown => '接続異常';

  @override
  String get endpointHealthUnknown => '観測データなし';

  @override
  String get endpointStateOk => '正常';

  @override
  String get endpointStateDegraded => '不安定';

  @override
  String get endpointStateDown => '異常';

  @override
  String get endpointStateUnknown => '不明';

  @override
  String get endpointServiceEew => 'EEW';

  @override
  String get endpointServiceRts => 'RTS';

  @override
  String get endpointServiceRadar => 'レーダー';

  @override
  String get endpointServiceSatellite => '衛星画像';

  @override
  String get endpointServiceQpesums => 'QPE';

  @override
  String get endpointServiceWind => '風';

  @override
  String get endpointServiceDpm => '災害地点';

  @override
  String get endpointServiceWeather => '天気';

  @override
  String get endpointServiceRain => '雨';

  @override
  String get endpointServiceLightning => '雷';

  @override
  String get endpointServiceTyphoon => '台風';

  @override
  String get endpointServiceReport => '地震報告';

  @override
  String get endpointServiceTremStation => '震度計';

  @override
  String get endpointServiceEvent => 'イベント';

  @override
  String get endpointServiceLocation => '位置情報';

  @override
  String get endpointServiceNotify => '通知';

  @override
  String get endpointServiceOther => 'その他';

  @override
  String get feedConnecting => '接続中…';

  @override
  String get notifyBannerDisabled => '通知がオフです — 災害警報を受け取れません。';

  @override
  String get weatherHumidity => '湿度';

  @override
  String typhoonValueMs(String n) {
    return '毎秒 $n m';
  }

  @override
  String homeForecastHumidity(String value) {
    return '湿度 $value%';
  }

  @override
  String get meshtasticBusyBody =>
      '先に別の Meshtastic アプリで無線機を切断してください。1 台の無線機を 2 つのアプリで使うと互いのメッセージを奪い合い、一部が失われます。';

  @override
  String get meshtasticChannelNoSlot => '空きチャンネルがありません — 無線機で1つ空けてください';

  @override
  String get restroomCategoryTransport => '交通';

  @override
  String get meshtasticBattery => 'バッテリー';

  @override
  String get meshtasticDistance => '距離';

  @override
  String get meshtasticSnrTrend => '信号トレンド (SNR)';

  @override
  String get meshtasticBatteryTrend => 'バッテリー推移';

  @override
  String get typhoonOverlayMenuTooltip => '台風オーバーレイ設定';

  @override
  String get mapLayerSatelliteBtdOzone => 'ひまわり 対流圏界面';

  @override
  String meshtasticRegionMismatch(String region) {
    return '無線機の地域は $region です — DPIP は TW が必要です';
  }

  @override
  String get notifySectionEarthquake => '地震';

  @override
  String get mapLayerDisasterMap => '防災マップ';

  @override
  String get weatherModeFog => '霧';

  @override
  String typhoonPickerNamed(String no, String name) {
    return '$name TY $no';
  }

  @override
  String get mapLayerStyleGrayTooltip => '気象庁の赤外画像の慣例：温度が低いほど白';

  @override
  String get moreAnnouncements => 'お知らせ';

  @override
  String get moreTagline => '防災情報統合プラットフォーム';

  @override
  String get moreVersionStable => '正式版';

  @override
  String get moreVersionNotes => '今回の更新';

  @override
  String get moreVersionNotesHighlightsSubtitle => 'このバージョンでの変更点';

  @override
  String releaseHighlightsTitle(Object train) {
    return '$train まとめ';
  }

  @override
  String get releaseHighlightsTabNormal => '変更点';

  @override
  String get releaseHighlightsTabAdvanced => '技術詳細';

  @override
  String get releaseHighlightsEmpty => 'まだコンテンツがありません。';

  @override
  String get releaseHighlightsSeeNotes => '完全なリリースノート';

  @override
  String get moreVersionNotesEmpty => 'このビルドの更新履歴が見つかりません';

  @override
  String get reportNotFound => 'この地震報告は見つかりませんでした';

  @override
  String get moreVersionSnapshot => 'テスト版';

  @override
  String get mapLayerSatelliteTransparentNoData => 'データなし(陸上) = 透明';

  @override
  String get restroomCategoryGovernment => '行政サービス施設';

  @override
  String get typhoonLegendCurrent => '現在中心';

  @override
  String get aedAddress => '住所';

  @override
  String get mapLayerAed => 'AED';

  @override
  String get changelogTypePrerelease => 'ベータ';

  @override
  String get reportFilterIntensityInfoModernBody =>
      '震度は 0–4、5弱、5強、6弱、6強、7。フィルタは新制に準拠し、それ以前の地震はリストで旧制表記になります。';

  @override
  String get typhoonOverlayWeatherNone => 'なし';

  @override
  String get mapLayerStyleGray => 'グレースケール（JMA）';

  @override
  String get weatherModeAuto => '自動';

  @override
  String get typhoonLabelProbCircle => '70%確率円';

  @override
  String get notifyOptAll => 'すべて受信';

  @override
  String get displayTheme => 'テーマ';

  @override
  String get mapLayerSatelliteB07 => 'ひまわり 短波長赤外(B07)';

  @override
  String get typhoonLabelDirection => 'これまでの進行方向';

  @override
  String get regionManageTitle => '登録地域';

  @override
  String get regionSaveNote =>
      '通知は GPS で取得した現在地に基づいて送信されます。よく使う地域を設定しても通知の送信先は変わりません。よく使う地域はホーム画面で各エリアの状況をすぐ確認するためのもので、通知を機能させるには位置情報の許可が必須です。';

  @override
  String get typhoonLegendCone => '予報円';

  @override
  String get moreCwaEew => '中央気象署 緊急地震速報';

  @override
  String get onboardingPermsTitle => '権限の許可';

  @override
  String get mapLayerStyleJma => '雲頂強調（JMA）';

  @override
  String get rainInterval10m => '10分';

  @override
  String get meshtasticConnectAnyway => '接続する';

  @override
  String reportListDayCount(int count) {
    return '$count';
  }

  @override
  String get mapLayerSatelliteB06 => 'ひまわり 近赤外(B06)';

  @override
  String get mapLayerSatelliteTransparentReflectance => '低反射率・夜間 = 透明、地図が透ける';

  @override
  String chartHourLabel(int hour) {
    return '$hour時';
  }

  @override
  String get mapLayerShelter => '避難所';

  @override
  String get typhoonOverlayProbabilityTooltip => '接近確率を表示（予報円を隠す）';

  @override
  String get mapLayerSatelliteNdwi => 'ひまわり NDWI';

  @override
  String get disasterMapOverlayShelterTooltip => '避難所を表示';

  @override
  String get mapNavHumidity => '湿度';

  @override
  String get reportDetailSortByIntensity => '震度順に並べ替え';

  @override
  String get homeRainTrendNoData => 'データなし';

  @override
  String get mapLayerCategoryRadar => 'レーダー';

  @override
  String get meshtasticShortName => '短縮名';

  @override
  String get mapLayerSatelliteAirmass => 'ひまわり エアマス';

  @override
  String get dataSectionWeather => '気象';

  @override
  String get aedHoursWeekday => '平日の開館時間';

  @override
  String get homeActiveEventsTitle => '発生中の事象';

  @override
  String get faq => 'よくある質問';

  @override
  String eewSerial(int serial) {
    return '第 $serial 報';
  }

  @override
  String get reportFilterSort => '並び替え';

  @override
  String get meshtasticRegionConfirm =>
      'この無線機を TW 地域に切り替えますか?再起動して一時的に切断され、他のチャンネルも移動します。';

  @override
  String get dataEarthquakeSubtitle => '地震報告';

  @override
  String get typhoonNoActive => '発生中の台風なし';

  @override
  String get mapLayerSatelliteB11 => 'ひまわり 二酸化硫黄/雲相(B11)';

  @override
  String get navEvents => 'イベント';

  @override
  String get onboardingTermsTitle => 'サービス利用規約';

  @override
  String get mapOsmOverlay => '詳細地図';

  @override
  String get mapOsmOverlayHint => '道路、建物、地名をより詳しく表示';

  @override
  String get mapOsmDetails => '詳細地図のレイヤー';

  @override
  String get moreDataSources => 'データ提供元';

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
    return '$enabled / $total レイヤーを有効化';
  }

  @override
  String get mapOsmSurface => '地表';

  @override
  String get mapOsmParks => '公園';

  @override
  String get mapOsmLandUse => '土地利用';

  @override
  String get mapOsmAirportAreas => '空港エリア';

  @override
  String get mapOsmWater => '水域';

  @override
  String get mapOsmRivers => '河川';

  @override
  String get mapOsmBoundaries => '境界';

  @override
  String get mapOsmBuildings => '建物';

  @override
  String get mapOsmRoads => '道路';

  @override
  String get mapOsmRoadNames => '道路名';

  @override
  String get mapOsmWaterNames => '水域名';

  @override
  String get mapOsmPeaks => '山頂';

  @override
  String get mapOsmAirportNames => '空港名';

  @override
  String get mapOsmPlaceNames => '地名';

  @override
  String get mapOsmPoi => '注目施設';

  @override
  String get mapOsmHouseNumbers => '住居表示';

  @override
  String get mapOsmRestoreAll => 'すべて復元';

  @override
  String get mapOsmSectionNatural => '自然地物';

  @override
  String get mapOsmSectionRoadsAndBuildings => '道路と建物';

  @override
  String get mapOsmSectionLabelsAndPlaces => 'ラベルと場所';

  @override
  String get mapTownLabels => '郷鎮名';

  @override
  String get notifySetFailed => '設定を保存できませんでした。もう一度お試しください。';

  @override
  String get meshtasticDisconnect => '切断';

  @override
  String get meshtasticUndecoded => '復号されていません';

  @override
  String get notifyAnnouncement => 'お知らせ';

  @override
  String get onboardingIntroTitle => 'DPIP へようこそ';

  @override
  String get regionCurrentUnavailable => '現在地を取得できません';

  @override
  String get languageSystem => 'システムの既定';

  @override
  String get skyTimeSunset => '日の入り';

  @override
  String get mapLayerSatelliteDust => 'ひまわり 黄砂';

  @override
  String get mapAppAppleMaps => 'Apple Maps';

  @override
  String get regionEdit => '変更';

  @override
  String get weatherDynamicState => '天気アニメーション';

  @override
  String get moonNow => '現在';

  @override
  String get moonSectionAppearance => '見え方';

  @override
  String get moonSectionRiseSet => '月の出・月の入り';

  @override
  String get moonSectionUpcoming => '次の月相';

  @override
  String get moonSectionCalendar => '月齢カレンダー';

  @override
  String get moonDistance => '距離';

  @override
  String get moonKilometres => 'km';

  @override
  String get moonApparentSize => '視直径';

  @override
  String get moonRise => '月の出';

  @override
  String get moonSet => '月の入り';

  @override
  String get moonNextNewMoon => '次の新月';

  @override
  String get moonAlwaysUp => '終日地平線上';

  @override
  String get moonNoEvent => 'この日はなし';

  @override
  String get sunTitle => '太陽';

  @override
  String get sunSectionDaylight => '日照';

  @override
  String get sunSectionTwilight => '薄明';

  @override
  String get sunSectionLight => '光';

  @override
  String get sunSectionSundial => '日時計';

  @override
  String get sunSectionTerms => '二十四節気';

  @override
  String get sunRise => '日の出';

  @override
  String get sunSet => '日の入り';

  @override
  String get sunNoon => '南中';

  @override
  String get sunDayLength => '昼の長さ';

  @override
  String get sunTwilightCivil => '市民';

  @override
  String get sunTwilightNautical => '航海';

  @override
  String get sunTwilightAstronomical => '天文';

  @override
  String get sunGoldenHourMorning => '朝のゴールデンアワー';

  @override
  String get sunGoldenHourEvening => '夕のゴールデンアワー';

  @override
  String get sunBlueHour => 'ブルーアワー';

  @override
  String get sunEquationOfTime => '均時差';

  @override
  String get sunMinutes => '分';

  @override
  String get solarTermNext => '次の節気';

  @override
  String get planetsTitle => '惑星';

  @override
  String get planetsSectionTonight => '現在';

  @override
  String get planetUp => '地平線上';

  @override
  String get planetDown => '地平線下';

  @override
  String get planetInGlare => '太陽に近い';

  @override
  String get planetMagnitude => '等級';

  @override
  String get planetElongation => '離角';

  @override
  String get planetSky => '時間帯';

  @override
  String get planetEvening => '宵の明星';

  @override
  String get planetMorning => '明けの明星';

  @override
  String get planetDistance => '距離';

  @override
  String get planetAu => 'au';

  @override
  String get planetAltitude => '高度';

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
  String get solarTermGrainFull => '小満';

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
  String get solarTermEndOfHeat => '処暑';

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
  String get solarTermAwakeningOfInsects => '啓蟄';

  @override
  String get tonightTitle => '今夜';

  @override
  String get tonightSectionDark => '観測ウィンドウ';

  @override
  String get tonightAstronomicalNight => '天文薄明終了';

  @override
  String get tonightNeverDark => '完全に暗くならない';

  @override
  String get tonightDarkWindow => '暗夜の時間帯';

  @override
  String get tonightMoonAllNight => '月が一晩中出ている';

  @override
  String get tonightDarkTotal => '暗夜合計';

  @override
  String get tonightMoonlight => '月明かり';

  @override
  String get tonightSectionShowers => '流星群';

  @override
  String get tonightRadiantDown => '放射点が昇らない';

  @override
  String get tonightPerHour => '個/時';

  @override
  String get tonightSectionSatellites => '衛星の通過';

  @override
  String get tonightSectionTargets => '今見られる天体';

  @override
  String get showerQuadrantids => 'しぶんぎ座';

  @override
  String get showerLyrids => 'こと座';

  @override
  String get showerEtaAquariids => 'みずがめ座η';

  @override
  String get showerDeltaAquariids => 'みずがめ座δ';

  @override
  String get showerPerseids => 'ペルセウス座';

  @override
  String get showerOrionids => 'オリオン座';

  @override
  String get showerSouthernTaurids => 'おうし座南';

  @override
  String get showerLeonids => 'しし座';

  @override
  String get showerGeminids => 'ふたご座';

  @override
  String get showerUrsids => 'こぐま座';

  @override
  String get deepSkyOpenCluster => '散開星団';

  @override
  String get deepSkyGlobularCluster => '球状星団';

  @override
  String get deepSkySpiralGalaxy => '渦巻銀河';

  @override
  String get deepSkyEllipticalGalaxy => '楕円銀河';

  @override
  String get deepSkyIrregularGalaxy => '不規則銀河';

  @override
  String get deepSkyPlanetaryNebula => '惑星状星雲';

  @override
  String get deepSkySupernovaRemnant => '超新星残骸';

  @override
  String get deepSkyEmissionNebula => '散光星雲';

  @override
  String get deepSkyReflectionNebula => '反射星雲';

  @override
  String get deepSkyAsterism => 'アステリズム';

  @override
  String get almanacTitle => '暦';

  @override
  String get almanacSectionToday => '今日';

  @override
  String get almanacGregorian => '西暦';

  @override
  String get almanacLunar => '旧暦';

  @override
  String get almanacYear => '歳次';

  @override
  String get almanacMonthLength => '月の大小';

  @override
  String get almanacLongMonth => '30日';

  @override
  String get almanacShortMonth => '29日';

  @override
  String get almanacLeapPrefix => '閏';

  @override
  String get almanacSectionLunarEclipses => '月食';

  @override
  String get almanacSectionSolarEclipses => '日食';

  @override
  String get almanacNoSolarEclipse => '範囲内になし';

  @override
  String get eclipseTotal => '皆既';

  @override
  String get eclipsePartial => '部分';

  @override
  String get eclipseAnnular => '金環';

  @override
  String get eclipsePenumbral => '半影';

  @override
  String get zodiacRat => '子';

  @override
  String get zodiacOx => '丑';

  @override
  String get zodiacTiger => '寅';

  @override
  String get zodiacRabbit => '卯';

  @override
  String get zodiacDragon => '辰';

  @override
  String get zodiacSnake => '巳';

  @override
  String get zodiacHorse => '午';

  @override
  String get zodiacGoat => '未';

  @override
  String get zodiacMonkey => '申';

  @override
  String get zodiacRooster => '酉';

  @override
  String get zodiacDog => '戌';

  @override
  String get zodiacPig => '亥';

  @override
  String get tideTitle => '潮汐';

  @override
  String get tideDisclaimer => '天文起潮力のみで、港湾の潮汐表ではありません。潮位は気象庁の公表値をご覧ください。';

  @override
  String get tideSectionNow => '現在';

  @override
  String get tidePhase => '周期';

  @override
  String get tideSpring => '大潮';

  @override
  String get tideNeap => '小潮';

  @override
  String get tideMiddling => '中潮';

  @override
  String get tideLunarDistanceFactor => '月の引力';

  @override
  String get tideEquilibrium => '平衡潮位';

  @override
  String get tideMetres => 'm';

  @override
  String get tidePerigeanSpring => '次の近地点大潮';

  @override
  String get tideSectionTurningPoints => '転換点';

  @override
  String get tideHigh => '高';

  @override
  String get tideLow => '低';

  @override
  String get skyChartTitle => '星図';

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
    return '軌道要素 $days 日前';
  }

  @override
  String almanacLunarDate(String leap, int month, int day) {
    return '$leap$month 月 $day 日';
  }

  @override
  String get tonightNoShowers => '流星群なし';

  @override
  String get tonightNoPasses => '48 時間以内に可視通過なし';

  @override
  String get tonightSatellitesUnavailable => '軌道データを読み込めません';

  @override
  String get tonightNoTargets => '十分な高度の天体なし';

  @override
  String get skyChartUnavailable => '星表を読み込めません';

  @override
  String get permissionSettingsTitle => '設定から許可してください';

  @override
  String get permissionSettingsHint => 'アプリに戻ると自動で再確認します。';

  @override
  String get permissionOpenSettings => '設定を開く';

  @override
  String permissionSettingsMessage(String what) {
    return '「$what」は拒否されており、システムは再度確認しません。設定から許可してください。';
  }

  @override
  String get permissionGuideNotification => 'システム設定から通知を許可してください。';

  @override
  String get permissionGuideForegroundLocation => 'システム設定から正確な位置情報を許可してください。';

  @override
  String permissionGuideBackgroundLocation(Object option) {
    return '「$option」で「常に許可」を選択してください。';
  }

  @override
  String get permissionGuideBackgroundExecution =>
      'システム設定でバックグラウンド実行を許可し、通知が停止されないようにしてください。';

  @override
  String get permissionGuideUnusedPause =>
      'アプリが「未使用」と表示される場合は、システム設定で「許可」を選択してください。';

  @override
  String get permissionGuideUnusedFreeSpace =>
      'ストレージ不足で一時停止された場合は、キャッシュを削除して再度開いてください。';

  @override
  String get permissionGuideUnusedRevoke =>
      'アプリの権限が取り消された場合は、システム設定で再度許可してください。';

  @override
  String get permissionGuideUnusedPlayProtect =>
      'Play プロテクトが一時停止した場合は、Google Play でアプリの状態を確認してください。';

  @override
  String permissionGuideVendorPower(Object vendor) {
    return '「$vendor」の省電力設定で、このアプリを「制限なし」に設定してください。';
  }

  @override
  String get permissionStillRequired => 'まだ必要です。設定から有効にしてください。';

  @override
  String get permissionVerifyManually => 'システム設定でこの権限が有効かどうか手動で確認してください。';

  @override
  String get permissionBackgroundLocationOption => '「常に許可」';

  @override
  String get displayTextSize => '文字サイズ';

  @override
  String get displayTextSizeDesc => 'アプリの画面にのみ適用され、地図のラベルの大きさは変わりません。';

  @override
  String get displayTextWeight => '文字の太さ';

  @override
  String get displayTextWeightDesc => '文字を太くすると読みやすくなることがあります。';

  @override
  String get displayContrast => 'コントラスト';

  @override
  String get displayContrastDesc => 'コントラストを上げると、文字と背景の区別がはっきりします。';

  @override
  String get displayColorVision => '色覚調整';

  @override
  String get displayColorVisionDesc => '地図の色を含め、アプリ全体の配色を調整します。';

  @override
  String get displayColorVisionNone => 'なし';

  @override
  String get displayColorVisionProtan => '1型（赤）';

  @override
  String get displayColorVisionDeutan => '2型（緑）';

  @override
  String get displayColorVisionTritan => '3型（青黄）';

  @override
  String get displayPreviewSample => '地震情報のサンプル';

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
  String get displayWeightMedium => 'やや太い';

  @override
  String get displayWeightBold => '太い';

  @override
  String get displayContrastStandard => '標準';

  @override
  String get displayContrastMedium => '中';

  @override
  String get displayContrastHigh => '高';

  @override
  String get meshtasticDirect => '直接';

  @override
  String meshtasticHopsAway(int n) {
    return '$nホップ';
  }

  @override
  String get meshtasticStatRelayShare => '他ノードの中継';

  @override
  String get meshtasticStatRelayShareHint => '送信量に占める割合';

  @override
  String get meshtasticStatRelayValue => '中継の完了率';

  @override
  String get meshtasticStatRelaySolePath => '唯一の経路になりがち — メッシュがこのノードに依存';

  @override
  String get meshtasticStatRelayRedundant => '他ノードも同じ経路を担う';

  @override
  String get meshtasticStatRedundancy => '重複受信';

  @override
  String get meshtasticStatThinEdge => '予備経路が少ない — 中継1つの停止で孤立の恐れ';

  @override
  String get meshtasticStatWellCovered => '複数の経路が届いている';

  @override
  String get meshtasticStatErrorRate => '受信エラー率';

  @override
  String get meshtasticStatErrorRateHint => '送信時間が横ばいで上昇＝混信';

  @override
  String get meshtasticTraceRoute => 'ルート追跡';

  @override
  String get meshtasticTracing => '追跡中…';

  @override
  String get meshtasticTraceUnreadable => '応答を解読できません';

  @override
  String get meshtasticTraceOffline => '無線機に未接続';

  @override
  String get meshtasticTraceCooldown => '無線機は30秒に1回まで';

  @override
  String get meshtasticTraceNoReply => '応答なし — 圏外または別のキー';

  @override
  String get meshtasticTraceDirect => '直接到達 — 中継なし';

  @override
  String meshtasticTraceHops(int n) {
    return '$n ホップ';
  }

  @override
  String get moreDumpDiagnostics => 'デバッグ情報とログを送信';

  @override
  String get moreDumpDiagnosticsHint => 'アップロードしてリンクをコピーします';

  @override
  String get dumpIncludeSensitive => '正確な位置情報を含める';

  @override
  String get dumpIncludeSensitiveHint =>
      'ログとバックグラウンド位置情報の座標を含めます。未選択の場合は null に置き換えます';

  @override
  String get dumpUpload => 'アップロード';

  @override
  String get dumpUploaded => 'アップロードしました';

  @override
  String get dumpLinkCopied => 'リンクをクリップボードにコピーしました';

  @override
  String get dumpCopyAgain => 'もう一度コピー';

  @override
  String get dumpUploadFailed => 'アップロードに失敗しました';

  @override
  String get statusLegendUnprobed => '未探知';

  @override
  String get statusLegendUnsupported => '非対応';

  @override
  String get rainScaleSection => '色階の間隔';

  @override
  String get rainScaleFine => '細かい';

  @override
  String get rainScaleCoarse => '粗い';

  @override
  String get notifyTestTitle => '通知テスト';

  @override
  String get notifyTestIntro =>
      '行をタップすると、そのアラートが実際に送信されます。重大な警報は最大音量で鳴り、消音スイッチとおやすみモードを貫通します。';

  @override
  String get notifyTestCriticalDenied =>
      'この端末では「緊急アラート」が許可されていないため、重大な警報も消音時には音が鳴りません。';

  @override
  String get notifyTestPermissionOff => '通知がオフのため、テストしても何も表示されません。';

  @override
  String get notifyTestBehaviourOverrides => '消音・おやすみモードを貫通';

  @override
  String get notifyTestBehaviourAlerts => '音とバナー（消音中は鳴りません）';

  @override
  String get notifyTestBehaviourSounds => '音のみ、バナーなし（消音中は鳴りません）';

  @override
  String get notifyTestBehaviourSilent => '無音 — 通知センターのみ';

  @override
  String get notifyTestFailed => 'テスト通知を送信できませんでした。';

  @override
  String get moreBugReports => '報告済みのバグ';

  @override
  String get bugTrackerEmpty => '報告されたバグはまだありません';

  @override
  String get bugTrackerReplies => '返信';

  @override
  String get bugTrackerGoToDiscord => '見つからない問題はDiscordで報告してください！';

  @override
  String get bugTrackerNoMatch => '選択したタグに一致する報告はありません';

  @override
  String get bugTrackerDeveloper => '開発者';

  @override
  String get bugTrackerCannotDisplay => 'この内容は表示できません — Discord でご確認ください';

  @override
  String get bugTrackerJoinDiscussion => 'Discord で議論に参加する';

  @override
  String get bugTrackerSortLast => '最新の返信';

  @override
  String get bugTrackerSortMostDiscussed => '返信が多い順';

  @override
  String get bugTrackerStaff => 'スタッフ';

  @override
  String eewSpokenLocalIntensity(String intensity) {
    return '現在地の予想震度、$intensity。';
  }

  @override
  String eewSpokenMaxIntensity(String intensity) {
    return '予想最大震度、$intensity。';
  }
}
