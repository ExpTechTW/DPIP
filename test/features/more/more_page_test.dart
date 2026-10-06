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
import 'package:dpip/core/geo/town.dart';
import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/core/meshtastic/mesh_unread.dart';
import 'package:dpip/core/network/endpoint_health.dart';
import 'package:dpip/core/notifications/notification_service.dart';
import 'package:dpip/core/permissions/permission_health.dart';
import 'package:dpip/core/settings/default_map_layer_controller.dart';
import 'package:dpip/core/settings/eew_cwa_only_settings.dart';
import 'package:dpip/core/settings/eew_spoken_announcement_settings.dart';
import 'package:dpip/core/settings/experimental_settings.dart';
import 'package:dpip/core/settings/region_store.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:dpip/core/version/app_build.dart';
import 'package:dpip/features/bug_tracker/bug_tracker_counter.dart';
import 'package:dpip/features/bug_tracker/domain/bug_repository.dart';
import 'package:dpip/features/bug_tracker/domain/bug_thread.dart';
import 'package:dpip/features/bug_tracker/data/bug_repository_impl.dart';
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
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

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
  (AppRoutes.spokenIntensity, 'Speak estimated intensity'),
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
        GoRoute(
          path: AppRoutes.regionSelectPath,
          name: AppRoutes.regionSelect,
          builder: (_, state) {
            final query = state.uri.queryParameters.entries
                .map((entry) => '${entry.key}=${entry.value}')
                .join('&');
            visited.add('region:$query');
            return const SizedBox.shrink();
          },
        ),
        for (final (name, path) in _namedRoutes)
          GoRoute(
            path: path,
            name: name,
            builder: (_, _) {
              visited.add(name);
              return const SizedBox.shrink();
            },
          ),
      ],
    ),
  ],
);

const _namedRoutes = <(String, String)>[
  (AppRoutes.defaultMapLayer, AppRoutes.defaultMapLayerPath),
  (AppRoutes.eewSource, AppRoutes.eewSourcePath),
  (AppRoutes.meshtastic, AppRoutes.meshtasticPath),
  (AppRoutes.experimental, AppRoutes.experimentalPath),
  (AppRoutes.bugTracker, AppRoutes.bugTrackerPath),
  (AppRoutes.developer, AppRoutes.developerPath),
  (AppRoutes.sponsor, AppRoutes.sponsorPath),
  (AppRoutes.serverStatus, AppRoutes.serverStatusPath),
];

