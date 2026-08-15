// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Filipino Pilipino (`fil`).
class AppLocalizationsFil extends AppLocalizations {
  AppLocalizationsFil([String locale = 'fil']) : super(locale);

  @override
  String typhoonValueLat(String lat) {
    return '$lat°N';
  }

  @override
  String get onboardingSkipBody =>
      'Kung walang lokasyon at mga notification, hindi ka maaalertuhan ng DPIP nang real time sa mga lindol at sakuna malapit sa iyo. Maaari mo pa ring ibigay ang mga ito sa ibang pagkakataon sa Settings.';

  @override
  String get rainInterval24h => '24 oras';

  @override
  String homeRainTrendHeavyStopping(int minutes) {
    return 'Baka huminto ang malakas na ulan sa loob ng $minutes minuto';
  }

  @override
  String get mapTimelineObserved => 'Naobserbahan';

  @override
  String get regionSelectTitle => 'Pumili ng rehiyon';

  @override
  String get skyTimeNoon => 'Tanghali';

  @override
  String get radarCountyOutlineSubtitle =>
      'Nananatiling mababasa ang mga hangganan sa ilalim ng radar echo.';

  @override
  String get dpmFilterSectionRestroomType => 'Mga uri ng banyo';

  @override
  String get mapLayerSatelliteB03 => 'Himawari Red (B03)';

  @override
  String get reportFilterIntensity => 'Intensity';

  @override
  String get mapLayerLightning => 'Kidlat';

  @override
  String get restroomTypeMale => 'Palikuran ng lalaki';

  @override
  String get meshtasticLastReceived => 'Last received';

  @override
  String get reportDetailSortByCounty => 'Ayusin ayon sa lalawigan';

  @override
  String get homeRainTrendScattered => 'Posibleng mahinang ulan';

  @override
  String get meshtasticUptime => 'Uptime';

  @override
  String get weatherRankingTempExtremes => 'Mga sukdulan ng temperatura';

  @override
  String get themeLight => 'Maliwanag';

  @override
  String get mapTerrainReliefHint => 'Ipakita ang anino ng terrain sa base map';

  @override
  String get meshtasticEmptyMessage => '(empty message)';

  @override
  String get moreSectionRegion => 'Rehiyon';

  @override
  String get dpmDisasterEarthquake => 'Lindol';

  @override
  String get mapLayerSatellite => 'Himawari Infrared (B13)';

  @override
  String get aedHoursSaturday => 'Oras sa Sabado';

  @override
  String get dpmDisasterSlope => 'Panganib sa dalisdis';

  @override
  String get moonPhaseNew => 'New moon';

  @override
  String get notifySectionEew => 'Maagang babala sa lindol';

  @override
  String get mapResetNorth => 'Bumalik sa hilaga';

  @override
  String get rainInterval2d => '2 araw';

  @override
  String get mapTownLabelsHint =>
      'Ipakita ang mga pangalan ng bayan kapag naka-zoom';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get notifyOptTsunamiWarning => 'Mga babala sa tsunami lamang';

  @override
  String get mapLayerSatelliteBtdFog => 'Himawari Night Fog';

  @override
  String get moreSectionAdvanced => 'Advanced';

  @override
  String get weatherRankingExtremeRange => 'Saklaw sa araw';

  @override
  String get permissionsTitle => 'Pagsusuri ng pahintulot';

  @override
  String get permissionsBody =>
      'Kailangan ng DPIP ang mga pahintulot na ito para makapag-alerto agad. Kadalasan, ang dahilan ng hindi dumating na alerto ay isang nawawalang pahintulot.';

  @override
  String get notifySettingsMenu => 'Mga setting ng notipikasyon';

  @override
  String get typhoonHistoryTitle => 'Dataset time';

  @override
  String mapAppDefault(String app) {
    return '$app (default)';
  }

  @override
  String get trendRange24h => '24 oras';

  @override
  String get mapLayerStyleJmaTooltip =>
      'Grayscale base, tinted below −40 °C to highlight cloud-top height';

  @override
  String weatherRankingRecordedAt(String time) {
    return 'Naitala noong $time';
  }

  @override
  String get mapLayerRain => 'Ulan';

  @override
  String get mapLayerQpesums => 'Pagtaya ng ulan sa susunod na 1 oras';

  @override
  String get mapOverlaySectionMap => 'Mapa';

  @override
  String get mapTerrainRelief => 'Rehiyebo ng terrain';

  @override
  String get eewMaxIntensity => 'Pinakamataas na intensidad';

  @override
  String get mapLegendCollapse => 'Itago ang alamat';

  @override
  String get updateAvailableTitle => 'May bagong bersyon';

  @override
  String updateAvailableBody(String version) {
    return 'Available na ang bersyon $version.';
  }

  @override
  String get updateSkip => 'Laktawan muna';

  @override
  String get updateViewChangelog => 'Tingnan ang mga pagbabago';

  @override
  String get updateOpenAppStore => 'App Store';

  @override
  String get updateOpenTestFlight => 'TestFlight';

  @override
  String get updateOpenPlayStore => 'Play Store';

  @override
  String get updateDownload => 'I-download';

  @override
  String get changelogTitle => 'Changelog';

  @override
  String get reportFilterOrderDesc => 'Pababa';

  @override
  String get meshtasticExcludeMqttSubtitle =>
      'Nodes bridged over the internet, not heard by radio';

  @override
  String get reportFilterIntensityInfoTitle =>
      'Bagong at lumang intensity scale';

  @override
  String get mapLayerTyphoon => 'Bagyo';

  @override
  String get radarOverlayMenuTooltip => 'Mga opsyon sa layer ng radar';

  @override
  String get mapMyLocation => 'Aking lokasyon';

  @override
  String get meshtasticNodes => 'Nodes';

  @override
  String get meshtasticSend => 'Send';

  @override
  String get typhoonOverlayStormL7Tooltip =>
      'Level-7 wind field + average circle (purple)';

  @override
  String get aedType => 'Uri';

  @override
  String get termsOfService => 'Mga Tuntunin ng Serbisyo';

  @override
  String get typhoonLegendCircle25 => 'Storm circle (L10)';

  @override
  String get sponsorTitle => 'Suportahan ang DPIP';

  @override
  String get mapNavSatellite => 'Satellite';

  @override
  String homeRainTrendUpdated(String time) {
    return 'Na-update $time';
  }

  @override
  String get onboardingNext => 'Susunod';

  @override
  String get weatherRankingMergeTown => 'Bayan';

  @override
  String get mapLayerMonitor => 'Seismic Monitor';

  @override
  String get moreYoutube => 'YouTube';

  @override
  String get sponsorSubscriptions => 'Mga subscription';

  @override
  String typhoonValueLon(String lon) {
    return '$lon°E';
  }

  @override
  String get skyTime => 'Oras ng langit';

  @override
  String get weatherModeCloudy => 'Maulap';

  @override
  String get skyTimeDusk => 'Takipsilim';

  @override
  String get meshtasticFirmware => 'Firmware';

  @override
  String get reportFilterDateEndNote => 'End day: through 24:00（Taipei）';

  @override
  String get reportFilterSortMagnitude => 'Magnitude';

  @override
  String get meshtasticSilent => 'Silent';

  @override
  String get mapLayerCategoryEarthquake => 'Lindol';

  @override
  String get mapLayerSatelliteB12 => 'Himawari Ozone (B12)';

  @override
  String get typhoonLegendPast => 'Aktwal na landas';

  @override
  String get restroomCategoryOther => 'Iba pa';

  @override
  String homeForecastHighLow(String high, String low) {
    return 'T $high° · B $low°';
  }

  @override
  String get locationBannerFix => 'Buksan ang mga setting';

  @override
  String get mapLegendExpand => 'Alamat';

  @override
  String get eewNone => 'Walang aktibong maagang babala sa lindol';

  @override
  String typhoonTyNo(String no) {
    return 'TY $no';
  }

