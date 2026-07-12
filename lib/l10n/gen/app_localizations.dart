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

  /// Section header on the More page grouping advanced/developer entries
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get moreSectionAdvanced;

  /// Title of the experimental-features settings page and its More-menu entry
  ///
  /// In en, this message translates to:
  /// **'Experimental features'**
  String get experimentalFeatures;

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
