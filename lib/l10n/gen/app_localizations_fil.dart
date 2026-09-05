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
  String get mapTimelineScrubPaused =>
      'Masyadong mabilis ang pag-drag kaya naka-pause ang frame updates. Bagalan upang magpatuloy.';

  @override
  String get regionSelectTitle => 'Pumili ng rehiyon';

  @override
  String get skyTimeNoon => 'Tanghali';

  @override
  String get radarCountyOutlineSubtitle =>
      'Nananatiling mababasa ang mga hangganan sa ilalim ng radar echo.';

  @override
  String get mapLayerSatelliteB03 => 'Himawari Red (B03)';

  @override
  String get reportFilterIntensity => 'Lakas';

  @override
  String get mapLayerLightning => 'Kidlat';

  @override
  String get restroomTypeMale => 'Palikuran ng lalaki';

  @override
  String get meshtasticLastReceived => 'Huling natanggap';

  @override
  String get reportDetailSortByCounty => 'Ayusin ayon sa lalawigan';

  @override
  String get onboardingPermUnusedApp => 'Panatilihing aktibo ang app';

  @override
  String get onboardingPermUnusedAppDesc =>
      'Pinapahinto ng Android ang mga app na matagal mong hindi binuksan at binabawi ang mga pahintulot ng mga ito, kaya hindi na makakarating ang mga babala sa sakuna sa iyong lugar.';

  @override
  String get onboardingPermBackgroundExec => 'Aktibidad sa background';

  @override
  String get onboardingPermBackgroundExecDesc =>
      'Kapag naka-off, hindi ginigising ang app para iulat ang lokasyon mo.';

  @override
  String get onboardingPermVendorPower => 'Setting ng baterya ng manufacturer';

  @override
  String onboardingPermVendorPowerDesc(String brand) {
    return 'Hinihinto ng $brand ang background na gawain ng mga app na hindi mo binuksan kamakailan. Hindi ito matutukoy o mababago ng app — pakipayagan nang manu-mano.';
  }

  @override
  String get homeRainTrendScattered => 'Posibleng mahinang ulan';

  @override
  String get meshtasticUptime => 'Oras ng pagtakbo';

  @override
  String get weatherRankingTempExtremes => 'Mga sukdulan ng temperatura';

  @override
  String get themeLight => 'Maliwanag';

  @override
  String get mapTerrainReliefHint => 'Ipakita ang anino ng terrain sa base map';

  @override
  String get meshtasticEmptyMessage => '(walang laman na mensahe)';

  @override
  String get moreSectionRegion => 'Rehiyon';

  @override
  String get mapLayerSatellite => 'Himawari Infrared (B13)';

  @override
  String get aedHoursSaturday => 'Oras sa Sabado';

  @override
  String get moonPhaseNew => 'Bagong buwan';

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
  String get commonCancel => 'Kanselahin';

  @override
  String get notifyOptTsunamiWarning => 'Mga babala sa tsunami lamang';

  @override
  String get mapLayerSatelliteBtdFog => 'Himawari Night Fog';

  @override
  String get moreSectionAdvanced => 'Mas advanced';

  @override
  String get moreSectionMesh => 'Mesh network';

  @override
  String get weatherRankingExtremeRange => 'Saklaw sa araw';

  @override
  String get permissionsTitle => 'Pagsusuri ng pahintulot';

  @override
  String get permissionsAttention => 'May pahintulot na kailangang ayusin';

  @override
  String get permissionsBody =>
      'Kailangan ng DPIP ang mga pahintulot na ito para makapag-alerto agad. Kadalasan, ang dahilan ng hindi dumating na alerto ay isang nawawalang pahintulot.';

  @override
  String get notifySettingsMenu => 'Mga setting ng notipikasyon';

  @override
  String mapAppDefault(String app) {
    return '$app (default)';
  }

  @override
  String get trendRange24h => '24 oras';

  @override
  String get mapLayerStyleJmaTooltip =>
      'Grayscale na base, may kulay sa ibaba ng −40 °C para i-highlight ang taas ng ulap';

  @override
  String get mapLayerRain => 'Ulan';

  @override
  String get mapLayerQpesums => 'Pagtaya ng ulan sa susunod na 1 oras';

  @override
  String get mapOverlaySectionMap => 'Mapa';

  @override
  String get mapTerrainRelief => 'Rehiyebo ng terrain';

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
  String get changelogShowSnapshots => 'Ipakita ang snapshot';

  @override
  String get changelogTitle => 'Changelog';

  @override
  String get reportFilterOrderDesc => 'Pababa';

  @override
  String get meshtasticExcludeMqttSubtitle =>
      'Mga node na konektado sa internet, hindi naririnig sa radyo';

  @override
  String get reportFilterIntensityInfoTitle =>
      'Bagong at lumang intensity scale';

  @override
  String get mapLayerTyphoon => 'Bagyo';

  @override
  String get radarOverlayMenuTooltip => 'Mga opsyon sa layer ng radar';

  @override
  String get meshtasticNodes => 'Mga node';

  @override
  String get meshtasticSend => 'Ipadala';

  @override
  String get typhoonOverlayStormL7Tooltip =>
      'Larangan ng hangin sa antas 7 + average circle (lila)';

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
  String get meshtasticSilent => 'Tahimik';

  @override
  String get mapLayerCategoryEarthquake => 'Lindol';

  @override
  String get mapLayerSatelliteB12 => 'Himawari Ozone (B12)';

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
  String get meshtasticLayerOptions => 'Mga opsyon sa node';

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
  String get typhoonOverlayStormBandSubtitle => 'May average circle';

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
  String get meshtasticChannelWorking => 'Ini-set up ang DPIP channel…';

  @override
  String get meshtasticRegionSwitch => 'Lumipat sa TW';

  @override
  String get meshtasticTraffic => 'Trapiko';

  @override
  String get mapLayerStyleBdTooltip =>
      'Dvorak BD curve — ang stepped grayscale para sa pagsusuri ng lakas ng bagyo';

  @override
  String get disasterMapOverlayAedTooltip => 'Ipakita ang mga lokasyon ng AED';

  @override
  String get mapLayerHumidity => 'Halumigmig';

  @override
  String get mapLayerSatelliteTransparentNight =>
      'Gabing transparent, makikita ang basemap';

  @override
  String get meshtasticScanning => 'Nag-scan…';

  @override
  String regionSelectFull(int max) {
    return 'Maaari kang mag-save ng hanggang $max na rehiyon';
  }

  @override
  String get meshtasticNewMessages => 'BAGO';

  @override
  String get meshtasticBatteryHistory => 'Kasaysayan ng baterya';

  @override
  String get meshtasticStatAvg => 'avg';

  @override
  String get meshtasticStatPeak => 'peak';

  @override
  String get meshtasticStatDrain => 'ubos';

  @override
  String get meshtasticStatEta => 'tatagal';

  @override
  String get meshtasticStatFull => 'puno sa';

  @override
  String get meshtasticStatTrend => 'trend';

  @override
  String get meshtasticStatCharging => 'nagcha-charge';

  @override
  String get meshtasticStatStable => 'stable';

  @override
  String get meshtasticNodesTotal => 'Kilala';

  @override
  String get meshtasticNodesOnline => 'Online';

  @override
  String get meshtasticRx => 'Natanggap';

  @override
  String get meshtasticTx => 'Naipadala';

  @override
  String get meshtasticNodesHistory => 'Kasaysayan ng node';

  @override
  String get meshtasticTrafficHistory => 'Kasaysayan ng trapiko';

  @override
  String meshtasticEtaHours(int n) {
    return '~$n oras';
  }

  @override
  String meshtasticEtaDays(int n) {
    return '~$n araw';
  }

  @override
  String get meshtasticTitle => 'Meshtastic';

  @override
  String get navMore => 'Higit Pa';

  @override
  String get meshtasticDpipChannel => 'DPIP channel';

  @override
  String get disasterMapOverlaySectionLayers => 'Mga layer';

  @override
  String get mapLayerSatelliteB05 => 'Himawari Near-Infrared (B05)';

  @override
  String get typhoonLabelNe => 'NE';

  @override
  String get meshtasticCopied => 'Nakopya ang mensahe';

  @override
  String get reportListEmpty => 'Walang ulat ng lindol';

  @override
  String get reportListEnd => 'Dulo ng listahan';

  @override
  String get mapLayerSatelliteTruecolor => 'Himawari True Color';

  @override
  String get typhoonOverlaySectionExtra => 'Mga overlay';

  @override
  String get eewSWave => 'S wave';

  @override
  String get meshtasticBusyTitle => 'May ibang app na gumagamit ng radyong ito';

  @override
  String get restroomCategoryCultural => 'Pook na pangkultura';

  @override
  String get typhoonLabelWind => 'Max. sustained wind malapit sa gitna';

  @override
  String get radarGlobalOutlineHint => 'Panlabas na balangkas ng bawat bansa';

  @override
  String get notifyEvacuation => 'Impormasyon sa sakuna';

  @override
  String get typhoonLegendCircle15 => 'Gale circle (L7)';

  @override
  String get dataSectionAstronomy => 'Astronomiya';

  @override
  String get homeRainTrendLightSustained =>
      'Tuloy-tuloy na mahinang ulan sa susunod na oras';

  @override
  String get commonError => 'May Nangyaring Mali';

  @override
  String get moonPhaseWaningCrescent => 'Lumiit na gasuklay';

  @override
  String get meshtasticPower => 'Kuryente';

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
    return 'Mga lugar: $areas';
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
  String get typhoonLabelStormAvg => 'Avg. radius ng Beaufort 10 na hangin';

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
  String homeRainTrendMinute(int minute) {
    return '$minute min';
  }

  @override
  String get rainInterval6h => '6 oras';

  @override
  String get restroomTypeUnspecified => 'Hindi natukoy';

  @override
  String get typhoonOverlayProbabilityHint => 'Itinatago ang forecast cone';

  @override
  String get mapLayerSatelliteGlobalOutline => 'Border ng bansa';

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
      'Radar echo na pinakamalapit sa oras ng bulletin ng bagyo';

  @override
  String get onboardingPermLocationDesc =>
      'Itutok ang mga alerto sa kinaroroonan mo.';

  @override
  String get mapLayerSatelliteB16 => 'Himawari CO₂ (B16)';

  @override
  String get homeActiveEventsEmpty => 'Walang aktibong event';

  @override
  String get typhoonLabelPosition => 'Lokasyon ng gitna';

  @override
  String get weatherRankingBy => 'Ayon sa';

  @override
  String get typhoonIntensityMild => 'Mahinang bagyo';

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
  String get mapLayerSatelliteCloudCloudy => 'Maulap';

  @override
  String get skyTimeSunrise => 'Paosmkat ng araw';

  @override
  String get meshtasticJumpToLatest => 'Pumunta sa pinakabago';

  @override
  String get meshtasticNoMessages => 'Wala pang mensahe';

  @override
  String get onboardingPermNotifyDesc =>
      'Ihatid ang mga alerto sa lindol, panahon, at sakuna sa sandaling maganap ang mga ito.';

  @override
  String get radarTownOutline => 'Mga hangganan ng bayan';

  @override
  String get mapLayerStyleSection => 'Estilo ng kulay';

  @override
  String get disasterMapOverlayMenuTooltip => 'Mga layer ng disaster map';

  @override
  String get moreGooglePlay => 'Google Play';

  @override
  String get meshtasticOnline => 'Kamakailang narinig';

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
      'Maaliwalas = transparent, makikita ang basemap';

  @override
  String get mapOverlaySectionReference => 'Layer ng sanggunian';

  @override
  String get mapLayerSatelliteB02 => 'Himawari Green (B02)';

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
      'Sa ibaba ng 0.1 = transparent (walang vegetation)';

  @override
  String get notifyOptLocalIntensity4 => 'Lokal na intensidad 4 pataas';

  @override
  String get eewArrived => 'Dumating';

  @override
  String get meshtasticNoDevices => 'Walang nahanap na Meshtastic device';

  @override
  String get mapLayerCategoryLife => 'Pang-araw-araw na buhay';

  @override
  String get reportFilterSortIntensity => 'Lakas';

  @override
  String get meshtasticStateDisconnected => 'Naka-disconnect';

  @override
  String get typhoonIntensityIntense => 'Malakas na bagyo';

  @override
  String get mapLayerOrderTitle => 'Ayusin ang ayos ng layer';

  @override
  String get mapLayerShow => 'Ipakita ang layer';

  @override
  String get mapLayerHide => 'Itago ang layer';

  @override
  String get mapLayerShowAll => 'Ipakita lahat';

  @override
  String get mapLayerHideAll => 'Itago lahat';

  @override
  String get dpmYes => 'Oo';

  @override
  String get meshtasticNoHistory => 'Kulang pa sa history';

  @override
  String get reportDetailLocalIntensityUnavailable =>
      'Walang datos ng intensity';

  @override
  String get mapLayerWindForecastGfs => 'GFS';

  @override
  String get reportFilterDepth => 'Lalim';

  @override
  String get onboardingScrollHint => 'Mag-scroll pababa para magpatuloy';

  @override
  String get mapNavQpesums => 'Pagtaya';

  @override
  String get notifyAdvisory => 'Mga advisory sa panahon';

  @override
  String get reportFilterReset => 'I-reset';

  @override
  String get mapLayerSatelliteMndwi => 'Himawari MNDWI';

  @override
  String get typhoonOverlaySectionStorm => 'Hanging bagyo';

  @override
  String get moonPhaseFull => 'Kabilugan ng buwan';

  @override
  String meshtasticBinaryPayload(String size) {
    return 'Binary na data · $size';
  }

  @override
  String get moonPhaseWaningGibbous => 'Humihinang bilog';

  @override
  String get reportFilterIntensityInfoModernTitle => 'Bago (mula 2020)';

  @override
  String typhoonDataTime(String time) {
    return 'Oras ng datos';
  }

  @override
  String get restroomTypeAccessible => 'Palikurang may accessibility';

  @override
  String get moreSectionAbout => 'Tungkol';

  @override
  String get meshtasticSelectDevice => 'Pumili ng radyo';

  @override
  String get onboardingIntroBody =>
      'Ang DPIP ang iyong kasama sa pag-iwas sa sakuna. Pinagsasama-sama nito ang mga maagang babala sa lindol, ulat ng lindol, panahon, at impormasyon sa panganib, at inaalertuhan ka sa sandaling mahalaga ito.\n\n• Mga lindol: mga maagang babala, ulat ng intensidad, at detalyadong ulat\n• Panahon: real-time na mensahe ng kulog at kidlat at mga advisory sa panahon\n• Impormasyon sa tsunami at sakuna\n\nSusunod, hihilingin naming basahin mo ang Mga Tuntunin ng Serbisyo at magbigay ng ilang pahintulot para maprotektahan ka ng DPIP nang real time.';

  @override
  String get shelterCapacityLabel => 'Kapasidad';

  @override
  String get reportDetailImage => 'Larawan ng Ulat';

  @override
  String get meshtasticStateConfiguring => 'Kino-configure…';

  @override
  String get typhoonLabelGaleAvg => 'Avg. radius ng Beaufort 7 na hangin';

  @override
  String get onboardingPermNotify => 'Mga Notipikasyon';

  @override
  String get meshtasticClearMessages => 'I-clear ang mga mensahe';

  @override
  String get meshtasticNotifyMessages => 'Mag-notify sa mga bagong mensahe';

  @override
  String get defaultMapLayerSettings => 'Default na layer ng mapa';

  @override
  String get eewSourceSettings => 'Pinagmulan ng EEW';

  @override
  String get eewSourceSubtitle =>
      'Piliin kung aling mga ahensya ang ipapakitang paunang babala sa lindol.';

  @override
  String get eewSourceAll => 'Lahat ng pinagmulan';

  @override
  String get eewSourceAllDescription =>
      'Ipakita ang paunang babala sa lindol mula sa bawat ahensyang naglalabas nito.';

  @override
  String get eewSourceCwaOnly => 'CWA lang';

  @override
  String get eewSourceCwaOnlyDescription =>
      'Ipakita lamang ang paunang babala sa lindol na inilabas ng Central Weather Administration (CWA) ng Taiwan.';

  @override
  String get moreSectionNotify => 'Mga Abiso';

  @override
  String get notifyUnavailable =>
      'Hindi pa handa ang push notifications — subukan muli mamaya.';

  @override
  String get mapLayerOrderReset => 'I-reset ang ayos';

  @override
  String get weatherRankingMergeCounty => 'Lalawigan';

  @override
  String get moreSectionApp => 'Kunin ang app';

  @override
  String get moreSectionBeta => 'Bersyon ng pagsubok';

  @override
  String get moreAndroidBeta => 'Bersyon ng pagsubok sa Android';

  @override
  String get moreTestFlight => 'Bersyon ng pagsubok sa iOS (TestFlight)';

  @override
  String get moreSectionPartners => 'Mga kasosyo';

  @override
  String get morePartnersNote =>
      'Nakaayos ayon sa tamang panahon ng pakikipagtulungan. Salamat sa mga indibidwal at kompanyang nag-ambag sa paghahanda sa kalamidad; ang kanilang kontribusyon ang nagbigay-daan sa DPIP.';

  @override
  String get morePartnerGeoscience => 'Geoscience';

  @override
  String get morePartnerTwds => 'TWDS';

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
  String get typhoonLabelGust => 'Pinakamalakas na bugso';

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
  String get moonAge => 'Edad ng buwan';

  @override
  String get meshtasticRadioSettings => 'LoRa';

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
  String get language => 'Wika';

  @override
  String homeForecastFeelsLike(String temp) {
    return 'Pakiramdam $temp°';
  }

  @override
  String get typhoonOverlayWeatherHint => 'Naka-align sa oras ng bulletin';

  @override
  String get skyTimeDawn => 'Bukang-liwayway';

  @override
  String get skyTimeAfternoon => 'Hapon';

  @override
  String get meshtasticLastHeard => 'Huling narinig';

  @override
  String get typhoonWarningTitle => 'Babala ng bagyo';

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
      'Larangan ng hangin sa antas 10 + average circle (dilaw)';

  @override
  String get moonPhaseWaxingGibbous => 'Lumalaking bilog';

  @override
  String get reportDetailTitle => 'Ulat ng Lindol';

  @override
  String get moreTremReport => 'Ulat ng pagtukoy ng TREM';

  @override
  String weatherDataTime(String station, String time) {
    return '$station · Oras ng datos $time';
  }

  @override
  String get meshtasticNoNodes => 'Wala pang narinig na node';

  @override
  String get meshtasticViaMqtt => 'Sa pamamagitan ng MQTT (internet)';

  @override
  String get radarCountyOutline => 'Mga hangganan ng lalawigan';

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
      'Ipakita ang mga detalye ng forecast point kapag naka-zoom';

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
  String get moonDays => 'araw';

  @override
  String mapLegendUnit(String unit) {
    return 'Yunit: $unit';
  }

  @override
  String get weatherModeClear => 'Maaliwalas';

  @override
  String get meshtasticRadio => 'Radyo';

  @override
  String get commonEmpty => 'Walang Maipakita';

  @override
  String get mapLayerSatelliteB01 => 'Himawari Blue (B01)';

  @override
  String get meshtasticExternalPower => 'Panlabas na kuryente';

  @override
  String get moonPhaseLastQuarter => 'Huling sangkapat';

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
  String get meshtasticLastSent => 'Huling ipinadala';

  @override
  String get meshtasticName => 'Pangalan';

  @override
  String get meshtasticScan => 'I-scan';

  @override
  String get mapLayerCategoryForecast => 'Numerical forecast';

  @override
  String get meshtasticChannelFailed => 'Hindi ma-set up ang DPIP channel';

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
  String get moonNextFullMoon => 'Susunod na kabilugan';

  @override
  String get dpmSheetEmpty => 'I-tap ang marker sa mapa para sa detalye';

  @override
  String get onboardingSkipLeave => 'Laktawan pa rin';

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
  String get onboardingPermBattery => 'Exemption sa baterya';

  @override
  String get typhoonLabelNw => 'NW';

  @override
  String get moonPhaseWaxingCrescent => 'Lumalaking gasuklay';

  @override
  String get restroomCategoryLeisure => 'Lugar ng libangan';

  @override
  String get mapLayerTemperature => 'Temperatura';

  @override
  String get aedCategory => 'Kategorya';

  @override
  String get meshtasticChannels => 'Mga channel';

  @override
  String get monitorWaiting => 'Naghihintay ng data…';

  @override
  String get typhoonOverlayForecastCallouts => 'Forecast tooltips';

  @override
  String get reportDetailEpicenter => 'Coordinates ng Epicenter';

  @override
  String get meshtasticVoltage => 'Boltahe';

  @override
  String get mapLayerMeshtasticSubtitle =>
      'LoRa mesh nodes na narinig ng radyo mo';

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
  String get notifyMonitor => 'Monitor ng malakas na paggalaw';

  @override
  String get onboardingStart => 'Maosmmula';

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
      'Zero difference = transparent (walang signal)';

  @override
  String get shelterIndoorLabel => 'Silungan sa loob';

  @override
  String get notifyOptOff => 'Naka-off';

  @override
  String get reportFilterSortTime => 'Oras';

  @override
  String get mapLayerSatelliteCloudProbablyClear => 'Malamang maaliwalas';

  @override
  String get weatherModeThunderstorm => 'Kulog at Kidlat';

  @override
  String get homeViewOnMap => 'Tingnan sa mapa';

  @override
  String get reportFilterIntensityInfoLegacyTitle => 'Luma (bago ang 2020)';

  @override
  String get typhoonLabelSpeed => 'Bilis ng paggalaw';

  @override
  String mapAppOpenFailed(String app) {
    return 'Hindi mabuksan ang $app';
  }

  @override
  String get mapLayerSatelliteRgbComposite => 'RGB composite (JMA recipe)';

  @override
  String get meshtasticReceived => 'Natanggap';

  @override
  String get weatherRankingExtremeLow => 'Pinakamababa ngayong araw';

  @override
  String get mapLayerSatelliteB10 => 'Himawari Lower Water Vapour (B10)';

  @override
  String get mapLayerSatelliteCloudProbablyCloudy => 'Malamang maulap';

  @override
  String get mapLayerSatelliteTransparentNoWater =>
      '≤ 0 = transparent (walang tubig)';

  @override
  String get shelterCategoryLabel => 'Mga uri ng kalamidad';

  @override
  String get meshtasticStateConnecting => 'Kumokonekta…';

  @override
  String get moonTitle => 'Buwan';

  @override
  String get weatherRankingGust => 'Bugso';

  @override
  String get moreAppStore => 'App Store';

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
  String get changelogOpenOnGitHub => 'Tingnan sa GitHub';

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
  String get meshtasticNotConnected => 'Hindi konektado sa radyo';

  @override
  String get weatherModeSnow => 'Niyebe';

  @override
  String get mapLayerMeshtastic => 'Meshtastic nodes';

  @override
  String get moreDeveloper => 'Impormasyon sa debug';

  @override
  String get mapLayerSatelliteB14 => 'Himawari Longwave Infrared (B14)';

  @override
  String get meshtasticChannelUse => 'Paggamit ng channel';

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
  String get meshtasticNotifyNodes => 'Mag-notify sa mga bagong node';

  @override
  String get onboardingPermCriticalDesc =>
      'Hayaang tumunog ang mga nakamamatay na babala sa lindol kahit sa silent mode o Do Not Disturb.';

  @override
  String get mapLayerSatelliteTransparentWarm =>
      'Maaliwalas (mainit) = transparent, makikita ang basemap';

  @override
  String get meshtasticSent => 'Ipinadala';

  @override
  String get homeForecastTitle => '24-oras na forecast';

  @override
  String get typhoonLegendWarningAreas => 'Mga lugar ng babala';

  @override
  String meshtasticExcludeMqttHidden(int count) {
    return '$count nakatago';
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
  String get meshtasticTapNode => 'I-tap ang node para sa detalye';

  @override
  String get commonLoading => 'Naglo-load…';

  @override
  String get typhoonIntensityModerate => 'Katamtamang bagyo';

  @override
  String get mapLayerSatelliteAsh => 'Himawari Ash';

  @override
  String get rainInterval3h => '3 oras';

  @override
  String get mapLayerCategorySatellite => 'Satellite';

  @override
  String get meshtasticChannelReady => 'Handa na ang DPIP channel';

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
      'I-highlight ang mga county sa ilalim ng babala ng bagyo';

  @override
  String get reportFilterDatePick => 'Pumili ng petsa';

  @override
  String get onboardingSkipStay => 'Bumalik';

  @override
  String get commonFetchFailed => 'Hindi ma-load ang data. Pakisubukan muli.';

  @override
  String get shelterOutdoorLabel => 'Silungan sa labas';

  @override
  String get meshtasticStateConnected => 'Nakakonekta';

  @override
  String get mapNavRadar => 'Radar';

  @override
  String get mapLayerSatelliteCloudClear => 'Maaliwalas';

  @override
  String eewSummary(String magnitude, String depth) {
    return 'M$magnitude · lalim $depth km';
  }

  @override
  String get locationBannerPermission =>
      'Naka-off ang pahintulot sa lokasyon — hindi matutukoy ng mga lokal na alerto ang iyong lugar.';

  @override
  String get typhoonOverlayWeatherNoneTooltip =>
      'Walang radar o infrared underlay';

  @override
  String get radarCountyOutlineHint => 'Iginuguhit sa ibabaw ng echo';

  @override
  String get windForecastCountyOutlineHint =>
      'Iginuhit sa itaas ng patlang ng hangin';

  @override
  String get homeRainTrendTitle => 'Ulan sa susunod na oras';

  @override
  String get moonPhaseFirstQuarter => 'Unang sangkapat';

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
  String get meshtasticReadingAge => 'Oras ng pagsukat';

  @override
  String get mapAppCallFailed => 'Hindi makatawag ang device na ito';

  @override
  String get reportFilterAny => 'Lahat';

  @override
  String get weatherRankingMergeTo => 'Pagsamahin';

  @override
  String get notifyIntensity => 'Ulat ng intensidad';

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
  String get meshtasticExcludeMqtt => 'Itago ang mga MQTT node';

  @override
  String get mapNavTyphoon => 'Bagyo';

  @override
  String get weatherModeSand => 'Alikabok';

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
    return '$direction · Lakas $level';
  }

  @override
  String get navHome => 'Tahanan';

  @override
  String get meshtasticRegionLabel => 'Rehiyon';

  @override
  String get mapLayerSatelliteCloudtop => 'Himawari Cloud Top Temperature';

  @override
  String get moonTimelineCaption => 'Porsyento';

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
  String get weatherRankingExtremeHigh => 'Pinakamataas ngayong araw';

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
  String get meshtasticSendHint => 'Mensaheng ipapadala';

  @override
  String monitorDelay(String value) {
    return 'Pagkaantala $value s';
  }

  @override
  String get dpmNo => 'Hindi';

  @override
  String get mapLayerSatelliteB08 => 'Himawari Upper Water Vapour (B08)';

  @override
  String get meshtasticReconnecting => 'Kumokonekta ulit…';

  @override
  String get radarTownOutlineSubtitle =>
      'Nananatiling mababasa ang mga hangganan ng bayan sa ilalim ng radar echo.';

  @override
  String get typhoonOverlayWeatherSatelliteTooltip =>
      'Infrared na pinakamalapit sa oras ng bulletin ng bagyo';

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
  String get regionSearchHint => 'Maghanap ng mga lalawigan at lungsod';

  @override
  String get regionSearchEmpty => 'Walang tumugmang lalawigan o lungsod';

  @override
  String get regionSearchTownHint => 'Maghanap ng mga bayan';

  @override
  String get regionSearchTownEmpty => 'Walang tumugmang bayan';

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
  String get mapLayerStyleTooltip => 'Estilo ng kulay';

  @override
  String lightningLegendCg(int minutes) {
    return 'Ulap–lupa · $minutes min';
  }

  @override
  String get skyTimeAuto => 'Awtomatiko';

  @override
  String get appLogs => 'Mga log ng app';

  @override
  String get serverStatusLocal => 'Katayuan ng device';

  @override
  String get serverStatusLocalBody =>
      'Ang mga sukatan ng server ay mula sa dashboard. Nasa ibaba ang aktwal na paghusga ng device na ito sa mga multi-active na endpoint (LB / Core bawat rehiyon): pasibo lang itong nagtatala ng trapikong talagang pinapadala; kung hindi pa ito naantig ng device, lalabas ang \'Hindi pa nasuri\'.';

  @override
  String get serverStatusAllUp => 'Lahat ng serbisyo ay normal';

  @override
  String get serverStatusDegraded => 'Bumaba ang pagganap';

  @override
  String get serverStatusDown => 'May problema ang serbisyo';

  @override
  String get serverStatusErrorRate => 'Rate ng error na 5xx';

  @override
  String get serverStatusLatency => 'Karaniwang latency';

  @override
  String get serverStatusUpdated => 'Na-update';

  @override
  String get serverStatusWeb => 'Katayuan ng server';

  @override
  String get serverStatusWebUrl => 'status.exptech.dev';

  @override
  String get serverStatusExpTech => 'Katayuan ng ExpTech';

  @override
  String get serverStatusCloudflare => 'Katayuan ng Cloudflare';

  @override
  String get serverStatusCloudflareAllOperational =>
      'Normal ang lahat ng lugar';

  @override
  String get serverStatusCloudflareOutage =>
      'May problema ang Cloudflare sa ilang lugar';

  @override
  String get serverStatusCloudflareNone => 'Walang lugar na maipapakita.';

  @override
  String get serverStatusCloudflareOperational => 'Normal';

  @override
  String get serverStatusCloudflareDegraded => 'Bumaba ang pagganap';

  @override
  String get serverStatusCloudflarePartial => 'Bahagyang pagkaantala';

  @override
  String get serverStatusCloudflareMajor => 'Malaking pagkaantala';

  @override
  String get serverStatusCloudflareUnknown => 'Hindi alam';

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
      'Core-eksklusibong API (radar / panahon / hangin)';

  @override
  String get endpointTierCoreStaticExclusive => 'Core-eksklusibong static';

  @override
  String get endpointTierLegacyApi => 'Legacy API (api-1)';

  @override
  String get endpointHealthOk => 'Normal ang koneksyon';

  @override
  String get endpointHealthDegraded => 'May endpoint na hindi matatag';

  @override
  String get endpointHealthDown => 'May problema ang koneksyon';

  @override
  String get endpointHealthUnknown => 'Wala pang datos';

  @override
  String get endpointStateOk => 'Normal';

  @override
  String get endpointStateDegraded => 'Hindi matatag';

  @override
  String get endpointStateDown => 'May problema';

  @override
  String get endpointStateUnknown => 'Hindi alam';

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
  String get endpointServiceWind => 'Hangin';

  @override
  String get endpointServiceDpm => 'Disaster points';

  @override
  String get endpointServiceWeather => 'Panahon';

  @override
  String get endpointServiceRain => 'Ulan';

  @override
  String get endpointServiceLightning => 'Kidlat';

  @override
  String get endpointServiceTyphoon => 'Bagyo';

  @override
  String get endpointServiceReport => 'Mga ulat ng lindol';

  @override
  String get endpointServiceTremStation => 'Tremor station';

  @override
  String get endpointServiceEvent => 'Mga event';

  @override
  String get endpointServiceLocation => 'Lokasyon';

  @override
  String get endpointServiceNotify => 'Mga notipikasyon';

  @override
  String get endpointServiceOther => 'Iba pa';

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
      'I-disconnect muna ito sa ibang Meshtastic app. Dalawang app sa isang radyo ang nag-aagawan sa mensahe, kaya may mawawala.';

  @override
  String get meshtasticChannelNoSlot =>
      'Walang libreng channel slot — magbakante sa radyo';

  @override
  String get restroomCategoryTransport => 'Transportasyon';

  @override
  String get meshtasticBattery => 'Baterya';

  @override
  String get meshtasticDistance => 'Distansya';

  @override
  String get meshtasticSnrTrend => 'Trend ng signal (SNR)';

  @override
  String get meshtasticBatteryTrend => 'Trend ng baterya';

  @override
  String get typhoonOverlayMenuTooltip => 'Mga opsyon sa typhoon overlay';

  @override
  String get mapLayerSatelliteBtdOzone => 'Himawari Tropopause';

  @override
  String meshtasticRegionMismatch(String region) {
    return 'Ang region ng radyo ay $region — kailangan ng DPIP ang TW';
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
  String get mapLayerStyleGrayTooltip =>
      'JMA grayscale — mas malamig ay mas puti';

  @override
  String get moreAnnouncements => 'Mga Anunsyo';

  @override
  String get moreTagline =>
      'Platform para sa Integral na Impormasyon sa Kalamidad';

  @override
  String get moreVersionStable => 'Pormal na bersyon';

  @override
  String get moreVersionNotes => 'Update na ito';

  @override
  String get moreVersionNotesHighlightsSubtitle =>
      'Ano ang nagbago sa bersyon na ito';

  @override
  String releaseHighlightsTitle(Object train) {
    return '$train buod';
  }

  @override
  String get releaseHighlightsTabNormal => 'Para sa mga user';

  @override
  String get releaseHighlightsTabAdvanced => 'Mas malalim';

  @override
  String get releaseHighlightsEmpty => 'Wala pang laman.';

  @override
  String get releaseHighlightsSeeNotes => 'Buong tala ng release';

  @override
  String get moreVersionNotesEmpty => 'Walang changelog para sa build na ito';

  @override
  String get reportNotFound => 'Hindi mahanap ang ulat ng lindol na ito';

  @override
  String get moreVersionSnapshot => 'Bersyon ng pagsubok';

  @override
  String get mapLayerSatelliteTransparentNoData =>
      'Walang data (lupa) = transparent';

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
  String get typhoonOverlayWeatherNone => 'Wala';

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
  String get typhoonLabelDirection => 'Direksyon ng paggalaw';

  @override
  String get regionManageTitle => 'Mga naka-save na rehiyon';

  @override
  String get regionSaveNote =>
      'Ipapadala ang mga abiso batay sa iyong lokasyon ng GPS. Ang pag-set ng paboritong lugar ay hindi nagbabago kung saan ipinapadala ang alerto — ang mga paboritong lugar ay para lang mabilis mong makita ang kalagayan ng bawat lugar sa home. Ibigay ang pahintulot sa lokasyon, kung hindi hindi gagana ang mga abiso.';

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
  String get meshtasticConnectAnyway => 'Kumonekta pa rin';

  @override
  String reportListDayCount(int count) {
    return '$count';
  }

  @override
  String get mapLayerSatelliteB06 => 'Himawari Near-Infrared (B06)';

  @override
  String get mapLayerSatelliteTransparentReflectance =>
      'Mababang reflectance / gabi = transparent, makikita ang basemap';

  @override
  String chartHourLabel(int hour) {
    return '${hour}h';
  }

  @override
  String get mapLayerShelter => 'Silungan';

  @override
  String get typhoonOverlayProbabilityTooltip =>
      'Ipakita ang strike probability (itinatago ang forecast cone)';

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
  String get meshtasticShortName => 'Maikling pangalan';

  @override
  String get mapLayerSatelliteAirmass => 'Himawari Airmass';

  @override
  String get dataSectionWeather => 'Panahon';

  @override
  String get aedHoursWeekday => 'Oras sa weekday';

  @override
  String get homeActiveEventsTitle => 'Mga aktibong event';

  @override
  String get faq => 'Mga FAQ';

  @override
  String eewSerial(int serial) {
    return 'Ulat $serial';
  }

  @override
  String get reportFilterSort => 'Pagkakasunud-sunod';

  @override
  String get meshtasticRegionConfirm =>
      'Lumipat ba ang radyong ito sa TW region? Magre-restart at magdi-disconnect saglit, at lilipat din ang lahat ng ibang channel.';

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
  String get mapOsmOverlay => 'Detalyadong mapa';

  @override
  String get mapOsmOverlayHint =>
      'Ipakita ang mas kumpletong mga kalsada, gusali, at pangalan ng lugar';

  @override
  String get mapOsmDetails => 'Mga detalye ng layer';

  @override
  String get moreDataSources => 'Mga pinagmulan ng data';

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
    return '$enabled sa $total na layer ang naka-enable';
  }

  @override
  String get mapOsmSurface => 'Ibabaw';

  @override
  String get mapOsmParks => 'Mga parke';

  @override
  String get mapOsmLandUse => 'Paggamit ng lupa';

  @override
  String get mapOsmAirportAreas => 'Mga lugar ng paliparan';

  @override
  String get mapOsmWater => 'Tubig';

  @override
  String get mapOsmRivers => 'Mga ilog';

  @override
  String get mapOsmBoundaries => 'Mga hangganan';

  @override
  String get mapOsmBuildings => 'Mga gusali';

  @override
  String get mapOsmRoads => 'Mga kalsada';

  @override
  String get mapOsmRoadNames => 'Pangalan ng kalsada';

  @override
  String get mapOsmWaterNames => 'Pangalan ng tubig';

  @override
  String get mapOsmPeaks => 'Mga taluktok';

  @override
  String get mapOsmAirportNames => 'Pangalan ng paliparan';

  @override
  String get mapOsmPlaceNames => 'Pangalan ng lugar';

  @override
  String get mapOsmPoi => 'Mga lugar ng interes';

  @override
  String get mapOsmHouseNumbers => 'Mga numero ng bahay';

  @override
  String get mapOsmRestoreAll => 'Ibalik lahat';

  @override
  String get mapOsmSectionNatural => 'Mga likas na anyo';

  @override
  String get mapOsmSectionRoadsAndBuildings => 'Mga kalsada at gusali';

  @override
  String get mapOsmSectionLabelsAndPlaces => 'Mga label at lugar';

  @override
  String get mapTownLabels => 'Mga pangalan ng bayan';

  @override
  String get notifySetFailed => 'Hindi ma-save ang setting. Pakisubukan muli.';

  @override
  String get meshtasticDisconnect => 'I-disconnect';

  @override
  String get meshtasticUndecoded => 'Hindi nade-decrypt';

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
  String get moonNow => 'Ngayon';

  @override
  String get moonSectionAppearance => 'Anyo';

  @override
  String get moonSectionRiseSet => 'Paosmkat at paglubog';

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
  String get moonRise => 'Paosmkat ng buwan';

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
  String get sunRise => 'Paosmkat ng araw';

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
  String get solarTermStartOfSpring => 'Simula ng Taosmbol';

  @override
  String get solarTermRainWater => 'Rain Water';

  @override
  String get solarTermAwakeningOfInsects => 'Awakening of Insects';

  @override
  String get tonightTitle => 'Ngayong gabi';

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

  @override
  String get permissionGuideNotification =>
      'Buksan ang System Settings upang payagan ang mga notipikasyon.';

  @override
  String get permissionGuideForegroundLocation =>
      'Buksan ang System Settings upang payagan ang tumpak na lokasyon.';

  @override
  String permissionGuideBackgroundLocation(Object option) {
    return 'Sa “$option”, piliin ang “Payagan sa lahat ng oras”.';
  }

  @override
  String get permissionGuideBackgroundExecution =>
      'Payagan ang background execution sa System Settings upang hindi i-pause ang mga notipikasyon.';

  @override
  String get permissionGuideUnusedPause =>
      'Kung minarkahan ang app na “hindi ginagamit”, piliin ang “Payagan” sa System Settings.';

  @override
  String get permissionGuideUnusedFreeSpace =>
      'Kung na-pause ang app dahil sa storage, i-clear ang cache at buksan muli.';

  @override
  String get permissionGuideUnusedRevoke =>
      'Kung binawi ang mga pahintulot ng app, ibigay muli sa System Settings.';

  @override
  String get permissionGuideUnusedPlayProtect =>
      'Kung i-pause ng Play Protect ang app, tingnan ang katayuan nito sa Google Play.';

  @override
  String permissionGuideVendorPower(Object vendor) {
    return 'Sa mga setting ng pagtitipid ng kuryente ng “$vendor”, itakda ang app na ito sa “Walang limitasyon”.';
  }

  @override
  String get permissionStillRequired =>
      'Kailangan pa rin — buksan ang Settings para paganahin.';

  @override
  String get permissionVerifyManually =>
      'Mangyaring i-verify nang manu-mano na naka-enable ang pahintulot na ito sa System Settings.';

  @override
  String get permissionBackgroundLocationOption => '“Payagan sa lahat ng oras”';

  @override
  String get displayTextSize => 'Laki ng teksto';

  @override
  String get displayTextSizeDesc =>
      'Nalalapat sa teksto ng app, hindi sa mga label sa mapa.';

  @override
  String get displayTextWeight => 'Kapal ng teksto';

  @override
  String get displayTextWeightDesc =>
      'Maaaring mas madaling basahin ang mas makapal na teksto.';

  @override
  String get displayContrast => 'Contrast';

  @override
  String get displayContrastDesc =>
      'Inihihiwalay ng mas mataas na contrast ang teksto sa background nito.';

  @override
  String get displayColorVision => 'Paningin sa kulay';

  @override
  String get displayColorVisionDesc =>
      'Binabago ang mga kulay sa buong app, pati na sa mapa.';

  @override
  String get displayColorVisionNone => 'Karaniwang kulay';

  @override
  String get displayColorVisionProtan => 'Mahina sa pula (protan)';

  @override
  String get displayColorVisionDeutan => 'Mahina sa berde (deutan)';

  @override
  String get displayColorVisionTritan => 'Mahina sa asul at dilaw (tritan)';

  @override
  String get displayPreviewSample => 'Halimbawang ulat ng lindol';

  @override
  String get displayScaleSmall => 'Maliit';

  @override
  String get displayScaleDefault => 'Default';

  @override
  String get displayScaleLarge => 'Malaki';

  @override
  String get displayScaleHuge => 'Napakalaki';

  @override
  String get displayWeightNormal => 'Normal';

  @override
  String get displayWeightMedium => 'Katamtaman';

  @override
  String get displayWeightBold => 'Makapal';

  @override
  String get displayContrastStandard => 'Karaniwan';

  @override
  String get displayContrastMedium => 'Katamtaman';

  @override
  String get displayContrastHigh => 'Mataas';

  @override
  String get meshtasticDirect => 'Direkta';

  @override
  String meshtasticHopsAway(int n) {
    return '$n hop';
  }

  @override
  String get meshtasticStatRelayShare => 'Ipinasa para sa iba';

  @override
  String get meshtasticStatRelayShareHint => 'Bahagi ng ipinadala nito';

  @override
  String get meshtasticStatRelayValue => 'Natapos na relay';

  @override
  String get meshtasticStatRelaySolePath =>
      'Madalas ang tanging daan — umaasa ang mesh dito';

  @override
  String get meshtasticStatRelayRedundant => 'May iba ring sumasaklaw';

  @override
  String get meshtasticStatRedundancy => 'Doblang natanggap';

  @override
  String get meshtasticStatThinEdge =>
      'Kaunti ang alternatibong daan — puwedeng maputol';

  @override
  String get meshtasticStatWellCovered => 'Maraming daan ang umaabot dito';

  @override
  String get meshtasticStatErrorRate => 'Sirang natanggap';

  @override
  String get meshtasticStatErrorRateHint =>
      'Tumataas habang patag ang airtime = interference';

  @override
  String get meshtasticTraceRoute => 'Sundan ang ruta';

  @override
  String get meshtasticTracing => 'Sinusundan…';

  @override
  String get meshtasticTraceUnreadable => 'Hindi mabasang tugon';

  @override
  String get meshtasticTraceOffline => 'Hindi nakakonekta sa radyo';

  @override
  String get meshtasticTraceCooldown =>
      'Isang beses kada 30 s lang ang pinapayagan ng radyo';

  @override
  String get meshtasticTraceNoReply =>
      'Walang tugon — wala sa saklaw o ibang key';

  @override
  String get meshtasticTraceDirect => 'Direkta — walang relay';

  @override
  String meshtasticTraceHops(int n) {
    return '$n na relay';
  }

  @override
  String get moreDumpDiagnostics => 'I-upload ang debug info at mga log';

  @override
  String get moreDumpDiagnosticsHint =>
      'Iuupload at kokopyahin ang link para ilakip sa ulat';

  @override
  String get dumpIncludeSensitive => 'Isama ang eksaktong lokasyon';

  @override
  String get dumpIncludeSensitiveHint =>
      'Isinasama ang mga coordinate mula sa log at lokasyon sa background; kapag hindi pinili, papalitan ng null';

  @override
  String get dumpUpload => 'I-upload';

  @override
  String get dumpUploaded => 'Na-upload';

  @override
  String get dumpLinkCopied => 'Nakopya ang link sa clipboard';

  @override
  String get dumpCopyAgain => 'Kopyahin ulit';

  @override
  String get dumpUploadFailed => 'Nabigong mag-upload';

  @override
  String get statusLegendUnprobed => 'Hindi pa nasuri';

  @override
  String get statusLegendUnsupported => 'Hindi suportado';

  @override
  String get rainScaleSection => 'Antas ng kulay';

  @override
  String get rainScaleFine => 'Pino';

  @override
  String get rainScaleCoarse => 'Magaspang';

  @override
  String get notifyTestTitle => 'Subukan ang mga notipikasyon';

  @override
  String get notifyTestIntro =>
      'Ang pag-tap sa isang row ay talagang magpapadala ng alertong iyon. Ang mga mahalagang alerto ay tutunog nang pinakamalakas at dadaan sa silent switch at Do Not Disturb.';

  @override
  String get notifyTestCriticalDenied =>
      'Hindi pinapayagan ang critical alerts sa device na ito, kaya mananatiling tahimik ang mga mahalagang alerto kapag naka-silent ang telepono.';

  @override
  String get notifyTestPermissionOff =>
      'Naka-off ang mga notipikasyon, kaya walang lalabas kapag sinubukan.';

  @override
  String get notifyTestBehaviourOverrides =>
      'Tutunog kahit naka-silent o Do Not Disturb';

  @override
  String get notifyTestBehaviourAlerts =>
      'May tunog at banner, maliban kung naka-silent ang telepono';

  @override
  String get notifyTestBehaviourSounds =>
      'May tunog, walang banner, maliban kung naka-silent ang telepono';

  @override
  String get notifyTestBehaviourSilent =>
      'Tahimik — sa listahan ng notipikasyon lang';

  @override
  String get notifyTestFailed =>
      'Hindi naipadala ang pansubok na notipikasyon.';

  @override
  String get moreBugReports => 'Mga naulat na bug';

  @override
  String get bugTrackerEmpty => 'Wala pang naulat na bug';

  @override
  String get bugTrackerReplies => 'Mga sagot';

  @override
  String get bugTrackerGoToDiscord =>
      'Hindi mo makita ang iyong problema? Iulat ito sa Discord!';

  @override
  String get bugTrackerNoMatch => 'Walang bug na tumutugma sa mga piling tag';

  @override
  String get bugTrackerDeveloper => 'Developer';

  @override
  String get bugTrackerCannotDisplay =>
      'Hindi maipakita ang nilalaman na ito — tingnan sa Discord';

  @override
  String get bugTrackerJoinDiscussion => 'Makilahok sa talakayan sa Discord';

  @override
  String get bugTrackerSortLast => 'Pinakabagong aktibidad';

  @override
  String get bugTrackerSortMostDiscussed => 'Pinakamaraming talakayan';

  @override
  String get bugTrackerStaff => 'Kawani';

  @override
  String eewSpokenLocalIntensity(String intensity) {
    return 'Tinatayang intensidad sa iyong lokasyon: $intensity.';
  }

  @override
  String eewSpokenMaxIntensity(String intensity) {
    return 'Tinatayang pinakamataas na intensidad: $intensity.';
  }
}
