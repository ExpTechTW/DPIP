/// The onboarding preset step is the first write a new device makes to its
/// alert filters, and the last thing between a first launch and the app.
///
/// Two ways it can go wrong silently: report success without the server
/// holding the choice (the user believes they chose "emergency only" while
/// every channel still rings), or trap the user when the network or the push
/// token is not there yet. So each outcome is pinned against what the fake
/// server actually ended up holding, and every failure must leave a way out.
library;

import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/notifications/notification_service.dart';
import 'package:dpip/core/settings/setting_keys.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:dpip/features/notification/domain/notify_preset.dart';
import 'package:dpip/features/notification/domain/notify_repository.dart';
import 'package:dpip/features/notification/domain/notify_settings.dart';
import 'package:dpip/features/onboarding/presentation/widgets/onboarding_notify_presets.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// A fresh device: every channel at its local threshold.
NotifySettings _fresh() =>
    NotifySettings.fromWire(const [1, 1, 1, 1, 1, 1, 1, 1, 1]);

/// Echoes each write like the server, and fails the request numbered
/// [failAt] (fetches and writes counted together).
class _Server implements NotifyRepository {
  NotifySettings settings = _fresh();
  int requests = 0;
  int? failAt;

  bool get _fails => ++requests == failAt;

  @override
  Future<Result<NotifySettings>> fetch(String token) async =>
      _fails ? const Err(NetworkFailure('429')) : Ok(settings);

  @override
  Future<Result<NotifySettings>> setChannel(
    String token,
    NotifyChannel channel,
    int optionIndex,
  ) async {
    if (_fails) return const Err(NetworkFailure('429'));
    settings = settings.withChannel(channel, optionIndex);
    return Ok(settings);
  }
}

/// Long enough for every request of the widest change, 2 s apart.
const Duration _allRequests = Duration(seconds: 30);

late AppLocalizations l10n;

Future<void> _pump(
  WidgetTester tester, {
  required _Server server,
  required VoidCallback onFinish,
  String? token = 'token',
  double textScale = 1,
}) async {
  final settings = SettingsStore.inMemory(
    token == null ? const {} : {SettingKeys.pushToken.name: token},
  );
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<NotifyRepository>.value(value: server),
        Provider.value(value: NotificationService(settings)),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: Scaffold(body: OnboardingNotifyPresetsPage(onFinish: onFinish)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder _card(String title) =>
    find.widgetWithText(RadioListTile<NotifyPreset>, title);

void main() {
  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  testWidgets('three radio buttons, recommended checked to start with', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester, server: _Server(), onFinish: () {});

    expect(find.byType(RadioListTile<NotifyPreset>), findsNWidgets(3));
    expect(find.text(l10n.notifyPresetCustom), findsNothing);
    for (final (title, checked) in [
      (l10n.notifyPresetRecommended, true),
      (l10n.notifyPresetAll, false),
      (l10n.notifyPresetEmergencyOnly, false),
    ]) {
      expect(
        tester.getSemantics(_card(title)),
        isSemantics(
          isInMutuallyExclusiveGroup: true,
          hasCheckedState: true,
          isChecked: checked,
          isEnabled: true,
        ),
        reason: title,
      );
    }
    semantics.dispose();
  });

  testWidgets('the chosen preset is what the server ends up holding', (
    tester,
  ) async {
    final server = _Server();
    var finished = false;
    await _pump(tester, server: server, onFinish: () => finished = true);

    await tester.tap(_card(l10n.notifyPresetEmergencyOnly));
    await tester.pump();
    await tester.tap(find.text(l10n.onboardingStart));
    await tester.pump();

    // In flight: nothing can be changed, and the button says why.
    expect(find.text(l10n.notifyPresetApplying), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    expect(
      tester
          .widget<RadioListTile<NotifyPreset>>(_card(l10n.notifyPresetAll))
          .enabled,
      isFalse,
    );
    expect(finished, isFalse);

    await tester.pump(_allRequests);
    await tester.pumpAndSettle();

    expect(finished, isTrue);
    expect(NotifyPreset.matching(server.settings), NotifyPreset.emergencyOnly);
  });

  testWidgets('a failure offers a retry that resumes, and a way out', (
    tester,
  ) async {
    // Fetch, then the first write lands, then the second is refused.
    final server = _Server()..failAt = 3;
    var finished = false;
    await _pump(tester, server: server, onFinish: () => finished = true);

    await tester.tap(_card(l10n.notifyPresetEmergencyOnly));
    await tester.pump();
    await tester.tap(find.text(l10n.onboardingStart));
    await tester.pump(_allRequests);
    await tester.pumpAndSettle();

    expect(finished, isFalse);
    expect(find.text(l10n.notifySetFailed), findsOneWidget);
    expect(find.text(l10n.onboardingNotifySkip), findsOneWidget);
    expect(server.settings.optionOf(NotifyChannel.eew), 0, reason: 'kept');

    await tester.tap(find.text(l10n.commonRetry));
    await tester.pump(_allRequests);
    await tester.pumpAndSettle();

    expect(finished, isTrue);
    expect(NotifyPreset.matching(server.settings), NotifyPreset.emergencyOnly);
  });

  testWidgets('no push token yet: says so, writes nothing, can still leave', (
    tester,
  ) async {
    final server = _Server();
    var finished = false;
    await _pump(
      tester,
      server: server,
      token: null,
      onFinish: () => finished = true,
    );

    await tester.tap(find.text(l10n.onboardingStart));
    await tester.pumpAndSettle();

    expect(find.text(l10n.notifyUnavailable), findsOneWidget);
    expect(server.requests, 0);
    expect(finished, isFalse);

    await tester.tap(find.text(l10n.onboardingNotifySkip));
    await tester.pumpAndSettle();

    expect(finished, isTrue);
    expect(server.requests, 0);
  });

  testWidgets('picking another preset after a failure starts afresh', (
    tester,
  ) async {
    await _pump(tester, server: _Server(), token: null, onFinish: () {});
    await tester.tap(find.text(l10n.onboardingStart));
    await tester.pumpAndSettle();
    expect(find.text(l10n.notifyUnavailable), findsOneWidget);

    await tester.tap(_card(l10n.notifyPresetAll));
    await tester.pumpAndSettle();

    expect(find.text(l10n.notifyUnavailable), findsNothing);
    expect(find.text(l10n.onboardingStart), findsOneWidget);
    expect(find.text(l10n.onboardingNotifySkip), findsNothing);
  });

  testWidgets('lays out at twice the text size on a small phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await _pump(tester, server: _Server(), onFinish: () {}, textScale: 2);

    expect(tester.takeException(), isNull);
    // The body scrolls; the last card is reachable and the action stays put.
    await tester.dragUntilVisible(
      _card(l10n.notifyPresetEmergencyOnly),
      find.byType(SingleChildScrollView),
      const Offset(0, -200),
    );
    expect(_card(l10n.notifyPresetEmergencyOnly).hitTestable(), findsOneWidget);
    expect(find.text(l10n.onboardingStart).hitTestable(), findsOneWidget);
  });
}
