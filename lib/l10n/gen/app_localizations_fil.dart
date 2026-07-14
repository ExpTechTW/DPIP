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
  String get navHome => 'Home';

  @override
  String get navEvents => 'Mga Kaganapan';

  @override
  String get navMap => 'Mapa';

  @override
  String get navEarthquake => 'Lindol';

  @override
  String get navMore => 'Higit Pa';

  @override
  String get appLogs => 'Mga log ng app';

  @override
  String get mapPlaceholderDisabled => 'Mapa (pansamantalang naka-disable)';

  @override
  String get moreSectionGeneral => 'Pangkalahatan';

  @override
  String get regionManageTitle => 'Mga naka-save na rehiyon';

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
  String get moreSectionAdvanced => 'Advanced';

  @override
  String get moreDeveloper => 'Mga setting ng developer';

  @override
  String get developerCopied => 'Nakopya sa clipboard';

  @override
  String get developerCopyAll => 'Kopyahin lahat';

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
  String get mapLayerRadar => 'Radar';

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
}
