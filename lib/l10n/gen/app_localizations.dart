import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// Bottom-nav label and page title for the Home tab
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// Bottom-nav label and page title for the Events tab
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get navEvents;

  /// Bottom-nav label and page title for the Map tab
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get navMap;

  /// Bottom-nav label and page title for the Earthquake tab (the swappable slot)
  ///
  /// In en, this message translates to:
  /// **'Earthquake'**
  String get navEarthquake;

  /// Bottom-nav label and page title for the More tab
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get navMore;

  /// Title of the in-app log viewer and its entry in the More menu
  ///
  /// In en, this message translates to:
  /// **'App logs'**
  String get appLogs;

  /// Placeholder shown in place of the map while MapLibre is disabled
  ///
  /// In en, this message translates to:
  /// **'Map (temporarily disabled)'**
  String get mapPlaceholderDisabled;

  /// Section header on the More page grouping general settings entries
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get moreSectionGeneral;

  /// More-menu entry that opens the region picker
  ///
  /// In en, this message translates to:
  /// **'Saved regions'**
  String get regionManageTitle;

  /// Title of the region picker (city list) page
  ///
  /// In en, this message translates to:
  /// **'Select a region'**
  String get regionSelectTitle;

  /// Header showing how many saved-region slots are used
  ///
  /// In en, this message translates to:
  /// **'{count}/{max} selected'**
  String regionSelectCount(int count, int max);

  /// Snackbar shown when trying to add a region beyond the cap
  ///
  /// In en, this message translates to:
  /// **'You can save up to {max} regions'**
  String regionSelectFull(int max);

  /// Section header on the More page grouping advanced/developer entries
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get moreSectionAdvanced;

  /// More-menu entry / title for the developer diagnostics page
  ///
  /// In en, this message translates to:
  /// **'Developer settings'**
  String get moreDeveloper;

  /// Snackbar shown after copying a diagnostic value
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get developerCopied;

  /// Tooltip for the copy-all action on the developer page
  ///
  /// In en, this message translates to:
  /// **'Copy all'**
  String get developerCopyAll;

  /// Title of the experimental-features settings page and its More-menu entry
  ///
  /// In en, this message translates to:
  /// **'Experimental features'**
  String get experimentalFeatures;

  /// Section header on the More page grouping external website links
  ///
  /// In en, this message translates to:
  /// **'Links'**
  String get moreSectionLinks;

  /// More-menu link to the CWA earthquake early warning publication log website
  ///
  /// In en, this message translates to:
  /// **'CWA earthquake early warning'**
  String get moreCwaEew;

  /// More-menu link to the TREM detection report website
  ///
  /// In en, this message translates to:
  /// **'TREM detection report'**
  String get moreTremReport;

  /// More-menu link to the ExpTech server status website
  ///
  /// In en, this message translates to:
  /// **'Server status'**
  String get moreServerStatus;

  /// More-menu link to the ExpTech announcements website
  ///
  /// In en, this message translates to:
  /// **'Announcements'**
  String get moreAnnouncements;

  /// More-menu link to the ExpTech Discord community
  ///
  /// In en, this message translates to:
  /// **'Discord community'**
  String get moreDiscord;

  /// More-menu link to the DPIP notification send-record website
  ///
  /// In en, this message translates to:
  /// **'DPIP notification log'**
  String get moreNotifyLog;

  /// Snackbar shown when an external link fails to open in the browser
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the link'**
  String get moreLinkOpenFailed;

  /// Setting that forces the home weather backdrop to a fixed state
  ///
  /// In en, this message translates to:
  /// **'Weather animation'**
  String get weatherDynamicState;

  /// Subtitle explaining the weather animation setting
  ///
  /// In en, this message translates to:
  /// **'Override the home backdrop weather'**
  String get weatherDynamicStateSubtitle;

  /// Weather animation follows real conditions
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get weatherModeAuto;

  /// Weather animation forced to a clear sky
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get weatherModeClear;

  /// Weather animation forced to rain
  ///
  /// In en, this message translates to:
  /// **'Rain'**
  String get weatherModeRain;

  /// Weather animation forced to heavy fog
  ///
  /// In en, this message translates to:
  /// **'Fog'**
  String get weatherModeFog;

  /// Weather animation forced to a thunderstorm
  ///
  /// In en, this message translates to:
  /// **'Thunderstorm'**
  String get weatherModeThunderstorm;

  /// Generic loading label for an async view
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get commonLoading;

  /// Button that re-runs a failed request
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// Generic headline when an async request fails
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get commonError;

  /// Generic message when a loaded list is empty
  ///
  /// In en, this message translates to:
  /// **'Nothing to show'**
  String get commonEmpty;

  /// A realtime feed is establishing its first data
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get feedConnecting;

  /// Banner over a realtime feed whose data has aged past the freshness threshold
  ///
  /// In en, this message translates to:
  /// **'Data may be out of date'**
  String get feedStale;

  /// Banner/headline when a realtime feed has gone offline
  ///
  /// In en, this message translates to:
  /// **'Connection lost'**
  String get feedOffline;

  /// Header of the earthquake monitor when one or more alerts are active
  ///
  /// In en, this message translates to:
  /// **'Earthquake early warning'**
  String get eewTitle;

  /// Calm state of the earthquake monitor when the live feed reports no alert
  ///
  /// In en, this message translates to:
  /// **'No active earthquake early warning'**
  String get eewNone;

  /// One-line summary of an EEW alert's magnitude and depth
  ///
  /// In en, this message translates to:
  /// **'M{magnitude} · depth {depth} km'**
  String eewSummary(String magnitude, String depth);

  /// Region bar label for the whole-country view
  ///
  /// In en, this message translates to:
  /// **'Nationwide'**
  String get regionNationwide;

  /// Region bar label for the current GPS township
  ///
  /// In en, this message translates to:
  /// **'Current location'**
  String get regionCurrent;

  /// Shown when the current-location area is selected but GPS is off/unavailable
  ///
  /// In en, this message translates to:
  /// **'Can\'t get current location'**
  String get regionCurrentUnavailable;

  /// Label for the precipitation metric in the home weather header
  ///
  /// In en, this message translates to:
  /// **'Precipitation'**
  String get weatherPrecipitation;

  /// Label for the humidity metric in the home weather header
  ///
  /// In en, this message translates to:
  /// **'Humidity'**
  String get weatherHumidity;

  /// Title of the map layer-picker sheet
  ///
  /// In en, this message translates to:
  /// **'Layers'**
  String get mapLayers;

  /// Name of the radar echo map layer in the layer picker
  ///
  /// In en, this message translates to:
  /// **'Radar'**
  String get mapLayerRadar;

  /// Label on the map timeline when the newest (latest) frame is selected
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get mapTimelineNow;

  /// Label above the map timeline's date (the radar observation time), e.g. Observed / 2026/07/14
  ///
  /// In en, this message translates to:
  /// **'Observed'**
  String get mapTimelineObserved;

  /// More-menu entry that opens the notification-settings page
  ///
  /// In en, this message translates to:
  /// **'Notification settings'**
  String get notifySettingsMenu;

  /// Title of the notification-settings page
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifyTitle;

  /// Shown on the notify page when there is no push token yet
  ///
  /// In en, this message translates to:
  /// **'Push notifications aren\'t ready yet — try again shortly.'**
  String get notifyUnavailable;

  /// Snackbar shown when saving a notification channel fails
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save the setting. Please try again.'**
  String get notifySetFailed;

  /// Notify page section header
  ///
  /// In en, this message translates to:
  /// **'Earthquake early warning'**
  String get notifySectionEew;

  /// Notify page section header
  ///
  /// In en, this message translates to:
  /// **'Earthquake'**
  String get notifySectionEarthquake;

  /// Notify page section header
  ///
  /// In en, this message translates to:
  /// **'Weather'**
  String get notifySectionWeather;

  /// Notify page section header
  ///
  /// In en, this message translates to:
  /// **'Tsunami'**
  String get notifySectionTsunami;

  /// Notify page section header
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get notifySectionOther;

  /// Notify channel title
  ///
  /// In en, this message translates to:
  /// **'Emergency earthquake alert'**
  String get notifyEew;

  /// Notify channel title
  ///
  /// In en, this message translates to:
  /// **'Strong-motion monitor'**
  String get notifyMonitor;

  /// Notify channel title
  ///
  /// In en, this message translates to:
  /// **'Earthquake report'**
  String get notifyReport;

  /// Notify channel title
  ///
  /// In en, this message translates to:
  /// **'Intensity report'**
  String get notifyIntensity;

  /// Notify channel title
  ///
  /// In en, this message translates to:
  /// **'Thunderstorm alerts'**
  String get notifyThunderstorm;

  /// Notify channel title
  ///
  /// In en, this message translates to:
  /// **'Weather advisories'**
  String get notifyAdvisory;

  /// Notify channel title
  ///
  /// In en, this message translates to:
  /// **'Disaster information'**
  String get notifyEvacuation;

  /// Notify channel title
  ///
  /// In en, this message translates to:
  /// **'Tsunami information'**
  String get notifyTsunami;

  /// Notify channel title
  ///
  /// In en, this message translates to:
  /// **'Announcements'**
  String get notifyAnnouncement;

  /// Notify option label
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get notifyOptOff;

  /// Notify option label
  ///
  /// In en, this message translates to:
  /// **'Receive all'**
  String get notifyOptAll;

  /// Notify option label
  ///
  /// In en, this message translates to:
  /// **'Local intensity 4 or above'**
  String get notifyOptLocalIntensity4;

  /// Notify option label
  ///
  /// In en, this message translates to:
  /// **'Local intensity 1 or above'**
  String get notifyOptLocalIntensity1;

  /// Notify option label
  ///
  /// In en, this message translates to:
  /// **'Current location only'**
  String get notifyOptWeatherLocal;

  /// Notify option label
  ///
  /// In en, this message translates to:
  /// **'Tsunami warnings only'**
  String get notifyOptTsunamiWarning;

  /// Notify option label
  ///
  /// In en, this message translates to:
  /// **'Tsunami advisories and warnings'**
  String get notifyOptTsunamiAll;

  /// Onboarding next-step button
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// Onboarding back button
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get onboardingBack;

  /// Hint shown until the user scrolls to the end
  ///
  /// In en, this message translates to:
  /// **'Scroll down to continue'**
  String get onboardingScrollHint;

  /// Onboarding intro page title
  ///
  /// In en, this message translates to:
  /// **'Welcome to DPIP'**
  String get onboardingIntroTitle;

  /// Onboarding intro page body
  ///
  /// In en, this message translates to:
  /// **'DPIP is your disaster-prevention companion. It brings together earthquake early warnings, earthquake reports, weather, and hazard information, and alerts you the moment it matters.\n\n• Earthquakes: early warnings, intensity reports, and detailed reports\n• Weather: real-time thunderstorm messages and weather advisories\n• Tsunami and disaster information\n\nNext, we\'ll ask you to review the Terms of Service and grant a few permissions so DPIP can protect you in real time.'**
  String get onboardingIntroBody;

  /// Onboarding terms page title
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get onboardingTermsTitle;

  /// Onboarding terms of service body
  ///
  /// In en, this message translates to:
  /// **'Please read the following notices before using DPIP:\n\n• All information should defer to the content published by the Central Weather Administration (CWA).\n\n• Depending on network, server, app, and upstream data-source conditions, information may not be received; we make every effort to avoid this but cannot guarantee it never happens.\n\n• Strong shaking may reach your location before the notification does.\n\n• Earthquake early warnings are fast-computed results that may carry significant error — understand this and use them with caution.\n\n• Any behavior not sanctioned by the authorities may carry legal risk; please follow all applicable regulations.\n\nIn addition, to provide localized alerts, this service collects and uploads your approximate location and push identifier — in the foreground and background — solely to decide which alerts to send you.\n\nBy tapping \"Agree and continue\" you confirm that you have read, understood, and agree to the above.'**
  String get onboardingTermsBody;

  /// Terms agreement checkbox label
  ///
  /// In en, this message translates to:
  /// **'I have read and agree to the Terms of Service'**
  String get onboardingTermsAgree;

  /// Terms page continue button
  ///
  /// In en, this message translates to:
  /// **'Agree and continue'**
  String get onboardingAgreeContinue;

  /// Onboarding permissions page title
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get onboardingPermsTitle;

  /// Onboarding permissions page intro
  ///
  /// In en, this message translates to:
  /// **'So DPIP can alert you the moment disaster strikes, please grant the following. You can change these anytime in system settings.'**
  String get onboardingPermsBody;

  /// Permission row: notifications
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get onboardingPermNotify;

  /// Permission row description: notifications
  ///
  /// In en, this message translates to:
  /// **'Deliver earthquake, weather, and disaster alerts the moment they happen.'**
  String get onboardingPermNotifyDesc;

  /// Permission row: critical alerts (iOS)
  ///
  /// In en, this message translates to:
  /// **'Critical alerts'**
  String get onboardingPermCritical;

  /// Permission row description: critical alerts
  ///
  /// In en, this message translates to:
  /// **'Let life-threatening earthquake warnings sound even in silent mode or Do Not Disturb.'**
  String get onboardingPermCriticalDesc;

  /// Permission row: location
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get onboardingPermLocation;

  /// Permission row description: location
  ///
  /// In en, this message translates to:
  /// **'Target alerts to where you are.'**
  String get onboardingPermLocationDesc;

  /// Permission row: background/Always location
  ///
  /// In en, this message translates to:
  /// **'Background location'**
  String get onboardingPermBackground;

  /// Permission row description: background location
  ///
  /// In en, this message translates to:
  /// **'Allow \"Always\" so alerts still target you when the app is closed.'**
  String get onboardingPermBackgroundDesc;

  /// Permission row: battery optimization (Android)
  ///
  /// In en, this message translates to:
  /// **'Battery exemption'**
  String get onboardingPermBattery;

  /// Permission row description: battery
  ///
  /// In en, this message translates to:
  /// **'Allow DPIP to keep running in the background so alerts aren\'t delayed or missed.'**
  String get onboardingPermBatteryDesc;

  /// Permission grant button
  ///
  /// In en, this message translates to:
  /// **'Grant'**
  String get onboardingGrant;

  /// Permission granted label
  ///
  /// In en, this message translates to:
  /// **'Granted'**
  String get onboardingGranted;

  /// Onboarding finish button
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get onboardingStart;

  /// Language picker tooltip / label
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Language picker option: follow the system language
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get languageSystem;

  /// Banner when the OS location toggle is off
  ///
  /// In en, this message translates to:
  /// **'Location services are off — local alerts can\'t target your area.'**
  String get locationBannerServiceOff;

  /// Banner when location permission is denied
  ///
  /// In en, this message translates to:
  /// **'Location permission is off — local alerts can\'t target your area.'**
  String get locationBannerPermission;

  /// Action on the location banner to open system settings
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get locationBannerFix;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
