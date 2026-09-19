import 'package:dpip/core/notifications/urgent_notification_settings.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/widgets/permission_checklist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child, {TextScaler? textScaler}) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('en'),
  builder: textScaler == null
      ? null
      : (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: textScaler),
          child: child!,
        ),
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

UrgentNotificationChannelStatus _channel(
  String id,
  UrgentNotificationChannelState state,
) => UrgentNotificationChannelStatus(
  requestedId: id,
  channelId: id,
  name: id,
  state: state,
);

Widget _urgentSection(List<UrgentNotificationChannelStatus> channels) =>
    UrgentNotificationSection(
      status: UrgentNotificationStatus(channels),
      title: 'Major alerts in Do Not Disturb',
      description: 'Choose which channels may interrupt.',
      loadingChannelId: null,
      unchangedChannelId: null,
      blocked: false,
      onOpen: (_) async {},
    );

void main() {
  testWidgets('loading state is visible and disables its action', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        PermissionRow(
          icon: Icons.location_on_outlined,
          title: 'Location',
          description: 'Used for local alerts',
          granted: false,
          loading: true,
          onGrant: () async {},
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('returning without a grant shows actionable feedback', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        PermissionRow(
          icon: Icons.notifications_outlined,
          title: 'Notifications',
          description: 'Used for alerts',
          granted: false,
          settingsAction: true,
          feedback: PermissionRowFeedback.stillNeeded,
          onGrant: () async {},
        ),
      ),
    );

    expect(
      find.text(
        'Still needs attention. Check the highlighted option in Settings.',
      ),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    expect(find.text('Open Settings'), findsOneWidget);
  });

  testWidgets('a channel still under Do Not Disturb marks the closed header', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _wrap(
        _urgentSection([
          _channel('tsunami', UrgentNotificationChannelState.bypasses),
          _channel('eew', UrgentNotificationChannelState.doesNotBypass),
        ]),
      ),
    );

    // The row saying so is inside the collapsed section, so the dot on the
    // header is the only thing the user has to go on.
    expect(find.text('Follows Do Not Disturb'), findsNothing);
    expect(find.byType(Badge), findsOneWidget);
    // The header tile merges its parts into one node, so the dot's label is
    // read out with the title rather than on its own.
    expect(
      find.bySemanticsLabel(RegExp('Permissions need attention')),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('every channel allowed leaves the header unmarked', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        _urgentSection([
          _channel('tsunami', UrgentNotificationChannelState.bypasses),
          _channel('eew', UrgentNotificationChannelState.bypasses),
        ]),
      ),
    );

    expect(find.byType(Badge), findsNothing);
  });

  testWidgets('long guidance remains usable on a narrow large-text display', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _wrap(
        PermissionRow(
          icon: Icons.factory_outlined,
          title: 'Manufacturer background manager',
          description:
              'Allow automatic startup and background activity for DPIP.',
          granted: false,
          advisory: true,
          settingsAction: true,
          feedback: PermissionRowFeedback.verifyManually,
          onGrant: () async {},
        ),
        textScaler: const TextScaler.linear(2),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Open Settings'), findsOneWidget);
  });

  testWidgets('a settled preference drops its settings action', (tester) async {
    await tester.pumpWidget(
      _wrap(
        PermissionRow(
          icon: Icons.notifications_active_outlined,
          title: 'Major EEW',
          description: 'Allowed during Do Not Disturb',
          granted: true,
          settingsAction: true,
          onGrant: () async {},
        ),
      ),
    );

    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(find.text('Open Settings'), findsNothing);
    expect(find.byType(OutlinedButton), findsNothing);
  });
}
