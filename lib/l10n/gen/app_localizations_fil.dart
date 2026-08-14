// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Filipino Pilipino (`fil`).
class AppLocalizationsFil extends AppLocalizations {
  AppLocalizationsFil([String locale = 'fil']) : super(locale);

  @override
  String get languageName => 'Filipino';

  @override
  String get navHome => 'Tahanan';

  @override
  String get navEvents => 'Mga Kaganapan';

  @override
  String get navMap => 'Mapa';

  @override
  String get navData => 'Datos';

  @override
  String get navEarthquake => 'Lindol';

  @override
  String get dataSectionSeismic => 'Seismic';

  @override
  String get dataEarthquakeSubtitle => 'Mga ulat ng lindol';

  @override
  String get dataSectionWeather => 'Panahon';

  @override
  String get dataWeatherRankingSubtitle => 'Live na ranggo ng istasyon';

  @override
  String get weatherRankingTitle => 'Mga ranggo ng obserbasyon';

  @override
  String weatherRankingMeta(String time, int count) {
    return 'Oras ng datos: $time\n$count istasyon';
  }

  @override
  String get weatherRankingEmpty => 'Walang obserbasyon na iraranggo';

  @override
  String get weatherRankingBy => 'Ayon sa';

  @override
  String get weatherRankingHighest => 'Pinakamataas';

  @override
  String get weatherRankingLowest => 'Pinakamababa';

  @override
  String get weatherRankingMergeTo => 'Pagsamahin';

  @override
  String get weatherRankingMergeTown => 'Bayan';

  @override
  String get weatherRankingMergeCounty => 'Lalawigan';

  @override
  String get weatherRankingWind => 'Bilis ng hangin';

  @override
  String get weatherRankingGust => 'Bugso';

  @override
  String get weatherRankingTempExtremes => 'Mga sukdulan ng temperatura';

  @override
  String get weatherRankingExtremeHigh => 'Pinakamataas ngayong araw';

  @override
  String get weatherRankingExtremeLow => 'Pinakamababa ngayong araw';

  @override
  String get weatherRankingExtremeRange => 'Saklaw sa araw';

  @override
  String weatherRankingRecordedAt(String time) {
    return 'Naitala noong $time';
  }

  @override
  String weatherRankingAnalysisCurrent(String value) {
    return 'Ngayon $value°C';
  }

  @override
  String weatherRankingAnalysisHigh(String value) {
    return 'Mataas $value';
  }

  @override
  String weatherRankingAnalysisLow(String value) {
    return 'Mababa $value';
  }

  @override
  String weatherRankingAnalysisRange(String value) {
    return 'Saklaw $value°C';
  }

  @override
  String get reportListEmpty => 'Walang ulat ng lindol';

  @override
  String get reportListEmptyFiltered =>
      'Walang ulat na tumutugma sa mga filter';

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
  String get reportListLocalFelt => 'Lokal na naramdaman';

  @override
  String get reportListToday => 'Ngayon';

  @override
  String get reportListYesterday => 'Kahapon';

  @override
  String reportListDayCount(int count) {
    return '$count';
  }

  @override
  String get reportListEnd => 'Dulo ng listahan';

  @override
  String get reportFilterTitle => 'Mga filter';

  @override
  String get reportFilterSort => 'Pagkakasunud-sunod';

  @override
  String get reportFilterSortTime => 'Oras';

  @override
  String get reportFilterSortIntensity => 'Intensity';

  @override
  String get reportFilterSortMagnitude => 'Magnitude';

  @override
  String get reportFilterSortDepth => 'Lalim';

  @override
  String get reportFilterOrderDesc => 'Pababa';

  @override
  String get reportFilterOrderAsc => 'Pataas';

  @override
  String get reportFilterIntensity => 'Intensity';

  @override
  String get reportFilterIntensityInfoTitle =>
      'Bagong at lumang intensity scale';

  @override
  String get reportFilterIntensityInfoIntro =>
      'Pinalitan ng CWA ang intensity scale noong 1 Ene 2020 (oras ng Taipei).';

  @override
  String get reportFilterIntensityInfoLegacyTitle => 'Luma (bago ang 2020)';

  @override
  String get reportFilterIntensityInfoLegacyBody =>
      'Antas 0–7 lang; walang 5−/5+/6−/6+.';

  @override
  String get reportFilterIntensityInfoModernTitle => 'Bago (mula 2020)';

  @override
  String get reportFilterIntensityInfoModernBody =>
      'Antas 0–4, 5−, 5+, 6−, 6+, 7. Gamit ng filter ang bagong scale; ang mga lumang event ay may legacy label sa listahan.';

  @override
  String get reportFilterMagnitude => 'Magnitude';

  @override
  String get reportFilterDepth => 'Depth';

  @override
  String reportFilterDepthKm(String depth) {
    return '$depth km';
  }

  @override
  String get reportFilterDate => 'Petsa';

  @override
  String get reportFilterDatePick => 'Pumili ng petsa';

