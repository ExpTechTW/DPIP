/// `needsAttention` is the whole contract of the red dot, and both of its
/// failure modes are bad: a dot that never lights leaves someone believing they
/// will be warned when they will not, and a dot that cannot be cleared teaches
/// them to ignore it. These pin which states light it and — just as
/// deliberately — which ones must not.
library;

import 'package:dpip/core/geo/location_service.dart';
import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/core/notifications/notification_service.dart';
import 'package:dpip/core/permissions/permission_health.dart';
import 'package:dpip/core/platform/background_execution.dart';
import 'package:dpip/core/platform/battery_optimization.dart';
import 'package:dpip/core/platform/unused_app_restrictions.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every permission granted, so the only thing that can light the badge in
/// these tests is the state each one is actually about. Without this the host's
/// unimplemented platform channels answer "denied", `needsAttention` is true no
/// matter what, and every "must NOT light" assertion below passes vacuously.
class _GrantedLocation extends LocationService {
  _GrantedLocation() : super(const TownDirectory({}));

  @override
  Future<bool> granted() async => true;

  @override
  Future<bool> backgroundGranted() async => true;
}

class _AllowedNotifications extends NotificationService {
  _AllowedNotifications(
    super.settings, {
    this.critical = true,
    this.criticalApplies = false,
  });

  final bool critical;

  /// Whether this platform has critical alerts at all. Overridden rather than
  /// read from `Platform`, which is the only way to exercise the iOS branch —
  /// the tests run on the host, where `Platform.isIOS` is false and the real
  /// getter would make every case below the Android one.
  @override
  final bool criticalApplies;

  @override
  Future<bool> criticalAllowed() async => critical;

  @override
  Future<bool> isAllowed() async => true;
}

class _FakeBattery extends BatteryOptimization {
  _FakeBattery(this._exempt);

  final bool _exempt;

  @override
  Future<bool> isIgnoring() async => _exempt;
}

class _FakeExecution extends BackgroundExecutionService {
  _FakeExecution(this._status);

  final BackgroundExecutionStatus _status;

  @override
  Future<BackgroundExecutionStatus> status() async => _status;
}

class _FakeUnusedApp extends UnusedAppRestrictionsService {
  _FakeUnusedApp(this._status);

  final UnusedAppRestrictions _status;

  @override
  Future<UnusedAppRestrictions> status() async => _status;
}

/// A health object with every permission granted, so `needsAttention` is false
/// until the state under test makes it true.
PermissionHealth _health({
  required BackgroundExecutionStatus execution,
  required UnusedAppRestrictions unusedApp,
  bool batteryExempt = true,
  bool critical = true,
  bool criticalApplies = false,
}) => PermissionHealth(
  location: _GrantedLocation(),
  notifications: _AllowedNotifications(
    SettingsStore.inMemory(),
    critical: critical,
    criticalApplies: criticalApplies,
  ),
  execution: _FakeExecution(execution),
  unusedApp: _FakeUnusedApp(unusedApp),
  battery: _FakeBattery(batteryExempt),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a fully healthy device shows nothing — the baseline', () async {
    final health = _health(
      execution: const BackgroundExecutionStatus(known: true),
      unusedApp: UnusedAppRestrictions.exempt,
    );
    await health.refresh();

    expect(
      health.needsAttention,
      isFalse,
      reason:
          'every other test asserts against this; if the fakes stop granting, '
          'needsAttention is true everywhere and the negative cases below all '
          'pass without testing anything',
    );
  });

  test('hibernation lights the badge', () async {
    final health = _health(
      execution: const BackgroundExecutionStatus(known: true),
      unusedApp: UnusedAppRestrictions.restricted,
    );
    await health.refresh();

    expect(health.keptActive, isFalse);
    expect(
      health.needsAttention,
      isTrue,
      reason:
          'Android revokes the permissions and force-stops the package after '
          'months unopened, and a stopped package receives no broadcast at all '
          '— not even the boot re-arm recovers it',
    );
  });

  test('a device that cannot answer about hibernation is left alone', () async {
    final health = _health(
      execution: const BackgroundExecutionStatus(known: true),
      unusedApp: UnusedAppRestrictions.unavailable,
    );
    await health.refresh();

    expect(health.keptActive, isTrue);
    expect(
      health.needsAttention,
      isFalse,
      reason: 'there is nothing on such a device for the user to change',
    );
  });

  test('a blocked background state lights the badge', () async {
    final health = _health(
      execution: const BackgroundExecutionStatus(restricted: true, known: true),
      unusedApp: UnusedAppRestrictions.exempt,
    );
    await health.refresh();

    expect(health.backgroundExecutionAllowed, isFalse);
    expect(health.needsAttention, isTrue);
  });

  test(
    'a policy-locked device is not accused of something it cannot fix',
    () async {
      final health = _health(
        execution: const BackgroundExecutionStatus(
          restricted: true,
          lockedByPolicy: true,
          known: true,
        ),
        unusedApp: UnusedAppRestrictions.exempt,
      );
      await health.refresh();

      expect(
        health.needsAttention,
        isFalse,
        reason:
            'under an MDM or parental-control profile the switch is not the '
            "user's to flip, so a badge would be a permanent unclearable mark",
      );
    },
  );

  test('an unanswered platform raises nothing', () async {
    final health = _health(
      // `known: false` is what an unsupported platform, an older build without
      // the plugin, or a failed call all produce. `restricted` is left at its
      // default here on purpose: the point is that the *absence* of an answer
      // must never be read as a problem.
      execution: const BackgroundExecutionStatus(),
      unusedApp: UnusedAppRestrictions.unavailable,
    );
    await health.refresh();

    expect(health.backgroundExecutionAllowed, isTrue);
    expect(health.needsAttention, isFalse);
  });

  /// The app holds Apple's critical-alert entitlement, so this grant really is
  /// the user's to give and to restore in Settings — and it is what makes a
  /// life-threatening warning sound through silent mode and Do Not Disturb at
  /// 3am, which is when it matters.
  test('a denied critical-alert grant lights the badge on iOS', () async {
    final health = _health(
      execution: const BackgroundExecutionStatus(known: true),
      unusedApp: UnusedAppRestrictions.exempt,
      critical: false,
      criticalApplies: true,
    );
    await health.refresh();

    expect(health.criticalAlertsAllowed, isFalse);
    expect(health.needsAttention, isTrue);
  });

  test('Android is never accused of missing critical alerts', () async {
    final health = _health(
      execution: const BackgroundExecutionStatus(known: true),
      unusedApp: UnusedAppRestrictions.exempt,
      // What the platform reports where the permission does not exist. Reading
      // it as "not granted" would put a permanent warning on every Android
      // device, which is why the applicability check is a seam of its own.
      critical: false,
      criticalApplies: false,
    );
    await health.refresh();

    expect(health.criticalAlertsAllowed, isTrue);
    expect(health.needsAttention, isFalse);
  });

  /// Doze does not stop a high-priority alert — FCM wakes the device for one —
  /// but it does throttle `setAndAllowWhileIdle` to about one fire every nine
  /// minutes, which puts the alarm spine's five-minute floor out of reach on the
  /// devices where that alarm is the only spine, and it delays geofence
  /// transitions. On a disaster app the latency is the product.
  test('a device Doze can throttle lights the badge', () async {
    final health = _health(
      execution: const BackgroundExecutionStatus(known: true),
      unusedApp: UnusedAppRestrictions.exempt,
      batteryExempt: false,
    );
    await health.refresh();

    expect(health.batteryExempt, isFalse);
    expect(health.needsAttention, isTrue);
  });
}
