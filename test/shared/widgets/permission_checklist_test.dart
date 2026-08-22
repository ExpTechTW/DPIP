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
}
