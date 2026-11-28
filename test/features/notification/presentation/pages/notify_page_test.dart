/// The notify page is the only place a channel filter is changed. A load
/// error that looks like "nothing to set", or a failed save that still moves
/// the check, would leave the phone subscribed to the wrong alerts.
library;

import 'package:dpip/core/settings/locale_config.dart';
import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/notifications/notification_channels.dart';
import 'package:dpip/core/notifications/notification_service.dart';
import 'package:dpip/core/notifications/plain_channels.dart';
import 'package:dpip/core/settings/setting_keys.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:dpip/features/notification/domain/notify_preset.dart';
import 'package:dpip/features/notification/domain/notify_repository.dart';
import 'package:dpip/features/notification/domain/notify_settings.dart';
import 'package:dpip/features/notification/presentation/notify_labels.dart';
import 'package:dpip/features/notification/presentation/pages/notify_page.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/navigation/app_routes.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

const Size _tall = Size(400, 4000);

NotifySettings _settings() =>
    NotifySettings.fromWire(List<int>.filled(NotifyChannel.values.length, 0));

class _Repo implements NotifyRepository {
  _Repo(this._result);

  Result<NotifySettings> _result;
  int sets = 0;

  @override
  Future<Result<NotifySettings>> fetch(String token) async => _result;

  @override
  Future<Result<NotifySettings>> setChannel(
    String token,
    NotifyChannel channel,
    int optionIndex,
  ) async {
    sets++;
    final next = List<int>.filled(NotifyChannel.values.length, 0);
    next[channel.index] = optionIndex;
    _result = Ok(NotifySettings.fromWire(next));
    return _result;
  }
}

Future<void> _pump(
  WidgetTester tester, {
  required NotifyRepository repo,
  String? token,
  PlainChannels? plainChannels,
}) async {
  tester.view.physicalSize = _tall;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final store = SettingsStore.inMemory(
    token == null ? const {} : {SettingKeys.pushToken.name: token},
  );
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => const NotifyPage()),
      GoRoute(
        name: AppRoutes.notifyTest,
        path: '/test',
        builder: (_, _) => const Scaffold(body: Text('test-page')),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<NotifyRepository>.value(value: repo),
        Provider(
          create: (_) => NotificationService(
            store,
            // Off Android unless a test says otherwise: the host is not one.
            plainChannels: plainChannels ?? PlainChannels(isAndroid: false),
          ),
        ),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  presetTests();
  channelVolumeTests();

  testWidgets('no token shows the unavailable state', (tester) async {
    await _pump(tester, repo: _Repo(Ok(_settings())));
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l10n.notifyUnavailable), findsOneWidget);
    expect(find.text(l10n.notifyTitle), findsOneWidget);
  });

  testWidgets('a failed fetch offers retry and then the channel list', (
    tester,
  ) async {
    final repo = _Repo(const Err(NetworkFailure('down')));
    await _pump(tester, repo: repo, token: 'token');
    expect(find.text('down'), findsOneWidget);

    repo._result = Ok(_settings());
    await tester.tap(find.byType(FilledButton).first);
    await tester.pumpAndSettle();

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(
      find.text(notifyChannelTitle(NotifyChannel.eew, l10n)),
      findsOneWidget,
    );
    expect(find.byType(Divider), findsWidgets);
  });

  testWidgets('picking another option saves it', (tester) async {
    final repo = _Repo(Ok(_settings()));
    await _pump(tester, repo: repo, token: 'token');
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));

    await tester.tap(find.text(notifyChannelTitle(NotifyChannel.eew, l10n)));
    await tester.pumpAndSettle();
    final all = notifyOptionLabel(NotifyOptionKind.all, l10n);
    await tester.tap(find.text(all).last);
    await tester.pumpAndSettle();

    expect(repo.sets, 1);
    expect(find.text(all), findsWidgets);
  });

  testWidgets('a failed save keeps the old option and says so', (tester) async {
    final repo = _FailingSave(_settings());
    await _pump(tester, repo: repo, token: 'token');
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));

    await tester.tap(
      find.text(notifyChannelTitle(NotifyChannel.monitor, l10n)),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.text(notifyOptionLabel(NotifyOptionKind.all, l10n)).last,
    );
    await tester.pumpAndSettle();
    expect(find.text(l10n.notifySetFailed), findsOneWidget);
  });
}

class _FailingSave implements NotifyRepository {
  _FailingSave(this.settings);

  final NotifySettings settings;

  @override
  Future<Result<NotifySettings>> fetch(String token) async => Ok(settings);

  @override
  Future<Result<NotifySettings>> setChannel(
    String token,
    NotifyChannel channel,
    int optionIndex,
  ) async => const Err(NetworkFailure('save failed'));
}