  @override
  String get reportFilterDateStartNote => 'Start day: from 00:00（Taipei）';

  @override
  String get reportFilterDateEndNote => 'End day: through 24:00（Taipei）';

  @override
  String reportFilterRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String get reportFilterLocation => 'Lokasyon';

  @override
  String get reportFilterLocationHint => 'hal. Hualien, offshore';

  @override
  String get reportFilterAny => 'Lahat';

  @override
  String get reportFilterApply => 'I-apply';

  @override
  String get reportFilterReset => 'I-reset';

  @override
  String get reportListSearch => 'Maghanap';

  @override
  String get reportDetailTitle => 'Ulat ng Lindol';

  @override
  String reportDetailNumbered(String number) {
    return 'Blg. $number Makabuluhang Naramdamang Lindol';
  }

  @override
  String get reportDetailLocalFelt => 'Lokal na Naramdamang Lindol';

  @override
  String get reportDetailInfo => 'Mga Detalye';

  @override
  String get reportDetailOriginTime => 'Oras ng pangyayari';

  @override
  String get reportDetailEpicenter => 'Coordinates ng Epicenter';

  @override
  String get reportDetailMagnitude => 'Magnitude';

  @override
  String get reportDetailDepth => 'Lalim ng Hypocenter';

  @override
  String get reportDetailAreaIntensity => 'Intensity ayon sa lugar';

  @override
  String get reportDetailLocalIntensity => 'Intensity sa iyong lokasyon';

  @override
  String get reportDetailLocalIntensityUnavailable =>
      'Walang datos ng intensity';

  @override
  String get reportDetailSortByIntensity => 'Ayusin ayon sa intensity';

  @override
  String get reportDetailSortByCounty => 'Ayusin ayon sa lalawigan';

  @override
  String get reportDetailImage => 'Larawan ng Ulat';

  @override
  String get reportDetailImageUnavailable =>
      'Wala pang available na larawan ng ulat';

  @override
  String get reportDetailOpenReport => 'Pahina ng Ulat';

  @override
  String get reportDetailReplay => 'I-replay';

  @override
  String get navMore => 'Higit Pa';

  @override
  String get appLogs => 'Mga log ng app';

  @override
  String get changelogTitle => 'Changelog';

  @override
  String get changelogEmpty => 'Wala pang release notes';

  @override
  String get changelogTypePrerelease => 'Beta';

  @override
  String get changelogTypeStable => 'Stable';

  @override
  String get changelogCurrentVersion => 'Kasalukuyan';

  @override
  String get changelogVersionDetails => 'Detalye ng release';

  @override
  String get changelogBodyEmpty => 'Walang tala para sa release na ito.';

  @override
  String get mapPlaceholderDisabled => 'Mapa (pansamantalang naka-disable)';

  @override
  String get moreSectionRegion => 'Rehiyon';

  @override
  String get moreSectionNotify => 'Mga Abiso';

  @override
  String get moreSectionDisplay => 'Display';

  @override
  String get regionManageTitle => 'Mga naka-save na rehiyon';

  @override
  String get regionAddButton => 'Magdagdag ng rehiyon';

  @override
  String get regionEmpty => 'Wala pang naka-save na rehiyon';

  @override
  String get regionSelectTitle => 'Pumili ng rehiyon';

  @override
  String regionSelectCount(int count, int max) {
    return '$count/$max ang napili';
  }

  @override
  String regionSelectFull(int max) {
    return 'Maaari kang mag-save ng hanggang $max na rehiyon';
  }

  @override
  String get regionEdit => 'I-edit';

  @override
  String get moreSectionAdvanced => 'Advanced';

  @override
  String get moreDeveloper => 'Impormasyon sa debug';

  @override
  String get experimentalFeatures => 'Mga experimental na feature';

  @override
  String get moreSectionLinks => 'Mga Link';

  @override
  String get moreCwaEew => 'Maagang babala sa lindol ng CWA';

  @override
  String get moreTremReport => 'Ulat ng pagtukoy ng TREM';

  @override
  String get moreServerStatus => 'Katayuan ng server';

  @override
  String get moreAnnouncements => 'Mga Anunsyo';

  @override
  String get moreDiscord => 'Komunidad sa Discord';

  @override
  String get moreNotifyLog => 'Log ng notipikasyon ng DPIP';

  @override
  String get moreLinkOpenFailed => 'Hindi mabuksan ang link';

  @override
  String get weatherDynamicState => 'Animation ng panahon';

  @override
  String get weatherDynamicStateSubtitle =>
      'I-override ang panahon sa background ng home';

  @override
  String get weatherModeAuto => 'Awtomatiko';

  @override
  String get weatherModeClear => 'Maaliwalas';

  @override
  String get weatherModeRain => 'Ulan';

  @override
  String get weatherModeFog => 'Makapal na Hamog';

  @override
  String get weatherModeThunderstorm => 'Kulog at Kidlat';

  @override
  String get commonLoading => 'Naglo-load…';

  @override
  String get commonRetry => 'Subukan Muli';

  @override
  String get commonError => 'May Nangyaring Mali';

