import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fil.dart';
import 'app_localizations_id.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_th.dart';
import 'app_localizations_vi.dart';
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
    Locale('fil'),
    Locale('id'),
    Locale('ja'),
    Locale('ko'),
    Locale('th'),
    Locale('vi'),
    Locale('zh'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
    Locale.fromSubtags(
      languageCode: 'zh',
      countryCode: 'HK',
      scriptCode: 'Hant',
    ),
  ];

  /// This language's own name, shown in the in-app language picker. Each locale's ARB names itself; the picker is built from these, never a hardcoded list.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageName;

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

  /// Button to open the region picker to add a saved region
  ///
  /// In en, this message translates to:
  /// **'Add a region'**
  String get regionAddButton;

  /// Empty state on the saved-regions manage page
  ///
  /// In en, this message translates to:
  /// **'No saved regions yet'**
  String get regionEmpty;

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
  /// **'Debug info'**
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

  /// Error headline when a data request (AsyncView) fails, with a retry button
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load data. Please try again.'**
  String get commonFetchFailed;

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

  /// Name of the composite radar reflectivity layer in the layer picker
  ///
  /// In en, this message translates to:
  /// **'Composite Radar Reflectivity'**
  String get mapLayerRadar;

  /// Name of the Himawari infrared layer in the layer picker
  ///
  /// In en, this message translates to:
  /// **'Himawari Infrared'**
  String get mapLayerSatellite;

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

  /// Label next to the language picker on the welcome screen
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageSettings;

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

  /// App-wide banner shown when notification permission is disabled
  ///
  /// In en, this message translates to:
  /// **'Notifications are off — you won\'t receive disaster alerts.'**
  String get notifyBannerDisabled;

  /// Title of the confirm dialog shown when finishing onboarding without key permissions
  ///
  /// In en, this message translates to:
  /// **'Permissions not granted'**
  String get onboardingSkipTitle;

  /// Body of the skip-permissions confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Without location and notifications, DPIP can\'t alert you to earthquakes and disasters near you in real time. You can still grant them later in Settings.'**
  String get onboardingSkipBody;

  /// Dismiss the skip dialog and return to grant permissions
  ///
  /// In en, this message translates to:
  /// **'Go back'**
  String get onboardingSkipStay;

  /// Proceed past onboarding without granting permissions
  ///
  /// In en, this message translates to:
  /// **'Skip anyway'**
  String get onboardingSkipLeave;

  /// More-menu link to the ExpTech YouTube channel
  ///
  /// In en, this message translates to:
  /// **'YouTube'**
  String get moreYoutube;

  /// More-menu link to the ExpTech GitHub organisation
  ///
  /// In en, this message translates to:
  /// **'ExpTech GitHub'**
  String get moreGithub;

  /// More-menu link to DPIP's source repository on GitHub
  ///
  /// In en, this message translates to:
  /// **'Source code'**
  String get moreSourceCode;

  /// More-page section header for the app-store download links
  ///
  /// In en, this message translates to:
  /// **'Get the app'**
  String get moreSectionApp;

  /// Google Play store link title (brand name)
  ///
  /// In en, this message translates to:
  /// **'Google Play'**
  String get moreGooglePlay;

  /// Apple App Store link title (brand name)
  ///
  /// In en, this message translates to:
  /// **'App Store'**
  String get moreAppStore;

  /// Display-settings menu entry and page title (theme mode)
  ///
  /// In en, this message translates to:
  /// **'Display'**
  String get displaySettings;

  /// Section header for the theme-mode chooser on the Display settings page
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get displayTheme;

  /// Theme option: follow the system light/dark setting
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// Theme option: always light
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// Theme option: always dark
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// More-menu section header for about / legal links
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get moreSectionAbout;

  /// More-menu link title for the Terms of Service
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// More-menu link title for the FAQ / help page
  ///
  /// In en, this message translates to:
  /// **'FAQ'**
  String get faq;

  /// More-menu entry that opens the bundled open-source license list
  ///
  /// In en, this message translates to:
  /// **'Open-source licenses'**
  String get openSourceLicenses;

  /// Support page title and the More-menu entry that opens it
  ///
  /// In en, this message translates to:
  /// **'Support DPIP'**
  String get sponsorTitle;

  /// Support page intro paragraph explaining why donations help
  ///
  /// In en, this message translates to:
  /// **'DPIP is dedicated to real-time disaster-prevention information, with no ads or other revenue model. Your support helps us keep the servers running and keep developing.'**
  String get sponsorIntro;

  /// Support page section header for recurring subscription tiers
  ///
  /// In en, this message translates to:
  /// **'Subscriptions'**
  String get sponsorSubscriptions;

  /// Badge on the recommended (subscription) support section
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get sponsorRecommended;

  /// Support page section header for one-time tips
  ///
  /// In en, this message translates to:
  /// **'One-time'**
  String get sponsorOneTime;

  /// Monthly price label for a subscription; price is the store-localized amount
  ///
  /// In en, this message translates to:
  /// **'{price} / month'**
  String sponsorPerMonth(String price);

  /// Footer action that restores previously bought purchases
  ///
  /// In en, this message translates to:
  /// **'Restore purchases'**
  String get sponsorRestore;

  /// Footer link to the Terms of Use
  ///
  /// In en, this message translates to:
  /// **'Terms of Use'**
  String get sponsorTerms;

  /// Footer link to the Privacy Policy
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get sponsorPrivacy;

  /// Snackbar shown when a purchase restore has been requested
  ///
  /// In en, this message translates to:
  /// **'Restoring purchases…'**
  String get sponsorRestoring;

  /// Snackbar shown when the store can't be reached to restore
  ///
  /// In en, this message translates to:
  /// **'Can\'t reach the store. Please try again later.'**
  String get sponsorRestoreUnavailable;

  /// Generic close button / action label
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// Map layer switcher label for the air-temperature layer
  ///
  /// In en, this message translates to:
  /// **'Temperature'**
  String get mapLayerTemperature;

  /// Trend chart range toggle: last 24 hours
  ///
  /// In en, this message translates to:
  /// **'24h'**
  String get trendRange24h;

  /// Trend chart range toggle: last 7 days
  ///
  /// In en, this message translates to:
  /// **'7d'**
  String get trendRange7d;

  /// Shown in the station trend chart when there is no data to plot
  ///
  /// In en, this message translates to:
  /// **'No trend data'**
  String get trendNoData;

  /// Map layer switcher label for the humidity layer
  ///
  /// In en, this message translates to:
  /// **'Humidity'**
  String get mapLayerHumidity;

  /// Map layer switcher label for the air-pressure layer
  ///
  /// In en, this message translates to:
  /// **'Pressure'**
  String get mapLayerPressure;

  /// Map layer switcher label for the wind-direction layer
  ///
  /// In en, this message translates to:
  /// **'Wind direction'**
  String get mapLayerWind;

  /// Layer-switcher label for the typhoon map layer
  ///
  /// In en, this message translates to:
  /// **'Typhoon'**
  String get mapLayerTyphoon;

  /// No description provided for @typhoonNoActive.
  ///
  /// In en, this message translates to:
  /// **'No active typhoon'**
  String get typhoonNoActive;

  /// No description provided for @typhoonWind.
  ///
  /// In en, this message translates to:
  /// **'Wind'**
  String get typhoonWind;

  /// No description provided for @typhoonGust.
  ///
  /// In en, this message translates to:
  /// **'Gust'**
  String get typhoonGust;

  /// No description provided for @typhoonPressure.
  ///
  /// In en, this message translates to:
  /// **'Pressure'**
  String get typhoonPressure;

  /// No description provided for @typhoonMotion.
  ///
  /// In en, this message translates to:
  /// **'Moving'**
  String get typhoonMotion;

  /// Bulletin table row label
  ///
  /// In en, this message translates to:
  /// **'Centre location'**
  String get typhoonLabelPosition;

  /// Bulletin table row label
  ///
  /// In en, this message translates to:
  /// **'Past movement direction'**
  String get typhoonLabelDirection;

  /// Bulletin table row label
  ///
  /// In en, this message translates to:
  /// **'Past movement speed'**
  String get typhoonLabelSpeed;

  /// Bulletin table row label
  ///
  /// In en, this message translates to:
  /// **'Central pressure'**
  String get typhoonLabelPressure;

  /// Bulletin table row label
  ///
  /// In en, this message translates to:
  /// **'Max. sustained wind near centre'**
  String get typhoonLabelWind;

  /// Bulletin table row label
  ///
  /// In en, this message translates to:
  /// **'Peak gust'**
  String get typhoonLabelGust;

  /// Bulletin table row label
  ///
  /// In en, this message translates to:
  /// **'Avg. radius of Beaufort 7 winds'**
  String get typhoonLabelGaleAvg;

  /// Bulletin table row label
  ///
  /// In en, this message translates to:
  /// **'Avg. radius of Beaufort 10 winds'**
  String get typhoonLabelStormAvg;

  /// Forecast point: radius of the 70% track probability circle
  ///
  /// In en, this message translates to:
  /// **'70% probability circle'**
  String get typhoonLabelProbCircle;

  /// Forecast lead time for a tapped track point
  ///
  /// In en, this message translates to:
  /// **'Forecast +{hours} h'**
  String typhoonForecastLead(String hours);

  /// No description provided for @typhoonLabelNw.
  ///
  /// In en, this message translates to:
  /// **'NW'**
  String get typhoonLabelNw;

  /// No description provided for @typhoonLabelNe.
  ///
  /// In en, this message translates to:
  /// **'NE'**
  String get typhoonLabelNe;

  /// No description provided for @typhoonLabelSw.
  ///
  /// In en, this message translates to:
  /// **'SW'**
  String get typhoonLabelSw;

  /// No description provided for @typhoonLabelSe.
  ///
  /// In en, this message translates to:
  /// **'SE'**
  String get typhoonLabelSe;

  /// No description provided for @typhoonValueLat.
  ///
  /// In en, this message translates to:
  /// **'{lat}°N'**
  String typhoonValueLat(String lat);

  /// No description provided for @typhoonValueLon.
  ///
  /// In en, this message translates to:
  /// **'{lon}°E'**
  String typhoonValueLon(String lon);

  /// No description provided for @typhoonValueKm.
  ///
  /// In en, this message translates to:
  /// **'{n} km'**
  String typhoonValueKm(String n);

  /// No description provided for @typhoonValueHpa.
  ///
  /// In en, this message translates to:
  /// **'{n} hPa'**
  String typhoonValueHpa(String n);

  /// No description provided for @typhoonValueMs.
  ///
  /// In en, this message translates to:
  /// **'{n} m/s'**
  String typhoonValueMs(String n);

  /// Bulletin data time under the intensity chip (Taipei wall clock)
  ///
  /// In en, this message translates to:
  /// **'Data time\n{time}'**
  String typhoonDataTime(String time);

  /// Map layer switcher label for the real-time seismic monitor (RTS)
  ///
  /// In en, this message translates to:
  /// **'Seismic Monitor'**
  String get mapLayerMonitor;

  /// Empty-state hint in the map station-value sheet, shown before any station is selected
  ///
  /// In en, this message translates to:
  /// **'Tap a station to see its reading'**
  String get stationSheetEmpty;

  /// RTS monitor latency: how far behind the latest snapshot is (calibrated now minus the snapshot timestamp), in seconds — pre-formatted to one decimal, e.g. "0.3"
  ///
  /// In en, this message translates to:
  /// **'Delay {value} s'**
  String monitorDelay(String value);

  /// Shown in the monitor panel before the first RTS snapshot arrives
  ///
  /// In en, this message translates to:
  /// **'Waiting for data…'**
  String get monitorWaiting;

  /// Unit footer under a map colour legend (e.g. Unit: dBZ)
  ///
  /// In en, this message translates to:
  /// **'Unit: {unit}'**
  String mapLegendUnit(String unit);

  /// Typhoon map legend: past/observed path
  ///
  /// In en, this message translates to:
  /// **'Observed track'**
  String get typhoonLegendPast;

  /// CWA class: tropical depression (past-track colour)
  ///
  /// In en, this message translates to:
  /// **'Tropical depression'**
  String get typhoonIntensityTd;

  /// CWA class: mild typhoon (past-track colour)
  ///
  /// In en, this message translates to:
  /// **'Mild typhoon'**
  String get typhoonIntensityMild;

  /// CWA class: moderate typhoon (past-track colour)
  ///
  /// In en, this message translates to:
  /// **'Moderate typhoon'**
  String get typhoonIntensityModerate;

  /// CWA class: intense typhoon (past-track colour)
  ///
  /// In en, this message translates to:
  /// **'Intense typhoon'**
  String get typhoonIntensityIntense;

  /// Typhoon map legend: forecast path
  ///
  /// In en, this message translates to:
  /// **'Forecast track'**
  String get typhoonLegendForecast;

  /// Typhoon map legend: forecast waypoint
  ///
  /// In en, this message translates to:
  /// **'Forecast point'**
  String get typhoonLegendForecastPoint;

  /// Typhoon map legend: current storm centre
  ///
  /// In en, this message translates to:
  /// **'Current centre'**
  String get typhoonLegendCurrent;

  /// Typhoon map legend: uncertainty cone
  ///
  /// In en, this message translates to:
  /// **'Forecast cone'**
  String get typhoonLegendCone;

  /// Collapsed map-legend chip label / tooltip — tap to expand
  ///
  /// In en, this message translates to:
  /// **'Legend'**
  String get mapLegendExpand;

  /// Tooltip on the control that collapses the map legend
  ///
  /// In en, this message translates to:
  /// **'Hide legend'**
  String get mapLegendCollapse;

  /// Typhoon UI: typhoonLegendCircle15
  ///
  /// In en, this message translates to:
  /// **'Gale circle (L7)'**
  String get typhoonLegendCircle15;

  /// Legend for the purple dashed mean-radius storm circle
  ///
  /// In en, this message translates to:
  /// **'Average circle'**
  String get typhoonLegendCircleAvg;

  /// Typhoon UI: typhoonLegendCircle25
  ///
  /// In en, this message translates to:
  /// **'Storm circle (L10)'**
  String get typhoonLegendCircle25;

  /// Per-quadrant storm-wind radii (km) for a typhoon circle
  ///
  /// In en, this message translates to:
  /// **'NE {ne} · SE {se} · SW {sw} · NW {nw} km'**
  String typhoonStormRadii(String ne, String se, String sw, String nw);

  /// Compact typhoon time chip / map label shape (day + hour, no month)
  ///
  /// In en, this message translates to:
  /// **'{day}日{hour}時'**
  String typhoonTimeChip(String day, String hour);

  /// Typhoon UI: typhoonLegendProbability
  ///
  /// In en, this message translates to:
  /// **'Strike probability'**
  String get typhoonLegendProbability;

  /// Typhoon UI: typhoonLegendWarningAreas
  ///
  /// In en, this message translates to:
  /// **'Warning areas'**
  String get typhoonLegendWarningAreas;

  /// Tooltip for the typhoon overlay-toggle chip beside the layer switcher
  ///
  /// In en, this message translates to:
  /// **'Typhoon overlay options'**
  String get typhoonOverlayMenuTooltip;

  /// Section header for L7/L10 storm-band choices in the overlay menu
  ///
  /// In en, this message translates to:
  /// **'Storm wind'**
  String get typhoonOverlaySectionStorm;

  /// Section header for optional typhoon overlays (probability, warning)
  ///
  /// In en, this message translates to:
  /// **'Overlays'**
  String get typhoonOverlaySectionExtra;

  /// Subtitle under each storm-band option (fill + dashed avg)
  ///
  /// In en, this message translates to:
  /// **'With average circle'**
  String get typhoonOverlayStormBandSubtitle;

  /// Short hint under the strike-probability toggle
  ///
  /// In en, this message translates to:
  /// **'Hides the forecast cone'**
  String get typhoonOverlayProbabilityHint;

  /// Tooltip for the strike-probability toggle; notes mutual exclusion with the cone
  ///
  /// In en, this message translates to:
  /// **'Show strike probability (hides the forecast cone)'**
  String get typhoonOverlayProbabilityTooltip;

  /// Tooltip for the warning-areas overlay toggle
  ///
  /// In en, this message translates to:
  /// **'Highlight counties under a typhoon warning'**
  String get typhoonOverlayWarningTooltip;

  /// Tooltip for the L7 storm-band radio option
  ///
  /// In en, this message translates to:
  /// **'Level-7 wind field + average circle (purple)'**
  String get typhoonOverlayStormL7Tooltip;

  /// Tooltip for the L10 storm-band radio row
  ///
  /// In en, this message translates to:
  /// **'Level-10 wind field + average circle (yellow)'**
  String get typhoonOverlayStormL10Tooltip;

  /// Overlay-menu section for radar / IR under the typhoon vectors
  ///
  /// In en, this message translates to:
  /// **'Weather underlay'**
  String get typhoonOverlaySectionWeather;

  /// No radar or satellite underlay
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get typhoonOverlayWeatherNone;

  /// Subtitle: weather tile matches typhoon report time
  ///
  /// In en, this message translates to:
  /// **'Aligned to bulletin time'**
  String get typhoonOverlayWeatherHint;

  /// Tooltip for clearing the weather underlay
  ///
  /// In en, this message translates to:
  /// **'No radar or infrared underlay'**
  String get typhoonOverlayWeatherNoneTooltip;

  /// Tooltip for radar underlay (mutex with IR)
  ///
  /// In en, this message translates to:
  /// **'Radar echo closest to the typhoon bulletin time'**
  String get typhoonOverlayWeatherRadarTooltip;

  /// Tooltip for Himawari IR underlay (mutex with radar)
  ///
  /// In en, this message translates to:
  /// **'Infrared closest to the typhoon bulletin time'**
  String get typhoonOverlayWeatherSatelliteTooltip;

  /// Typhoon UI: typhoonWarningTitle
  ///
  /// In en, this message translates to:
  /// **'Typhoon warning'**
  String get typhoonWarningTitle;

  /// List of counties under a typhoon warning
  ///
  /// In en, this message translates to:
  /// **'Areas: {areas}'**
  String typhoonWarningAreas(String areas);

  /// Typhoon UI: typhoonTrackDetail
  ///
  /// In en, this message translates to:
  /// **'Track detail'**
  String get typhoonTrackDetail;

  /// Typhoon UI: typhoonHistoryTitle
  ///
  /// In en, this message translates to:
  /// **'Dataset time'**
  String get typhoonHistoryTitle;

  /// Typhoon UI: typhoonHistoryLive
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get typhoonHistoryLive;

  /// Typhoon UI: typhoonSatelliteTitle
  ///
  /// In en, this message translates to:
  /// **'Satellite'**
  String get typhoonSatelliteTitle;

  /// Overlay menu: toggle forecast-point Flutter callout cards
  ///
  /// In en, this message translates to:
  /// **'Forecast tooltips'**
  String get typhoonOverlayForecastCallouts;

  /// Tooltip for the forecast callouts overlay toggle
  ///
  /// In en, this message translates to:
  /// **'Show forecast-point detail cards when zoomed in'**
  String get typhoonOverlayForecastCalloutsTooltip;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'en',
    'fil',
    'id',
    'ja',
    'ko',
    'th',
    'vi',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+script+country codes are specified.
  switch (locale.toString()) {
    case 'zh_Hant_HK':
      return AppLocalizationsZhHantHk();
  }

  // Lookup logic when language+script codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.scriptCode) {
          case 'Hans':
            return AppLocalizationsZhHans();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fil':
      return AppLocalizationsFil();
    case 'id':
      return AppLocalizationsId();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'th':
      return AppLocalizationsTh();
    case 'vi':
      return AppLocalizationsVi();
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
