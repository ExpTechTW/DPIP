/// The first level of the region picker: a search field over the counties and
/// cities, then the full city list to drill into.
library;

import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/core/settings/region_store.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/navigation/app_routes.dart';
import 'package:dpip/shared/widgets/empty_view.dart';
import 'package:dpip/shared/widgets/section_header.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// The city level of the region picker, with a filter on top.
///
/// The query narrows the city list in place — it never leaves this page: a
/// matching city keeps its star marker and drill-down, a non-matching one
/// disappears, and no match at all shows an empty view. Townships are reached
/// by drilling in, as before.
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

    final savedCities = {
      for (final code in store.savedCodes) directory.byCode(code)?.cityName,
    };
    final needle = _searchController.text.trim().toLowerCase();
    final cities = [
      for (final city in directory.cities)
        if (needle.isEmpty || city.toLowerCase().contains(needle)) city,
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.regionSelectTitle)),
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
                hintText: l10n.regionSearchHint,
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
            l10n.regionSelectCount(
              store.savedCodes.length,
              RegionStore.maxSaved,
            ),
          ),
          if (cities.isEmpty)
            EmptyView(icon: Icons.search_off, message: l10n.regionSearchEmpty)
          else
            for (final city in cities)
              ListTile(
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
              ),
        ],
      ),
    );
  }
}
