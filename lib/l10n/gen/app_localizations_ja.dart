// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get languageName => '日本語';

  @override
  String get navHome => 'ホーム';

  @override
  String get navEvents => 'イベント';

  @override
  String get navMap => '地図';

  @override
  String get navData => 'データ';

  @override
  String get navEarthquake => '地震';

  @override
  String get dataSectionSeismic => '地震';

  @override
  String get dataEarthquakeSubtitle => '地震報告';

  @override
  String get dataSectionWeather => '気象';

  @override
  String get dataWeatherRankingSubtitle => '即時観測ランキング';

  @override
  String get weatherRankingTitle => '観測ランキング';

  @override
  String weatherRankingMeta(String time, int count) {
    return 'データ時刻：$time\n観測点 $count';
  }

  @override
  String get weatherRankingEmpty => '並べ替え可能な観測がありません';

  @override
  String get weatherRankingBy => '並び';

  @override
  String get weatherRankingHighest => '最高';

  @override
  String get weatherRankingLowest => '最低';

  @override
  String get weatherRankingMergeTo => '統合';

  @override
  String get weatherRankingMergeTown => '町村';

  @override
  String get weatherRankingMergeCounty => '県市';

  @override
  String get weatherRankingWind => '風速';

  @override
  String get weatherRankingGust => '突風';

  @override
  String get weatherRankingTempExtremes => '気温極値';

  @override
  String get weatherRankingExtremeHigh => '今日の最高';

  @override
  String get weatherRankingExtremeLow => '今日の最低';

  @override
  String get weatherRankingExtremeRange => '日較差';

  @override
  String weatherRankingRecordedAt(String time) {
    return '記録時刻 $time';
  }

  @override
  String weatherRankingAnalysisCurrent(String value) {
    return '現在 $value°C';
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
    return '較差 $value°C';
  }

  @override
  String get reportListEmpty => '地震報告はありません';

  @override
  String get reportListEmptyFiltered => '条件に一致する地震報告はありません';

  @override
  String reportListMeta(String magnitude, String depth) {
    return 'M$magnitude · $depth km';
  }

  @override
  String reportListMagnitude(String magnitude) {
    return 'M$magnitude';
  }

  @override
  String get reportListDepthUnit => 'km';

  @override
  String get reportListLocalFelt => '局地有感';

  @override
  String get reportListToday => '今日';

  @override
  String get reportListYesterday => '昨日';

  @override
  String reportListDayCount(int count) {
    return '$count';
  }

  @override
  String get reportListEnd => 'これ以上ありません';

  @override
  String get reportFilterTitle => '絞り込み';

  @override
  String get reportFilterSort => '並び替え';

  @override
  String get reportFilterSortTime => '時間';

  @override
  String get reportFilterSortIntensity => '震度';

  @override
  String get reportFilterSortMagnitude => '規模';

  @override
  String get reportFilterSortDepth => '深さ';

  @override
  String get reportFilterOrderDesc => '降順';

  @override
  String get reportFilterOrderAsc => '昇順';

  @override
  String get reportFilterIntensity => '震度';

  @override
  String get reportFilterIntensityInfoTitle => '震度の新制と旧制';

  @override
  String get reportFilterIntensityInfoIntro =>
      '気象署は 2020 年 1 月 1 日（台北時間）から新制震度を採用しています。';

  @override
  String get reportFilterIntensityInfoLegacyTitle => '旧制（2020 年より前）';

  @override
  String get reportFilterIntensityInfoLegacyBody =>
      '震度は 0–7 のみ。5弱／5強／6弱／6強の区分はありません。';

  @override
  String get reportFilterIntensityInfoModernTitle => '新制（2020 年以降）';

  @override
  String get reportFilterIntensityInfoModernBody =>
      '震度は 0–4、5弱、5強、6弱、6強、7。フィルタは新制に準拠し、それ以前の地震はリストで旧制表記になります。';

  @override
  String get reportFilterMagnitude => 'マグニチュード';

  @override
  String get reportFilterDepth => '深さ';

  @override
  String reportFilterDepthKm(String depth) {
    return '$depth km';
  }

  @override
  String get reportFilterDate => '日付';

  @override
  String get reportFilterDatePick => '日付を選択';

  @override
  String get reportFilterDateStartNote => '開始日：当日 00:00（台北時間）';

  @override
  String get reportFilterDateEndNote => '終了日：当日 24:00（台北時間）';

  @override
  String reportFilterRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String get reportFilterLocation => '場所';

  @override
  String get reportFilterLocationHint => '例：花蓮、海域';

  @override
  String get reportFilterAny => '指定なし';

  @override
  String get reportFilterApply => '適用';

  @override
  String get reportFilterReset => 'リセット';

  @override
  String get reportListSearch => '検索';

  @override
  String get reportDetailTitle => '地震レポート';

  @override
  String reportDetailNumbered(String number) {
    return 'No.$number 顕著有感地震';
  }

  @override
  String get reportDetailLocalFelt => '局地的な有感地震';

  @override
  String get reportDetailInfo => '詳細情報';

  @override
  String get reportDetailOriginTime => '発震時刻';

  @override
  String get reportDetailEpicenter => '震央座標';

  @override
  String get reportDetailMagnitude => '地震規模';

  @override
  String get reportDetailDepth => '震源の深さ';

  @override
  String get reportDetailAreaIntensity => '地域別震度';

  @override
  String get reportDetailLocalIntensity => '現在地の震度';

  @override
  String get reportDetailLocalIntensityUnavailable => '震度情報なし';

  @override
  String get reportDetailSortByIntensity => '震度順に並べ替え';

  @override
  String get reportDetailSortByCounty => '地域順に並べ替え';

  @override
  String get reportDetailImage => '地震レポート画像';

  @override
  String get reportDetailImageUnavailable => 'レポート画像はまだありません';

  @override
  String get reportDetailOpenReport => 'レポートページ';

  @override
  String get reportDetailReplay => 'リプレイ';

  @override
  String get navMore => 'その他';

  @override
  String get appLogs => 'アプリログ';

  @override
  String get changelogTitle => '更新履歴';

  @override
  String get changelogEmpty => 'リリースノートはまだありません';

  @override
  String get changelogTypePrerelease => 'ベータ';

  @override
  String get changelogTypeStable => '正式';

  @override
  String get changelogCurrentVersion => '現行';

  @override
  String get changelogVersionDetails => 'リリース詳細';

  @override
  String get changelogBodyEmpty => 'このリリースの説明はありません。';

  @override
  String get mapPlaceholderDisabled => '地図(一時的に無効)';

  @override
  String get moreSectionRegion => '地域';

  @override
  String get moreSectionNotify => '通知';

  @override
  String get moreSectionDisplay => '表示';

  @override
  String get regionManageTitle => '登録地域';

  @override
  String get regionAddButton => '地域を追加';

  @override
  String get regionEmpty => '登録地域がありません';

  @override
  String get regionSelectTitle => '地域を選択';

  @override
  String regionSelectCount(int count, int max) {
    return '$count/$max 件選択中';
  }

  @override
  String regionSelectFull(int max) {
    return '地域は最大 $max 件まで登録できます';
  }

  @override
  String get regionEdit => '変更';

  @override
  String get moreSectionAdvanced => '詳細設定';

  @override
  String get moreDeveloper => 'デバッグ情報';

  @override
  String get experimentalFeatures => '実験的機能';

  @override
  String get moreSectionLinks => '関連リンク';

  @override
  String get moreCwaEew => '中央気象署 緊急地震速報';

  @override
  String get moreTremReport => 'TREM 検知レポート';

  @override
  String get moreServerStatus => 'サーバー状態';

  @override
  String get moreAnnouncements => 'お知らせ';

  @override
  String get moreDiscord => 'Discord コミュニティ';

  @override
  String get moreNotifyLog => 'DPIP 通知送信履歴';

  @override
  String get moreLinkOpenFailed => 'リンクを開けませんでした';

  @override
  String get weatherDynamicState => '天気アニメーション';

  @override
  String get weatherDynamicStateSubtitle => 'ホーム背景の天気を上書きします';

  @override
  String get weatherModeAuto => '自動';

  @override
  String get weatherModeClear => '晴れ';

  @override
  String get weatherModeRain => '雨';

  @override
  String get weatherModeFog => '霧';

  @override
  String get weatherModeThunderstorm => '雷雨';

  @override
  String get commonLoading => '読み込み中…';

  @override
  String get commonRetry => '再試行';

  @override
  String get commonError => '問題が発生しました';

  @override
  String get commonFetchFailed => 'データを取得できませんでした。しばらくしてから再度お試しください。';

  @override
  String get commonEmpty => '表示する項目がありません';

  @override
  String get feedConnecting => '接続中…';

  @override
  String get feedStale => 'データが最新でない可能性があります';

  @override
  String get feedOffline => '接続が切断されました';

  @override
  String get eewTitle => '緊急地震速報';

  @override
  String get eewNone => '現在、緊急地震速報はありません';

  @override
  String eewSummary(String magnitude, String depth) {
    return 'M$magnitude・深さ $depth km';
  }

  @override
  String get regionNationwide => '全国';

  @override
  String get regionCurrent => '現在地';

  @override
  String get regionCurrentUnavailable => '現在地を取得できません';

  @override
  String get weatherPrecipitation => '降水量';

  @override
  String get weatherHumidity => '湿度';

  @override
  String get homeForecastTitle => '24時間予報';

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
    return '$direction · 風力$level';
  }

  @override
  String get homeForecastUnavailable => '地域を選ぶと予報を表示します';

  @override
  String get homeForecastEmpty => '予報データがありません';

  @override
  String get homeActiveEventsTitle => '発生中の事象';

  @override
  String get homeActiveEventsEmpty => '発生中の事象はありません';

  @override
  String get homeRainTrendTitle => '今後1時間の雨';

  @override
  String homeRainTrendMinute(int minute) {
    return '$minute分';
  }

  @override
  String homeRainTrendUpdated(String time) {
    return '更新 $time';
  }

  @override
  String get homeRainTrendNoData => 'データなし';

  @override
  String get homeRainTrendScattered => 'にわか雨の可能性があります';

  @override
  String get homeRainTrendLightSustained => '今後1時間は小雨が続きます';

  @override
  String homeRainTrendLightStopping(int minutes) {
    return '$minutes分後に小雨が止む見込みです';
  }

  @override
  String get homeRainTrendHeavySustained => '今後1時間は大雨が続きます';

  @override
  String homeRainTrendHeavyStopping(int minutes) {
    return '$minutes分後に大雨が止む見込みです';
  }

  @override
  String get mapLayers => 'レイヤー';

  @override
  String get mapLayerOrderTitle => 'レイヤーの順番';

  @override
  String get mapLayerOrderReset => '既定の順序に戻す';

  @override
  String get mapLayerRadar => 'レーダー合成エコー図';

  @override
  String get mapLayerSatellite => 'ひまわり 赤外線図';

  @override
  String get mapLayerQpesums => '1時間降水量予報';

  @override
  String get mapLayerLightning => '雷';

  @override
  String lightningLegendCg(int minutes) {
    return '対地 · $minutes 分以内';
  }

  @override
  String lightningLegendCc(int minutes) {
    return '雲間 · $minutes 分以内';
  }

  @override
  String get mapTimelineNow => '現在';

  @override
  String get mapTimelineObserved => '観測';

  @override
  String get mapTimelineForecast => '予報';

  @override
  String get notifySettingsMenu => '通知設定';

  @override
  String get notifyTitle => '通知';

  @override
  String get notifyUnavailable => 'プッシュ通知はまだ準備できていません。しばらくしてから再度お試しください。';

  @override
  String get notifySetFailed => '設定を保存できませんでした。もう一度お試しください。';

  @override
  String get notifySectionEew => '緊急地震速報';

  @override
  String get notifySectionEarthquake => '地震';

  @override
  String get notifySectionWeather => '天気';

  @override
  String get notifySectionTsunami => '津波';

  @override
  String get notifySectionOther => 'その他';

  @override
  String get notifyEew => '緊急地震速報';

  @override
  String get notifyMonitor => '強震モニタ';

  @override
  String get notifyReport => '地震報告';

  @override
  String get notifyIntensity => '震度速報';

  @override
  String get notifyThunderstorm => '雷雨情報';

  @override
  String get notifyAdvisory => '気象警報・注意報';

  @override
  String get notifyEvacuation => '防災情報';

  @override
  String get notifyTsunami => '津波情報';

  @override
  String get notifyAnnouncement => 'お知らせ';

  @override
  String get notifyOptOff => 'オフ';

  @override
  String get notifyOptAll => 'すべて受信';

  @override
  String get notifyOptLocalIntensity4 => '所在地の震度4以上';

  @override
  String get notifyOptLocalIntensity1 => '所在地の震度1以上';

  @override
  String get notifyOptWeatherLocal => '現在地のみ';

  @override
  String get notifyOptTsunamiWarning => '津波警報のみ';

  @override
  String get notifyOptTsunamiAll => '津波情報・津波警報';

  @override
  String get onboardingNext => '次へ';

  @override
  String get onboardingBack => '戻る';

  @override
  String get onboardingScrollHint => '下にスクロールして続行してください';

  @override
  String get onboardingIntroTitle => 'DPIP へようこそ';

  @override
  String get onboardingIntroBody =>
      'DPIP はあなたと共にある防災パートナーです。緊急地震速報、地震報告、天気、各種災害情報を統合し、重要な瞬間にすぐお知らせします。\n\n• 地震:緊急地震速報、震度速報、地震報告\n• 天気:雷雨即時情報、気象警報・注意報\n• 津波・防災情報\n\n次に、サービス利用規約をご確認いただき、DPIP がリアルタイムであなたを守れるよう、いくつかの権限の許可をお願いします。';

  @override
  String get onboardingTermsTitle => 'サービス利用規約';

  @override
  String get onboardingTermsBody =>
      'DPIP をご利用になる前に、以下の注意事項を必ずお読みください:\n\n• すべての情報は、台湾中央気象署(CWA)が発表する内容を優先してください。\n\n• ネットワーク、サーバー、アプリ、上流のデータソースの状態によっては、情報を受信できない場合があります。可能な限り回避に努めますが、決して発生しないことを保証するものではありません。\n\n• 強い揺れが、通知より先にあなたの所在地へ到達する場合があります。\n\n• 緊急地震速報は高速に計算された結果であり、大きな誤差を含む可能性があります。この点を理解したうえで、慎重にご利用ください。\n\n• 公的機関に認められていない行為には法的リスクが伴う可能性があります。関連する規定を必ずお守りください。\n\nまた、地域に応じた警報を提供するため、本サービスは、どの警報をあなたに送信するかを判断する目的にのみ、あなたのおおよその位置情報とプッシュ識別子を、フォアグラウンドおよびバックグラウンドで収集・アップロードします。\n\n下部の「同意して続行」をタップすることで、上記を読み、理解し、同意したものとみなされます。';

  @override
  String get onboardingTermsAgree => 'サービス利用規約を読み、同意します';

  @override
  String get onboardingAgreeContinue => '同意して続行';

  @override
  String get onboardingPermsTitle => '権限の許可';

  @override
  String get onboardingPermsBody =>
      '災害が発生した瞬間に DPIP がお知らせできるよう、以下の権限を許可してください。これらはシステム設定でいつでも変更できます。';

  @override
  String get onboardingPermNotify => '通知';

  @override
  String get onboardingPermNotifyDesc => '地震、天気、災害の発生時に、警報をすぐお届けします。';

  @override
  String get onboardingPermCritical => '重大な通知';

  @override
  String get onboardingPermCriticalDesc =>
      '生命に関わる緊急地震速報を、消音モードやおやすみモードでも鳴らせるようにします。';

  @override
  String get onboardingPermLocation => '位置情報';

  @override
  String get onboardingPermLocationDesc => 'あなたの所在地に合わせて警報を配信します。';

  @override
  String get onboardingPermBackground => 'バックグラウンドの位置情報';

  @override
  String get onboardingPermBackgroundDesc =>
      '「常に許可」を選択すると、アプリを閉じていても所在地に合わせて警報を配信できます。';

  @override
  String get onboardingPermBattery => 'バッテリー最適化の除外';

  @override
  String get onboardingPermBatteryDesc =>
      'DPIP がバックグラウンドで動作し続けられるようにして、警報の遅延や取りこぼしを防ぎます。';

  @override
  String get onboardingGrant => '許可';

  @override
  String get onboardingGranted => '許可済み';

  @override
  String get onboardingStart => 'はじめる';

  @override
  String get language => '言語';

  @override
  String get languageSettings => '言語設定';

  @override
  String get languageSystem => 'システムの既定';

  @override
  String get locationBannerServiceOff => '位置情報サービスがオフです。所在地に合わせた警報を配信できません。';

  @override
  String get locationBannerPermission => '位置情報の許可がオフです。所在地に合わせた警報を配信できません。';

  @override
  String get locationBannerFix => '設定を開く';

  @override
  String get notifyBannerDisabled => '通知がオフです — 災害警報を受け取れません。';

  @override
  String get onboardingSkipTitle => '権限が許可されていません';

  @override
  String get onboardingSkipBody =>
      '位置情報と通知を許可しないと、DPIP はお近くの地震や災害をリアルタイムでお知らせできません。設定から後で許可することもできます。';

  @override
  String get onboardingSkipStay => '戻って許可';

  @override
  String get onboardingSkipLeave => 'このままスキップ';

  @override
  String get moreYoutube => 'YouTube';

  @override
  String get moreGithub => 'ExpTech GitHub';

  @override
  String get moreSourceCode => 'ソースコード';

  @override
  String get moreSectionApp => 'アプリを入手';

  @override
  String get moreGooglePlay => 'Google Play';

  @override
  String get moreAppStore => 'App Store';

  @override
  String get displaySettings => '表示';

  @override
  String get defaultMapLayerSettings => '地図の初期レイヤー';

  @override
  String get defaultMapLayerSubtitle =>
      '地図タブを開いたときに表示するレイヤーです。下部ナビのアイコンとラベルもこれに合わせます。';

  @override
  String get mapNavRadar => 'レーダー';

  @override
  String get mapNavQpesums => '予報';

  @override
  String get mapNavSatellite => '衛星';

  @override
  String get mapNavLightning => '稲妻';

  @override
  String get mapNavTyphoon => '台風';

  @override
  String get mapNavEarthquake => '地震';

  @override
  String get mapNavTemperature => '気温';

  @override
  String get mapNavHumidity => '湿度';

  @override
  String get mapNavPressure => '気圧';

  @override
  String get mapNavWind => '風向';

  @override
  String get mapNavRain => '雨量';

  @override
  String get mapNavDisaster => '防災';

  @override
  String get displayTheme => 'テーマ';

  @override
  String get themeSystem => 'システム';

  @override
  String get themeLight => 'ライト';

  @override
  String get themeDark => 'ダーク';

  @override
  String get moreSectionAbout => '情報';

  @override
  String get termsOfService => '利用規約';

  @override
  String get faq => 'よくある質問';

  @override
  String get openSourceLicenses => 'オープンソースライセンス';

  @override
  String get sponsorTitle => 'DPIP を支援';

  @override
  String get sponsorIntro =>
      'DPIP はリアルタイムの防災情報の提供に取り組んでおり、広告やその他の収益モデルはありません。皆さまのご支援はサーバーの運用と継続的な開発に役立ちます。';

  @override
  String get sponsorSubscriptions => 'サブスクリプション';

  @override
  String get sponsorRecommended => 'おすすめ';

  @override
  String get sponsorOneTime => '一回限りの支援';

  @override
  String sponsorPerMonth(String price) {
    return '$price / 月';
  }

  @override
  String get sponsorRestore => '購入を復元';

  @override
  String get sponsorTerms => '利用規約';

  @override
  String get sponsorPrivacy => 'プライバシーポリシー';

  @override
  String get sponsorRestoring => '購入を復元しています…';

  @override
  String get sponsorRestoreUnavailable => 'ストアに接続できません。しばらくしてからもう一度お試しください。';

  @override
  String get commonClose => '閉じる';

  @override
  String get mapLayerTemperature => '気温';

  @override
  String get trendRange24h => '24時間';

  @override
  String get trendRange7d => '7日間';

  @override
  String get trendNoData => 'トレンドデータがありません';

  @override
  String trendCumulativeTotal(String total) {
    return '累計 $total mm';
  }

  @override
  String chartHourLabel(int hour) {
    return '$hour時';
  }

  @override
  String get mapLayerHumidity => '湿度';

  @override
  String get mapLayerPressure => '気圧';

  @override
  String get mapLayerWind => '風向';

  @override
  String get mapLayerRain => '降水量';

  @override
  String get rainIntervalMenu => '累積期間';

  @override
  String get rainIntervalNow => '今日';

  @override
  String get rainInterval10m => '10分';

  @override
  String get rainInterval1h => '1時間';

  @override
  String get rainInterval3h => '3時間';

  @override
  String get rainInterval6h => '6時間';

  @override
  String get rainInterval12h => '12時間';

  @override
  String get rainInterval24h => '24時間';

  @override
  String get rainInterval2d => '2日';

  @override
  String get rainInterval3d => '3日';

  @override
  String get mapLayerTyphoon => '台風';

  @override
  String get typhoonNoActive => '発生中の台風なし';

  @override
  String get typhoonWind => '風速';

  @override
  String get typhoonGust => '最大瞬間風速';

  @override
  String get typhoonPressure => '気圧';

  @override
  String get typhoonMotion => '進行';

  @override
  String get typhoonLabelPosition => '中心位置';

  @override
  String get typhoonLabelDirection => 'これまでの進行方向';

  @override
  String get typhoonLabelSpeed => 'これまでの移動速度';

  @override
  String get typhoonLabelPressure => '中心気圧';

  @override
  String get typhoonLabelWind => '中心付近の最大風速';

  @override
  String get typhoonLabelGust => '最大瞬間風速';

  @override
  String get typhoonLabelGaleAvg => '強風域の平均半径';

  @override
  String get typhoonLabelStormAvg => '暴風域の平均半径';

  @override
  String get typhoonLabelProbCircle => '70%確率円';

  @override
  String typhoonForecastLead(String hours) {
    return '予報 +$hours 時間';
  }

  @override
  String get typhoonLabelNw => '北西';

  @override
  String get typhoonLabelNe => '北東';

  @override
  String get typhoonLabelSw => '南西';

  @override
  String get typhoonLabelSe => '南東';

  @override
  String typhoonValueLat(String lat) {
    return '北緯 $lat 度';
  }

  @override
  String typhoonValueLon(String lon) {
    return '東経 $lon 度';
  }

  @override
  String typhoonValueKm(String n) {
    return '$n km';
  }

  @override
  String typhoonValueHpa(String n) {
    return '$n hPa';
  }

  @override
  String typhoonValueMs(String n) {
    return '毎秒 $n m';
  }

  @override
  String typhoonDataTime(String time) {
    return '資料時刻\n$time';
  }

  @override
  String get mapLayerMonitor => '強震モニタ';

  @override
  String get mapLayerDisasterMap => '防災マップ';

  @override
  String get mapLayerAed => 'AED';

  @override
  String get disasterMapOverlayMenuTooltip => '防災マップのレイヤー';

  @override
  String get disasterMapOverlaySectionLayers => 'レイヤー';

  @override
  String get disasterMapOverlayAedTooltip => 'AEDの位置を表示';

  @override
  String get aedAddress => '住所';

  @override
  String get aedRegion => '地域';

  @override
  String get aedCategory => '分類';

  @override
  String get aedType => '種類';

  @override
  String get aedPlaceDesc => '設置場所';

  @override
  String get aedDescription => '備考';

  @override
  String get aedHoursWeekday => '平日の開館時間';

  @override
  String get aedHoursSaturday => '土曜の開館時間';

  @override
  String get aedHoursSunday => '日曜の開館時間';

  @override
  String get aedOpenRemark => '開館時間メモ';

  @override
  String get aedEmergencyPhone => '緊急連絡先';

  @override
  String get mapLayerRestroom => 'トイレ';

  @override
  String get mapLayerShelter => '避難所';

  @override
  String get disasterMapOverlayRestroomTooltip => 'トイレを表示';

  @override
  String get disasterMapOverlayShelterTooltip => '避難所を表示';

  @override
  String get dpmOpenInMaps => '地図アプリで開く';

  @override
  String get mapAppGoogleMaps => 'Google Maps';

  @override
  String get mapAppAppleMaps => 'Apple Maps';

  @override
  String mapAppDefault(String app) {
    return '$app（デフォルト）';
  }

  @override
  String get mapAppCopyCoordinates => '座標をコピー';

  @override
  String get mapAppCoordinatesCopied => '座標をコピーしました';

  @override
  String get mapOverlaySectionReference => '参照レイヤー';

  @override
  String get mapLayerCategoryEarthquake => '地震';

  @override
  String get mapLayerCategoryTyphoon => '台風';

  @override
  String get mapLayerCategoryWeather => '気象観測';

  @override
  String get mapLayerCategorySatellite => '衛星';

  @override
  String get mapLayerCategoryRadar => 'レーダー';

  @override
  String get mapLayerCategoryLife => '生活';

  @override
  String get mapOverlaySectionMap => '地図';

  @override
  String get rainIntervalSection => '集計時間';

  @override
  String get mapTownLabels => '郷鎮名';

  @override
  String get mapTownLabelsHint => '拡大すると郷鎮名を表示';

  @override
  String get dpmSheetEmpty => '地図上のマーカーをタップして詳細を表示';

  @override
  String get dpmAddress => '住所';

  @override
  String get restroomTypeLabel => '種別';

  @override
  String get restroomCategoryLabel => '区分';

  @override
  String get restroomGradeLabel => '等級';

  @override
  String get restroomTypeFemale => '女性用トイレ';

  @override
  String get restroomTypeMale => '男性用トイレ';

  @override
  String get restroomTypeMixed => '男女共用トイレ';

  @override
  String get restroomTypeAccessible => 'バリアフリートイレ';

  @override
  String get restroomTypeGenderNeutral => 'ジェンダーニュートラルトイレ';

  @override
  String get restroomTypeFamily => '親子トイレ';

  @override
  String get restroomTypeUnspecified => '未設定';

  @override
  String get restroomCategoryTransport => '交通';

  @override
  String get restroomCategoryPark => '公園';

  @override
  String get restroomCategoryCommercial => '商業・営業施設';

  @override
  String get restroomCategoryReligious => '宗教・礼拝施設';

  @override
  String get restroomCategoryCultural => '文化・娯楽施設';

  @override
  String get restroomCategoryGovernment => '行政サービス施設';

  @override
  String get restroomCategoryWelfare => '社会福祉施設・集会所';

  @override
  String get restroomCategoryTourist => '観光地・景勝地';

  @override
  String get restroomCategoryLeisure => 'レジャー・娯楽施設';

  @override
  String get restroomCategoryOther => 'その他';

  @override
  String get restroomGradeExcellent => '最上級';

  @override
  String get restroomGradeGood => '優良';

  @override
  String get restroomGradeAverage => '普通';

  @override
  String get restroomGradePoor => '不合格';

  @override
  String get shelterAddressLabel => '住所';

  @override
  String get shelterCapacityLabel => '収容人数';

  @override
  String shelterCapacityValue(int n) {
    return '$n 人';
  }

  @override
  String get shelterCategoryLabel => '対象災害';

  @override
  String get shelterIndoorLabel => '屋内収容';

  @override
  String get shelterOutdoorLabel => '屋外収容';

  @override
  String get shelterVulnerableOkLabel => '要配慮者向け収容';

  @override
  String get dpmYes => 'はい';

  @override
  String get dpmNo => 'いいえ';

  @override
  String get stationSheetEmpty => '観測点をタップして値を表示';

  @override
  String monitorDelay(String value) {
    return '遅延 $value s';
  }

  @override
  String get monitorWaiting => 'データ待機中…';

  @override
  String mapLegendUnit(String unit) {
    return '単位：$unit';
  }

  @override
  String get typhoonLegendPast => '実況経路';

  @override
  String get typhoonIntensityTd => '熱帯低気圧';

  @override
  String typhoonPickerNamed(String no, String name) {
    return '$name TY $no';
  }

  @override
  String typhoonPickerTd(String no) {
    return '熱帯低気圧 TD $no';
  }

  @override
  String get typhoonIntensityMild => '弱い台風';

  @override
  String get typhoonIntensityModerate => '並の台風';

  @override
  String get typhoonIntensityIntense => '強い台風';

  @override
  String get typhoonLegendForecast => '予報経路';

  @override
  String get typhoonLegendForecastPoint => '予報点';

  @override
  String get typhoonLegendCurrent => '現在中心';

  @override
  String get typhoonLegendCone => '予報円';

  @override
  String get mapLegendExpand => '凡例';

  @override
  String get mapLegendCollapse => '凡例を閉じる';

  @override
  String get mapMyLocation => '現在地';

  @override
  String get mapResetNorth => '北を上にする';

  @override
  String get typhoonLegendCircle15 => '強風域（30kt）';

  @override
  String get typhoonLegendCircleAvg => '平均円';

  @override
  String get typhoonLegendCircle25 => '暴風域（50kt）';

  @override
  String typhoonStormRadii(String ne, String se, String sw, String nw) {
    return 'NE $ne · SE $se · SW $sw · NW $nw km';
  }

  @override
  String typhoonTimeChip(String day, String hour) {
    return '$day日$hour時';
  }

  @override
  String get typhoonLegendProbability => '接近確率';

  @override
  String get typhoonLegendWarningAreas => '警報区域';

  @override
  String get typhoonOverlayMenuTooltip => '台風オーバーレイ設定';

  @override
  String get typhoonOverlaySectionStorm => '暴風域';

  @override
  String get typhoonOverlaySectionExtra => 'オーバーレイ';

  @override
  String get typhoonOverlayStormBandSubtitle => '平均円付き';

  @override
  String get typhoonOverlayProbabilityHint => '予報円を隠します';

  @override
  String get typhoonOverlayProbabilityTooltip => '接近確率を表示（予報円を隠す）';

  @override
  String get typhoonOverlayWarningTooltip => '台風警報対象の県を強調';

  @override
  String get typhoonOverlayStormL7Tooltip => '強風域 + 平均円（紫）';

  @override
  String get typhoonOverlayStormL10Tooltip => '暴風域 + 平均円（黄）';

  @override
  String get typhoonOverlaySectionWeather => '天気下敷き';

  @override
  String get typhoonOverlayWeatherNone => 'なし';

  @override
  String get typhoonOverlayWeatherHint => '通報時刻に合わせる';

  @override
  String get typhoonOverlayWeatherNoneTooltip => 'レーダー／赤外線なし';

  @override
  String get typhoonOverlayWeatherRadarTooltip => '通報時刻に最も近いレーダー';

  @override
  String get typhoonOverlayWeatherSatelliteTooltip => '通報時刻に最も近い赤外線';

  @override
  String get typhoonWarningTitle => '台風警報';

  @override
  String typhoonWarningAreas(String areas) {
    return '対象地域：$areas';
  }

  @override
  String get typhoonTrackDetail => '経路詳細';

  @override
  String get typhoonHistoryTitle => '資料時刻';

  @override
  String get typhoonHistoryLive => '最新';

  @override
  String get typhoonSatelliteTitle => '衛星';

  @override
  String get typhoonOverlayForecastCallouts => '予報点の情報';

  @override
  String get typhoonOverlayForecastCalloutsTooltip => '拡大時に予報点の詳細カードを表示';

  @override
  String get dpmFilterSectionRestroom => '施設の種類';

  @override
  String get dpmFilterSectionRestroomType => 'トイレの種類';

  @override
  String get dpmFilterSectionShelter => '避難所の災害種別';

  @override
  String get dpmDisasterFlood => '洪水';

  @override
  String get dpmDisasterEarthquake => '震災';

  @override
  String get dpmDisasterLandslide => '土石流';

  @override
  String get dpmDisasterTsunami => '津波';

  @override
  String get dpmDisasterSlope => '斜面災害';

  @override
  String get dpmDisasterNuclear => '原子力事故';

  @override
  String get skyTime => '空の時刻';

  @override
  String get skyTimeAuto => '自動';

  @override
  String get skyTimeDawn => '夜明け前';

  @override
  String get skyTimeSunrise => '日の出';

  @override
  String get skyTimeMorning => '午前';

  @override
  String get skyTimeNoon => '正午';

  @override
  String get skyTimeAfternoon => '午後';

  @override
  String get skyTimeGolden => 'ゴールデンアワー';

  @override
  String get skyTimeSunset => '日の入り';

  @override
  String get skyTimeDusk => '薄暮';

  @override
  String get skyTimeNight => '夜';

  @override
  String get weatherModeCloudy => '曇り';

  @override
  String get weatherModeOvercast => '本曇り';

  @override
  String get weatherModeSnow => '雪';

  @override
  String get weatherModeSand => '砂じん';

  @override
  String get radarScanRange => '走査範囲を表示';

  @override
  String get radarScanRangeSubtitle => '4基のレーダーが実際に観測する範囲を示します。';

  @override
  String get radarScanRangeHint => '枠外の空白は未観測';

  @override
  String get radarOverlayMenuTooltip => 'レーダーレイヤー設定';

  @override
  String get radarCountyOutline => '県市境界';

  @override
  String get radarCountyOutlineHint => 'エコーの上に描画';

  @override
  String get radarCountyOutlineSubtitle => 'レーダーエコーの下でも県市境界が見えるようにします。';

  @override
  String get radarTownOutline => '市町村境界';

  @override
  String get radarTownOutlineHint => 'より細かい区分';

  @override
  String get radarTownOutlineSubtitle => 'レーダーエコーの下でも市町村境界が見えるようにします。';

  @override
  String get qpesumsOverlayMenuTooltip => '定量降水予報レイヤー設定';
}