/// Echoes each write into the full settings, like the server does — what a
/// preset needs to be seen landing — and can fail the write numbered
/// [failSetAt].
class _EchoRepo implements NotifyRepository {
  _EchoRepo(this.settings);

  NotifySettings settings;
  int sets = 0;
  int? failSetAt;

  @override
  Future<Result<NotifySettings>> fetch(String token) async => Ok(settings);

  @override
  Future<Result<NotifySettings>> setChannel(
    String token,
    NotifyChannel channel,
    int optionIndex,
  ) async {
    sets++;
    if (failSetAt == sets) return const Err(NetworkFailure('429'));
    settings = settings.withChannel(channel, optionIndex);
    return Ok(settings);
  }
}

/// Every channel at its local threshold — a fresh device, which is custom.
NotifySettings _fresh() =>
    NotifySettings.fromWire(const [1, 1, 1, 1, 1, 1, 1, 1, 1]);

NotifySettings _presetSettings(NotifyPreset preset) => NotifySettings.fromWire([
  for (final channel in NotifyChannel.values) preset.optionFor(channel)!,
]);

Finder _presetRow(NotifyPreset preset, AppLocalizations l10n) =>
    find.widgetWithText(
      RadioListTile<NotifyPreset>,
      notifyPresetLabel(preset, l10n),
    );

/// Long enough for every request of the widest preset, 2 s apart.
const Duration _allRequests = Duration(seconds: 30);

void presetTests() {
  group('presets', () {
    testWidgets('each preset is a radio button; custom is the checked one', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _pump(tester, repo: _EchoRepo(_fresh()), token: 'token');
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));

      for (final preset in NotifyPreset.values) {
        final checked = preset == NotifyPreset.custom;
        expect(
          tester.getSemantics(_presetRow(preset, l10n)),
          isSemantics(
            isInMutuallyExclusiveGroup: true,
            hasCheckedState: true,
            isChecked: checked,
            hasEnabledState: true,
            isEnabled: true,
          ),
          reason: preset.name,
        );
      }
      semantics.dispose();
    });

    testWidgets('settings that match a preset check it; custom then disables', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _pump(
        tester,
        repo: _EchoRepo(_presetSettings(NotifyPreset.emergencyOnly)),
        token: 'token',
      );
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));

      expect(
        tester.getSemantics(_presetRow(NotifyPreset.emergencyOnly, l10n)),
        isSemantics(isChecked: true),
      );
      // Nothing to apply, so nothing to offer a screen reader.
      expect(
        tester.getSemantics(_presetRow(NotifyPreset.custom, l10n)),
        isSemantics(isChecked: false, isEnabled: false),
      );
      semantics.dispose();
    });

    testWidgets('leaving custom asks first; cancelling sends nothing', (
      tester,
    ) async {
      final repo = _EchoRepo(_fresh());
      await _pump(tester, repo: repo, token: 'token');
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));

      await tester.tap(_presetRow(NotifyPreset.all, l10n));
      await tester.pumpAndSettle();
      expect(find.text(l10n.notifyPresetConfirmBody), findsOneWidget);

      await tester.tap(find.text(l10n.commonCancel));
      await tester.pumpAndSettle();
      expect(repo.sets, 0);
    });

    testWidgets('applying fills the channels in and checks the preset', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final repo = _EchoRepo(_fresh());
      await _pump(tester, repo: repo, token: 'token');
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));

      await tester.tap(_presetRow(NotifyPreset.emergencyOnly, l10n));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.notifyPresetApply));
      await tester.pump();

      // In flight: the chosen row spins — and says so to a screen reader —
      // and every channel row is locked.
      final applying = tester.getSemantics(
        _presetRow(NotifyPreset.emergencyOnly, l10n),
      );
      expect(applying.label, contains(l10n.notifyPresetApplying));
      expect(applying, isSemantics(isChecked: true));
      final eewRow = tester.widget<ListTile>(
        find.widgetWithText(
          ListTile,
          notifyChannelTitle(NotifyChannel.eew, l10n),
        ),
      );
      expect(eewRow.enabled, isFalse);

      await tester.pump(_allRequests);
      await tester.pumpAndSettle();

      expect(NotifyPreset.matching(repo.settings), NotifyPreset.emergencyOnly);
      expect(
        tester
            .widget<RadioGroup<NotifyPreset>>(
              find.byType(RadioGroup<NotifyPreset>),
            )
            .groupValue,
        NotifyPreset.emergencyOnly,
      );
      expect(
        find.text(notifyOptionLabel(NotifyOptionKind.localIntensity4, l10n)),
        findsOneWidget,
        reason: 'the EEW row shows what the server now holds',
      );
      expect(find.text(l10n.notifySetFailed), findsNothing);
      semantics.dispose();
    });

    testWidgets('a failure part-way says so and shows the real state', (
      tester,
    ) async {
      final repo = _EchoRepo(_presetSettings(NotifyPreset.recommended))
        ..failSetAt = 2;
      await _pump(tester, repo: repo, token: 'token');
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));

      // From a preset, not custom: no confirmation in the way.
      await tester.tap(_presetRow(NotifyPreset.emergencyOnly, l10n));
      await tester.pump(_allRequests);
      await tester.pumpAndSettle();

      expect(find.text(l10n.notifySetFailed), findsOneWidget);
      expect(repo.sets, 2);
      expect(
        tester
            .widget<RadioGroup<NotifyPreset>>(
              find.byType(RadioGroup<NotifyPreset>),
            )
            .groupValue,
        NotifyPreset.custom,
      );
    });
  });
}

