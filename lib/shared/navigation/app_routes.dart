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

  static const String earthquake = 'earthquake';
  static const String earthquakePath = '/earthquake';

  static const String more = 'more';
  static const String morePath = '/more';

  // Full-screen routes pushed over the shell.
  static const String experimental = 'experimental';
  static const String experimentalPath = '/experimental';

  static const String log = 'log';
  static const String logPath = '/log';

  // Region picker: the city list, then the township list within a city
  // (`:city` path parameter). Saved townships feed the Home region bar.
  static const String regionSelect = 'regionSelect';
  static const String regionSelectPath = '/region-select';

  static const String regionSelectCity = 'regionSelectCity';
  static const String regionSelectCityPath = ':city';

  // Per-channel push notification settings.
  static const String notifySettings = 'notifySettings';
  static const String notifySettingsPath = '/notify-settings';
}