  @override
  String get commonFetchFailed => 'Hindi ma-load ang data. Pakisubukan muli.';

  @override
  String get commonEmpty => 'Walang Maipakita';

  @override
  String get feedConnecting => 'Kumokonekta…';

  @override
  String get feedStale => 'Maaaring luma na ang datos';

  @override
  String get feedOffline => 'Nawala ang koneksyon';

  @override
  String get eewTitle => 'Maagang babala sa lindol';

  @override
  String get eewNone => 'Walang aktibong maagang babala sa lindol';

  @override
  String eewSummary(String magnitude, String depth) {
    return 'M$magnitude · lalim $depth km';
  }

  @override
  String get regionNationwide => 'Buong bansa';

  @override
  String get regionCurrent => 'Kasalukuyang lokasyon';

  @override
  String get regionCurrentUnavailable =>
      'Hindi makuha ang kasalukuyang lokasyon';

  @override
  String get weatherPrecipitation => 'Pag-ulan';

  @override
  String get weatherHumidity => 'Halumigmig';

  @override
  String weatherDataTime(String station, String time) {
    return '$station · Oras ng datos $time';
  }

  @override
  String get homeViewOnMap => 'Tingnan sa mapa';

  @override
  String get homeForecastTitle => '24-oras na forecast';

  @override
  String homeForecastHighLow(String high, String low) {
    return 'T $high° · B $low°';
  }

  @override
  String homeForecastPop(String pop) {
    return '$pop%';
  }

  @override
  String homeForecastFeelsLike(String temp) {
    return 'Pakiramdam $temp°';
  }

  @override
  String homeForecastHumidity(String value) {
    return 'Halumigmig $value%';
  }

  @override
  String homeForecastWind(String direction, String level) {
    return '$direction · Force $level';
  }

  @override
  String get homeForecastUnavailable =>
      'Pumili ng bayan para makita ang forecast';

  @override
  String get homeForecastEmpty => 'Walang forecast';

  @override
  String get homeActiveEventsTitle => 'Mga aktibong event';

  @override
  String get homeActiveEventsEmpty => 'Walang aktibong event';

  @override
  String get homeRainTrendTitle => 'Ulan sa susunod na oras';

  @override
  String homeRainTrendMinute(int minute) {
    return '$minute min';
  }

  @override
  String homeRainTrendUpdated(String time) {
    return 'Na-update $time';
  }

  @override
  String get homeRainTrendNoData => 'Walang data';

  @override
  String get homeRainTrendScattered => 'Posibleng mahinang ulan';

  @override
  String get homeRainTrendLightSustained =>
      'Tuloy-tuloy na mahinang ulan sa susunod na oras';

  @override
  String homeRainTrendLightStopping(int minutes) {
    return 'Baka huminto ang mahinang ulan sa loob ng $minutes minuto';
  }

  @override
  String get homeRainTrendHeavySustained =>
      'Tuloy-tuloy na malakas na ulan sa susunod na oras';

  @override
  String homeRainTrendHeavyStopping(int minutes) {
    return 'Baka huminto ang malakas na ulan sa loob ng $minutes minuto';
  }

  @override
  String get mapLayers => 'Mga Layer';

  @override
  String get mapLayerOrderTitle => 'Ayusin ang ayos ng layer';

  @override
  String get mapLayerOrderReset => 'I-reset ang ayos';

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
  String get mapLayerQpesums => 'Pagtaya ng ulan sa susunod na 1 oras';

  @override
  String get mapLayerLightning => 'Kidlat';

  @override
  String lightningLegendCg(int minutes) {
    return 'Ulap–lupa · $minutes min';
  }

  @override
  String lightningLegendCc(int minutes) {
    return 'Ulap–ulap · $minutes min';
  }

  @override
  String get mapTimelineNow => 'Ngayon';

  @override
  String get mapTimelinePast => 'Nakaraan';

  @override
  String get mapTimelineFuture => 'Hinaharap';

  @override
  String get mapTimelineObserved => 'Naobserbahan';

  @override
  String get mapTimelineForecast => 'Pagtaya';

  @override
  String mapTimelineDataTime(String time) {
    return 'Oras ng data $time';
  }

  @override
  String get notifySettingsMenu => 'Mga setting ng notipikasyon';

  @override
  String get notifyTitle => 'Mga Notipikasyon';

  @override
  String get notifyUnavailable =>
      'Hindi pa handa ang push notifications — subukan muli mamaya.';

  @override
  String get notifySetFailed => 'Hindi ma-save ang setting. Pakisubukan muli.';

  @override
  String get notifySectionEew => 'Maagang babala sa lindol';

  @override
  String get notifySectionEarthquake => 'Lindol';

  @override
  String get notifySectionWeather => 'Panahon';

  @override
  String get notifySectionTsunami => 'Tsunami';

  @override
  String get notifySectionOther => 'Iba pa';

  @override
  String get notifyEew => 'Emergency na alerto sa lindol';

  @override
  String get notifyMonitor => 'Monitor ng malakas na paggalaw';

