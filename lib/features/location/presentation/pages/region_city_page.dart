/// The second level of the region picker: the townships within one city, each
/// toggleable as a saved Home region (up to [RegionStore.maxSaved]).
library;

import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/geo/place_search.dart';
import 'package:dpip/core/geo/town.dart';
import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/core/settings/region_store.dart';
import 'package:dpip/features/location/presentation/widgets/region_town_tile.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/widgets/empty_view.dart';
import 'package:dpip/shared/widgets/section_header.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// Lists the townships of [city], filterable from a search field on top.
/// Tapping a row toggles it as a saved region: a saved row shows a filled star
/// and removes on tap; an unsaved row adds (when under the cap) or, once full,
/// leaves the selection unchanged and explains the limit. The selection is
/// stored by **code** in the [RegionStore]; names and coordinates shown here
/// are derived from the directory.
class RegionCityPage extends StatefulWidget {
  const RegionCityPage({
    super.key,
    required this.city,
    this.replaceCode,
    this.returnToMore,
  });

  /// The city display name (`縣市`) whose townships this page lists.
  final String city;

  /// 選擇一個區域會替換掉之前的
  final String? replaceCode;

  /// 是否成功選擇後返回頁面
  final bool? returnToMore;

  @override
  State<RegionCityPage> createState() => _RegionCityPageState();
}

class _RegionCityPageState extends State<RegionCityPage> {
  final _searchController = TextEditingController();

  /// The townships of [RegionCityPage.city], each with its name folded for
  /// the filter ([foldPlaceName]). The directory is one immutable instance for
  /// the app's life, so scan and fold once per city instead of once per build:
  /// [build] re-runs on every keystroke and the scan walks all 368 towns,
  /// building a `cityName` string for each.
  late List<(Town, String)> _towns = _scan(widget.city);

  List<(Town, String)> _scan(String city) => [
    for (final town in context.read<TownDirectory>().townsInCity(city))
      (town, foldPlaceName(town.townName)),
  ];

  @override
  void didUpdateWidget(covariant RegionCityPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // go_router keys a page by its route *pattern* (`:city`), not by the
    // resolved city, so a `go()` or a deep link to another city reuses this
    // State with a different `widget.city`. The push path used today mints a
    // fresh one, which is what makes the scan above an optimisation and this
    // re-scan the thing that keeps it correct.
    if (oldWidget.city != widget.city) {
      _towns = _scan(widget.city);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = context.watch<RegionStore>();
    // Read `savedCodes` once (the getter allocates a fresh list each call).
    final savedCodes = store.savedCodes;
    final query = GoRouterState.of(context).uri.queryParameters;
    final effectiveReplaceCode = widget.replaceCode ?? query['replace'];
    final effectiveReturnToMore =
        widget.returnToMore == true || query['returnToMore'] == '1';

    // Folded like the names, so `台東` finds 臺東市 and a stray space or a
    // full-width character from a CJK keyboard does not empty the list.
    final needle = foldPlaceName(_searchController.text);
    final shown = [
      for (final (town, name) in _towns)
        if (needle.isEmpty || name.contains(needle)) town,
    ];

    return Scaffold(
      appBar: AppBar(title: Text(widget.city)),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: l10n.regionSearchTownHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: needle.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        tooltip: l10n.commonClose,
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      ),
                isDense: true,
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          SectionHeader(
            l10n.regionSelectCount(savedCodes.length, RegionStore.maxSaved),
          ),
          if (shown.isEmpty)
            EmptyView(
              icon: Icons.search_off,
              message: l10n.regionSearchTownEmpty,
            )
          else
            for (final town in shown)
              RegionTownTile(
                town: town,
                store: store,
                savedCodes: savedCodes,
                replaceCode: effectiveReplaceCode,
                returnToMore: effectiveReturnToMore,
              ),
        ],
      ),
    );
  }
}