  @override
  String get notifyOptTsunamiAll => 'Mga abiso at babala sa tsunami';

  @override
  String get meshtasticLayerOptions => 'Node options';

  @override
  String get onboardingAgreeContinue => 'Sumang-ayon at magpatuloy';

  @override
  String get commonRetry => 'Subukan Muli';

  @override
  String get meshtasticNodeId => 'Node ID';

  @override
  String reportDetailNumbered(String number) {
    return 'Blg. $number Makabuluhang Naramdamang Lindol';
  }

  @override
  String get typhoonOverlayStormBandSubtitle => 'With average circle';

  @override
  String get disasterMapOverlayRestroomTooltip =>
      'Ipakita ang mga pampublikong palikuran';

  @override
  String get weatherRankingTitle => 'Mga ranggo ng obserbasyon';

  @override
  String get homeRainTrendHeavySustained =>
      'Tuloy-tuloy na malakas na ulan sa susunod na oras';

  @override
  String get notifySectionTsunami => 'Tsunami';

  @override
  String get restroomCategoryPark => 'Parke';

  @override
  String get moreLinkOpenFailed => 'Hindi mabuksan ang link';

  @override
  String get themeDark => 'Madilim';

  @override
  String get sponsorRestore => 'Ibalik ang mga pagbili';

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
  String get mapLayerHumidity => 'Halumigmig';

  @override
  String get mapLayerSatelliteTransparentNight =>
      'Night = transparent, the basemap shows';

  @override
  String get meshtasticScanning => 'Scanning…';

  @override
  String regionSelectFull(int max) {
    return 'Maaari kang mag-save ng hanggang $max na rehiyon';
  }

  @override
  String get meshtasticTitle => 'Meshtastic';

  @override
  String get navMore => 'Higit Pa';

  @override
  String get meshtasticDpipChannel => 'DPIP channel';

  @override
  String get disasterMapOverlaySectionLayers => 'Layers';

  @override
  String get mapLayerSatelliteB05 => 'Himawari Near-Infrared (B05)';

  @override
  String typhoonStormRadii(String ne, String se, String sw, String nw) {
    return 'NE $ne · SE $se · SW $sw · NW $nw km';
  }

  @override
  String get typhoonLabelNe => 'NE';

  @override
  String get meshtasticCopied => 'Message copied';

  @override
  String get reportListEmpty => 'Walang ulat ng lindol';

  @override
  String get reportListEnd => 'Dulo ng listahan';

  @override
  String get mapLayerSatelliteTruecolor => 'Himawari True Color';

  @override
  String get typhoonOverlaySectionExtra => 'Overlays';

  @override
  String get eewSWave => 'S wave';

  @override
  String get meshtasticBusyTitle => 'Another app is using this radio';

  @override
  String get restroomCategoryCultural => 'Pook na pangkultura';

  @override
  String get typhoonLabelWind => 'Max. sustained wind near centre';

  @override
  String get radarGlobalOutlineHint => 'Panlabas na balangkas ng bawat bansa';

  @override
  String get notifyEvacuation => 'Impormasyon sa sakuna';

  @override
  String get typhoonLegendCircle15 => 'Gale circle (L7)';

  @override
  String get dataSectionAstronomy => 'Astronomy';

  @override
  String get homeRainTrendLightSustained =>
      'Tuloy-tuloy na mahinang ulan sa susunod na oras';

  @override
  String get commonError => 'May Nangyaring Mali';

  @override
  String get moonPhaseWaningCrescent => 'Waning crescent';

  @override
  String get meshtasticPower => 'Power';

  @override
  String get mapTimelineNow => 'Ngayon';

  @override
  String reportFilterRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String get reportDetailOpenReport => 'Pahina ng Ulat';

  @override
  String get trendRange7d => '7 araw';

  @override
  String typhoonWarningAreas(String areas) {
    return 'Areas: $areas';
  }

  @override
  String get rainIntervalSection => 'Window ng oras';

  @override
  String get notifyTitle => 'Mga Notipikasyon';

  @override
  String get meshtasticTxPower => 'TX power';

  @override
  String get restroomCategoryLabel => 'Kategorya';

  @override
  String get sponsorRestoring => 'Ibinabalik ang mga pagbili…';

  @override
  String get sponsorIntro =>
      'Nakatuon ang DPIP sa pagbibigay ng real-time na impormasyon sa pag-iwas sa sakuna, nang walang ad o iba pang modelo ng kita. Tumutulong ang inyong suporta na mapanatili ang mga server at magpatuloy sa pagbuo.';

  @override
  String get shelterAddressLabel => 'Address';

  @override
  String get typhoonLabelStormAvg => 'Avg. radius of Beaufort 10 winds';

  @override
  String get restroomCategoryCommercial => 'Komersyal na establisyimento';

  @override
  String get aedRegion => 'Rehiyon';

  @override
  String homeRainTrendLightStopping(int minutes) {
    return 'Baka huminto ang mahinang ulan sa loob ng $minutes minuto';
  }

  @override
  String get reportDetailInfo => 'Mga Detalye';

  @override
  String get mapNavWind => 'Hangin';

  @override
  String get windForecastOverlayMenuTooltip =>
      'Mga opsyon sa layer ng pagtataya ng hangin';

  @override
  String get dataWeatherRankingSubtitle => 'Live na ranggo ng istasyon';

  @override
  String homeRainTrendMinute(int minute) {
    return '$minute min';
  }

  @override
  String get rainInterval6h => '6 oras';

  @override
  String get restroomTypeUnspecified => 'Hindi natukoy';

  @override
  String get typhoonOverlayProbabilityHint => 'Hides the forecast cone';

  @override
  String get mapLayerSatelliteGlobalOutline => 'Country border';

  @override
  String get mapNavTemperature => 'Temperatura';

  @override
  String get typhoonLegendForecastPoint => 'Punto ng forecast';

  @override
  String get reportListYesterday => 'Kahapon';

  @override
  String get moreSectionLinks => 'Mga Link';

  @override
  String get feedOffline => 'Nawala ang koneksyon';

  @override
  String get mapLayerStyleBd => 'Dvorak BD';

  @override
  String get moreSectionDisplay => 'Display';

  @override
  String get rainInterval3d => '3 araw';

  @override
  String get defaultMapLayerSubtitle =>
      'Bubukas ang tab ng Mapa sa layer na ito. Susunod ang icon at label ng bottom navigation.';

  @override
  String get aedDescription => 'Tala';

  @override
  String get typhoonOverlayWeatherRadarTooltip =>
      'Radar echo closest to the typhoon bulletin time';

  @override
  String get onboardingPermLocationDesc =>
      'Itutok ang mga alerto sa kinaroroonan mo.';

  @override
  String get mapLayerSatelliteB16 => 'Himawari CO₂ (B16)';

  @override
  String get homeActiveEventsEmpty => 'Walang aktibong event';

  @override
  String get typhoonLabelPosition => 'Centre location';

  @override
  String get weatherRankingBy => 'Ayon sa';

  @override
  String get typhoonIntensityMild => 'Mild typhoon';

  @override
  String get windForecastGlobalOutlineHint =>
      'Panlabas na balangkas ng bawat bansa';

  @override
  String get rainInterval1h => '1 oras';

  @override
  String get eewLocalIntensity => 'Tantiya sa lokasyon';

  @override
  String get mapLayerRadar => 'Composite Radar Reflectivity';

  @override
  String get restroomCategoryReligious => 'Relihiyosong lugar';

  @override
  String get meshtasticRole => 'Role';

  @override
  String get mapLayerSatelliteCloudCloudy => 'Cloudy';

  @override
  String get skyTimeSunrise => 'Pagsikat ng araw';

  @override
  String get meshtasticNoMessages => 'No messages yet';

  @override
  String get onboardingPermNotifyDesc =>
      'Ihatid ang mga alerto sa lindol, panahon, at sakuna sa sandaling maganap ang mga ito.';