  @override
  String get notifyReport => 'Ulat ng lindol';

  @override
  String get notifyIntensity => 'Ulat ng intensidad';

  @override
  String get notifyThunderstorm => 'Mga alerto sa kulog at kidlat';

  @override
  String get notifyAdvisory => 'Mga advisory sa panahon';

  @override
  String get notifyEvacuation => 'Impormasyon sa sakuna';

  @override
  String get notifyTsunami => 'Impormasyon sa tsunami';

  @override
  String get notifyAnnouncement => 'Mga Anunsyo';

  @override
  String get notifyOptOff => 'Naka-off';

  @override
  String get notifyOptAll => 'Tumanggap ng lahat';

  @override
  String get notifyOptLocalIntensity4 => 'Lokal na intensidad 4 pataas';

  @override
  String get notifyOptLocalIntensity1 => 'Lokal na intensidad 1 pataas';

  @override
  String get notifyOptWeatherLocal => 'Kasalukuyang lokasyon lamang';

  @override
  String get notifyOptTsunamiWarning => 'Mga babala sa tsunami lamang';

  @override
  String get notifyOptTsunamiAll => 'Mga abiso at babala sa tsunami';

  @override
  String get onboardingNext => 'Susunod';

  @override
  String get onboardingBack => 'Bumalik';

  @override
  String get onboardingScrollHint => 'Mag-scroll pababa para magpatuloy';

  @override
  String get onboardingIntroTitle => 'Maligayang pagdating sa DPIP';

  @override
  String get onboardingIntroBody =>
      'Ang DPIP ang iyong kasama sa pag-iwas sa sakuna. Pinagsasama-sama nito ang mga maagang babala sa lindol, ulat ng lindol, panahon, at impormasyon sa panganib, at inaalertuhan ka sa sandaling mahalaga ito.\n\n• Mga lindol: mga maagang babala, ulat ng intensidad, at detalyadong ulat\n• Panahon: real-time na mensahe ng kulog at kidlat at mga advisory sa panahon\n• Impormasyon sa tsunami at sakuna\n\nSusunod, hihilingin naming basahin mo ang Mga Tuntunin ng Serbisyo at magbigay ng ilang pahintulot para maprotektahan ka ng DPIP nang real time.';

  @override
  String get onboardingTermsTitle => 'Mga Tuntunin ng Serbisyo';

  @override
  String get onboardingTermsBody =>
      'Mangyaring basahin ang mga sumusunod na paunawa bago gamitin ang DPIP:\n\n• Ang lahat ng impormasyon ay dapat sumunod sa nilalamang inilathala ng Central Weather Administration (CWA).\n\n• Depende sa kalagayan ng network, server, app, at pinagmumulan ng datos, may posibilidad na hindi matanggap ang impormasyon; ginagawa namin ang lahat ng aming makakaya upang maiwasan ito ngunit hindi namin magagarantiya na hindi ito mangyayari.\n\n• Maaaring maunang makarating sa iyong lokasyon ang malakas na pagyanig bago pa dumating ang notipikasyon.\n\n• Ang mga maagang babala sa lindol ay mabilis na kinakalkulang resulta na maaaring magtaglay ng malaking pagkakamali — unawain ito at gamitin nang may pag-iingat.\n\n• Anumang gawaing hindi pinahihintulutan ng mga awtoridad ay maaaring magdala ng panganib sa batas; mangyaring sundin ang lahat ng naaangkop na regulasyon.\n\nBukod dito, upang magbigay ng lokal na mga alerto, kinokolekta at ini-upload ng serbisyong ito ang iyong tinatayang lokasyon at push identifier — sa foreground at background — para lamang matukoy kung aling mga alerto ang ipapadala sa iyo.\n\nSa pamamagitan ng pag-tap sa \"Sumang-ayon at magpatuloy\" kinukumpirma mo na nabasa, naunawaan, at sinasang-ayunan mo ang nasa itaas.';

  @override
  String get onboardingTermsAgree =>
      'Nabasa ko na at sumasang-ayon ako sa Mga Tuntunin ng Serbisyo';

  @override
  String get onboardingAgreeContinue => 'Sumang-ayon at magpatuloy';

  @override
  String get onboardingPermsTitle => 'Mga Pahintulot';

  @override
  String get onboardingPermsBody =>
      'Para maalertuhan ka ng DPIP sa sandaling maganap ang sakuna, mangyaring ibigay ang mga sumusunod. Maaari mo itong baguhin anumang oras sa mga setting ng system.';

  @override
  String get onboardingPermNotify => 'Mga Notipikasyon';

  @override
  String get onboardingPermNotifyDesc =>
      'Ihatid ang mga alerto sa lindol, panahon, at sakuna sa sandaling maganap ang mga ito.';

  @override
  String get onboardingPermCritical => 'Mga kritikal na alerto';

  @override
  String get onboardingPermCriticalDesc =>
      'Hayaang tumunog ang mga nakamamatay na babala sa lindol kahit sa silent mode o Do Not Disturb.';

