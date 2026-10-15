/// The first level of the region picker: a search field over the counties,
/// cities and townships, then the full city list to drill into.
library;

import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/geo/place_search.dart';
import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/core/settings/region_store.dart';
import 'package:dpip/features/location/presentation/widgets/region_town_tile.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/navigation/app_routes.dart';
import 'package:dpip/shared/widgets/empty_view.dart';
import 'package:dpip/shared/widgets/section_header.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// The city level of the region picker, with a search on top.
///
/// The query narrows the city list in place — it never leaves this page: a
/// matching city keeps its star marker and drill-down, a non-matching one
/// disappears. Townships the query names are listed under the cities and pick
/// straight from here, so `板橋` does not first need the user to know it is in
/// 新北市. Both sides are compared folded ([foldPlaceName]), so the everyday
/// `台北` finds the directory's `臺北市`. No match at all shows an empty view.
class RegionSelectPage extends StatefulWidget {
  const RegionSelectPage({super.key, this.replaceCode, this.returnToMore});

  /// 選擇一個區域會替換掉之前的
  final String? replaceCode;

  /// 是否成功選擇後返回頁面
  final bool? returnToMore;

  @override
  State<RegionSelectPage> createState() => _RegionSelectPageState();
}

class _RegionSelectPageState extends State<RegionSelectPage> {
  final _searchController = TextEditingController();

  /// The city and township names, folded once for the page's lifetime.
  ///
  /// [TownDirectory.cities] is a getter that walks every township to collapse
  /// them into the ~20 city names, and [build] runs on every character typed
  /// into the search field. The directory is built once at bootstrap and never
  /// mutated, so neither the names nor their folded forms can differ between
  /// keystrokes — each search scans this index instead of rebuilding it.
  late final PlaceSearchIndex _index = PlaceSearchIndex(
    context.read<TownDirectory>(),
  );

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final directory = context.read<TownDirectory>();
    final store = context.watch<RegionStore>();
    final query = GoRouterState.of(context).uri.queryParameters;
    final effectiveReplaceCode = widget.replaceCode ?? query['replace'];
    final effectiveReturnToMore =
        widget.returnToMore == true || query['returnToMore'] == '1';

    // Read once (the getter allocates a fresh list each call).
    final savedCodes = store.savedCodes;
    final savedCities = {
      for (final code in savedCodes) directory.byCode(code)?.cityName,
    };
    final searching = foldPlaceName(_searchController.text).isNotEmpty;
    final (:cities, :towns) = _index.search(_searchController.text);

    Widget cityTile(String city) => ListTile(
      leading: const Icon(Icons.location_city_outlined),
      title: Text(city),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (savedCities.contains(city))
            Icon(Icons.star, size: 18, color: colors.primary),
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: () => context.pushNamed(
        AppRoutes.regionSelectCity,
        pathParameters: {'city': city},
        queryParameters: {
          ...?(effectiveReplaceCode == null
              ? null
              : {'replace': effectiveReplaceCode}),
          if (effectiveReturnToMore) 'returnToMore': '1',
        },
      ),
    );

    // Slivers built on demand: a one-character query such as `區` names well
    // over a hundred townships, and this rebuilds on every keystroke.
    return Scaffold(
      appBar: AppBar(title: Text(l10n.regionSelectTitle)),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
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
                  hintText: l10n.regionSearchHint,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: !searching
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
          ),
          SliverToBoxAdapter(
            child: SectionHeader(
              l10n.regionSelectCount(savedCodes.length, RegionStore.maxSaved),
            ),
          ),
          if (cities.isEmpty && towns.isEmpty)
            SliverToBoxAdapter(
              child: EmptyView(
                icon: Icons.search_off,
                message: l10n.regionSearchEmpty,
              ),
            )
          else ...[
            SliverList.builder(
              itemCount: cities.length,
              itemBuilder: (context, i) => cityTile(cities[i]),
            ),
            if (towns.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: SectionHeader(l10n.regionSearchTownsHeader),
              ),
              SliverList.builder(
                itemCount: towns.length,
                itemBuilder: (context, i) => RegionTownTile(
                  town: towns[i],
                  store: store,
                  savedCodes: savedCodes,
                  replaceCode: effectiveReplaceCode,
                  returnToMore: effectiveReturnToMore,
                  showCity: true,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
