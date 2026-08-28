/// The update dialog: that it appears, that it appears *once*, and that its
/// buttons lead where they say.
///
/// The once-per-version rule is the part worth pinning — it is enforced by a
/// persisted key written before the dialog is shown, which is easy to break
/// into a nag that returns on every launch.
library;

import 'dart:typed_data';

import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/platform/install_source.dart';
import 'package:dpip/core/settings/setting_keys.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:dpip/features/changelog/domain/changelog_repository.dart';
import 'package:dpip/core/version/app_build.dart';
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

  @override
  Future<Result<Uint8List>> avatarBytes(String login) async =>
      const Err(UnexpectedFailure('no network'));
}

/// A release advertises its ordinal in the note body, invisibly — see
/// `buildCodeOf`. Every build carries one now (CI stamps it, and the git hooks
/// write it for a debug build), so a release without one is never offered.
ReleaseNote _note(String tag, {required bool pre, int? build}) => ReleaseNote(
  tagName: tag,
  name: tag,
  body: build == null ? '' : '<!-- dpip-build: $build -->',
  prerelease: pre,
  publishedAt: DateTime.utc(2026, 1, 1),
  htmlUrl: 'https://github.com/ExpTechTW/DPIP/releases/tag/$tag',
);

/// What the running build claims to be, for the ordinal comparison.
const int _currentBuild = 1000;

final _releases = [
  _note('v3.2.1', pre: false, build: 1010),
  _note('v3.2.0', pre: false, build: 900),
  _note('v3.9.9', pre: true, build: 1005),
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

  // Pin what the running build claims to be. Without this it is whatever the
  // git hooks wrote into build_info.g.dart for the checkout the suite happens
  // to run on — which is above every ordinal below, so nothing would ever be
  // offered and the failure would look like a broken prompt.
  setUp(() => AppBuild.debugSet(label: '3.2.0', code: _currentBuild));

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

  testWidgets('keeps phone-width actions in two intentional rows', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(371, 667);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pump(tester, version: '3.2.0');

    final skip = tester.getRect(find.text('Skip this one'));
    final changes = tester.getRect(find.text('View changes'));
    final store = tester.getRect(
      find.widgetWithText(FilledButton, 'App Store'),
    );
    expect(skip.center.dy, changes.center.dy);
    expect(store.top, greaterThan(skip.bottom));
    expect(store.width, greaterThan(skip.width + changes.width));
  });

  testWidgets('a TestFlight build is sent to TestFlight', (tester) async {
    await _pump(
      tester,
      version: '3.9.9',
      source: InstallSource.testFlight,
      repository: _FakeRepository([
        _note('v3.9.91', pre: true, build: 1020),
        ..._releases,
      ]),
    );

    expect(find.text('Version v3.9.91 is out.'), findsOneWidget);
    expect(find.text('TestFlight'), findsOneWidget);
    expect(find.text('App Store'), findsNothing);
  });

  testWidgets('says nothing when the build is already current', (tester) async {
    // Current by *ordinal*, which is what decides now — the version string
    // cannot, because a snapshot named for a later week legitimately precedes
    // the release it led to.
    AppBuild.debugSet(label: '3.2.1', code: 1010);
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

  @override
  Future<Result<Uint8List>> avatarBytes(String login) async =>
      const Err(NetworkFailure('offline'));
}
