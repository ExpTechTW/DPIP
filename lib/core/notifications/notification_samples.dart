/// The sample alert each channel's test notification posts.
///
/// **Deliberately Traditional Chinese, and deliberately not localized.** These
/// are not the app's own words — they are reproductions of what the backend
/// actually sends, and the backend sends Chinese to every device regardless of
/// its language. Translating them would make the test show something the user
/// will never receive, which is the one thing a test must not do. The page's
/// own chrome around them is localized normally.
///
/// Carried over verbatim from the legacy app's `assets/notify_test.json` so a
/// user who knew the old alerts recognises these. An asset is not needed: 21
/// fixed strings compile into the binary, cost no I/O, and cannot be missing at
/// runtime the way a mis-declared asset can.
///
/// Ideographic spaces are written as `\u3000` rather than pasted, because in
/// source they are indistinguishable from an ordinary space — and CWA's real
/// alerts use them for column alignment, so getting one wrong changes how the
/// sample reads.
library;

/// One channel's sample alert.
typedef NotificationSample = ({String title, String body});

/// Sample alerts, keyed by `channelKey`.
///
/// Covers the 21 push channels one-for-one. The locally-raised mesh channels
/// and the silent `background` service channel are absent on purpose: nothing
/// pushes them, so there is no server message to reproduce.
abstract final class NotificationSamples {
  const NotificationSamples._();

  /// The sample for [channelKey], or null for a channel with nothing to
  /// reproduce.
  static NotificationSample? of(String channelKey) => byChannel[channelKey];

  static const Map<String, NotificationSample> byChannel = {
    'eew_alert-important-v2': (
      title: '🚨 《緊急地震速報 (氣象署發布) 》',
      body: '花蓮縣壽豐鄉發生地震\u3000強烈搖晃警戒\n〈預估強烈搖晃地區〉\n花蓮\u3000南投\u3000臺東\u3000宜蘭',
    ),
    'eew_alert-general-v2': (
      title: '🚨 《緊急地震速報 (氣象署發布) 》',
      body: '花蓮縣壽豐鄉發生地震\u3000強烈搖晃警戒\n〈預估強烈搖晃地區〉\n花蓮\u3000南投\u3000臺東\u3000宜蘭',
    ),
    'eew_alert-silent-v2': (
      title: '🚨 《緊急地震速報 (氣象署發布) 》',
      body: '花蓮縣壽豐鄉發生地震\u3000強烈搖晃警戒\n〈預估強烈搖晃地區〉\n花蓮\u3000南投\u3000臺東\u3000宜蘭',
    ),
    'eew-important-v2': (
      title: '⚠️ 地震速報',
      body: '10:15左右，花蓮縣壽豐鄉發生地震。震源深度10公里，地震規模M6.1，最大預估震度4。',
    ),
    'eew-general-v2': (
      title: '⚠️ 地震速報',
      body: '10:15左右，花蓮縣壽豐鄉發生地震。震源深度10公里，地震規模M6.1，最大預估震度4。',
    ),
    'eew-silence-v2': (
      title: '⚠️ 地震速報',
      body: '10:15左右，花蓮縣壽豐鄉發生地震。震源深度10公里，地震規模M6.1，最大預估震度4。',
    ),
    'int_report-general-v2': (
      title: '📨 震度速報 [07:36]',
      body: '[震度 ５弱]\u3000花蓮縣',
    ),
    'int_report-silence-v2': (
      title: '📨 震度速報 [07:36]',
      body: '[震度 ５弱]\u3000花蓮縣',
    ),
    'eq-v2': (title: '📡 強震監視器', body: '臺南市歸仁區\u3000偵測到晃動'),
    'report-general-v2': (
      title: '🔔 地震報告 [小區域有感地震]',
      body: '00:36左右，花蓮縣近海發生地震。震源深度23.8公里，地震規模M4.0，花蓮縣觀測到最大震度２。',
    ),
    'report-silence-v2': (
      title: '🔔 地震報告 [小區域有感地震]',
      body: '00:36左右，花蓮縣近海發生地震。震源深度23.8公里，地震規模M4.0，花蓮縣觀測到最大震度２。',
    ),
    'thunderstorm-important-v2': (
      title: '⛈️ 山區暴雨',
      body: '您所在區域附近有暴雨發生的機率，留意溪水暴漲並儘速遠離溪流，持續至8/4 16:34',
    ),
    'thunderstorm-general-v2': (
      title: '⛈️ 雷雨即時訊息',
      body: '您所在區域附近有劇烈雷雨或降雨發生，請注意防範，持續至08/26 17:30',
    ),
    'weather_major-important-v2': (title: '📊 臺南市歸仁區 天氣特報', body: '[發布]超大豪雨特報'),
    'weather_minor-general-v2': (
      title: '📊 臺南市歸仁區 天氣特報',
      body: '[發布]大雨特報\n對流雲系發展旺盛，易有短延時強降雨，新北市已有豪雨發生，今（７日）晚至明（８日）晨基隆北海岸、彰化、雲林、南投、東半部地區及大臺北山區有局部大雨發生的機率，請注意雷擊及強陣風，山區慎防坍方、落石及溪水暴漲。',
    ),
    'evacuation_major-important-v2': (
      title: '🌧️ 防災資訊(短時極端降雨紀錄)',
      body: '臺南市永康區(CAN040 國一N323K) 1 小時累積雨量達到 91.5 mm/hr，請注意自身安全。',
    ),
    'evacuation_minor-general-v2': (
      title: '⚠️ 防災資訊(河川水位-注意)',
      body: '北寮橋 (水位 73.5m) 已達二級警戒，提高警覺，並密切注意水情變化。',
    ),
    'tsunami-important-v2': (title: '🌊 海嘯警報發布', body: '海嘯警報已發布\n請儘速前往安全區域避難'),
    'tsunami-general-v2': (title: '🌊 海嘯警報發布', body: '海嘯警報已發布\n請儘速前往安全區域避難'),
    'tsunami-silent-v2': (
      title: '🌊 太平洋海嘯消息',
      body: '頃獲太平洋海嘯警報中心通報，２０２４年０８月１８日０３時１０分（臺灣時間），俄羅斯\u3000堪察加半島東部外海發生規模７﹒４地震，震央位於東經１６０﹒１０度、北緯５２﹒７０度。該中心研判可能在太平洋地區引發海嘯威脅，氣象署將嚴密監視海嘯的後續影響，隨時提供最新資訊。',
    ),
    'announcement-general-v2': (title: '📢 公告', body: '這是一則測試公告。'),
  };
}
