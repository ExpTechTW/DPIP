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

  /// Selected theme mode (`light` / `dark`; empty/absent = follow system). See
  /// `ThemeController`.
  static const PrefKey<String> themeMode = PrefKey<String>._('app.themeMode');

  /// Default map overlay when opening the Map tab. See
  /// `DefaultMapLayerController` (`radar` / `satellite` / … / `dpm`).
  static const PrefKey<String> defaultMapLayer = PrefKey<String>._(
    'map.defaultLayer',
  );

  /// User-customised layer order in the map layer picker (layer ids,
  /// most-preferred first; empty = the surface's declared order). See
  /// `MapLayerOrderController`.
  static const PrefKey<List<String>> mapLayerOrder = PrefKey<List<String>>._(
    'map.layerOrder',
  );

  /// User-customised category order in the map layer picker (category names,
  /// most-preferred first; empty = the declared category order). See
  /// `MapLayerOrderController`.
  static const PrefKey<List<String>> mapLayerCategoryOrder =
      PrefKey<List<String>>._('map.layerCategoryOrder');

  /// Saved Home township codes (ordered list). See `RegionStore`.
  static const PrefKey<List<String>> savedRegionCodes = PrefKey<List<String>>._(
    'home.savedRegionCodes',
  );

  /// Experimental weather-animation override. See `ExperimentalSettings`.
  static const PrefKey<String> weatherMode = PrefKey<String>._(
    'experimental.weatherMode',
  );

  /// Experimental time-of-day override for the backdrop. See
  /// `ExperimentalSettings`.
  static const PrefKey<String> skyTimeMode = PrefKey<String>._(
    'experimental.skyTimeMode',
  );

  /// Whether the experimental-features menu is unlocked. Hidden behind ten taps
  /// on the Developer page's version row so accidental users never see it. See
  /// `ExperimentalSettings`.
  static const PrefKey<bool> experimentalUnlocked = PrefKey<bool>._(
    'experimental.unlocked',
  );

  /// Last push token — the FCM registration token on Android, the raw APNs
  /// device token on iOS (backend registration keys on whichever this
  /// platform actually uses). See `NotificationService`.
  static const PrefKey<String> pushToken = PrefKey<String>._(
    'notification.pushToken',
  );

  /// Notification-channel catalogue version (forces Android re-create). See
  /// `NotificationService`.
  static const PrefKey<int> channelVersion = PrefKey<int>._(
    'notification.channelVersion',
  );

  /// Last successful *attempt* to POST `updateDeviceLocation` (UTC millis).
  /// Foreground reporter skips a new call within 60s — server 429 guard.
  static const PrefKey<int> deviceLocationUpdatedAtMs = PrefKey<int>._(
    'location.deviceLocationUpdatedAtMs',
  );

  /// The radio `MeshLink` keeps reconnecting to (BLE id), and its name for
  /// display. Their presence *is* the intent to stay connected — removed by
  /// `MeshLink.detach()`, which is the only thing that stops reconnection.
  static const PrefKey<String> meshDeviceId = PrefKey<String>._(
    'meshtastic.deviceId',
  );
  static const PrefKey<String> meshDeviceName = PrefKey<String>._(
    'meshtastic.deviceName',
  );

  /// Local (never pushed) mesh notifications. Messages default on; new-node
  /// alerts default **off** — a busy mesh introduces neighbours all day. See
  /// `MeshAlerts`.
  static const PrefKey<bool> meshNotifyMessages = PrefKey<bool>._(
    'meshtastic.notifyMessages',
  );
  static const PrefKey<bool> meshNotifyNodes = PrefKey<bool>._(
    'meshtastic.notifyNodes',
  );

  /// Whether the mesh map layer hides MQTT-only nodes. Defaults to **true** —
  /// see `MeshNodeStore.excludeMqtt`.
  static const PrefKey<bool> meshExcludeMqtt = PrefKey<bool>._(
    'map.meshExcludeMqtt',
  );

  /// The last known mesh node table (JSON strings, most-recently-heard first).
  /// Survives reconnects and restarts so the map and the node list have
  /// something to show with no radio attached. See `MeshNodeStore`.
  static const PrefKey<List<String>> meshNodes = PrefKey<List<String>>._(
    'meshtastic.nodes',
  );

  /// The mesh message log — the most recent messages as JSON strings, newest
  /// first. See `MeshChatController`. The radio's own replay queue is small,
  /// shared with telemetry, and lost on reboot, so the log is kept here.
  static const PrefKey<List<String>> meshMessages = PrefKey<List<String>>._(
    'meshtastic.messages',
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

  /// The most recent satellite element set, and when it was fetched.
  ///
  /// Cached as the raw TLE text: it is a few hundred bytes, it is the format
  /// every source speaks, and keeping it verbatim means the parser is the only
  /// thing that has to understand it.
  static const PrefKey<String> satelliteElements = PrefKey<String>._(
    'astro:satellite:tle',
  );
  static const PrefKey<int> satelliteElementsFetchedAt = PrefKey<int>._(
    'astro:satellite:fetchedAt',
  );
}