Future<void> _pump(
  WidgetTester tester,
  GoRouter router, {
  MeshUnread? unread,
  ChangelogRepository changelog = const _EmptyChangelogRepository(),
  TownDirectory towns = const TownDirectory({}),
  Size size = const Size(800, 4000),
}) async {
  // Tall enough that every group lays out and hit-tests inside the viewport —
  // a row past the bottom edge takes taps that silently miss.
  tester.view.physicalSize = size;
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
        ChangeNotifierProvider(
          create: (_) => EewSpokenAnnouncementSettings(settings),
        ),
        ChangeNotifierProvider(create: (_) => ExperimentalSettings(settings)),
        ChangeNotifierProvider(create: (_) => RegionStore(settings)),
        Provider<TownDirectory>(create: (_) => towns),
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
        // The bug-tracker tile watches this counter for its badge; an empty
        // index keeps the tile unbadged, which is what these tests assume.
        ChangeNotifierProvider<BugTrackerCounter>(
          create: (_) => BugTrackerCounter(const _EmptyBugRepository()),
        ),
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

/// A bug repository answering an empty index — the More tile only reads the
/// counter, which never fires without an explicit load.
class _EmptyBugRepository implements BugRepository {
  const _EmptyBugRepository();

  @override
  Future<Result<List<BugThread>>> threads() async => const Ok([]);

  @override
  Future<Result<BugThreadDetail>> thread(int id) async {
    final parsed = parseBugThreads(_emptyIndex());
    return Ok(BugThreadDetail(thread: parsed.first, messages: const []));
  }

  @override
  Future<Result<Uint8List>> avatar(String url) async =>
      Ok(Uint8List.fromList(<int>[]));
}

Map<String, Object> _emptyIndex() => {
  'users': <String, Object>{},
  'threads': <Map<String, Object>>[
    {
      'threads_id': 0,
      'title': '',
      'tags': <String>['DPIP'],
      'body': '',
      'author': 0,
      'created_at': 1787511150,
      'message_count': 0,
      'locked': false,
      'last_message_id': 0,
    },
  ],
};

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

  testWidgets('lists formal data sources quietly under About', (tester) async {
    await _pump(tester, _router([]));
    await tester.fling(find.byType(ListView), const Offset(0, -5000), 5000);
    // Enough for the fling's ballistic scroll to carry the list to the end.
    await tester.pump(const Duration(milliseconds: 600));
    const sources = [
      '探索智慧科技有限公司 — TREM-Net',
      '交通部中央氣象署 (CWA)',
      '気象庁 (JMA)',
      '國家災害防救科技中心 (NCDR)',
      'European Centre for Medium-Range Weather Forecasts (ECMWF)',
      'National Oceanic and Atmospheric Administration / National Centers '
          'for Environmental Prediction — Global Forecast System '
          '(NOAA/NCEP GFS)',
      '政府資料開放平臺',
      '© OpenStreetMap contributors',
      'National Aeronautics and Space Administration / Goddard Space Flight '
          'Center Scientific Visualization Studio — CGI Moon Kit '
          '(NASA/GSFC SVS)',
    ];

    expect(find.text('Data sources'), findsOneWidget);
    for (final source in sources) {
      expect(find.text(source), findsOneWidget, reason: '$source missing');
    }
    expect(
      tester.getTopLeft(find.text(sources.first)).dy,
      lessThan(tester.getTopLeft(find.text(sources[1])).dy),
    );
    expect(
      tester.widget<Text>(find.text(sources.first)).style?.fontSize,
      Theme.of(tester.element(find.text(sources.first)))
          .textTheme
          .labelSmall
          ?.fontSize,
    );
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
    expect(
      find.widgetWithText(ListTile, l10n.morePartnerThinktron),
      findsOneWidget,
    );
    expect(
      find.widgetWithText(ListTile, l10n.morePartnerJimsun),
      findsOneWidget,
    );
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

  testWidgets('the accessibility row shows its state and opens its page', (
    tester,
  ) async {
    final visited = <String>[];
    await _pump(tester, _router(visited));
    const label = 'Speak estimated intensity';

    // The row reads as a destination like every other row in this menu — the
    // choice and the trade it makes live on the page, not in the menu.
    final tile = tester.widget<ListTile>(find.widgetWithText(ListTile, label));
    expect(tile.trailing, isA<Icon>());
    expect(find.byType(Switch), findsNothing);

    // Off by default, and the row says so without opening anything.
    expect(
      find.descendant(
        of: find.widgetWithText(ListTile, label),
        matching: find.text('Off'),
      ),
      findsOneWidget,
    );

    // Under 無障礙, not 通知 — a row that drifts back into another section is
    // exactly the kind of edit nothing else would notice.
    final accessibility = tester.getTopLeft(find.text('Accessibility')).dy;
    final row = tester.getTopLeft(find.widgetWithText(ListTile, label)).dy;
    final nextSection = tester.getTopLeft(find.text('Mesh network')).dy;
    expect(row, greaterThan(accessibility));
    expect(row, lessThan(nextSection));

    await tester.tap(find.widgetWithText(ListTile, label));
    await tester.pump(const Duration(milliseconds: 600));
    expect(visited, [AppRoutes.spokenIntensity]);
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
      await tester.pumpAndSettle();
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
    expect(find.text(stable ? 'Release' : 'Snapshot'), findsOneWidget);
    // The badge carries the day the build was cut — what the card's own
    // stamp says, so a tester can tell which build they are running.
    if (AppBuild.buildDate.isNotEmpty) {
      expect(find.text(AppBuild.buildDate), findsOneWidget);
    }
  });

  testWidgets('the version card opens this update\'s notes', (tester) async {
    final visited = <String>[];
    await _pump(tester, _router(visited));
    // The card is the DPIP row with the chevron — tap its label.
    await tester.tap(find.text('DPIP').first);
    await tester.pumpAndSettle();
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

  testWidgets('saved regions expand, edit, delete, and fill the cap', (
    tester,
  ) async {
    final visited = <String>[];
    final router = _router(visited);
    const zhongzheng = Town(
      code: '6300500',
      city: '臺北',
      town: '中正',
      lat: 25.03,
      lng: 121.51,
      cityLevel: '市',
      townLevel: '區',
    );
    await _pump(
      tester,
      router,
      towns: const TownDirectory({'6300500': zhongzheng}),
    );
    await tester.tap(find.widgetWithText(ListTile, 'Saved regions'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('No saved regions yet'), findsOneWidget);
    tester
        .widget<TextButton>(find.widgetWithText(TextButton, 'Add a region'))
        .onPressed!();
    await tester.pumpAndSettle();
    expect(visited, ['region:returnToMore=1']);
    router.pop();
    await tester.pumpAndSettle();

    final store = tester.element(find.byType(MorePage)).read<RegionStore>();
    store.addSaved('6300500');
    store.addSaved('unknown');
    await tester.pump();
    await tester.tap(find.widgetWithText(ListTile, 'Saved regions'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('中正區'), findsOneWidget);
    expect(find.text('unknown'), findsOneWidget);

    tester.widget<ListTile>(find.widgetWithText(ListTile, '中正區')).onTap!();
    await tester.pumpAndSettle();
    expect(find.text('臺北市 中正區'), findsOneWidget);
    await tester.tap(find.widgetWithText(ListTile, 'Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('臺北市 中正區'), findsNothing);

    tester.widget<ListTile>(find.widgetWithText(ListTile, 'unknown')).onTap!();
    await tester.pumpAndSettle();
    expect(find.text('unknown'), findsWidgets);
    await tester.tap(find.widgetWithText(ListTile, 'Edit'));
    await tester.pumpAndSettle();
    expect(visited.last, 'region:replace=unknown&returnToMore=1');
    router.pop();
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ListTile, 'Saved regions'));
    await tester.pump(const Duration(milliseconds: 200));
    tester.widget<ListTile>(find.widgetWithText(ListTile, '中正區')).onTap!();
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Delete'));
    await tester.pumpAndSettle();
    expect(find.text('中正區'), findsNothing);

    store.addSaved('6300500');
    store.addSaved('second');
    await tester.pump();
    await tester.tap(find.widgetWithText(ListTile, 'Saved regions'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('3/3 selected'), findsOneWidget);
    expect(find.text('Add a region'), findsNothing);
  });

  testWidgets('display and mesh rows follow their settings into their pages', (
    tester,
  ) async {
    final visited = <String>[];
    await _pump(tester, _router(visited));
    final page = tester.element(find.byType(MorePage));
    await page.read<EewCwaOnlySettings>().setEnabled(false);
    await page.read<EewSpokenAnnouncementSettings>().setEnabled(true);
    await page.read<ExperimentalSettings>().unlock();
    await tester.pump();

    expect(find.text('All sources'), findsOneWidget);
    expect(find.text('On'), findsWidgets);

    Future<void> leave() async {
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      navigator.pop();
      await tester.pumpAndSettle();
    }

    for (final (label, route) in <(String, String)>[
      ('Default map layer', AppRoutes.defaultMapLayer),
      ('EEW source', AppRoutes.eewSource),
      ('Meshtastic', AppRoutes.meshtastic),
      ('Experimental features', AppRoutes.experimental),
      ('Changelog', AppRoutes.changelog),
      ('Bug reports', AppRoutes.bugTracker),
      ('Debug info', AppRoutes.developer),
    ]) {
      visited.clear();
      await tester.ensureVisible(find.widgetWithText(ListTile, label));
      await tester.tap(find.widgetWithText(ListTile, label));
      await tester.pumpAndSettle();
      expect(visited, [route], reason: label);
      await leave();
    }

    visited.clear();
    await tester.tap(find.text('Server status'));
    await tester.pumpAndSettle();
    expect(visited, [AppRoutes.serverStatus]);
  });

  testWidgets('external rows open, and a refused launch says so', (
    tester,
  ) async {
    final launcher = _RecordingLauncher();
    final previous = UrlLauncherPlatform.instance;
    UrlLauncherPlatform.instance = launcher;
    addTearDown(() => UrlLauncherPlatform.instance = previous);

    final visited = <String>[];
    await _pump(tester, _router(visited));

    await tester.tap(find.text('Discord community'));
    await tester.pump();
    expect(launcher.launched, ['https://exptech.com.tw/dc']);

    await tester.tap(find.text('Announcements'));
    await tester.pump();
    expect(launcher.launched, contains('https://announcement.exptech.com.tw/'));

    await tester.ensureVisible(find.text('Terms of Service'));
    await tester.tap(find.text('Terms of Service'));
    await tester.pump();
    expect(launcher.launched, contains('https://exptech.com.tw/tos'));

    launcher.fail = true;
    await tester.ensureVisible(find.text('Discord community'));
    await tester.tap(find.text('Discord community'));
    await tester.pump();
    expect(find.text("Couldn't open the link"), findsOneWidget);

    launcher.fail = false;
    visited.clear();
    await tester.tap(find.text('Support DPIP'));
    await tester.pumpAndSettle();
    expect(visited, [AppRoutes.sponsor]);
  });

  testWidgets('the license row opens Flutter\'s license page', (tester) async {
    await _pump(tester, _router([]));
    await tester.ensureVisible(
      find.widgetWithText(ListTile, 'Open-source licenses'),
    );
    await tester.tap(find.widgetWithText(ListTile, 'Open-source licenses'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(LicensePage), findsOneWidget);
  });

  testWidgets('cancelling the diagnostics dump clears its spinner', (
    tester,
  ) async {
    await _pump(tester, _router([]));
    await tester.ensureVisible(
      find.widgetWithText(ListTile, 'Dump debug info and logs'),
    );
    await tester.tap(find.widgetWithText(ListTile, 'Dump debug info and logs'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsWidgets);
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('a narrow version card folds extra avatars and opens a profile', (
    tester,
  ) async {
    final launcher = _RecordingLauncher();
    final previous = UrlLauncherPlatform.instance;
    UrlLauncherPlatform.instance = launcher;
    addTearDown(() => UrlLauncherPlatform.instance = previous);

    AppBuild.debugSet(
      label: '26.1',
      code: 426000100,
      platformVersion: '26.1.0',
    );
    addTearDown(() => AppBuild.debugSet(label: 'dev', code: 0));

    final logins = List.generate(20, (i) => String.fromCharCode(97 + i));
    final notes = [
      ReleaseNote(
        tagName: '26.1',
        name: '26.1',
        prerelease: false,
        publishedAt: DateTime.utc(2026, 9, 1),
        body: logins.map((login) => '- note — @$login').join('\n'),
      ),
    ];
    await _pump(
      tester,
      _router([]),
      changelog: _NotesChangelogRepository(notes),
    );
    await tester.pump();
    expect(find.text('26.1.0'), findsOneWidget);
    expect(find.textContaining(RegExp(r'^\+\d+$')), findsOneWidget);
    tester
        .widget<GestureDetector>(
          find
              .ancestor(
                of: find.text('A'),
                matching: find.byType(GestureDetector),
              )
              .first,
        )
        .onTap!();
    await tester.pump();
    expect(launcher.launched, ['https://github.com/a']);
  });

  testWidgets('a launcher that declines still tells the user', (tester) async {
    final launcher = _RecordingLauncher()..refuse = true;
    final previous = UrlLauncherPlatform.instance;
    UrlLauncherPlatform.instance = launcher;
    addTearDown(() => UrlLauncherPlatform.instance = previous);

    await _pump(tester, _router([]));
    await tester.tap(find.text('Discord community'));
    await tester.pump();
    expect(find.text("Couldn't open the link"), findsOneWidget);
  });
}

class _RecordingLauncher extends UrlLauncherPlatform {
  final launched = <String>[];
  bool fail = false;
  bool refuse = false;

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> canLaunch(String url) async => !fail;

  @override
  Future<bool> launch(
    String url, {
    required bool useSafariVC,
    required bool useWebView,
    required bool enableJavaScript,
    required bool enableDomStorage,
    required bool universalLinksOnly,
    required Map<String, String> headers,
    String? webOnlyWindowName,
  }) async {
    if (fail) throw StateError('no browser');
    if (refuse) return false;
    launched.add(url);
    return true;
  }
}
