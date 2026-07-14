/// The single registry of every `SharedPreferences` key the app persists.
///
/// KV keys used to live as private literals inside each settings object, so the
/// whole persisted surface couldn't be seen in one place — making collisions and
/// migrations easy to get wrong. They're centralised here (one file to audit);
/// each store keeps owning its own read/write logic and just references a key
/// from here. This is the common large-project pattern: a typed key registry
/// (the alternative extremes — a single god "Settings" facade, or generated
/// prefs — are heavier than this codebase needs).
///
/// **Never change an existing string** without a migration: it's the storage
/// address of already-saved user data. New keys should follow `<area>.<name>`.
abstract final class PreferenceKeys {
  const PreferenceKeys._();

  /// First-launch onboarding completion flag. See `OnboardingStore`.
  static const String onboardingComplete = 'onboarding.complete';

  /// Selected UI language override (locale tag; empty/absent = system). See
  /// `LocaleController`.
  static const String locale = 'app.locale';

  /// Saved Home township codes (ordered list). See `RegionStore`.
  static const String savedRegionCodes = 'home.savedRegionCodes';

  /// Experimental weather-animation override. See `ExperimentalSettings`.
  static const String weatherMode = 'experimental.weatherMode';

  /// Last push (FCM) token. See `NotificationService`.
  static const String pushToken = 'notification.pushToken';

  /// Notification-channel catalogue version (forces Android re-create). See
  /// `NotificationService`.
  static const String channelVersion = 'notification.channelVersion';

  /// Selected LB / Core API region. See `RegionSelection`.
  ///
  /// Colon-form kept as-is (pre-existing storage address).
  static const String regionLb = 'network:region:lb';
  static const String regionCore = 'network:region:core';
}