  @override
  String get radarTownOutline => 'Mga hangganan ng bayan';

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
  String get dpmDisasterTsunami => 'Tsunami';

  @override
  String get changelogTypeStable => 'Stable';

  @override
  String get mapLayerSatelliteTransparentClear =>
      'Clear sky = transparent, the basemap shows';

  @override
  String get mapOverlaySectionReference => 'Layer ng sanggunian';

  @override
  String get mapLayerSatelliteB02 => 'Himawari Green (B02)';

  @override
  String get reportListLocalFelt => 'Lokal na naramdaman';

  @override
  String get weatherRankingEmpty => 'Walang obserbasyon na iraranggo';

  @override
  String get notifySectionOther => 'Iba pa';

  @override
  String weatherRankingMeta(String time, int count) {
    return 'Oras ng datos: $time\n$count istasyon';
  }

  @override
  String get onboardingTermsAgree =>
      'Nabasa ko na at sumasang-ayon ako sa Mga Tuntunin ng Serbisyo';

  @override
  String get mapLayerSatelliteTransparentNoVegetation =>
      'Below 0.1 = transparent (no vegetation)';

  @override
  String get notifyOptLocalIntensity4 => 'Lokal na intensidad 4 pataas';

  @override
  String get eewArrived => 'Dumating';

  @override
  String get meshtasticNoDevices => 'No Meshtastic devices found';

  @override
  String get mapLayerCategoryLife => 'Pang-araw-araw na buhay';

  @override
  String get reportFilterSortIntensity => 'Intensity';

  @override
  String get typhoonMotion => 'Gumagalaw';

  @override
  String get meshtasticStateDisconnected => 'Disconnected';

  @override
  String get typhoonIntensityIntense => 'Intense typhoon';

  @override
  String get mapLayerOrderTitle => 'Ayusin ang ayos ng layer';

  @override
  String get dpmYes => 'Oo';

  @override
  String get meshtasticNoHistory => 'Not enough history yet';

  @override
  String get reportDetailLocalIntensityUnavailable =>
      'Walang datos ng intensity';

  @override
  String get mapLayerWindForecastGfs => 'GFS';

  @override
  String get reportListDepthUnit => 'km';

  @override
  String get reportFilterDepth => 'Depth';

  @override
  String get onboardingScrollHint => 'Mag-scroll pababa para magpatuloy';

  @override
  String get mapNavQpesums => 'Pagtaya';

  @override
  String get navMap => 'Mapa';

  @override
  String get notifyAdvisory => 'Mga advisory sa panahon';

  @override
  String get reportFilterReset => 'I-reset';

  @override
  String get mapLayerSatelliteMndwi => 'Himawari MNDWI';

  @override
  String get typhoonOverlaySectionStorm => 'Storm wind';

  @override
  String get moonPhaseFull => 'Full moon';

  @override
  String get moonPhaseWaningGibbous => 'Waning gibbous';

  @override
  String get weatherDynamicStateSubtitle =>
      'I-override ang panahon sa background ng home';

  @override
  String get reportFilterIntensityInfoModernTitle => 'Bago (mula 2020)';

  @override
  String typhoonDataTime(String time) {
    return 'Data time\n$time';
  }

  @override
  String get restroomTypeAccessible => 'Palikurang may accessibility';

  @override
  String get moreSectionAbout => 'Tungkol';

  @override
  String get meshtasticSelectDevice => 'Select a radio';

  @override
  String get onboardingIntroBody =>
      'Ang DPIP ang iyong kasama sa pag-iwas sa sakuna. Pinagsasama-sama nito ang mga maagang babala sa lindol, ulat ng lindol, panahon, at impormasyon sa panganib, at inaalertuhan ka sa sandaling mahalaga ito.\n\n• Mga lindol: mga maagang babala, ulat ng intensidad, at detalyadong ulat\n• Panahon: real-time na mensahe ng kulog at kidlat at mga advisory sa panahon\n• Impormasyon sa tsunami at sakuna\n\nSusunod, hihilingin naming basahin mo ang Mga Tuntunin ng Serbisyo at magbigay ng ilang pahintulot para maprotektahan ka ng DPIP nang real time.';

  @override
  String get shelterCapacityLabel => 'Kapasidad';

  @override
  String get reportDetailImage => 'Larawan ng Ulat';

  @override
  String get meshtasticStateConfiguring => 'Configuring…';

  @override
  String get typhoonLabelGaleAvg => 'Avg. radius of Beaufort 7 winds';

  @override
  String get onboardingPermNotify => 'Mga Notipikasyon';

  @override
  String get meshtasticClearMessages => 'Clear messages';

  @override
  String get meshtasticNotifyMessages => 'Notify on new messages';

  @override
  String get defaultMapLayerSettings => 'Default na layer ng mapa';

  @override
  String get moreSectionNotify => 'Mga Abiso';

  @override
  String get notifyUnavailable =>
      'Hindi pa handa ang push notifications — subukan muli mamaya.';

  @override
  String get mapLayerOrderReset => 'I-reset ang ayos';

  @override
  String get dpmAddress => 'Address';

  @override
  String get weatherRankingMergeCounty => 'Lalawigan';

  @override
  String get moreSectionApp => 'Kunin ang app';

  @override
  String get reportFilterIntensityInfoLegacyBody =>
      'Antas 0–7 lang; walang 5−/5+/6−/6+.';

  @override
  String get mapLayerSatelliteSst => 'Himawari Sea Surface Temperature';

  @override
  String get qpesumsOverlayMenuTooltip =>
      'Mga opsyon sa layer ng pagtataya ng pag-ulan';

  @override
  String get mapTimelineFuture => 'Hinaharap';

  @override
  String get typhoonLegendCircleAvg => 'Average circle';

  @override
  String reportFilterDepthKm(String depth) {
    return '$depth km';
  }

  @override
  String get typhoonLabelSe => 'SE';

  @override
  String get radarTownOutlineHint => 'Mas pinong hati';

  @override
  String eewCountdown(int seconds) {
    return '$seconds segundo';
  }

  @override
  String get typhoonLabelGust => 'Peak gust';

  @override
  String get mapAppGoogleMaps => 'Google Maps';

  @override
  String get sponsorTerms => 'Mga Tuntunin ng Paggamit';

  @override
  String get restroomTypeGenderNeutral => 'Palikurang neutral sa kasarian';

  @override
  String get notifyThunderstorm => 'Mga alerto sa kulog at kidlat';

  @override
  String get skyTimeGolden => 'Gintong oras';

  @override
  String get moonAge => 'Age';

  @override
  String get meshtasticRadioSettings => 'LoRa';

  @override
  String weatherRankingAnalysisCurrent(String value) {
    return 'Ngayon $value°C';
  }

  @override
  String get moreGithub => 'ExpTech GitHub';

  @override
  String get homeForecastUnavailable =>
      'Pumili ng bayan para makita ang forecast';

  @override
  String get mapLayers => 'Mga Layer';

  @override
  String get meshtasticHardware => 'Hardware';

  @override
  String get languageSettings => 'Wika';

  @override
  String get dpmDisasterNuclear => 'Aksidente sa nukleyar';

  @override
  String get language => 'Wika';

  @override
  String homeForecastFeelsLike(String temp) {
    return 'Pakiramdam $temp°';
  }

  @override
  String get typhoonOverlayWeatherHint => 'Aligned to bulletin time';

  @override
  String get skyTimeDawn => 'Bukang-liwayway';

  @override
  String get skyTimeAfternoon => 'Hapon';

  @override
  String get meshtasticLastHeard => 'Last heard';

  @override
  String get typhoonWarningTitle => 'Typhoon warning';

  @override
  String get moreSourceCode => 'Source code';

  @override
  String get mapLayerCategoryWeather => 'Obserbasyon sa panahon';

  @override
  String get mapLayerSatelliteB09 => 'Himawari Mid Water Vapour (B09)';

