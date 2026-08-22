/// The More menu's catalogue.
///
/// Same reason as the data hub's test: a tile can silently fail to land — an
/// edit that no longer matches, a route constant that was never registered —
/// and nothing else notices. 權限檢查 in particular is the page people reach
/// for when an alert did not arrive, so a menu that quietly stops offering it
/// is a failure that only shows up on the day it matters.
library;

import 'dart:typed_data';

import 'package:dpip/app/theme/app_gold.dart';
import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/geo/location_service.dart';
import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/core/meshtastic/mesh_unread.dart';
import 'package:dpip/core/network/endpoint_health.dart';
import 'package:dpip/core/notifications/notification_service.dart';
import 'package:dpip/core/permissions/permission_health.dart';
import 'package:dpip/core/settings/default_map_layer_controller.dart';
import 'package:dpip/core/settings/eew_cwa_only_settings.dart';
import 'package:dpip/core/settings/experimental_settings.dart';
import 'package:dpip/core/settings/region_store.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:dpip/core/version/app_build.dart';
import 'package:dpip/features/changelog/domain/changelog_repository.dart';
import 'package:dpip/features/changelog/domain/release_note.dart';
import 'package:dpip/features/more/domain/developer_note.dart';
import 'package:dpip/features/more/presentation/pages/more_page.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/navigation/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// A changelog repository whose releases call resolves with no notes: the
/// version card's contributor fetch then settles (to an empty strip) without
/// touching a network.
class _EmptyChangelogRepository implements ChangelogRepository {
  const _EmptyChangelogRepository();

  @override
  Future<Result<List<ReleaseNote>>> releases({int page = 1}) async =>
      const Ok([]);

  @override
  Future<Result<Uint8List>> avatarBytes(String login) async =>
      const Err(UnexpectedFailure('no network'));
}

/// A changelog repository whose releases call always fails — the avatar
/// skeleton must stay put rather than collapse the slot.
class _FailingChangelogRepository implements ChangelogRepository {
  const _FailingChangelogRepository();

  @override
  Future<Result<List<ReleaseNote>>> releases({int page = 1}) async =>
      const Err(UnexpectedFailure('no network'));

  @override
  Future<Result<Uint8List>> avatarBytes(String login) async =>
      const Err(UnexpectedFailure('no network'));
}

/// A changelog repository that answers a fixed page of notes. [ChangelogApi]
/// sorts newest first by publish time, so the first note is the newest.
class _NotesChangelogRepository implements ChangelogRepository {
  _NotesChangelogRepository(this.notes);

  final List<ReleaseNote> notes;

  @override
  Future<Result<List<ReleaseNote>>> releases({int page = 1}) async =>
      Ok(List.of(notes));

  @override
  Future<Result<Uint8List>> avatarBytes(String login) async =>
      const Err(UnexpectedFailure('no network'));
}

/// The in-app destinations the menu must offer, with their English labels.
const _tiles = <(String, String)>[
  (AppRoutes.notifySettings, 'Notification settings'),
  (AppRoutes.permissions, 'Permission check'),
  (AppRoutes.language, 'Language'),
  (AppRoutes.display, 'Display'),
  (AppRoutes.log, 'App logs'),
];

GoRouter _router(List<String> visited) => GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (_, _) => const MorePage(),
      routes: [
        for (final (name, _) in _tiles)
          GoRoute(
            path: name,
            name: name,
            builder: (_, _) {
              visited.add(name);
              return const SizedBox.shrink();
            },
          ),
        // The version card opens the changelog, which leads onward to the
        // highlights page (本次更新) and then to the notes.
        GoRoute(
          path: AppRoutes.changelogPath,
          name: AppRoutes.changelog,
          builder: (_, _) {
            visited.add(AppRoutes.changelog);
            return const SizedBox.shrink();
          },
        ),
        GoRoute(
          path: AppRoutes.releaseHighlightsPath,
          name: AppRoutes.releaseHighlights,
          builder: (_, _) {
            visited.add(AppRoutes.releaseHighlights);
            return const SizedBox.shrink();
          },
        ),
        GoRoute(
          path: AppRoutes.versionNotesPath,
          name: AppRoutes.versionNotes,
          builder: (_, _) {
            visited.add(AppRoutes.versionNotes);
            return const SizedBox.shrink();
          },
        ),
      ],
    ),
  ],
);

