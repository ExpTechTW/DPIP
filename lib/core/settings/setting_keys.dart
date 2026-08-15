/// The single registry of every setting the app persists.
///
/// Keys used to live as private literals inside each settings object, so the
/// whole persisted surface could not be seen in one place — which makes
/// collisions and migrations easy to get wrong. They are centralised here (one
/// file to audit); each store keeps owning its own read/write logic and just
/// references a key from here.
///
/// A key is a typed [SettingKey], not a bare `String`. Its constructor is
/// private, so a `SettingKey` can only be minted in this library — every
/// instance is one of the `static const` fields below. Combined with the
/// [SettingsStore] facade (whose methods take a `SettingKey`, never a
/// `String`), an ad-hoc key physically cannot reach storage: the compiler
/// rejects it, not code review.
///
/// **Never change an existing string** without a migration: it is the storage
/// address of already-saved user data. New keys follow `<area>.<name>`.
library;

/// A typed handle to one persisted setting.
///
/// `T` is the value type stored under it (a phantom type — there is no field of
/// type `T`); it is what lets [SettingsStore] reject a type-mismatched read/write at
/// compile time. The private constructor is the closure: no code outside this
/// library can construct a `SettingKey`.
final class SettingKey<T> {
  const SettingKey._(this.name);

  /// The on-disk storage address. Public so [SettingsStore] (a separate
  /// library) can read it; harmless because no [SettingsStore] method accepts
  /// a raw `String`, so a name can never be fed back in to mint an ad-hoc key.
  final String name;
}

/// The typed key registry — the only source of [SettingKey]s in the app.
abstract final class SettingKeys {
  const SettingKeys._();

  /// First-launch onboarding completion flag. See `OnboardingStore`.
  static const SettingKey<bool> onboardingComplete = SettingKey<bool>._(
    'onboarding.complete',
  );

  /// Selected UI language override (locale tag; empty/absent = system). See
  /// `LocaleController`.
  static const SettingKey<String> locale = SettingKey<String>._('app.locale');

  /// Selected theme mode (`light` / `dark`; empty/absent = follow system). See
  /// `ThemeController`.
  static const SettingKey<String> themeMode = SettingKey<String>._(
    'app.themeMode',
  );

  /// Default map overlay when opening the Map tab. See
  /// `DefaultMapLayerController` (`radar` / `satellite` / … / `dpm`).
  static const SettingKey<String> defaultMapLayer = SettingKey<String>._(
    'map.defaultLayer',
  );

  /// User-customised layer order in the map layer picker (layer ids,
  /// most-preferred first; empty = the surface's declared order). See
  /// `MapLayerOrderController`.
  static const SettingKey<List<String>> mapLayerOrder =
      SettingKey<List<String>>._('map.layerOrder');

  /// User-customised category order in the map layer picker (category names,
  /// most-preferred first; empty = the declared category order). See
  /// `MapLayerOrderController`.
  static const SettingKey<List<String>> mapLayerCategoryOrder =
      SettingKey<List<String>>._('map.layerCategoryOrder');

  /// Saved Home township codes (ordered list). See `RegionStore`.
  static const SettingKey<List<String>> savedRegionCodes =
      SettingKey<List<String>>._('home.savedRegionCodes');

  /// Experimental weather-animation override. See `ExperimentalSettings`.
  static const SettingKey<String> weatherMode = SettingKey<String>._(
    'experimental.weatherMode',
  );

  /// Experimental time-of-day override for the backdrop. See
  /// `ExperimentalSettings`.
  static const SettingKey<String> skyTimeMode = SettingKey<String>._(
    'experimental.skyTimeMode',
  );

  /// Whether the experimental-features menu is unlocked. Hidden behind ten taps
  /// on the Developer page's version row so accidental users never see it. See
  /// `ExperimentalSettings`.
  static const SettingKey<bool> experimentalUnlocked = SettingKey<bool>._(
    'experimental.unlocked',
  );

  /// Last push token — the FCM registration token on Android, the raw APNs
  /// device token on iOS (backend registration keys on whichever this
  /// platform actually uses). See `NotificationService`.
  static const SettingKey<String> pushToken = SettingKey<String>._(
    'notification.pushToken',
  );

  /// Notification-channel catalogue version (forces Android re-create). See
  /// `NotificationService`.
  static const SettingKey<int> channelVersion = SettingKey<int>._(
    'notification.channelVersion',
  );

  /// Last successful *attempt* to POST `updateDeviceLocation` (UTC millis).
  /// Foreground reporter skips a new call within 60s — server 429 guard.
  static const SettingKey<int> deviceLocationUpdatedAtMs = SettingKey<int>._(
    'location.deviceLocationUpdatedAtMs',
  );

  /// The radio `MeshLink` keeps reconnecting to (BLE id), and its name for
  /// display. Their presence *is* the intent to stay connected — removed by
  /// `MeshLink.detach()`, which is the only thing that stops reconnection.
  static const SettingKey<String> meshDeviceId = SettingKey<String>._(
    'meshtastic.deviceId',
  );
  static const SettingKey<String> meshDeviceName = SettingKey<String>._(
    'meshtastic.deviceName',
  );

  /// Local (never pushed) mesh notifications. Messages default on; new-node
  /// alerts default **off** — a busy mesh introduces neighbours all day. See
  /// `MeshAlerts`.
  static const SettingKey<bool> meshNotifyMessages = SettingKey<bool>._(
    'meshtastic.notifyMessages',
  );
  static const SettingKey<bool> meshNotifyNodes = SettingKey<bool>._(
    'meshtastic.notifyNodes',
  );

  /// Whether the mesh map layer hides MQTT-only nodes. Defaults to **true** —
  /// see `MeshNodeStore.excludeMqtt`.
  static const SettingKey<bool> meshExcludeMqtt = SettingKey<bool>._(
    'map.meshExcludeMqtt',
  );

  /// The newest release the update dialog has already offered (tag, e.g.
  /// `v3.2.1`). The prompt is once per version, so this is written the moment
  /// the dialog is shown — see `UpdatePrompt`.
  static const SettingKey<String> updatePromptedVersion = SettingKey<String>._(
    'update.promptedVersion',
  );

  /// Selected LB / Core API region. See `RegionSelection`.
  ///
  /// Colon-form kept as-is (pre-existing storage address).
  static const SettingKey<String> regionLb = SettingKey<String>._(
    'network:region:lb',
  );
  static const SettingKey<String> regionCore = SettingKey<String>._(
    'network:region:core',
  );
}
