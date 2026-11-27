/// Picks the one township a location set by hand is pinned to.
library;

import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/geo/place_search.dart';
import 'package:dpip/core/geo/town.dart';
import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/widgets/empty_view.dart';
import 'package:dpip/shared/widgets/section_header.dart';
import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// A search over the counties, cities and townships, then the city list and a
/// city's townships; tapping a township pops this page with it.
///
/// Single choice and nothing saved here — the caller decides what the
/// township is for. The home region picker writes to the saved regions as it
/// goes, which is why this is its own page rather than that one.
class LocationTownPickerPage extends StatefulWidget {
  const LocationTownPickerPage({super.key});

  @override
  State<LocationTownPickerPage> createState() => _LocationTownPickerPageState();
}

class _LocationTownPickerPageState extends State<LocationTownPickerPage> {
  final _searchController = TextEditingController();

  /// The city being browsed; null on the city list.
  String? _city;

  late final TownDirectory _directory = context.read<TownDirectory>();

  /// The place names, folded once for the page's lifetime (see
  /// `RegionSelectPage`).
  late final PlaceSearchIndex _index = PlaceSearchIndex(_directory);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final city = _city;
    final cityTowns = city == null
        ? const <Town>[]
        : _directory.townsInCity(city);

    return PopScope(
      // Back from a city's townships returns to the city list first.
      canPop: city == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _city = null);
      },
      child: Scaffold(
        appBar: AppBar(title: Text(city ?? l10n.locationModePickTownTitle)),
        body: city == null
            ? _cityLevel(l10n)
            : ListView.builder(
                itemCount: cityTowns.length,
                itemBuilder: (context, i) =>
                    _townTile(cityTowns[i], showCity: false),
              ),
      ),
    );
  }

  Widget _cityLevel(AppLocalizations l10n) {
    final searching = foldPlaceName(_searchController.text).isNotEmpty;
    final (:cities, :towns) = _index.search(_searchController.text);
    return CustomScrollView(
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
            itemBuilder: (context, i) => ListTile(
              leading: const Icon(Icons.location_city_outlined),
              title: Text(cities[i]),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => setState(() => _city = cities[i]),
            ),
          ),
          if (towns.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: SectionHeader(l10n.regionSearchTownsHeader),
            ),
            SliverList.builder(
              itemCount: towns.length,
              itemBuilder: (context, i) => _townTile(towns[i], showCity: true),
            ),
          ],
        ],
      ],
    );
  }

  Widget _townTile(Town town, {required bool showCity}) => ListTile(
    leading: const Icon(Icons.place_outlined),
    title: Text(town.townName),
    subtitle: showCity ? Text(town.cityName) : null,
    onTap: () => context.pop(town),
  );
}
