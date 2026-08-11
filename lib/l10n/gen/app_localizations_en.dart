// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get languageName => 'English';

  @override
  String get navHome => 'Home';

  @override
  String get navEvents => 'Events';

  @override
  String get navMap => 'Map';

  @override
  String get navData => 'Data';

  @override
  String get navEarthquake => 'Earthquake';

  @override
  String get dataSectionSeismic => 'Seismic';

  @override
  String get dataEarthquakeSubtitle => 'Earthquake reports';

  @override
  String get dataSectionWeather => 'Weather';

  @override
  String get dataWeatherRankingSubtitle => 'Live station rankings';

  @override
  String get weatherRankingTitle => 'Observation rankings';

  @override
  String weatherRankingMeta(String time, int count) {
    return 'Data time: $time\n$count stations';
  }

  @override
  String get weatherRankingEmpty => 'No observations to rank';

  @override
  String get weatherRankingBy => 'Sort by';

  @override
  String get weatherRankingHighest => 'Highest';

  @override
  String get weatherRankingLowest => 'Lowest';

  @override
  String get weatherRankingMergeTo => 'Merge to';

  @override
  String get weatherRankingMergeTown => 'Township';

  @override
  String get weatherRankingMergeCounty => 'County';

  @override
  String get weatherRankingWind => 'Wind speed';

  @override
  String get weatherRankingGust => 'Gust';

  @override
  String get weatherRankingTempExtremes => 'Daily extremes';

  @override
  String get weatherRankingExtremeHigh => 'Daily high';

  @override
  String get weatherRankingExtremeLow => 'Daily low';

  @override
  String get weatherRankingExtremeRange => 'Diurnal range';

  @override
  String weatherRankingRecordedAt(String time) {
    return 'Recorded at $time';
  }

  @override
  String weatherRankingAnalysisCurrent(String value) {
    return 'Now $value°C';
  }

  @override
  String weatherRankingAnalysisHigh(String value) {
    return 'High $value';
  }

  @override
  String weatherRankingAnalysisLow(String value) {
    return 'Low $value';
  }

  @override
  String weatherRankingAnalysisRange(String value) {
    return 'Range $value°C';
  }

  @override
  String get reportListEmpty => 'No earthquake reports';

  @override
  String get reportListEmptyFiltered =>
      'No earthquake reports match these filters';

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
  String get reportListLocalFelt => 'Local felt';

  @override
  String get reportListToday => 'Today';

  @override
  String get reportListYesterday => 'Yesterday';

  @override
  String reportListDayCount(int count) {
    return '$count';
  }

  @override
  String get reportListEnd => 'End of list';

  @override
  String get reportFilterTitle => 'Filters';

  @override
  String get reportFilterSort => 'Sort';

  @override
  String get reportFilterSortTime => 'Time';

  @override
  String get reportFilterSortIntensity => 'Intensity';

  @override
  String get reportFilterSortMagnitude => 'Magnitude';

  @override
  String get reportFilterSortDepth => 'Depth';

  @override
  String get reportFilterOrderDesc => 'Descending';

  @override
  String get reportFilterOrderAsc => 'Ascending';

  @override
  String get reportFilterIntensity => 'Intensity';

  @override
  String get reportFilterIntensityInfoTitle => 'Intensity scales';

  @override
  String get reportFilterIntensityInfoIntro =>
      'CWA changed the felt-intensity scale on 1 Jan 2020 (Taipei time).';

  @override
  String get reportFilterIntensityInfoLegacyTitle => 'Legacy (before 2020)';

  @override
  String get reportFilterIntensityInfoLegacyBody =>
      'Only levels 0–7. No 5− / 5+ / 6− / 6+ split.';

  @override
  String get reportFilterIntensityInfoModernTitle => 'Current (from 2020)';

  @override
  String get reportFilterIntensityInfoModernBody =>
      'Levels 0–4, 5−, 5+, 6−, 6+, and 7. The filter slider uses this scale; older events still show legacy labels in the list.';

  @override
  String get reportFilterMagnitude => 'Magnitude';

  @override
  String get reportFilterDepth => 'Depth';

  @override
  String reportFilterDepthKm(String depth) {
    return '$depth km';
  }

  @override
  String get reportFilterDate => 'Date';

  @override
  String get reportFilterDatePick => 'Pick dates';

  @override
  String get reportFilterDateStartNote => 'Start day: from 00:00 (Taipei)';

  @override
  String get reportFilterDateEndNote => 'End day: through 24:00 (Taipei)';

  @override
  String reportFilterRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String get reportFilterLocation => 'Location';

  @override
  String get reportFilterLocationHint => 'e.g. Hualien, offshore';

  @override
  String get reportFilterAny => 'Any';

  @override
  String get reportFilterApply => 'Apply';

  @override
  String get reportFilterReset => 'Reset';

  @override
  String get reportListSearch => 'Search';

  @override
  String get reportDetailTitle => 'Earthquake Report';

  @override
  String reportDetailNumbered(String number) {
    return 'No. $number Significant Earthquake';
  }

  @override
  String get reportDetailLocalFelt => 'Local Felt Earthquake';

  @override
  String get reportDetailInfo => 'Details';

  @override
  String get reportDetailOriginTime => 'Origin time';

  @override
  String get reportDetailEpicenter => 'Epicenter';

  @override
  String get reportDetailMagnitude => 'Magnitude';

  @override
  String get reportDetailDepth => 'Depth';

  @override
  String get reportDetailAreaIntensity => 'Intensity by area';

  @override
  String get reportDetailLocalIntensity => 'Intensity at your locations';

  @override
  String get reportDetailLocalIntensityUnavailable => 'No intensity data';

  @override
  String get reportDetailSortByIntensity => 'Sort by intensity';

  @override
  String get reportDetailSortByCounty => 'Sort by county';

  @override
  String get reportDetailImage => 'Report image';

  @override
  String get reportDetailImageUnavailable => 'Report image not available';

  @override
  String get reportDetailOpenReport => 'Report page';

  @override
  String get reportDetailReplay => 'Replay';

  @override
  String get navMore => 'More';

  @override
  String get appLogs => 'App logs';

  @override
  String get changelogTitle => 'Changelog';

  @override
  String get changelogEmpty => 'No release notes yet';

  @override
  String get changelogTypePrerelease => 'Beta';

  @override
  String get changelogTypeStable => 'Stable';

  @override
  String get changelogCurrentVersion => 'Current';

  @override
  String get changelogVersionDetails => 'Release details';

  @override
  String get changelogBodyEmpty => 'No notes for this release.';

  @override
  String get mapPlaceholderDisabled => 'Map (temporarily disabled)';

  @override
  String get moreSectionRegion => 'Region';

  @override
  String get moreSectionNotify => 'Notifications';

  @override
  String get moreSectionDisplay => 'Display';

  @override
  String get regionManageTitle => 'Saved regions';

  @override
  String get regionAddButton => 'Add a region';

  @override
  String get regionEmpty => 'No saved regions yet';

  @override
  String get regionSelectTitle => 'Select a region';

  @override
  String regionSelectCount(int count, int max) {
    return '$count/$max selected';
  }

  @override
  String regionSelectFull(int max) {
    return 'You can save up to $max regions';
  }

  @override
  String get regionEdit => 'Edit';

  @override
  String get moreSectionAdvanced => 'Advanced';

  @override
  String get moreDeveloper => 'Debug info';

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
  String get moreDiscord => 'Discord community';

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
  String get commonFetchFailed => 'Couldn\'t load data. Please try again.';

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
  String get regionNationwide => 'Nationwide';

  @override
  String get regionCurrent => 'Current location';

  @override
  String get regionCurrentUnavailable => 'Can\'t get current location';

  @override
  String get weatherPrecipitation => 'Precipitation';

  @override
  String get weatherHumidity => 'Humidity';

  @override
  String get homeForecastTitle => '24-hour forecast';

  @override
  String homeForecastHighLow(String high, String low) {
    return 'H $high° · L $low°';
  }

  @override
  String homeForecastPop(String pop) {
    return '$pop%';
  }

  @override
  String homeForecastFeelsLike(String temp) {
    return 'Feels like $temp°';
  }

  @override
  String homeForecastHumidity(String value) {
    return 'Humidity $value%';
  }

  @override
  String homeForecastWind(String direction, String level) {
    return '$direction · Force $level';
  }

  @override
  String get homeForecastUnavailable => 'Select a township to see the forecast';

  @override
  String get homeForecastEmpty => 'No forecast available';

  @override
  String get homeActiveEventsTitle => 'Active events';

  @override
  String get homeActiveEventsEmpty => 'No active events';

  @override
  String get homeRainTrendTitle => 'Next hour precipitation';

  @override
  String homeRainTrendMinute(int minute) {
    return '$minute min';
  }

  @override
  String homeRainTrendUpdated(String time) {
    return 'Updated $time';
  }

  @override
  String get homeRainTrendNoData => 'No data';

  @override
  String get homeRainTrendScattered => 'Light showers possible';

  @override
  String get homeRainTrendLightSustained =>
      'Light rain continuing for the next hour';

  @override
  String homeRainTrendLightStopping(int minutes) {
    return 'Light rain likely to stop in $minutes minutes';
  }

  @override
  String get homeRainTrendHeavySustained =>
      'Heavy rain continuing for the next hour';

  @override
  String homeRainTrendHeavyStopping(int minutes) {
    return 'Heavy rain likely to stop in $minutes minutes';
  }

  @override
  String get mapLayers => 'Layers';

  @override
  String get mapLayerOrderTitle => 'Reorder layers';

  @override
  String get mapLayerOrderReset => 'Reset order';

  @override
  String get mapLayerRadar => 'Composite Radar Reflectivity';

  @override
  String get mapLayerSatellite => 'Himawari Infrared (B13)';

  @override
  String get mapLayerSatelliteB01 => 'Himawari Blue (B01)';

  @override
  String get mapLayerSatelliteB02 => 'Himawari Green (B02)';

  @override
  String get mapLayerSatelliteB03 => 'Himawari Red (B03)';

  @override
  String get mapLayerSatelliteB04 => 'Himawari Near-Infrared (B04)';

  @override
  String get mapLayerSatelliteB05 => 'Himawari Near-Infrared (B05)';

  @override
  String get mapLayerSatelliteB06 => 'Himawari Near-Infrared (B06)';

  @override
  String get mapLayerSatelliteB07 => 'Himawari Shortwave Infrared (B07)';

  @override
  String get mapLayerSatelliteB08 => 'Himawari Upper Water Vapour (B08)';

  @override
  String get mapLayerSatelliteB09 => 'Himawari Mid Water Vapour (B09)';

  @override
  String get mapLayerSatelliteB10 => 'Himawari Lower Water Vapour (B10)';

  @override
  String get mapLayerSatelliteB11 => 'Himawari SO₂ / Cloud Phase (B11)';

  @override
  String get mapLayerSatelliteB12 => 'Himawari Ozone (B12)';

  @override
  String get mapLayerSatelliteB13 => 'Himawari Infrared (B13)';

  @override
  String get mapLayerSatelliteB14 => 'Himawari Longwave Infrared (B14)';

  @override
  String get mapLayerSatelliteB15 => 'Himawari Longwave Infrared (B15)';

  @override
  String get mapLayerSatelliteB16 => 'Himawari CO₂ (B16)';

  @override
  String get mapLayerSatelliteTruecolor => 'Himawari True Color';

  @override
  String get mapLayerSatelliteNaturalcolor => 'Himawari Natural Color';

  @override
  String get mapLayerSatelliteAsh => 'Himawari Ash';

  @override
  String get mapLayerSatelliteDust => 'Himawari Dust';

  @override
  String get mapLayerSatelliteAirmass => 'Himawari Airmass';

  @override
  String get mapLayerSatelliteNightmicrophysics =>
      'Himawari Night Microphysics';

  @override
  String get mapLayerSatelliteWatervapor => 'Himawari Water Vapour';

  @override
  String get mapLayerSatelliteBtdSplit => 'Himawari Split Window';

  @override
  String get mapLayerSatelliteBtdFog => 'Himawari Night Fog';

  @override
  String get mapLayerSatelliteBtdWvirw => 'Himawari Overshooting Top';

  @override
  String get mapLayerSatelliteBtdSo2 => 'Himawari SO₂ / Cloud Phase';

  @override
  String get mapLayerSatelliteBtdCo2 => 'Himawari Cirrus / Cloud Height';

  @override
  String get mapLayerSatelliteBtdOzone => 'Himawari Tropopause';

  @override
  String get mapLayerSatelliteCloudtop => 'Himawari Cloud Top Temperature';

  @override
  String get mapLayerSatelliteCloudmask => 'Himawari Cloud Mask';

  @override
  String get mapLayerSatelliteSst => 'Himawari Sea Surface Temperature';

  @override
  String get mapLayerSatelliteNdvi => 'Himawari NDVI';

  @override
  String get mapLayerSatelliteNdwi => 'Himawari NDWI';

  @override
  String get mapLayerSatelliteMndwi => 'Himawari MNDWI';

  @override
  String get mapLayerSatelliteGlobalOutline => 'Country border';

  @override
  String get mapLayerSatelliteRgbComposite => 'RGB composite (JMA recipe)';

  @override
  String get mapLayerSatelliteCloudClear => 'Clear';

  @override
  String get mapLayerSatelliteCloudProbablyClear => 'Probably clear';

  @override
  String get mapLayerSatelliteCloudProbablyCloudy => 'Probably cloudy';

  @override
  String get mapLayerSatelliteCloudCloudy => 'Cloudy';

  @override
  String get mapLayerSatelliteTransparentWarm =>
      'Clear sky (warm end) = transparent, the basemap shows';

  @override
  String get mapLayerSatelliteTransparentReflectance =>
      'Low reflectance / night = transparent, the basemap shows';

  @override
  String get mapLayerSatelliteTransparentZero =>
      'Zero difference = transparent (no signal)';

  @override
  String get mapLayerSatelliteTransparentNight =>
      'Night = transparent, the basemap shows';

  @override
  String get mapLayerSatelliteTransparentNoData =>
      'No data (land) = transparent';

  @override
  String get mapLayerSatelliteTransparentNoVegetation =>
      'Below 0.1 = transparent (no vegetation)';

  @override
  String get mapLayerSatelliteTransparentNoWater =>
      '≤ 0 = transparent (no water)';

  @override
  String get mapLayerSatelliteTransparentClear =>
      'Clear sky = transparent, the basemap shows';

  @override
  String get mapLayerStyleSection => 'Colour style';

  @override
  String get mapLayerStyleTooltip => 'Colour style';

  @override
  String get mapLayerStyleGray => 'Grayscale (JMA)';

  @override
  String get mapLayerStyleGrayTooltip => 'JMA grayscale — colder is whiter';

  @override
  String get mapLayerStyleJma => 'Cloud-top enhancement (JMA)';

  @override
  String get mapLayerStyleJmaTooltip =>
      'Grayscale base, tinted below −40 °C to highlight cloud-top height';

  @override
  String get mapLayerStyleBd => 'Dvorak BD';

  @override
  String get mapLayerStyleBdTooltip =>
      'Dvorak BD curve — the stepped grayscale for tropical-cyclone intensity analysis';

  @override
  String get mapLayerQpesums => '1h Precipitation Forecast';

  @override
  String get mapLayerLightning => 'Lightning';

  @override
  String lightningLegendCg(int minutes) {
    return 'Cloud-to-ground · $minutes min';
  }

  @override
  String lightningLegendCc(int minutes) {
    return 'Cloud-to-cloud · $minutes min';
  }

  @override
  String get mapTimelineNow => 'Now';

  @override
  String get mapTimelinePast => 'Past';

  @override
  String get mapTimelineFuture => 'Future';

  @override
  String get mapTimelineObserved => 'Observed';

  @override
  String get mapTimelineForecast => 'Forecast';

  @override
  String get notifySettingsMenu => 'Notification settings';

  @override
  String get notifyTitle => 'Notifications';

  @override
  String get notifyUnavailable =>
      'Push notifications aren\'t ready yet — try again shortly.';

  @override
  String get notifySetFailed => 'Couldn\'t save the setting. Please try again.';

  @override
  String get notifySectionEew => 'Earthquake early warning';

  @override
  String get notifySectionEarthquake => 'Earthquake';

  @override
  String get notifySectionWeather => 'Weather';

  @override
  String get notifySectionTsunami => 'Tsunami';

  @override
  String get notifySectionOther => 'Other';

  @override
  String get notifyEew => 'Emergency earthquake alert';

  @override
  String get notifyMonitor => 'Strong-motion monitor';

  @override
  String get notifyReport => 'Earthquake report';

  @override
  String get notifyIntensity => 'Intensity report';

  @override
  String get notifyThunderstorm => 'Thunderstorm alerts';

  @override
  String get notifyAdvisory => 'Weather advisories';

  @override
  String get notifyEvacuation => 'Disaster information';

  @override
  String get notifyTsunami => 'Tsunami information';

  @override
  String get notifyAnnouncement => 'Announcements';

  @override
  String get notifyOptOff => 'Off';

  @override
  String get notifyOptAll => 'Receive all';

  @override
  String get notifyOptLocalIntensity4 => 'Local intensity 4 or above';

  @override
  String get notifyOptLocalIntensity1 => 'Local intensity 1 or above';

  @override
  String get notifyOptWeatherLocal => 'Current location only';

  @override
  String get notifyOptTsunamiWarning => 'Tsunami warnings only';

  @override
  String get notifyOptTsunamiAll => 'Tsunami advisories and warnings';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingBack => 'Back';

  @override
  String get onboardingScrollHint => 'Scroll down to continue';

  @override
  String get onboardingIntroTitle => 'Welcome to DPIP';

  @override
  String get onboardingIntroBody =>
      'DPIP is your disaster-prevention companion. It brings together earthquake early warnings, earthquake reports, weather, and hazard information, and alerts you the moment it matters.\n\n• Earthquakes: early warnings, intensity reports, and detailed reports\n• Weather: real-time thunderstorm messages and weather advisories\n• Tsunami and disaster information\n\nNext, we\'ll ask you to review the Terms of Service and grant a few permissions so DPIP can protect you in real time.';

  @override
  String get onboardingTermsTitle => 'Terms of Service';

  @override
  String get onboardingTermsBody =>
      'Please read the following notices before using DPIP:\n\n• All information should defer to the content published by the Central Weather Administration (CWA).\n\n• Depending on network, server, app, and upstream data-source conditions, information may not be received; we make every effort to avoid this but cannot guarantee it never happens.\n\n• Strong shaking may reach your location before the notification does.\n\n• Earthquake early warnings are fast-computed results that may carry significant error — understand this and use them with caution.\n\n• Any behavior not sanctioned by the authorities may carry legal risk; please follow all applicable regulations.\n\nIn addition, to provide localized alerts, this service collects and uploads your approximate location and push identifier — in the foreground and background — solely to decide which alerts to send you.\n\nBy tapping \"Agree and continue\" you confirm that you have read, understood, and agree to the above.';

  @override
  String get onboardingTermsAgree =>
      'I have read and agree to the Terms of Service';

  @override
  String get onboardingAgreeContinue => 'Agree and continue';

  @override
  String get onboardingPermsTitle => 'Permissions';

  @override
  String get onboardingPermsBody =>
      'So DPIP can alert you the moment disaster strikes, please grant the following. You can change these anytime in system settings.';

  @override
  String get onboardingPermNotify => 'Notifications';

  @override
  String get onboardingPermNotifyDesc =>
      'Deliver earthquake, weather, and disaster alerts the moment they happen.';

  @override
  String get onboardingPermCritical => 'Critical alerts';

  @override
  String get onboardingPermCriticalDesc =>
      'Let life-threatening earthquake warnings sound even in silent mode or Do Not Disturb.';

  @override
  String get onboardingPermLocation => 'Location';

  @override
  String get onboardingPermLocationDesc => 'Target alerts to where you are.';

  @override
  String get onboardingPermBackground => 'Background location';

  @override
  String get onboardingPermBackgroundDesc =>
      'Allow \"Always\" so alerts still target you when the app is closed.';

  @override
  String get onboardingPermBattery => 'Battery exemption';

  @override
  String get onboardingPermBatteryDesc =>
      'Allow DPIP to keep running in the background so alerts aren\'t delayed or missed.';

  @override
  String get onboardingGrant => 'Grant';

  @override
  String get onboardingGranted => 'Granted';

  @override
  String get onboardingStart => 'Get started';

  @override
  String get language => 'Language';

  @override
  String get languageSettings => 'Language';

  @override
  String get languageSystem => 'System default';

  @override
  String get locationBannerServiceOff =>
      'Location services are off — local alerts can\'t target your area.';

  @override
  String get locationBannerPermission =>
      'Location permission is off — local alerts can\'t target your area.';

  @override
  String get locationBannerFix => 'Open settings';

  @override
  String get notifyBannerDisabled =>
      'Notifications are off — you won\'t receive disaster alerts.';

  @override
  String get onboardingSkipTitle => 'Permissions not granted';

  @override
  String get onboardingSkipBody =>
      'Without location and notifications, DPIP can\'t alert you to earthquakes and disasters near you in real time. You can still grant them later in Settings.';

  @override
  String get onboardingSkipStay => 'Go back';

  @override
  String get onboardingSkipLeave => 'Skip anyway';

  @override
  String get moreYoutube => 'YouTube';

  @override
  String get moreGithub => 'ExpTech GitHub';

  @override
  String get moreSourceCode => 'Source code';

  @override
  String get moreSectionApp => 'Get the app';

  @override
  String get moreGooglePlay => 'Google Play';

  @override
  String get moreAppStore => 'App Store';

  @override
  String get displaySettings => 'Display';

  @override
  String get defaultMapLayerSettings => 'Default map layer';

  @override
  String get defaultMapLayerSubtitle =>
      'The Map tab opens on this overlay. The bottom-navigation icon and label follow this choice.';

  @override
  String get mapNavRadar => 'Radar';

  @override
  String get mapNavQpesums => 'Forecast';

  @override
  String get mapNavSatellite => 'Satellite';

  @override
  String get mapNavLightning => 'Lightning';

  @override
  String get mapNavTyphoon => 'Typhoon';

  @override
  String get mapNavEarthquake => 'Earthquake';

  @override
  String get mapNavTemperature => 'Temperature';

  @override
  String get mapNavHumidity => 'Humidity';

  @override
  String get mapNavPressure => 'Pressure';

  @override
  String get mapNavWind => 'Wind';

  @override
  String get mapNavRain => 'Rain';

  @override
  String get mapNavDisaster => 'Disaster';

  @override
  String get displayTheme => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get moreSectionAbout => 'About';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get faq => 'FAQ';

  @override
  String get openSourceLicenses => 'Open-source licenses';

  @override
  String get sponsorTitle => 'Support DPIP';

  @override
  String get sponsorIntro =>
      'DPIP is dedicated to real-time disaster-prevention information, with no ads or other revenue model. Your support helps us keep the servers running and keep developing.';

  @override
  String get sponsorSubscriptions => 'Subscriptions';

  @override
  String get sponsorRecommended => 'Recommended';

  @override
  String get sponsorOneTime => 'One-time';

  @override
  String sponsorPerMonth(String price) {
    return '$price / month';
  }

  @override
  String get sponsorRestore => 'Restore purchases';

  @override
  String get sponsorTerms => 'Terms of Use';

  @override
  String get sponsorPrivacy => 'Privacy Policy';

  @override
  String get sponsorRestoring => 'Restoring purchases…';

  @override
  String get sponsorRestoreUnavailable =>
      'Can\'t reach the store. Please try again later.';

  @override
  String get commonClose => 'Close';

  @override
  String get mapLayerTemperature => 'Temperature';

  @override
  String get trendRange24h => '24h';

  @override
  String get trendRange7d => '7d';

  @override
  String get trendNoData => 'No trend data';

  @override
  String trendCumulativeTotal(String total) {
    return 'Cumulative $total mm';
  }

  @override
  String chartHourLabel(int hour) {
    return '${hour}h';
  }

  @override
  String get mapLayerHumidity => 'Humidity';

  @override
  String get mapLayerPressure => 'Pressure';

  @override
  String get mapLayerWind => 'Wind direction';

  @override
  String get mapLayerRain => 'Rainfall';

  @override
  String get rainIntervalMenu => 'Accumulation window';

  @override
  String get rainIntervalNow => 'Today';

  @override
  String get rainInterval10m => '10 min';

  @override
  String get rainInterval1h => '1 h';

  @override
  String get rainInterval3h => '3 h';

  @override
  String get rainInterval6h => '6 h';

  @override
  String get rainInterval12h => '12 h';

  @override
  String get rainInterval24h => '24 h';

  @override
  String get rainInterval2d => '2 d';

  @override
  String get rainInterval3d => '3 d';

  @override
  String get mapLayerTyphoon => 'Typhoon';

  @override
  String get typhoonNoActive => 'No active typhoon';

  @override
  String get typhoonWind => 'Wind';

  @override
  String get typhoonGust => 'Gust';

  @override
  String get typhoonPressure => 'Pressure';

  @override
  String get typhoonMotion => 'Moving';

  @override
  String get typhoonLabelPosition => 'Centre location';

  @override
  String get typhoonLabelDirection => 'Past movement direction';

  @override
  String get typhoonLabelSpeed => 'Past movement speed';

  @override
  String get typhoonLabelPressure => 'Central pressure';

  @override
  String get typhoonLabelWind => 'Max. sustained wind near centre';

  @override
  String get typhoonLabelGust => 'Peak gust';

  @override
  String get typhoonLabelGaleAvg => 'Avg. radius of Beaufort 7 winds';

  @override
  String get typhoonLabelStormAvg => 'Avg. radius of Beaufort 10 winds';

  @override
  String get typhoonLabelProbCircle => '70% probability circle';

  @override
  String typhoonForecastLead(String hours) {
    return 'Forecast +$hours h';
  }

  @override
  String get typhoonLabelNw => 'NW';

  @override
  String get typhoonLabelNe => 'NE';

  @override
  String get typhoonLabelSw => 'SW';

  @override
  String get typhoonLabelSe => 'SE';

  @override
  String typhoonValueLat(String lat) {
    return '$lat°N';
  }

  @override
  String typhoonValueLon(String lon) {
    return '$lon°E';
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
    return '$n m/s';
  }

  @override
  String typhoonDataTime(String time) {
    return 'Data time\n$time';
  }

  @override
  String get mapLayerWindForecastEcmwf => 'ECMWF';

  @override
  String get mapLayerWindForecastGfs => 'GFS';

  @override
  String get mapLayerMonitor => 'Seismic Monitor';

  @override
  String get mapLayerDisasterMap => 'Disaster Map';

  @override
  String get mapLayerAed => 'AED';

  @override
  String get disasterMapOverlayMenuTooltip => 'Disaster map layers';

  @override
  String get disasterMapOverlaySectionLayers => 'Layers';

  @override
  String get disasterMapOverlayAedTooltip => 'Show AED locations';

  @override
  String get aedAddress => 'Address';

  @override
  String get aedRegion => 'Region';

  @override
  String get aedCategory => 'Category';

  @override
  String get aedType => 'Type';

  @override
  String get aedPlaceDesc => 'Placement';

  @override
  String get aedDescription => 'Notes';

  @override
  String get aedHoursWeekday => 'Weekday hours';

  @override
  String get aedHoursSaturday => 'Saturday hours';

  @override
  String get aedHoursSunday => 'Sunday hours';

  @override
  String get aedOpenRemark => 'Hours note';

  @override
  String get aedEmergencyPhone => 'Emergency phone';

  @override
  String get mapLayerRestroom => 'Restrooms';

  @override
  String get mapLayerShelter => 'Shelters';

  @override
  String get disasterMapOverlayRestroomTooltip => 'Show public restrooms';

  @override
  String get disasterMapOverlayShelterTooltip => 'Show evacuation shelters';

  @override
  String get dpmOpenInMaps => 'Open in maps';

  @override
  String get mapAppGoogleMaps => 'Google Maps';

  @override
  String get mapAppAppleMaps => 'Apple Maps';

  @override
  String mapAppDefault(String app) {
    return '$app (default)';
  }

  @override
  String get mapAppCopyCoordinates => 'Copy coordinates';

  @override
  String get mapAppCoordinatesCopied => 'Coordinates copied';

  @override
  String mapAppOpenFailed(String app) {
    return 'Could not open $app';
  }

  @override
  String get mapOverlaySectionReference => 'Reference layers';

  @override
  String get mapLayerCategoryEarthquake => 'Earthquake';

  @override
  String get mapLayerCategoryTyphoon => 'Typhoon';

  @override
  String get mapLayerCategoryWeather => 'Weather observations';

  @override
  String get mapLayerCategorySatellite => 'Satellite';

  @override
  String get mapLayerCategoryRadar => 'Radar';

  @override
  String get mapLayerCategoryLife => 'Daily life';

  @override
  String get mapLayerCategoryForecast => 'Numerical forecast';

  @override
  String get mapOverlaySectionMap => 'Map';

  @override
  String get rainIntervalSection => 'Time window';

  @override
  String get mapTownLabels => 'Township names';

  @override
  String get mapTownLabelsHint => 'Show township names when zoomed in';

  @override
  String get dpmSheetEmpty => 'Tap a marker on the map for details';

  @override
  String get dpmAddress => 'Address';

  @override
  String get restroomTypeLabel => 'Type';

  @override
  String get restroomCategoryLabel => 'Category';

  @override
  String get restroomGradeLabel => 'Grade';

  @override
  String get restroomTypeFemale => 'Female';

  @override
  String get restroomTypeMale => 'Male';

  @override
  String get restroomTypeMixed => 'Mixed';

  @override
  String get restroomTypeAccessible => 'Accessible';

  @override
  String get restroomTypeGenderNeutral => 'Gender-neutral';

  @override
  String get restroomTypeFamily => 'Family';

  @override
  String get restroomTypeUnspecified => 'Unspecified';

  @override
  String get restroomCategoryTransport => 'Transport';

  @override
  String get restroomCategoryPark => 'Park';

  @override
  String get restroomCategoryCommercial => 'Commercial';

  @override
  String get restroomCategoryReligious => 'Religious';

  @override
  String get restroomCategoryCultural => 'Cultural';

  @override
  String get restroomCategoryGovernment => 'Government';

  @override
  String get restroomCategoryWelfare => 'Welfare';

  @override
  String get restroomCategoryTourist => 'Tourist';

  @override
  String get restroomCategoryLeisure => 'Leisure';

  @override
  String get restroomCategoryOther => 'Other';

  @override
  String get restroomGradeExcellent => 'Excellent';

  @override
  String get restroomGradeGood => 'Good';

  @override
  String get restroomGradeAverage => 'Average';

  @override
  String get restroomGradePoor => 'Below standard';

  @override
  String get shelterAddressLabel => 'Address';

  @override
  String get shelterCapacityLabel => 'Capacity';

  @override
  String shelterCapacityValue(int n) {
    return '$n people';
  }

  @override
  String get shelterCategoryLabel => 'Disaster types';

  @override
  String get shelterIndoorLabel => 'Indoor shelter';

  @override
  String get shelterOutdoorLabel => 'Outdoor shelter';

  @override
  String get shelterVulnerableOkLabel => 'Vulnerable-people friendly';

  @override
  String get dpmYes => 'Yes';

  @override
  String get dpmNo => 'No';

  @override
  String get stationSheetEmpty => 'Tap a station to see its reading';

  @override
  String monitorDelay(String value) {
    return 'Delay $value s';
  }

  @override
  String get monitorWaiting => 'Waiting for data…';

  @override
  String mapLegendUnit(String unit) {
    return 'Unit: $unit';
  }

  @override
  String get typhoonLegendPast => 'Observed track';

  @override
  String get typhoonIntensityTd => 'Tropical depression';

  @override
  String typhoonPickerNamed(String no, String name) {
    return '$name TY $no';
  }

  @override
  String typhoonPickerTd(String no) {
    return 'Tropical depression TD $no';
  }

  @override
  String get typhoonIntensityMild => 'Mild typhoon';

  @override
  String get typhoonIntensityModerate => 'Moderate typhoon';

  @override
  String get typhoonIntensityIntense => 'Intense typhoon';

  @override
  String get typhoonLegendForecast => 'Forecast track';

  @override
  String get typhoonLegendForecastPoint => 'Forecast point';

  @override
  String get typhoonLegendCurrent => 'Current centre';

  @override
  String get typhoonLegendCone => 'Forecast cone';

  @override
  String get mapLegendExpand => 'Legend';

  @override
  String get mapLegendCollapse => 'Hide legend';

  @override
  String get mapMyLocation => 'My location';

  @override
  String get mapResetNorth => 'Reset north';

  @override
  String get typhoonLegendCircle15 => 'Gale circle (L7)';

  @override
  String get typhoonLegendCircleAvg => 'Average circle';

  @override
  String get typhoonLegendCircle25 => 'Storm circle (L10)';

  @override
  String typhoonStormRadii(String ne, String se, String sw, String nw) {
    return 'NE $ne · SE $se · SW $sw · NW $nw km';
  }

  @override
  String typhoonTimeChip(String day, String hour) {
    return '$day日$hour時';
  }

  @override
  String get typhoonLegendProbability => 'Strike probability';

  @override
  String get typhoonLegendWarningAreas => 'Warning areas';

  @override
  String get typhoonOverlayMenuTooltip => 'Typhoon overlay options';

  @override
  String get typhoonOverlaySectionStorm => 'Storm wind';

  @override
  String get typhoonOverlaySectionExtra => 'Overlays';

  @override
  String get typhoonOverlayStormBandSubtitle => 'With average circle';

  @override
  String get typhoonOverlayProbabilityHint => 'Hides the forecast cone';

  @override
  String get typhoonOverlayProbabilityTooltip =>
      'Show strike probability (hides the forecast cone)';

  @override
  String get typhoonOverlayWarningTooltip =>
      'Highlight counties under a typhoon warning';

  @override
  String get typhoonOverlayStormL7Tooltip =>
      'Level-7 wind field + average circle (purple)';

  @override
  String get typhoonOverlayStormL10Tooltip =>
      'Level-10 wind field + average circle (yellow)';

  @override
  String get typhoonOverlaySectionWeather => 'Weather underlay';

  @override
  String get typhoonOverlayWeatherNone => 'None';

  @override
  String get typhoonOverlayWeatherHint => 'Aligned to bulletin time';

  @override
  String get typhoonOverlayWeatherNoneTooltip =>
      'No radar or infrared underlay';

  @override
  String get typhoonOverlayWeatherRadarTooltip =>
      'Radar echo closest to the typhoon bulletin time';

  @override
  String get typhoonOverlayWeatherSatelliteTooltip =>
      'Infrared closest to the typhoon bulletin time';

  @override
  String get typhoonWarningTitle => 'Typhoon warning';

  @override
  String typhoonWarningAreas(String areas) {
    return 'Areas: $areas';
  }

  @override
  String get typhoonTrackDetail => 'Track detail';

  @override
  String get typhoonHistoryTitle => 'Dataset time';

  @override
  String get typhoonHistoryLive => 'Live';

  @override
  String get typhoonSatelliteTitle => 'Satellite';

  @override
  String get typhoonOverlayForecastCallouts => 'Forecast tooltips';

  @override
  String get typhoonOverlayForecastCalloutsTooltip =>
      'Show forecast-point detail cards when zoomed in';

  @override
  String get dpmFilterSectionRestroom => 'Venue types';

  @override
  String get dpmFilterSectionRestroomType => 'Toilet types';

  @override
  String get dpmFilterSectionShelter => 'Shelter disaster types';

  @override
  String get dpmDisasterFlood => 'Flood';

  @override
  String get dpmDisasterEarthquake => 'Earthquake';

  @override
  String get dpmDisasterLandslide => 'Landslide';

  @override
  String get dpmDisasterTsunami => 'Tsunami';

  @override
  String get dpmDisasterSlope => 'Slope hazard';

  @override
  String get dpmDisasterNuclear => 'Nuclear accident';

  @override
  String get skyTime => 'Sky time';

  @override
  String get skyTimeAuto => 'Auto';

  @override
  String get skyTimeDawn => 'Dawn';

  @override
  String get skyTimeSunrise => 'Sunrise';

  @override
  String get skyTimeMorning => 'Morning';

  @override
  String get skyTimeNoon => 'Noon';

  @override
  String get skyTimeAfternoon => 'Afternoon';

  @override
  String get skyTimeGolden => 'Golden hour';

  @override
  String get skyTimeSunset => 'Sunset';

  @override
  String get skyTimeDusk => 'Dusk';

  @override
  String get skyTimeNight => 'Night';

  @override
  String get weatherModeCloudy => 'Cloudy';

  @override
  String get weatherModeOvercast => 'Overcast';

  @override
  String get weatherModeSnow => 'Snow';

  @override
  String get weatherModeSand => 'Dust';

  @override
  String get radarScanRange => 'Show scan range';

  @override
  String get radarScanRangeSubtitle =>
      'Outlines the area the four radars actually observe.';

  @override
  String get radarScanRangeHint => 'Blank outside means unobserved';

  @override
  String get radarOverlayMenuTooltip => 'Radar overlay options';

  @override
  String get radarCountyOutline => 'County borders';

  @override
  String get radarGlobalOutline => 'National borders';

  @override
  String get radarGlobalOutlineHint => 'Every country\'s outer frame';

  @override
  String get radarCountyOutlineHint => 'Drawn over the echo';

  @override
  String get radarCountyOutlineSubtitle =>
      'Keeps county borders legible under the radar echo.';

  @override
  String get radarTownOutline => 'Township borders';

  @override
  String get radarTownOutlineHint => 'The finer mesh';

  @override
  String get radarTownOutlineSubtitle =>
      'Keeps township borders legible under the radar echo.';

  @override
  String get qpesumsOverlayMenuTooltip => 'QPESUMS overlay options';

  @override
  String get windForecastOverlayMenuTooltip => 'Wind forecast overlay options';

  @override
  String get windForecastCountyOutlineHint => 'Drawn over the wind field';

  @override
  String get windForecastGlobalOutlineHint => 'Every country\'s outer frame';

  @override
  String get windForecastTownOutlineHint => 'The finer mesh';
}
