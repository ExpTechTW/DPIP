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
  String get navEarthquake => '地震';

  @override
  String get navMore => 'その他';

  @override
  String get appLogs => 'アプリログ';

  @override
  String get mapPlaceholderDisabled => '地図(一時的に無効)';

  @override
  String get moreSectionGeneral => '一般';

  @override
  String get regionManageTitle => '登録地域';

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
  String get moreSectionAdvanced => '詳細設定';

  @override
  String get moreDeveloper => '開発者設定';

  @override
  String get developerCopied => 'クリップボードにコピーしました';

  @override
  String get developerCopyAll => 'すべてコピー';

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
  String get mapLayers => 'レイヤー';

  @override
  String get mapLayerRadar => 'レーダー';

  @override
  String get mapTimelineNow => '現在';

  @override
  String get mapTimelineObserved => '観測';

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
}