  @override
  String get windForecastTownOutlineHint => 'Ang mas pinong mesh';

  @override
  String get mapLayerSatelliteCloudmask => 'Himawari Cloud Mask';

  @override
  String get mapAppCopyCoordinates => 'Kopyahin ang coordinates';

  @override
  String get reportFilterIntensityInfoIntro =>
      'Pinalitan ng CWA ang intensity scale noong 1 Ene 2020 (oras ng Taipei).';

  @override
  String get mapNavEarthquake => 'Lindol';

  @override
  String get typhoonGust => 'Ugong';

  @override
  String get restroomGradeAverage => 'Katamtaman';

  @override
  String get mapLayerSatelliteBtdCo2 => 'Himawari Cirrus / Cloud Height';

  @override
  String get onboardingPermBackgroundDesc =>
      'Payagan ang \"Always\" para patuloy kang matukoy ng mga alerto kahit sarado ang app.';

  @override
  String get mapTimelineForecast => 'Pagtaya';

  @override
  String get restroomTypeLabel => 'Uri';

  @override
  String get navEarthquake => 'Lindol';

  @override
  String get typhoonOverlayStormL10Tooltip =>
      'Level-10 wind field + average circle (yellow)';

  @override
  String get moonPhaseWaxingGibbous => 'Waxing gibbous';

  @override
  String get reportDetailTitle => 'Ulat ng Lindol';

  @override
  String get moreTremReport => 'Ulat ng pagtukoy ng TREM';

  @override
  String weatherDataTime(String station, String time) {
    return '$station · Oras ng datos $time';
  }

  @override
  String get meshtasticNoNodes => 'No nodes heard yet';

  @override
  String get meshtasticViaMqtt => 'Via MQTT (internet)';

  @override
  String get radarCountyOutline => 'Mga hangganan ng lalawigan';

  @override
  String get onboardingGranted => 'Naibigay na';

  @override
  String get commonClose => 'Isara';

  @override
  String get restroomGradeLabel => 'Baitang';

  @override
  String get rainIntervalNow => 'Ngayon';

  @override
  String get changelogCurrentVersion => 'Kasalukuyan';

  @override
  String get typhoonLabelPressure => 'Central pressure';

  @override
  String get typhoonOverlayForecastCalloutsTooltip =>
      'Show forecast-point detail cards when zoomed in';

  @override
  String get aedOpenRemark => 'Tala sa oras';

  @override
  String get onboardingPermsBody =>
      'Para maalertuhan ka ng DPIP sa sandaling maganap ang sakuna, mangyaring ibigay ang mga sumusunod. Maaari mo itong baguhin anumang oras sa mga setting ng system.';

  @override
  String get typhoonOverlaySectionWeather => 'Weather underlay';

  @override
  String get notifyOptWeatherLocal => 'Kasalukuyang lokasyon lamang';

  @override
  String get mapNavRain => 'Ulan';

  @override
  String get moonDays => 'days';

  @override
  String mapLegendUnit(String unit) {
    return 'Yunit: $unit';
  }

  @override
  String get weatherModeClear => 'Maaliwalas';

  @override
  String get meshtasticRadio => 'Radio';

  @override
  String get commonEmpty => 'Walang Maipakita';

  @override
  String get mapLayerSatelliteB01 => 'Himawari Blue (B01)';

  @override
  String get meshtasticExternalPower => 'External power';

  @override
  String get moonPhaseLastQuarter => 'Last quarter';

  @override
  String get reportFilterOrderAsc => 'Pataas';

  @override
  String get reportFilterApply => 'I-apply';

  @override
  String get reportDetailImageUnavailable =>
      'Wala pang available na larawan ng ulat';

  @override
  String get weatherRankingHighest => 'Pinakamataas';

  @override
  String get reportDetailReplay => 'I-replay';

  @override
  String get mapLayerRestroom => 'Pampublikong Palikuran';

  @override
  String get restroomCategoryWelfare => 'Institusyon ng kapakanan';

  @override
  String get restroomGradeExcellent => 'Napakahusay';

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
  String get themeSystem => 'Sistema';

  @override
  String get mapLayerSatelliteNdvi => 'Himawari NDVI';

  @override
  String get typhoonLegendForecast => 'Tinatayang landas';

  @override
  String typhoonValueHpa(String n) {
    return '$n hPa';
  }

  @override
  String get weatherPrecipitation => 'Pag-ulan';

  @override
  String get moonNextFullMoon => 'Next full moon';

  @override
  String get dpmSheetEmpty => 'I-tap ang marker sa mapa para sa detalye';

  @override
  String get onboardingSkipLeave => 'Laktawan pa rin';

  @override
  String get onboardingBack => 'Bumalik';

  @override
  String get aedPlaceDesc => 'Lokasyon ng paglagay';

  @override
  String get onboardingSkipTitle => 'Hindi pa naibibigay ang mga pahintulot';

  @override
  String get restroomTypeFamily => 'Palikuran ng pamilya';

  @override
  String typhoonValueKm(String n) {
    return '$n km';
  }

  @override
  String get typhoonPressure => 'Presyon';

  @override
  String get onboardingPermBattery => 'Exemption sa baterya';

  @override
  String get typhoonLabelNw => 'NW';

  @override
  String get dpmDisasterFlood => 'Baha';

  @override
  String get moonPhaseWaxingCrescent => 'Waxing crescent';

  @override
  String get restroomCategoryLeisure => 'Lugar ng libangan';

  @override
  String get mapLayerTemperature => 'Temperatura';

  @override
  String get aedCategory => 'Kategorya';

  @override
  String get meshtasticChannels => 'Channels';

  @override
  String get monitorWaiting => 'Naghihintay ng data…';

  @override
  String get typhoonOverlayForecastCallouts => 'Forecast tooltips';

  @override
  String get reportDetailEpicenter => 'Coordinates ng Epicenter';

  @override
  String get meshtasticVoltage => 'Voltage';

  @override
  String get mapLayerMeshtasticSubtitle =>
      'LoRa mesh nodes heard by your radio';

  @override
  String get mapLayerWind => 'Hangin';

  @override
  String get reportDetailMagnitude => 'Magnitude';

  @override
  String get reportDetailAreaIntensity => 'Intensity ayon sa lugar';

  @override
  String get rainInterval12h => '12 oras';

  @override
  String reportListMagnitude(String magnitude) {
    return 'M$magnitude';
  }

  @override
  String get dpmDisasterLandslide => 'Pagguho ng lupa';

  @override
  String get notifyMonitor => 'Monitor ng malakas na paggalaw';

  @override
  String get onboardingStart => 'Magsimula';

  @override
  String sponsorPerMonth(String price) {
    return '$price / buwan';
  }

  @override
  String get mapLayerPressure => 'Presyon';

  @override
  String get mapLayerSatelliteB04 => 'Himawari Near-Infrared (B04)';

  @override
  String get mapLayerSatelliteTransparentZero =>
      'Zero difference = transparent (no signal)';

  @override
  String get shelterIndoorLabel => 'Silungan sa loob';

  @override
  String get notifyOptOff => 'Naka-off';

  @override
  String get reportFilterSortTime => 'Oras';

  @override
  String get mapLayerSatelliteCloudProbablyClear => 'Probably clear';

  @override
  String get weatherModeThunderstorm => 'Kulog at Kidlat';

  @override
  String get homeViewOnMap => 'Tingnan sa mapa';

  @override
  String get reportFilterIntensityInfoLegacyTitle => 'Luma (bago ang 2020)';

  @override
  String get typhoonLabelSpeed => 'Past movement speed';

  @override
  String mapAppOpenFailed(String app) {
    return 'Hindi mabuksan ang $app';
  }

  @override
  String get mapLayerSatelliteRgbComposite => 'RGB composite (JMA recipe)';

  @override
  String get meshtasticReceived => 'Received';

