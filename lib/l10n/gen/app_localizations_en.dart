// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String typhoonValueLat(String lat) {
    return '$lat°N';
  }

  @override
  String get onboardingSkipBody =>
      'Without location and notifications, DPIP can\'t alert you to earthquakes and disasters near you in real time. You can still grant them later in Settings.';

  @override
  String get rainInterval24h => '24 h';

  @override
  String homeRainTrendHeavyStopping(int minutes) {
    return 'Heavy rain likely to stop in $minutes minutes';
  }

  @override
  String get mapTimelineObserved => 'Observed';

  @override
  String get mapTimelineScrubPaused =>
      'Frame updates paused because you\'re scrubbing too fast. Slow down to resume.';

  @override
  String get regionSelectTitle => 'Select a region';

  @override
  String get skyTimeNoon => 'Noon';

  @override
  String get radarCountyOutlineSubtitle =>
      'Keeps county borders legible under the radar echo.';

  @override
  String get mapLayerSatelliteB03 => 'Himawari Red (B03)';

  @override
  String get reportFilterIntensity => 'Intensity';

  @override
  String get mapLayerLightning => 'Lightning';

  @override
  String get restroomTypeMale => 'Male';

  @override
  String get meshtasticLastReceived => 'Last received';

  @override
  String get reportDetailSortByCounty => 'Sort by county';

  @override
  String get onboardingPermUnusedApp => 'Keep app active';

  @override
  String get onboardingPermUnusedAppDesc =>
      'Android pauses apps you haven\'t opened in a while and revokes their permissions — which stops disaster alerts reaching your area.';

  @override
  String get onboardingPermBackgroundExec => 'Background activity';

  @override
  String get onboardingPermBackgroundExecDesc =>
      'Without this the app is never woken to report where you are.';

  @override
  String get onboardingPermVendorPower => 'Manufacturer battery settings';

  @override
  String onboardingPermVendorPowerDesc(String brand) {
    return '$brand stops background work for apps you have not opened recently. The app cannot detect or change this — please allow it by hand.';
  }

  @override
  String get homeRainTrendScattered => 'Light showers possible';

  @override
  String get meshtasticUptime => 'Uptime';

  @override
  String get weatherRankingTempExtremes => 'Daily extremes';

  @override
  String get themeLight => 'Light';

  @override
  String get mapTerrainReliefHint =>
      'Show shaded terrain relief on the base map';

  @override
  String get meshtasticEmptyMessage => '(empty message)';

  @override
  String get moreSectionRegion => 'Region';

  @override
  String get mapLayerSatellite => 'Himawari Infrared (B13)';

  @override
  String get aedHoursSaturday => 'Saturday hours';

  @override
  String get moonPhaseNew => 'New moon';

  @override
  String get notifySectionEew => 'Earthquake early warning';

  @override
  String get mapResetNorth => 'Reset north';

  @override
  String get rainInterval2d => '2 d';

  @override
  String get mapTownLabelsHint => 'Show township names when zoomed in';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get notifyOptTsunamiWarning => 'Tsunami warnings only';

  @override
  String get mapLayerSatelliteBtdFog => 'Himawari Night Fog';

  @override
  String get moreSectionAdvanced => 'Advanced';

  @override
  String get moreSectionMesh => 'Mesh network';

  @override
  String get weatherRankingExtremeRange => 'Diurnal range';

  @override
  String get permissionsTitle => 'Permission check';

  @override
  String get permissionsAttention => 'Permissions need attention';

  @override
  String get permissionsBody =>
      'DPIP needs these permissions to alert you in time. A missing one is the usual reason an alert never arrived.';

  @override
  String get notifySettingsMenu => 'Notification settings';

  @override
  String mapAppDefault(String app) {
    return '$app (default)';
  }

  @override
  String get trendRange24h => '24h';

  @override
  String get mapLayerStyleJmaTooltip =>
      'Grayscale base, tinted below −40 °C to highlight cloud-top height';

  @override
  String get mapLayerRain => 'Rainfall';

  @override
  String get mapLayerQpesums => '1h Precipitation Forecast';

  @override
  String get mapOverlaySectionMap => 'Map';

  @override
  String get mapTerrainRelief => 'Terrain relief';

  @override
  String get mapLegendCollapse => 'Hide legend';

  @override
  String get updateAvailableTitle => 'Update available';

  @override
  String updateAvailableBody(String version) {
    return 'Version $version is out.';
  }

  @override
  String get updateSkip => 'Skip this one';

  @override
  String get updateViewChangelog => 'View changes';

  @override
  String get updateOpenAppStore => 'App Store';

  @override
  String get updateOpenTestFlight => 'TestFlight';

  @override
  String get updateOpenPlayStore => 'Play Store';

  @override
  String get updateDownload => 'Download';

  @override
  String get changelogShowSnapshots => 'Show snapshots';

  @override
  String get changelogTitle => 'Changelog';

  @override
  String get reportFilterOrderDesc => 'Descending';

  @override
  String get meshtasticExcludeMqttSubtitle =>
      'Nodes bridged over the internet, not heard by radio';

  @override
  String get reportFilterIntensityInfoTitle => 'Intensity scales';

  @override
  String get mapLayerTyphoon => 'Typhoon';

  @override
  String get radarOverlayMenuTooltip => 'Radar overlay options';

  @override
  String get meshtasticNodes => 'Nodes';

  @override
  String get meshtasticSend => 'Send';

  @override
  String get typhoonOverlayStormL7Tooltip =>
      'Level-7 wind field + average circle (purple)';

  @override
  String get aedType => 'Type';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get typhoonLegendCircle25 => 'Storm circle (L10)';

  @override
  String get sponsorTitle => 'Support DPIP';

  @override
  String get mapNavSatellite => 'Satellite';

  @override
  String homeRainTrendUpdated(String time) {
    return 'Updated $time';
  }

  @override
  String get onboardingNext => 'Next';

  @override
  String get weatherRankingMergeTown => 'Township';

  @override
  String get mapLayerMonitor => 'Seismic Monitor';

  @override
  String get moreYoutube => 'YouTube';

  @override
  String get sponsorSubscriptions => 'Subscriptions';

  @override
  String typhoonValueLon(String lon) {
    return '$lon°E';
  }

  @override
  String get skyTime => 'Sky time';

  @override
  String get weatherModeCloudy => 'Cloudy';

  @override
  String get skyTimeDusk => 'Dusk';

  @override
  String get meshtasticFirmware => 'Firmware';

  @override
  String get reportFilterDateEndNote => 'End day: through 24:00 (Taipei)';

  @override
  String get reportFilterSortMagnitude => 'Magnitude';

  @override
  String get meshtasticSilent => 'Silent';

  @override
  String get mapLayerCategoryEarthquake => 'Earthquake';

  @override
  String get mapLayerSatelliteB12 => 'Himawari Ozone (B12)';

  @override
  String get restroomCategoryOther => 'Other';

  @override
  String homeForecastHighLow(String high, String low) {
    return 'H $high° · L $low°';
  }

  @override
  String get locationBannerFix => 'Open settings';

  @override
  String get mapLegendExpand => 'Legend';

  @override
  String get eewNone => 'No active earthquake early warning';

  @override
  String typhoonTyNo(String no) {
    return 'TY $no';
  }

  @override
  String get notifyOptTsunamiAll => 'Tsunami advisories and warnings';

  @override
  String get meshtasticLayerOptions => 'Node options';

  @override
  String get onboardingAgreeContinue => 'Agree and continue';

  @override
  String get commonRetry => 'Retry';

  @override
  String get meshtasticNodeId => 'Node ID';

  @override
  String reportDetailNumbered(String number) {
    return 'No. $number Significant Earthquake';
  }

  @override
  String get typhoonOverlayStormBandSubtitle => 'With average circle';

  @override
  String get disasterMapOverlayRestroomTooltip => 'Show public restrooms';

  @override
  String get weatherRankingTitle => 'Observation rankings';

  @override
  String get homeRainTrendHeavySustained =>
      'Heavy rain continuing for the next hour';

  @override
  String get notifySectionTsunami => 'Tsunami';

  @override
  String get restroomCategoryPark => 'Park';

  @override
  String get moreLinkOpenFailed => 'Couldn\'t open the link';

  @override
  String get themeDark => 'Dark';

  @override
  String get sponsorRestore => 'Restore purchases';

  @override
  String get meshtasticChannelWorking => 'Setting up the DPIP channel…';

  @override
  String get meshtasticRegionSwitch => 'Switch to TW';

  @override
  String get meshtasticTraffic => 'Traffic';

  @override
  String get mapLayerStyleBdTooltip =>
      'Dvorak BD curve — the stepped grayscale for tropical-cyclone intensity analysis';

  @override
  String get disasterMapOverlayAedTooltip => 'Show AED locations';

  @override
  String get mapLayerHumidity => 'Humidity';

  @override
  String get mapLayerSatelliteTransparentNight =>
      'Night = transparent, the basemap shows';

  @override
  String get meshtasticScanning => 'Scanning…';

  @override
  String regionSelectFull(int max) {
    return 'You can save up to $max regions';
  }

  @override
  String get meshtasticNewMessages => 'NEW';

  @override
  String get meshtasticBatteryHistory => 'Battery history';

  @override
  String get meshtasticStatAvg => 'avg';

  @override
  String get meshtasticStatPeak => 'peak';

  @override
  String get meshtasticStatDrain => 'drain';

  @override
  String get meshtasticStatEta => 'lasts';

  @override
  String get meshtasticStatFull => 'full in';

  @override
  String get meshtasticStatTrend => 'trend';

  @override
  String get meshtasticStatCharging => 'charging';

  @override
  String get meshtasticStatStable => 'stable';

  @override
  String get meshtasticNodesTotal => 'Known';

  @override
  String get meshtasticNodesOnline => 'Online';

  @override
  String get meshtasticRx => 'Received';

  @override
  String get meshtasticTx => 'Sent';

  @override
  String get meshtasticNodesHistory => 'Node history';

  @override
  String get meshtasticTrafficHistory => 'Traffic history';

  @override
  String meshtasticEtaHours(int n) {
    return '~${n}h';
  }

  @override
  String meshtasticEtaDays(int n) {
    return '~${n}d';
  }

  @override
  String get meshtasticTitle => 'Meshtastic';

  @override
  String get navMore => 'More';

  @override
  String get meshtasticDpipChannel => 'DPIP channel';

  @override
  String get disasterMapOverlaySectionLayers => 'Layers';

  @override
  String get mapLayerSatelliteB05 => 'Himawari Near-Infrared (B05)';

  @override
  String get typhoonLabelNe => 'NE';

  @override
  String get meshtasticCopied => 'Message copied';

  @override
  String get reportListEmpty => 'No earthquake reports';

  @override
  String get reportListEnd => 'End of list';

  @override
  String get mapLayerSatelliteTruecolor => 'Himawari True Color';

  @override
  String get typhoonOverlaySectionExtra => 'Overlays';

  @override
  String get eewSWave => 'S-wave';

  @override
  String get meshtasticBusyTitle => 'Another app is using this radio';

  @override
  String get restroomCategoryCultural => 'Cultural';

  @override
  String get typhoonLabelWind => 'Max. sustained wind near centre';

  @override
  String get radarGlobalOutlineHint => 'Every country\'s outer frame';

  @override
  String get notifyEvacuation => 'Disaster information';

  @override
  String get typhoonLegendCircle15 => 'Gale circle (L7)';

  @override
  String get dataSectionAstronomy => 'Astronomy';

  @override
  String get homeRainTrendLightSustained =>
      'Light rain continuing for the next hour';

  @override
  String get commonError => 'Something went wrong';

  @override
  String get moonPhaseWaningCrescent => 'Waning crescent';

  @override
  String get meshtasticPower => 'Power';

  @override
  String get mapTimelineNow => 'Now';

  @override
  String reportFilterRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String get reportDetailOpenReport => 'Report page';

  @override
  String get trendRange7d => '7d';

  @override
  String typhoonWarningAreas(String areas) {
    return 'Areas: $areas';
  }

  @override
  String get rainIntervalSection => 'Time window';

  @override
  String get notifyTitle => 'Notifications';

  @override
  String get meshtasticTxPower => 'TX power';

  @override
  String get restroomCategoryLabel => 'Category';

  @override
  String get sponsorRestoring => 'Restoring purchases…';

  @override
  String get sponsorIntro =>
      'DPIP is dedicated to real-time disaster-prevention information, with no ads or other revenue model. Your support helps us keep the servers running and keep developing.';

  @override
  String get typhoonLabelStormAvg => 'Avg. radius of Beaufort 10 winds';

  @override
  String get restroomCategoryCommercial => 'Commercial';

  @override
  String get aedRegion => 'Region';

  @override
  String homeRainTrendLightStopping(int minutes) {
    return 'Light rain likely to stop in $minutes minutes';
  }

  @override
  String get reportDetailInfo => 'Details';

  @override
  String get mapNavWind => 'Wind';

  @override
  String get windForecastOverlayMenuTooltip => 'Wind forecast overlay options';

  @override
  String homeRainTrendMinute(int minute) {
    return '$minute min';
  }

  @override
  String get rainInterval6h => '6 h';

  @override
  String get restroomTypeUnspecified => 'Unspecified';

  @override
  String get typhoonOverlayProbabilityHint => 'Hides the forecast cone';

  @override
  String get mapLayerSatelliteGlobalOutline => 'Country border';

  @override
  String get mapNavTemperature => 'Temperature';

  @override
  String get typhoonLegendForecastPoint => 'Forecast point';

  @override
  String get reportListYesterday => 'Yesterday';

  @override
  String get moreSectionLinks => 'Links';

  @override
  String get feedOffline => 'Connection lost';

  @override
  String get mapLayerStyleBd => 'Dvorak BD';

  @override
  String get moreSectionDisplay => 'Display';

  @override
  String get rainInterval3d => '3 d';

  @override
  String get defaultMapLayerSubtitle =>
      'The Map tab opens on this overlay. The bottom-navigation icon and label follow this choice.';

  @override
  String get aedDescription => 'Notes';

  @override
  String get typhoonOverlayWeatherRadarTooltip =>
      'Radar echo closest to the typhoon bulletin time';

  @override
  String get onboardingPermLocationDesc => 'Target alerts to where you are.';

  @override
  String get mapLayerSatelliteB16 => 'Himawari CO₂ (B16)';

  @override
  String get homeActiveEventsEmpty => 'No active events';

  @override
  String get typhoonLabelPosition => 'Centre location';

  @override
  String get weatherRankingBy => 'Sort by';

  @override
  String get typhoonIntensityMild => 'Mild typhoon';

  @override
  String get windForecastGlobalOutlineHint => 'Every country\'s outer frame';

  @override
  String get rainInterval1h => '1 h';

  @override
  String get eewLocalIntensity => 'Estimated at my location';

  @override
  String get mapLayerRadar => 'Composite Radar Reflectivity';

  @override
  String get restroomCategoryReligious => 'Religious';

  @override
  String get meshtasticRole => 'Role';

  @override
  String get mapLayerSatelliteCloudCloudy => 'Cloudy';

  @override
  String get skyTimeSunrise => 'Sunrise';

  @override
  String get meshtasticJumpToLatest => 'Jump to latest';

  @override
  String get meshtasticNoMessages => 'No messages yet';

  @override
  String get onboardingPermNotifyDesc =>
      'Deliver earthquake, weather, and disaster alerts the moment they happen.';

  @override
  String get radarTownOutline => 'Township borders';

  @override
  String get mapLayerStyleSection => 'Colour style';

  @override
  String get disasterMapOverlayMenuTooltip => 'Disaster map layers';

  @override
  String get moreGooglePlay => 'Google Play';

  @override
  String get meshtasticOnline => 'Heard recently';

  @override
  String get typhoonLabelSw => 'SW';

  @override
  String typhoonForecastLead(String hours) {
    return 'Forecast +$hours h';
  }

  @override
  String get changelogTypeStable => 'Stable';

  @override
  String get mapLayerSatelliteTransparentClear =>
      'Clear sky = transparent, the basemap shows';

  @override
  String get mapOverlaySectionReference => 'Reference layers';

  @override
  String get mapLayerSatelliteB02 => 'Himawari Green (B02)';

  @override
  String get weatherRankingEmpty => 'No observations to rank';

  @override
  String get notifySectionOther => 'Other';

  @override
  String weatherRankingMeta(String time, int count) {
    return 'Data time: $time\n$count stations';
  }

  @override
  String get onboardingTermsAgree =>
      'I have read and agree to the Terms of Service';

  @override
  String get mapLayerSatelliteTransparentNoVegetation =>
      'Below 0.1 = transparent (no vegetation)';

  @override
  String get notifyOptLocalIntensity4 => 'Local intensity 4 or above';

  @override
  String get eewArrived => 'Arrived';

  @override
  String get meshtasticNoDevices => 'No Meshtastic devices found';

  @override
  String get mapLayerCategoryLife => 'Daily life';

  @override
  String get reportFilterSortIntensity => 'Intensity';

  @override
  String get meshtasticStateDisconnected => 'Disconnected';

  @override
  String get typhoonIntensityIntense => 'Intense typhoon';

  @override
  String get mapLayerOrderTitle => 'Reorder layers';

  @override
  String get mapLayerShow => 'Show layer';

  @override
  String get mapLayerHide => 'Hide layer';

  @override
  String get mapLayerShowAll => 'Show all';

  @override
  String get mapLayerHideAll => 'Hide all';

  @override
  String get dpmYes => 'Yes';

  @override
  String get meshtasticNoHistory => 'Not enough history yet';

  @override
  String get reportDetailLocalIntensityUnavailable => 'No intensity data';

  @override
  String get mapLayerWindForecastGfs => 'GFS';

  @override
  String get reportFilterDepth => 'Depth';

  @override
  String get onboardingScrollHint => 'Scroll down to continue';

  @override
  String get mapNavQpesums => 'Forecast';

  @override
  String get notifyAdvisory => 'Weather advisories';

  @override
  String get reportFilterReset => 'Reset';

  @override
  String get mapLayerSatelliteMndwi => 'Himawari MNDWI';

  @override
  String get typhoonOverlaySectionStorm => 'Storm wind';

  @override
  String get moonPhaseFull => 'Full moon';

  @override
  String meshtasticBinaryPayload(String size) {
    return 'Binary payload · $size';
  }

  @override
  String get moonPhaseWaningGibbous => 'Waning gibbous';

  @override
  String get reportFilterIntensityInfoModernTitle => 'Current (from 2020)';

  @override
  String typhoonDataTime(String time) {
    return 'Data time\n$time';
  }

  @override
  String get restroomTypeAccessible => 'Accessible';

  @override
  String get moreSectionAbout => 'About';

  @override
  String get meshtasticSelectDevice => 'Select a radio';

  @override
  String get onboardingIntroBody =>
      'DPIP is your disaster-prevention companion. It brings together earthquake early warnings, earthquake reports, weather, and hazard information, and alerts you the moment it matters.\n\n• Earthquakes: early warnings, intensity reports, and detailed reports\n• Weather: real-time thunderstorm messages and weather advisories\n• Tsunami and disaster information\n\nNext, we\'ll ask you to review the Terms of Service and grant a few permissions so DPIP can protect you in real time.';

  @override
  String get shelterCapacityLabel => 'Capacity';

  @override
  String get reportDetailImage => 'Report image';

  @override
  String get meshtasticStateConfiguring => 'Configuring…';

  @override
  String get typhoonLabelGaleAvg => 'Avg. radius of Beaufort 7 winds';

  @override
  String get onboardingPermNotify => 'Notifications';

  @override
  String get meshtasticClearMessages => 'Clear messages';

  @override
  String get meshtasticNotifyMessages => 'Notify on new messages';

  @override
  String get defaultMapLayerSettings => 'Default map layer';

  @override
  String get eewSourceSettings => 'EEW source';

  @override
  String get eewSourceSubtitle =>
      'Choose which agencies\' earthquake early warnings the app shows.';

  @override
  String get eewSourceAll => 'All sources';

  @override
  String get eewSourceAllDescription =>
      'Show earthquake early warnings from every publishing agency.';

  @override
  String get eewSourceCwaOnly => 'CWA only';

  @override
  String get eewSourceCwaOnlyDescription =>
      'Show only earthquake early warnings published by Taiwan\'s Central Weather Administration (CWA).';

  @override
  String get moreSectionNotify => 'Notifications';

  @override
  String get notifyUnavailable =>
      'Push notifications aren\'t ready yet — try again shortly.';

  @override
  String get mapLayerOrderReset => 'Reset order';

  @override
  String get weatherRankingMergeCounty => 'County';

  @override
  String get moreSectionApp => 'Get the app';

  @override
  String get moreSectionBeta => 'Beta';

  @override
  String get moreAndroidBeta => 'Android beta';

  @override
  String get moreTestFlight => 'iOS beta (TestFlight)';

  @override
  String get moreSectionPartners => 'Partners';

  @override
  String get morePartnersNote =>
      'Listed in order of partnership. Thank you to the individuals and companies whose contributions to disaster preparedness made DPIP possible.';

  @override
  String get morePartnerGeoscience => 'Geoscience';

  @override
  String get morePartnerTwds => 'TWDS';

  @override
  String get reportFilterIntensityInfoLegacyBody =>
      'Only levels 0–7. No 5− / 5+ / 6− / 6+ split.';

  @override
  String get mapLayerSatelliteSst => 'Himawari Sea Surface Temperature';

  @override
  String get qpesumsOverlayMenuTooltip => 'QPESUMS overlay options';

  @override
  String get mapTimelineFuture => 'Future';

  @override
  String get typhoonLegendCircleAvg => 'Average circle';

  @override
  String reportFilterDepthKm(String depth) {
    return '$depth km';
  }

  @override
  String get typhoonLabelSe => 'SE';

  @override
  String get radarTownOutlineHint => 'The finer mesh';

  @override
  String eewCountdown(int seconds) {
    return '$seconds s';
  }

  @override
  String get typhoonLabelGust => 'Peak gust';

  @override
  String get mapAppGoogleMaps => 'Google Maps';

  @override
  String get sponsorTerms => 'Terms of Use';

  @override
  String get restroomTypeGenderNeutral => 'Gender-neutral';

  @override
  String get notifyThunderstorm => 'Thunderstorm alerts';

  @override
  String get skyTimeGolden => 'Golden hour';

  @override
  String get moonAge => 'Age';

  @override
  String get meshtasticRadioSettings => 'LoRa';

  @override
  String get moreGithub => 'ExpTech GitHub';

  @override
  String get homeForecastUnavailable => 'Select a township to see the forecast';

  @override
  String get mapLayers => 'Layers';

  @override
  String get meshtasticHardware => 'Hardware';

  @override
  String get languageSettings => 'Language';

  @override
  String get language => 'Language';

  @override
  String homeForecastFeelsLike(String temp) {
    return 'Feels like $temp°';
  }

  @override
  String get typhoonOverlayWeatherHint => 'Aligned to bulletin time';

  @override
  String get skyTimeDawn => 'Dawn';

  @override
  String get skyTimeAfternoon => 'Afternoon';

  @override
  String get meshtasticLastHeard => 'Last heard';

  @override
  String get typhoonWarningTitle => 'Typhoon warning';

  @override
  String get moreSourceCode => 'Source code';

  @override
  String get mapLayerCategoryWeather => 'Weather observations';

  @override
  String get mapLayerSatelliteB09 => 'Himawari Mid Water Vapour (B09)';

  @override
  String get windForecastTownOutlineHint => 'The finer mesh';

  @override
  String get mapLayerSatelliteCloudmask => 'Himawari Cloud Mask';

  @override
  String get mapAppCopyCoordinates => 'Copy coordinates';

  @override
  String get reportFilterIntensityInfoIntro =>
      'CWA changed the felt-intensity scale on 1 Jan 2020 (Taipei time).';

  @override
  String get mapNavEarthquake => 'Earthquake';

  @override
  String get restroomGradeAverage => 'Average';

  @override
  String get mapLayerSatelliteBtdCo2 => 'Himawari Cirrus / Cloud Height';

  @override
  String get onboardingPermBackgroundDesc =>
      'Allow \"Always\" so alerts still target you when the app is closed.';

  @override
  String get mapTimelineForecast => 'Forecast';

  @override
  String get restroomTypeLabel => 'Type';

  @override
  String get navEarthquake => 'Earthquake';

  @override
  String get typhoonOverlayStormL10Tooltip =>
      'Level-10 wind field + average circle (yellow)';

  @override
  String get moonPhaseWaxingGibbous => 'Waxing gibbous';

  @override
  String get reportDetailTitle => 'Earthquake Report';

  @override
  String get moreTremReport => 'TREM detection report';

  @override
  String weatherDataTime(String station, String time) {
    return '$station · Data $time';
  }

  @override
  String get meshtasticNoNodes => 'No nodes heard yet';

  @override
  String get meshtasticViaMqtt => 'Via MQTT (internet)';

  @override
  String get radarCountyOutline => 'County borders';

  @override
  String get commonClose => 'Close';

  @override
  String get restroomGradeLabel => 'Grade';

  @override
  String get rainIntervalNow => 'Today';

  @override
  String get changelogCurrentVersion => 'Current';

  @override
  String get typhoonLabelPressure => 'Central pressure';

  @override
  String get typhoonOverlayForecastCalloutsTooltip =>
      'Show forecast-point detail cards when zoomed in';

  @override
  String get aedOpenRemark => 'Hours note';

  @override
  String get onboardingPermsBody =>
      'So DPIP can alert you the moment disaster strikes, please grant the following. You can change these anytime in system settings.';

  @override
  String get typhoonOverlaySectionWeather => 'Weather underlay';

  @override
  String get notifyOptWeatherLocal => 'Current location only';

  @override
  String get mapNavRain => 'Rain';

  @override
  String get moonDays => 'days';

  @override
  String mapLegendUnit(String unit) {
    return 'Unit: $unit';
  }

  @override
  String get weatherModeClear => 'Clear';

  @override
  String get meshtasticRadio => 'Radio';

  @override
  String get commonEmpty => 'Nothing to show';

  @override
  String get mapLayerSatelliteB01 => 'Himawari Blue (B01)';

  @override
  String get meshtasticExternalPower => 'External power';

  @override
  String get moonPhaseLastQuarter => 'Last quarter';

  @override
  String get reportFilterOrderAsc => 'Ascending';

  @override
  String get reportFilterApply => 'Apply';

  @override
  String get reportDetailImageUnavailable => 'Report image not available';

  @override
  String get weatherRankingHighest => 'Highest';

  @override
  String get reportDetailReplay => 'Replay';

  @override
  String get mapLayerRestroom => 'Restrooms';

  @override
  String get restroomCategoryWelfare => 'Welfare';

  @override
  String get restroomGradeExcellent => 'Excellent';

  @override
  String get meshtasticLastSent => 'Last sent';

  @override
  String get meshtasticName => 'Name';

  @override
  String get meshtasticScan => 'Scan';

  @override
  String get mapLayerCategoryForecast => 'Numerical forecast';

  @override
  String get meshtasticChannelFailed => 'Couldn\'t set up the DPIP channel';

  @override
  String get themeSystem => 'System';

  @override
  String get mapLayerSatelliteNdvi => 'Himawari NDVI';

  @override
  String get typhoonLegendForecast => 'Forecast track';

  @override
  String typhoonValueHpa(String n) {
    return '$n hPa';
  }

  @override
  String get weatherPrecipitation => 'Precipitation';

  @override
  String get moonNextFullMoon => 'Next full moon';

  @override
  String get dpmSheetEmpty => 'Tap a marker on the map for details';

  @override
  String get onboardingSkipLeave => 'Skip anyway';

  @override
  String get aedPlaceDesc => 'Placement';

  @override
  String get onboardingSkipTitle => 'Permissions not granted';

  @override
  String get restroomTypeFamily => 'Family';

  @override
  String typhoonValueKm(String n) {
    return '$n km';
  }

  @override
  String get onboardingPermBattery => 'Battery exemption';

  @override
  String get typhoonLabelNw => 'NW';

  @override
  String get moonPhaseWaxingCrescent => 'Waxing crescent';

  @override
  String get restroomCategoryLeisure => 'Leisure';

  @override
  String get mapLayerTemperature => 'Temperature';

  @override
  String get aedCategory => 'Category';

  @override
  String get meshtasticChannels => 'Channels';

  @override
  String get monitorWaiting => 'Waiting for data…';

  @override
  String get typhoonOverlayForecastCallouts => 'Forecast tooltips';

  @override
  String get reportDetailEpicenter => 'Epicenter';

  @override
  String get meshtasticVoltage => 'Voltage';

  @override
  String get mapLayerMeshtasticSubtitle =>
      'LoRa mesh nodes heard by your radio';

  @override
  String get mapLayerWind => 'Wind direction';

  @override
  String get reportDetailMagnitude => 'Magnitude';

  @override
  String get reportDetailAreaIntensity => 'Intensity by area';

  @override
  String get rainInterval12h => '12 h';

  @override
  String reportListMagnitude(String magnitude) {
    return 'M$magnitude';
  }

  @override
  String get notifyMonitor => 'Strong-motion monitor';

  @override
  String get onboardingStart => 'Get started';

  @override
  String sponsorPerMonth(String price) {
    return '$price / month';
  }

  @override
  String get mapLayerPressure => 'Pressure';

  @override
  String get mapLayerSatelliteB04 => 'Himawari Near-Infrared (B04)';

  @override
  String get mapLayerSatelliteTransparentZero =>
      'Zero difference = transparent (no signal)';

  @override
  String get shelterIndoorLabel => 'Indoor shelter';

  @override
  String get notifyOptOff => 'Off';

  @override
  String get reportFilterSortTime => 'Time';

  @override
  String get mapLayerSatelliteCloudProbablyClear => 'Probably clear';

  @override
  String get weatherModeThunderstorm => 'Thunderstorm';

  @override
  String get homeViewOnMap => 'View on map';

  @override
  String get reportFilterIntensityInfoLegacyTitle => 'Legacy (before 2020)';

  @override
  String get typhoonLabelSpeed => 'Past movement speed';

  @override
  String mapAppOpenFailed(String app) {
    return 'Could not open $app';
  }

  @override
  String get mapLayerSatelliteRgbComposite => 'RGB composite (JMA recipe)';

  @override
  String get meshtasticReceived => 'Received';

  @override
  String get weatherRankingExtremeLow => 'Daily low';

  @override
  String get mapLayerSatelliteB10 => 'Himawari Lower Water Vapour (B10)';

  @override
  String get mapLayerSatelliteCloudProbablyCloudy => 'Probably cloudy';

  @override
  String get mapLayerSatelliteTransparentNoWater =>
      '≤ 0 = transparent (no water)';

  @override
  String get shelterCategoryLabel => 'Disaster types';

  @override
  String get meshtasticStateConnecting => 'Connecting…';

  @override
  String get moonTitle => 'Moon';

  @override
  String get weatherRankingGust => 'Gust';

  @override
  String get moreAppStore => 'App Store';

  @override
  String get moreServerStatus => 'Server status';

  @override
  String get notifySectionWeather => 'Weather';

  @override
  String get meshtasticPreset => 'Modem preset';

  @override
  String get dataSectionSeismic => 'Seismic';

  @override
  String get changelogBodyEmpty => 'No notes for this release.';

  @override
  String get changelogOpenOnGitHub => 'View on GitHub';

  @override
  String get radarGlobalOutline => 'National borders';

  @override
  String get notifyEew => 'Emergency earthquake alert';

  @override
  String get regionNationwide => 'Nationwide';

  @override
  String get moreNotifyLog => 'DPIP notification log';

  @override
  String get regionCurrent => 'Current location';

  @override
  String get meshtasticNotConnected => 'Not connected to a radio';

  @override
  String get weatherModeSnow => 'Snow';

  @override
  String get mapLayerMeshtastic => 'Meshtastic nodes';

  @override
  String get moreDeveloper => 'Debug info';

  @override
  String get mapLayerSatelliteB14 => 'Himawari Longwave Infrared (B14)';

  @override
  String get meshtasticChannelUse => 'Channel use';

  @override
  String get mapNavLightning => 'Lightning';

  @override
  String get homeForecastEmpty => 'No forecast available';

  @override
  String get sponsorOneTime => 'One-time';

  @override
  String get mapLayerSatelliteBtdSplit => 'Himawari Split Window';

  @override
  String get onboardingPermBackground => 'Background location';

  @override
  String get aedEmergencyPhone => 'Emergency phone';

  @override
  String get dpmOpenInMaps => 'Open in maps';

  @override
  String get meshtasticNotifyNodes => 'Notify on new nodes';

  @override
  String get onboardingPermCriticalDesc =>
      'Let life-threatening earthquake warnings sound even in silent mode or Do Not Disturb.';

  @override
  String get mapLayerSatelliteTransparentWarm =>
      'Clear sky (warm end) = transparent, the basemap shows';

  @override
  String get meshtasticSent => 'Sent';

  @override
  String get homeForecastTitle => '24-hour forecast';

  @override
  String get typhoonLegendWarningAreas => 'Warning areas';

  @override
  String meshtasticExcludeMqttHidden(int count) {
    return '$count hidden';
  }

  @override
  String get notifyOptLocalIntensity1 => 'Local intensity 1 or above';

  @override
  String get mapTimelinePast => 'Past';

  @override
  String get restroomTypeFemale => 'Female';

  @override
  String get reportListToday => 'Today';

  @override
  String get meshtasticTapNode => 'Tap a node for details';

  @override
  String get commonLoading => 'Loading…';

  @override
  String get typhoonIntensityModerate => 'Moderate typhoon';

  @override
  String get mapLayerSatelliteAsh => 'Himawari Ash';

  @override
  String get rainInterval3h => '3 h';

  @override
  String get mapLayerCategorySatellite => 'Satellite';

  @override
  String get meshtasticChannelReady => 'DPIP channel ready';

  @override
  String get mapLayerSatelliteNightmicrophysics =>
      'Himawari Night Microphysics';

  @override
  String get typhoonIntensityTd => 'Tropical depression';

  @override
  String get reportFilterDate => 'Date';

  @override
  String get sponsorRestoreUnavailable =>
      'Can\'t reach the store. Please try again later.';

  @override
  String homeForecastPop(String pop) {
    return '$pop%';
  }

  @override
  String get regionEmpty => 'No saved regions yet';

  @override
  String get onboardingPermBatteryDesc =>
      'Allow DPIP to keep running in the background so alerts aren\'t delayed or missed.';

  @override
  String get mapNavDisaster => 'Disaster';

  @override
  String get radarScanRangeSubtitle =>
      'Outlines the area the four radars actually observe.';

  @override
  String get aedHoursSunday => 'Sunday hours';

  @override
  String get reportDetailOriginTime => 'Origin time';

  @override
  String get trendNoData => 'No trend data';

  @override
  String get onboardingPermLocation => 'Location';

  @override
  String get moreDiscord => 'Discord community';

  @override
  String get mapNavPressure => 'Pressure';

  @override
  String get mapLayerSatelliteB13 => 'Himawari Infrared (B13)';

  @override
  String typhoonTdNo(String no) {
    return 'TD $no';
  }

  @override
  String get changelogEmpty => 'No release notes yet';

  @override
  String get reportFilterDateStartNote => 'Start day: from 00:00 (Taipei)';

  @override
  String get eewTitle => 'Earthquake early warning';

  @override
  String get mapLayerWindForecastEcmwf => 'ECMWF';

  @override
  String regionSelectCount(int count, int max) {
    return '$count/$max selected';
  }

  @override
  String get mapLayerSatelliteBtdSo2 => 'Himawari SO₂ / Cloud Phase';

  @override
  String get meshtasticStateError => 'Error';

  @override
  String get weatherModeOvercast => 'Overcast';

  @override
  String get reportDetailDepth => 'Depth';

  @override
  String get typhoonOverlayWarningTooltip =>
      'Highlight counties under a typhoon warning';

  @override
  String get reportFilterDatePick => 'Pick dates';

  @override
  String get onboardingSkipStay => 'Go back';

  @override
  String get commonFetchFailed => 'Couldn\'t load data. Please try again.';

  @override
  String get shelterOutdoorLabel => 'Outdoor shelter';

  @override
  String get meshtasticStateConnected => 'Connected';

  @override
  String get mapNavRadar => 'Radar';

  @override
  String get mapLayerSatelliteCloudClear => 'Clear';

  @override
  String eewSummary(String magnitude, String depth) {
    return 'M$magnitude · depth $depth km';
  }

  @override
  String get locationBannerPermission =>
      'Location permission is off — local alerts can\'t target your area.';

  @override
  String get typhoonOverlayWeatherNoneTooltip =>
      'No radar or infrared underlay';

  @override
  String get radarCountyOutlineHint => 'Drawn over the echo';

  @override
  String get windForecastCountyOutlineHint => 'Drawn over the wind field';

  @override
  String get homeRainTrendTitle => 'Next hour precipitation';

  @override
  String get moonPhaseFirstQuarter => 'First quarter';

  @override
  String get mapLayerCategoryTyphoon => 'Typhoon';

  @override
  String get meshtasticUtilization => 'Airtime (24h)';

  @override
  String get restroomTypeMixed => 'Mixed';

  @override
  String get restroomGradeGood => 'Good';

  @override
  String get notifyTsunami => 'Tsunami information';

  @override
  String get navData => 'Data';

  @override
  String get mapLayerSatelliteBtdWvirw => 'Himawari Overshooting Top';

  @override
  String get meshtasticReadingAge => 'Reading taken';

  @override
  String get mapAppCallFailed => 'This device cannot make phone calls';

  @override
  String get reportFilterAny => 'Any';

  @override
  String get weatherRankingMergeTo => 'Merge to';

  @override
  String get notifyIntensity => 'Intensity report';

  @override
  String get rainIntervalMenu => 'Accumulation window';

  @override
  String get reportDetailLocalFelt => 'Local Felt Earthquake';

  @override
  String get meshtasticDevice => 'Device';

  @override
  String get onboardingGrant => 'Grant';

  @override
  String get weatherModeRain => 'Rain';

  @override
  String get shelterVulnerableOkLabel => 'Vulnerable-people friendly';

  @override
  String get stationSheetEmpty => 'Tap a station to see its reading';

  @override
  String get typhoonLegendProbability => 'Strike probability';

  @override
  String get reportFilterMagnitude => 'Magnitude';

  @override
  String get skyTimeMorning => 'Morning';

  @override
  String get experimentalFeatures => 'Experimental features';

  @override
  String get onboardingTermsBody =>
      'Please read the following notices before using DPIP:\n\n• All information should defer to the content published by the Central Weather Administration (CWA).\n\n• Depending on network, server, app, and upstream data-source conditions, information may not be received; we make every effort to avoid this but cannot guarantee it never happens.\n\n• Strong shaking may reach your location before the notification does.\n\n• Earthquake early warnings are fast-computed results that may carry significant error — understand this and use them with caution.\n\n• Any behavior not sanctioned by the authorities may carry legal risk; please follow all applicable regulations.\n\nIn addition, to provide localized alerts, this service collects and uploads your approximate location and push identifier — in the foreground and background — solely to decide which alerts to send you.\n\nBy tapping \"Agree and continue\" you confirm that you have read, understood, and agree to the above.';

  @override
  String get reportFilterTitle => 'Filters';

  @override
  String get onboardingPermCritical => 'Critical alerts';

  @override
  String trendCumulativeTotal(String total) {
    return 'Cumulative $total mm';
  }

  @override
  String get languageName => 'English';

  @override
  String get reportListEmptyFiltered =>
      'No earthquake reports match these filters';

  @override
  String get meshtasticExcludeMqtt => 'Hide MQTT nodes';

  @override
  String get mapNavTyphoon => 'Typhoon';

  @override
  String get weatherModeSand => 'Dust';

  @override
  String get notifyReport => 'Earthquake report';

  @override
  String get mapAppCoordinatesCopied => 'Coordinates copied';

  @override
  String get skyTimeNight => 'Night';

  @override
  String get sponsorRecommended => 'Recommended';

  @override
  String get mapLayerSatelliteB15 => 'Himawari Longwave Infrared (B15)';

  @override
  String get weatherRankingWind => 'Wind speed';

  @override
  String get feedStale => 'Data may be out of date';

  @override
  String homeForecastWind(String direction, String level) {
    return '$direction · Force $level';
  }

  @override
  String get navHome => 'Home';

  @override
  String get meshtasticRegionLabel => 'Region';

  @override
  String get mapLayerSatelliteCloudtop => 'Himawari Cloud Top Temperature';

  @override
  String get moonTimelineCaption => 'Phase';

  @override
  String get openSourceLicenses => 'Open-source licenses';

  @override
  String get weatherRankingLowest => 'Lowest';

  @override
  String get reportFilterSortDepth => 'Depth';

  @override
  String mapTimelineDataTime(String time) {
    return 'Data $time';
  }

  @override
  String get radarScanRange => 'Show scan range';

  @override
  String get meshtasticHopLimit => 'Hop limit';

  @override
  String get weatherRankingExtremeHigh => 'Daily high';

  @override
  String get sponsorPrivacy => 'Privacy Policy';

  @override
  String get reportDetailLocalIntensity => 'Intensity at your locations';

  @override
  String get mapLayerSatelliteNaturalcolor => 'Himawari Natural Color';

  @override
  String get meshtasticAirtime => 'Air time (TX)';

  @override
  String shelterCapacityValue(int n) {
    return '$n people';
  }

  @override
  String lightningLegendCc(int minutes) {
    return 'Cloud-to-cloud · $minutes min';
  }

  @override
  String get meshtasticSendHint => 'Message to broadcast';

  @override
  String monitorDelay(String value) {
    return 'Delay $value s';
  }

  @override
  String get dpmNo => 'No';

  @override
  String get mapLayerSatelliteB08 => 'Himawari Upper Water Vapour (B08)';

  @override
  String get meshtasticReconnecting => 'Reconnecting…';

  @override
  String get radarTownOutlineSubtitle =>
      'Keeps township borders legible under the radar echo.';

  @override
  String get typhoonOverlayWeatherSatelliteTooltip =>
      'Infrared closest to the typhoon bulletin time';

  @override
  String get radarScanRangeHint => 'Blank outside means unobserved';

  @override
  String typhoonPickerTd(String no) {
    return 'Tropical depression TD $no';
  }

  @override
  String get mapLayerSatelliteWatervapor => 'Himawari Water Vapour';

  @override
  String get regionAddButton => 'Add a region';

  @override
  String get regionSearchHint => 'Search counties and cities';

  @override
  String get regionSearchEmpty => 'No matching counties or cities';

  @override
  String get regionSearchTownHint => 'Search townships';

  @override
  String get regionSearchTownEmpty => 'No matching townships';

  @override
  String get displaySettings => 'Display';

  @override
  String get restroomGradePoor => 'Below standard';

  @override
  String get restroomCategoryTourist => 'Tourist';

  @override
  String get locationBannerServiceOff =>
      'Location services are off — local alerts can\'t target your area.';

  @override
  String get mapLayerStyleTooltip => 'Colour style';

  @override
  String lightningLegendCg(int minutes) {
    return 'Cloud-to-ground · $minutes min';
  }

  @override
  String get skyTimeAuto => 'Auto';

  @override
  String get appLogs => 'App logs';

  @override
  String get serverStatusLocal => 'Local status';

  @override
  String get serverStatusLocalBody =>
      'Metrics come from the dashboard. Below is this device\'s own view of the multi-active endpoints (LB / Core per region): it passively records the traffic each endpoint actually serves, so a cell with no data means nothing was observed through this device yet.';

  @override
  String get serverStatusAllUp => 'All services operational';

  @override
  String get serverStatusDegraded => 'Services degraded';

  @override
  String get serverStatusDown => 'Service down';

  @override
  String get serverStatusErrorRate => '5xx error rate';

  @override
  String get serverStatusLatency => 'Avg latency';

  @override
  String get serverStatusUpdated => 'Updated';

  @override
  String get serverStatusWeb => 'Server status';

  @override
  String get serverStatusWebUrl => 'status.exptech.dev';

  @override
  String get serverStatusExpTech => 'ExpTech status';

  @override
  String get serverStatusCloudflare => 'Cloudflare status';

  @override
  String get serverStatusCloudflareAllOperational => 'All regions operational';

  @override
  String get serverStatusCloudflareOutage => 'Cloudflare regional issue';

  @override
  String get serverStatusCloudflareNone => 'No regions to show.';

  @override
  String get serverStatusCloudflareOperational => 'Operational';

  @override
  String get serverStatusCloudflareDegraded => 'Degraded';

  @override
  String get serverStatusCloudflarePartial => 'Partial outage';

  @override
  String get serverStatusCloudflareMajor => 'Major outage';

  @override
  String get serverStatusCloudflareUnknown => 'Unknown';

  @override
  String get endpointTierLbApi => 'LB API';

  @override
  String get endpointTierLbStatic => 'LB Static';

  @override
  String get endpointTierCoreApi => 'Core API';

  @override
  String get endpointTierCoreStatic => 'Core Static';

  @override
  String get endpointTierCoreExclusiveApi =>
      'Core-exclusive API (radar / weather / wind)';

  @override
  String get endpointTierCoreStaticExclusive => 'Core-exclusive static';

  @override
  String get endpointTierLegacyApi => 'Legacy API (api-1)';

  @override
  String get endpointHealthOk => 'Local connections healthy';

  @override
  String get endpointHealthDegraded => 'Some endpoints unstable';

  @override
  String get endpointHealthDown => 'Local connections failing';

  @override
  String get endpointHealthUnknown => 'No observations yet';

  @override
  String get endpointStateOk => 'OK';

  @override
  String get endpointStateDegraded => 'Unstable';

  @override
  String get endpointStateDown => 'Failing';

  @override
  String get endpointStateUnknown => 'Unknown';

  @override
  String get endpointServiceEew => 'EEW';

  @override
  String get endpointServiceRts => 'RTS';

  @override
  String get endpointServiceRadar => 'Radar';

  @override
  String get endpointServiceSatellite => 'Satellite';

  @override
  String get endpointServiceQpesums => 'QPE';

  @override
  String get endpointServiceWind => 'Wind';

  @override
  String get endpointServiceDpm => 'Disaster points';

  @override
  String get endpointServiceWeather => 'Weather';

  @override
  String get endpointServiceRain => 'Rain';

  @override
  String get endpointServiceLightning => 'Lightning';

  @override
  String get endpointServiceTyphoon => 'Typhoon';

  @override
  String get endpointServiceReport => 'EQ reports';

  @override
  String get endpointServiceTremStation => 'Tremor station';

  @override
  String get endpointServiceEvent => 'Events';

  @override
  String get endpointServiceLocation => 'Location';

  @override
  String get endpointServiceNotify => 'Notifications';

  @override
  String get endpointServiceOther => 'Other';

  @override
  String get feedConnecting => 'Connecting…';

  @override
  String get notifyBannerDisabled =>
      'Notifications are off — you won\'t receive disaster alerts.';

  @override
  String get weatherHumidity => 'Humidity';

  @override
  String typhoonValueMs(String n) {
    return '$n m/s';
  }

  @override
  String homeForecastHumidity(String value) {
    return 'Humidity $value%';
  }

  @override
  String get meshtasticBusyBody =>
      'Disconnect it in the other Meshtastic app first. Two apps on one radio take each other\'s messages, so some will go missing.';

  @override
  String get meshtasticChannelNoSlot =>
      'No free channel slot — free one on the radio';

  @override
  String get restroomCategoryTransport => 'Transport';

  @override
  String get meshtasticBattery => 'Battery';

  @override
  String get meshtasticDistance => 'Distance';

  @override
  String get meshtasticSnrTrend => 'Signal trend (SNR)';

  @override
  String get meshtasticBatteryTrend => 'Battery trend';

  @override
  String get typhoonOverlayMenuTooltip => 'Typhoon overlay options';

  @override
  String get mapLayerSatelliteBtdOzone => 'Himawari Tropopause';

  @override
  String meshtasticRegionMismatch(String region) {
    return 'Radio region is $region — DPIP needs TW';
  }

  @override
  String get notifySectionEarthquake => 'Earthquake';

  @override
  String get mapLayerDisasterMap => 'Disaster Map';

  @override
  String get weatherModeFog => 'Fog';

  @override
  String typhoonPickerNamed(String no, String name) {
    return '$name TY $no';
  }

  @override
  String get mapLayerStyleGrayTooltip => 'JMA grayscale — colder is whiter';

  @override
  String get moreAnnouncements => 'Announcements';

  @override
  String get moreTagline => 'Disaster Prevention Information Platform';

  @override
  String get moreVersionStable => 'Release';

  @override
  String get moreVersionNotes => 'This update';

  @override
  String get moreVersionNotesHighlightsSubtitle =>
      'What changed in this release';

  @override
  String releaseHighlightsTitle(Object train) {
    return '$train key highlights';
  }

  @override
  String get releaseHighlightsTabNormal => 'For users';

  @override
  String get releaseHighlightsTabAdvanced => 'Deep dive';

  @override
  String get releaseHighlightsEmpty => 'Nothing here yet.';

  @override
  String get releaseHighlightsSeeNotes => 'Full release notes';

  @override
  String get moreVersionNotesEmpty => 'No changelog for this build';

  @override
  String get reportNotFound => 'That earthquake report is no longer available';

  @override
  String get moreVersionSnapshot => 'Snapshot';

  @override
  String get mapLayerSatelliteTransparentNoData =>
      'No data (land) = transparent';

  @override
  String get restroomCategoryGovernment => 'Government';

  @override
  String get typhoonLegendCurrent => 'Current centre';

  @override
  String get aedAddress => 'Address';

  @override
  String get mapLayerAed => 'AED';

  @override
  String get changelogTypePrerelease => 'Beta';

  @override
  String get reportFilterIntensityInfoModernBody =>
      'Levels 0–4, 5−, 5+, 6−, 6+, and 7. The filter slider uses this scale; older events still show legacy labels in the list.';

  @override
  String get typhoonOverlayWeatherNone => 'None';

  @override
  String get mapLayerStyleGray => 'Grayscale (JMA)';

  @override
  String get weatherModeAuto => 'Auto';

  @override
  String get typhoonLabelProbCircle => '70% probability circle';

  @override
  String get notifyOptAll => 'Receive all';

  @override
  String get displayTheme => 'Theme';

  @override
  String get mapLayerSatelliteB07 => 'Himawari Shortwave Infrared (B07)';

  @override
  String get typhoonLabelDirection => 'Past movement direction';

  @override
  String get regionManageTitle => 'Saved regions';

  @override
  String get regionSaveNote =>
      'Notifications are sent based on your GPS location. Setting a saved region does not change where alerts are sent — saved regions only affect which areas the home screen shows at a glance. Grant location permission, or alerts cannot work.';

  @override
  String get typhoonLegendCone => 'Forecast cone';

  @override
  String get moreCwaEew => 'CWA earthquake early warning';

  @override
  String get onboardingPermsTitle => 'Permissions';

  @override
  String get mapLayerStyleJma => 'Cloud-top enhancement (JMA)';

  @override
  String get rainInterval10m => '10 min';

  @override
  String get meshtasticConnectAnyway => 'Connect anyway';

  @override
  String reportListDayCount(int count) {
    return '$count';
  }

  @override
  String get mapLayerSatelliteB06 => 'Himawari Near-Infrared (B06)';

  @override
  String get mapLayerSatelliteTransparentReflectance =>
      'Low reflectance / night = transparent, the basemap shows';

  @override
  String chartHourLabel(int hour) {
    return '${hour}h';
  }

  @override
  String get mapLayerShelter => 'Shelters';

  @override
  String get typhoonOverlayProbabilityTooltip =>
      'Show strike probability (hides the forecast cone)';

  @override
  String get mapLayerSatelliteNdwi => 'Himawari NDWI';

  @override
  String get disasterMapOverlayShelterTooltip => 'Show evacuation shelters';

  @override
  String get mapNavHumidity => 'Humidity';

  @override
  String get reportDetailSortByIntensity => 'Sort by intensity';

  @override
  String get homeRainTrendNoData => 'No data';

  @override
  String get mapLayerCategoryRadar => 'Radar';

  @override
  String get meshtasticShortName => 'Short name';

  @override
  String get mapLayerSatelliteAirmass => 'Himawari Airmass';

  @override
  String get dataSectionWeather => 'Weather';

  @override
  String get aedHoursWeekday => 'Weekday hours';

  @override
  String get homeActiveEventsTitle => 'Active events';

  @override
  String get faq => 'FAQ';

  @override
  String eewSerial(int serial) {
    return 'Report $serial';
  }

  @override
  String get reportFilterSort => 'Sort';

  @override
  String get meshtasticRegionConfirm =>
      'Switch this radio to the TW region? It restarts and disconnects for a moment, and every other channel on it moves too.';

  @override
  String get dataEarthquakeSubtitle => 'Earthquake reports';

  @override
  String get typhoonNoActive => 'No active typhoon';

  @override
  String get mapLayerSatelliteB11 => 'Himawari SO₂ / Cloud Phase (B11)';

  @override
  String get navEvents => 'Events';

  @override
  String get onboardingTermsTitle => 'Terms of Service';

  @override
  String get mapOsmOverlay => 'Detailed map';

  @override
  String get mapOsmOverlayHint =>
      'Show more complete roads, buildings, and place labels';

  @override
  String get mapOsmDetails => 'Detailed map layers';

  @override
  String get moreDataSources => 'Data sources';

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
    return '$enabled of $total layers enabled';
  }

  @override
  String get mapOsmSurface => 'Surface';

  @override
  String get mapOsmParks => 'Parks';

  @override
  String get mapOsmLandUse => 'Land use';

  @override
  String get mapOsmAirportAreas => 'Airport areas';

  @override
  String get mapOsmWater => 'Water';

  @override
  String get mapOsmRivers => 'Rivers';

  @override
  String get mapOsmBoundaries => 'Boundaries';

  @override
  String get mapOsmBuildings => 'Buildings';

  @override
  String get mapOsmRoads => 'Roads';

  @override
  String get mapOsmRoadNames => 'Road names';

  @override
  String get mapOsmWaterNames => 'Water names';

  @override
  String get mapOsmPeaks => 'Peaks';

  @override
  String get mapOsmAirportNames => 'Airport names';

  @override
  String get mapOsmPlaceNames => 'Place names';

  @override
  String get mapOsmPoi => 'Points of interest';

  @override
  String get mapOsmHouseNumbers => 'House numbers';

  @override
  String get mapOsmRestoreAll => 'Restore all';

  @override
  String get mapOsmSectionNatural => 'Natural features';

  @override
  String get mapOsmSectionRoadsAndBuildings => 'Roads & buildings';

  @override
  String get mapOsmSectionLabelsAndPlaces => 'Labels & places';

  @override
  String get mapTownLabels => 'Township names';

  @override
  String get notifySetFailed => 'Couldn\'t save the setting. Please try again.';

  @override
  String get meshtasticDisconnect => 'Disconnect';

  @override
  String get meshtasticUndecoded => 'Not decrypted';

  @override
  String get notifyAnnouncement => 'Announcements';

  @override
  String get onboardingIntroTitle => 'Welcome to DPIP';

  @override
  String get regionCurrentUnavailable => 'Can\'t get current location';

  @override
  String get languageSystem => 'System default';

  @override
  String get skyTimeSunset => 'Sunset';

  @override
  String get mapLayerSatelliteDust => 'Himawari Dust';

  @override
  String get mapAppAppleMaps => 'Apple Maps';

  @override
  String get regionEdit => 'Edit';

  @override
  String get weatherDynamicState => 'Weather animation';

  @override
  String get moonNow => 'Now';

  @override
  String get moonSectionAppearance => 'Appearance';

  @override
  String get moonSectionRiseSet => 'Rise and set';

  @override
  String get moonSectionUpcoming => 'Upcoming';

  @override
  String get moonSectionCalendar => 'Calendar';

  @override
  String get moonDistance => 'Distance';

  @override
  String get moonKilometres => 'km';

  @override
  String get moonApparentSize => 'Apparent size';

  @override
  String get moonRise => 'Moonrise';

  @override
  String get moonSet => 'Moonset';

  @override
  String get moonNextNewMoon => 'Next new moon';

  @override
  String get moonAlwaysUp => 'Up all day';

  @override
  String get moonNoEvent => 'None today';

  @override
  String get sunTitle => 'Sun';

  @override
  String get sunSectionDaylight => 'Daylight';

  @override
  String get sunSectionTwilight => 'Twilight';

  @override
  String get sunSectionLight => 'Light';

  @override
  String get sunSectionSundial => 'Sundial';

  @override
  String get sunSectionTerms => 'Solar terms';

  @override
  String get sunRise => 'Sunrise';

  @override
  String get sunSet => 'Sunset';

  @override
  String get sunNoon => 'Solar noon';

  @override
  String get sunDayLength => 'Day length';

  @override
  String get sunTwilightCivil => 'Civil';

  @override
  String get sunTwilightNautical => 'Nautical';

  @override
  String get sunTwilightAstronomical => 'Astronomical';

  @override
  String get sunGoldenHourMorning => 'Morning golden hour';

  @override
  String get sunGoldenHourEvening => 'Evening golden hour';

  @override
  String get sunBlueHour => 'Blue hour';

  @override
  String get sunEquationOfTime => 'Equation of time';

  @override
  String get sunMinutes => 'min';

  @override
  String get solarTermNext => 'Next term';

  @override
  String get planetsTitle => 'Planets';

  @override
  String get planetsSectionTonight => 'Right now';

  @override
  String get planetUp => 'Up';

  @override
  String get planetDown => 'Below';

  @override
  String get planetInGlare => 'In glare';

  @override
  String get planetMagnitude => 'Magnitude';

  @override
  String get planetElongation => 'Elongation';

  @override
  String get planetSky => 'Sky';

  @override
  String get planetEvening => 'Evening';

  @override
  String get planetMorning => 'Morning';

  @override
  String get planetDistance => 'Distance';

  @override
  String get planetAu => 'au';

  @override
  String get planetAltitude => 'Altitude';

  @override
  String get planetMercury => 'Mercury';

  @override
  String get planetVenus => 'Venus';

  @override
  String get planetMars => 'Mars';

  @override
  String get planetJupiter => 'Jupiter';

  @override
  String get planetSaturn => 'Saturn';

  @override
  String get planetUranus => 'Uranus';

  @override
  String get planetNeptune => 'Neptune';

  @override
  String get solarTermVernalEquinox => 'Vernal Equinox';

  @override
  String get solarTermPureBrightness => 'Pure Brightness';

  @override
  String get solarTermGrainRain => 'Grain Rain';

  @override
  String get solarTermStartOfSummer => 'Start of Summer';

  @override
  String get solarTermGrainFull => 'Grain Full';

  @override
  String get solarTermGrainInEar => 'Grain in Ear';

  @override
  String get solarTermSummerSolstice => 'Summer Solstice';

  @override
  String get solarTermMinorHeat => 'Minor Heat';

  @override
  String get solarTermMajorHeat => 'Major Heat';

  @override
  String get solarTermStartOfAutumn => 'Start of Autumn';

  @override
  String get solarTermEndOfHeat => 'End of Heat';

  @override
  String get solarTermWhiteDew => 'White Dew';

  @override
  String get solarTermAutumnalEquinox => 'Autumnal Equinox';

  @override
  String get solarTermColdDew => 'Cold Dew';

  @override
  String get solarTermFrostDescent => 'Frost Descent';

  @override
  String get solarTermStartOfWinter => 'Start of Winter';

  @override
  String get solarTermMinorSnow => 'Minor Snow';

  @override
  String get solarTermMajorSnow => 'Major Snow';

  @override
  String get solarTermWinterSolstice => 'Winter Solstice';

  @override
  String get solarTermMinorCold => 'Minor Cold';

  @override
  String get solarTermMajorCold => 'Major Cold';

  @override
  String get solarTermStartOfSpring => 'Start of Spring';

  @override
  String get solarTermRainWater => 'Rain Water';

  @override
  String get solarTermAwakeningOfInsects => 'Awakening of Insects';

  @override
  String get tonightTitle => 'Tonight';

  @override
  String get tonightSectionDark => 'Observing window';

  @override
  String get tonightAstronomicalNight => 'Astronomical night';

  @override
  String get tonightNeverDark => 'Never fully dark';

  @override
  String get tonightDarkWindow => 'Dark window';

  @override
  String get tonightMoonAllNight => 'Moon up all night';

  @override
  String get tonightDarkTotal => 'Total dark';

  @override
  String get tonightMoonlight => 'Moonlight';

  @override
  String get tonightSectionShowers => 'Meteor showers';

  @override
  String get tonightRadiantDown => 'Radiant never rises';

  @override
  String get tonightPerHour => '/h';

  @override
  String get tonightSectionSatellites => 'Satellite passes';

  @override
  String get tonightSectionTargets => 'Targets up now';

  @override
  String get showerQuadrantids => 'Quadrantids';

  @override
  String get showerLyrids => 'Lyrids';

  @override
  String get showerEtaAquariids => 'Eta Aquariids';

  @override
  String get showerDeltaAquariids => 'Delta Aquariids';

  @override
  String get showerPerseids => 'Perseids';

  @override
  String get showerOrionids => 'Orionids';

  @override
  String get showerSouthernTaurids => 'Southern Taurids';

  @override
  String get showerLeonids => 'Leonids';

  @override
  String get showerGeminids => 'Geminids';

  @override
  String get showerUrsids => 'Ursids';

  @override
  String get deepSkyOpenCluster => 'Open cluster';

  @override
  String get deepSkyGlobularCluster => 'Globular cluster';

  @override
  String get deepSkySpiralGalaxy => 'Spiral galaxy';

  @override
  String get deepSkyEllipticalGalaxy => 'Elliptical galaxy';

  @override
  String get deepSkyIrregularGalaxy => 'Irregular galaxy';

  @override
  String get deepSkyPlanetaryNebula => 'Planetary nebula';

  @override
  String get deepSkySupernovaRemnant => 'Supernova remnant';

  @override
  String get deepSkyEmissionNebula => 'Emission nebula';

  @override
  String get deepSkyReflectionNebula => 'Reflection nebula';

  @override
  String get deepSkyAsterism => 'Asterism';

  @override
  String get almanacTitle => 'Almanac';

  @override
  String get almanacSectionToday => 'Today';

  @override
  String get almanacGregorian => 'Gregorian';

  @override
  String get almanacLunar => 'Lunisolar';

  @override
  String get almanacYear => 'Year';

  @override
  String get almanacMonthLength => 'Month length';

  @override
  String get almanacLongMonth => '30 days';

  @override
  String get almanacShortMonth => '29 days';

  @override
  String get almanacLeapPrefix => 'Leap ';

  @override
  String get almanacSectionLunarEclipses => 'Lunar eclipses';

  @override
  String get almanacSectionSolarEclipses => 'Solar eclipses';

  @override
  String get almanacNoSolarEclipse => 'None in range';

  @override
  String get eclipseTotal => 'Total';

  @override
  String get eclipsePartial => 'Partial';

  @override
  String get eclipseAnnular => 'Annular';

  @override
  String get eclipsePenumbral => 'Penumbral';

  @override
  String get zodiacRat => 'Rat';

  @override
  String get zodiacOx => 'Ox';

  @override
  String get zodiacTiger => 'Tiger';

  @override
  String get zodiacRabbit => 'Rabbit';

  @override
  String get zodiacDragon => 'Dragon';

  @override
  String get zodiacSnake => 'Snake';

  @override
  String get zodiacHorse => 'Horse';

  @override
  String get zodiacGoat => 'Goat';

  @override
  String get zodiacMonkey => 'Monkey';

  @override
  String get zodiacRooster => 'Rooster';

  @override
  String get zodiacDog => 'Dog';

  @override
  String get zodiacPig => 'Pig';

  @override
  String get tideTitle => 'Tide';

  @override
  String get tideDisclaimer =>
      'Astronomical forcing only — not a harbour tide table. For water levels use the CWA\'s published tables.';

  @override
  String get tideSectionNow => 'Right now';

  @override
  String get tidePhase => 'Cycle';

  @override
  String get tideSpring => 'Spring';

  @override
  String get tideNeap => 'Neap';

  @override
  String get tideMiddling => 'Middling';

  @override
  String get tideLunarDistanceFactor => 'Lunar pull';

  @override
  String get tideEquilibrium => 'Equilibrium tide';

  @override
  String get tideMetres => 'm';

  @override
  String get tidePerigeanSpring => 'Next perigean spring';

  @override
  String get tideSectionTurningPoints => 'Turning points';

  @override
  String get tideHigh => 'High';

  @override
  String get tideLow => 'Low';

  @override
  String get skyChartTitle => 'Sky chart';

  @override
  String get skyChartNorth => 'N';

  @override
  String get skyChartEast => 'E';

  @override
  String get skyChartSouth => 'S';

  @override
  String get skyChartWest => 'W';

  @override
  String tonightElementAge(int days) {
    return 'elements $days d old';
  }

  @override
  String almanacLunarDate(String leap, int month, int day) {
    return '${leap}month $month, day $day';
  }

  @override
  String get tonightNoShowers => 'No shower running';

  @override
  String get tonightNoPasses => 'No visible pass in 48 h';

  @override
  String get tonightSatellitesUnavailable => 'Orbit data unavailable';

  @override
  String get tonightNoTargets => 'Nothing high enough';

  @override
  String get skyChartUnavailable => 'Star catalogue unavailable';

  @override
  String get permissionSettingsTitle => 'Grant it in Settings';

  @override
  String get permissionSettingsHint =>
      'The app checks again when you come back.';

  @override
  String get permissionOpenSettings => 'Open Settings';

  @override
  String permissionSettingsMessage(String what) {
    return '“$what” was declined, and the system will not ask again. Turn it on in Settings.';
  }

  @override
  String get permissionGuideNotification =>
      'Open System Settings to allow notifications.';

  @override
  String get permissionGuideForegroundLocation =>
      'Open System Settings to allow precise location.';

  @override
  String permissionGuideBackgroundLocation(Object option) {
    return 'In “$option”, choose “Allow all the time”.';
  }

  @override
  String get permissionGuideBackgroundExecution =>
      'Allow background execution in System Settings so notifications are not paused.';

  @override
  String get permissionGuideUnusedPause =>
      'If the app is marked “unused”, choose “Allow” in System Settings.';

  @override
  String get permissionGuideUnusedFreeSpace =>
      'If the app was paused for storage, clear cache and reopen it.';

  @override
  String get permissionGuideUnusedRevoke =>
      'If the app\'s permissions were revoked, grant them again in System Settings.';

  @override
  String get permissionGuideUnusedPlayProtect =>
      'If Play Protect paused the app, check its status in Google Play.';

  @override
  String permissionGuideVendorPower(Object vendor) {
    return 'In “$vendor” power-saving settings, set this app to “Unrestricted”.';
  }

  @override
  String get permissionStillRequired =>
      'Still needs attention. Check the highlighted option in Settings.';

  @override
  String get permissionVerifyManually =>
      'Please verify this permission is enabled in System Settings.';

  @override
  String get permissionBackgroundLocationOption => '“Allow all the time”';

  @override
  String get displayTextSize => 'Text size';

  @override
  String get displayTextSizeDesc =>
      'Applies to the app interface — map labels keep their own size.';

  @override
  String get displayTextWeight => 'Text weight';

  @override
  String get displayTextWeightDesc => 'Bolder text can be easier to read.';

  @override
  String get displayContrast => 'Contrast';

  @override
  String get displayContrastDesc =>
      'Higher contrast separates text from its background.';

  @override
  String get displayColorVision => 'Colour vision';

  @override
  String get displayColorVisionDesc =>
      'Recolours the whole app, including map colours.';

  @override
  String get displayColorVisionNone => 'Standard colours';

  @override
  String get displayColorVisionProtan => 'Red-weak (protanopia)';

  @override
  String get displayColorVisionDeutan => 'Green-weak (deuteranopia)';

  @override
  String get displayColorVisionTritan => 'Blue-yellow weak (tritanopia)';

  @override
  String get displayPreviewSample => 'Sample earthquake report';

  @override
  String get displayScaleSmall => 'Small';

  @override
  String get displayScaleDefault => 'Default';

  @override
  String get displayScaleLarge => 'Large';

  @override
  String get displayScaleHuge => 'Extra large';

  @override
  String get displayWeightNormal => 'Normal';

  @override
  String get displayWeightMedium => 'Medium';

  @override
  String get displayWeightBold => 'Bold';

  @override
  String get displayContrastStandard => 'Standard';

  @override
  String get displayContrastMedium => 'Medium';

  @override
  String get displayContrastHigh => 'High';

  @override
  String get meshtasticDirect => 'Direct';

  @override
  String meshtasticHopsAway(int n) {
    return '$n hops';
  }

  @override
  String get meshtasticStatRelayShare => 'Relayed for others';

  @override
  String get meshtasticStatRelayShareHint => 'Share of what this radio sent';

  @override
  String get meshtasticStatRelayValue => 'Relays completed';

  @override
  String get meshtasticStatRelaySolePath =>
      'Often the only path — the mesh leans on this node';

  @override
  String get meshtasticStatRelayRedundant => 'Others cover the same hops';

  @override
  String get meshtasticStatRedundancy => 'Duplicate receptions';

  @override
  String get meshtasticStatThinEdge =>
      'Few spare paths — one relay failing could cut you off';

  @override
  String get meshtasticStatWellCovered => 'Several paths reach here';

  @override
  String get meshtasticStatErrorRate => 'Corrupt receptions';

  @override
  String get meshtasticStatErrorRateHint =>
      'Rising while airtime is flat means interference';

  @override
  String get meshtasticTraceRoute => 'Trace route';

  @override
  String get meshtasticTracing => 'Tracing…';

  @override
  String get meshtasticTraceUnreadable => 'Unreadable reply';

  @override
  String get meshtasticTraceOffline => 'Radio not connected';

  @override
  String get meshtasticTraceCooldown => 'Radio limits this to once every 30 s';

  @override
  String get meshtasticTraceNoReply =>
      'No reply — out of range or on another channel key';

  @override
  String get meshtasticTraceDirect => 'Direct — no relays between';

  @override
  String meshtasticTraceHops(int n) {
    return '$n hops';
  }

  @override
  String get moreDumpDiagnostics => 'Dump debug info and logs';

  @override
  String get moreDumpDiagnosticsHint =>
      'Uploads them and copies a link to paste into a report';

  @override
  String get dumpIncludeSensitive => 'Include precise location';

  @override
  String get dumpIncludeSensitiveHint =>
      'Includes coordinates from logs and background location; otherwise they are replaced with null';

  @override
  String get dumpUpload => 'Upload';

  @override
  String get dumpUploaded => 'Uploaded';

  @override
  String get dumpLinkCopied => 'The link is on your clipboard';

  @override
  String get dumpCopyAgain => 'Copy again';

  @override
  String get dumpUploadFailed => 'Upload failed — try again';

  @override
  String get statusLegendUnprobed => 'Not yet probed';

  @override
  String get statusLegendUnsupported => 'Not offered';

  @override
  String get rainScaleSection => 'Colour scale';

  @override
  String get rainScaleFine => 'Fine';

  @override
  String get rainScaleCoarse => 'Coarse';

  @override
  String get notifyTestTitle => 'Test notifications';

  @override
  String get notifyTestIntro =>
      'Tapping a row sends that alert for real. Major alerts play at full volume and sound through the silent switch and Do Not Disturb.';

  @override
  String get notifyTestCriticalDenied =>
      'Critical alerts aren\'t allowed on this device, so major alerts stay silent when your phone is.';

  @override
  String get notifyTestPermissionOff =>
      'Notifications are turned off, so a test won\'t show anything.';

  @override
  String get notifyTestBehaviourOverrides =>
      'Sounds through silent and Do Not Disturb';

  @override
  String get notifyTestBehaviourAlerts =>
      'Sound and a banner, unless your phone is silenced';

  @override
  String get notifyTestBehaviourSounds =>
      'Sound but no banner, unless your phone is silenced';

  @override
  String get notifyTestBehaviourSilent => 'Silent — notification list only';

  @override
  String get notifyTestFailed => 'Couldn\'t send the test notification.';

  @override
  String get moreBugReports => 'Bug reports';

  @override
  String get bugTrackerEmpty => 'No reported bugs yet';

  @override
  String get bugTrackerReplies => 'Replies';

  @override
  String get bugTrackerGoToDiscord =>
      'Can\'t find your issue? Report it on Discord!';

  @override
  String get bugTrackerNoMatch => 'No threads match the selected tags';

  @override
  String get bugTrackerDeveloper => 'Developer';

  @override
  String get bugTrackerCannotDisplay =>
      'This content can\'t be displayed here — view it on Discord';

  @override
  String get bugTrackerJoinDiscussion => 'Join the discussion on Discord';

  @override
  String get bugTrackerSortLast => 'Latest activity';

  @override
  String get bugTrackerSortMostDiscussed => 'Most discussed';

  @override
  String get bugTrackerStaff => 'Staff';

  @override
  String eewSpokenLocalIntensity(String intensity) {
    return 'Estimated intensity at your location: $intensity.';
  }

  @override
  String eewSpokenMaxIntensity(String intensity) {
    return 'Estimated maximum intensity: $intensity.';
  }
}
