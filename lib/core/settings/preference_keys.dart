/// The single registry of every `SharedPreferences` key the app persists.
///
/// KV keys used to live as private literals inside each settings object, so the
/// whole persisted surface couldn't be seen in one place — making collisions and
/// migrations easy to get wrong. They're centralised here (one file to audit);
/// each store keeps owning its own read/write logic and just references a key
/// from here.
///
/// A key is a typed [PrefKey], not a bare `String`. Its constructor is private,
/// so a `PrefKey` can only be minted in this library — every instance is one of
/// the `static const` fields below. Combined with the `Prefs` facade (whose
/// methods take a `PrefKey`, never a `String`), an ad-hoc key physically cannot
/// reach storage: the compiler rejects it, not code review.
///
/// **Never change an existing string** without a migration: it's the storage
/// address of already-saved user data. New keys should follow `<area>.<name>`.
library;

/// A typed handle to one persisted `SharedPreferences` key.
///
/// `T` is the value type stored under it (a phantom type — there is no field of
/// type `T`); it's what lets `Prefs` reject a type-mismatched read/write at
/// compile time. The private constructor is the closure: no code outside this
/// library can construct a `PrefKey`.
final class PrefKey<T> {
  const PrefKey._(this.name);

  /// The on-disk storage address. Public so `Prefs` (a separate library) can
  /// read it; harmless because no `Prefs` method accepts a raw `String`, so a
  /// name can never be fed back in to mint an ad-hoc key.
  final String name;
}

/// The typed key registry — the only source of [PrefKey]s in the app.
abstract final class PreferenceKeys {
  const PreferenceKeys._();

  /// First-launch onboarding completion flag. See `OnboardingStore`.
  static const PrefKey<bool> onboardingComplete = PrefKey<bool>._(
    'onboarding.complete',
  );

  /// Selected UI language override (locale tag; empty/absent = system). See
  /// `LocaleController`.
  static const PrefKey<String> locale = PrefKey<String>._('app.locale');

  /// Saved Home township codes (ordered list). See `RegionStore`.
  static const PrefKey<List<String>> savedRegionCodes = PrefKey<List<String>>._(
    'home.savedRegionCodes',
  );

  /// Experimental weather-animation override. See `ExperimentalSettings`.
  static const PrefKey<String> weatherMode = PrefKey<String>._(
    'experimental.weatherMode',
  );

  /// Last push (FCM) token. See `NotificationService`.
  static const PrefKey<String> pushToken = PrefKey<String>._(
    'notification.pushToken',
  );

  /// Notification-channel catalogue version (forces Android re-create). See
  /// `NotificationService`.
  static const PrefKey<int> channelVersion = PrefKey<int>._(
    'notification.channelVersion',
  );

  /// Selected LB / Core API region. See `RegionSelection`.
  ///
  /// Colon-form kept as-is (pre-existing storage address).
  static const PrefKey<String> regionLb = PrefKey<String>._(
    'network:region:lb',
  );
  static const PrefKey<String> regionCore = PrefKey<String>._(
    'network:region:core',
  );
}
