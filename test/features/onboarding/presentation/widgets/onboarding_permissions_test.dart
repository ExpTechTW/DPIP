/// The onboarding flow's last step: encourage — never require — the
/// permissions a disaster alert depends on, then let the user finish either
/// way.
///
/// [OnboardingPermissionsPage] reads no permission itself; it only watches
/// [PermissionChecklist]'s [PermissionState] and decides, in `_finish`,
/// whether leaving needs a second tap. That decision rests on
/// [PermissionState.essentialsGranted] (`notify && location`) — the two
/// without which a warning cannot reach this user at all, unlike background
/// location or the battery exemption, which degrade delivery without
/// silencing it outright. Getting the gate backwards fails in one of two
/// silent directions: too strict nags a fully-granted user forever; too loose
/// — e.g. `||` where the source has `&&` — lets a phone with only one of the
/// two essentials leave onboarding with no warning ever shown, on the one
/// screen whose job is to show it.
///
/// `_state` starts null, before the checklist's first async read lands, and
/// `_state?.essentialsGranted ?? false` treats "not yet known" as "missing" —
/// the only safe reading for a gate like this. That default also means the
/// gate can never be more permissive than the checklist it watches: if
/// [NotificationService.isAllowed] ever throws (it has no try/catch, unlike
/// every other platform read reachable from this page), the checklist's
/// refresh never reaches its `onChanged` call, `_state` stays null forever,
/// and this page would ask the user to confirm on every single finish rather
/// than only the ones that deserve it.
library;

import 'package:dpip/core/geo/location_service.dart';
import 'package:dpip/core/geo/location_status.dart';
import 'package:dpip/core/geo/town.dart';
import 'package:dpip/core/notifications/foreground_eew_announcement_gate.dart';
import 'package:dpip/core/notifications/notification_service.dart';
import 'package:dpip/core/permissions/permission_health.dart';
import 'package:dpip/core/permissions/permission_outcome.dart';
import 'package:dpip/features/onboarding/presentation/widgets/onboarding_permissions.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/widgets/permission_checklist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// Every member of [NotificationService]'s interface is implemented, even
/// where a plain default would do, so a future addition to that interface
/// fails this file at compile time instead of quietly not being simulated.
class _FakeNotificationService implements NotificationService {
  _FakeNotificationService({this.allowed = false});

  /// Drives [PermissionState.notify] via [isAllowed].
  bool allowed;

  @override
  Future<bool> isAllowed() async => allowed;

  @override
  bool get criticalApplies => false;

  @override
  Future<bool> criticalAllowed() => throw UnimplementedError();

  @override
  Future<PermissionOutcome> requestPermission() => throw UnimplementedError();

  @override
  Future<PermissionOutcome> requestCritical() => throw UnimplementedError();

  @override
  Future<bool> openSystemSettings() => throw UnimplementedError();

  @override
  Future<void> init() => throw UnimplementedError();

  @override
  Future<bool> showTest(String channelKey) => throw UnimplementedError();

  @override
  Future<void> showDebugEewWarning({
    required String title,
    required String body,
  }) => throw UnimplementedError();

  @override
  String? get token => null;

  @override
  ForegroundEewAnnouncementGate get foregroundEewGate =>
      throw UnimplementedError();
}

/// As above: every [LocationService] member is stubbed explicitly.
class _FakeLocationService implements LocationService {
  _FakeLocationService({this.isGranted = false});

  /// Drives [PermissionState.location] via [granted].
  bool isGranted;

  @override
  Future<bool> granted() async => isGranted;

  // Only reached when [granted] is true (PermissionHealth.refresh short-
  // circuits background to false otherwise) — false is a safe, unexercised
  // default since no test here depends on background specifically.
  @override
  Future<bool> backgroundGranted() async => false;

  @override
  Future<LocationStatus> status() => throw UnimplementedError();

  @override
  Stream<bool> serviceEnabledStream() => throw UnimplementedError();

  @override
  Future<bool> openSettings() => throw UnimplementedError();

  @override
  Future<PermissionOutcome> requestPermission() => throw UnimplementedError();

  @override
  Future<PermissionOutcome> requestBackground() => throw UnimplementedError();

  @override
  Stream<GpsFix> positionStream({int distanceFilterMeters = 250}) =>
      throw UnimplementedError();

  @override
  Future<GpsFix?> currentFix() => throw UnimplementedError();

  @override
  Future<GpsFix?> lastKnownFix() => throw UnimplementedError();

