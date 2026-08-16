/// Central registry of route names and paths.
///
/// Every route identifier lives here so the router and any feature can navigate
/// by name (`context.goNamed` / `pushNamed`) without importing another feature's
/// page widget — that import would couple features together and the layering
/// gate rejects it. `path` is the URL registered in the router; `name` is the
/// stable identifier used to navigate.
abstract final class AppRoutes {
  const AppRoutes._();

  // Bottom-navigation branches, in shell order.
  static const String home = 'home';
  static const String homePath = '/home';

  static const String events = 'events';
  static const String eventsPath = '/events';

  static const String map = 'map';
  static const String mapPath = '/map';

  /// Bottom-nav "資料" hub (was the Earthquake slot).
  static const String data = 'data';
  static const String dataPath = '/data';

  /// Earthquake report catalogue — nested under [dataPath].
  static const String earthquake = 'earthquake';
  static const String earthquakePath = 'earthquake';

  /// A single report's detail (震度/規模 breakdown) — nested under
  /// [earthquakePath] with an `:id` path parameter (the report id).
  static const String earthquakeReport = 'earthquakeReport';
  static const String earthquakeReportPath = ':id';

  /// RTS + EEW replay from a report's "重播" chip — nested under
  /// [earthquakeReportPath]. Takes the replay start instant as a required
  /// `?t=` query parameter (Unix ms); the `:id` param above is unused by the
  /// replay page itself, just inherited from the parent route.
  static const String earthquakeReplay = 'earthquakeReplay';
  static const String earthquakeReplayPath = 'replay';

  /// Live EEW monitor — nested under [dataPath].
  static const String eew = 'eew';
  static const String eewPath = 'eew';

  /// Weather observation ranking — nested under [dataPath].
  /// Optional `?tab=` —
  /// `rain|temperature|tempExtremes|wind|gust|humidity|pressure`.
  static const String weatherRanking = 'weatherRanking';
  static const String weatherRankingPath = 'weather-ranking';

  /// Lunar phase — nested under [dataPath]. Local computation only.
  static const String moon = 'moon';
  static const String moonPath = 'moon';

  /// Daylight, twilight and the solar terms — nested under [dataPath].
  static const String sun = 'sun';
  static const String sunPath = 'sun';

  /// The planets tonight — nested under [dataPath].
  static const String planets = 'planets';
  static const String planetsPath = 'planets';

  /// Tonight's observing window and what is up — nested under [dataPath].
  static const String tonight = 'tonight';
  static const String tonightPath = 'tonight';

  /// 農曆 and upcoming eclipses — nested under [dataPath].
  static const String almanac = 'almanac';
  static const String almanacPath = 'almanac';

  /// The naked-eye sky chart — nested under [dataPath].
  static const String skyChart = 'skyChart';
  static const String skyChartPath = 'sky-chart';

  /// Astronomical tidal forcing — nested under [dataPath].
  static const String tide = 'tide';
  static const String tidePath = 'tide';

  static const String more = 'more';
  static const String morePath = '/more';

  // First-launch onboarding (intro → terms → permissions), shown before the
  // shell until completed.
  static const String onboarding = 'onboarding';
  static const String onboardingPath = '/onboarding';

  // Full-screen routes pushed over the shell.
  static const String experimental = 'experimental';
  static const String experimentalPath = '/experimental';

  static const String developer = 'developer';
  static const String developerPath = '/developer';

  // Appearance / language settings, pushed over the shell from the More tab.
  static const String display = 'display';
  static const String displayPath = '/display';

  static const String language = 'language';
  static const String languagePath = '/language';

  /// Default Map-tab overlay (also drives bottom-nav icon/label).
  static const String defaultMapLayer = 'defaultMapLayer';
  static const String defaultMapLayerPath = '/default-map-layer';

  static const String log = 'log';
  static const String logPath = '/log';

  /// LoRa mesh (Meshtastic) BLE test page — scan/connect/chat against a radio.
  static const String meshtastic = 'meshtastic';
  static const String meshtasticPath = '/meshtastic';

  /// App release notes (GitHub releases).
  static const String changelog = 'changelog';
  static const String changelogPath = '/changelog';

  // Saved-region management: the manage page (view/remove saved townships)
  // opens the picker to add. Saved townships feed the Home region bar.
  static const String regionManage = 'regionManage';
  static const String regionManagePath = '/region';

  // Region picker: the city list, then the township list within a city
  // (`:city` path parameter).
  static const String regionSelect = 'regionSelect';
  static const String regionSelectPath = '/region-select';

  static const String regionSelectCity = 'regionSelectCity';
  static const String regionSelectCityPath = ':city';

  /// Permission checklist (權限檢查) — the same rows onboarding shows, kept
  /// reachable afterwards because a missing alert is usually a missing grant.
  static const String permissions = 'permissions';
  static const String permissionsPath = '/permissions';

  // Per-channel push notification settings.
  static const String notifySettings = 'notifySettings';
  static const String notifySettingsPath = '/notify-settings';

  // Support / in-app-purchase page.
  static const String sponsor = 'sponsor';
  static const String sponsorPath = '/sponsor';
}