  @override
  String get weatherRankingExtremeLow => 'Pinakamababa ngayong araw';

  @override
  String get mapLayerSatelliteB10 => 'Himawari Lower Water Vapour (B10)';

  @override
  String get mapLayerSatelliteCloudProbablyCloudy => 'Probably cloudy';

  @override
  String get mapLayerSatelliteTransparentNoWater =>
      '≤ 0 = transparent (no water)';

  @override
  String get shelterCategoryLabel => 'Mga uri ng kalamidad';

  @override
  String get meshtasticStateConnecting => 'Connecting…';

  @override
  String get moonTitle => 'Moon';

  @override
  String get weatherRankingGust => 'Bugso';

  @override
  String get moreAppStore => 'App Store';

  @override
  String get dpmFilterSectionShelter => 'Mga uri ng sakuna sa silungan';

  @override
  String get moreServerStatus => 'Katayuan ng server';

  @override
  String get notifySectionWeather => 'Panahon';

  @override
  String get meshtasticPreset => 'Modem preset';

  @override
  String get dataSectionSeismic => 'Seismic';

  @override
  String get changelogBodyEmpty => 'Walang tala para sa release na ito.';

  @override
  String get radarGlobalOutline => 'Mga hangganan ng bansa';

  @override
  String get notifyEew => 'Emergency na alerto sa lindol';

  @override
  String get regionNationwide => 'Buong bansa';

  @override
  String get moreNotifyLog => 'Log ng notipikasyon ng DPIP';

  @override
  String get regionCurrent => 'Kasalukuyang lokasyon';

  @override
  String get dpmFilterSectionRestroom => 'Mga uri ng lugar';

  @override
  String get meshtasticNotConnected => 'Not connected to a radio';

  @override
  String get weatherModeSnow => 'Niyebe';

  @override
  String get mapLayerMeshtastic => 'Meshtastic nodes';

  @override
  String get moreDeveloper => 'Impormasyon sa debug';

  @override
  String get mapLayerSatelliteB14 => 'Himawari Longwave Infrared (B14)';

  @override
  String get meshtasticChannelUse => 'Channel use';

  @override
  String get mapNavLightning => 'Kidlat';

  @override
  String get homeForecastEmpty => 'Walang forecast';

  @override
  String get sponsorOneTime => 'Isang beses';

  @override
  String get mapLayerSatelliteBtdSplit => 'Himawari Split Window';

  @override
  String get onboardingPermBackground => 'Lokasyon sa background';

  @override
  String get aedEmergencyPhone => 'Emergency phone';

  @override
  String get dpmOpenInMaps => 'Buksan sa mapa';

  @override
  String get meshtasticNotifyNodes => 'Notify on new nodes';

  @override
  String get onboardingPermCriticalDesc =>
      'Hayaang tumunog ang mga nakamamatay na babala sa lindol kahit sa silent mode o Do Not Disturb.';

  @override
  String get mapLayerSatelliteTransparentWarm =>
      'Clear sky (warm end) = transparent, the basemap shows';

  @override
  String get meshtasticSent => 'Sent';

  @override
  String get homeForecastTitle => '24-oras na forecast';

  @override
  String get typhoonLegendWarningAreas => 'Warning areas';

  @override
  String meshtasticExcludeMqttHidden(int count) {
    return '$count hidden';
  }

  @override
  String get notifyOptLocalIntensity1 => 'Lokal na intensidad 1 pataas';

  @override
  String get mapTimelinePast => 'Nakaraan';

  @override
  String get restroomTypeFemale => 'Palikuran ng babae';

  @override
  String get reportListToday => 'Ngayon';

  @override
  String get meshtasticTapNode => 'Tap a node for details';

  @override
  String get commonLoading => 'Naglo-load…';

  @override
  String get typhoonIntensityModerate => 'Moderate typhoon';

  @override
  String get typhoonWind => 'Hangin';

  @override
  String get mapLayerSatelliteAsh => 'Himawari Ash';

  @override
  String get rainInterval3h => '3 oras';

  @override
  String get reportListSearch => 'Maghanap';

  @override
  String get mapLayerCategorySatellite => 'Satellite';

  @override
  String get meshtasticChannelReady => 'DPIP channel ready';

  @override
  String get reportFilterLocation => 'Lokasyon';

  @override
  String get mapLayerSatelliteNightmicrophysics =>
      'Himawari Night Microphysics';

  @override
  String get typhoonIntensityTd => 'Tropical depression';

  @override
  String get reportFilterDate => 'Petsa';

  @override
  String get sponsorRestoreUnavailable =>
      'Hindi maabot ang store. Pakisubukan muli mamaya.';

  @override
  String homeForecastPop(String pop) {
    return '$pop%';
  }

  @override
  String get regionEmpty => 'Wala pang naka-save na rehiyon';

  @override
  String get onboardingPermBatteryDesc =>
      'Payagan ang DPIP na patuloy na tumakbo sa background para hindi maantala o mapalampas ang mga alerto.';

  @override
  String get mapNavDisaster => 'Sakuna';

  @override
  String get radarScanRangeSubtitle =>
      'Ipinapakita ang aktwal na saklaw ng apat na radar.';

  @override
  String get aedHoursSunday => 'Oras sa Linggo';

  @override
  String get reportDetailOriginTime => 'Oras ng pangyayari';

  @override
  String get trendNoData => 'Walang trend data';

  @override
  String get onboardingPermLocation => 'Lokasyon';

  @override
  String get moreDiscord => 'Komunidad sa Discord';

  @override
  String get mapNavPressure => 'Presyon';

  @override
  String get mapLayerSatelliteB13 => 'Himawari Infrared (B13)';

  @override
  String typhoonTdNo(String no) {
    return 'TD $no';
  }

  @override
  String get changelogEmpty => 'Wala pang release notes';

  @override
  String get reportFilterDateStartNote => 'Start day: from 00:00（Taipei）';

  @override
  String get eewTitle => 'Maagang babala sa lindol';

  @override
  String get mapLayerWindForecastEcmwf => 'ECMWF';

  @override
  String regionSelectCount(int count, int max) {
    return '$count/$max ang napili';
  }

  @override
  String get mapLayerSatelliteBtdSo2 => 'Himawari SO₂ / Cloud Phase';

  @override
  String get meshtasticStateError => 'Error';

  @override
  String get weatherModeOvercast => 'Makulimlim';

  @override
  String get reportDetailDepth => 'Lalim ng Hypocenter';

  @override
  String get typhoonOverlayWarningTooltip =>
      'Highlight counties under a typhoon warning';

  @override
  String get reportFilterDatePick => 'Pumili ng petsa';

  @override
  String get onboardingSkipStay => 'Bumalik';

  @override
  String get commonFetchFailed => 'Hindi ma-load ang data. Pakisubukan muli.';

  @override
  String get shelterOutdoorLabel => 'Silungan sa labas';

  @override
  String get meshtasticStateConnected => 'Connected';

  @override
  String get mapNavRadar => 'Radar';

  @override
  String get mapLayerSatelliteCloudClear => 'Clear';

  @override
  String eewSummary(String magnitude, String depth) {
    return 'M$magnitude · lalim $depth km';
  }

  @override
  String get locationBannerPermission =>
      'Naka-off ang pahintulot sa lokasyon — hindi matutukoy ng mga lokal na alerto ang iyong lugar.';

  @override
  String get typhoonOverlayWeatherNoneTooltip =>
      'No radar or infrared underlay';

  @override
  String get radarCountyOutlineHint => 'Iginuguhit sa ibabaw ng echo';

  @override
  String get windForecastCountyOutlineHint =>
      'Iginuhit sa itaas ng patlang ng hangin';

  @override
  String get homeRainTrendTitle => 'Ulan sa susunod na oras';

  @override
  String get moonPhaseFirstQuarter => 'First quarter';

  @override
  String get mapLayerCategoryTyphoon => 'Bagyo';

