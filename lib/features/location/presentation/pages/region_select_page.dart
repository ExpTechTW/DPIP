/// The first level of the region picker: a list of cities to drill into.
library;

import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/core/settings/region_store.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/navigation/app_routes.dart';
import 'package:dpip/shared/widgets/section_header.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// Lists every city (`縣市`); tapping one opens its township list where regions
/// are toggled on/off. A city that already holds a saved township is marked with
/// a star, and the header shows how many of the [RegionStore.maxSaved] slots are
/// used — so the whole selection is legible from the top level.
class RegionSelectPage extends StatelessWidget {
  const RegionSelectPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final directory = context.read<TownDirectory>();
    final store = context.watch<RegionStore>();

    final cities = directory.cities;
    // Cities that contain at least one saved township, for the star marker.
    final savedCities = {
      for (final code in store.savedCodes) directory.byCode(code)?.cityName,
    };

    return Scaffold(
      appBar: AppBar(title: Text(l10n.regionSelectTitle)),
      body: ListView(
        children: [
          SectionHeader(
            l10n.regionSelectCount(
              store.savedCodes.length,
              RegionStore.maxSaved,
            ),
          ),
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
              ),
            ),
        ],
      ),
    );
  }
}