/// The entry for channels an older version created on the wrong volume. It
/// must say nothing at all unless Android reports a mismatch, and when it does,
/// the way out it offers must be the app-info page.
void channelVolumeTests() {
  group('channel volume entry', () {
    const native = MethodChannel('test/plain_notification_channels');
    const permissions = MethodChannel(
      'flutter.baseflow.com/permissions/methods',
    );
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

    tearDown(() {
      messenger.setMockMethodCallHandler(native, null);
      messenger.setMockMethodCallHandler(permissions, null);
    });

    /// Android reporting every sound channel on the stream the catalogue asks
    /// for, except [overrides].
    PlainChannels android([Map<String, int> overrides = const {}]) {
      messenger.setMockMethodCallHandler(native, (call) async {
        if (call.method != 'usages') return null;
        return {
          for (final channel in NotificationChannels.channels)
            if (PlainChannels.usageOf(channel) case final usage?)
              channel.channelKey!: usage.android,
          ...overrides,
        };
      });
      return PlainChannels(channel: native, isAndroid: true);
    }

    testWidgets('says nothing when every channel matches', (tester) async {
      await _pump(
        tester,
        repo: _Repo(Ok(_settings())),
        token: 'token',
        plainChannels: android(),
      );
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));

      expect(find.text(l10n.notifyVolumeMismatchTitle), findsNothing);
      expect(find.text(l10n.notifyPresetSection), findsOneWidget);
    });

    testWidgets('says nothing off Android, and never asks', (tester) async {
      var asked = false;
      messenger.setMockMethodCallHandler(native, (call) async {
        asked = true;
        return {'eq-v2': 4};
      });
      await _pump(
        tester,
        repo: _Repo(Ok(_settings())),
        token: 'token',
        plainChannels: PlainChannels(channel: native, isAndroid: false),
      );
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));

      expect(find.text(l10n.notifyVolumeMismatchTitle), findsNothing);
      expect(asked, isFalse);
    });

    testWidgets('names each channel, its volume, and the way to change it', (
      tester,
    ) async {
      var opened = 0;
      messenger.setMockMethodCallHandler(permissions, (call) async {
        if (call.method == 'openAppSettings') opened++;
        return true;
      });
      await _pump(
        tester,
        repo: _Repo(Ok(_settings())),
        token: 'token',
        plainChannels: android({
          'report-general-v2': 4, // a report on the alarm volume — #660
          'eew_alert-important-v2': 5, // a major alert on the notification one
        }),
      );
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));

      await tester.tap(find.text(l10n.notifyVolumeMismatchTitle));
      await tester.pumpAndSettle();

      expect(find.text(l10n.notifyVolumeMismatchCause), findsOneWidget);
      expect(find.text('地震報告(一般)'), findsOneWidget);
      expect(
        find.text(
          l10n.notifyVolumeMismatchChannel(
            l10n.notifyVolumeAlarm,
            l10n.notifyVolumeNotification,
          ),
        ),
        findsOneWidget,
      );
      expect(find.text('緊急地震速報(重大)'), findsOneWidget);
      expect(
        find.text(
          l10n.notifyVolumeMismatchChannel(
            l10n.notifyVolumeNotification,
            l10n.notifyVolumeAlarm,
          ),
        ),
        findsOneWidget,
      );
      // Only the two that differ.
      expect(find.text('地震報告 (無聲通知)'), findsNothing);
      expect(find.text('強震監視器(一般)'), findsNothing);
      // The cost is stated before the button.
      expect(find.text(l10n.notifyVolumeMismatchWarning), findsOneWidget);

      await tester.tap(find.text(l10n.notifyVolumeMismatchOpenAppInfo));
      await tester.pumpAndSettle();

      expect(opened, 1);
    });

    testWidgets('shows without a push token too', (tester) async {
      await _pump(
        tester,
        repo: _Repo(Ok(_settings())),
        plainChannels: android({'eq-v2': 4}),
      );
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));

      expect(find.text(l10n.notifyUnavailable), findsOneWidget);
      expect(find.text(l10n.notifyVolumeMismatchTitle), findsOneWidget);
    });
  });
}
