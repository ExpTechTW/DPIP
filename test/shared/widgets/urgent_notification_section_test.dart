/// Pins the per-channel behaviour of the Android urgent-channel section.
///
/// The section is many channels behind one checklist item, so every state it
/// shows has to be scoped to one row: a spinner, a "still needs attention"
/// hint, a settings action. Getting any of them section-wide makes every
/// channel look like it is being changed, or like it was left unchanged.
library;

import 'package:dpip/core/notifications/urgent_notification_settings.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/widgets/permission_checklist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('en'),
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

UrgentNotificationChannelStatus _channel(
  String id,
  UrgentNotificationChannelState state, {
  String? name,
}) {
  final present =
      state == UrgentNotificationChannelState.bypasses ||
      state == UrgentNotificationChannelState.doesNotBypass;
  return UrgentNotificationChannelStatus(
    requestedId: id,
    channelId: present ? id : null,
    name: present ? (name ?? id) : null,
    state: state,
  );
}

const _allowed = 'Allowed during Do Not Disturb';
const _follows = 'Follows Do Not Disturb';
const _stillNeeded =
    'Still needs attention. Check the highlighted option in Settings.';

void main() {
  group('urgentUnchangedHint', () {
    final status = UrgentNotificationStatus([
      _channel('eew', UrgentNotificationChannelState.doesNotBypass),
      _channel('tsunami', UrgentNotificationChannelState.bypasses),
      _channel('storm', UrgentNotificationChannelState.missing),
    ]);

    test('nothing was opened, or nothing was read', () {
      expect(urgentUnchangedHint(null, status), isNull);
      expect(urgentUnchangedHint('eew', null), isNull);
    });

    test('the opened channel still following DND keeps the hint', () {
      expect(urgentUnchangedHint('eew', status), 'eew');
    });

    test('the opened channel now allowed clears it', () {
      expect(urgentUnchangedHint('tsunami', status), isNull);
    });

    test('a channel the system no longer reports clears it', () {
      expect(urgentUnchangedHint('storm', status), isNull);
      expect(urgentUnchangedHint('gone', status), isNull);
    });
  });

  group('UrgentNotificationSection', () {
    Future<List<UrgentNotificationChannelStatus>> pump(
      WidgetTester tester, {
      required UrgentNotificationStatus status,
      String? loadingChannelId,
      String? unchangedChannelId,
      bool blocked = false,
    }) async {
      final opened = <UrgentNotificationChannelStatus>[];
      await tester.pumpWidget(
        _wrap(
          UrgentNotificationSection(
            status: status,
            title: 'Major alerts in Do Not Disturb',
            description: 'Choose which channels may interrupt.',
            loadingChannelId: loadingChannelId,
            unchangedChannelId: unchangedChannelId,
            blocked: blocked,
            onOpen: (channel) async => opened.add(channel),
          ),
        ),
      );
      if (find.byType(ExpansionTile).evaluate().isNotEmpty) {
        await tester.tap(find.text('Major alerts in Do Not Disturb'));
        // Not pumpAndSettle: a row that is loading spins for ever. The tile's
        // own expansion animation is well under this.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
      }
      return opened;
    }

    Finder row(String title) => find.ancestor(
      of: find.text(title),
      matching: find.byType(PermissionRow),
    );

    final mixed = UrgentNotificationStatus([
      _channel(
        'eew',
        UrgentNotificationChannelState.doesNotBypass,
        name: 'EEW',
      ),
      _channel(
        'tsunami',
        UrgentNotificationChannelState.bypasses,
        name: 'Tsunami',
      ),
      _channel('storm', UrgentNotificationChannelState.missing),
      _channel('flood', UrgentNotificationChannelState.unavailable),
    ]);

    testWidgets('lists only the channels the system actually has', (
      tester,
    ) async {
      await pump(tester, status: mixed);

      expect(find.byType(PermissionRow), findsNWidgets(2));
      expect(
        find.descendant(of: row('EEW'), matching: find.text(_follows)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: row('Tsunami'), matching: find.text(_allowed)),
        findsOneWidget,
      );
    });

    testWidgets('renders nothing when no channel is present', (tester) async {
      await pump(
        tester,
        status: UrgentNotificationStatus([
          _channel('storm', UrgentNotificationChannelState.missing),
          _channel('flood', UrgentNotificationChannelState.unavailable),
        ]),
      );

      expect(find.byType(ExpansionTile), findsNothing);
      expect(find.byType(PermissionRow), findsNothing);
    });

    testWidgets('only an unsettled channel offers its settings', (
      tester,
    ) async {
      await pump(tester, status: mixed);

      expect(
        find.descendant(of: row('EEW'), matching: find.text('Open Settings')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: row('Tsunami'),
          matching: find.text('Open Settings'),
        ),
        findsNothing,
      );
    });

    testWidgets('the spinner belongs to the channel being opened', (
      tester,
    ) async {
      await pump(
        tester,
        status: UrgentNotificationStatus([
          _channel(
            'eew',
            UrgentNotificationChannelState.doesNotBypass,
            name: 'EEW',
          ),
          _channel(
            'storm',
            UrgentNotificationChannelState.doesNotBypass,
            name: 'Storm',
          ),
        ]),
        loadingChannelId: 'storm',
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(
        find.descendant(
          of: row('Storm'),
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
        reason: 'a section-wide flag would spin every channel',
      );
    });

    testWidgets('the unchanged hint belongs to the channel that was opened', (
      tester,
    ) async {
      await pump(
        tester,
        status: UrgentNotificationStatus([
          _channel(
            'eew',
            UrgentNotificationChannelState.doesNotBypass,
            name: 'EEW',
          ),
          _channel(
            'storm',
            UrgentNotificationChannelState.doesNotBypass,
            name: 'Storm',
          ),
        ]),
        unchangedChannelId: 'eew',
      );

      expect(find.text(_stillNeeded), findsOneWidget);
      expect(
        find.descendant(of: row('EEW'), matching: find.text(_stillNeeded)),
        findsOneWidget,
        reason: 'the channels nobody opened were never asked about',
      );
    });

    testWidgets('a tap opens that channel', (tester) async {
      final opened = await pump(tester, status: mixed);

      await tester.tap(
        find.descendant(of: row('EEW'), matching: find.text('Open Settings')),
      );
      await tester.pump();
      expect(opened.map((channel) => channel.channelId), ['eew']);
    });

    testWidgets('a busy page blocks every channel', (tester) async {
      final opened = await pump(tester, status: mixed, blocked: true);

      await tester.tap(
        find.descendant(of: row('EEW'), matching: find.text('Open Settings')),
        warnIfMissed: false,
      );
      await tester.pump();
      expect(opened, isEmpty);
    });
  });
}
