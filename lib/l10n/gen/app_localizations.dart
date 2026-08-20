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
import 'app_localizations_yue.dart';
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
    Locale('yue'),
    Locale('zh'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
    Locale.fromSubtags(
      languageCode: 'zh',
      countryCode: 'HK',
      scriptCode: 'Hant',
    ),
    Locale('zh', 'TW'),
  ];

  /// No description provided for @typhoonValueLat.
  ///
  /// In en, this message translates to:
  /// **'{lat}°N'**
  String typhoonValueLat(String lat);

  /// Body of the skip-permissions confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Without location and notifications, DPIP can\'t alert you to earthquakes and disasters near you in real time. You can still grant them later in Settings.'**
  String get onboardingSkipBody;

  /// No description provided for @rainInterval24h.
  ///
  /// In en, this message translates to:
  /// **'24 h'**
  String get rainInterval24h;

  /// Home rain trend subtitle: heavy rain forecast to stop partway through the hour
  ///
  /// In en, this message translates to:
  /// **'Heavy rain likely to stop in {minutes} minutes'**
  String homeRainTrendHeavyStopping(int minutes);

  /// Label above the map timeline's date (the radar observation time), e.g. Observed / 2026/07/14
  ///
  /// In en, this message translates to:
  /// **'Observed'**
  String get mapTimelineObserved;

  /// Warning above the map timeline when rapid scrubbing outruns its bounded render queue
  ///
  /// In en, this message translates to:
  /// **'Frame updates paused because you\'re scrubbing too fast. Slow down to resume.'**
  String get mapTimelineScrubPaused;

  /// Title of the region picker (city list) page
  ///
  /// In en, this message translates to:
  /// **'Select a region'**
  String get regionSelectTitle;

  /// Label for the skyTimeNoon option in the experimental backdrop settings.
  ///
  /// In en, this message translates to:
  /// **'Noon'**
  String get skyTimeNoon;

  /// County-border overlay toggle in the map's radar overlay menu.
  ///
  /// In en, this message translates to:
  /// **'Keeps county borders legible under the radar echo.'**
  String get radarCountyOutlineSubtitle;

  /// Himawari visible-red channel (B03, 0.64 µm) layer name
  ///
  /// In en, this message translates to:
  /// **'Himawari Red (B03)'**
  String get mapLayerSatelliteB03;

  /// Label for the felt-intensity range filter
  ///
  /// In en, this message translates to:
  /// **'Intensity'**
  String get reportFilterIntensity;

  /// Map layer switcher label for the lightning strike timeline
  ///
  /// In en, this message translates to:
  /// **'Lightning'**
  String get mapLayerLightning;

  /// Restroom type: male restroom
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get restroomTypeMale;

  /// Age of the last received packet
  ///
  /// In en, this message translates to:
  /// **'Last received'**
  String get meshtasticLastReceived;

  /// Tooltip on the area-intensity sort toggle when tapping it switches to an alphabetical county list
  ///
  /// In en, this message translates to:
  /// **'Sort by county'**
  String get reportDetailSortByCounty;

  /// Permission row: unused-app restrictions (Android)
  ///
  /// In en, this message translates to:
  /// **'Keep app active'**
  String get onboardingPermUnusedApp;

  /// Permission row description: unused-app restrictions
  ///
  /// In en, this message translates to:
  /// **'Android pauses apps you haven\'t opened in a while and revokes their permissions — which stops disaster alerts reaching your area.'**
  String get onboardingPermUnusedAppDesc;

  /// Permission row title: whether the OS lets the app run background work at all (Android 'Restricted' battery state / iOS Background App Refresh).
  ///
  /// In en, this message translates to:
  /// **'Background activity'**
  String get onboardingPermBackgroundExec;

  /// Permission row description for background activity.
  ///
  /// In en, this message translates to:
  /// **'Without this the app is never woken to report where you are.'**
  String get onboardingPermBackgroundExecDesc;

  /// Permission row title shown only on manufacturers that add their own battery manager (Samsung, Xiaomi, Huawei, OPPO, vivo...).
  ///
  /// In en, this message translates to:
  /// **'Manufacturer battery settings'**
  String get onboardingPermVendorPower;

  /// Permission row description for the manufacturer battery manager. {brand} is the device manufacturer name.
  ///
  /// In en, this message translates to:
  /// **'{brand} stops background work for apps you have not opened recently. The app cannot detect or change this — please allow it by hand.'**
  String onboardingPermVendorPowerDesc(String brand);

  /// Home rain trend subtitle: peak intensity below the light-rain threshold
  ///
  /// In en, this message translates to:
  /// **'Light showers possible'**
  String get homeRainTrendScattered;

  /// Time since the radio booted
  ///
  /// In en, this message translates to:
  /// **'Uptime'**
  String get meshtasticUptime;

  /// Ranking tab for recorded daily high/low/range (not current temp)
  ///
  /// In en, this message translates to:
  /// **'Daily extremes'**
  String get weatherRankingTempExtremes;

  /// Theme option: always light
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// Hint under the terrain-relief setting
  ///
  /// In en, this message translates to:
  /// **'Show shaded terrain relief on the base map'**
  String get mapTerrainReliefHint;

  /// Placeholder for a text packet with no body
  ///
  /// In en, this message translates to:
  /// **'(empty message)'**
  String get meshtasticEmptyMessage;

  /// Section header on the More page for saved regions
  ///
  /// In en, this message translates to:
  /// **'Region'**
  String get moreSectionRegion;

  /// Name of the Himawari infrared layer in the layer picker
  ///
  /// In en, this message translates to:
  /// **'Himawari Infrared (B13)'**
  String get mapLayerSatellite;

  /// AED Saturday opening hours row label
  ///
  /// In en, this message translates to:
  /// **'Saturday hours'**
  String get aedHoursSaturday;

  /// Phase: new moon
  ///
  /// In en, this message translates to:
  /// **'New moon'**
  String get moonPhaseNew;

  /// Notify page section header
  ///
  /// In en, this message translates to:
  /// **'Earthquake early warning'**
  String get notifySectionEew;

  /// Map compass tooltip: re-points the camera to north-up
  ///
  /// In en, this message translates to:
  /// **'Reset north'**
  String get mapResetNorth;

  /// No description provided for @rainInterval2d.
  ///
  /// In en, this message translates to:
  /// **'2 d'**
  String get rainInterval2d;

  /// Hint under the township-names setting
  ///
  /// In en, this message translates to:
  /// **'Show township names when zoomed in'**
  String get mapTownLabelsHint;

  /// Dismisses a dialog without acting
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// Notify option label
  ///
  /// In en, this message translates to:
  /// **'Tsunami warnings only'**
  String get notifyOptTsunamiWarning;

  /// Himawari night fog / low-cloud brightness-temperature-difference layer name
  ///
  /// In en, this message translates to:
  /// **'Himawari Night Fog'**
  String get mapLayerSatelliteBtdFog;

  /// Section header on the More page grouping advanced/developer entries
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get moreSectionAdvanced;

  /// More page section header: Meshtastic mesh network
  ///
  /// In en, this message translates to:
  /// **'Mesh network'**
  String get moreSectionMesh;

  /// Chip to rank by daily high minus low
  ///
  /// In en, this message translates to:
  /// **'Diurnal range'**
  String get weatherRankingExtremeRange;

  /// Title of the standalone permission checklist page
  ///
  /// In en, this message translates to:
  /// **'Permission check'**
  String get permissionsTitle;

  /// Screen-reader label for the permission warning dot
  ///
  /// In en, this message translates to:
  /// **'Permissions need attention'**
  String get permissionsAttention;

  /// Intro line on the permission checklist page
  ///
  /// In en, this message translates to:
  /// **'DPIP needs these permissions to alert you in time. A missing one is the usual reason an alert never arrived.'**
  String get permissionsBody;

  /// More-menu entry that opens the notification-settings page
  ///
  /// In en, this message translates to:
  /// **'Notification settings'**
  String get notifySettingsMenu;

  /// Choice-sheet label suffix marking the platform home map app, with the app name
  ///
  /// In en, this message translates to:
  /// **'{app} (default)'**
  String mapAppDefault(String app);

  /// Trend chart range toggle: last 24 hours
  ///
  /// In en, this message translates to:
  /// **'24h'**
  String get trendRange24h;

  /// Explains the JMA cloud-top enhancement band rendering
  ///
  /// In en, this message translates to:
  /// **'Grayscale base, tinted below −40 °C to highlight cloud-top height'**
  String get mapLayerStyleJmaTooltip;

  /// Map layer switcher label for the rainfall station layer
  ///
  /// In en, this message translates to:
  /// **'Rainfall'**
  String get mapLayerRain;

  /// Name of the QPESUMS next-1-hour precipitation forecast layer in the layer picker
  ///
  /// In en, this message translates to:
  /// **'1h Precipitation Forecast'**
  String get mapLayerQpesums;

  /// Section title in map overlay settings menus: base-map settings
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get mapOverlaySectionMap;

  /// Map setting: show the base map's hillshade relief
  ///
  /// In en, this message translates to:
  /// **'Terrain relief'**
  String get mapTerrainRelief;

  /// Tooltip on the control that collapses the map legend
  ///
  /// In en, this message translates to:
  /// **'Hide legend'**
  String get mapLegendCollapse;

  /// Title of the new-version dialog
  ///
  /// In en, this message translates to:
  /// **'Update available'**
  String get updateAvailableTitle;

  /// Body of the new-version dialog
  ///
  /// In en, this message translates to:
  /// **'Version {version} is out.'**
  String updateAvailableBody(String version);

  /// No description provided for @updateSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip this one'**
  String get updateSkip;

  /// No description provided for @updateViewChangelog.
  ///
  /// In en, this message translates to:
  /// **'View changes'**
  String get updateViewChangelog;

  /// No description provided for @updateOpenAppStore.
  ///
  /// In en, this message translates to:
  /// **'App Store'**
  String get updateOpenAppStore;

  /// No description provided for @updateOpenTestFlight.
  ///
  /// In en, this message translates to:
  /// **'TestFlight'**
  String get updateOpenTestFlight;

  /// No description provided for @updateOpenPlayStore.
  ///
  /// In en, this message translates to:
  /// **'Play Store'**
  String get updateOpenPlayStore;

  /// No description provided for @updateDownload.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get updateDownload;

  /// Changelog action that reveals pre-release snapshots
  ///
  /// In en, this message translates to:
  /// **'Show snapshots'**
  String get changelogShowSnapshots;

  /// More-menu entry and page title for GitHub release notes
  ///
  /// In en, this message translates to:
  /// **'Changelog'**
  String get changelogTitle;

  /// Sort order: newest / largest first
  ///
  /// In en, this message translates to:
  /// **'Descending'**
  String get reportFilterOrderDesc;

  /// What an MQTT node is
  ///
  /// In en, this message translates to:
  /// **'Nodes bridged over the internet, not heard by radio'**
  String get meshtasticExcludeMqttSubtitle;

  /// Title of the dialog explaining CWA 新制 vs 舊制 intensity
  ///
  /// In en, this message translates to:
  /// **'Intensity scales'**
  String get reportFilterIntensityInfoTitle;

  /// Layer-switcher label for the typhoon map layer
  ///
  /// In en, this message translates to:
  /// **'Typhoon'**
  String get mapLayerTyphoon;

  /// Tooltip for the radar overlay-options chip beside the layer switcher
  ///
  /// In en, this message translates to:
  /// **'Radar overlay options'**
  String get radarOverlayMenuTooltip;

  /// Mesh nodes section header
  ///
  /// In en, this message translates to:
  /// **'Nodes'**
  String get meshtasticNodes;

  /// Send message button
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get meshtasticSend;

  /// Tooltip for the L7 storm-band radio option
  ///
  /// In en, this message translates to:
  /// **'Level-7 wind field + average circle (purple)'**
  String get typhoonOverlayStormL7Tooltip;

  /// AED venue type row label
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get aedType;

  /// More-menu link title for the Terms of Service
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// Typhoon UI: typhoonLegendCircle25
  ///
  /// In en, this message translates to:
  /// **'Storm circle (L10)'**
  String get typhoonLegendCircle25;

  /// Support page title and the More-menu entry that opens it
  ///
  /// In en, this message translates to:
  /// **'Support DPIP'**
  String get sponsorTitle;

  /// Short Map-tab bottom-nav / default-layer picker label for satellite
  ///
  /// In en, this message translates to:
  /// **'Satellite'**
  String get mapNavSatellite;

  /// Data-update time beside the home rain trend title, Taipei wall clock HH:mm
  ///
  /// In en, this message translates to:
  /// **'Updated {time}'**
  String homeRainTrendUpdated(String time);

  /// Onboarding next-step button
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// Chip to keep one extreme station per township
  ///
  /// In en, this message translates to:
  /// **'Township'**
  String get weatherRankingMergeTown;

  /// Map layer switcher label for the real-time seismic monitor (RTS)
  ///
  /// In en, this message translates to:
  /// **'Seismic Monitor'**
  String get mapLayerMonitor;

  /// More-menu link to the ExpTech YouTube channel
  ///
  /// In en, this message translates to:
  /// **'YouTube'**
  String get moreYoutube;

  /// Support page section header for recurring subscription tiers
  ///
  /// In en, this message translates to:
  /// **'Subscriptions'**
  String get sponsorSubscriptions;

  /// No description provided for @typhoonValueLon.
  ///
  /// In en, this message translates to:
  /// **'{lon}°E'**
  String typhoonValueLon(String lon);

  /// Label for the experimental sky time-of-day override.
  ///
  /// In en, this message translates to:
  /// **'Sky time'**
  String get skyTime;

  /// Label for the weatherModeCloudy option in the experimental backdrop settings.
  ///
  /// In en, this message translates to:
  /// **'Cloudy'**
  String get weatherModeCloudy;

  /// Label for the skyTimeDusk option in the experimental backdrop settings.
  ///
  /// In en, this message translates to:
  /// **'Dusk'**
  String get skyTimeDusk;

  /// Firmware version
  ///
  /// In en, this message translates to:
  /// **'Firmware'**
  String get meshtasticFirmware;

  /// Explains that endTime covers through the end of that calendar day
  ///
  /// In en, this message translates to:
  /// **'End day: through 24:00 (Taipei)'**
  String get reportFilterDateEndNote;

  /// Sort reports by magnitude
  ///
  /// In en, this message translates to:
  /// **'Magnitude'**
  String get reportFilterSortMagnitude;

  /// Legend: node known but not heard recently
  ///
  /// In en, this message translates to:
  /// **'Silent'**
  String get meshtasticSilent;

  /// Section title in map overlay lists: the seismic-monitor overlays
  ///
  /// In en, this message translates to:
  /// **'Earthquake'**
  String get mapLayerCategoryEarthquake;

  /// Himawari ozone-band channel (B12, 9.6 µm) layer name
  ///
  /// In en, this message translates to:
  /// **'Himawari Ozone (B12)'**
  String get mapLayerSatelliteB12;

  /// Restroom venue category: other
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get restroomCategoryOther;

  /// 24h forecast series high and low air temperatures
  ///
  /// In en, this message translates to:
  /// **'H {high}° · L {low}°'**
  String homeForecastHighLow(String high, String low);

  /// Action on the location banner to open system settings
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get locationBannerFix;

  /// Collapsed map-legend chip label / tooltip — tap to expand
  ///
  /// In en, this message translates to:
  /// **'Legend'**
  String get mapLegendExpand;

  /// Calm state of the earthquake monitor when the live feed reports no alert
  ///
  /// In en, this message translates to:
  /// **'No active earthquake early warning'**
  String get eewNone;

  /// Secondary badge on the typhoon sheet hero: the CWA typhoon serial number, e.g. TY 4
  ///
  /// In en, this message translates to:
  /// **'TY {no}'**
  String typhoonTyNo(String no);

  /// Notify option label
  ///
  /// In en, this message translates to:
  /// **'Tsunami advisories and warnings'**
  String get notifyOptTsunamiAll;

  /// Tooltip for the mesh layer's options chip
  ///
  /// In en, this message translates to:
  /// **'Node options'**
  String get meshtasticLayerOptions;

  /// Terms page continue button
  ///
  /// In en, this message translates to:
  /// **'Agree and continue'**
  String get onboardingAgreeContinue;

  /// Button that re-runs a failed request
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// The radio's node number
  ///
  /// In en, this message translates to:
  /// **'Node ID'**
  String get meshtasticNodeId;

  /// Eyebrow label on the detail header for a numbered CWA report
  ///
  /// In en, this message translates to:
  /// **'No. {number} Significant Earthquake'**
  String reportDetailNumbered(String number);

  /// Subtitle under each storm-band option (fill + dashed avg)
  ///
  /// In en, this message translates to:
  /// **'With average circle'**
  String get typhoonOverlayStormBandSubtitle;

  /// Tooltip for the restroom toggle in the disaster-map overlay menu
  ///
  /// In en, this message translates to:
  /// **'Show public restrooms'**
  String get disasterMapOverlayRestroomTooltip;

  /// App bar title for the weather station ranking page
  ///
  /// In en, this message translates to:
  /// **'Observation rankings'**
  String get weatherRankingTitle;

  /// Home rain trend subtitle: heavy rain that keeps up through the hour
  ///
  /// In en, this message translates to:
  /// **'Heavy rain continuing for the next hour'**
  String get homeRainTrendHeavySustained;

  /// Notify page section header
  ///
  /// In en, this message translates to:
  /// **'Tsunami'**
  String get notifySectionTsunami;

  /// Restroom venue category: park
  ///
  /// In en, this message translates to:
  /// **'Park'**
  String get restroomCategoryPark;

  /// Snackbar shown when an external link fails to open in the browser
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the link'**
  String get moreLinkOpenFailed;

  /// Theme option: always dark
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// Footer action that restores previously bought purchases
  ///
  /// In en, this message translates to:
  /// **'Restore purchases'**
  String get sponsorRestore;

  /// Creating/verifying the DPIP channel
  ///
  /// In en, this message translates to:
  /// **'Setting up the DPIP channel…'**
  String get meshtasticChannelWorking;

  /// Button applying the DPIP LoRa region
  ///
  /// In en, this message translates to:
  /// **'Switch to TW'**
  String get meshtasticRegionSwitch;

  /// Section: packet counters
  ///
  /// In en, this message translates to:
  /// **'Traffic'**
  String get meshtasticTraffic;

  /// Explains the Dvorak BD band rendering
  ///
  /// In en, this message translates to:
  /// **'Dvorak BD curve — the stepped grayscale for tropical-cyclone intensity analysis'**
  String get mapLayerStyleBdTooltip;

  /// Tooltip for the AED toggle in the disaster-map overlay menu
  ///
  /// In en, this message translates to:
  /// **'Show AED locations'**
  String get disasterMapOverlayAedTooltip;

  /// Map layer switcher label for the humidity layer
  ///
  /// In en, this message translates to:
  /// **'Humidity'**
  String get mapLayerHumidity;

  /// Satellite legend note: the daytime RGB recipes fade out across the terminator and are transparent at night
  ///
  /// In en, this message translates to:
  /// **'Night = transparent, the basemap shows'**
  String get mapLayerSatelliteTransparentNight;

  /// Scan in progress
  ///
  /// In en, this message translates to:
  /// **'Scanning…'**
  String get meshtasticScanning;

  /// Snackbar shown when trying to add a region beyond the cap
  ///
  /// In en, this message translates to:
  /// **'You can save up to {max} regions'**
  String regionSelectFull(int max);

  /// Pill on the red unread divider in the mesh chat log
  ///
  /// In en, this message translates to:
  /// **'NEW'**
  String get meshtasticNewMessages;

  /// Section header over the radio's 24h battery chart
  ///
  /// In en, this message translates to:
  /// **'Battery history'**
  String get meshtasticBatteryHistory;

  /// Mesh chart label
  ///
  /// In en, this message translates to:
  /// **'avg'**
  String get meshtasticStatAvg;

  /// Mesh chart label
  ///
  /// In en, this message translates to:
  /// **'peak'**
  String get meshtasticStatPeak;

  /// Mesh chart label
  ///
  /// In en, this message translates to:
  /// **'drain'**
  String get meshtasticStatDrain;

  /// Mesh chart label
  ///
  /// In en, this message translates to:
  /// **'lasts'**
  String get meshtasticStatEta;

  /// Estimated time until the pack is full
  ///
  /// In en, this message translates to:
  /// **'full in'**
  String get meshtasticStatFull;

  /// Mesh chart label
  ///
  /// In en, this message translates to:
  /// **'trend'**
  String get meshtasticStatTrend;

  /// Mesh chart label
  ///
  /// In en, this message translates to:
  /// **'charging'**
  String get meshtasticStatCharging;

  /// Mesh chart label
  ///
  /// In en, this message translates to:
  /// **'stable'**
  String get meshtasticStatStable;

  /// Mesh chart label
  ///
  /// In en, this message translates to:
  /// **'Known'**
  String get meshtasticNodesTotal;

  /// Mesh chart label
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get meshtasticNodesOnline;

  /// Mesh chart label
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get meshtasticRx;

  /// Mesh chart label
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get meshtasticTx;

  /// Mesh chart label
  ///
  /// In en, this message translates to:
  /// **'Node history'**
  String get meshtasticNodesHistory;

  /// Mesh chart label
  ///
  /// In en, this message translates to:
  /// **'Traffic history'**
  String get meshtasticTrafficHistory;

  /// Battery time-left estimate
  ///
  /// In en, this message translates to:
  /// **'~{n}h'**
  String meshtasticEtaHours(int n);

  /// Battery time-left estimate
  ///
  /// In en, this message translates to:
  /// **'~{n}d'**
  String meshtasticEtaDays(int n);

  /// Meshtastic test page title
  ///
  /// In en, this message translates to:
  /// **'Meshtastic'**
  String get meshtasticTitle;

  /// Bottom-nav label and page title for the More tab
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get navMore;

  /// Which channel DPIP payloads use
  ///
  /// In en, this message translates to:
  /// **'DPIP channel'**
  String get meshtasticDpipChannel;

  /// Section header for DPM sub-layer toggles in the overlay menu
  ///
  /// In en, this message translates to:
  /// **'Layers'**
  String get disasterMapOverlaySectionLayers;

  /// Himawari near-infrared channel (B05, 1.6 µm) layer name
  ///
  /// In en, this message translates to:
  /// **'Himawari Near-Infrared (B05)'**
  String get mapLayerSatelliteB05;

  /// No description provided for @typhoonLabelNe.
  ///
  /// In en, this message translates to:
  /// **'NE'**
  String get typhoonLabelNe;

  /// Toast shown after copying a message
  ///
  /// In en, this message translates to:
  /// **'Message copied'**
  String get meshtasticCopied;

  /// Empty state when the report catalogue has no rows
  ///
  /// In en, this message translates to:
  /// **'No earthquake reports'**
  String get reportListEmpty;

  /// Footer when the report catalogue has no further pages
  ///
  /// In en, this message translates to:
  /// **'End of list'**
  String get reportListEnd;

  /// Himawari True Color RGB composite layer name
  ///
  /// In en, this message translates to:
  /// **'Himawari True Color'**
  String get mapLayerSatelliteTruecolor;

  /// Section header for optional typhoon overlays (probability, warning)
  ///
  /// In en, this message translates to:
  /// **'Overlays'**
  String get typhoonOverlaySectionExtra;

  /// Label for the S-wave arrival countdown tile
  ///
  /// In en, this message translates to:
  /// **'S-wave'**
  String get eewSWave;

  /// Another app holds the BLE link
  ///
  /// In en, this message translates to:
  /// **'Another app is using this radio'**
  String get meshtasticBusyTitle;

  /// Restroom venue category: cultural / leisure activity venue
  ///
  /// In en, this message translates to:
  /// **'Cultural'**
  String get restroomCategoryCultural;

  /// Bulletin table row label
  ///
  /// In en, this message translates to:
  /// **'Max. sustained wind near centre'**
  String get typhoonLabelWind;

  /// Hint under the national-border toggle in the radar overlay menu.
  ///
  /// In en, this message translates to:
  /// **'Every country\'s outer frame'**
  String get radarGlobalOutlineHint;

  /// Notify channel title
  ///
  /// In en, this message translates to:
  /// **'Disaster information'**
  String get notifyEvacuation;

  /// Typhoon UI: typhoonLegendCircle15
  ///
  /// In en, this message translates to:
  /// **'Gale circle (L7)'**
  String get typhoonLegendCircle15;

  /// Astronomy section header in the data catalogue
  ///
  /// In en, this message translates to:
  /// **'Astronomy'**
  String get dataSectionAstronomy;

  /// Home rain trend subtitle: light rain that keeps up through the hour
  ///
  /// In en, this message translates to:
  /// **'Light rain continuing for the next hour'**
  String get homeRainTrendLightSustained;

  /// Generic headline when an async request fails
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get commonError;

  /// Phase: waning crescent
  ///
  /// In en, this message translates to:
  /// **'Waning crescent'**
  String get moonPhaseWaningCrescent;

  /// Section: battery and uptime
  ///
  /// In en, this message translates to:
  /// **'Power'**
  String get meshtasticPower;

  /// Label on the map timeline when the newest (latest) frame is selected
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get mapTimelineNow;

  /// Displays a selected filter range (intensity, magnitude, depth, or dates)
  ///
  /// In en, this message translates to:
  /// **'{start} – {end}'**
  String reportFilterRange(String start, String end);

  /// Button that opens the official CWA report page in a browser
  ///
  /// In en, this message translates to:
  /// **'Report page'**
  String get reportDetailOpenReport;

  /// Trend chart range toggle: last 7 days
  ///
  /// In en, this message translates to:
  /// **'7d'**
  String get trendRange7d;

  /// List of counties under a typhoon warning
  ///
  /// In en, this message translates to:
  /// **'Areas: {areas}'**
  String typhoonWarningAreas(String areas);

  /// Section title in the rainfall menu: the accumulation-interval choices
  ///
  /// In en, this message translates to:
  /// **'Time window'**
  String get rainIntervalSection;

  /// Title of the notification-settings page
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifyTitle;

  /// Transmit power
  ///
  /// In en, this message translates to:
  /// **'TX power'**
  String get meshtasticTxPower;

  /// Restroom detail row label for the venue category
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get restroomCategoryLabel;

  /// Snackbar shown when a purchase restore has been requested
  ///
  /// In en, this message translates to:
  /// **'Restoring purchases…'**
  String get sponsorRestoring;

  /// Support page intro paragraph explaining why donations help
  ///
  /// In en, this message translates to:
  /// **'DPIP is dedicated to real-time disaster-prevention information, with no ads or other revenue model. Your support helps us keep the servers running and keep developing.'**
  String get sponsorIntro;

  /// Bulletin table row label
  ///
  /// In en, this message translates to:
  /// **'Avg. radius of Beaufort 10 winds'**
  String get typhoonLabelStormAvg;

  /// Restroom venue category: commercial establishment
  ///
  /// In en, this message translates to:
  /// **'Commercial'**
  String get restroomCategoryCommercial;

  /// AED city / district row label
  ///
  /// In en, this message translates to:
  /// **'Region'**
  String get aedRegion;

  /// Home rain trend subtitle: light rain forecast to stop partway through the hour
  ///
  /// In en, this message translates to:
  /// **'Light rain likely to stop in {minutes} minutes'**
  String homeRainTrendLightStopping(int minutes);

  /// Section header over origin time / epicenter / magnitude / depth
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get reportDetailInfo;

  /// Short Map-tab bottom-nav / default-layer picker label for wind
  ///
  /// In en, this message translates to:
  /// **'Wind'**
  String get mapNavWind;

  /// Tooltip for the wind-forecast overlay-options chip beside the layer switcher.
  ///
  /// In en, this message translates to:
  /// **'Wind forecast overlay options'**
  String get windForecastOverlayMenuTooltip;

  /// X-axis tick label on the home rain trend chart, minutes from now
  ///
  /// In en, this message translates to:
  /// **'{minute} min'**
  String homeRainTrendMinute(int minute);

  /// No description provided for @rainInterval6h.
  ///
  /// In en, this message translates to:
  /// **'6 h'**
  String get rainInterval6h;

  /// Restroom type: not specified
  ///
  /// In en, this message translates to:
  /// **'Unspecified'**
  String get restroomTypeUnspecified;

  /// Short hint under the strike-probability toggle
  ///
  /// In en, this message translates to:
  /// **'Hides the forecast cone'**
  String get typhoonOverlayProbabilityHint;

  /// Satellite legend row: the country/global border, drawn bright yellow over the imagery
  ///
  /// In en, this message translates to:
  /// **'Country border'**
  String get mapLayerSatelliteGlobalOutline;

  /// Short Map-tab bottom-nav / default-layer picker label for temperature
  ///
  /// In en, this message translates to:
  /// **'Temperature'**
  String get mapNavTemperature;

  /// Typhoon map legend: forecast waypoint
  ///
  /// In en, this message translates to:
  /// **'Forecast point'**
  String get typhoonLegendForecastPoint;

  /// Date section header for reports that originated yesterday (Taipei)
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get reportListYesterday;

  /// Section header on the More page grouping external website links
  ///
  /// In en, this message translates to:
  /// **'Links'**
  String get moreSectionLinks;

  /// Banner/headline when a realtime feed has gone offline
  ///
  /// In en, this message translates to:
  /// **'Connection lost'**
  String get feedOffline;

  /// Colour-style option: Dvorak BD curve stepped grayscale
  ///
  /// In en, this message translates to:
  /// **'Dvorak BD'**
  String get mapLayerStyleBd;

  /// Section header on the More page for language and theme
  ///
  /// In en, this message translates to:
  /// **'Display'**
  String get moreSectionDisplay;

  /// No description provided for @rainInterval3d.
  ///
  /// In en, this message translates to:
  /// **'3 d'**
  String get rainInterval3d;

  /// Explanatory subtitle on the default-map-layer settings page
  ///
  /// In en, this message translates to:
  /// **'The Map tab opens on this overlay. The bottom-navigation icon and label follow this choice.'**
  String get defaultMapLayerSubtitle;

  /// AED free-text description row label
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get aedDescription;

  /// Tooltip for radar underlay (mutex with IR)
  ///
  /// In en, this message translates to:
  /// **'Radar echo closest to the typhoon bulletin time'**
  String get typhoonOverlayWeatherRadarTooltip;

  /// Permission row description: location
  ///
  /// In en, this message translates to:
  /// **'Target alerts to where you are.'**
  String get onboardingPermLocationDesc;

  /// Himawari CO₂-band channel (B16, 13.3 µm) layer name
  ///
  /// In en, this message translates to:
  /// **'Himawari CO₂ (B16)'**
  String get mapLayerSatelliteB16;

  /// Empty state when the realtime event feed has nothing in effect
  ///
  /// In en, this message translates to:
  /// **'No active events'**
  String get homeActiveEventsEmpty;

  /// Bulletin table row label
  ///
  /// In en, this message translates to:
  /// **'Centre location'**
  String get typhoonLabelPosition;

  /// Label before highest/lowest (or desc/asc) chips on ranking
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get weatherRankingBy;

  /// CWA class: mild typhoon (past-track colour)
  ///
  /// In en, this message translates to:
  /// **'Mild typhoon'**
  String get typhoonIntensityMild;

  /// Hint under the national-border toggle in the wind-forecast overlay menu.
  ///
  /// In en, this message translates to:
  /// **'Every country\'s outer frame'**
  String get windForecastGlobalOutlineHint;

  /// No description provided for @rainInterval1h.
  ///
  /// In en, this message translates to:
  /// **'1 h'**
  String get rainInterval1h;

  /// Label for the estimated felt intensity at the user's location
  ///
  /// In en, this message translates to:
  /// **'Estimated at my location'**
  String get eewLocalIntensity;

  /// Name of the composite radar reflectivity layer in the layer picker
  ///
  /// In en, this message translates to:
  /// **'Composite Radar Reflectivity'**
  String get mapLayerRadar;

  /// Restroom venue category: religious / ceremonial venue
  ///
  /// In en, this message translates to:
  /// **'Religious'**
  String get restroomCategoryReligious;

  /// Device role (client, router...)
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get meshtasticRole;

  /// Cloud-mask category: cloudy
  ///
  /// In en, this message translates to:
  /// **'Cloudy'**
  String get mapLayerSatelliteCloudCloudy;

  /// Label for the skyTimeSunrise option in the experimental backdrop settings.
  ///
  /// In en, this message translates to:
  /// **'Sunrise'**
  String get skyTimeSunrise;

  /// Chat button that scrolls back to the newest message
  ///
  /// In en, this message translates to:
  /// **'Jump to latest'**
  String get meshtasticJumpToLatest;

  /// Empty message log while connected
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get meshtasticNoMessages;

  /// Permission row description: notifications
  ///
  /// In en, this message translates to:
  /// **'Deliver earthquake, weather, and disaster alerts the moment they happen.'**
  String get onboardingPermNotifyDesc;

  /// Township-border overlay toggle in the map's radar overlay menu.
  ///
  /// In en, this message translates to:
  /// **'Township borders'**
  String get radarTownOutline;

  /// Section header of the satellite band colour-style menu on the map
  ///
  /// In en, this message translates to:
  /// **'Colour style'**
  String get mapLayerStyleSection;

  /// Tooltip on the disaster-map overlay tune button
  ///
  /// In en, this message translates to:
  /// **'Disaster map layers'**
  String get disasterMapOverlayMenuTooltip;

  /// Google Play store link title (brand name)
  ///
  /// In en, this message translates to:
  /// **'Google Play'**
  String get moreGooglePlay;

  /// Legend: node heard within the online window
  ///
  /// In en, this message translates to:
  /// **'Heard recently'**
  String get meshtasticOnline;

  /// No description provided for @typhoonLabelSw.
  ///
  /// In en, this message translates to:
  /// **'SW'**
  String get typhoonLabelSw;

  /// Forecast lead time for a tapped track point
  ///
  /// In en, this message translates to:
  /// **'Forecast +{hours} h'**
  String typhoonForecastLead(String hours);

  /// Chip label for a stable release
  ///
  /// In en, this message translates to:
  /// **'Stable'**
  String get changelogTypeStable;

  /// Satellite legend note: the cloud-mask clear category is transparent so the basemap shows
  ///
  /// In en, this message translates to:
  /// **'Clear sky = transparent, the basemap shows'**
  String get mapLayerSatelliteTransparentClear;

  /// Section title in map overlay settings menus: the reference overlays
  ///
  /// In en, this message translates to:
  /// **'Reference layers'**
  String get mapOverlaySectionReference;

  /// Himawari visible-green channel (B02, 0.51 µm) layer name
  ///
  /// In en, this message translates to:
  /// **'Himawari Green (B02)'**
  String get mapLayerSatelliteB02;

  /// Empty state when a ranking list has no rows after filters
  ///
  /// In en, this message translates to:
  /// **'No observations to rank'**
  String get weatherRankingEmpty;

  /// Notify page section header
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get notifySectionOther;

  /// Snapshot time and station count above a ranking list
  ///
  /// In en, this message translates to:
  /// **'Data time: {time}\n{count} stations'**
  String weatherRankingMeta(String time, int count);

  /// Terms agreement checkbox label
  ///
  /// In en, this message translates to:
  /// **'I have read and agree to the Terms of Service'**
  String get onboardingTermsAgree;

  /// Satellite legend note: NDVI below the bare-soil threshold is transparent
  ///
  /// In en, this message translates to:
  /// **'Below 0.1 = transparent (no vegetation)'**
  String get mapLayerSatelliteTransparentNoVegetation;

  /// Notify option label
  ///
  /// In en, this message translates to:
  /// **'Local intensity 4 or above'**
  String get notifyOptLocalIntensity4;

  /// S-wave arrival countdown state once the wave has arrived
  ///
  /// In en, this message translates to:
  /// **'Arrived'**
  String get eewArrived;

  /// Empty scan result
  ///
  /// In en, this message translates to:
  /// **'No Meshtastic devices found'**
  String get meshtasticNoDevices;

  /// Section title in map overlay lists: everyday-life facility overlays
  ///
  /// In en, this message translates to:
  /// **'Daily life'**
  String get mapLayerCategoryLife;

  /// Sort reports by max intensity
  ///
  /// In en, this message translates to:
  /// **'Intensity'**
  String get reportFilterSortIntensity;

  /// Connection state label
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get meshtasticStateDisconnected;

  /// CWA class: intense typhoon (past-track colour)
  ///
  /// In en, this message translates to:
  /// **'Intense typhoon'**
  String get typhoonIntensityIntense;

  /// Title of the layer-order editor, also the tooltip of the reorder button in the layer picker
  ///
  /// In en, this message translates to:
  /// **'Reorder layers'**
  String get mapLayerOrderTitle;

  /// No description provided for @mapLayerShow.
  ///
  /// In en, this message translates to:
  /// **'Show layer'**
  String get mapLayerShow;

  /// No description provided for @mapLayerHide.
  ///
  /// In en, this message translates to:
  /// **'Hide layer'**
  String get mapLayerHide;

  /// No description provided for @mapLayerShowAll.
  ///
  /// In en, this message translates to:
  /// **'Show all'**
  String get mapLayerShowAll;

  /// No description provided for @mapLayerHideAll.
  ///
  /// In en, this message translates to:
  /// **'Hide all'**
  String get mapLayerHideAll;

  /// Affirmative value in the disaster-map detail sheet
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get dpmYes;

  /// Chart placeholder before two samples exist
  ///
  /// In en, this message translates to:
  /// **'Not enough history yet'**
  String get meshtasticNoHistory;

  /// Shown in place of an intensity badge when a location's county isn't in this report's felt-area list at all
  ///
  /// In en, this message translates to:
  /// **'No intensity data'**
  String get reportDetailLocalIntensityUnavailable;

  /// Map layer switcher label for the GFS wind-forecast layer
  ///
  /// In en, this message translates to:
  /// **'GFS'**
  String get mapLayerWindForecastGfs;

  /// Label for the hypocentral-depth range filter
  ///
  /// In en, this message translates to:
  /// **'Depth'**
  String get reportFilterDepth;

  /// Hint shown until the user scrolls to the end
  ///
  /// In en, this message translates to:
  /// **'Scroll down to continue'**
  String get onboardingScrollHint;

  /// Short Map-tab bottom-nav / default-layer picker label for the 1h QPESUMS precipitation forecast
  ///
  /// In en, this message translates to:
  /// **'Forecast'**
  String get mapNavQpesums;

  /// Notify channel title
  ///
  /// In en, this message translates to:
  /// **'Weather advisories'**
  String get notifyAdvisory;

  /// Clears all filters in the report filter sheet
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reportFilterReset;

  /// Himawari modified normalised-difference water-index layer name
  ///
  /// In en, this message translates to:
  /// **'Himawari MNDWI'**
  String get mapLayerSatelliteMndwi;

  /// Section header for L7/L10 storm-band choices in the overlay menu
  ///
  /// In en, this message translates to:
  /// **'Storm wind'**
  String get typhoonOverlaySectionStorm;

  /// Phase: full moon
  ///
  /// In en, this message translates to:
  /// **'Full moon'**
  String get moonPhaseFull;

  /// Label above a chat message whose body was not text and is shown as a hex dump. {size} is a formatted byte count, e.g. "24 B".
  ///
  /// In en, this message translates to:
  /// **'Binary payload · {size}'**
  String meshtasticBinaryPayload(String size);

  /// Phase: waning gibbous
  ///
  /// In en, this message translates to:
  /// **'Waning gibbous'**
  String get moonPhaseWaningGibbous;

  /// No description provided for @reportFilterIntensityInfoModernTitle.
  ///
  /// In en, this message translates to:
  /// **'Current (from 2020)'**
  String get reportFilterIntensityInfoModernTitle;

  /// Bulletin data time under the intensity chip (Taipei wall clock)
  ///
  /// In en, this message translates to:
  /// **'Data time\n{time}'**
  String typhoonDataTime(String time);

  /// Restroom type: accessible restroom
  ///
  /// In en, this message translates to:
  /// **'Accessible'**
  String get restroomTypeAccessible;

  /// More-menu section header for about / legal links
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get moreSectionAbout;

  /// Device picker sheet title
  ///
  /// In en, this message translates to:
  /// **'Select a radio'**
  String get meshtasticSelectDevice;

  /// Onboarding intro page body
  ///
  /// In en, this message translates to:
  /// **'DPIP is your disaster-prevention companion. It brings together earthquake early warnings, earthquake reports, weather, and hazard information, and alerts you the moment it matters.\n\n• Earthquakes: early warnings, intensity reports, and detailed reports\n• Weather: real-time thunderstorm messages and weather advisories\n• Tsunami and disaster information\n\nNext, we\'ll ask you to review the Terms of Service and grant a few permissions so DPIP can protect you in real time.'**
  String get onboardingIntroBody;

  /// Shelter detail capacity row label
  ///
  /// In en, this message translates to:
  /// **'Capacity'**
  String get shelterCapacityLabel;

  /// Section header over the CWA-rendered report image
  ///
  /// In en, this message translates to:
  /// **'Report image'**
  String get reportDetailImage;

  /// Connection state label
  ///
  /// In en, this message translates to:
  /// **'Configuring…'**
  String get meshtasticStateConfiguring;

  /// Bulletin table row label
  ///
  /// In en, this message translates to:
  /// **'Avg. radius of Beaufort 7 winds'**
  String get typhoonLabelGaleAvg;

  /// Permission row: notifications
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get onboardingPermNotify;

  /// Menu action clearing the message log
  ///
  /// In en, this message translates to:
  /// **'Clear messages'**
  String get meshtasticClearMessages;

  /// Toggle: local notification for an incoming mesh message
  ///
  /// In en, this message translates to:
  /// **'Notify on new messages'**
  String get meshtasticNotifyMessages;

  /// More-menu entry and page title for choosing the Map tab's default overlay
  ///
  /// In en, this message translates to:
  /// **'Default map layer'**
  String get defaultMapLayerSettings;

  /// No description provided for @eewSourceSettings.
  ///
  /// In en, this message translates to:
  /// **'EEW source'**
  String get eewSourceSettings;

  /// No description provided for @eewSourceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose which agencies\' earthquake early warnings the app shows.'**
  String get eewSourceSubtitle;

  /// No description provided for @eewSourceAll.
  ///
  /// In en, this message translates to:
  /// **'All sources'**
  String get eewSourceAll;

  /// No description provided for @eewSourceAllDescription.
  ///
  /// In en, this message translates to:
  /// **'Show earthquake early warnings from every publishing agency.'**
  String get eewSourceAllDescription;

  /// No description provided for @eewSourceCwaOnly.
  ///
  /// In en, this message translates to:
  /// **'CWA only'**
  String get eewSourceCwaOnly;

  /// No description provided for @eewSourceCwaOnlyDescription.
  ///
  /// In en, this message translates to:
  /// **'Show only earthquake early warnings published by Taiwan\'s Central Weather Administration (CWA).'**
  String get eewSourceCwaOnlyDescription;

  /// Section header on the More page for notification settings
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get moreSectionNotify;

  /// Shown on the notify page when there is no push token yet
  ///
  /// In en, this message translates to:
  /// **'Push notifications aren\'t ready yet — try again shortly.'**
  String get notifyUnavailable;

  /// Button that restores the layer picker's default order
  ///
  /// In en, this message translates to:
  /// **'Reset order'**
  String get mapLayerOrderReset;

  /// Chip to keep one extreme station per county
  ///
  /// In en, this message translates to:
  /// **'County'**
  String get weatherRankingMergeCounty;

  /// More-page section header for the app-store download links
  ///
  /// In en, this message translates to:
  /// **'Get the app'**
  String get moreSectionApp;

  /// No description provided for @moreSectionBeta.
  ///
  /// In en, this message translates to:
  /// **'Beta'**
  String get moreSectionBeta;

  /// No description provided for @moreAndroidBeta.
  ///
  /// In en, this message translates to:
  /// **'Android beta'**
  String get moreAndroidBeta;

  /// No description provided for @moreTestFlight.
  ///
  /// In en, this message translates to:
  /// **'iOS beta (TestFlight)'**
  String get moreTestFlight;

  /// No description provided for @moreSectionPartners.
  ///
  /// In en, this message translates to:
  /// **'Partners'**
  String get moreSectionPartners;

  /// No description provided for @morePartnersNote.
  ///
  /// In en, this message translates to:
  /// **'Listed in order of partnership. Thank you to the individuals and companies whose contributions to disaster preparedness made DPIP possible.'**
  String get morePartnersNote;

  /// No description provided for @morePartnerGeoscience.
  ///
  /// In en, this message translates to:
  /// **'Geoscience'**
  String get morePartnerGeoscience;

  /// No description provided for @morePartnerTwds.
  ///
  /// In en, this message translates to:
  /// **'TWDS'**
  String get morePartnerTwds;

  /// No description provided for @reportFilterIntensityInfoLegacyBody.
  ///
  /// In en, this message translates to:
  /// **'Only levels 0–7. No 5− / 5+ / 6− / 6+ split.'**
  String get reportFilterIntensityInfoLegacyBody;

  /// Himawari sea-surface-temperature (ACSPO L3C) layer name
  ///
  /// In en, this message translates to:
  /// **'Himawari Sea Surface Temperature'**
  String get mapLayerSatelliteSst;

  /// Tooltip for the QPESUMS forecast overlay-options chip beside the layer switcher.
  ///
  /// In en, this message translates to:
  /// **'QPESUMS overlay options'**
  String get qpesumsOverlayMenuTooltip;

  /// Label on the map timeline when the selected frame postdates the present
  ///
  /// In en, this message translates to:
  /// **'Future'**
  String get mapTimelineFuture;

  /// Legend for the purple dashed mean-radius storm circle
  ///
  /// In en, this message translates to:
  /// **'Average circle'**
  String get typhoonLegendCircleAvg;

  /// Depth value with unit in the filter sheet
  ///
  /// In en, this message translates to:
  /// **'{depth} km'**
  String reportFilterDepthKm(String depth);

  /// No description provided for @typhoonLabelSe.
  ///
  /// In en, this message translates to:
  /// **'SE'**
  String get typhoonLabelSe;

  /// Hint under the township-border toggle in the radar overlay menu.
  ///
  /// In en, this message translates to:
  /// **'The finer mesh'**
  String get radarTownOutlineHint;

  /// S-wave arrival countdown in seconds
  ///
  /// In en, this message translates to:
  /// **'{seconds} s'**
  String eewCountdown(int seconds);

  /// Bulletin table row label
  ///
  /// In en, this message translates to:
  /// **'Peak gust'**
  String get typhoonLabelGust;

  /// External map app choice: Google Maps
  ///
  /// In en, this message translates to:
  /// **'Google Maps'**
  String get mapAppGoogleMaps;

  /// Footer link to the Terms of Use
  ///
  /// In en, this message translates to:
  /// **'Terms of Use'**
  String get sponsorTerms;

  /// Restroom type: gender-neutral restroom
  ///
  /// In en, this message translates to:
  /// **'Gender-neutral'**
  String get restroomTypeGenderNeutral;

  /// Notify channel title
  ///
  /// In en, this message translates to:
  /// **'Thunderstorm alerts'**
  String get notifyThunderstorm;

  /// Label for the skyTimeGolden option in the experimental backdrop settings.
  ///
  /// In en, this message translates to:
  /// **'Golden hour'**
  String get skyTimeGolden;

  /// Moon age label
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get moonAge;

  /// Section: LoRa settings
  ///
  /// In en, this message translates to:
  /// **'LoRa'**
  String get meshtasticRadioSettings;

  /// More-menu link to the ExpTech GitHub organisation
  ///
  /// In en, this message translates to:
  /// **'ExpTech GitHub'**
  String get moreGithub;

  /// Shown when no township code is available for the forecast API
  ///
  /// In en, this message translates to:
  /// **'Select a township to see the forecast'**
  String get homeForecastUnavailable;

  /// Title of the map layer-picker sheet
  ///
  /// In en, this message translates to:
  /// **'Layers'**
  String get mapLayers;

  /// Board model
  ///
  /// In en, this message translates to:
  /// **'Hardware'**
  String get meshtasticHardware;

  /// Label next to the language picker on the welcome screen
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageSettings;

  /// Language picker tooltip / label
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Apparent temperature for the selected forecast hour
  ///
  /// In en, this message translates to:
  /// **'Feels like {temp}°'**
  String homeForecastFeelsLike(String temp);

  /// Subtitle: weather tile matches typhoon report time
  ///
  /// In en, this message translates to:
  /// **'Aligned to bulletin time'**
  String get typhoonOverlayWeatherHint;

  /// Label for the skyTimeDawn option in the experimental backdrop settings.
  ///
  /// In en, this message translates to:
  /// **'Dawn'**
  String get skyTimeDawn;

  /// Label for the skyTimeAfternoon option in the experimental backdrop settings.
  ///
  /// In en, this message translates to:
  /// **'Afternoon'**
  String get skyTimeAfternoon;

  /// When a node last transmitted
  ///
  /// In en, this message translates to:
  /// **'Last heard'**
  String get meshtasticLastHeard;

  /// Typhoon UI: typhoonWarningTitle
  ///
  /// In en, this message translates to:
  /// **'Typhoon warning'**
  String get typhoonWarningTitle;

  /// More-menu link to DPIP's source repository on GitHub
  ///
  /// In en, this message translates to:
  /// **'Source code'**
  String get moreSourceCode;

  /// Section title in map overlay lists: the weather-observation overlays
  ///
  /// In en, this message translates to:
  /// **'Weather observations'**
  String get mapLayerCategoryWeather;

  /// Himawari mid-level water-vapour channel (B09, 6.9 µm) layer name
  ///
  /// In en, this message translates to:
  /// **'Himawari Mid Water Vapour (B09)'**
  String get mapLayerSatelliteB09;

  /// Hint under the township-border toggle in the wind-forecast overlay menu.
  ///
  /// In en, this message translates to:
  /// **'The finer mesh'**
  String get windForecastTownOutlineHint;

  /// Himawari cloud-mask (Level-2 retrieval) layer name
  ///
  /// In en, this message translates to:
  /// **'Himawari Cloud Mask'**
  String get mapLayerSatelliteCloudmask;

  /// Choice-sheet action: copy the point's coordinates
  ///
  /// In en, this message translates to:
  /// **'Copy coordinates'**
  String get mapAppCopyCoordinates;

  /// Intro paragraph for the intensity-scale info dialog
  ///
  /// In en, this message translates to:
  /// **'CWA changed the felt-intensity scale on 1 Jan 2020 (Taipei time).'**
  String get reportFilterIntensityInfoIntro;

  /// Short Map-tab bottom-nav / default-layer picker label for RTS seismic monitor
  ///
  /// In en, this message translates to:
  /// **'Earthquake'**
  String get mapNavEarthquake;

  /// Restroom cleanliness grade: average
  ///
  /// In en, this message translates to:
  /// **'Average'**
  String get restroomGradeAverage;

  /// Himawari cirrus / cloud-height brightness-temperature-difference layer name
  ///
  /// In en, this message translates to:
  /// **'Himawari Cirrus / Cloud Height'**
  String get mapLayerSatelliteBtdCo2;

  /// Permission row description: background location
  ///
  /// In en, this message translates to:
  /// **'Allow \"Always\" so alerts still target you when the app is closed.'**
  String get onboardingPermBackgroundDesc;

  /// Label above the map timeline's date when the frame times are forecast times, e.g. Forecast / 2026/07/14
  ///
  /// In en, this message translates to:
  /// **'Forecast'**
  String get mapTimelineForecast;

  /// Restroom detail row label for the toilet type
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get restroomTypeLabel;

  /// Earthquake report catalogue title (entry under the Data hub)
  ///
  /// In en, this message translates to:
  /// **'Earthquake'**
  String get navEarthquake;

  /// Tooltip for the L10 storm-band radio row
  ///
  /// In en, this message translates to:
  /// **'Level-10 wind field + average circle (yellow)'**
  String get typhoonOverlayStormL10Tooltip;

  /// Phase: waxing gibbous
  ///
  /// In en, this message translates to:
  /// **'Waxing gibbous'**
  String get moonPhaseWaxingGibbous;

  /// Header title over the report detail map's back button
  ///
  /// In en, this message translates to:
  /// **'Earthquake Report'**
  String get reportDetailTitle;

  /// More-menu link to the TREM detection report website
  ///
  /// In en, this message translates to:
  /// **'TREM detection report'**
  String get moreTremReport;

  /// Nearest-station name and observation time shown as small text under the home weather header name
  ///
  /// In en, this message translates to:
  /// **'{station} · Data {time}'**
  String weatherDataTime(String station, String time);

  /// Empty node list
  ///
  /// In en, this message translates to:
  /// **'No nodes heard yet'**
  String get meshtasticNoNodes;

  /// Legend: node reported over an MQTT bridge
  ///
  /// In en, this message translates to:
  /// **'Via MQTT (internet)'**
  String get meshtasticViaMqtt;

  /// County-border overlay toggle in the map's radar overlay menu.
  ///
  /// In en, this message translates to:
  /// **'County borders'**
  String get radarCountyOutline;

  /// Generic close button / action label
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// Restroom detail row label for the cleanliness grade
  ///
  /// In en, this message translates to:
  /// **'Grade'**
  String get restroomGradeLabel;

  /// Rainfall accumulation since local midnight (API now)
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get rainIntervalNow;

  /// Chip/badge when a release matches the installed app version
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get changelogCurrentVersion;

  /// Bulletin table row label
  ///
  /// In en, this message translates to:
  /// **'Central pressure'**
  String get typhoonLabelPressure;

  /// Tooltip for the forecast callouts overlay toggle
  ///
  /// In en, this message translates to:
  /// **'Show forecast-point detail cards when zoomed in'**
  String get typhoonOverlayForecastCalloutsTooltip;

  /// AED opening-hours remark row label
  ///
  /// In en, this message translates to:
  /// **'Hours note'**
  String get aedOpenRemark;

  /// Onboarding permissions page intro
  ///
  /// In en, this message translates to:
  /// **'So DPIP can alert you the moment disaster strikes, please grant the following. You can change these anytime in system settings.'**
  String get onboardingPermsBody;

  /// Overlay-menu section for radar / IR under the typhoon vectors
  ///
  /// In en, this message translates to:
  /// **'Weather underlay'**
  String get typhoonOverlaySectionWeather;

  /// Notify option label
  ///
  /// In en, this message translates to:
  /// **'Current location only'**
  String get notifyOptWeatherLocal;

  /// Short Map-tab bottom-nav / default-layer picker label for rain
  ///
  /// In en, this message translates to:
  /// **'Rain'**
  String get mapNavRain;

  /// Day unit for the moon age
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get moonDays;

  /// Unit footer under a map colour legend (e.g. Unit: dBZ)
  ///
  /// In en, this message translates to:
  /// **'Unit: {unit}'**
  String mapLegendUnit(String unit);

  /// Weather animation forced to a clear sky
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get weatherModeClear;

  /// Radio diagnostics sheet title
  ///
  /// In en, this message translates to:
  /// **'Radio'**
  String get meshtasticRadio;

  /// Generic message when a loaded list is empty
  ///
  /// In en, this message translates to:
  /// **'Nothing to show'**
  String get commonEmpty;

  /// Himawari visible-blue channel (B01, 0.47 µm) layer name
  ///
  /// In en, this message translates to:
  /// **'Himawari Blue (B01)'**
  String get mapLayerSatelliteB01;

  /// Battery value when mains powered
  ///
  /// In en, this message translates to:
  /// **'External power'**
  String get meshtasticExternalPower;

  /// Phase: last quarter
  ///
  /// In en, this message translates to:
  /// **'Last quarter'**
  String get moonPhaseLastQuarter;

  /// Sort order: oldest / smallest first
  ///
  /// In en, this message translates to:
  /// **'Ascending'**
  String get reportFilterOrderAsc;

  /// Primary button on the report filter sheet — saves draft and searches
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get reportFilterApply;

  /// Shown in place of the report image when it fails to load
  ///
  /// In en, this message translates to:
  /// **'Report image not available'**
  String get reportDetailImageUnavailable;

  /// Chip to rank temperature descending
  ///
  /// In en, this message translates to:
  /// **'Highest'**
  String get weatherRankingHighest;

  /// Button that opens the RTS/EEW replay starting from this report's origin time
  ///
  /// In en, this message translates to:
  /// **'Replay'**
  String get reportDetailReplay;

  /// Disaster-map overlay menu toggle for public restrooms
  ///
  /// In en, this message translates to:
  /// **'Restrooms'**
  String get mapLayerRestroom;

  /// Restroom venue category: social welfare institution / gathering place
  ///
  /// In en, this message translates to:
  /// **'Welfare'**
  String get restroomCategoryWelfare;

  /// Restroom cleanliness grade: excellent
  ///
  /// In en, this message translates to:
  /// **'Excellent'**
  String get restroomGradeExcellent;

  /// Age of the last sent packet
  ///
  /// In en, this message translates to:
  /// **'Last sent'**
  String get meshtasticLastSent;

  /// The radio's long name
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get meshtasticName;

  /// Start scanning for Meshtastic radios
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get meshtasticScan;

  /// Section title in map overlay lists: numerical weather prediction (ECMWF/GFS) wind-field overlays
  ///
  /// In en, this message translates to:
  /// **'Numerical forecast'**
  String get mapLayerCategoryForecast;

  /// The radio rejected the channel write
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t set up the DPIP channel'**
  String get meshtasticChannelFailed;

  /// Theme option: follow the system light/dark setting
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// Himawari normalised-difference vegetation-index layer name
  ///
  /// In en, this message translates to:
  /// **'Himawari NDVI'**
  String get mapLayerSatelliteNdvi;

  /// Typhoon map legend: forecast path
  ///
  /// In en, this message translates to:
  /// **'Forecast track'**
  String get typhoonLegendForecast;

  /// No description provided for @typhoonValueHpa.
  ///
  /// In en, this message translates to:
  /// **'{n} hPa'**
  String typhoonValueHpa(String n);

  /// Label for the precipitation metric in the home weather header
  ///
  /// In en, this message translates to:
  /// **'Precipitation'**
  String get weatherPrecipitation;

  /// Next full moon date label
  ///
  /// In en, this message translates to:
  /// **'Next full moon'**
  String get moonNextFullMoon;

  /// Hint in the disaster-map detail sheet when nothing is selected
  ///
  /// In en, this message translates to:
  /// **'Tap a marker on the map for details'**
  String get dpmSheetEmpty;

  /// Proceed past onboarding without granting permissions
  ///
  /// In en, this message translates to:
  /// **'Skip anyway'**
  String get onboardingSkipLeave;

  /// AED placement description row label
  ///
  /// In en, this message translates to:
  /// **'Placement'**
  String get aedPlaceDesc;

  /// Title of the confirm dialog shown when finishing onboarding without key permissions
  ///
  /// In en, this message translates to:
  /// **'Permissions not granted'**
  String get onboardingSkipTitle;

  /// Restroom type: family restroom
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get restroomTypeFamily;

  /// No description provided for @typhoonValueKm.
  ///
  /// In en, this message translates to:
  /// **'{n} km'**
  String typhoonValueKm(String n);

  /// Permission row: battery optimization (Android)
  ///
  /// In en, this message translates to:
  /// **'Battery exemption'**
  String get onboardingPermBattery;

  /// No description provided for @typhoonLabelNw.
  ///
  /// In en, this message translates to:
  /// **'NW'**
  String get typhoonLabelNw;

  /// Phase: waxing crescent
  ///
  /// In en, this message translates to:
  /// **'Waxing crescent'**
  String get moonPhaseWaxingCrescent;

  /// Restroom venue category: leisure / entertainment venue
  ///
  /// In en, this message translates to:
  /// **'Leisure'**
  String get restroomCategoryLeisure;

  /// Map layer switcher label for the air-temperature layer
  ///
  /// In en, this message translates to:
  /// **'Temperature'**
  String get mapLayerTemperature;

  /// AED venue category row label
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get aedCategory;

  /// Section: the radio's channel table
  ///
  /// In en, this message translates to:
  /// **'Channels'**
  String get meshtasticChannels;

  /// Shown in the monitor panel before the first RTS snapshot arrives
  ///
  /// In en, this message translates to:
  /// **'Waiting for data…'**
  String get monitorWaiting;

  /// Overlay menu: toggle forecast-point Flutter callout cards
  ///
  /// In en, this message translates to:
  /// **'Forecast tooltips'**
  String get typhoonOverlayForecastCallouts;

  /// Row label for the epicenter's latitude/longitude
  ///
  /// In en, this message translates to:
  /// **'Epicenter'**
  String get reportDetailEpicenter;

  /// Battery voltage
  ///
  /// In en, this message translates to:
  /// **'Voltage'**
  String get meshtasticVoltage;

  /// Map layer switcher subtitle
  ///
  /// In en, this message translates to:
  /// **'LoRa mesh nodes heard by your radio'**
  String get mapLayerMeshtasticSubtitle;

  /// Map layer switcher label for the wind-direction layer
  ///
  /// In en, this message translates to:
  /// **'Wind direction'**
  String get mapLayerWind;

  /// Row label for the report's magnitude
  ///
  /// In en, this message translates to:
  /// **'Magnitude'**
  String get reportDetailMagnitude;

  /// Section header over the per-area/town felt-intensity breakdown
  ///
  /// In en, this message translates to:
  /// **'Intensity by area'**
  String get reportDetailAreaIntensity;

  /// No description provided for @rainInterval12h.
  ///
  /// In en, this message translates to:
  /// **'12 h'**
  String get rainInterval12h;

  /// Emphasized magnitude on a report list row
  ///
  /// In en, this message translates to:
  /// **'M{magnitude}'**
  String reportListMagnitude(String magnitude);

  /// Notify channel title
  ///
  /// In en, this message translates to:
  /// **'Strong-motion monitor'**
  String get notifyMonitor;

  /// Onboarding finish button
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get onboardingStart;

  /// Monthly price label for a subscription; price is the store-localized amount
  ///
  /// In en, this message translates to:
  /// **'{price} / month'**
  String sponsorPerMonth(String price);

  /// Map layer switcher label for the air-pressure layer
  ///
  /// In en, this message translates to:
  /// **'Pressure'**
  String get mapLayerPressure;

  /// Himawari near-infrared channel (B04, 0.86 µm) layer name
  ///
  /// In en, this message translates to:
  /// **'Himawari Near-Infrared (B04)'**
  String get mapLayerSatelliteB04;

  /// Satellite legend note: on the brightness-temperature-difference layers a near-zero difference is transparent — no absorber is present
  ///
  /// In en, this message translates to:
  /// **'Zero difference = transparent (no signal)'**
  String get mapLayerSatelliteTransparentZero;

  /// Shelter detail row: whether indoor shelter is provided
  ///
  /// In en, this message translates to:
  /// **'Indoor shelter'**
  String get shelterIndoorLabel;

  /// Notify option label
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get notifyOptOff;

  /// Sort reports by origin time
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get reportFilterSortTime;

  /// Cloud-mask category: probably clear
  ///
  /// In en, this message translates to:
  /// **'Probably clear'**
  String get mapLayerSatelliteCloudProbablyClear;

  /// Weather animation forced to a thunderstorm
  ///
  /// In en, this message translates to:
  /// **'Thunderstorm'**
  String get weatherModeThunderstorm;

  /// Small home-header link that opens the map tab on the temperature layer at the nearest station
  ///
  /// In en, this message translates to:
  /// **'View on map'**
  String get homeViewOnMap;

  /// No description provided for @reportFilterIntensityInfoLegacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Legacy (before 2020)'**
  String get reportFilterIntensityInfoLegacyTitle;

  /// Bulletin table row label
  ///
  /// In en, this message translates to:
  /// **'Past movement speed'**
  String get typhoonLabelSpeed;

  /// Snackbar when the chosen map app cannot be opened on this device
  ///
  /// In en, this message translates to:
  /// **'Could not open {app}'**
  String mapAppOpenFailed(String app);

  /// Satellite legend note for the RGB-recipe products (True Color, Ash, …) that carry no single numerical scale
  ///
  /// In en, this message translates to:
  /// **'RGB composite (JMA recipe)'**
  String get mapLayerSatelliteRgbComposite;

  /// Packets received this session
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get meshtasticReceived;

  /// Chip to rank by recorded daily minimum temperature
  ///
  /// In en, this message translates to:
  /// **'Daily low'**
  String get weatherRankingExtremeLow;

  /// Himawari lower-level water-vapour channel (B10, 7.3 µm) layer name
  ///
  /// In en, this message translates to:
  /// **'Himawari Lower Water Vapour (B10)'**
  String get mapLayerSatelliteB10;

  /// Cloud-mask category: probably cloudy
  ///
  /// In en, this message translates to:
  /// **'Probably cloudy'**
  String get mapLayerSatelliteCloudProbablyCloudy;

  /// Satellite legend note: NDWI/MNDWI at zero or below is transparent — no water signal
  ///
  /// In en, this message translates to:
  /// **'≤ 0 = transparent (no water)'**
  String get mapLayerSatelliteTransparentNoWater;

  /// Shelter detail applicable-disaster categories row label
  ///
  /// In en, this message translates to:
  /// **'Disaster types'**
  String get shelterCategoryLabel;

  /// Connection state label
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get meshtasticStateConnecting;

  /// Moon page title
  ///
  /// In en, this message translates to:
  /// **'Moon'**
  String get moonTitle;

  /// Ranking tab/tile for peak gust speed
  ///
  /// In en, this message translates to:
  /// **'Gust'**
  String get weatherRankingGust;

  /// Apple App Store link title (brand name)
  ///
  /// In en, this message translates to:
  /// **'App Store'**
  String get moreAppStore;

  /// More-menu link to the ExpTech server status website
  ///
  /// In en, this message translates to:
  /// **'Server status'**
  String get moreServerStatus;

  /// Notify page section header
  ///
  /// In en, this message translates to:
  /// **'Weather'**
  String get notifySectionWeather;

  /// LoRa modem preset
  ///
  /// In en, this message translates to:
  /// **'Modem preset'**
  String get meshtasticPreset;

  /// Section header on the Data hub for earthquake-related entries
  ///
  /// In en, this message translates to:
  /// **'Seismic'**
  String get dataSectionSeismic;

  /// Placeholder when a GitHub release has an empty markdown body
  ///
  /// In en, this message translates to:
  /// **'No notes for this release.'**
  String get changelogBodyEmpty;

  /// No description provided for @changelogOpenOnGitHub.
  ///
  /// In en, this message translates to:
  /// **'View on GitHub'**
  String get changelogOpenOnGitHub;

  /// World-country-border overlay toggle in the map's reference-layer overlay menus.
  ///
  /// In en, this message translates to:
  /// **'National borders'**
  String get radarGlobalOutline;

  /// Notify channel title
  ///
  /// In en, this message translates to:
  /// **'Emergency earthquake alert'**
  String get notifyEew;

  /// Region bar label for the whole-country view
  ///
  /// In en, this message translates to:
  /// **'Nationwide'**
  String get regionNationwide;

  /// More-menu link to the DPIP notification send-record website
  ///
  /// In en, this message translates to:
  /// **'DPIP notification log'**
  String get moreNotifyLog;

  /// Region bar label for the current GPS township
  ///
  /// In en, this message translates to:
  /// **'Current location'**
  String get regionCurrent;

  /// Empty message log while not connected
  ///
  /// In en, this message translates to:
  /// **'Not connected to a radio'**
  String get meshtasticNotConnected;

  /// Label for the weatherModeSnow option in the experimental backdrop settings.
  ///
  /// In en, this message translates to:
  /// **'Snow'**
  String get weatherModeSnow;

  /// Map layer name: mesh nodes
  ///
  /// In en, this message translates to:
  /// **'Meshtastic nodes'**
  String get mapLayerMeshtastic;

  /// More-menu entry / title for the developer diagnostics page
  ///
  /// In en, this message translates to:
  /// **'Debug info'**
  String get moreDeveloper;

  /// Himawari longwave-infrared channel (B14, 11.2 µm) layer name
  ///
  /// In en, this message translates to:
  /// **'Himawari Longwave Infrared (B14)'**
  String get mapLayerSatelliteB14;

  /// Share of airtime seen busy
  ///
  /// In en, this message translates to:
  /// **'Channel use'**
  String get meshtasticChannelUse;

  /// Short Map-tab bottom-nav / default-layer picker label for lightning
  ///
  /// In en, this message translates to:
  /// **'Lightning'**
  String get mapNavLightning;

  /// Empty or failed forecast on the home sheet
  ///
  /// In en, this message translates to:
  /// **'No forecast available'**
  String get homeForecastEmpty;

  /// Support page section header for one-time tips
  ///
  /// In en, this message translates to:
  /// **'One-time'**
  String get sponsorOneTime;

  /// Himawari split-window brightness-temperature-difference layer name
  ///
  /// In en, this message translates to:
  /// **'Himawari Split Window'**
  String get mapLayerSatelliteBtdSplit;

  /// Permission row: background/Always location
  ///
  /// In en, this message translates to:
  /// **'Background location'**
  String get onboardingPermBackground;

  /// AED emergency contact phone row label
  ///
  /// In en, this message translates to:
  /// **'Emergency phone'**
  String get aedEmergencyPhone;

  /// Action in the disaster-map detail sheet: open the point in an external map app
  ///
  /// In en, this message translates to:
  /// **'Open in maps'**
  String get dpmOpenInMaps;

  /// Toggle: local notification when a new node is heard
  ///
  /// In en, this message translates to:
  /// **'Notify on new nodes'**
  String get meshtasticNotifyNodes;

  /// Permission row description: critical alerts
  ///
  /// In en, this message translates to:
  /// **'Let life-threatening earthquake warnings sound even in silent mode or Do Not Disturb.'**
  String get onboardingPermCriticalDesc;

  /// Satellite legend note: on the IR grayscale/enhancements the warm end is clear sky, drawn transparent so the basemap shows
  ///
  /// In en, this message translates to:
  /// **'Clear sky (warm end) = transparent, the basemap shows'**
  String get mapLayerSatelliteTransparentWarm;

  /// Packets sent this session
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get meshtasticSent;

  /// Section title for the home sheet township hourly forecast
  ///
  /// In en, this message translates to:
  /// **'24-hour forecast'**
  String get homeForecastTitle;

  /// Typhoon UI: typhoonLegendWarningAreas
  ///
  /// In en, this message translates to:
  /// **'Warning areas'**
  String get typhoonLegendWarningAreas;

  /// How many nodes the filter is hiding
  ///
  /// In en, this message translates to:
  /// **'{count} hidden'**
  String meshtasticExcludeMqttHidden(int count);

  /// Notify option label
  ///
  /// In en, this message translates to:
  /// **'Local intensity 1 or above'**
  String get notifyOptLocalIntensity1;

  /// Label on the map timeline when the selected frame predates the present
  ///
  /// In en, this message translates to:
  /// **'Past'**
  String get mapTimelinePast;

  /// Restroom type: female restroom
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get restroomTypeFemale;

  /// Date section header for reports that originated today (Taipei)
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get reportListToday;

  /// Resting state of the map node sheet
  ///
  /// In en, this message translates to:
  /// **'Tap a node for details'**
  String get meshtasticTapNode;

  /// Generic loading label for an async view
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get commonLoading;

  /// CWA class: moderate typhoon (past-track colour)
  ///
  /// In en, this message translates to:
  /// **'Moderate typhoon'**
  String get typhoonIntensityModerate;

  /// Himawari Ash RGB composite layer name
  ///
  /// In en, this message translates to:
  /// **'Himawari Ash'**
  String get mapLayerSatelliteAsh;

  /// No description provided for @rainInterval3h.
  ///
  /// In en, this message translates to:
  /// **'3 h'**
  String get rainInterval3h;

  /// Section title in map overlay lists: satellite-imagery overlays
  ///
  /// In en, this message translates to:
  /// **'Satellite'**
  String get mapLayerCategorySatellite;

  /// The DPIP channel exists on the radio
  ///
  /// In en, this message translates to:
  /// **'DPIP channel ready'**
  String get meshtasticChannelReady;

  /// Himawari Night Microphysics RGB composite layer name
  ///
  /// In en, this message translates to:
  /// **'Himawari Night Microphysics'**
  String get mapLayerSatelliteNightmicrophysics;

  /// CWA class: tropical depression (past-track colour)
  ///
  /// In en, this message translates to:
  /// **'Tropical depression'**
  String get typhoonIntensityTd;

  /// Label for the origin-time date-range filter
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get reportFilterDate;

  /// Snackbar shown when the store can't be reached to restore
  ///
  /// In en, this message translates to:
  /// **'Can\'t reach the store. Please try again later.'**
  String get sponsorRestoreUnavailable;

  /// Probability of precipitation percent on a forecast hour chip
  ///
  /// In en, this message translates to:
  /// **'{pop}%'**
  String homeForecastPop(String pop);

  /// Empty state on the saved-regions manage page
  ///
  /// In en, this message translates to:
  /// **'No saved regions yet'**
  String get regionEmpty;

  /// Permission row description: battery
  ///
  /// In en, this message translates to:
  /// **'Allow DPIP to keep running in the background so alerts aren\'t delayed or missed.'**
  String get onboardingPermBatteryDesc;

  /// Short Map-tab bottom-nav / default-layer picker label for disaster-prevention map
  ///
  /// In en, this message translates to:
  /// **'Disaster'**
  String get mapNavDisaster;

  /// Radar scan-range overlay toggle in the map's radar overlay menu.
  ///
  /// In en, this message translates to:
  /// **'Outlines the area the four radars actually observe.'**
  String get radarScanRangeSubtitle;

  /// AED Sunday opening hours row label
  ///
  /// In en, this message translates to:
  /// **'Sunday hours'**
  String get aedHoursSunday;

  /// Row label for the report's origin date/time
  ///
  /// In en, this message translates to:
  /// **'Origin time'**
  String get reportDetailOriginTime;

  /// Shown in the station trend chart when there is no data to plot
  ///
  /// In en, this message translates to:
  /// **'No trend data'**
  String get trendNoData;

  /// Permission row: location
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get onboardingPermLocation;

  /// More-menu link to the ExpTech Discord community
  ///
  /// In en, this message translates to:
  /// **'Discord community'**
  String get moreDiscord;

  /// Short Map-tab bottom-nav / default-layer picker label for pressure
  ///
  /// In en, this message translates to:
  /// **'Pressure'**
  String get mapNavPressure;

  /// Himawari clean-infrared window channel (B13, 10.4 µm) layer name
  ///
  /// In en, this message translates to:
  /// **'Himawari Infrared (B13)'**
  String get mapLayerSatelliteB13;

  /// Secondary badge on the typhoon sheet hero: the CWA tropical-depression serial number, e.g. TD 14
  ///
  /// In en, this message translates to:
  /// **'TD {no}'**
  String typhoonTdNo(String no);

  /// Empty state when the releases API returns nothing
  ///
  /// In en, this message translates to:
  /// **'No release notes yet'**
  String get changelogEmpty;

  /// Explains that startTime covers from midnight on that calendar day
  ///
  /// In en, this message translates to:
  /// **'Start day: from 00:00 (Taipei)'**
  String get reportFilterDateStartNote;

  /// Header of the earthquake monitor when one or more alerts are active
  ///
  /// In en, this message translates to:
  /// **'Earthquake early warning'**
  String get eewTitle;

  /// Map layer switcher label for the ECMWF wind-forecast layer
  ///
  /// In en, this message translates to:
  /// **'ECMWF'**
  String get mapLayerWindForecastEcmwf;

  /// Header showing how many saved-region slots are used
  ///
  /// In en, this message translates to:
  /// **'{count}/{max} selected'**
  String regionSelectCount(int count, int max);

  /// Himawari SO₂ / cloud-phase brightness-temperature-difference layer name
  ///
  /// In en, this message translates to:
  /// **'Himawari SO₂ / Cloud Phase'**
  String get mapLayerSatelliteBtdSo2;

  /// Connection state label
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get meshtasticStateError;

  /// Label for the weatherModeOvercast option in the experimental backdrop settings.
  ///
  /// In en, this message translates to:
  /// **'Overcast'**
  String get weatherModeOvercast;

  /// Row label for the report's hypocentral depth
  ///
  /// In en, this message translates to:
  /// **'Depth'**
  String get reportDetailDepth;

  /// Tooltip for the warning-areas overlay toggle
  ///
  /// In en, this message translates to:
  /// **'Highlight counties under a typhoon warning'**
  String get typhoonOverlayWarningTooltip;

  /// Button to open the date-range picker when none selected
  ///
  /// In en, this message translates to:
  /// **'Pick dates'**
  String get reportFilterDatePick;

  /// Dismiss the skip dialog and return to grant permissions
  ///
  /// In en, this message translates to:
  /// **'Go back'**
  String get onboardingSkipStay;

  /// Error headline when a data request (AsyncView) fails, with a retry button
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load data. Please try again.'**
  String get commonFetchFailed;

  /// Shelter detail row: whether outdoor shelter is provided
  ///
  /// In en, this message translates to:
  /// **'Outdoor shelter'**
  String get shelterOutdoorLabel;

  /// Connection state label
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get meshtasticStateConnected;

  /// Short Map-tab bottom-nav / default-layer picker label for radar
  ///
  /// In en, this message translates to:
  /// **'Radar'**
  String get mapNavRadar;

  /// Cloud-mask category: clear sky, transparent on the map
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get mapLayerSatelliteCloudClear;

  /// One-line summary of an EEW alert's magnitude and depth
  ///
  /// In en, this message translates to:
  /// **'M{magnitude} · depth {depth} km'**
  String eewSummary(String magnitude, String depth);

  /// Banner when location permission is denied
  ///
  /// In en, this message translates to:
  /// **'Location permission is off — local alerts can\'t target your area.'**
  String get locationBannerPermission;

  /// Tooltip for clearing the weather underlay
  ///
  /// In en, this message translates to:
  /// **'No radar or infrared underlay'**
  String get typhoonOverlayWeatherNoneTooltip;

  /// Hint under the county-border toggle in the radar overlay menu.
  ///
  /// In en, this message translates to:
  /// **'Drawn over the echo'**
  String get radarCountyOutlineHint;

  /// Hint under the county-border toggle in the wind-forecast overlay menu.
  ///
  /// In en, this message translates to:
  /// **'Drawn over the wind field'**
  String get windForecastCountyOutlineHint;

  /// Section title for the home sheet 1-hour per-minute rainfall bar chart
  ///
  /// In en, this message translates to:
  /// **'Next hour precipitation'**
  String get homeRainTrendTitle;

  /// Phase: first quarter
  ///
  /// In en, this message translates to:
  /// **'First quarter'**
  String get moonPhaseFirstQuarter;

  /// Section title in map overlay lists: typhoon overlays
  ///
  /// In en, this message translates to:
  /// **'Typhoon'**
  String get mapLayerCategoryTyphoon;

  /// Section title for the 24h airtime chart
  ///
  /// In en, this message translates to:
  /// **'Airtime (24h)'**
  String get meshtasticUtilization;

  /// Restroom type: mixed/unisex restroom
  ///
  /// In en, this message translates to:
  /// **'Mixed'**
  String get restroomTypeMixed;

  /// Restroom cleanliness grade: good
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get restroomGradeGood;

  /// Notify channel title
  ///
  /// In en, this message translates to:
  /// **'Tsunami information'**
  String get notifyTsunami;

  /// Bottom-nav label and page title for the Data hub tab
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get navData;

  /// Himawari overshooting-cloud-top brightness-temperature-difference layer name
  ///
  /// In en, this message translates to:
  /// **'Himawari Overshooting Top'**
  String get mapLayerSatelliteBtdWvirw;

  /// How old the battery/airtime numbers are
  ///
  /// In en, this message translates to:
  /// **'Reading taken'**
  String get meshtasticReadingAge;

  /// Snackbar when tapping the emergency phone and the device has no phone handler
  ///
  /// In en, this message translates to:
  /// **'This device cannot make phone calls'**
  String get mapAppCallFailed;

  /// Chip / slider label meaning no filter applied
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get reportFilterAny;

  /// Label before township/county merge chips on ranking
  ///
  /// In en, this message translates to:
  /// **'Merge to'**
  String get weatherRankingMergeTo;

  /// Notify channel title
  ///
  /// In en, this message translates to:
  /// **'Intensity report'**
  String get notifyIntensity;

  /// Tooltip for the rainfall accumulation-interval menu
  ///
  /// In en, this message translates to:
  /// **'Accumulation window'**
  String get rainIntervalMenu;

  /// Eyebrow label on the detail header for a …000 (unnumbered) report
  ///
  /// In en, this message translates to:
  /// **'Local Felt Earthquake'**
  String get reportDetailLocalFelt;

  /// Section: device identity
  ///
  /// In en, this message translates to:
  /// **'Device'**
  String get meshtasticDevice;

  /// Permission grant button
  ///
  /// In en, this message translates to:
  /// **'Grant'**
  String get onboardingGrant;

  /// Weather animation forced to rain
  ///
  /// In en, this message translates to:
  /// **'Rain'**
  String get weatherModeRain;

  /// Shelter detail row: whether evacuees needing care can be accommodated
  ///
  /// In en, this message translates to:
  /// **'Vulnerable-people friendly'**
  String get shelterVulnerableOkLabel;

  /// Empty-state hint in the map station-value sheet, shown before any station is selected
  ///
  /// In en, this message translates to:
  /// **'Tap a station to see its reading'**
  String get stationSheetEmpty;

  /// Typhoon UI: typhoonLegendProbability
  ///
  /// In en, this message translates to:
  /// **'Strike probability'**
  String get typhoonLegendProbability;

  /// Label for the magnitude range filter
  ///
  /// In en, this message translates to:
  /// **'Magnitude'**
  String get reportFilterMagnitude;

  /// Label for the skyTimeMorning option in the experimental backdrop settings.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get skyTimeMorning;

  /// Title of the experimental-features settings page and its More-menu entry
  ///
  /// In en, this message translates to:
  /// **'Experimental features'**
  String get experimentalFeatures;

  /// Onboarding terms of service body
  ///
  /// In en, this message translates to:
  /// **'Please read the following notices before using DPIP:\n\n• All information should defer to the content published by the Central Weather Administration (CWA).\n\n• Depending on network, server, app, and upstream data-source conditions, information may not be received; we make every effort to avoid this but cannot guarantee it never happens.\n\n• Strong shaking may reach your location before the notification does.\n\n• Earthquake early warnings are fast-computed results that may carry significant error — understand this and use them with caution.\n\n• Any behavior not sanctioned by the authorities may carry legal risk; please follow all applicable regulations.\n\nIn addition, to provide localized alerts, this service collects and uploads your approximate location and push identifier — in the foreground and background — solely to decide which alerts to send you.\n\nBy tapping \"Agree and continue\" you confirm that you have read, understood, and agree to the above.'**
  String get onboardingTermsBody;

  /// Title of the earthquake report filter sheet
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get reportFilterTitle;

  /// Permission row: critical alerts (iOS)
  ///
  /// In en, this message translates to:
  /// **'Critical alerts'**
  String get onboardingPermCritical;

  /// Running total label above the cumulative station rain trend chart
  ///
  /// In en, this message translates to:
  /// **'Cumulative {total} mm'**
  String trendCumulativeTotal(String total);

  /// This language's own name, shown in the in-app language picker. Each locale's ARB names itself; the picker is built from these, never a hardcoded list.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageName;

  /// Empty state when active filters yield no report rows
  ///
  /// In en, this message translates to:
  /// **'No earthquake reports match these filters'**
  String get reportListEmptyFiltered;

  /// Toggle hiding internet-bridged nodes
  ///
  /// In en, this message translates to:
  /// **'Hide MQTT nodes'**
  String get meshtasticExcludeMqtt;

  /// Short Map-tab bottom-nav / default-layer picker label for typhoon
  ///
  /// In en, this message translates to:
  /// **'Typhoon'**
  String get mapNavTyphoon;

  /// Label for the weatherModeSand option in the experimental backdrop settings.
  ///
  /// In en, this message translates to:
  /// **'Dust'**
  String get weatherModeSand;

  /// Notify channel title
  ///
  /// In en, this message translates to:
  /// **'Earthquake report'**
  String get notifyReport;

  /// Snackbar confirming the coordinates were copied
  ///
  /// In en, this message translates to:
  /// **'Coordinates copied'**
  String get mapAppCoordinatesCopied;

  /// Label for the skyTimeNight option in the experimental backdrop settings.
  ///
  /// In en, this message translates to:
  /// **'Night'**
  String get skyTimeNight;

  /// Badge on the recommended (subscription) support section
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get sponsorRecommended;

  /// Himawari longwave-infrared channel (B15, 12.4 µm) layer name
  ///
  /// In en, this message translates to:
  /// **'Himawari Longwave Infrared (B15)'**
  String get mapLayerSatelliteB15;

  /// Ranking tab/tile for sustained wind speed
  ///
  /// In en, this message translates to:
  /// **'Wind speed'**
  String get weatherRankingWind;

  /// Banner over a realtime feed whose data has aged past the freshness threshold
  ///
  /// In en, this message translates to:
  /// **'Data may be out of date'**
  String get feedStale;

  /// Wind direction string and Beaufort force for the selected hour
  ///
  /// In en, this message translates to:
  /// **'{direction} · Force {level}'**
  String homeForecastWind(String direction, String level);

  /// Bottom-nav label and page title for the Home tab
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// LoRa region
  ///
  /// In en, this message translates to:
  /// **'Region'**
  String get meshtasticRegionLabel;

  /// Himawari cloud-top-temperature (Level-2 retrieval) layer name
  ///
  /// In en, this message translates to:
  /// **'Himawari Cloud Top Temperature'**
  String get mapLayerSatelliteCloudtop;

  /// Moon phase timeline caption
  ///
  /// In en, this message translates to:
  /// **'Phase'**
  String get moonTimelineCaption;

  /// More-menu entry that opens the bundled open-source license list
  ///
  /// In en, this message translates to:
  /// **'Open-source licenses'**
  String get openSourceLicenses;

  /// Chip to rank temperature ascending
  ///
  /// In en, this message translates to:
  /// **'Lowest'**
  String get weatherRankingLowest;

  /// Sort reports by hypocentral depth
  ///
  /// In en, this message translates to:
  /// **'Depth'**
  String get reportFilterSortDepth;

  /// Model-run issue time shown on the map timeline under a forecast layer's caption, e.g. Data 8/11 14:00
  ///
  /// In en, this message translates to:
  /// **'Data {time}'**
  String mapTimelineDataTime(String time);

  /// Radar scan-range overlay toggle in the map's radar overlay menu.
  ///
  /// In en, this message translates to:
  /// **'Show scan range'**
  String get radarScanRange;

  /// How many hops a packet may take
  ///
  /// In en, this message translates to:
  /// **'Hop limit'**
  String get meshtasticHopLimit;

  /// Chip to rank by recorded daily maximum temperature
  ///
  /// In en, this message translates to:
  /// **'Daily high'**
  String get weatherRankingExtremeHigh;

  /// Footer link to the Privacy Policy
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get sponsorPrivacy;

  /// Section header over the per-location (GPS + saved townships) felt-intensity readout, shown above the area breakdown
  ///
  /// In en, this message translates to:
  /// **'Intensity at your locations'**
  String get reportDetailLocalIntensity;

  /// Himawari Natural Color RGB composite layer name
  ///
  /// In en, this message translates to:
  /// **'Himawari Natural Color'**
  String get mapLayerSatelliteNaturalcolor;

  /// Share of airtime this radio transmitted
  ///
  /// In en, this message translates to:
  /// **'Air time (TX)'**
  String get meshtasticAirtime;

  /// Shelter detail capacity row value
  ///
  /// In en, this message translates to:
  /// **'{n} people'**
  String shelterCapacityValue(int n);

  /// Lightning legend: cloud-to-cloud strike within N minutes
  ///
  /// In en, this message translates to:
  /// **'Cloud-to-cloud · {minutes} min'**
  String lightningLegendCc(int minutes);

  /// Message input hint
  ///
  /// In en, this message translates to:
  /// **'Message to broadcast'**
  String get meshtasticSendHint;

  /// RTS monitor latency: how far behind the latest snapshot is (calibrated now minus the snapshot timestamp), in seconds — pre-formatted to one decimal, e.g. "0.3"
  ///
  /// In en, this message translates to:
  /// **'Delay {value} s'**
  String monitorDelay(String value);

  /// Negative value in the disaster-map detail sheet
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get dpmNo;

  /// Himawari upper-level water-vapour channel (B08, 6.2 µm) layer name
  ///
  /// In en, this message translates to:
  /// **'Himawari Upper Water Vapour (B08)'**
  String get mapLayerSatelliteB08;

  /// The link dropped and is being re-established
  ///
  /// In en, this message translates to:
  /// **'Reconnecting…'**
  String get meshtasticReconnecting;

  /// Township-border overlay toggle in the map's radar overlay menu.
  ///
  /// In en, this message translates to:
  /// **'Keeps township borders legible under the radar echo.'**
  String get radarTownOutlineSubtitle;

  /// Tooltip for Himawari IR underlay (mutex with radar)
  ///
  /// In en, this message translates to:
  /// **'Infrared closest to the typhoon bulletin time'**
  String get typhoonOverlayWeatherSatelliteTooltip;

  /// Hint under the radar scan-range toggle in the radar overlay menu.
  ///
  /// In en, this message translates to:
  /// **'Blank outside means unobserved'**
  String get radarScanRangeHint;

  /// Sheet picker: unnamed tropical depression (CWA tdNo)
  ///
  /// In en, this message translates to:
  /// **'Tropical depression TD {no}'**
  String typhoonPickerTd(String no);

  /// Himawari water-vapour layer name
  ///
  /// In en, this message translates to:
  /// **'Himawari Water Vapour'**
  String get mapLayerSatelliteWatervapor;

  /// Button to open the region picker to add a saved region
  ///
  /// In en, this message translates to:
  /// **'Add a region'**
  String get regionAddButton;

  /// No description provided for @regionSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search counties and cities'**
  String get regionSearchHint;

  /// No description provided for @regionSearchEmpty.
  ///
  /// In en, this message translates to:
  /// **'No matching counties or cities'**
  String get regionSearchEmpty;

  /// No description provided for @regionSearchTownHint.
  ///
  /// In en, this message translates to:
  /// **'Search townships'**
  String get regionSearchTownHint;

  /// No description provided for @regionSearchTownEmpty.
  ///
  /// In en, this message translates to:
  /// **'No matching townships'**
  String get regionSearchTownEmpty;

  /// Display-settings menu entry and page title (theme mode)
  ///
  /// In en, this message translates to:
  /// **'Display'**
  String get displaySettings;

  /// Restroom cleanliness grade: below standard
  ///
  /// In en, this message translates to:
  /// **'Below standard'**
  String get restroomGradePoor;

  /// Restroom venue category: tourist area / scenic spot
  ///
  /// In en, this message translates to:
  /// **'Tourist'**
  String get restroomCategoryTourist;

  /// Banner when the OS location toggle is off
  ///
  /// In en, this message translates to:
  /// **'Location services are off — local alerts can\'t target your area.'**
  String get locationBannerServiceOff;

  /// Tooltip of the colour-style chip beside the layer switcher
  ///
  /// In en, this message translates to:
  /// **'Colour style'**
  String get mapLayerStyleTooltip;

  /// Lightning legend: cloud-to-ground strike within N minutes
  ///
  /// In en, this message translates to:
  /// **'Cloud-to-ground · {minutes} min'**
  String lightningLegendCg(int minutes);

  /// Label for the skyTimeAuto option in the experimental backdrop settings.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get skyTimeAuto;

  /// Title of the in-app log viewer and its entry in the More menu
  ///
  /// In en, this message translates to:
  /// **'App logs'**
  String get appLogs;

  /// No description provided for @serverStatusLocal.
  ///
  /// In en, this message translates to:
  /// **'Local status'**
  String get serverStatusLocal;

  /// No description provided for @serverStatusLocalBody.
  ///
  /// In en, this message translates to:
  /// **'Metrics come from the dashboard. Below is this device\'s own view of the multi-active endpoints (LB / Core per region): it passively records the traffic each endpoint actually serves, so a cell with no data means nothing was observed through this device yet.'**
  String get serverStatusLocalBody;

  /// No description provided for @serverStatusAllUp.
  ///
  /// In en, this message translates to:
  /// **'All services operational'**
  String get serverStatusAllUp;

  /// No description provided for @serverStatusDegraded.
  ///
  /// In en, this message translates to:
  /// **'Services degraded'**
  String get serverStatusDegraded;

  /// No description provided for @serverStatusDown.
  ///
  /// In en, this message translates to:
  /// **'Service down'**
  String get serverStatusDown;

  /// No description provided for @serverStatusErrorRate.
  ///
  /// In en, this message translates to:
  /// **'5xx error rate'**
  String get serverStatusErrorRate;

  /// No description provided for @serverStatusLatency.
  ///
  /// In en, this message translates to:
  /// **'Avg latency'**
  String get serverStatusLatency;

  /// No description provided for @serverStatusUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get serverStatusUpdated;

  /// No description provided for @serverStatusWeb.
  ///
  /// In en, this message translates to:
  /// **'Server status'**
  String get serverStatusWeb;

  /// No description provided for @serverStatusWebUrl.
  ///
  /// In en, this message translates to:
  /// **'status.exptech.dev'**
  String get serverStatusWebUrl;

  /// No description provided for @serverStatusExpTech.
  ///
  /// In en, this message translates to:
  /// **'ExpTech status'**
  String get serverStatusExpTech;

  /// No description provided for @serverStatusCloudflare.
  ///
  /// In en, this message translates to:
  /// **'Cloudflare status'**
  String get serverStatusCloudflare;

  /// No description provided for @serverStatusCloudflareAllOperational.
  ///
  /// In en, this message translates to:
  /// **'All regions operational'**
  String get serverStatusCloudflareAllOperational;

  /// No description provided for @serverStatusCloudflareOutage.
  ///
  /// In en, this message translates to:
  /// **'Cloudflare regional issue'**
  String get serverStatusCloudflareOutage;

  /// No description provided for @serverStatusCloudflareNone.
  ///
  /// In en, this message translates to:
  /// **'No regions to show.'**
  String get serverStatusCloudflareNone;

  /// No description provided for @serverStatusCloudflareOperational.
  ///
  /// In en, this message translates to:
  /// **'Operational'**
  String get serverStatusCloudflareOperational;

  /// No description provided for @serverStatusCloudflareDegraded.
  ///
  /// In en, this message translates to:
  /// **'Degraded'**
  String get serverStatusCloudflareDegraded;

  /// No description provided for @serverStatusCloudflarePartial.
  ///
  /// In en, this message translates to:
  /// **'Partial outage'**
  String get serverStatusCloudflarePartial;

  /// No description provided for @serverStatusCloudflareMajor.
  ///
  /// In en, this message translates to:
  /// **'Major outage'**
  String get serverStatusCloudflareMajor;

  /// No description provided for @serverStatusCloudflareUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get serverStatusCloudflareUnknown;

  /// No description provided for @endpointTierLbApi.
  ///
  /// In en, this message translates to:
  /// **'LB API'**
  String get endpointTierLbApi;

  /// No description provided for @endpointTierLbStatic.
  ///
  /// In en, this message translates to:
  /// **'LB Static'**
  String get endpointTierLbStatic;

  /// No description provided for @endpointTierCoreApi.
  ///
  /// In en, this message translates to:
  /// **'Core API'**
  String get endpointTierCoreApi;

  /// No description provided for @endpointTierCoreStatic.
  ///
  /// In en, this message translates to:
  /// **'Core Static'**
  String get endpointTierCoreStatic;

  /// No description provided for @endpointTierCoreExclusiveApi.
  ///
  /// In en, this message translates to:
  /// **'Core-exclusive API (radar / weather / wind)'**
  String get endpointTierCoreExclusiveApi;

  /// No description provided for @endpointTierCoreStaticExclusive.
  ///
  /// In en, this message translates to:
  /// **'Core-exclusive static'**
  String get endpointTierCoreStaticExclusive;

  /// No description provided for @endpointTierLegacyApi.
  ///
  /// In en, this message translates to:
  /// **'Legacy API (api-1)'**
  String get endpointTierLegacyApi;

  /// No description provided for @endpointHealthOk.
  ///
  /// In en, this message translates to:
  /// **'Local connections healthy'**
  String get endpointHealthOk;

  /// No description provided for @endpointHealthDegraded.
  ///
  /// In en, this message translates to:
  /// **'Some endpoints unstable'**
  String get endpointHealthDegraded;

  /// No description provided for @endpointHealthDown.
  ///
  /// In en, this message translates to:
  /// **'Local connections failing'**
  String get endpointHealthDown;

  /// No description provided for @endpointHealthUnknown.
  ///
  /// In en, this message translates to:
  /// **'No observations yet'**
  String get endpointHealthUnknown;

  /// No description provided for @endpointStateOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get endpointStateOk;

  /// No description provided for @endpointStateDegraded.
  ///
  /// In en, this message translates to:
  /// **'Unstable'**
  String get endpointStateDegraded;

  /// No description provided for @endpointStateDown.
  ///
  /// In en, this message translates to:
  /// **'Failing'**
  String get endpointStateDown;

  /// No description provided for @endpointStateUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get endpointStateUnknown;

  /// No description provided for @endpointServiceEew.
  ///
  /// In en, this message translates to:
  /// **'EEW'**
  String get endpointServiceEew;

  /// No description provided for @endpointServiceRts.
  ///
  /// In en, this message translates to:
  /// **'RTS'**
  String get endpointServiceRts;

  /// No description provided for @endpointServiceRadar.
  ///
  /// In en, this message translates to:
  /// **'Radar'**
  String get endpointServiceRadar;

  /// No description provided for @endpointServiceSatellite.
  ///
  /// In en, this message translates to:
  /// **'Satellite'**
  String get endpointServiceSatellite;

  /// No description provided for @endpointServiceQpesums.
  ///
  /// In en, this message translates to:
  /// **'QPE'**
  String get endpointServiceQpesums;

  /// No description provided for @endpointServiceWind.
  ///
  /// In en, this message translates to:
  /// **'Wind'**
  String get endpointServiceWind;

  /// No description provided for @endpointServiceDpm.
  ///
  /// In en, this message translates to:
  /// **'Disaster points'**
  String get endpointServiceDpm;

  /// No description provided for @endpointServiceWeather.
  ///
  /// In en, this message translates to:
  /// **'Weather'**
  String get endpointServiceWeather;

  /// No description provided for @endpointServiceRain.
  ///
  /// In en, this message translates to:
  /// **'Rain'**
  String get endpointServiceRain;

  /// No description provided for @endpointServiceLightning.
  ///
  /// In en, this message translates to:
  /// **'Lightning'**
  String get endpointServiceLightning;

  /// No description provided for @endpointServiceTyphoon.
  ///
  /// In en, this message translates to:
  /// **'Typhoon'**
  String get endpointServiceTyphoon;

  /// No description provided for @endpointServiceReport.
  ///
  /// In en, this message translates to:
  /// **'EQ reports'**
  String get endpointServiceReport;

  /// No description provided for @endpointServiceTremStation.
  ///
  /// In en, this message translates to:
  /// **'Tremor station'**
  String get endpointServiceTremStation;

  /// No description provided for @endpointServiceEvent.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get endpointServiceEvent;

  /// No description provided for @endpointServiceLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get endpointServiceLocation;

  /// No description provided for @endpointServiceNotify.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get endpointServiceNotify;

  /// No description provided for @endpointServiceOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get endpointServiceOther;

  /// A realtime feed is establishing its first data
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get feedConnecting;

  /// App-wide banner shown when notification permission is disabled
  ///
  /// In en, this message translates to:
  /// **'Notifications are off — you won\'t receive disaster alerts.'**
  String get notifyBannerDisabled;

  /// Label for the humidity metric in the home weather header
  ///
  /// In en, this message translates to:
  /// **'Humidity'**
  String get weatherHumidity;

  /// No description provided for @typhoonValueMs.
  ///
  /// In en, this message translates to:
  /// **'{n} m/s'**
  String typhoonValueMs(String n);

  /// Relative humidity for the selected forecast hour
  ///
  /// In en, this message translates to:
  /// **'Humidity {value}%'**
  String homeForecastHumidity(String value);

  /// Why two clients on one radio is a problem
  ///
  /// In en, this message translates to:
  /// **'Disconnect it in the other Meshtastic app first. Two apps on one radio take each other\'s messages, so some will go missing.'**
  String get meshtasticBusyBody;

  /// Every secondary channel slot is taken
  ///
  /// In en, this message translates to:
  /// **'No free channel slot — free one on the radio'**
  String get meshtasticChannelNoSlot;

  /// Restroom venue category: transport facility
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get restroomCategoryTransport;

  /// Battery charge
  ///
  /// In en, this message translates to:
  /// **'Battery'**
  String get meshtasticBattery;

  /// No description provided for @meshtasticDistance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get meshtasticDistance;

  /// No description provided for @meshtasticSnrTrend.
  ///
  /// In en, this message translates to:
  /// **'Signal trend (SNR)'**
  String get meshtasticSnrTrend;

  /// No description provided for @meshtasticBatteryTrend.
  ///
  /// In en, this message translates to:
  /// **'Battery trend'**
  String get meshtasticBatteryTrend;

  /// Tooltip for the typhoon overlay-toggle chip beside the layer switcher
  ///
  /// In en, this message translates to:
  /// **'Typhoon overlay options'**
  String get typhoonOverlayMenuTooltip;

  /// Himawari tropopause brightness-temperature-difference layer name
  ///
  /// In en, this message translates to:
  /// **'Himawari Tropopause'**
  String get mapLayerSatelliteBtdOzone;

  /// Radio is on another LoRa region than DPIP needs
  ///
  /// In en, this message translates to:
  /// **'Radio region is {region} — DPIP needs TW'**
  String meshtasticRegionMismatch(String region);

  /// Notify page section header
  ///
  /// In en, this message translates to:
  /// **'Earthquake'**
  String get notifySectionEarthquake;

  /// Map layer switcher label for the disaster-prevention map (DPM)
  ///
  /// In en, this message translates to:
  /// **'Disaster Map'**
  String get mapLayerDisasterMap;

  /// Weather animation forced to heavy fog
  ///
  /// In en, this message translates to:
  /// **'Fog'**
  String get weatherModeFog;

  /// Sheet picker: named typhoon (CWA name + TY tyNo)
  ///
  /// In en, this message translates to:
  /// **'{name} TY {no}'**
  String typhoonPickerNamed(String no, String name);

  /// Explains the JMA grayscale band rendering
  ///
  /// In en, this message translates to:
  /// **'JMA grayscale — colder is whiter'**
  String get mapLayerStyleGrayTooltip;

  /// More-menu link to the ExpTech announcements website
  ///
  /// In en, this message translates to:
  /// **'Announcements'**
  String get moreAnnouncements;

  /// No description provided for @moreTagline.
  ///
  /// In en, this message translates to:
  /// **'Disaster Prevention Information Platform'**
  String get moreTagline;

  /// No description provided for @moreVersionStable.
  ///
  /// In en, this message translates to:
  /// **'Release'**
  String get moreVersionStable;

  /// No description provided for @moreVersionNotes.
  ///
  /// In en, this message translates to:
  /// **'This update'**
  String get moreVersionNotes;

  /// No description provided for @moreVersionNotesHighlightsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'What changed in this release'**
  String get moreVersionNotesHighlightsSubtitle;

  /// No description provided for @releaseHighlightsTitle.
  ///
  /// In en, this message translates to:
  /// **'{train} key highlights'**
  String releaseHighlightsTitle(Object train);

  /// No description provided for @releaseHighlightsTabNormal.
  ///
  /// In en, this message translates to:
  /// **'For users'**
  String get releaseHighlightsTabNormal;

  /// No description provided for @releaseHighlightsTabAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Deep dive'**
  String get releaseHighlightsTabAdvanced;

  /// No description provided for @releaseHighlightsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet.'**
  String get releaseHighlightsEmpty;

  /// No description provided for @releaseHighlightsSeeNotes.
  ///
  /// In en, this message translates to:
  /// **'Full release notes'**
  String get releaseHighlightsSeeNotes;

  /// No description provided for @moreVersionNotesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No changelog for this build'**
  String get moreVersionNotesEmpty;

  /// Shown when a report opened from a notification or a deep link no longer exists (HTTP 404), just before the user is returned to the report list.
  ///
  /// In en, this message translates to:
  /// **'That earthquake report is no longer available'**
  String get reportNotFound;

  /// No description provided for @moreVersionSnapshot.
  ///
  /// In en, this message translates to:
  /// **'Snapshot'**
  String get moreVersionSnapshot;

  /// Satellite legend note: the SST retrieval has no value over land, drawn transparent
  ///
  /// In en, this message translates to:
  /// **'No data (land) = transparent'**
  String get mapLayerSatelliteTransparentNoData;

  /// Restroom venue category: public service office
  ///
  /// In en, this message translates to:
  /// **'Government'**
  String get restroomCategoryGovernment;

  /// Typhoon map legend: current storm centre
  ///
  /// In en, this message translates to:
  /// **'Current centre'**
  String get typhoonLegendCurrent;

  /// AED detail row label
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get aedAddress;

  /// Disaster-map overlay menu toggle for AED (defibrillator) points
  ///
  /// In en, this message translates to:
  /// **'AED'**
  String get mapLayerAed;

  /// Chip label for a pre-release
  ///
  /// In en, this message translates to:
  /// **'Beta'**
  String get changelogTypePrerelease;

  /// No description provided for @reportFilterIntensityInfoModernBody.
  ///
  /// In en, this message translates to:
  /// **'Levels 0–4, 5−, 5+, 6−, 6+, and 7. The filter slider uses this scale; older events still show legacy labels in the list.'**
  String get reportFilterIntensityInfoModernBody;

  /// No radar or satellite underlay
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get typhoonOverlayWeatherNone;

  /// Colour-style option: JMA grayscale, the default radar-image convention
  ///
  /// In en, this message translates to:
  /// **'Grayscale (JMA)'**
  String get mapLayerStyleGray;

  /// Weather animation follows real conditions
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get weatherModeAuto;

  /// Forecast point: radius of the 70% track probability circle
  ///
  /// In en, this message translates to:
  /// **'70% probability circle'**
  String get typhoonLabelProbCircle;

  /// Notify option label
  ///
  /// In en, this message translates to:
  /// **'Receive all'**
  String get notifyOptAll;

  /// Section header for the theme-mode chooser on the Display settings page
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get displayTheme;

  /// Himawari shortwave-infrared channel (B07, 3.9 µm) layer name
  ///
  /// In en, this message translates to:
  /// **'Himawari Shortwave Infrared (B07)'**
  String get mapLayerSatelliteB07;

  /// Bulletin table row label
  ///
  /// In en, this message translates to:
  /// **'Past movement direction'**
  String get typhoonLabelDirection;

  /// More-menu entry that opens the region picker
  ///
  /// In en, this message translates to:
  /// **'Saved regions'**
  String get regionManageTitle;

  /// Note about how notifications and saved regions work
  ///
  /// In en, this message translates to:
  /// **'Notifications are sent based on your GPS location. Setting a saved region does not change where alerts are sent — saved regions only affect which areas the home screen shows at a glance. Grant location permission, or alerts cannot work.'**
  String get regionSaveNote;

  /// Typhoon map legend: uncertainty cone
  ///
  /// In en, this message translates to:
  /// **'Forecast cone'**
  String get typhoonLegendCone;

  /// More-menu link to the CWA earthquake early warning publication log website
  ///
  /// In en, this message translates to:
  /// **'CWA earthquake early warning'**
  String get moreCwaEew;

  /// Onboarding permissions page title
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get onboardingPermsTitle;

  /// Colour-style option: JMA cloud-top enhancement, tinted below −40 °C
  ///
  /// In en, this message translates to:
  /// **'Cloud-top enhancement (JMA)'**
  String get mapLayerStyleJma;

  /// No description provided for @rainInterval10m.
  ///
  /// In en, this message translates to:
  /// **'10 min'**
  String get rainInterval10m;

  /// Connect despite the other app
  ///
  /// In en, this message translates to:
  /// **'Connect anyway'**
  String get meshtasticConnectAnyway;

  /// Number of reports in a day section
  ///
  /// In en, this message translates to:
  /// **'{count}'**
  String reportListDayCount(int count);

  /// Himawari near-infrared channel (B06, 2.3 µm) layer name
  ///
  /// In en, this message translates to:
  /// **'Himawari Near-Infrared (B06)'**
  String get mapLayerSatelliteB06;

  /// Satellite legend note: on the reflectance bands a dark or night pixel is transparent so the basemap shows
  ///
  /// In en, this message translates to:
  /// **'Low reflectance / night = transparent, the basemap shows'**
  String get mapLayerSatelliteTransparentReflectance;

  /// Compact chart X-axis hour tick (e.g. 20h / 20時)
  ///
  /// In en, this message translates to:
  /// **'{hour}h'**
  String chartHourLabel(int hour);

  /// Disaster-map overlay menu toggle for evacuation shelters
  ///
  /// In en, this message translates to:
  /// **'Shelters'**
  String get mapLayerShelter;

  /// Tooltip for the strike-probability toggle; notes mutual exclusion with the cone
  ///
  /// In en, this message translates to:
  /// **'Show strike probability (hides the forecast cone)'**
  String get typhoonOverlayProbabilityTooltip;

  /// Himawari normalised-difference water-index layer name
  ///
  /// In en, this message translates to:
  /// **'Himawari NDWI'**
  String get mapLayerSatelliteNdwi;

  /// Tooltip for the shelter toggle in the disaster-map overlay menu
  ///
  /// In en, this message translates to:
  /// **'Show evacuation shelters'**
  String get disasterMapOverlayShelterTooltip;

  /// Short Map-tab bottom-nav / default-layer picker label for humidity
  ///
  /// In en, this message translates to:
  /// **'Humidity'**
  String get mapNavHumidity;

  /// Tooltip on the area-intensity sort toggle when tapping it switches to grouping by intensity level
  ///
  /// In en, this message translates to:
  /// **'Sort by intensity'**
  String get reportDetailSortByIntensity;

  /// Label on the home rain trend chart for minutes beyond the forecast window, and the empty-card hint
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get homeRainTrendNoData;

  /// Section title in map overlay lists: radar and precipitation-forecast overlays
  ///
  /// In en, this message translates to:
  /// **'Radar'**
  String get mapLayerCategoryRadar;

  /// The radio's short name
  ///
  /// In en, this message translates to:
  /// **'Short name'**
  String get meshtasticShortName;

  /// Himawari Airmass RGB composite layer name
  ///
  /// In en, this message translates to:
  /// **'Himawari Airmass'**
  String get mapLayerSatelliteAirmass;

  /// Section header on the Data hub for weather observation rankings
  ///
  /// In en, this message translates to:
  /// **'Weather'**
  String get dataSectionWeather;

  /// AED weekday opening hours row label
  ///
  /// In en, this message translates to:
  /// **'Weekday hours'**
  String get aedHoursWeekday;

  /// Section title for currently active disaster notices on the collapsed home sheet
  ///
  /// In en, this message translates to:
  /// **'Active events'**
  String get homeActiveEventsTitle;

  /// More-menu link title for the FAQ / help page
  ///
  /// In en, this message translates to:
  /// **'FAQ'**
  String get faq;

  /// The serial (report number) of an EEW alert
  ///
  /// In en, this message translates to:
  /// **'Report {serial}'**
  String eewSerial(int serial);

  /// Section title for report list sort field + order
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get reportFilterSort;

  /// Confirmation before rebooting the radio
  ///
  /// In en, this message translates to:
  /// **'Switch this radio to the TW region? It restarts and disconnects for a moment, and every other channel on it moves too.'**
  String get meshtasticRegionConfirm;

  /// Subtitle under the Earthquake tile on the Data hub
  ///
  /// In en, this message translates to:
  /// **'Earthquake reports'**
  String get dataEarthquakeSubtitle;

  /// No description provided for @typhoonNoActive.
  ///
  /// In en, this message translates to:
  /// **'No active typhoon'**
  String get typhoonNoActive;

  /// Himawari SO₂ absorption channel (B11, 8.6 µm) layer name
  ///
  /// In en, this message translates to:
  /// **'Himawari SO₂ / Cloud Phase (B11)'**
  String get mapLayerSatelliteB11;

  /// Bottom-nav label and page title for the Events tab
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get navEvents;

  /// Onboarding terms page title
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get onboardingTermsTitle;

  /// No description provided for @mapOsmOverlay.
  ///
  /// In en, this message translates to:
  /// **'Detailed map'**
  String get mapOsmOverlay;

  /// No description provided for @mapOsmOverlayHint.
  ///
  /// In en, this message translates to:
  /// **'Show more complete roads, buildings, and place labels'**
  String get mapOsmOverlayHint;

  /// No description provided for @mapOsmDetails.
  ///
  /// In en, this message translates to:
  /// **'Detailed map layers'**
  String get mapOsmDetails;

  /// Heading above the subtle source-attribution list at the bottom of About
  ///
  /// In en, this message translates to:
  /// **'Data sources'**
  String get moreDataSources;

  /// No description provided for @dataSourceTremNet.
  ///
  /// In en, this message translates to:
  /// **'探索智慧科技有限公司 — TREM-Net'**
  String get dataSourceTremNet;

  /// No description provided for @dataSourceCwa.
  ///
  /// In en, this message translates to:
  /// **'交通部中央氣象署 (CWA)'**
  String get dataSourceCwa;

  /// No description provided for @dataSourceJma.
  ///
  /// In en, this message translates to:
  /// **'気象庁 (JMA)'**
  String get dataSourceJma;

  /// No description provided for @dataSourceNcdr.
  ///
  /// In en, this message translates to:
  /// **'國家災害防救科技中心 (NCDR)'**
  String get dataSourceNcdr;

  /// No description provided for @dataSourceEcmwf.
  ///
  /// In en, this message translates to:
  /// **'European Centre for Medium-Range Weather Forecasts (ECMWF)'**
  String get dataSourceEcmwf;

  /// No description provided for @dataSourceNoaaGfs.
  ///
  /// In en, this message translates to:
  /// **'National Oceanic and Atmospheric Administration / National Centers for Environmental Prediction — Global Forecast System (NOAA/NCEP GFS)'**
  String get dataSourceNoaaGfs;

  /// No description provided for @dataSourceGovernmentOpenData.
  ///
  /// In en, this message translates to:
  /// **'政府資料開放平臺'**
  String get dataSourceGovernmentOpenData;

  /// No description provided for @dataSourceOpenStreetMap.
  ///
  /// In en, this message translates to:
  /// **'© OpenStreetMap contributors'**
  String get dataSourceOpenStreetMap;

  /// No description provided for @dataSourceNasaMoon.
  ///
  /// In en, this message translates to:
  /// **'National Aeronautics and Space Administration / Goddard Space Flight Center Scientific Visualization Studio — CGI Moon Kit (NASA/GSFC SVS)'**
  String get dataSourceNasaMoon;

  /// How many of the OSM layers are enabled
  ///
  /// In en, this message translates to:
  /// **'{enabled} of {total} layers enabled'**
  String mapOsmDetailsHint(int enabled, int total);

  /// No description provided for @mapOsmSurface.
  ///
  /// In en, this message translates to:
  /// **'Surface'**
  String get mapOsmSurface;

  /// No description provided for @mapOsmParks.
  ///
  /// In en, this message translates to:
  /// **'Parks'**
  String get mapOsmParks;

  /// No description provided for @mapOsmLandUse.
  ///
  /// In en, this message translates to:
  /// **'Land use'**
  String get mapOsmLandUse;

  /// No description provided for @mapOsmAirportAreas.
  ///
  /// In en, this message translates to:
  /// **'Airport areas'**
  String get mapOsmAirportAreas;

  /// No description provided for @mapOsmWater.
  ///
  /// In en, this message translates to:
  /// **'Water'**
  String get mapOsmWater;

  /// No description provided for @mapOsmRivers.
  ///
  /// In en, this message translates to:
  /// **'Rivers'**
  String get mapOsmRivers;

  /// No description provided for @mapOsmBoundaries.
  ///
  /// In en, this message translates to:
  /// **'Boundaries'**
  String get mapOsmBoundaries;

  /// No description provided for @mapOsmBuildings.
  ///
  /// In en, this message translates to:
  /// **'Buildings'**
  String get mapOsmBuildings;

  /// No description provided for @mapOsmRoads.
  ///
  /// In en, this message translates to:
  /// **'Roads'**
  String get mapOsmRoads;

  /// No description provided for @mapOsmRoadNames.
  ///
  /// In en, this message translates to:
  /// **'Road names'**
  String get mapOsmRoadNames;

  /// No description provided for @mapOsmWaterNames.
  ///
  /// In en, this message translates to:
  /// **'Water names'**
  String get mapOsmWaterNames;

  /// No description provided for @mapOsmPeaks.
  ///
  /// In en, this message translates to:
  /// **'Peaks'**
  String get mapOsmPeaks;

  /// No description provided for @mapOsmAirportNames.
  ///
  /// In en, this message translates to:
  /// **'Airport names'**
  String get mapOsmAirportNames;

  /// No description provided for @mapOsmPlaceNames.
  ///
  /// In en, this message translates to:
  /// **'Place names'**
  String get mapOsmPlaceNames;

  /// No description provided for @mapOsmPoi.
  ///
  /// In en, this message translates to:
  /// **'Points of interest'**
  String get mapOsmPoi;

  /// No description provided for @mapOsmHouseNumbers.
  ///
  /// In en, this message translates to:
  /// **'House numbers'**
  String get mapOsmHouseNumbers;

  /// No description provided for @mapOsmRestoreAll.
  ///
  /// In en, this message translates to:
  /// **'Restore all'**
  String get mapOsmRestoreAll;

  /// No description provided for @mapOsmSectionNatural.
  ///
  /// In en, this message translates to:
  /// **'Natural features'**
  String get mapOsmSectionNatural;

  /// No description provided for @mapOsmSectionRoadsAndBuildings.
  ///
  /// In en, this message translates to:
  /// **'Roads & buildings'**
  String get mapOsmSectionRoadsAndBuildings;

  /// No description provided for @mapOsmSectionLabelsAndPlaces.
  ///
  /// In en, this message translates to:
  /// **'Labels & places'**
  String get mapOsmSectionLabelsAndPlaces;

  /// Map setting: show township-name labels when the map is zoomed in
  ///
  /// In en, this message translates to:
  /// **'Township names'**
  String get mapTownLabels;

  /// Snackbar shown when saving a notification channel fails
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save the setting. Please try again.'**
  String get notifySetFailed;

  /// Disconnect from the radio
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get meshtasticDisconnect;

  /// Packets the radio could not decrypt
  ///
  /// In en, this message translates to:
  /// **'Not decrypted'**
  String get meshtasticUndecoded;

  /// Notify channel title
  ///
  /// In en, this message translates to:
  /// **'Announcements'**
  String get notifyAnnouncement;

  /// Onboarding intro page title
  ///
  /// In en, this message translates to:
  /// **'Welcome to DPIP'**
  String get onboardingIntroTitle;

  /// Shown when the current-location area is selected but GPS is off/unavailable
  ///
  /// In en, this message translates to:
  /// **'Can\'t get current location'**
  String get regionCurrentUnavailable;

  /// Language picker option: follow the system language
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get languageSystem;

  /// Label for the skyTimeSunset option in the experimental backdrop settings.
  ///
  /// In en, this message translates to:
  /// **'Sunset'**
  String get skyTimeSunset;

  /// Himawari Dust RGB composite layer name
  ///
  /// In en, this message translates to:
  /// **'Himawari Dust'**
  String get mapLayerSatelliteDust;

  /// External map app choice: Apple Maps
  ///
  /// In en, this message translates to:
  /// **'Apple Maps'**
  String get mapAppAppleMaps;

  /// Edit action on a saved-region bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get regionEdit;

  /// Setting that forces the home weather backdrop to a fixed state
  ///
  /// In en, this message translates to:
  /// **'Weather animation'**
  String get weatherDynamicState;

  /// Returns the moon page to the present moment
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get moonNow;

  /// Section header: how the Moon looks at the chosen moment
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get moonSectionAppearance;

  /// Section header: moonrise and moonset for the user's township
  ///
  /// In en, this message translates to:
  /// **'Rise and set'**
  String get moonSectionRiseSet;

  /// Section header: the next full and new moons
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get moonSectionUpcoming;

  /// Section header: the month-at-a-glance phase calendar
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get moonSectionCalendar;

  /// Earth-Moon centre-to-centre distance
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get moonDistance;

  /// Unit suffix for the lunar distance
  ///
  /// In en, this message translates to:
  /// **'km'**
  String get moonKilometres;

  /// The Moon's apparent angular diameter
  ///
  /// In en, this message translates to:
  /// **'Apparent size'**
  String get moonApparentSize;

  /// Time the Moon rises
  ///
  /// In en, this message translates to:
  /// **'Moonrise'**
  String get moonRise;

  /// Time the Moon sets
  ///
  /// In en, this message translates to:
  /// **'Moonset'**
  String get moonSet;

  /// Date and time of the next new moon
  ///
  /// In en, this message translates to:
  /// **'Next new moon'**
  String get moonNextNewMoon;

  /// Shown when the Moon neither rises nor sets and stays above the horizon
  ///
  /// In en, this message translates to:
  /// **'Up all day'**
  String get moonAlwaysUp;

  /// Shown when a calendar day has no moonrise or no moonset
  ///
  /// In en, this message translates to:
  /// **'None today'**
  String get moonNoEvent;

  /// Sun page title
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get sunTitle;

  /// Section header: sunrise, noon, sunset, day length
  ///
  /// In en, this message translates to:
  /// **'Daylight'**
  String get sunSectionDaylight;

  /// Section header: the three twilight bands
  ///
  /// In en, this message translates to:
  /// **'Twilight'**
  String get sunSectionTwilight;

  /// Section header: golden and blue hour
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get sunSectionLight;

  /// Section header: equation of time and the next solar term
  ///
  /// In en, this message translates to:
  /// **'Sundial'**
  String get sunSectionSundial;

  /// Section header: the year's twenty-four solar terms
  ///
  /// In en, this message translates to:
  /// **'Solar terms'**
  String get sunSectionTerms;

  /// Time the Sun rises
  ///
  /// In en, this message translates to:
  /// **'Sunrise'**
  String get sunRise;

  /// Time the Sun sets
  ///
  /// In en, this message translates to:
  /// **'Sunset'**
  String get sunSet;

  /// Solar noon, the Sun's upper transit
  ///
  /// In en, this message translates to:
  /// **'Solar noon'**
  String get sunNoon;

  /// How long the Sun is above the horizon, as hours:minutes
  ///
  /// In en, this message translates to:
  /// **'Day length'**
  String get sunDayLength;

  /// Civil twilight, the Sun 6 degrees below the horizon
  ///
  /// In en, this message translates to:
  /// **'Civil'**
  String get sunTwilightCivil;

  /// Nautical twilight, 12 degrees below
  ///
  /// In en, this message translates to:
  /// **'Nautical'**
  String get sunTwilightNautical;

  /// Astronomical twilight, 18 degrees below
  ///
  /// In en, this message translates to:
  /// **'Astronomical'**
  String get sunTwilightAstronomical;

  /// Morning golden hour span
  ///
  /// In en, this message translates to:
  /// **'Morning golden hour'**
  String get sunGoldenHourMorning;

  /// Evening golden hour span
  ///
  /// In en, this message translates to:
  /// **'Evening golden hour'**
  String get sunGoldenHourEvening;

  /// Blue hour span after sunset
  ///
  /// In en, this message translates to:
  /// **'Blue hour'**
  String get sunBlueHour;

  /// Apparent solar time minus mean solar time
  ///
  /// In en, this message translates to:
  /// **'Equation of time'**
  String get sunEquationOfTime;

  /// Unit suffix for the equation of time
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get sunMinutes;

  /// The next of the twenty-four solar terms
  ///
  /// In en, this message translates to:
  /// **'Next term'**
  String get solarTermNext;

  /// Planets page title
  ///
  /// In en, this message translates to:
  /// **'Planets'**
  String get planetsTitle;

  /// Section header: the planets right now
  ///
  /// In en, this message translates to:
  /// **'Right now'**
  String get planetsSectionTonight;

  /// Badge: the planet is above the horizon
  ///
  /// In en, this message translates to:
  /// **'Up'**
  String get planetUp;

  /// Badge: the planet is below the horizon
  ///
  /// In en, this message translates to:
  /// **'Below'**
  String get planetDown;

  /// Badge: too close to the Sun to be seen
  ///
  /// In en, this message translates to:
  /// **'In glare'**
  String get planetInGlare;

  /// Apparent visual magnitude
  ///
  /// In en, this message translates to:
  /// **'Magnitude'**
  String get planetMagnitude;

  /// Angular distance from the Sun
  ///
  /// In en, this message translates to:
  /// **'Elongation'**
  String get planetElongation;

  /// Label for whether the planet is an evening or morning object
  ///
  /// In en, this message translates to:
  /// **'Sky'**
  String get planetSky;

  /// Sets after the Sun, so visible in the evening
  ///
  /// In en, this message translates to:
  /// **'Evening'**
  String get planetEvening;

  /// Rises before the Sun, so visible before dawn
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get planetMorning;

  /// Distance from the Earth
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get planetDistance;

  /// Unit suffix: astronomical units
  ///
  /// In en, this message translates to:
  /// **'au'**
  String get planetAu;

  /// Height above the horizon right now
  ///
  /// In en, this message translates to:
  /// **'Altitude'**
  String get planetAltitude;

  /// Planet name
  ///
  /// In en, this message translates to:
  /// **'Mercury'**
  String get planetMercury;

  /// Planet name
  ///
  /// In en, this message translates to:
  /// **'Venus'**
  String get planetVenus;

  /// Planet name
  ///
  /// In en, this message translates to:
  /// **'Mars'**
  String get planetMars;

  /// Planet name
  ///
  /// In en, this message translates to:
  /// **'Jupiter'**
  String get planetJupiter;

  /// Planet name
  ///
  /// In en, this message translates to:
  /// **'Saturn'**
  String get planetSaturn;

  /// Planet name
  ///
  /// In en, this message translates to:
  /// **'Uranus'**
  String get planetUranus;

  /// Planet name
  ///
  /// In en, this message translates to:
  /// **'Neptune'**
  String get planetNeptune;

  /// One of the twenty-four solar terms
  ///
  /// In en, this message translates to:
  /// **'Vernal Equinox'**
  String get solarTermVernalEquinox;

  /// One of the twenty-four solar terms
  ///
  /// In en, this message translates to:
  /// **'Pure Brightness'**
  String get solarTermPureBrightness;

  /// One of the twenty-four solar terms
  ///
  /// In en, this message translates to:
  /// **'Grain Rain'**
  String get solarTermGrainRain;

  /// One of the twenty-four solar terms
  ///
  /// In en, this message translates to:
  /// **'Start of Summer'**
  String get solarTermStartOfSummer;

  /// One of the twenty-four solar terms
  ///
  /// In en, this message translates to:
  /// **'Grain Full'**
  String get solarTermGrainFull;

  /// One of the twenty-four solar terms
  ///
  /// In en, this message translates to:
  /// **'Grain in Ear'**
  String get solarTermGrainInEar;

  /// One of the twenty-four solar terms
  ///
  /// In en, this message translates to:
  /// **'Summer Solstice'**
  String get solarTermSummerSolstice;

  /// One of the twenty-four solar terms
  ///
  /// In en, this message translates to:
  /// **'Minor Heat'**
  String get solarTermMinorHeat;

  /// One of the twenty-four solar terms
  ///
  /// In en, this message translates to:
  /// **'Major Heat'**
  String get solarTermMajorHeat;

  /// One of the twenty-four solar terms
  ///
  /// In en, this message translates to:
  /// **'Start of Autumn'**
  String get solarTermStartOfAutumn;

  /// One of the twenty-four solar terms
  ///
  /// In en, this message translates to:
  /// **'End of Heat'**
  String get solarTermEndOfHeat;

  /// One of the twenty-four solar terms
  ///
  /// In en, this message translates to:
  /// **'White Dew'**
  String get solarTermWhiteDew;

  /// One of the twenty-four solar terms
  ///
  /// In en, this message translates to:
  /// **'Autumnal Equinox'**
  String get solarTermAutumnalEquinox;

  /// One of the twenty-four solar terms
  ///
  /// In en, this message translates to:
  /// **'Cold Dew'**
  String get solarTermColdDew;

  /// One of the twenty-four solar terms
  ///
  /// In en, this message translates to:
  /// **'Frost Descent'**
  String get solarTermFrostDescent;

  /// One of the twenty-four solar terms
  ///
  /// In en, this message translates to:
  /// **'Start of Winter'**
  String get solarTermStartOfWinter;

  /// One of the twenty-four solar terms
  ///
  /// In en, this message translates to:
  /// **'Minor Snow'**
  String get solarTermMinorSnow;

  /// One of the twenty-four solar terms
  ///
  /// In en, this message translates to:
  /// **'Major Snow'**
  String get solarTermMajorSnow;

  /// One of the twenty-four solar terms
  ///
  /// In en, this message translates to:
  /// **'Winter Solstice'**
  String get solarTermWinterSolstice;

  /// One of the twenty-four solar terms
  ///
  /// In en, this message translates to:
  /// **'Minor Cold'**
  String get solarTermMinorCold;

  /// One of the twenty-four solar terms
  ///
  /// In en, this message translates to:
  /// **'Major Cold'**
  String get solarTermMajorCold;

  /// One of the twenty-four solar terms
  ///
  /// In en, this message translates to:
  /// **'Start of Spring'**
  String get solarTermStartOfSpring;

  /// One of the twenty-four solar terms
  ///
  /// In en, this message translates to:
  /// **'Rain Water'**
  String get solarTermRainWater;

  /// One of the twenty-four solar terms
  ///
  /// In en, this message translates to:
  /// **'Awakening of Insects'**
  String get solarTermAwakeningOfInsects;

  /// Tonight page title
  ///
  /// In en, this message translates to:
  /// **'Tonight'**
  String get tonightTitle;

  /// Section header: the observing window
  ///
  /// In en, this message translates to:
  /// **'Observing window'**
  String get tonightSectionDark;

  /// Dusk to dawn with the Sun 18 degrees down
  ///
  /// In en, this message translates to:
  /// **'Astronomical night'**
  String get tonightAstronomicalNight;

  /// Shown when the Sun never gets 18 degrees below the horizon
  ///
  /// In en, this message translates to:
  /// **'Never fully dark'**
  String get tonightNeverDark;

  /// The longest stretch with no Sun and no Moon
  ///
  /// In en, this message translates to:
  /// **'Dark window'**
  String get tonightDarkWindow;

  /// Shown when the Moon is up for the whole night
  ///
  /// In en, this message translates to:
  /// **'Moon up all night'**
  String get tonightMoonAllNight;

  /// Total dark time, hours:minutes
  ///
  /// In en, this message translates to:
  /// **'Total dark'**
  String get tonightDarkTotal;

  /// The Moon's illuminated fraction tonight
  ///
  /// In en, this message translates to:
  /// **'Moonlight'**
  String get tonightMoonlight;

  /// Section header: meteor showers running now
  ///
  /// In en, this message translates to:
  /// **'Meteor showers'**
  String get tonightSectionShowers;

  /// The shower's radiant never rises here
  ///
  /// In en, this message translates to:
  /// **'Radiant never rises'**
  String get tonightRadiantDown;

  /// Unit: meteors per hour
  ///
  /// In en, this message translates to:
  /// **'/h'**
  String get tonightPerHour;

  /// Section header: visible satellite passes
  ///
  /// In en, this message translates to:
  /// **'Satellite passes'**
  String get tonightSectionSatellites;

  /// Section header: deep-sky objects high enough to observe
  ///
  /// In en, this message translates to:
  /// **'Targets up now'**
  String get tonightSectionTargets;

  /// Meteor shower name
  ///
  /// In en, this message translates to:
  /// **'Quadrantids'**
  String get showerQuadrantids;

  /// Meteor shower name
  ///
  /// In en, this message translates to:
  /// **'Lyrids'**
  String get showerLyrids;

  /// Meteor shower name
  ///
  /// In en, this message translates to:
  /// **'Eta Aquariids'**
  String get showerEtaAquariids;

  /// Meteor shower name
  ///
  /// In en, this message translates to:
  /// **'Delta Aquariids'**
  String get showerDeltaAquariids;

  /// Meteor shower name
  ///
  /// In en, this message translates to:
  /// **'Perseids'**
  String get showerPerseids;

  /// Meteor shower name
  ///
  /// In en, this message translates to:
  /// **'Orionids'**
  String get showerOrionids;

  /// Meteor shower name
  ///
  /// In en, this message translates to:
  /// **'Southern Taurids'**
  String get showerSouthernTaurids;

  /// Meteor shower name
  ///
  /// In en, this message translates to:
  /// **'Leonids'**
  String get showerLeonids;

  /// Meteor shower name
  ///
  /// In en, this message translates to:
  /// **'Geminids'**
  String get showerGeminids;

  /// Meteor shower name
  ///
  /// In en, this message translates to:
  /// **'Ursids'**
  String get showerUrsids;

  /// Deep-sky object type
  ///
  /// In en, this message translates to:
  /// **'Open cluster'**
  String get deepSkyOpenCluster;

  /// Deep-sky object type
  ///
  /// In en, this message translates to:
  /// **'Globular cluster'**
  String get deepSkyGlobularCluster;

  /// Deep-sky object type
  ///
  /// In en, this message translates to:
  /// **'Spiral galaxy'**
  String get deepSkySpiralGalaxy;

  /// Deep-sky object type
  ///
  /// In en, this message translates to:
  /// **'Elliptical galaxy'**
  String get deepSkyEllipticalGalaxy;

  /// Deep-sky object type
  ///
  /// In en, this message translates to:
  /// **'Irregular galaxy'**
  String get deepSkyIrregularGalaxy;

  /// Deep-sky object type
  ///
  /// In en, this message translates to:
  /// **'Planetary nebula'**
  String get deepSkyPlanetaryNebula;

  /// Deep-sky object type
  ///
  /// In en, this message translates to:
  /// **'Supernova remnant'**
  String get deepSkySupernovaRemnant;

  /// Deep-sky object type
  ///
  /// In en, this message translates to:
  /// **'Emission nebula'**
  String get deepSkyEmissionNebula;

  /// Deep-sky object type
  ///
  /// In en, this message translates to:
  /// **'Reflection nebula'**
  String get deepSkyReflectionNebula;

  /// Deep-sky object type: a star pattern, not a single object
  ///
  /// In en, this message translates to:
  /// **'Asterism'**
  String get deepSkyAsterism;

  /// Almanac page title
  ///
  /// In en, this message translates to:
  /// **'Almanac'**
  String get almanacTitle;

  /// Section header: today's date in both calendars
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get almanacSectionToday;

  /// The Gregorian date
  ///
  /// In en, this message translates to:
  /// **'Gregorian'**
  String get almanacGregorian;

  /// The lunisolar date
  ///
  /// In en, this message translates to:
  /// **'Lunisolar'**
  String get almanacLunar;

  /// The sexagenary year and its zodiac animal
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get almanacYear;

  /// Whether this lunar month has 29 or 30 days
  ///
  /// In en, this message translates to:
  /// **'Month length'**
  String get almanacMonthLength;

  /// A 30-day lunar month
  ///
  /// In en, this message translates to:
  /// **'30 days'**
  String get almanacLongMonth;

  /// A 29-day lunar month
  ///
  /// In en, this message translates to:
  /// **'29 days'**
  String get almanacShortMonth;

  /// Prefix marking an intercalary lunar month
  ///
  /// In en, this message translates to:
  /// **'Leap '**
  String get almanacLeapPrefix;

  /// Section header: upcoming lunar eclipses
  ///
  /// In en, this message translates to:
  /// **'Lunar eclipses'**
  String get almanacSectionLunarEclipses;

  /// Section header: solar eclipses visible from here
  ///
  /// In en, this message translates to:
  /// **'Solar eclipses'**
  String get almanacSectionSolarEclipses;

  /// No solar eclipse is visible from here in the search window
  ///
  /// In en, this message translates to:
  /// **'None in range'**
  String get almanacNoSolarEclipse;

  /// Eclipse type
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get eclipseTotal;

  /// Eclipse type
  ///
  /// In en, this message translates to:
  /// **'Partial'**
  String get eclipsePartial;

  /// Eclipse type: a ring of Sun remains
  ///
  /// In en, this message translates to:
  /// **'Annular'**
  String get eclipseAnnular;

  /// Eclipse type: the Moon only enters the outer shadow
  ///
  /// In en, this message translates to:
  /// **'Penumbral'**
  String get eclipsePenumbral;

  /// Chinese zodiac animal
  ///
  /// In en, this message translates to:
  /// **'Rat'**
  String get zodiacRat;

  /// Chinese zodiac animal
  ///
  /// In en, this message translates to:
  /// **'Ox'**
  String get zodiacOx;

  /// Chinese zodiac animal
  ///
  /// In en, this message translates to:
  /// **'Tiger'**
  String get zodiacTiger;

  /// Chinese zodiac animal
  ///
  /// In en, this message translates to:
  /// **'Rabbit'**
  String get zodiacRabbit;

  /// Chinese zodiac animal
  ///
  /// In en, this message translates to:
  /// **'Dragon'**
  String get zodiacDragon;

  /// Chinese zodiac animal
  ///
  /// In en, this message translates to:
  /// **'Snake'**
  String get zodiacSnake;

  /// Chinese zodiac animal
  ///
  /// In en, this message translates to:
  /// **'Horse'**
  String get zodiacHorse;

  /// Chinese zodiac animal
  ///
  /// In en, this message translates to:
  /// **'Goat'**
  String get zodiacGoat;

  /// Chinese zodiac animal
  ///
  /// In en, this message translates to:
  /// **'Monkey'**
  String get zodiacMonkey;

  /// Chinese zodiac animal
  ///
  /// In en, this message translates to:
  /// **'Rooster'**
  String get zodiacRooster;

  /// Chinese zodiac animal
  ///
  /// In en, this message translates to:
  /// **'Dog'**
  String get zodiacDog;

  /// Chinese zodiac animal
  ///
  /// In en, this message translates to:
  /// **'Pig'**
  String get zodiacPig;

  /// Tide page title
  ///
  /// In en, this message translates to:
  /// **'Tide'**
  String get tideTitle;

  /// Says plainly that this is the astronomical forcing, not a harbour tide table
  ///
  /// In en, this message translates to:
  /// **'Astronomical forcing only — not a harbour tide table. For water levels use the CWA\'s published tables.'**
  String get tideDisclaimer;

  /// Section header: the tide-raising force right now
  ///
  /// In en, this message translates to:
  /// **'Right now'**
  String get tideSectionNow;

  /// Where in the spring-neap cycle the tide sits
  ///
  /// In en, this message translates to:
  /// **'Cycle'**
  String get tidePhase;

  /// Spring tide: Sun and Moon aligned
  ///
  /// In en, this message translates to:
  /// **'Spring'**
  String get tideSpring;

  /// Neap tide: Sun and Moon at right angles
  ///
  /// In en, this message translates to:
  /// **'Neap'**
  String get tideNeap;

  /// Between spring and neap
  ///
  /// In en, this message translates to:
  /// **'Middling'**
  String get tideMiddling;

  /// How much stronger the Moon's pull is than at mean distance
  ///
  /// In en, this message translates to:
  /// **'Lunar pull'**
  String get tideLunarDistanceFactor;

  /// The equilibrium tide height
  ///
  /// In en, this message translates to:
  /// **'Equilibrium tide'**
  String get tideEquilibrium;

  /// Unit: metres
  ///
  /// In en, this message translates to:
  /// **'m'**
  String get tideMetres;

  /// The next spring tide at lunar perigee - the highest water
  ///
  /// In en, this message translates to:
  /// **'Next perigean spring'**
  String get tidePerigeanSpring;

  /// Section header: when the forcing peaks and troughs
  ///
  /// In en, this message translates to:
  /// **'Turning points'**
  String get tideSectionTurningPoints;

  /// A high point of the tidal forcing
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get tideHigh;

  /// A low point of the tidal forcing
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get tideLow;

  /// Sky chart page title
  ///
  /// In en, this message translates to:
  /// **'Sky chart'**
  String get skyChartTitle;

  /// Compass point on the sky chart
  ///
  /// In en, this message translates to:
  /// **'N'**
  String get skyChartNorth;

  /// Compass point on the sky chart
  ///
  /// In en, this message translates to:
  /// **'E'**
  String get skyChartEast;

  /// Compass point on the sky chart
  ///
  /// In en, this message translates to:
  /// **'S'**
  String get skyChartSouth;

  /// Compass point on the sky chart
  ///
  /// In en, this message translates to:
  /// **'W'**
  String get skyChartWest;

  /// How old the bundled satellite element set is, in days
  ///
  /// In en, this message translates to:
  /// **'elements {days} d old'**
  String tonightElementAge(int days);

  /// A lunisolar date: an optional leap marker, the month and the day
  ///
  /// In en, this message translates to:
  /// **'{leap}month {month}, day {day}'**
  String almanacLunarDate(String leap, int month, int day);

  /// Shown when no meteor shower is running today
  ///
  /// In en, this message translates to:
  /// **'No shower running'**
  String get tonightNoShowers;

  /// Shown when no satellite pass is visible in the next two days
  ///
  /// In en, this message translates to:
  /// **'No visible pass in 48 h'**
  String get tonightNoPasses;

  /// Shown when the bundled element set could not be read
  ///
  /// In en, this message translates to:
  /// **'Orbit data unavailable'**
  String get tonightSatellitesUnavailable;

  /// Shown when nothing in the catalogue is high enough tonight
  ///
  /// In en, this message translates to:
  /// **'Nothing high enough'**
  String get tonightNoTargets;

  /// Shown when the bundled star catalogue could not be read
  ///
  /// In en, this message translates to:
  /// **'Star catalogue unavailable'**
  String get skyChartUnavailable;

  /// Dialog title: the permission must be granted in system settings
  ///
  /// In en, this message translates to:
  /// **'Grant it in Settings'**
  String get permissionSettingsTitle;

  /// Reassures the user they can come back and that the app re-checks on return
  ///
  /// In en, this message translates to:
  /// **'The app checks again when you come back.'**
  String get permissionSettingsHint;

  /// Button that opens the system settings page
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get permissionOpenSettings;

  /// Explains that the system will not ask again for this permission
  ///
  /// In en, this message translates to:
  /// **'“{what}” was declined, and the system will not ask again. Turn it on in Settings.'**
  String permissionSettingsMessage(String what);

  /// No description provided for @permissionGuideNotification.
  ///
  /// In en, this message translates to:
  /// **'Open System Settings to allow notifications.'**
  String get permissionGuideNotification;

  /// No description provided for @permissionGuideForegroundLocation.
  ///
  /// In en, this message translates to:
  /// **'Open System Settings to allow precise location.'**
  String get permissionGuideForegroundLocation;

  /// Instruction for background location
  ///
  /// In en, this message translates to:
  /// **'In “{option}”, choose “Allow all the time”.'**
  String permissionGuideBackgroundLocation(Object option);

  /// No description provided for @permissionGuideBackgroundExecution.
  ///
  /// In en, this message translates to:
  /// **'Allow background execution in System Settings so notifications are not paused.'**
  String get permissionGuideBackgroundExecution;

  /// No description provided for @permissionGuideUnusedPause.
  ///
  /// In en, this message translates to:
  /// **'If the app is marked “unused”, choose “Allow” in System Settings.'**
  String get permissionGuideUnusedPause;

  /// No description provided for @permissionGuideUnusedFreeSpace.
  ///
  /// In en, this message translates to:
  /// **'If the app was paused for storage, clear cache and reopen it.'**
  String get permissionGuideUnusedFreeSpace;

  /// No description provided for @permissionGuideUnusedRevoke.
  ///
  /// In en, this message translates to:
  /// **'If the app\'s permissions were revoked, grant them again in System Settings.'**
  String get permissionGuideUnusedRevoke;

  /// No description provided for @permissionGuideUnusedPlayProtect.
  ///
  /// In en, this message translates to:
  /// **'If Play Protect paused the app, check its status in Google Play.'**
  String get permissionGuideUnusedPlayProtect;

  /// Instruction for vendor power saving
  ///
  /// In en, this message translates to:
  /// **'In “{vendor}” power-saving settings, set this app to “Unrestricted”.'**
  String permissionGuideVendorPower(Object vendor);

  /// No description provided for @permissionStillRequired.
  ///
  /// In en, this message translates to:
  /// **'Still needs attention. Check the highlighted option in Settings.'**
  String get permissionStillRequired;

  /// No description provided for @permissionVerifyManually.
  ///
  /// In en, this message translates to:
  /// **'Please verify this permission is enabled in System Settings.'**
  String get permissionVerifyManually;

  /// No description provided for @permissionBackgroundLocationOption.
  ///
  /// In en, this message translates to:
  /// **'“Allow all the time”'**
  String get permissionBackgroundLocationOption;

  /// Display settings: text size section header
  ///
  /// In en, this message translates to:
  /// **'Text size'**
  String get displayTextSize;

  /// Display settings: what the text size control affects
  ///
  /// In en, this message translates to:
  /// **'Applies to the app interface — map labels keep their own size.'**
  String get displayTextSizeDesc;

  /// Display settings: text weight section header
  ///
  /// In en, this message translates to:
  /// **'Text weight'**
  String get displayTextWeight;

  /// Display settings: what the text weight control does
  ///
  /// In en, this message translates to:
  /// **'Bolder text can be easier to read.'**
  String get displayTextWeightDesc;

  /// Display settings: contrast section header
  ///
  /// In en, this message translates to:
  /// **'Contrast'**
  String get displayContrast;

  /// Display settings: what the contrast control does
  ///
  /// In en, this message translates to:
  /// **'Higher contrast separates text from its background.'**
  String get displayContrastDesc;

  /// Display settings: colour-vision section header
  ///
  /// In en, this message translates to:
  /// **'Colour vision'**
  String get displayColorVision;

  /// Display settings: what the colour-vision control recolours
  ///
  /// In en, this message translates to:
  /// **'Recolours the whole app, including map colours.'**
  String get displayColorVisionDesc;

  /// Display settings option: displayColorVisionNone
  ///
  /// In en, this message translates to:
  /// **'Standard colours'**
  String get displayColorVisionNone;

  /// Display settings option: displayColorVisionProtan
  ///
  /// In en, this message translates to:
  /// **'Red-weak (protanopia)'**
  String get displayColorVisionProtan;

  /// Display settings option: displayColorVisionDeutan
  ///
  /// In en, this message translates to:
  /// **'Green-weak (deuteranopia)'**
  String get displayColorVisionDeutan;

  /// Display settings option: displayColorVisionTritan
  ///
  /// In en, this message translates to:
  /// **'Blue-yellow weak (tritanopia)'**
  String get displayColorVisionTritan;

  /// Section header above the live sample on the Display settings page. Marks the mock earthquake report as an example, not a real event — must never read as 'live' or 'current'.
  ///
  /// In en, this message translates to:
  /// **'Sample earthquake report'**
  String get displayPreviewSample;

  /// Display settings option: displayScaleSmall
  ///
  /// In en, this message translates to:
  /// **'Small'**
  String get displayScaleSmall;

  /// Display settings option: displayScaleDefault
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get displayScaleDefault;

  /// Display settings option: displayScaleLarge
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get displayScaleLarge;

  /// Display settings option: displayScaleHuge
  ///
  /// In en, this message translates to:
  /// **'Extra large'**
  String get displayScaleHuge;

  /// Display settings option: displayWeightNormal
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get displayWeightNormal;

  /// Display settings option: displayWeightMedium
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get displayWeightMedium;

  /// Display settings option: displayWeightBold
  ///
  /// In en, this message translates to:
  /// **'Bold'**
  String get displayWeightBold;

  /// Display settings option: displayContrastStandard
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get displayContrastStandard;

  /// Display settings option: displayContrastMedium
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get displayContrastMedium;

  /// Display settings option: displayContrastHigh
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get displayContrastHigh;

  /// Node is a direct neighbour (0 hops)
  ///
  /// In en, this message translates to:
  /// **'Direct'**
  String get meshtasticDirect;

  /// How many relays away a node is
  ///
  /// In en, this message translates to:
  /// **'{n} hops'**
  String meshtasticHopsAway(int n);

  /// Radio stat tile
  ///
  /// In en, this message translates to:
  /// **'Relayed for others'**
  String get meshtasticStatRelayShare;

  /// Radio stat tile
  ///
  /// In en, this message translates to:
  /// **'Share of what this radio sent'**
  String get meshtasticStatRelayShareHint;

  /// Radio stat tile
  ///
  /// In en, this message translates to:
  /// **'Relays completed'**
  String get meshtasticStatRelayValue;

  /// Radio stat tile
  ///
  /// In en, this message translates to:
  /// **'Often the only path — the mesh leans on this node'**
  String get meshtasticStatRelaySolePath;

  /// Radio stat tile
  ///
  /// In en, this message translates to:
  /// **'Others cover the same hops'**
  String get meshtasticStatRelayRedundant;

  /// Radio stat tile
  ///
  /// In en, this message translates to:
  /// **'Duplicate receptions'**
  String get meshtasticStatRedundancy;

  /// Radio stat tile
  ///
  /// In en, this message translates to:
  /// **'Few spare paths — one relay failing could cut you off'**
  String get meshtasticStatThinEdge;

  /// Radio stat tile
  ///
  /// In en, this message translates to:
  /// **'Several paths reach here'**
  String get meshtasticStatWellCovered;

  /// Radio stat tile
  ///
  /// In en, this message translates to:
  /// **'Corrupt receptions'**
  String get meshtasticStatErrorRate;

  /// Radio stat tile
  ///
  /// In en, this message translates to:
  /// **'Rising while airtime is flat means interference'**
  String get meshtasticStatErrorRateHint;

  /// Sheet action: ask the mesh how this node is reached
  ///
  /// In en, this message translates to:
  /// **'Trace route'**
  String get meshtasticTraceRoute;

  /// Sheet button while a traceroute probe is in flight
  ///
  /// In en, this message translates to:
  /// **'Tracing…'**
  String get meshtasticTracing;

  /// Traceroute outcome when the reply decoded to nothing usable
  ///
  /// In en, this message translates to:
  /// **'Unreadable reply'**
  String get meshtasticTraceUnreadable;

  /// Why the traceroute button is disabled — no radio link
  ///
  /// In en, this message translates to:
  /// **'Radio not connected'**
  String get meshtasticTraceOffline;

  /// Why the traceroute button is counting down
  ///
  /// In en, this message translates to:
  /// **'Radio limits this to once every 30 s'**
  String get meshtasticTraceCooldown;

  /// Traceroute outcome when the destination never answers
  ///
  /// In en, this message translates to:
  /// **'No reply — out of range or on another channel key'**
  String get meshtasticTraceNoReply;

  /// Traceroute outcome for a one-hop route
  ///
  /// In en, this message translates to:
  /// **'Direct — no relays between'**
  String get meshtasticTraceDirect;

  /// Traceroute outcome hop count
  ///
  /// In en, this message translates to:
  /// **'{n} hops'**
  String meshtasticTraceHops(int n);

  /// More menu row that uploads a debug dump
  ///
  /// In en, this message translates to:
  /// **'Dump debug info and logs'**
  String get moreDumpDiagnostics;

  /// Subtitle of the debug-dump row
  ///
  /// In en, this message translates to:
  /// **'Uploads them and copies a link to paste into a report'**
  String get moreDumpDiagnosticsHint;

  /// Unchecked-by-default consent for private diagnostics
  ///
  /// In en, this message translates to:
  /// **'Include precise location'**
  String get dumpIncludeSensitive;

  /// Explains which diagnostics require explicit consent
  ///
  /// In en, this message translates to:
  /// **'Includes coordinates from logs and background location; otherwise they are replaced with null'**
  String get dumpIncludeSensitiveHint;

  /// Button that confirms a diagnostics upload
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get dumpUpload;

  /// Title of the dialog shown after a debug dump uploads
  ///
  /// In en, this message translates to:
  /// **'Uploaded'**
  String get dumpUploaded;

  /// Says the uploaded dump link is already on the clipboard
  ///
  /// In en, this message translates to:
  /// **'The link is on your clipboard'**
  String get dumpLinkCopied;

  /// Button that copies the dump link to the clipboard again
  ///
  /// In en, this message translates to:
  /// **'Copy again'**
  String get dumpCopyAgain;

  /// Shown when a debug dump could not be uploaded
  ///
  /// In en, this message translates to:
  /// **'Upload failed — try again'**
  String get dumpUploadFailed;

  /// No description provided for @statusLegendUnprobed.
  ///
  /// In en, this message translates to:
  /// **'Not yet probed'**
  String get statusLegendUnprobed;

  /// No description provided for @statusLegendUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Not offered'**
  String get statusLegendUnsupported;

  /// Menu section header for the rainfall colour-scale interval choice
  ///
  /// In en, this message translates to:
  /// **'Colour scale'**
  String get rainScaleSection;

  /// Rainfall colour scale option: close-spaced thresholds (1-300 mm), for short accumulation windows
  ///
  /// In en, this message translates to:
  /// **'Fine'**
  String get rainScaleFine;

  /// Rainfall colour scale option: wide-spaced thresholds (10-1500 mm), for multi-day totals
  ///
  /// In en, this message translates to:
  /// **'Coarse'**
  String get rainScaleCoarse;

  /// Title of the page that sends sample notifications
  ///
  /// In en, this message translates to:
  /// **'Test notifications'**
  String get notifyTestTitle;

  /// Explains that a tap fires a real alert, and warns that major alerts ignore silent mode
  ///
  /// In en, this message translates to:
  /// **'Tapping a row sends that alert for real. Major alerts play at full volume and sound through the silent switch and Do Not Disturb.'**
  String get notifyTestIntro;

  /// Shown on iOS when the critical-alert permission was refused
  ///
  /// In en, this message translates to:
  /// **'Critical alerts aren\'t allowed on this device, so major alerts stay silent when your phone is.'**
  String get notifyTestCriticalDenied;

  /// Shown when notification permission is not granted, so a test does nothing
  ///
  /// In en, this message translates to:
  /// **'Notifications are turned off, so a test won\'t show anything.'**
  String get notifyTestPermissionOff;

  /// Channel behaviour: sounds through silent mode and Do Not Disturb
  ///
  /// In en, this message translates to:
  /// **'Sounds through silent and Do Not Disturb'**
  String get notifyTestBehaviourOverrides;

  /// Channel behaviour: sound plus a heads-up banner, but the silent switch still applies
  ///
  /// In en, this message translates to:
  /// **'Sound and a banner, unless your phone is silenced'**
  String get notifyTestBehaviourAlerts;

  /// Channel behaviour: sound but no banner, and the silent switch still applies
  ///
  /// In en, this message translates to:
  /// **'Sound but no banner, unless your phone is silenced'**
  String get notifyTestBehaviourSounds;

  /// Channel behaviour: no sound, appears only in the notification list
  ///
  /// In en, this message translates to:
  /// **'Silent — notification list only'**
  String get notifyTestBehaviourSilent;

  /// Snackbar shown when the test notification could not be posted
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t send the test notification.'**
  String get notifyTestFailed;

  /// Title of the read-only reported-bugs screen and its More-tab entry
  ///
  /// In en, this message translates to:
  /// **'Bug reports'**
  String get moreBugReports;

  /// Shown when the bug-tracker index has no threads
  ///
  /// In en, this message translates to:
  /// **'No reported bugs yet'**
  String get bugTrackerEmpty;

  /// Header above the reply thread on a bug detail page
  ///
  /// In en, this message translates to:
  /// **'Replies'**
  String get bugTrackerReplies;

  /// Call-to-action above the bug list, linking to the Discord report channel
  ///
  /// In en, this message translates to:
  /// **'Can\'t find your issue? Report it on Discord!'**
  String get bugTrackerGoToDiscord;

  /// Shown when the active tag filters match no thread
  ///
  /// In en, this message translates to:
  /// **'No threads match the selected tags'**
  String get bugTrackerNoMatch;

  /// Badge beside staff names on bug threads
  ///
  /// In en, this message translates to:
  /// **'Developer'**
  String get bugTrackerDeveloper;

  /// Placeholder for a reply whose text is unavailable
  ///
  /// In en, this message translates to:
  /// **'This content can\'t be displayed here — view it on Discord'**
  String get bugTrackerCannotDisplay;

  /// Button handing discussion back to Discord
  ///
  /// In en, this message translates to:
  /// **'Join the discussion on Discord'**
  String get bugTrackerJoinDiscussion;

  /// Sort chip: threads with the most recent reply first
  ///
  /// In en, this message translates to:
  /// **'Latest activity'**
  String get bugTrackerSortLast;

  /// Sort chip: threads with the most replies first
  ///
  /// In en, this message translates to:
  /// **'Most discussed'**
  String get bugTrackerSortMostDiscussed;

  /// Badge beside triage-team names on bug threads
  ///
  /// In en, this message translates to:
  /// **'Staff'**
  String get bugTrackerStaff;

  /// Short foreground TTS phrase before an EEW warning sound
  ///
  /// In en, this message translates to:
  /// **'Estimated intensity at your location: {intensity}.'**
  String eewSpokenLocalIntensity(String intensity);

  /// TTS fallback when the device location is unavailable
  ///
  /// In en, this message translates to:
  /// **'Estimated maximum intensity: {intensity}.'**
  String eewSpokenMaxIntensity(String intensity);
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
    'yue',
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

  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.countryCode) {
          case 'TW':
            return AppLocalizationsZhTw();
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
    case 'yue':
      return AppLocalizationsYue();
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
