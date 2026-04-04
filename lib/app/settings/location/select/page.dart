/// Location selection page listing all available cities.
library;

import 'package:dpip/core/i18n.dart';
import 'package:dpip/global.dart';
import 'package:dpip/models/settings/location.dart';
import 'package:dpip/router.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/utils/extensions/string.dart';
import 'package:dpip/widgets/list/segmented_list.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

/// A page that lists all cities for location selection.
///
/// Tap a city to navigate to the district selection page for that city.
/// The currently active location city is highlighted with a subtitle.
class SettingsLocationSelectPage extends StatelessWidget {
  /// Creates a [SettingsLocationSelectPage].
  const SettingsLocationSelectPage({super.key});

  @override
  Widget build(BuildContext context) {
    final entries = Global.location.entries;

    final Set<String> walked = {};
    final locations = entries
        .where((e) => walked.add(e.value.cityWithLevel))
        .map((e) => e.value)
        .toList();

    final length = locations.length;
    print('length = ${locations.length}');
    print(locations);

    final code = context.useLocation.code;

    return CustomScrollView(
      slivers: [
        SliverSegmentedList(
          label: Text('縣市'.i18n),
          children: [
            for (final (index, location) in locations.indexed)
              SegmentedListTile(
                isFirst: index == 0,
                isLast: index == length - 1,
                title: Text(location.cityWithLevel),
                subtitle: code != null && location.cityWithLevel == code.getLocation().cityWithLevel
                    ? Text('目前所在地'.i18n)
                    : null,
                trailing: const Icon(Symbols.chevron_right_rounded),
                onTap: () => SettingsLocationSelectCityRoute(
                  city: location.cityWithLevel,
                ).push(context),
              ),
          ],
        ),
        SliverPadding(padding: .only(bottom: context.padding.bottom + 16)),
      ],
    );
  }
}
