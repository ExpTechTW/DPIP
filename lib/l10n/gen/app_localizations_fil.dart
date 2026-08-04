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
  String get mapLayers => 'Mga Layer';

  @override
  String get mapLayerRadar => 'Composite Radar Reflectivity';

  @override
  String get mapLayerSatellite => 'Himawari Infrared';

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
  String get mapTimelineObserved => 'Naobserbahan';

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
  String get aedSheetEmpty => 'I-tap ang AED marker para sa detalye';

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
}
