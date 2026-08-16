/// The update dialog: that it appears, that it appears *once*, and that its
/// buttons lead where they say.
///
/// The once-per-version rule is the part worth pinning — it is enforced by a
/// persisted key written before the dialog is shown, which is easy to break
/// into a nag that returns on every launch.
library;

import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/platform/install_source.dart';
import 'package:dpip/core/settings/setting_keys.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:dpip/features/changelog/domain/changelog_repository.dart';
import 'package:dpip/features/changelog/domain/release_note.dart';
import 'package:dpip/features/changelog/presentation/widgets/update_prompt.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/navigation/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

class _FakeRepository implements ChangelogRepository {
  _FakeRepository(this.notes);

  final List<ReleaseNote> notes;

  @override
  Future<Result<List<ReleaseNote>>> releases({int page = 1}) async => Ok(notes);
}

ReleaseNote _note(String tag, {required bool pre}) => ReleaseNote(
  tagName: tag,
  name: tag,
  prerelease: pre,
  publishedAt: DateTime.utc(2026, 1, 1),
  htmlUrl: 'https://github.com/ExpTechTW/DPIP/releases/tag/$tag',
);

final _releases = [
  _note('v3.2.1', pre: false),
  _note('v3.2.0', pre: false),
  _note('v3.9.9', pre: true),
];

Future<SettingsStore> _pump(
  WidgetTester tester, {
  required String version,
  InstallSource source = InstallSource.appStore,
  SettingsStore? settings,
  ChangelogRepository? repository,
  List<String>? visited,
}) async {
  PackageInfo.setMockInitialValues(
    appName: 'DPIP',
    packageName: 'com.exptech.dpip',
    version: version,
    buildNumber: '1',
    buildSignature: '',
  );
  InstallSourceService.debugSet(source);
  addTearDown(() => InstallSourceService.debugSet(null));

  final store = settings ?? SettingsStore.inMemory();
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<SettingsStore>.value(value: store),
        Provider<ChangelogRepository>.value(
          value: repository ?? _FakeRepository(_releases),
        ),
      ],
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (_, _) =>
                  const Scaffold(body: Center(child: UpdatePrompt())),
              routes: [
                GoRoute(
                  path: 'changelog',
                  name: AppRoutes.changelog,
                  builder: (_, _) {
                    visited?.add(AppRoutes.changelog);
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return store;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('names the new version and offers all three ways out', (
    tester,
  ) async {
    await _pump(tester, version: '3.2.0');

    expect(find.text('Update available'), findsOneWidget);
    expect(find.text('Version v3.2.1 is out.'), findsOneWidget);
    expect(find.text('Skip this one'), findsOneWidget);
    expect(find.text('View changes'), findsOneWidget);
    // The update button names its destination, which follows the installer.
    expect(find.text('App Store'), findsOneWidget);
  });

  testWidgets('a TestFlight build is sent to TestFlight', (tester) async {
    await _pump(
      tester,
      version: '3.9.9',
      source: InstallSource.testFlight,
      repository: _FakeRepository([_note('v3.9.91', pre: true), ..._releases]),
    );

    expect(find.text('Version v3.9.91 is out.'), findsOneWidget);
    expect(find.text('TestFlight'), findsOneWidget);
    expect(find.text('App Store'), findsNothing);
  });

  testWidgets('says nothing when the build is already current', (tester) async {
    await _pump(tester, version: '3.2.1');
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('offers a version once, however the dialog ended', (
    tester,
  ) async {
    final store = await _pump(tester, version: '3.2.0');
    expect(
      store.getString(SettingKeys.updatePromptedVersion),
      'v3.2.1',
      reason: 'recorded when shown, not when acted on',
    );
    await tester.tap(find.text('Skip this one'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);

    // A fresh launch with the same state must stay silent.
    await _pump(tester, version: '3.2.0', settings: store);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('"View changes" opens the changelog', (tester) async {
    final visited = <String>[];
    await _pump(tester, version: '3.2.0', visited: visited);
    await tester.tap(find.text('View changes'));
    await tester.pumpAndSettle();
    expect(visited, [AppRoutes.changelog]);
  });

  testWidgets('a failed check is silent, not an error', (tester) async {
    await _pump(tester, version: '3.2.0', repository: _FailingRepository());
    expect(find.byType(AlertDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

class _FailingRepository implements ChangelogRepository {
  @override
  Future<Result<List<ReleaseNote>>> releases({int page = 1}) async =>
      const Err(NetworkFailure('offline'));
}