  @override
  String get onboardingPermLocation => 'Lokasyon';

  @override
  String get onboardingPermLocationDesc =>
      'Itutok ang mga alerto sa kinaroroonan mo.';

  @override
  String get onboardingPermBackground => 'Lokasyon sa background';

  @override
  String get onboardingPermBackgroundDesc =>
      'Payagan ang \"Always\" para patuloy kang matukoy ng mga alerto kahit sarado ang app.';

  @override
  String get onboardingPermBattery => 'Exemption sa baterya';

  @override
  String get onboardingPermBatteryDesc =>
      'Payagan ang DPIP na patuloy na tumakbo sa background para hindi maantala o mapalampas ang mga alerto.';

  @override
  String get onboardingGrant => 'Ibigay';

  @override
  String get onboardingGranted => 'Naibigay na';

  @override
  String get onboardingStart => 'Magsimula';

  @override
  String get language => 'Wika';

  @override
  String get languageSettings => 'Wika';

  @override
  String get languageSystem => 'Default ng system';

  @override
  String get locationBannerServiceOff =>
      'Naka-off ang mga serbisyo ng lokasyon — hindi matutukoy ng mga lokal na alerto ang iyong lugar.';

  @override
  String get locationBannerPermission =>
      'Naka-off ang pahintulot sa lokasyon — hindi matutukoy ng mga lokal na alerto ang iyong lugar.';

  @override
  String get locationBannerFix => 'Buksan ang mga setting';

  @override
  String get notifyBannerDisabled =>
      'Naka-off ang mga notification — hindi ka makakatanggap ng mga alerto sa sakuna.';

  @override
  String get onboardingSkipTitle => 'Hindi pa naibibigay ang mga pahintulot';

  @override
  String get onboardingSkipBody =>
      'Kung walang lokasyon at mga notification, hindi ka maaalertuhan ng DPIP nang real time sa mga lindol at sakuna malapit sa iyo. Maaari mo pa ring ibigay ang mga ito sa ibang pagkakataon sa Settings.';

  @override
  String get onboardingSkipStay => 'Bumalik';

  @override
  String get onboardingSkipLeave => 'Laktawan pa rin';

  @override
  String get moreYoutube => 'YouTube';

  @override
  String get moreGithub => 'ExpTech GitHub';

  @override
  String get moreSourceCode => 'Source code';

  @override
  String get moreSectionApp => 'Kunin ang app';

  @override
  String get moreGooglePlay => 'Google Play';

  @override
  String get moreAppStore => 'App Store';

  @override
  String get displaySettings => 'Pagpapakita';

  @override
  String get defaultMapLayerSettings => 'Default na layer ng mapa';

  @override
  String get defaultMapLayerSubtitle =>
      'Bubukas ang tab ng Mapa sa layer na ito. Susunod ang icon at label ng bottom navigation.';

  @override
  String get mapNavRadar => 'Radar';

  @override
  String get mapNavQpesums => 'Pagtaya';

  @override
  String get mapNavSatellite => 'Satellite';

  @override
  String get mapNavLightning => 'Kidlat';

  @override
  String get mapNavTyphoon => 'Bagyo';

  @override
  String get mapNavEarthquake => 'Lindol';

  @override
  String get mapNavTemperature => 'Temperatura';

  @override
  String get mapNavHumidity => 'Halumigmig';

  @override
  String get mapNavPressure => 'Presyon';

  @override
  String get mapNavWind => 'Hangin';

  @override
  String get mapNavRain => 'Ulan';

  @override
  String get mapNavDisaster => 'Sakuna';

  @override
  String get displayTheme => 'Tema';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeLight => 'Maliwanag';

  @override
  String get themeDark => 'Madilim';

  @override
  String get moreSectionAbout => 'Tungkol';

  @override
  String get termsOfService => 'Mga Tuntunin ng Serbisyo';

  @override
  String get faq => 'Mga FAQ';

  @override
  String get openSourceLicenses => 'Mga lisensya ng open-source';

  @override
  String get sponsorTitle => 'Suportahan ang DPIP';

  @override
  String get sponsorIntro =>
      'Nakatuon ang DPIP sa pagbibigay ng real-time na impormasyon sa pag-iwas sa sakuna, nang walang ad o iba pang modelo ng kita. Tumutulong ang inyong suporta na mapanatili ang mga server at magpatuloy sa pagbuo.';

  @override
  String get sponsorSubscriptions => 'Mga subscription';

  @override
  String get sponsorRecommended => 'Inirerekomenda';

  @override
  String get sponsorOneTime => 'Isang beses';

  @override
  String sponsorPerMonth(String price) {
    return '$price / buwan';
  }

  @override
  String get sponsorRestore => 'Ibalik ang mga pagbili';

  @override
  String get sponsorTerms => 'Mga Tuntunin ng Paggamit';

  @override
  String get sponsorPrivacy => 'Patakaran sa Privacy';

  @override
  String get sponsorRestoring => 'Ibinabalik ang mga pagbili…';

