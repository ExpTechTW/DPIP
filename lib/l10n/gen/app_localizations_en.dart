// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get navHome => 'Home';

  @override
  String get navEvents => 'Events';

  @override
  String get navMap => 'Map';

  @override
  String get navEarthquake => 'Earthquake';

  @override
  String get navMore => 'More';

  @override
  String get appLogs => 'App logs';

  @override
  String get mapPlaceholderDisabled => 'Map (temporarily disabled)';

  @override
  String get moreSectionAdvanced => 'Advanced';

  @override
  String get experimentalFeatures => 'Experimental features';

  @override
  String get moreSectionLinks => 'Links';

  @override
  String get moreCwaEew => 'CWA earthquake early warning';

  @override
  String get moreTremReport => 'TREM detection report';

  @override
  String get moreServerStatus => 'Server status';

  @override
  String get moreAnnouncements => 'Announcements';

  @override
  String get moreNotifyLog => 'DPIP notification log';

  @override
  String get moreLinkOpenFailed => 'Couldn\'t open the link';

  @override
  String get weatherDynamicState => 'Weather animation';

  @override
  String get weatherDynamicStateSubtitle =>
      'Override the home backdrop weather';

  @override
  String get weatherModeAuto => 'Auto';

  @override
  String get weatherModeClear => 'Clear';

  @override
  String get weatherModeRain => 'Rain';

  @override
  String get weatherModeFog => 'Fog';

  @override
  String get weatherModeThunderstorm => 'Thunderstorm';

  @override
  String get commonLoading => 'Loading…';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonError => 'Something went wrong';

  @override
  String get commonEmpty => 'Nothing to show';

  @override
  String get feedConnecting => 'Connecting…';

  @override
  String get feedStale => 'Data may be out of date';

  @override
  String get feedOffline => 'Connection lost';

  @override
  String get eewTitle => 'Earthquake early warning';

  @override
  String get eewNone => 'No active earthquake early warning';

  @override
  String eewSummary(String magnitude, String depth) {
    return 'M$magnitude · depth $depth km';
  }

  @override
  String areaPlaceholder(int number) {
    return 'Area $number';
  }

  @override
  String get weatherPrecipitation => 'Precipitation';

  @override
  String get weatherHumidity => 'Humidity';

  @override
  String get mapLayers => 'Layers';

  @override
  String get mapLayerRadar => 'Radar';

  @override
  String get mapTimelineNow => 'Now';

  @override
  String get mapTimelineObserved => 'Observed';
}
