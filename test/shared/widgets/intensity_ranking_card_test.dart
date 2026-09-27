/// The monitor's 震度排行 card, as the live map and the replay page draw it.
///
/// Two things are easy to break unseen: an empty ranking must draw nothing at
/// all (not a titled, empty card parked over the map for every calm minute),
/// and each row's badge must carry the intensity's own label and palette
/// colour — the badge is what is read first, before the place name.
library;

import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/seismic/intensity_colors.dart';
import 'package:dpip/shared/widgets/intensity_badge.dart';
import 'package:dpip/shared/widgets/intensity_ranking_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(List<IntensityRankingEntry> entries) => MaterialApp(
  locale: const Locale('zh', 'TW'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: IntensityRankingCard(entries: entries)),
);

void main() {
  testWidgets('an empty ranking draws nothing', (tester) async {
    await tester.pumpWidget(_host(const []));

    expect(find.byType(IntensityBadge), findsNothing);
    expect(find.text('各地震度排行'), findsNothing);
  });

  testWidgets('each row shows its place under the title, badge first', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(const [(name: '花蓮縣秀林鄉', level: 6), (name: '宜蘭縣南澳鄉', level: 3)]),
    );

    expect(find.text('各地震度排行'), findsOneWidget);
    expect(find.text('花蓮縣秀林鄉'), findsOneWidget);
    final badges = tester
        .widgetList<IntensityBadge>(find.byType(IntensityBadge))
        .toList();
    expect(badges.map((b) => b.label), ['5⁺', '3']);
    expect(badges.first.color, IntensityColors.discrete(6));
    expect(
      tester.getTopLeft(find.text('花蓮縣秀林鄉')).dy,
      lessThan(tester.getTopLeft(find.text('宜蘭縣南澳鄉')).dy),
    );
  });
}