  @override
  String get sponsorRestoreUnavailable =>
      'Hindi maabot ang store. Pakisubukan muli mamaya.';

  @override
  String get commonClose => 'Isara';

  @override
  String get mapLayerTemperature => 'Temperatura';

  @override
  String get trendRange24h => '24 oras';

  @override
  String get trendRange7d => '7 araw';

  @override
  String get trendNoData => 'Walang trend data';

  @override
  String trendCumulativeTotal(String total) {
    return 'Kabuuang $total mm';
  }

  @override
  String chartHourLabel(int hour) {
    return '${hour}h';
  }

  @override
  String get mapLayerHumidity => 'Halumigmig';

  @override
  String get mapLayerPressure => 'Presyon';

  @override
  String get mapLayerWind => 'Hangin';

  @override
  String get mapLayerRain => 'Ulan';

  @override
  String get rainIntervalMenu => 'Bintana ng akumulasyon';

  @override
  String get rainIntervalNow => 'Ngayon';

  @override
  String get rainInterval10m => '10 min';

  @override
  String get rainInterval1h => '1 oras';

  @override
  String get rainInterval3h => '3 oras';

  @override
  String get rainInterval6h => '6 oras';

  @override
  String get rainInterval12h => '12 oras';

  @override
  String get rainInterval24h => '24 oras';

  @override
  String get rainInterval2d => '2 araw';

  @override
  String get rainInterval3d => '3 araw';

  @override
  String get mapLayerTyphoon => 'Bagyo';

  @override
  String get typhoonNoActive => 'Walang aktibong bagyo';

  @override
  String get typhoonWind => 'Hangin';

  @override
  String get typhoonGust => 'Ugong';

  @override
  String get typhoonPressure => 'Presyon';

  @override
  String get typhoonMotion => 'Gumagalaw';

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
  String get aedRegion => 'Rehiyon';

  @override
  String get aedCategory => 'Kategorya';

  @override
  String get aedType => 'Uri';

  @override
  String get aedPlaceDesc => 'Lokasyon ng paglagay';

  @override
  String get aedDescription => 'Tala';

  @override
  String get aedHoursWeekday => 'Oras sa weekday';

  @override
  String get aedHoursSaturday => 'Oras sa Sabado';

  @override
  String get aedHoursSunday => 'Oras sa Linggo';

  @override
  String get aedOpenRemark => 'Tala sa oras';

  @override
  String get aedEmergencyPhone => 'Emergency phone';

  @override
  String get mapLayerRestroom => 'Pampublikong Palikuran';

  @override
  String get mapLayerShelter => 'Silungan';

  @override
  String get disasterMapOverlayRestroomTooltip =>
      'Ipakita ang mga pampublikong palikuran';

  @override
  String get disasterMapOverlayShelterTooltip => 'Ipakita ang mga silungan';

  @override
  String get dpmOpenInMaps => 'Buksan sa mapa';

  @override
  String get mapAppGoogleMaps => 'Google Maps';

  @override
  String get mapAppAppleMaps => 'Apple Maps';

  @override
  String mapAppDefault(String app) {
    return '$app (default)';
  }

  @override
  String get mapAppCopyCoordinates => 'Kopyahin ang coordinates';

  @override
  String get mapAppCoordinatesCopied => 'Na-kopya ang coordinates';

  @override
  String mapAppOpenFailed(String app) {
    return 'Hindi mabuksan ang $app';
  }

  @override
  String get mapAppCallFailed => 'Hindi makatawag ang device na ito';

  @override
  String get mapOverlaySectionReference => 'Layer ng sanggunian';

  @override
  String get mapLayerCategoryEarthquake => 'Lindol';

  @override
  String get mapLayerCategoryTyphoon => 'Bagyo';

  @override
  String get mapLayerCategoryWeather => 'Obserbasyon sa panahon';

  @override
  String get mapLayerCategorySatellite => 'Satellite';

  @override
  String get mapLayerCategoryRadar => 'Radar';

  @override
  String get mapLayerCategoryLife => 'Pang-araw-araw na buhay';

  @override
  String get mapLayerCategoryForecast => 'Numerical forecast';

  @override
  String get mapOverlaySectionMap => 'Mapa';

  @override
  String get rainIntervalSection => 'Window ng oras';

  @override
  String get mapTownLabels => 'Mga pangalan ng bayan';

  @override
  String get mapTownLabelsHint =>
      'Ipakita ang mga pangalan ng bayan kapag naka-zoom';

  @override
  String get mapTerrainRelief => 'Rehiyebo ng terrain';

  @override
  String get mapTerrainReliefHint => 'Ipakita ang anino ng terrain sa base map';

  @override
  String get dpmSheetEmpty => 'I-tap ang marker sa mapa para sa detalye';

  @override
  String get dpmAddress => 'Address';

  @override
  String get restroomTypeLabel => 'Uri';

  @override
  String get restroomCategoryLabel => 'Kategorya';

  @override
  String get restroomGradeLabel => 'Baitang';