Future<void> _pump(
  WidgetTester tester,
  GoRouter router, {
  MeshUnread? unread,
  ChangelogRepository changelog = const _EmptyChangelogRepository(),
}) async {
  // Tall enough that every group lays out and hit-tests inside the viewport —
  // a row past the bottom edge takes taps that silently miss.
  tester.view.physicalSize = const Size(800, 4000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final settings = SettingsStore.inMemory();
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => DefaultMapLayerController(settings),
        ),
        ChangeNotifierProvider(create: (_) => EewCwaOnlySettings(settings)),
        ChangeNotifierProvider(create: (_) => ExperimentalSettings(settings)),
        ChangeNotifierProvider(create: (_) => RegionStore(settings)),
        Provider(create: (_) => const TownDirectory({})),
        ChangeNotifierProvider(create: (_) => unread ?? MeshUnread(null)),
        // The status card wears the same dot as the More tab.
        ChangeNotifierProvider(create: (_) => EndpointHealthMonitor()),
        // MorePage badges its permission row from this. Both services are pure
        // constructors and nothing calls start(), so it holds its optimistic
        // defaults and the row renders unbadged — which is what these tests are
        // asserting about.
        ChangeNotifierProvider(
          create: (_) => PermissionHealth(
            location: LocationService(const TownDirectory({})),
            notifications: NotificationService(settings),
          ),
        ),
        // The version card's contributor strip reads the changelog.
        Provider<ChangelogRepository>(create: (_) => changelog),
      ],
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('offers every in-app destination', (tester) async {
    await _pump(tester, _router([]));
    for (final (route, label) in _tiles) {
      // Scoped to the row: a section header can carry the same word (the
      // Display group is literally headed "Display").
      expect(
        find.widgetWithText(ListTile, label),
        findsOneWidget,
        reason: '$route tile missing',
      );
    }
  });

  testWidgets('the beta and partners groups sit under 取得 App', (tester) async {
    await _pump(tester, _router([]));
    final l10n = AppLocalizations.of(tester.element(find.byType(MorePage)));
    // Both beta channels plus both partners are rows.
    expect(find.widgetWithText(ListTile, l10n.moreAndroidBeta), findsOneWidget);
    expect(find.widgetWithText(ListTile, l10n.moreTestFlight), findsOneWidget);
    expect(
      find.widgetWithText(ListTile, l10n.morePartnerGeoscience),
      findsOneWidget,
    );
    expect(find.widgetWithText(ListTile, l10n.morePartnerTwds), findsOneWidget);
    // And they land below the store rows, in the 取得 App order.
    final play = tester.getTopLeft(
      find.widgetWithText(ListTile, 'Google Play'),
    );
    final beta = tester.getTopLeft(
      find.widgetWithText(ListTile, l10n.moreAndroidBeta),
    );
    final partner = tester.getTopLeft(
      find.widgetWithText(ListTile, l10n.morePartnerGeoscience),
    );
    expect(play.dy, lessThan(beta.dy));
    expect(beta.dy, lessThan(partner.dy));
  });

  testWidgets('permission check sits with the notification settings', (
    tester,
  ) async {
    await _pump(tester, _router([]));
    final notify = tester
        .getTopLeft(find.widgetWithText(ListTile, 'Notification settings'))
        .dy;
    final permissions = tester
        .getTopLeft(find.widgetWithText(ListTile, 'Permission check'))
        .dy;
    expect(permissions - notify, lessThan(120));
  });

  for (final (route, label) in _tiles) {
    testWidgets('the $label tile navigates to $route', (tester) async {
      final visited = <String>[];
      await _pump(tester, _router(visited));
      await tester.tap(find.widgetWithText(ListTile, label));
      // pumpAndSettle would time out: the support card's border breathes
      // forever. A fixed pump covers the navigation transition.
      await tester.pump(const Duration(milliseconds: 600));
      expect(visited, [route]);
    });
  }

  testWidgets(
    'the support callout sits under server status, sharing its width',
    (tester) async {
      await _pump(tester, _router([]));
      final status = tester.getTopLeft(find.text('Server status')).dy;
      final support = tester.getTopLeft(find.text('Support DPIP')).dy;
      // Support now lives in the right column, directly under server status.
      expect(support, greaterThan(status));
      // And the two share the same left edge.
      final statusLeft = tester.getTopLeft(find.text('Server status')).dx;
      final supportLeft = tester.getTopLeft(find.text('Support DPIP')).dx;
      expect(supportLeft, statusLeft);
      // …and all of them sit above every menu group.
      expect(
        tester
            .getTopLeft(find.widgetWithText(ListTile, 'Notification settings'))
            .dy,
        greaterThan(support),
      );
    },
  );

  testWidgets('the developer note sits under Support DPIP', (tester) async {
    await _pump(tester, _router([]));
    // The default test locale is en-US, so the card serves the English note.
    final note = developerNoteFor('en');
    expect(find.text(note.title), findsOneWidget);
    expect(find.text(note.body), findsOneWidget);
    final support = tester.getTopLeft(find.text('Support DPIP')).dy;
    final noteTop = tester.getTopLeft(find.text(note.title)).dy;
    expect(noteTop, greaterThan(support));
  });

  testWidgets('the notification log sits with the notification settings', (
    tester,
  ) async {
    await _pump(tester, _router([]));
    final notify = tester
        .getTopLeft(find.widgetWithText(ListTile, 'Notification settings'))
        .dy;
    final log = tester
        .getTopLeft(find.widgetWithText(ListTile, 'DPIP notification log'))
        .dy;
    expect(log - notify, lessThan(240));
    // Announcements left the links list — the only one left is the card.
    expect(find.widgetWithText(ListTile, 'Announcements'), findsNothing);
  });

  testWidgets('Discord appears once, as the callout', (tester) async {
    // It used to be a row in the links list; leaving it there as well would
    // undo the ranking the callout exists to create.
    await _pump(tester, _router([]));
    expect(find.text('Discord community'), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'Discord community'), findsNothing);
  });

  testWidgets('the support callout outranks Discord visually', (tester) async {
    await _pump(tester, _router([]));
    // The gold belongs to support alone: if Discord were gold too, neither
    // would read as the lead. Both are flat now — the colour is the whole
    // ranking, so assert that the two fills differ.
    final gold = AppGold.of(tester.element(find.text('Support DPIP')));
    final support = tester.widget<DecoratedBox>(
      find
          .ancestor(
            of: find.text('Support DPIP'),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    final discord = tester.widget<Material>(
      find
          .ancestor(
            of: find.text('Discord community'),
            matching: find.byType(Material),
          )
          .first,
    );
    final supportDecoration = support.decoration as BoxDecoration;
    expect(supportDecoration.color, gold.fill);
    expect(discord.color, isNot(gold.fill));
  });

  testWidgets('the hero-card rows in the right column share one left edge', (
    tester,
  ) async {
    await _pump(tester, _router([]));
    // Discord, the announcement, server status and support stack in the right
    // column; their icon circles and labels must start at the same left edge
    // for the stack to read as aligned rows (vertical position differs by
    // design).
    final iconXs = [
      tester.getCenter(find.byIcon(Icons.discord)).dx,
      tester.getCenter(find.byIcon(Icons.campaign_outlined)).dx,
      tester.getCenter(find.byIcon(Icons.dns_outlined)).dx,
      tester.getCenter(find.byIcon(Icons.favorite)).dx,
    ];
    expect(iconXs.toSet(), hasLength(1));

    final textXs = [
      tester.getTopLeft(find.text('Discord community')).dx,
      tester.getTopLeft(find.text('Announcements')).dx,
      tester.getTopLeft(find.text('Server status')).dx,
      tester.getTopLeft(find.text('Support DPIP')).dx,
    ];
    expect(textXs.toSet(), hasLength(1));
  });

  testWidgets('the Meshtastic row carries a dot only while unread exists', (
    tester,
  ) async {
    final unread = MeshUnread(null);
    await _pump(tester, _router([]), unread: unread);
    // The row's icon is badged only when a conversation holds something the
    // user has not seen — the same state the chat page's pills read.
    Finder meshBadge() => find.descendant(
      of: find.widgetWithText(ListTile, 'Meshtastic'),
      matching: find.byType(Badge),
    );
    expect(meshBadge(), findsNothing);

    unread.recordIncoming(2, DateTime.utc(2026, 1, 1).millisecondsSinceEpoch);
    await tester.pump();
    expect(meshBadge(), findsOneWidget);

    unread.markVisible(2); // read it
    await tester.pump();
    expect(meshBadge(), findsNothing);
  });

  testWidgets('the version card names this build and its train', (
    tester,
  ) async {
    await _pump(tester, _router([]));
    // The card leads with the train number (26.1 for both release and
    // snapshot). Fine print under it: a snapshot prints its own label
    // (26w34a), a release prints the platform's recorded version.
    final label = AppBuild.label;
    final stable = RegExp(r'^\d+\.\d+$').hasMatch(label);
    expect(find.text(AppBuild.train), findsWidgets);
    if (stable) {
      // The platform version is what Settings → app shows for a release; in
      // these tests it is unset so the card falls back to the train, which is
      // the same string the lead number printed — so it may appear twice.
      expect(find.text(AppBuild.train), findsNWidgets(2));
    } else {
      expect(find.text(label), findsOneWidget);
    }
    expect(
      find.descendant(of: find.byType(InkWell), matching: find.text('DPIP')),
      findsWidgets,
    );
    expect(find.text('Snapshot'), findsOneWidget);
    // The badge carries the day the build was cut — what the card's own
    // stamp says, so a tester can tell which snapshot they are running.
    if (AppBuild.buildDate.isNotEmpty) {
      expect(find.text(AppBuild.buildDate), findsOneWidget);
    }
  });

  testWidgets('the version card opens this update\'s notes', (tester) async {
    final visited = <String>[];
    await _pump(tester, _router(visited));
    // The card is the DPIP row with the chevron — tap its label.
    await tester.tap(find.text('DPIP').first);
    // pumpAndSettle would time out: the support card's border breathes
    // forever. A fixed pump covers the navigation transition.
    await tester.pump(const Duration(milliseconds: 600));
    expect(visited, [AppRoutes.versionNotes]);
  });

  testWidgets(
    'the version card falls back to the newest note\x27s contributors',
    (tester) async {
      // A build no published release names — a local/dev label newer than
      // anything GitHub holds — must still show the newest note's avatars
      // rather than an empty strip.
      AppBuild.debugSet(label: '26w99x', code: 999999);
      addTearDown(() => AppBuild.debugSet(label: 'dev', code: 0));

      final notes = [
        ReleaseNote(
          tagName: '26w34j',
          name: '26w34j',
          prerelease: true,
          publishedAt: DateTime.utc(2026, 8, 22),
          body: '- something — @whes1015\n- other — @ExptechTW',
        ),
        ReleaseNote(
          tagName: '26w34i',
          name: '26w34i',
          prerelease: true,
          publishedAt: DateTime.utc(2026, 8, 21),
          body: '- older — @someone',
        ),
      ];
      await _pump(
        tester,
        _router([]),
        changelog: _NotesChangelogRepository(notes),
      );
      // Avatar bytes fail in this harness, so each circle falls back to the
      // login's initial — the strip still renders per contributor.
      expect(find.text('W'), findsOneWidget);
      expect(find.text('E'), findsOneWidget);
      // The older note's sole contributor must not leak in.
      expect(find.text('S'), findsNothing);
    },
  );

  testWidgets('a failed fetch keeps the avatar skeleton in place', (
    tester,
  ) async {
    await _pump(
      tester,
      _router([]),
      changelog: const _FailingChangelogRepository(),
    );
    // The fetch failed, but the slot must not collapse — the three dim
    // circles of the skeleton (26×26, the 30px avatar minus its 4px border)
    // stay where the avatars would land, so the badge row below never jumps
    // and the card does not look broken.
    final skeleton = find.byWidgetPredicate(
      (w) =>
          w is Container &&
          w.constraints?.maxWidth == 26 &&
          w.constraints?.maxHeight == 26 &&
          (w.decoration as BoxDecoration?)?.shape == BoxShape.circle,
    );
    expect(skeleton, findsNWidgets(3));
  });
}