  @override
  String get meshtasticUtilization => 'Airtime (24h)';

  @override
  String get restroomTypeMixed => 'Pinagsamang palikuran';

  @override
  String get restroomGradeGood => 'Mahusay';

  @override
  String get notifyTsunami => 'Impormasyon sa tsunami';

  @override
  String get navData => 'Datos';

  @override
  String get mapLayerSatelliteBtdWvirw => 'Himawari Overshooting Top';

  @override
  String get meshtasticReadingAge => 'Reading taken';

  @override
  String get mapAppCallFailed => 'Hindi makatawag ang device na ito';

  @override
  String get reportFilterAny => 'Lahat';

  @override
  String get weatherRankingMergeTo => 'Pagsamahin';

  @override
  String get notifyIntensity => 'Ulat ng intensidad';

  @override
  String typhoonTimeChip(String day, String hour) {
    return '$day日$hour時';
  }

  @override
  String get rainIntervalMenu => 'Bintana ng akumulasyon';

  @override
  String get reportDetailLocalFelt => 'Lokal na Naramdamang Lindol';

  @override
  String get meshtasticDevice => 'Device';

  @override
  String get onboardingGrant => 'Ibigay';

  @override
  String get weatherModeRain => 'Ulan';

  @override
  String get shelterVulnerableOkLabel => 'Angkop para sa mahihina';

  @override
  String get stationSheetEmpty => 'I-tap ang istasyon para makita ang datos';

  @override
  String get typhoonLegendProbability => 'Strike probability';

  @override
  String get reportFilterMagnitude => 'Magnitude';

  @override
  String get skyTimeMorning => 'Umaga';

  @override
  String get experimentalFeatures => 'Mga experimental na feature';

  @override
  String get onboardingTermsBody =>
      'Mangyaring basahin ang mga sumusunod na paunawa bago gamitin ang DPIP:\n\n• Ang lahat ng impormasyon ay dapat sumunod sa nilalamang inilathala ng Central Weather Administration (CWA).\n\n• Depende sa kalagayan ng network, server, app, at pinagmumulan ng datos, may posibilidad na hindi matanggap ang impormasyon; ginagawa namin ang lahat ng aming makakaya upang maiwasan ito ngunit hindi namin magagarantiya na hindi ito mangyayari.\n\n• Maaaring maunang makarating sa iyong lokasyon ang malakas na pagyanig bago pa dumating ang notipikasyon.\n\n• Ang mga maagang babala sa lindol ay mabilis na kinakalkulang resulta na maaaring magtaglay ng malaking pagkakamali — unawain ito at gamitin nang may pag-iingat.\n\n• Anumang gawaing hindi pinahihintulutan ng mga awtoridad ay maaaring magdala ng panganib sa batas; mangyaring sundin ang lahat ng naaangkop na regulasyon.\n\nBukod dito, upang magbigay ng lokal na mga alerto, kinokolekta at ini-upload ng serbisyong ito ang iyong tinatayang lokasyon at push identifier — sa foreground at background — para lamang matukoy kung aling mga alerto ang ipapadala sa iyo.\n\nSa pamamagitan ng pag-tap sa \"Sumang-ayon at magpatuloy\" kinukumpirma mo na nabasa, naunawaan, at sinasang-ayunan mo ang nasa itaas.';

  @override
  String get reportFilterTitle => 'Mga filter';

  @override
  String get onboardingPermCritical => 'Mga kritikal na alerto';

  @override
  String trendCumulativeTotal(String total) {
    return 'Kabuuang $total mm';
  }

  @override
  String get languageName => 'Filipino';

  @override
  String get reportListEmptyFiltered =>
      'Walang ulat na tumutugma sa mga filter';

  @override
  String get meshtasticExcludeMqtt => 'Hide MQTT nodes';

  @override
  String get mapNavTyphoon => 'Bagyo';

  @override
  String get weatherModeSand => 'Alikabok';

  @override
  String get typhoonSatelliteTitle => 'Satellite';

  @override
  String get notifyReport => 'Ulat ng lindol';

  @override
  String get mapAppCoordinatesCopied => 'Na-kopya ang coordinates';

  @override
  String get skyTimeNight => 'Gabi';

  @override
  String get sponsorRecommended => 'Inirerekomenda';

  @override
  String get mapLayerSatelliteB15 => 'Himawari Longwave Infrared (B15)';

  @override
  String get weatherRankingWind => 'Bilis ng hangin';

  @override
  String get feedStale => 'Maaaring luma na ang datos';

  @override
  String homeForecastWind(String direction, String level) {
    return '$direction · Force $level';
  }

  @override
  String get navHome => 'Tahanan';

  @override
  String get meshtasticRegionLabel => 'Region';

  @override
  String get mapLayerSatelliteCloudtop => 'Himawari Cloud Top Temperature';

  @override
  String get moonTimelineCaption => 'Phase';

  @override
  String reportListMeta(String magnitude, String depth) {
    return 'M$magnitude · $depth km';
  }

  @override
  String get openSourceLicenses => 'Mga lisensya ng open-source';

  @override
  String get weatherRankingLowest => 'Pinakamababa';

  @override
  String get reportFilterSortDepth => 'Lalim';

  @override
  String mapTimelineDataTime(String time) {
    return 'Oras ng data $time';
  }

  @override
  String get radarScanRange => 'Ipakita ang saklaw ng pag-scan';

  @override
  String get meshtasticHopLimit => 'Hop limit';

  @override
  String weatherRankingAnalysisRange(String value) {
    return 'Saklaw $value°C';
  }

  @override
  String get weatherRankingExtremeHigh => 'Pinakamataas ngayong araw';

  @override
  String get changelogVersionDetails => 'Detalye ng release';

  @override
  String get sponsorPrivacy => 'Patakaran sa Privacy';

  @override
  String get reportDetailLocalIntensity => 'Intensity sa iyong lokasyon';

  @override
  String get mapLayerSatelliteNaturalcolor => 'Himawari Natural Color';

  @override
  String get meshtasticAirtime => 'Air time (TX)';

  @override
  String shelterCapacityValue(int n) {
    return '$n katao';
  }

  @override
  String lightningLegendCc(int minutes) {
    return 'Ulap–ulap · $minutes min';
  }

  @override
  String get meshtasticSendHint => 'Message to broadcast';

  @override
  String monitorDelay(String value) {
    return 'Pagkaantala $value s';
  }

  @override
  String get dpmNo => 'Hindi';

  @override
  String get mapLayerSatelliteB08 => 'Himawari Upper Water Vapour (B08)';

  @override
  String get meshtasticReconnecting => 'Reconnecting…';

  @override
  String get radarTownOutlineSubtitle =>
      'Nananatiling mababasa ang mga hangganan ng bayan sa ilalim ng radar echo.';

  @override
  String get typhoonOverlayWeatherSatelliteTooltip =>
      'Infrared closest to the typhoon bulletin time';

  @override
  String get radarScanRangeHint => 'Sa labas: hindi naoobserbahan';

  @override
  String typhoonPickerTd(String no) {
    return 'Tropical depression TD $no';
  }

  @override
  String get mapLayerSatelliteWatervapor => 'Himawari Water Vapour';

  @override
  String get regionAddButton => 'Magdagdag ng rehiyon';

  @override
  String get displaySettings => 'Pagpapakita';

  @override
  String get restroomGradePoor => 'Mas mababa sa pamantayan';

  @override
  String get restroomCategoryTourist => 'Lugar para sa turista';

  @override
  String get locationBannerServiceOff =>
      'Naka-off ang mga serbisyo ng lokasyon — hindi matutukoy ng mga lokal na alerto ang iyong lugar.';

  @override
  String get mapLayerStyleTooltip => 'Colour style';

  @override
  String lightningLegendCg(int minutes) {
    return 'Ulap–lupa · $minutes min';
  }

  @override
  String get skyTimeAuto => 'Awtomatiko';