  @override
  String get restroomTypeFemale => 'Palikuran ng babae';

  @override
  String get restroomTypeMale => 'Palikuran ng lalaki';

  @override
  String get restroomTypeMixed => 'Pinagsamang palikuran';

  @override
  String get restroomTypeAccessible => 'Palikurang may accessibility';

  @override
  String get restroomTypeGenderNeutral => 'Palikurang neutral sa kasarian';

  @override
  String get restroomTypeFamily => 'Palikuran ng pamilya';

  @override
  String get restroomTypeUnspecified => 'Hindi natukoy';

  @override
  String get restroomCategoryTransport => 'Transportasyon';

  @override
  String get restroomCategoryPark => 'Parke';

  @override
  String get restroomCategoryCommercial => 'Komersyal na establisyimento';

  @override
  String get restroomCategoryReligious => 'Relihiyosong lugar';

  @override
  String get restroomCategoryCultural => 'Pook na pangkultura';

  @override
  String get restroomCategoryGovernment => 'Opisina ng gobyerno';

  @override
  String get restroomCategoryWelfare => 'Institusyon ng kapakanan';

  @override
  String get restroomCategoryTourist => 'Lugar para sa turista';

  @override
  String get restroomCategoryLeisure => 'Lugar ng libangan';

  @override
  String get restroomCategoryOther => 'Iba pa';

  @override
  String get restroomGradeExcellent => 'Napakahusay';

  @override
  String get restroomGradeGood => 'Mahusay';

  @override
  String get restroomGradeAverage => 'Katamtaman';

  @override
  String get restroomGradePoor => 'Mas mababa sa pamantayan';

  @override
  String get shelterAddressLabel => 'Address';

  @override
  String get shelterCapacityLabel => 'Kapasidad';

  @override
  String shelterCapacityValue(int n) {
    return '$n katao';
  }

  @override
  String get shelterCategoryLabel => 'Mga uri ng kalamidad';

  @override
  String get shelterIndoorLabel => 'Silungan sa loob';

  @override
  String get shelterOutdoorLabel => 'Silungan sa labas';

  @override
  String get shelterVulnerableOkLabel => 'Angkop para sa mahihina';

  @override
  String get dpmYes => 'Oo';

  @override
  String get dpmNo => 'Hindi';

  @override
  String get stationSheetEmpty => 'I-tap ang istasyon para makita ang datos';

  @override
  String monitorDelay(String value) {
    return 'Pagkaantala $value s';
  }

  @override
  String get monitorWaiting => 'Naghihintay ng data…';

  @override
  String mapLegendUnit(String unit) {
    return 'Yunit: $unit';
  }

  @override
  String get typhoonLegendPast => 'Aktwal na landas';

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
  String typhoonTyNo(String no) {
    return 'TY $no';
  }

  @override
  String typhoonTdNo(String no) {
    return 'TD $no';
  }

  @override
  String get typhoonIntensityMild => 'Mild typhoon';

  @override
  String get typhoonIntensityModerate => 'Moderate typhoon';

  @override
  String get typhoonIntensityIntense => 'Intense typhoon';

  @override
  String get typhoonLegendForecast => 'Tinatayang landas';

  @override
  String get typhoonLegendForecastPoint => 'Punto ng forecast';

  @override
  String get typhoonLegendCurrent => 'Kasalukuyang sentro';

  @override
  String get typhoonLegendCone => 'Kono ng forecast';

  @override
  String get mapLegendExpand => 'Alamat';

  @override
  String get mapLegendCollapse => 'Itago ang alamat';

  @override
  String get mapMyLocation => 'Aking lokasyon';

  @override
  String get mapResetNorth => 'Bumalik sa hilaga';

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
  String get dpmFilterSectionRestroom => 'Mga uri ng lugar';

  @override
  String get dpmFilterSectionRestroomType => 'Mga uri ng banyo';

  @override
  String get dpmFilterSectionShelter => 'Mga uri ng sakuna sa silungan';

  @override
  String get dpmDisasterFlood => 'Baha';

  @override
  String get dpmDisasterEarthquake => 'Lindol';

  @override
  String get dpmDisasterLandslide => 'Pagguho ng lupa';

  @override
  String get dpmDisasterTsunami => 'Tsunami';

  @override
  String get dpmDisasterSlope => 'Panganib sa dalisdis';

  @override
  String get dpmDisasterNuclear => 'Aksidente sa nukleyar';

  @override
  String get skyTime => 'Oras ng langit';

  @override
  String get skyTimeAuto => 'Awtomatiko';

  @override
  String get skyTimeDawn => 'Bukang-liwayway';

  @override
  String get skyTimeSunrise => 'Pagsikat ng araw';

  @override
  String get skyTimeMorning => 'Umaga';

  @override
  String get skyTimeNoon => 'Tanghali';

  @override
  String get skyTimeAfternoon => 'Hapon';

  @override
  String get skyTimeGolden => 'Gintong oras';

  @override
  String get skyTimeSunset => 'Paglubog ng araw';

