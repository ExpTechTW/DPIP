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
  String get moreSectionGeneral => 'General';

  @override
  String get regionManageTitle => 'Saved regions';

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
  String get mapLayers => 'Layers';

  @override
  String get mapLayerRadar => 'Radar';

  @override
  String get mapTimelineNow => 'Now';

  @override
  String get mapTimelineObserved => 'Observed';

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
      'Welcome to DPIP (Disaster Prevention Information Platform). Please read these terms before using the app.\n\n1. Nature of service: DPIP aggregates earthquake, weather, and disaster information from the Central Weather Administration (CWA), ExpTech, and other sources on a best-effort basis. It is for reference only and does not replace official government warnings and instructions; for actual disaster response, follow the CWA and the competent authorities.\n\n2. Timeliness and accuracy: Delivery may be delayed, interrupted, or incomplete due to network, device, system, or third-party factors. Earthquake early warnings are inherently uncertain and may produce false or missed alarms — do not rely on this service as your sole means of disaster preparedness.\n\n3. Location and data: To provide localized alerts, the app collects and uploads your approximate location and push identifier, in the foreground and background, solely to decide which alerts to send you.\n\n4. Limitation of liability: To the maximum extent permitted by law, ExpTech and its developers are not liable for any direct or indirect damages arising from the use of, or inability to use, this service.\n\n5. Changes: These terms may be updated at any time without individual notice; continued use constitutes acceptance of the latest terms.\n\nBy tapping \"Agree and continue\" you confirm that you have read, understood, and agree to these Terms of Service.';

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
  String get onboardingPermLocationDesc =>
      'Automatically target alerts to where you are — including in the background.';

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
}
