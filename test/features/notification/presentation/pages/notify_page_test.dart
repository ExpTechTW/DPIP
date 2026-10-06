/// The notify page is the only place a channel filter is changed. A load
/// error that looks like "nothing to set", or a failed save that still moves
/// the check, would leave the phone subscribed to the wrong alerts.
library;

import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/notifications/notification_service.dart';
import 'package:dpip/core/settings/setting_keys.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:dpip/features/notification/domain/notify_repository.dart';
import 'package:dpip/features/notification/domain/notify_settings.dart';
import 'package:dpip/features/notification/presentation/notify_labels.dart';
import 'package:dpip/features/notification/presentation/pages/notify_page.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/navigation/app_routes.dart';
import 'package:flutter/material.dart';
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
        Provider(create: (_) => NotificationService(store)),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
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