  @override
  String get skyTimeDusk => 'Takipsilim';

  @override
  String get skyTimeNight => 'Gabi';

  @override
  String get weatherModeCloudy => 'Maulap';

  @override
  String get weatherModeOvercast => 'Makulimlim';

  @override
  String get weatherModeSnow => 'Niyebe';

  @override
  String get weatherModeSand => 'Alikabok';

  @override
  String get radarScanRange => 'Ipakita ang saklaw ng pag-scan';

  @override
  String get radarScanRangeSubtitle =>
      'Ipinapakita ang aktwal na saklaw ng apat na radar.';

  @override
  String get radarScanRangeHint => 'Sa labas: hindi naoobserbahan';

  @override
  String get radarOverlayMenuTooltip => 'Mga opsyon sa layer ng radar';

  @override
  String get radarCountyOutline => 'Mga hangganan ng lalawigan';

  @override
  String get radarGlobalOutline => 'Mga hangganan ng bansa';

  @override
  String get radarGlobalOutlineHint => 'Panlabas na balangkas ng bawat bansa';

  @override
  String get radarCountyOutlineHint => 'Iginuguhit sa ibabaw ng echo';

  @override
  String get radarCountyOutlineSubtitle =>
      'Nananatiling mababasa ang mga hangganan sa ilalim ng radar echo.';

  @override
  String get radarTownOutline => 'Mga hangganan ng bayan';

  @override
  String get radarTownOutlineHint => 'Mas pinong hati';

  @override
  String get radarTownOutlineSubtitle =>
      'Nananatiling mababasa ang mga hangganan ng bayan sa ilalim ng radar echo.';

  @override
  String get qpesumsOverlayMenuTooltip =>
      'Mga opsyon sa layer ng pagtataya ng pag-ulan';

  @override
  String get windForecastOverlayMenuTooltip =>
      'Mga opsyon sa layer ng pagtataya ng hangin';

  @override
  String get windForecastCountyOutlineHint =>
      'Iginuhit sa itaas ng patlang ng hangin';

  @override
  String get windForecastGlobalOutlineHint =>
      'Panlabas na balangkas ng bawat bansa';

  @override
  String get windForecastTownOutlineHint => 'Ang mas pinong mesh';

  @override
  String get meshtasticTitle => 'Mesh Network Test';

  @override
  String get meshtasticScan => 'Scan';

  @override
  String get meshtasticScanning => 'Scanning…';

  @override
  String get meshtasticDisconnect => 'Disconnect';

  @override
  String get meshtasticNoDevices => 'No Meshtastic devices found';

  @override
  String get meshtasticInitializing => 'Initializing Bluetooth…';

  @override
  String get meshtasticReady => 'Ready — press scan to find radios';

  @override
  String get meshtasticNotSupported =>
      'Bluetooth is not supported on this device';

  @override
  String get meshtasticNodes => 'Nodes';

  @override
  String get meshtasticMessages => 'Messages';

  @override
  String get meshtasticSend => 'Send';

  @override
  String get meshtasticSendHint => 'Message to broadcast';

  @override
  String get meshtasticStateDisconnected => 'Disconnected';

  @override
  String get meshtasticStateConnecting => 'Connecting…';

  @override
  String get meshtasticStateConfiguring => 'Configuring…';

  @override
  String get meshtasticStateConnected => 'Connected';

  @override
  String get meshtasticStateError => 'Error';

  @override
  String get meshtasticFailed => 'Operation failed';

  @override
  String get meshtasticNoMessages => 'No messages yet';

  @override
  String get meshtasticNoNodes => 'No nodes heard yet';

  @override
  String get meshtasticNotConnected => 'Not connected to a radio';

  @override
  String get meshtasticSelectDevice => 'Select a radio';

  @override
  String get meshtasticClearMessages => 'Clear messages';

  @override
  String get meshtasticEmptyMessage => '(empty message)';

  @override
  String get meshtasticCopied => 'Message copied';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get meshtasticReconnecting => 'Reconnecting…';

  @override
  String get meshtasticChannelWorking => 'Setting up the DPIP channel…';

  @override
  String get meshtasticChannelReady => 'DPIP channel ready';

  @override
  String get meshtasticChannelNoSlot =>
      'No free channel slot — free one on the radio';

  @override
  String get meshtasticChannelFailed => 'Couldn\'t set up the DPIP channel';

  @override
  String meshtasticRegionMismatch(String region) {
    return 'Radio region is $region — DPIP needs TW';
  }

  @override
  String get meshtasticRegionSwitch => 'Switch to TW';

  @override
  String get meshtasticRegionConfirm =>
      'Switch this radio to the TW region? It restarts and disconnects for a moment, and every other channel on it moves too.';

  @override
  String get meshtasticBusyTitle => 'Another app is using this radio';

  @override
  String get meshtasticBusyBody =>
      'Disconnect it in the other Meshtastic app first. Two apps on one radio take each other\'s messages, so some will go missing.';

  @override
  String get meshtasticConnectAnyway => 'Connect anyway';
}
