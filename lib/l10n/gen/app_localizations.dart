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
    Locale('zh', 'TW'),
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

  /// Bottom-nav label and page title for the Data hub tab
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get navData;

  /// Earthquake report catalogue title (entry under the Data hub)
  ///
  /// In en, this message translates to:
  /// **'Earthquake'**
  String get navEarthquake;

  /// Section header on the Data hub for earthquake-related entries
  ///
  /// In en, this message translates to:
  /// **'Seismic'**
  String get dataSectionSeismic;

  /// Subtitle under the Earthquake tile on the Data hub
  ///
  /// In en, this message translates to:
  /// **'Earthquake reports'**
  String get dataEarthquakeSubtitle;

  /// Section header on the Data hub for weather observation rankings
  ///
  /// In en, this message translates to:
  /// **'Weather'**
  String get dataSectionWeather;

  /// Subtitle under weather ranking tiles on the Data hub
  ///
  /// In en, this message translates to:
  /// **'Live station rankings'**
  String get dataWeatherRankingSubtitle;

  /// App bar title for the weather station ranking page
  ///
  /// In en, this message translates to:
  /// **'Observation rankings'**
  String get weatherRankingTitle;

  /// Snapshot time and station count above a ranking list
  ///
  /// In en, this message translates to:
  /// **'Data time: {time}\n{count} stations'**
  String weatherRankingMeta(String time, int count);

  /// Empty state when a ranking list has no rows after filters
  ///
  /// In en, this message translates to:
  /// **'No observations to rank'**
  String get weatherRankingEmpty;

  /// Label before highest/lowest (or desc/asc) chips on ranking
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get weatherRankingBy;

  /// Chip to rank temperature descending
  ///
  /// In en, this message translates to:
  /// **'Highest'**
  String get weatherRankingHighest;

  /// Chip to rank temperature ascending
  ///
  /// In en, this message translates to:
  /// **'Lowest'**
  String get weatherRankingLowest;

  /// Label before township/county merge chips on ranking
  ///
  /// In en, this message translates to:
  /// **'Merge to'**
  String get weatherRankingMergeTo;

  /// Chip to keep one extreme station per township
  ///
  /// In en, this message translates to:
  /// **'Township'**
  String get weatherRankingMergeTown;

  /// Chip to keep one extreme station per county
  ///
  /// In en, this message translates to:
  /// **'County'**
  String get weatherRankingMergeCounty;

  /// Ranking tab/tile for sustained wind speed
  ///
  /// In en, this message translates to:
  /// **'Wind speed'**
  String get weatherRankingWind;

  /// Ranking tab/tile for peak gust speed
  ///
  /// In en, this message translates to:
  /// **'Gust'**
  String get weatherRankingGust;

  /// Ranking tab for recorded daily high/low/range (not current temp)
  ///
  /// In en, this message translates to:
  /// **'Daily extremes'**
  String get weatherRankingTempExtremes;

  /// Chip to rank by recorded daily maximum temperature
  ///
  /// In en, this message translates to:
  /// **'Daily high'**
  String get weatherRankingExtremeHigh;

  /// Chip to rank by recorded daily minimum temperature
  ///
  /// In en, this message translates to:
  /// **'Daily low'**
  String get weatherRankingExtremeLow;

  /// Chip to rank by daily high minus low
  ///
  /// In en, this message translates to:
  /// **'Diurnal range'**
  String get weatherRankingExtremeRange;

  /// Occurrence time for a gust or daily extreme
  ///
  /// In en, this message translates to:
  /// **'Recorded at {time}'**
  String weatherRankingRecordedAt(String time);

  /// Current temperature fragment in an extremes analysis line
  ///
  /// In en, this message translates to:
  /// **'Now {value}°C'**
  String weatherRankingAnalysisCurrent(String value);

  /// Daily high fragment; value may include clock time
  ///
  /// In en, this message translates to:
  /// **'High {value}'**
  String weatherRankingAnalysisHigh(String value);

  /// Daily low fragment; value may include clock time
  ///
  /// In en, this message translates to:
  /// **'Low {value}'**
  String weatherRankingAnalysisLow(String value);

  /// Diurnal range fragment in an extremes analysis line
  ///
  /// In en, this message translates to:
  /// **'Range {value}°C'**
  String weatherRankingAnalysisRange(String value);

  /// Empty state when the report catalogue has no rows
  ///
  /// In en, this message translates to:
  /// **'No earthquake reports'**
  String get reportListEmpty;

  /// Empty state when active filters yield no report rows
  ///
  /// In en, this message translates to:
  /// **'No earthquake reports match these filters'**
  String get reportListEmptyFiltered;

  /// Magnitude and depth line on a report list row
  ///
  /// In en, this message translates to:
  /// **'M{magnitude} · {depth} km'**
  String reportListMeta(String magnitude, String depth);

  /// Emphasized magnitude on a report list row
  ///
  /// In en, this message translates to:
  /// **'M{magnitude}'**
  String reportListMagnitude(String magnitude);

  /// Depth unit label beside the depth value on a report list row
  ///
  /// In en, this message translates to:
  /// **'km'**
  String get reportListDepthUnit;

  /// Label for …000 serial reports (small-area felt quake, no CWA number)
  ///
  /// In en, this message translates to:
  /// **'Local felt'**
  String get reportListLocalFelt;

  /// Date section header for reports that originated today (Taipei)
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get reportListToday;

  /// Date section header for reports that originated yesterday (Taipei)
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get reportListYesterday;

  /// Number of reports in a day section
  ///
  /// In en, this message translates to:
  /// **'{count}'**
  String reportListDayCount(int count);

  /// Footer when the report catalogue has no further pages
  ///
  /// In en, this message translates to:
  /// **'End of list'**
  String get reportListEnd;

  /// Title of the earthquake report filter sheet
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get reportFilterTitle;

  /// Section title for report list sort field + order
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get reportFilterSort;

  /// Sort reports by origin time
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get reportFilterSortTime;

  /// Sort reports by max intensity
  ///
  /// In en, this message translates to:
  /// **'Intensity'**
  String get reportFilterSortIntensity;

  /// Sort reports by magnitude
  ///
  /// In en, this message translates to:
  /// **'Magnitude'**
  String get reportFilterSortMagnitude;

  /// Sort reports by hypocentral depth
  ///
  /// In en, this message translates to:
  /// **'Depth'**
  String get reportFilterSortDepth;

  /// Sort order: newest / largest first
  ///
  /// In en, this message translates to:
  /// **'Descending'**
  String get reportFilterOrderDesc;

  /// Sort order: oldest / smallest first
  ///
  /// In en, this message translates to:
  /// **'Ascending'**
  String get reportFilterOrderAsc;

  /// Label for the felt-intensity range filter
  ///
  /// In en, this message translates to:
  /// **'Intensity'**
  String get reportFilterIntensity;

  /// Title of the dialog explaining CWA 新制 vs 舊制 intensity
  ///
  /// In en, this message translates to:
  /// **'Intensity scales'**
  String get reportFilterIntensityInfoTitle;

  /// Intro paragraph for the intensity-scale info dialog
  ///
  /// In en, this message translates to:
  /// **'CWA changed the felt-intensity scale on 1 Jan 2020 (Taipei time).'**
  String get reportFilterIntensityInfoIntro;

  /// No description provided for @reportFilterIntensityInfoLegacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Legacy (before 2020)'**
  String get reportFilterIntensityInfoLegacyTitle;

  /// No description provided for @reportFilterIntensityInfoLegacyBody.
  ///
  /// In en, this message translates to:
  /// **'Only levels 0–7. No 5− / 5+ / 6− / 6+ split.'**
  String get reportFilterIntensityInfoLegacyBody;

  /// No description provided for @reportFilterIntensityInfoModernTitle.
  ///
  /// In en, this message translates to:
  /// **'Current (from 2020)'**
  String get reportFilterIntensityInfoModernTitle;

  /// No description provided for @reportFilterIntensityInfoModernBody.
  ///
  /// In en, this message translates to:
  /// **'Levels 0–4, 5−, 5+, 6−, 6+, and 7. The filter slider uses this scale; older events still show legacy labels in the list.'**
  String get reportFilterIntensityInfoModernBody;

  /// Label for the magnitude range filter
  ///
  /// In en, this message translates to:
  /// **'Magnitude'**
  String get reportFilterMagnitude;

  /// Label for the hypocentral-depth range filter
  ///
  /// In en, this message translates to:
  /// **'Depth'**
  String get reportFilterDepth;

  /// Depth value with unit in the filter sheet
  ///
  /// In en, this message translates to:
  /// **'{depth} km'**
  String reportFilterDepthKm(String depth);

  /// Label for the origin-time date-range filter
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get reportFilterDate;

  /// Button to open the date-range picker when none selected
  ///
  /// In en, this message translates to:
  /// **'Pick dates'**
  String get reportFilterDatePick;

  /// Explains that startTime covers from midnight on that calendar day
  ///
  /// In en, this message translates to:
  /// **'Start day: from 00:00 (Taipei)'**
  String get reportFilterDateStartNote;

  /// Explains that endTime covers through the end of that calendar day
  ///
  /// In en, this message translates to:
  /// **'End day: through 24:00 (Taipei)'**
  String get reportFilterDateEndNote;

  /// Displays a selected filter range (intensity, magnitude, depth, or dates)
  ///
  /// In en, this message translates to:
  /// **'{start} – {end}'**
  String reportFilterRange(String start, String end);

  /// Label for the location keyword filter field
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get reportFilterLocation;

  /// Hint for the location keyword filter field
  ///
  /// In en, this message translates to:
  /// **'e.g. Hualien, offshore'**
  String get reportFilterLocationHint;

  /// Chip / slider label meaning no filter applied
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get reportFilterAny;

  /// Primary button on the report filter sheet — saves draft and searches
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get reportFilterApply;

  /// Clears all filters in the report filter sheet
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reportFilterReset;

  /// Fetches the report list with the current draft filters
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get reportListSearch;

  /// Header title over the report detail map's back button
  ///
  /// In en, this message translates to:
  /// **'Earthquake Report'**
  String get reportDetailTitle;

  /// Eyebrow label on the detail header for a numbered CWA report
  ///
  /// In en, this message translates to:
  /// **'No. {number} Significant Earthquake'**
  String reportDetailNumbered(String number);

  /// Eyebrow label on the detail header for a …000 (unnumbered) report
  ///
  /// In en, this message translates to:
  /// **'Local Felt Earthquake'**
  String get reportDetailLocalFelt;

  /// Section header over origin time / epicenter / magnitude / depth
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get reportDetailInfo;

  /// Row label for the report's origin date/time
  ///
  /// In en, this message translates to:
  /// **'Origin time'**
  String get reportDetailOriginTime;

  /// Row label for the epicenter's latitude/longitude
  ///
  /// In en, this message translates to:
  /// **'Epicenter'**
  String get reportDetailEpicenter;

  /// Row label for the report's magnitude
  ///
  /// In en, this message translates to:
  /// **'Magnitude'**
  String get reportDetailMagnitude;

  /// Row label for the report's hypocentral depth
  ///
  /// In en, this message translates to:
  /// **'Depth'**
  String get reportDetailDepth;

  /// Section header over the per-area/town felt-intensity breakdown
  ///
  /// In en, this message translates to:
  /// **'Intensity by area'**
  String get reportDetailAreaIntensity;

  /// Section header over the per-location (GPS + saved townships) felt-intensity readout, shown above the area breakdown
  ///
  /// In en, this message translates to:
  /// **'Intensity at your locations'**
  String get reportDetailLocalIntensity;

  /// Shown in place of an intensity badge when a location's county isn't in this report's felt-area list at all
  ///
  /// In en, this message translates to:
  /// **'No intensity data'**
  String get reportDetailLocalIntensityUnavailable;

  /// Tooltip on the area-intensity sort toggle when tapping it switches to grouping by intensity level
  ///
  /// In en, this message translates to:
  /// **'Sort by intensity'**
  String get reportDetailSortByIntensity;

  /// Tooltip on the area-intensity sort toggle when tapping it switches to an alphabetical county list
  ///
  /// In en, this message translates to:
  /// **'Sort by county'**
  String get reportDetailSortByCounty;

  /// Section header over the CWA-rendered report image
  ///
  /// In en, this message translates to:
  /// **'Report image'**
  String get reportDetailImage;

  /// Shown in place of the report image when it fails to load
  ///
  /// In en, this message translates to:
  /// **'Report image not available'**
  String get reportDetailImageUnavailable;

  /// Button that opens the official CWA report page in a browser
  ///
  /// In en, this message translates to:
  /// **'Report page'**
  String get reportDetailOpenReport;

  /// Button that opens the RTS/EEW replay starting from this report's origin time
  ///
  /// In en, this message translates to:
  /// **'Replay'**
  String get reportDetailReplay;

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

  /// More-menu entry and page title for GitHub release notes
  ///
  /// In en, this message translates to:
  /// **'Changelog'**
  String get changelogTitle;

  /// Empty state when the releases API returns nothing
  ///
  /// In en, this message translates to:
  /// **'No release notes yet'**
  String get changelogEmpty;

  /// Chip label for a pre-release
  ///
  /// In en, this message translates to:
  /// **'Beta'**
  String get changelogTypePrerelease;

  /// Chip label for a stable release
  ///
  /// In en, this message translates to:
  /// **'Stable'**
  String get changelogTypeStable;

  /// Chip/badge when a release matches the installed app version
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get changelogCurrentVersion;

  /// App bar title on a single release's detail page
  ///
  /// In en, this message translates to:
  /// **'Release details'**
  String get changelogVersionDetails;

  /// Placeholder when a GitHub release has an empty markdown body
  ///
  /// In en, this message translates to:
  /// **'No notes for this release.'**
  String get changelogBodyEmpty;

  /// Placeholder shown in place of the map while MapLibre is disabled
  ///
  /// In en, this message translates to:
  /// **'Map (temporarily disabled)'**
  String get mapPlaceholderDisabled;

  /// Section header on the More page for saved regions
  ///
  /// In en, this message translates to:
  /// **'Region'**
  String get moreSectionRegion;

  /// Section header on the More page for notification settings
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get moreSectionNotify;

  /// Section header on the More page for language and theme
  ///
  /// In en, this message translates to:
  /// **'Display'**
  String get moreSectionDisplay;

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

  /// Edit action on a saved-region bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get regionEdit;

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

  /// Section title for the home sheet township hourly forecast
  ///
  /// In en, this message translates to:
  /// **'24-hour forecast'**
  String get homeForecastTitle;

  /// 24h forecast series high and low air temperatures
  ///
  /// In en, this message translates to:
  /// **'H {high}° · L {low}°'**
  String homeForecastHighLow(String high, String low);

  /// Probability of precipitation percent on a forecast hour chip
  ///
  /// In en, this message translates to:
  /// **'{pop}%'**
  String homeForecastPop(String pop);

  /// Apparent temperature for the selected forecast hour
  ///
  /// In en, this message translates to:
  /// **'Feels like {temp}°'**
  String homeForecastFeelsLike(String temp);

  /// Relative humidity for the selected forecast hour
  ///
  /// In en, this message translates to:
  /// **'Humidity {value}%'**
  String homeForecastHumidity(String value);

  /// Wind direction string and Beaufort force for the selected hour
  ///
  /// In en, this message translates to:
  /// **'{direction} · Force {level}'**
  String homeForecastWind(String direction, String level);

  /// Shown when no township code is available for the forecast API
  ///
  /// In en, this message translates to:
  /// **'Select a township to see the forecast'**
  String get homeForecastUnavailable;

  /// Empty or failed forecast on the home sheet
  ///
  /// In en, this message translates to:
  /// **'No forecast available'**
  String get homeForecastEmpty;

  /// Section title for currently active disaster notices on the collapsed home sheet
  ///
  /// In en, this message translates to:
  /// **'Active events'**
  String get homeActiveEventsTitle;

  /// Empty state when the realtime event feed has nothing in effect
  ///
  /// In en, this message translates to:
  /// **'No active events'**
  String get homeActiveEventsEmpty;

  /// Section title for the home sheet 1-hour per-minute rainfall bar chart
  ///
  /// In en, this message translates to:
  /// **'Next hour precipitation'**
  String get homeRainTrendTitle;

  /// X-axis tick label on the home rain trend chart, minutes from now
  ///
  /// In en, this message translates to:
  /// **'{minute} min'**
  String homeRainTrendMinute(int minute);

  /// Data-update time beside the home rain trend title, Taipei wall clock HH:mm
  ///
  /// In en, this message translates to:
  /// **'Updated {time}'**
  String homeRainTrendUpdated(String time);

  /// Label on the home rain trend chart for minutes beyond the forecast window, and the empty-card hint
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get homeRainTrendNoData;

  /// Home rain trend subtitle: peak intensity below the light-rain threshold
  ///
  /// In en, this message translates to:
  /// **'Light showers possible'**
  String get homeRainTrendScattered;

  /// Home rain trend subtitle: light rain that keeps up through the hour
  ///
  /// In en, this message translates to:
  /// **'Light rain continuing for the next hour'**
  String get homeRainTrendLightSustained;

  /// Home rain trend subtitle: light rain forecast to stop partway through the hour
  ///
  /// In en, this message translates to:
  /// **'Light rain likely to stop in {minutes} minutes'**
  String homeRainTrendLightStopping(int minutes);

  /// Home rain trend subtitle: heavy rain that keeps up through the hour
  ///
  /// In en, this message translates to:
  /// **'Heavy rain continuing for the next hour'**
  String get homeRainTrendHeavySustained;

  /// Home rain trend subtitle: heavy rain forecast to stop partway through the hour
  ///
  /// In en, this message translates to:
  /// **'Heavy rain likely to stop in {minutes} minutes'**
  String homeRainTrendHeavyStopping(int minutes);

  /// Title of the map layer-picker sheet
  ///
  /// In en, this message translates to:
  /// **'Layers'**
  String get mapLayers;

  /// Title of the layer-order editor, also the tooltip of the reorder button in the layer picker
  ///
  /// In en, this message translates to:
  /// **'Reorder layers'**
  String get mapLayerOrderTitle;

  /// Button that restores the layer picker's default order
  ///
  /// In en, this message translates to:
  /// **'Reset order'**
  String get mapLayerOrderReset;

  /// Name of the composite radar reflectivity layer in the layer picker
  ///
  /// In en, this message translates to:
  /// **'Composite Radar Reflectivity'**
  String get mapLayerRadar;

  /// Name of the Himawari infrared layer in the layer picker
  ///
  /// In en, this message translates to:
  /// **'Himawari Infrared (B13)'**
  String get mapLayerSatellite;

  /// Himawari visible-blue channel (B01, 0.47 µm) layer name
  ///
  /// In en, this message translates to:
  /// **'Himawari Blue (B01)'**
  String get mapLayerSatelliteB01;

  /// Himawari visible-green channel (B02, 0.51 µm) layer name
  ///
  /// In en, this message translates to:
  /// **'Himawari Green (B02)'**
  String get mapLayerSatelliteB02;

  /// Himawari visible-red channel (B03, 0.64 µm) layer name
  ///
  /// In en, this message translates to:
  /// **'Himawari Red (B03)'**
  String get mapLayerSatelliteB03;

  /// Himawari near-infrared channel (B04, 0.86 µm) layer name
  ///
  /// In en, this message translates to:
  /// **'Himawari Near-Infrared (B04)'**
  String get mapLayerSatelliteB04;

  /// Himawari near-infrared channel (B05, 1.6 µm) layer name
  ///
  /// In en, this message translates to:
  /// **'Himawari Near-Infrared (B05)'**
  String get mapLayerSatelliteB05;

  /// Himawari near-infrared channel (B06, 2.3 µm) layer name
  ///
  /// In en, this message translates to:
  /// **'Himawari Near-Infrared (B06)'**
  String get mapLayerSatelliteB06;

  /// Himawari shortwave-infrared channel (B07, 3.9 µm) layer name
  ///
  /// In en, this message translates to:
  /// **'Himawari Shortwave Infrared (B07)'**
  String get mapLayerSatelliteB07;

  /// Himawari upper-level water-vapour channel (B08, 6.2 µm) layer name
  ///
  /// In en, this message translates to:
  /// **'Himawari Upper Water Vapour (B08)'**
  String get mapLayerSatelliteB08;

  /// Himawari mid-level water-vapour channel (B09, 6.9 µm) layer name
  ///
  /// In en, this message translates to:
  /// **'Himawari Mid Water Vapour (B09)'**
  String get mapLayerSatelliteB09;

  /// Himawari lower-level water-vapour channel (B10, 7.3 µm) layer name
  ///
  /// In en, this message translates to:
  /// **'Himawari Lower Water Vapour (B10)'**
  String get mapLayerSatelliteB10;

  /// Himawari SO₂ absorption channel (B11, 8.6 µm) layer name
  ///
  /// In en, this message translates to:
  /// **'Himawari SO₂ / Cloud Phase (B11)'**
  String get mapLayerSatelliteB11;

  /// Himawari ozone-band channel (B12, 9.6 µm) layer name
  ///
  /// In en, this message translates to:
  /// **'Himawari Ozone (B12)'**
  String get mapLayerSatelliteB12;

  /// Himawari clean-infrared window channel (B13, 10.4 µm) layer name
  ///
  /// In en, this message translates to:
  /// **'Himawari Infrared (B13)'**
  String get mapLayerSatelliteB13;

  /// Himawari longwave-infrared channel (B14, 11.2 µm) layer name
  ///
  /// In en, this message translates to:
  /// **'Himawari Longwave Infrared (B14)'**
  String get mapLayerSatelliteB14;

  /// Himawari longwave-infrared channel (B15, 12.4 µm) layer name
  ///
  /// In en, this message translates to:
  /// **'Himawari Longwave Infrared (B15)'**
  String get mapLayerSatelliteB15;

  /// Himawari CO₂-band channel (B16, 13.3 µm) layer name
  ///
  /// In en, this message translates to:
  /// **'Himawari CO₂ (B16)'**
  String get mapLayerSatelliteB16;

  /// Himawari True Color RGB composite layer name
  ///
  /// In en, this message translates to:
  /// **'Himawari True Color'**
  String get mapLayerSatelliteTruecolor;

  /// Himawari Natural Color RGB composite layer name
  ///
  /// In en, this message translates to:
  /// **'Himawari Natural Color'**
  String get mapLayerSatelliteNaturalcolor;

  /// Himawari Ash RGB composite layer name
  ///
  /// In en, this message translates to:
  /// **'Himawari Ash'**
  String get mapLayerSatelliteAsh;

  /// Himawari Dust RGB composite layer name
  ///
  /// In en, this message translates to:
  /// **'Himawari Dust'**
  String get mapLayerSatelliteDust;

  /// Himawari Airmass RGB composite layer name
  ///
  /// In en, this message translates to:
  /// **'Himawari Airmass'**
  String get mapLayerSatelliteAirmass;

  /// Himawari Night Microphysics RGB composite layer name
  ///
  /// In en, this message translates to:
  /// **'Himawari Night Microphysics'**
  String get mapLayerSatelliteNightmicrophysics;

  /// Himawari water-vapour layer name
  ///
  /// In en, this message translates to:
  /// **'Himawari Water Vapour'**
  String get mapLayerSatelliteWatervapor;

  /// Himawari split-window brightness-temperature-difference layer name
  ///
  /// In en, this message translates to:
  /// **'Himawari Split Window'**
  String get mapLayerSatelliteBtdSplit;

  /// Himawari night fog / low-cloud brightness-temperature-difference layer name
  ///
  /// In en, this message translates to:
  /// **'Himawari Night Fog'**
  String get mapLayerSatelliteBtdFog;

  /// Himawari overshooting-cloud-top brightness-temperature-difference layer name
  ///
  /// In en, this message translates to:
  /// **'Himawari Overshooting Top'**
  String get mapLayerSatelliteBtdWvirw;

  /// Himawari SO₂ / cloud-phase brightness-temperature-difference layer name
  ///
  /// In en, this message translates to:
  /// **'Himawari SO₂ / Cloud Phase'**
  String get mapLayerSatelliteBtdSo2;

  /// Himawari cirrus / cloud-height brightness-temperature-difference layer name
  ///
  /// In en, this message translates to:
  /// **'Himawari Cirrus / Cloud Height'**
  String get mapLayerSatelliteBtdCo2;

  /// Himawari tropopause brightness-temperature-difference layer name
  ///
  /// In en, this message translates to:
  /// **'Himawari Tropopause'**
  String get mapLayerSatelliteBtdOzone;

  /// Himawari cloud-top-temperature (Level-2 retrieval) layer name
  ///
  /// In en, this message translates to:
  /// **'Himawari Cloud Top Temperature'**
  String get mapLayerSatelliteCloudtop;

  /// Himawari cloud-mask (Level-2 retrieval) layer name
  ///
  /// In en, this message translates to:
  /// **'Himawari Cloud Mask'**
  String get mapLayerSatelliteCloudmask;

  /// Himawari sea-surface-temperature (ACSPO L3C) layer name
  ///
  /// In en, this message translates to:
  /// **'Himawari Sea Surface Temperature'**
  String get mapLayerSatelliteSst;

  /// Himawari normalised-difference vegetation-index layer name
  ///
  /// In en, this message translates to:
  /// **'Himawari NDVI'**
  String get mapLayerSatelliteNdvi;

  /// Himawari normalised-difference water-index layer name
  ///
  /// In en, this message translates to:
  /// **'Himawari NDWI'**
  String get mapLayerSatelliteNdwi;

  /// Himawari modified normalised-difference water-index layer name
  ///
  /// In en, this message translates to:
  /// **'Himawari MNDWI'**
  String get mapLayerSatelliteMndwi;

  /// Satellite legend row: the country/global border, drawn bright yellow over the imagery
  ///
  /// In en, this message translates to:
  /// **'Country border'**
  String get mapLayerSatelliteGlobalOutline;

  /// Satellite legend note for the RGB-recipe products (True Color, Ash, …) that carry no single numerical scale
  ///
  /// In en, this message translates to:
  /// **'RGB composite (JMA recipe)'**
  String get mapLayerSatelliteRgbComposite;

  /// Cloud-mask category: clear sky, transparent on the map
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get mapLayerSatelliteCloudClear;

  /// Cloud-mask category: probably clear
  ///
  /// In en, this message translates to:
  /// **'Probably clear'**
  String get mapLayerSatelliteCloudProbablyClear;

  /// Cloud-mask category: probably cloudy
  ///
  /// In en, this message translates to:
  /// **'Probably cloudy'**
  String get mapLayerSatelliteCloudProbablyCloudy;

  /// Cloud-mask category: cloudy
  ///
  /// In en, this message translates to:
  /// **'Cloudy'**
  String get mapLayerSatelliteCloudCloudy;

  /// Satellite legend note: on the IR grayscale/enhancements the warm end is clear sky, drawn transparent so the basemap shows
  ///
  /// In en, this message translates to:
  /// **'Clear sky (warm end) = transparent, the basemap shows'**
  String get mapLayerSatelliteTransparentWarm;

  /// Satellite legend note: on the reflectance bands a dark or night pixel is transparent so the basemap shows
  ///
  /// In en, this message translates to:
  /// **'Low reflectance / night = transparent, the basemap shows'**
  String get mapLayerSatelliteTransparentReflectance;

  /// Satellite legend note: on the brightness-temperature-difference layers a near-zero difference is transparent — no absorber is present
  ///
  /// In en, this message translates to:
  /// **'Zero difference = transparent (no signal)'**
  String get mapLayerSatelliteTransparentZero;

  /// Satellite legend note: the daytime RGB recipes fade out across the terminator and are transparent at night
  ///
  /// In en, this message translates to:
  /// **'Night = transparent, the basemap shows'**
  String get mapLayerSatelliteTransparentNight;

  /// Satellite legend note: the SST retrieval has no value over land, drawn transparent
  ///
  /// In en, this message translates to:
  /// **'No data (land) = transparent'**
  String get mapLayerSatelliteTransparentNoData;

  /// Satellite legend note: NDVI below the bare-soil threshold is transparent
  ///
  /// In en, this message translates to:
  /// **'Below 0.1 = transparent (no vegetation)'**
  String get mapLayerSatelliteTransparentNoVegetation;

  /// Satellite legend note: NDWI/MNDWI at zero or below is transparent — no water signal
  ///
  /// In en, this message translates to:
  /// **'≤ 0 = transparent (no water)'**
  String get mapLayerSatelliteTransparentNoWater;

  /// Satellite legend note: the cloud-mask clear category is transparent so the basemap shows
  ///
  /// In en, this message translates to:
  /// **'Clear sky = transparent, the basemap shows'**
  String get mapLayerSatelliteTransparentClear;

  /// Section header of the satellite band colour-style menu on the map
  ///
  /// In en, this message translates to:
  /// **'Colour style'**
  String get mapLayerStyleSection;

  /// Tooltip of the colour-style chip beside the layer switcher
  ///
  /// In en, this message translates to:
  /// **'Colour style'**
  String get mapLayerStyleTooltip;

  /// Colour-style option: JMA grayscale, the default radar-image convention
  ///
  /// In en, this message translates to:
  /// **'Grayscale (JMA)'**
  String get mapLayerStyleGray;

  /// Explains the JMA grayscale band rendering
  ///
  /// In en, this message translates to:
  /// **'JMA grayscale — colder is whiter'**
  String get mapLayerStyleGrayTooltip;

  /// Colour-style option: JMA cloud-top enhancement, tinted below −40 °C
  ///
  /// In en, this message translates to:
  /// **'Cloud-top enhancement (JMA)'**
  String get mapLayerStyleJma;

  /// Explains the JMA cloud-top enhancement band rendering
  ///
  /// In en, this message translates to:
  /// **'Grayscale base, tinted below −40 °C to highlight cloud-top height'**
  String get mapLayerStyleJmaTooltip;

  /// Colour-style option: Dvorak BD curve stepped grayscale
  ///
  /// In en, this message translates to:
  /// **'Dvorak BD'**
  String get mapLayerStyleBd;

  /// Explains the Dvorak BD band rendering
  ///
  /// In en, this message translates to:
  /// **'Dvorak BD curve — the stepped grayscale for tropical-cyclone intensity analysis'**
  String get mapLayerStyleBdTooltip;

  /// Name of the QPESUMS next-1-hour precipitation forecast layer in the layer picker
  ///
  /// In en, this message translates to:
  /// **'1h Precipitation Forecast'**
  String get mapLayerQpesums;

  /// Map layer switcher label for the lightning strike timeline
  ///
  /// In en, this message translates to:
  /// **'Lightning'**
  String get mapLayerLightning;

  /// Lightning legend: cloud-to-ground strike within N minutes
  ///
  /// In en, this message translates to:
  /// **'Cloud-to-ground · {minutes} min'**
  String lightningLegendCg(int minutes);

  /// Lightning legend: cloud-to-cloud strike within N minutes
  ///
  /// In en, this message translates to:
  /// **'Cloud-to-cloud · {minutes} min'**
  String lightningLegendCc(int minutes);

  /// Label on the map timeline when the newest (latest) frame is selected
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get mapTimelineNow;

  /// Label on the map timeline when the selected frame predates the present
  ///
  /// In en, this message translates to:
  /// **'Past'**
  String get mapTimelinePast;

  /// Label on the map timeline when the selected frame postdates the present
  ///
  /// In en, this message translates to:
  /// **'Future'**
  String get mapTimelineFuture;

  /// Label above the map timeline's date (the radar observation time), e.g. Observed / 2026/07/14
  ///
  /// In en, this message translates to:
  /// **'Observed'**
  String get mapTimelineObserved;

  /// Label above the map timeline's date when the frame times are forecast times, e.g. Forecast / 2026/07/14
  ///
  /// In en, this message translates to:
  /// **'Forecast'**
  String get mapTimelineForecast;

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

  /// More-menu entry and page title for choosing the Map tab's default overlay
  ///
  /// In en, this message translates to:
  /// **'Default map layer'**
  String get defaultMapLayerSettings;

  /// Explanatory subtitle on the default-map-layer settings page
  ///
  /// In en, this message translates to:
  /// **'The Map tab opens on this overlay. The bottom-navigation icon and label follow this choice.'**
  String get defaultMapLayerSubtitle;

  /// Short Map-tab bottom-nav / default-layer picker label for radar
  ///
  /// In en, this message translates to:
  /// **'Radar'**
  String get mapNavRadar;

  /// Short Map-tab bottom-nav / default-layer picker label for the 1h QPESUMS precipitation forecast
  ///
  /// In en, this message translates to:
  /// **'Forecast'**
  String get mapNavQpesums;

  /// Short Map-tab bottom-nav / default-layer picker label for satellite
  ///
  /// In en, this message translates to:
  /// **'Satellite'**
  String get mapNavSatellite;

  /// Short Map-tab bottom-nav / default-layer picker label for lightning
  ///
  /// In en, this message translates to:
  /// **'Lightning'**
  String get mapNavLightning;

  /// Short Map-tab bottom-nav / default-layer picker label for typhoon
  ///
  /// In en, this message translates to:
  /// **'Typhoon'**
  String get mapNavTyphoon;

  /// Short Map-tab bottom-nav / default-layer picker label for RTS seismic monitor
  ///
  /// In en, this message translates to:
  /// **'Earthquake'**
  String get mapNavEarthquake;

  /// Short Map-tab bottom-nav / default-layer picker label for temperature
  ///
  /// In en, this message translates to:
  /// **'Temperature'**
  String get mapNavTemperature;

  /// Short Map-tab bottom-nav / default-layer picker label for humidity
  ///
  /// In en, this message translates to:
  /// **'Humidity'**
  String get mapNavHumidity;

  /// Short Map-tab bottom-nav / default-layer picker label for pressure
  ///
  /// In en, this message translates to:
  /// **'Pressure'**
  String get mapNavPressure;

  /// Short Map-tab bottom-nav / default-layer picker label for wind
  ///
  /// In en, this message translates to:
  /// **'Wind'**
  String get mapNavWind;

  /// Short Map-tab bottom-nav / default-layer picker label for rain
  ///
  /// In en, this message translates to:
  /// **'Rain'**
  String get mapNavRain;

  /// Short Map-tab bottom-nav / default-layer picker label for disaster-prevention map
  ///
  /// In en, this message translates to:
  /// **'Disaster'**
  String get mapNavDisaster;

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

  /// Running total label above the cumulative station rain trend chart
  ///
  /// In en, this message translates to:
  /// **'Cumulative {total} mm'**
  String trendCumulativeTotal(String total);

  /// Compact chart X-axis hour tick (e.g. 20h / 20時)
  ///
  /// In en, this message translates to:
  /// **'{hour}h'**
  String chartHourLabel(int hour);

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

  /// Map layer switcher label for the rainfall station layer
  ///
  /// In en, this message translates to:
  /// **'Rainfall'**
  String get mapLayerRain;

  /// Tooltip for the rainfall accumulation-interval menu
  ///
  /// In en, this message translates to:
  /// **'Accumulation window'**
  String get rainIntervalMenu;

  /// Rainfall accumulation since local midnight (API now)
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get rainIntervalNow;

  /// No description provided for @rainInterval10m.
  ///
  /// In en, this message translates to:
  /// **'10 min'**
  String get rainInterval10m;

  /// No description provided for @rainInterval1h.
  ///
  /// In en, this message translates to:
  /// **'1 h'**
  String get rainInterval1h;

  /// No description provided for @rainInterval3h.
  ///
  /// In en, this message translates to:
  /// **'3 h'**
  String get rainInterval3h;

  /// No description provided for @rainInterval6h.
  ///
  /// In en, this message translates to:
  /// **'6 h'**
  String get rainInterval6h;

  /// No description provided for @rainInterval12h.
  ///
  /// In en, this message translates to:
  /// **'12 h'**
  String get rainInterval12h;

  /// No description provided for @rainInterval24h.
  ///
  /// In en, this message translates to:
  /// **'24 h'**
  String get rainInterval24h;

  /// No description provided for @rainInterval2d.
  ///
  /// In en, this message translates to:
  /// **'2 d'**
  String get rainInterval2d;

  /// No description provided for @rainInterval3d.
  ///
  /// In en, this message translates to:
  /// **'3 d'**
  String get rainInterval3d;

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

  /// Map layer switcher label for the ECMWF wind-forecast layer
  ///
  /// In en, this message translates to:
  /// **'ECMWF'**
  String get mapLayerWindForecastEcmwf;

  /// Map layer switcher label for the GFS wind-forecast layer
  ///
  /// In en, this message translates to:
  /// **'GFS'**
  String get mapLayerWindForecastGfs;

  /// Map layer switcher label for the real-time seismic monitor (RTS)
  ///
  /// In en, this message translates to:
  /// **'Seismic Monitor'**
  String get mapLayerMonitor;

  /// Map layer switcher label for the disaster-prevention map (DPM)
  ///
  /// In en, this message translates to:
  /// **'Disaster Map'**
  String get mapLayerDisasterMap;

  /// Disaster-map overlay menu toggle for AED (defibrillator) points
  ///
  /// In en, this message translates to:
  /// **'AED'**
  String get mapLayerAed;

  /// Tooltip on the disaster-map overlay tune button
  ///
  /// In en, this message translates to:
  /// **'Disaster map layers'**
  String get disasterMapOverlayMenuTooltip;

  /// Section header for DPM sub-layer toggles in the overlay menu
  ///
  /// In en, this message translates to:
  /// **'Layers'**
  String get disasterMapOverlaySectionLayers;

  /// Tooltip for the AED toggle in the disaster-map overlay menu
  ///
  /// In en, this message translates to:
  /// **'Show AED locations'**
  String get disasterMapOverlayAedTooltip;

  /// AED detail row label
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get aedAddress;

  /// AED city / district row label
  ///
  /// In en, this message translates to:
  /// **'Region'**
  String get aedRegion;

  /// AED venue category row label
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get aedCategory;

  /// AED venue type row label
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get aedType;

  /// AED placement description row label
  ///
  /// In en, this message translates to:
  /// **'Placement'**
  String get aedPlaceDesc;

  /// AED free-text description row label
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get aedDescription;

  /// AED weekday opening hours row label
  ///
  /// In en, this message translates to:
  /// **'Weekday hours'**
  String get aedHoursWeekday;

  /// AED Saturday opening hours row label
  ///
  /// In en, this message translates to:
  /// **'Saturday hours'**
  String get aedHoursSaturday;

  /// AED Sunday opening hours row label
  ///
  /// In en, this message translates to:
  /// **'Sunday hours'**
  String get aedHoursSunday;

  /// AED opening-hours remark row label
  ///
  /// In en, this message translates to:
  /// **'Hours note'**
  String get aedOpenRemark;

  /// AED emergency contact phone row label
  ///
  /// In en, this message translates to:
  /// **'Emergency phone'**
  String get aedEmergencyPhone;

  /// Disaster-map overlay menu toggle for public restrooms
  ///
  /// In en, this message translates to:
  /// **'Restrooms'**
  String get mapLayerRestroom;

  /// Disaster-map overlay menu toggle for evacuation shelters
  ///
  /// In en, this message translates to:
  /// **'Shelters'**
  String get mapLayerShelter;

  /// Tooltip for the restroom toggle in the disaster-map overlay menu
  ///
  /// In en, this message translates to:
  /// **'Show public restrooms'**
  String get disasterMapOverlayRestroomTooltip;

  /// Tooltip for the shelter toggle in the disaster-map overlay menu
  ///
  /// In en, this message translates to:
  /// **'Show evacuation shelters'**
  String get disasterMapOverlayShelterTooltip;

  /// Action in the disaster-map detail sheet: open the point in an external map app
  ///
  /// In en, this message translates to:
  /// **'Open in maps'**
  String get dpmOpenInMaps;

  /// External map app choice: Google Maps
  ///
  /// In en, this message translates to:
  /// **'Google Maps'**
  String get mapAppGoogleMaps;

  /// External map app choice: Apple Maps
  ///
  /// In en, this message translates to:
  /// **'Apple Maps'**
  String get mapAppAppleMaps;

  /// Choice-sheet label suffix marking the platform home map app, with the app name
  ///
  /// In en, this message translates to:
  /// **'{app} (default)'**
  String mapAppDefault(String app);

  /// Choice-sheet action: copy the point's coordinates
  ///
  /// In en, this message translates to:
  /// **'Copy coordinates'**
  String get mapAppCopyCoordinates;

  /// Snackbar confirming the coordinates were copied
  ///
  /// In en, this message translates to:
  /// **'Coordinates copied'**
  String get mapAppCoordinatesCopied;

  /// Section title in map overlay settings menus: the reference overlays
  ///
  /// In en, this message translates to:
  /// **'Reference layers'**
  String get mapOverlaySectionReference;

  /// Section title in map overlay lists: the seismic-monitor overlays
  ///
  /// In en, this message translates to:
  /// **'Earthquake'**
  String get mapLayerCategoryEarthquake;

  /// Section title in map overlay lists: typhoon overlays
  ///
  /// In en, this message translates to:
  /// **'Typhoon'**
  String get mapLayerCategoryTyphoon;

  /// Section title in map overlay lists: the weather-observation overlays
  ///
  /// In en, this message translates to:
  /// **'Weather observations'**
  String get mapLayerCategoryWeather;

  /// Section title in map overlay lists: satellite-imagery overlays
  ///
  /// In en, this message translates to:
  /// **'Satellite'**
  String get mapLayerCategorySatellite;

  /// Section title in map overlay lists: radar and precipitation-forecast overlays
  ///
  /// In en, this message translates to:
  /// **'Radar'**
  String get mapLayerCategoryRadar;

  /// Section title in map overlay lists: everyday-life facility overlays
  ///
  /// In en, this message translates to:
  /// **'Daily life'**
  String get mapLayerCategoryLife;

  /// Section title in map overlay lists: numerical weather prediction (ECMWF/GFS) wind-field overlays
  ///
  /// In en, this message translates to:
  /// **'Numerical forecast'**
  String get mapLayerCategoryForecast;

  /// Section title in map overlay settings menus: base-map settings
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get mapOverlaySectionMap;

  /// Section title in the rainfall menu: the accumulation-interval choices
  ///
  /// In en, this message translates to:
  /// **'Time window'**
  String get rainIntervalSection;

  /// Map setting: show township-name labels when the map is zoomed in
  ///
  /// In en, this message translates to:
  /// **'Township names'**
  String get mapTownLabels;

  /// Hint under the township-names setting
  ///
  /// In en, this message translates to:
  /// **'Show township names when zoomed in'**
  String get mapTownLabelsHint;

  /// Hint in the disaster-map detail sheet when nothing is selected
  ///
  /// In en, this message translates to:
  /// **'Tap a marker on the map for details'**
  String get dpmSheetEmpty;

  /// Address row label in the disaster-map restroom / shelter detail sheet
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get dpmAddress;

  /// Restroom detail row label for the toilet type
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get restroomTypeLabel;

  /// Restroom detail row label for the venue category
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get restroomCategoryLabel;

  /// Restroom detail row label for the cleanliness grade
  ///
  /// In en, this message translates to:
  /// **'Grade'**
  String get restroomGradeLabel;

  /// Restroom type: female restroom
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get restroomTypeFemale;

  /// Restroom type: male restroom
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get restroomTypeMale;

  /// Restroom type: mixed/unisex restroom
  ///
  /// In en, this message translates to:
  /// **'Mixed'**
  String get restroomTypeMixed;

  /// Restroom type: accessible restroom
  ///
  /// In en, this message translates to:
  /// **'Accessible'**
  String get restroomTypeAccessible;

  /// Restroom type: gender-neutral restroom
  ///
  /// In en, this message translates to:
  /// **'Gender-neutral'**
  String get restroomTypeGenderNeutral;

  /// Restroom type: family restroom
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get restroomTypeFamily;

  /// Restroom type: not specified
  ///
  /// In en, this message translates to:
  /// **'Unspecified'**
  String get restroomTypeUnspecified;

  /// Restroom venue category: transport facility
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get restroomCategoryTransport;

  /// Restroom venue category: park
  ///
  /// In en, this message translates to:
  /// **'Park'**
  String get restroomCategoryPark;

  /// Restroom venue category: commercial establishment
  ///
  /// In en, this message translates to:
  /// **'Commercial'**
  String get restroomCategoryCommercial;

  /// Restroom venue category: religious / ceremonial venue
  ///
  /// In en, this message translates to:
  /// **'Religious'**
  String get restroomCategoryReligious;

  /// Restroom venue category: cultural / leisure activity venue
  ///
  /// In en, this message translates to:
  /// **'Cultural'**
  String get restroomCategoryCultural;

  /// Restroom venue category: public service office
  ///
  /// In en, this message translates to:
  /// **'Government'**
  String get restroomCategoryGovernment;

  /// Restroom venue category: social welfare institution / gathering place
  ///
  /// In en, this message translates to:
  /// **'Welfare'**
  String get restroomCategoryWelfare;

  /// Restroom venue category: tourist area / scenic spot
  ///
  /// In en, this message translates to:
  /// **'Tourist'**
  String get restroomCategoryTourist;

  /// Restroom venue category: leisure / entertainment venue
  ///
  /// In en, this message translates to:
  /// **'Leisure'**
  String get restroomCategoryLeisure;

  /// Restroom venue category: other
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get restroomCategoryOther;

  /// Restroom cleanliness grade: excellent
  ///
  /// In en, this message translates to:
  /// **'Excellent'**
  String get restroomGradeExcellent;

  /// Restroom cleanliness grade: good
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get restroomGradeGood;

  /// Restroom cleanliness grade: average
  ///
  /// In en, this message translates to:
  /// **'Average'**
  String get restroomGradeAverage;

  /// Restroom cleanliness grade: below standard
  ///
  /// In en, this message translates to:
  /// **'Below standard'**
  String get restroomGradePoor;

  /// Shelter detail address row label
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get shelterAddressLabel;

  /// Shelter detail capacity row label
  ///
  /// In en, this message translates to:
  /// **'Capacity'**
  String get shelterCapacityLabel;

  /// Shelter detail capacity row value
  ///
  /// In en, this message translates to:
  /// **'{n} people'**
  String shelterCapacityValue(int n);

  /// Shelter detail applicable-disaster categories row label
  ///
  /// In en, this message translates to:
  /// **'Disaster types'**
  String get shelterCategoryLabel;

  /// Shelter detail row: whether indoor shelter is provided
  ///
  /// In en, this message translates to:
  /// **'Indoor shelter'**
  String get shelterIndoorLabel;

  /// Shelter detail row: whether outdoor shelter is provided
  ///
  /// In en, this message translates to:
  /// **'Outdoor shelter'**
  String get shelterOutdoorLabel;

  /// Shelter detail row: whether evacuees needing care can be accommodated
  ///
  /// In en, this message translates to:
  /// **'Vulnerable-people friendly'**
  String get shelterVulnerableOkLabel;

  /// Affirmative value in the disaster-map detail sheet
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get dpmYes;

  /// Negative value in the disaster-map detail sheet
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get dpmNo;

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

  /// Sheet picker: named typhoon (CWA name + TY tyNo)
  ///
  /// In en, this message translates to:
  /// **'{name} TY {no}'**
  String typhoonPickerNamed(String no, String name);

  /// Sheet picker: unnamed tropical depression (CWA tdNo)
  ///
  /// In en, this message translates to:
  /// **'Tropical depression TD {no}'**
  String typhoonPickerTd(String no);

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

  /// Map control that centers the camera on the device GPS fix
  ///
  /// In en, this message translates to:
  /// **'My location'**
  String get mapMyLocation;

  /// Map compass tooltip: re-points the camera to north-up
  ///
  /// In en, this message translates to:
  /// **'Reset north'**
  String get mapResetNorth;

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

  /// Filter section title in the disaster-map sheet: restroom venue categories
  ///
  /// In en, this message translates to:
  /// **'Venue types'**
  String get dpmFilterSectionRestroom;

  /// Filter section title in the disaster-map sheet: restroom toilet-kind categories
  ///
  /// In en, this message translates to:
  /// **'Toilet types'**
  String get dpmFilterSectionRestroomType;

  /// Filter section title in the disaster-map sheet: shelter disaster types
  ///
  /// In en, this message translates to:
  /// **'Shelter disaster types'**
  String get dpmFilterSectionShelter;

  /// Shelter disaster-type filter chip: flood
  ///
  /// In en, this message translates to:
  /// **'Flood'**
  String get dpmDisasterFlood;

  /// Shelter disaster-type filter chip: earthquake
  ///
  /// In en, this message translates to:
  /// **'Earthquake'**
  String get dpmDisasterEarthquake;

  /// Shelter disaster-type filter chip: landslide
  ///
  /// In en, this message translates to:
  /// **'Landslide'**
  String get dpmDisasterLandslide;

  /// Shelter disaster-type filter chip: tsunami
  ///
  /// In en, this message translates to:
  /// **'Tsunami'**
  String get dpmDisasterTsunami;

  /// Shelter disaster-type filter chip: slope hazard
  ///
  /// In en, this message translates to:
  /// **'Slope hazard'**
  String get dpmDisasterSlope;

  /// Shelter disaster-type filter chip: nuclear accident
  ///
  /// In en, this message translates to:
  /// **'Nuclear accident'**
  String get dpmDisasterNuclear;

  /// Label for the experimental sky time-of-day override.
  ///
  /// In en, this message translates to:
  /// **'Sky time'**
  String get skyTime;

  /// Label for the skyTimeAuto option in the experimental backdrop settings.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get skyTimeAuto;

  /// Label for the skyTimeDawn option in the experimental backdrop settings.
  ///
  /// In en, this message translates to:
  /// **'Dawn'**
  String get skyTimeDawn;

  /// Label for the skyTimeSunrise option in the experimental backdrop settings.
  ///
  /// In en, this message translates to:
  /// **'Sunrise'**
  String get skyTimeSunrise;

  /// Label for the skyTimeMorning option in the experimental backdrop settings.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get skyTimeMorning;

  /// Label for the skyTimeNoon option in the experimental backdrop settings.
  ///
  /// In en, this message translates to:
  /// **'Noon'**
  String get skyTimeNoon;

  /// Label for the skyTimeAfternoon option in the experimental backdrop settings.
  ///
  /// In en, this message translates to:
  /// **'Afternoon'**
  String get skyTimeAfternoon;

  /// Label for the skyTimeGolden option in the experimental backdrop settings.
  ///
  /// In en, this message translates to:
  /// **'Golden hour'**
  String get skyTimeGolden;

  /// Label for the skyTimeSunset option in the experimental backdrop settings.
  ///
  /// In en, this message translates to:
  /// **'Sunset'**
  String get skyTimeSunset;

  /// Label for the skyTimeDusk option in the experimental backdrop settings.
  ///
  /// In en, this message translates to:
  /// **'Dusk'**
  String get skyTimeDusk;

  /// Label for the skyTimeNight option in the experimental backdrop settings.
  ///
  /// In en, this message translates to:
  /// **'Night'**
  String get skyTimeNight;

  /// Label for the weatherModeCloudy option in the experimental backdrop settings.
  ///
  /// In en, this message translates to:
  /// **'Cloudy'**
  String get weatherModeCloudy;

  /// Label for the weatherModeOvercast option in the experimental backdrop settings.
  ///
  /// In en, this message translates to:
  /// **'Overcast'**
  String get weatherModeOvercast;

  /// Label for the weatherModeSnow option in the experimental backdrop settings.
  ///
  /// In en, this message translates to:
  /// **'Snow'**
  String get weatherModeSnow;

  /// Label for the weatherModeSand option in the experimental backdrop settings.
  ///
  /// In en, this message translates to:
  /// **'Dust'**
  String get weatherModeSand;

  /// Radar scan-range overlay toggle in the map's radar overlay menu.
  ///
  /// In en, this message translates to:
  /// **'Show scan range'**
  String get radarScanRange;

  /// Radar scan-range overlay toggle in the map's radar overlay menu.
  ///
  /// In en, this message translates to:
  /// **'Outlines the area the four radars actually observe.'**
  String get radarScanRangeSubtitle;

  /// Hint under the radar scan-range toggle in the radar overlay menu.
  ///
  /// In en, this message translates to:
  /// **'Blank outside means unobserved'**
  String get radarScanRangeHint;

  /// Tooltip for the radar overlay-options chip beside the layer switcher
  ///
  /// In en, this message translates to:
  /// **'Radar overlay options'**
  String get radarOverlayMenuTooltip;

  /// County-border overlay toggle in the map's radar overlay menu.
  ///
  /// In en, this message translates to:
  /// **'County borders'**
  String get radarCountyOutline;

  /// World-country-border overlay toggle in the map's reference-layer overlay menus.
  ///
  /// In en, this message translates to:
  /// **'National borders'**
  String get radarGlobalOutline;

  /// Hint under the national-border toggle in the radar overlay menu.
  ///
  /// In en, this message translates to:
  /// **'Every country\'s outer frame'**
  String get radarGlobalOutlineHint;

  /// Hint under the county-border toggle in the radar overlay menu.
  ///
  /// In en, this message translates to:
  /// **'Drawn over the echo'**
  String get radarCountyOutlineHint;

  /// County-border overlay toggle in the map's radar overlay menu.
  ///
  /// In en, this message translates to:
  /// **'Keeps county borders legible under the radar echo.'**
  String get radarCountyOutlineSubtitle;

  /// Township-border overlay toggle in the map's radar overlay menu.
  ///
  /// In en, this message translates to:
  /// **'Township borders'**
  String get radarTownOutline;

  /// Hint under the township-border toggle in the radar overlay menu.
  ///
  /// In en, this message translates to:
  /// **'The finer mesh'**
  String get radarTownOutlineHint;

  /// Township-border overlay toggle in the map's radar overlay menu.
  ///
  /// In en, this message translates to:
  /// **'Keeps township borders legible under the radar echo.'**
  String get radarTownOutlineSubtitle;

  /// Tooltip for the QPESUMS forecast overlay-options chip beside the layer switcher.
  ///
  /// In en, this message translates to:
  /// **'QPESUMS overlay options'**
  String get qpesumsOverlayMenuTooltip;

  /// Tooltip for the wind-forecast overlay-options chip beside the layer switcher.
  ///
  /// In en, this message translates to:
  /// **'Wind forecast overlay options'**
  String get windForecastOverlayMenuTooltip;

  /// Hint under the county-border toggle in the wind-forecast overlay menu.
  ///
  /// In en, this message translates to:
  /// **'Drawn over the wind field'**
  String get windForecastCountyOutlineHint;

  /// Hint under the national-border toggle in the wind-forecast overlay menu.
  ///
  /// In en, this message translates to:
  /// **'Every country\'s outer frame'**
  String get windForecastGlobalOutlineHint;

  /// Hint under the township-border toggle in the wind-forecast overlay menu.
  ///
  /// In en, this message translates to:
  /// **'The finer mesh'**
  String get windForecastTownOutlineHint;
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
