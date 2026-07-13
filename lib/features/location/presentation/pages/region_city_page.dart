/// The second level of the region picker: the townships within one city, each
/// toggleable as a saved Home region (up to [RegionStore.maxSaved]).
library;

import 'package:dpip/core/geo/town.dart';
import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/core/settings/region_store.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/widgets/section_header.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Lists the townships of [city]. Tapping a row toggles it as a saved region:
/// a saved row shows a filled star and removes on tap; an unsaved row adds
/// (when under the cap) or, once full, leaves the selection unchanged and
/// explains the limit. The selection is stored by **code** in the [RegionStore];
/// names and coordinates shown here are derived from the directory.
class RegionCityPage extends StatelessWidget {
  const RegionCityPage({super.key, required this.city});

  /// The city display name (`縣市`) whose townships this page lists.
  final String city;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final directory = context.read<TownDirectory>();
    final store = context.watch<RegionStore>();
    final towns = directory.townsInCity(city);

    return Scaffold(
      appBar: AppBar(title: Text(city)),
      body: ListView(
        children: [
          SectionHeader(
            l10n.regionSelectCount(
              store.savedCodes.length,
              RegionStore.maxSaved,
            ),
          ),
          for (final town in towns)
            _TownTile(
              town: town,
              saved: store.savedCodes.contains(town.code),
              canAdd: store.canSave(town.code),
              onToggle: () => _toggle(context, store, town),
            ),
        ],
      ),
    );
  }

  void _toggle(BuildContext context, RegionStore store, Town town) {
    if (store.savedCodes.contains(town.code)) {
      store.removeSaved(town.code);
    } else if (!store.addSaved(town.code)) {
      // At the cap — nothing added; explain the limit.
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(l10n.regionSelectFull(RegionStore.maxSaved))),
        );
    }
  }
}

/// One township row — name, code + centroid coordinates, and a star that
/// reflects and toggles its saved state.
class _TownTile extends StatelessWidget {
  const _TownTile({
    required this.town,
    required this.saved,
    required this.canAdd,
    required this.onToggle,
  });

  final Town town;
  final bool saved;
  final bool canAdd;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    // Saved → primary star; addable → muted outline; at the cap → dimmed.
    final starColor = saved
        ? colors.primary
        : canAdd
        ? colors.onSurfaceVariant
        : colors.onSurface.withValues(alpha: 0.3);

    return ListTile(
      leading: const Icon(Icons.location_on_outlined),
      title: Text(town.townName),
      subtitle: Text(
        '${town.code}・${town.lng.toStringAsFixed(2)}°E・'
        '${town.lat.toStringAsFixed(2)}°N',
      ),
      trailing: Icon(saved ? Icons.star : Icons.star_border, color: starColor),
      onTap: onToggle,
    );
  }
}