  @override
  String get appLogs => 'Mga log ng app';

  @override
  String get feedConnecting => 'Kumokonekta…';

  @override
  String get notifyBannerDisabled =>
      'Naka-off ang mga notification — hindi ka makakatanggap ng mga alerto sa sakuna.';

  @override
  String get weatherHumidity => 'Halumigmig';

  @override
  String typhoonValueMs(String n) {
    return '$n m/s';
  }

  @override
  String homeForecastHumidity(String value) {
    return 'Halumigmig $value%';
  }

  @override
  String get meshtasticBusyBody =>
      'Disconnect it in the other Meshtastic app first. Two apps on one radio take each other\'s messages, so some will go missing.';

  @override
  String get meshtasticChannelNoSlot =>
      'No free channel slot — free one on the radio';

  @override
  String get restroomCategoryTransport => 'Transportasyon';

  @override
  String get reportFilterLocationHint => 'hal. Hualien, offshore';

  @override
  String get moonSubtitle => 'Lunar phase and illumination — computed locally';

  @override
  String get meshtasticBattery => 'Battery';

  @override
  String get meshtasticDistance => 'Distansya';

  @override
  String get meshtasticSnrTrend => 'Trend ng signal (SNR)';

  @override
  String get meshtasticBatteryTrend => 'Trend ng baterya';

  @override
  String get typhoonOverlayMenuTooltip => 'Typhoon overlay options';

  @override
  String get mapLayerSatelliteBtdOzone => 'Himawari Tropopause';

  @override
  String meshtasticRegionMismatch(String region) {
    return 'Radio region is $region — DPIP needs TW';
  }

  @override
  String get notifySectionEarthquake => 'Lindol';

  @override
  String get mapLayerDisasterMap => 'Disaster Map';

  @override
  String get weatherModeFog => 'Makapal na Hamog';

  @override
  String typhoonPickerNamed(String no, String name) {
    return '$name TY $no';
  }

  @override
  String get mapLayerStyleGrayTooltip => 'JMA grayscale — colder is whiter';

  @override
  String get moreAnnouncements => 'Mga Anunsyo';

  @override
  String get mapLayerSatelliteTransparentNoData =>
      'No data (land) = transparent';

  @override
  String get restroomCategoryGovernment => 'Opisina ng gobyerno';

  @override
  String get typhoonLegendCurrent => 'Kasalukuyang sentro';

  @override
  String get aedAddress => 'Address';

  @override
  String get mapLayerAed => 'AED';

  @override
  String get changelogTypePrerelease => 'Beta';

  @override
  String get reportFilterIntensityInfoModernBody =>
      'Antas 0–4, 5−, 5+, 6−, 6+, 7. Gamit ng filter ang bagong scale; ang mga lumang event ay may legacy label sa listahan.';

  @override
  String get typhoonOverlayWeatherNone => 'None';

  @override
  String get mapLayerStyleGray => 'Grayscale (JMA)';

  @override
  String get weatherModeAuto => 'Awtomatiko';

  @override
  String get typhoonLabelProbCircle => '70% probability circle';

  @override
  String get notifyOptAll => 'Tumanggap ng lahat';

  @override
  String get displayTheme => 'Tema';

  @override
  String get mapLayerSatelliteB07 => 'Himawari Shortwave Infrared (B07)';

  @override
  String get typhoonLabelDirection => 'Past movement direction';

  @override
  String get regionManageTitle => 'Mga naka-save na rehiyon';

  @override
  String get typhoonLegendCone => 'Kono ng forecast';

  @override
  String get moreCwaEew => 'Maagang babala sa lindol ng CWA';

  @override
  String get onboardingPermsTitle => 'Mga Pahintulot';

  @override
  String get mapLayerStyleJma => 'Cloud-top enhancement (JMA)';

  @override
  String get rainInterval10m => '10 min';

  @override
  String weatherRankingAnalysisLow(String value) {
    return 'Mababa $value';
  }

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
  String get mapLayerShelter => 'Silungan';

  @override
  String get typhoonOverlayProbabilityTooltip =>
      'Show strike probability (hides the forecast cone)';

  @override
  String get mapLayerSatelliteNdwi => 'Himawari NDWI';

  @override
  String get disasterMapOverlayShelterTooltip => 'Ipakita ang mga silungan';

  @override
  String get mapNavHumidity => 'Halumigmig';

  @override
  String get reportDetailSortByIntensity => 'Ayusin ayon sa intensity';

  @override
  String get homeRainTrendNoData => 'Walang data';

  @override
  String get mapLayerCategoryRadar => 'Radar';

  @override
  String get meshtasticShortName => 'Short name';

  @override
  String get mapLayerSatelliteAirmass => 'Himawari Airmass';

  @override
  String get typhoonTrackDetail => 'Track detail';

  @override
  String get dataSectionWeather => 'Panahon';

  @override
  String get aedHoursWeekday => 'Oras sa weekday';

  @override
  String get homeActiveEventsTitle => 'Mga aktibong event';

  @override
  String weatherRankingAnalysisHigh(String value) {
    return 'Mataas $value';
  }

  @override
  String get faq => 'Mga FAQ';

  @override
  String get typhoonHistoryLive => 'Live';

  @override
  String eewSerial(int serial) {
    return 'Ulat $serial';
  }

  @override
  String get reportFilterSort => 'Pagkakasunud-sunod';

  @override
  String get meshtasticRegionConfirm =>
      'Switch this radio to the TW region? It restarts and disconnects for a moment, and every other channel on it moves too.';

  @override
  String get dataEarthquakeSubtitle => 'Mga ulat ng lindol';

  @override
  String get typhoonNoActive => 'Walang aktibong bagyo';

  @override
  String get mapLayerSatelliteB11 => 'Himawari SO₂ / Cloud Phase (B11)';

  @override
  String get navEvents => 'Mga Kaganapan';

  @override
  String get onboardingTermsTitle => 'Mga Tuntunin ng Serbisyo';

  @override
  String get mapTownLabels => 'Mga pangalan ng bayan';

  @override
  String get notifySetFailed => 'Hindi ma-save ang setting. Pakisubukan muli.';

  @override
  String get meshtasticDisconnect => 'Disconnect';

  @override
  String get meshtasticUndecoded => 'Not decrypted';

  @override
  String get notifyAnnouncement => 'Mga Anunsyo';

  @override
  String get onboardingIntroTitle => 'Maligayang pagdating sa DPIP';

  @override
  String get regionCurrentUnavailable =>
      'Hindi makuha ang kasalukuyang lokasyon';

  @override
  String get languageSystem => 'Default ng system';

  @override
  String get skyTimeSunset => 'Paglubog ng araw';

  @override
  String get mapLayerSatelliteDust => 'Himawari Dust';

  @override
  String get mapAppAppleMaps => 'Apple Maps';

  @override
  String get regionEdit => 'I-edit';

  @override
  String get weatherDynamicState => 'Animation ng panahon';

  @override
  String get mapPlaceholderDisabled => 'Mapa (pansamantalang naka-disable)';

  @override
  String get moonNow => 'Ngayon';

  @override
  String get moonSectionAppearance => 'Anyo';

  @override
  String get moonSectionRiseSet => 'Pagsikat at paglubog';

  @override
  String get moonSectionUpcoming => 'Susunod';

  @override
  String get moonSectionCalendar => 'Kalendaryo';

  @override
  String get moonDistance => 'Distansya';

  @override
  String get moonKilometres => 'km';

  @override
  String get moonApparentSize => 'Lapad sa langit';

  @override
  String get moonRise => 'Pagsikat ng buwan';

  @override
  String get moonSet => 'Paglubog ng buwan';

  @override
  String get moonNextNewMoon => 'Susunod na bagong buwan';

  @override
  String get moonAlwaysUp => 'Nasa itaas buong araw';

  @override
  String get moonNoEvent => 'Wala sa araw na ito';

  @override
  String get sunTitle => 'Araw';