  @override
  Future<Town?> currentTown() => throw UnimplementedError();

  @override
  Future<Town?> townAt(double lat, double lng) => throw UnimplementedError();
}

/// [OnboardingPermissionsPage] unconditionally embeds [PermissionChecklist],
/// which reads [NotificationService], [LocationService] and [PermissionHealth]
/// via `context.read` from inside a post-frame callback — all three must be
/// supplied or the page throws before it ever finishes building.
Widget _wrap(
  Widget child, {
  required _FakeNotificationService notifications,
  required _FakeLocationService location,
}) {
  return MultiProvider(
    providers: [
      Provider<NotificationService>.value(value: notifications),
      Provider<LocationService>.value(value: location),
      ChangeNotifierProvider<PermissionHealth>(
        create: (_) =>
            PermissionHealth(location: location, notifications: notifications),
      ),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  testWidgets('renders the heading, body copy, and the embedded checklist', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        OnboardingPermissionsPage(onFinish: () {}),
        notifications: _FakeNotificationService(),
        location: _FakeLocationService(),
      ),
    );
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(
      tester.element(find.byType(OnboardingPermissionsPage)),
    );
    expect(find.text(l10n.onboardingPermsTitle), findsOneWidget);
    expect(find.text(l10n.onboardingPermsBody), findsOneWidget);
    expect(find.byType(PermissionChecklist), findsOneWidget);
  });

  testWidgets('both essentials granted finishes immediately, with no dialog', (
    tester,
  ) async {
    var finished = false;
    await tester.pumpWidget(
      _wrap(
        OnboardingPermissionsPage(onFinish: () => finished = true),
        notifications: _FakeNotificationService(allowed: true),
        location: _FakeLocationService(isGranted: true),
      ),
    );
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(
      tester.element(find.byType(OnboardingPermissionsPage)),
    );
    await tester.tap(find.text(l10n.onboardingStart));
    await tester.pumpAndSettle();

    expect(finished, isTrue);
    expect(find.byType(AlertDialog), findsNothing);
  });

  for (final missing in ['notify', 'location']) {
    testWidgets(
      'missing only $missing still asks to confirm before finishing — '
      'essentialsGranted is a conjunction, not either alone',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            OnboardingPermissionsPage(onFinish: () {}),
            notifications: _FakeNotificationService(
              allowed: missing != 'notify',
            ),
            location: _FakeLocationService(isGranted: missing != 'location'),
          ),
        );
        await tester.pumpAndSettle();

        final l10n = AppLocalizations.of(
          tester.element(find.byType(OnboardingPermissionsPage)),
        );
        await tester.tap(find.text(l10n.onboardingStart));
        await tester.pumpAndSettle();

        expect(find.text(l10n.onboardingSkipTitle), findsOneWidget);
      },
    );
  }

  testWidgets(
    'missing an essential, then Stay: onFinish never fires and the dialog closes',
    (tester) async {
      var finished = false;
      await tester.pumpWidget(
        _wrap(
          OnboardingPermissionsPage(onFinish: () => finished = true),
          notifications: _FakeNotificationService(),
          location: _FakeLocationService(),
        ),
      );
      await tester.pumpAndSettle();

      final l10n = AppLocalizations.of(
        tester.element(find.byType(OnboardingPermissionsPage)),
      );
      await tester.tap(find.text(l10n.onboardingStart));
      await tester.pumpAndSettle();
      expect(find.text(l10n.onboardingSkipTitle), findsOneWidget);

      await tester.tap(find.text(l10n.onboardingSkipStay));
      await tester.pumpAndSettle();

      expect(finished, isFalse);
      expect(find.byType(AlertDialog), findsNothing);
    },
  );

  testWidgets('missing an essential, then Leave: onFinish still fires', (
    tester,
  ) async {
    var finished = false;
    await tester.pumpWidget(
      _wrap(
        OnboardingPermissionsPage(onFinish: () => finished = true),
        notifications: _FakeNotificationService(allowed: true),
        // Location withheld, so essentialsGranted is still false even though
        // notify alone is true.
        location: _FakeLocationService(),
      ),
    );
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(
      tester.element(find.byType(OnboardingPermissionsPage)),
    );
    await tester.tap(find.text(l10n.onboardingStart));
    await tester.pumpAndSettle();
    expect(find.text(l10n.onboardingSkipTitle), findsOneWidget);

    await tester.tap(find.text(l10n.onboardingSkipLeave));
    await tester.pumpAndSettle();

    expect(finished, isTrue);
  });
}