  @override
  String get sunSubtitle => 'Pagsikat, takipsilim at solar terms';

  @override
  String get sunSectionDaylight => 'Liwanag ng araw';

  @override
  String get sunSectionTwilight => 'Takipsilim';

  @override
  String get sunSectionLight => 'Liwanag';

  @override
  String get sunSectionSundial => 'Orasang araw';

  @override
  String get sunSectionTerms => 'Solar terms';

  @override
  String get sunRise => 'Pagsikat ng araw';

  @override
  String get sunSet => 'Paglubog ng araw';

  @override
  String get sunNoon => 'Tanghaling tapat';

  @override
  String get sunDayLength => 'Haba ng araw';

  @override
  String get sunTwilightCivil => 'Sibil';

  @override
  String get sunTwilightNautical => 'Nautical';

  @override
  String get sunTwilightAstronomical => 'Astronomical';

  @override
  String get sunGoldenHourMorning => 'Golden hour sa umaga';

  @override
  String get sunGoldenHourEvening => 'Golden hour sa hapon';

  @override
  String get sunBlueHour => 'Blue hour';

  @override
  String get sunEquationOfTime => 'Equation of time';

  @override
  String get sunMinutes => 'min';

  @override
  String get solarTermNext => 'Susunod na termino';

  @override
  String get planetsTitle => 'Mga planeta';

  @override
  String get planetsSubtitle => 'Nasaan ngayong gabi, at gaano kaliwanag';

  @override
  String get planetsSectionTonight => 'Ngayon';

  @override
  String get planetUp => 'Nasa itaas';

  @override
  String get planetDown => 'Nasa ibaba';

  @override
  String get planetInGlare => 'Malapit sa araw';

  @override
  String get planetMagnitude => 'Magnitude';

  @override
  String get planetElongation => 'Elongation';

  @override
  String get planetSky => 'Panahon';

  @override
  String get planetEvening => 'Gabi';

  @override
  String get planetMorning => 'Umaga';

  @override
  String get planetDistance => 'Distansya';

  @override
  String get planetAu => 'au';

  @override
  String get planetAltitude => 'Taas';

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
  String get solarTermStartOfSummer => 'Simula ng Tag-init';

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
  String get solarTermStartOfAutumn => 'Simula ng Taglagas';

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
  String get solarTermStartOfWinter => 'Simula ng Taglamig';

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
  String get solarTermStartOfSpring => 'Simula ng Tagsibol';

  @override
  String get solarTermRainWater => 'Rain Water';

  @override
  String get solarTermAwakeningOfInsects => 'Awakening of Insects';

  @override
  String get tonightTitle => 'Ngayong gabi';

  @override
  String get tonightSubtitle => 'Ano ang makikita, at kailan';

  @override
  String get tonightSectionDark => 'Oras ng obserbasyon';

  @override
  String get tonightAstronomicalNight => 'Astronomical na gabi';

  @override
  String get tonightNeverDark => 'Hindi tuluyang dumidilim';

  @override
  String get tonightDarkWindow => 'Madilim na yugto';

  @override
  String get tonightMoonAllNight => 'Buwan nasa langit buong gabi';

  @override
  String get tonightDarkTotal => 'Kabuuang dilim';

  @override
  String get tonightMoonlight => 'Liwanag ng buwan';

  @override
  String get tonightSectionShowers => 'Mga meteor shower';

  @override
  String get tonightRadiantDown => 'Hindi sumisikat ang radiant';

  @override
  String get tonightPerHour => '/oras';

  @override
  String get tonightSectionSatellites => 'Pagdaan ng satelayt';

  @override
  String get tonightSectionTargets => 'Nakikita ngayon';

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
  String get almanacTitle => 'Almanake';

  @override
  String get almanacSubtitle => 'Petsang lunisolar at mga eklipse';

  @override
  String get almanacSectionToday => 'Ngayon';

  @override
  String get almanacGregorian => 'Gregorian';

  @override
  String get almanacLunar => 'Lunisolar';

  @override
  String get almanacYear => 'Taon';

  @override
  String get almanacMonthLength => 'Haba ng buwan';

  @override
  String get almanacLongMonth => '30 araw';

  @override
  String get almanacShortMonth => '29 araw';

  @override
  String get almanacLeapPrefix => 'Leap ';

  @override
  String get almanacSectionLunarEclipses => 'Eklipse ng buwan';

  @override
  String get almanacSectionSolarEclipses => 'Eklipse ng araw';

  @override
  String get almanacNoSolarEclipse => 'Wala sa saklaw';

  @override
  String get eclipseTotal => 'Total';

  @override
  String get eclipsePartial => 'Parsyal';

  @override
  String get eclipseAnnular => 'Annular';

  @override
  String get eclipsePenumbral => 'Penumbral';

  @override
  String get zodiacRat => 'Daga';

  @override
  String get zodiacOx => 'Baka';

  @override
  String get zodiacTiger => 'Tigre';

  @override
  String get zodiacRabbit => 'Kuneho';

  @override
  String get zodiacDragon => 'Dragon';

  @override
  String get zodiacSnake => 'Ahas';

  @override
  String get zodiacHorse => 'Kabayo';

  @override
  String get zodiacGoat => 'Kambing';

  @override
  String get zodiacMonkey => 'Unggoy';

  @override
  String get zodiacRooster => 'Manok';

  @override
  String get zodiacDog => 'Aso';

  @override
  String get zodiacPig => 'Baboy';

  @override
  String get tideTitle => 'Taog';

  @override
  String get tideSubtitle => 'Spring, neap at hila ng buwan';

  @override
  String get tideDisclaimer =>
      'Astronomikal na puwersa lamang — hindi talaan ng taog sa daungan. Para sa lebel ng tubig, gamitin ang talaan ng CWA.';

  @override
  String get tideSectionNow => 'Ngayon';

  @override
  String get tidePhase => 'Siklo';

  @override
  String get tideSpring => 'Spring';

  @override
  String get tideNeap => 'Neap';

  @override
  String get tideMiddling => 'Katamtaman';

  @override
  String get tideLunarDistanceFactor => 'Hila ng buwan';

  @override
  String get tideEquilibrium => 'Equilibrium tide';

  @override
  String get tideMetres => 'm';

  @override
  String get tidePerigeanSpring => 'Susunod na perigean spring';

  @override
  String get tideSectionTurningPoints => 'Mga turning point';

  @override
  String get tideHigh => 'Taas';

  @override
  String get tideLow => 'Baba';

  @override
  String get skyChartTitle => 'Mapa ng langit';

  @override
  String get skyChartSubtitle => 'Ang langit sa itaas mo';

  @override
  String get skyChartNorth => 'H';

  @override
  String get skyChartEast => 'S';

  @override
  String get skyChartSouth => 'T';

  @override
  String get skyChartWest => 'K';

  @override
  String tonightElementAge(int days) {
    return '$days araw nang luma ang elements';
  }

  @override
  String almanacLunarDate(String leap, int month, int day) {
    return '${leap}buwan $month, araw $day';
  }

  @override
  String get tonightNoShowers => 'Walang shower ngayon';

  @override
  String get tonightNoPasses => 'Walang nakikitang pass sa 48 oras';

  @override
  String get tonightSatellitesUnavailable => 'Hindi mabasa ang orbit data';

  @override
  String get tonightNoTargets => 'Walang sapat na taas';

  @override
  String get skyChartUnavailable => 'Hindi mabasa ang star catalogue';

  @override
  String get permissionSettingsTitle => 'Payagan ito sa Settings';

  @override
  String get permissionSettingsHint => 'Susuriin muli ng app pagbalik mo.';

  @override
  String get permissionOpenSettings => 'Buksan ang Settings';

  @override
  String permissionSettingsMessage(String what) {
    return 'Tinanggihan ang “$what” at hindi na magtatanong ang sistema. I-on ito sa Settings.';
  }
}
