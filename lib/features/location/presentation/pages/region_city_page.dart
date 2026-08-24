/// The second level of the region picker: the townships within one city, each
/// toggleable as a saved Home region (up to [RegionStore.maxSaved]).
library;

import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/geo/town.dart';
import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/core/settings/region_store.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/navigation/app_routes.dart';
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final directory = context.read<TownDirectory>();
    final store = context.watch<RegionStore>();
    final towns = directory.townsInCity(widget.city);
    final query = GoRouterState.of(context).uri.queryParameters;
    final effectiveReplaceCode = widget.replaceCode ?? query['replace'];

    final needle = _searchController.text.trim().toLowerCase();
    final shown = [
      for (final town in towns)
        if (needle.isEmpty || town.townName.toLowerCase().contains(needle))
          town,
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
            l10n.regionSelectCount(
              store.savedCodes.length,
              RegionStore.maxSaved,
            ),
          ),
          if (shown.isEmpty)
            EmptyView(
              icon: Icons.search_off,
              message: l10n.regionSearchTownEmpty,
            )
          else
            for (final town in shown)
              _TownTile(
                town: town,
                saved: store.savedCodes.contains(town.code),
                enabled:
                    effectiveReplaceCode == null ||
                    town.code == effectiveReplaceCode ||
                    !store.savedCodes.contains(town.code),
                canAdd:
                    effectiveReplaceCode != null ||
                    store.canSave(town.code) ||
                    store.savedCodes.contains(town.code),
                onToggle: () => _toggle(context, store, town),
              ),
        ],
      ),
    );
  }

  void _toggle(BuildContext context, RegionStore store, Town town) {
    final query = GoRouterState.of(context).uri.queryParameters;
    final replace = widget.replaceCode ?? query['replace'];
    final shouldReturnToMore =
        widget.returnToMore == true || query['returnToMore'] == '1';
    var changed = false;
    if (replace != null) {
      if (store.savedCodes.contains(town.code) && town.code != replace) return;
      changed = store.replaceSaved(replace, town.code);
    } else if (store.savedCodes.contains(town.code)) {
      store.removeSaved(town.code);
      changed = true;
    } else if (!store.addSaved(town.code)) {
      // At the cap — nothing added; explain the limit.
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(l10n.regionSelectFull(RegionStore.maxSaved))),
        );
    } else {
      changed = true;
    }
    if (changed && shouldReturnToMore) {
      context.goNamed(AppRoutes.more);
    }
  }
}

/// One township row — name, code + centroid coordinates, and a star that
/// reflects and toggles its saved state.
class _TownTile extends StatelessWidget {
  const _TownTile({
    required this.town,
    required this.saved,
    required this.enabled,
    required this.canAdd,
    required this.onToggle,
  });

  final Town town;
  final bool saved;
  final bool enabled;
  final bool canAdd;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    // Saved → primary star; addable → muted outline; at the cap → dimmed.
    final starColor = !enabled
        ? colors.onSurface.withValues(alpha: 0.3)
        : saved
        ? colors.primary
        : canAdd
        ? colors.onSurfaceVariant
        : colors.onSurface.withValues(alpha: 0.3);

    return ListTile(
      enabled: enabled,
      leading: const Icon(Icons.location_on_outlined),
      title: Text(town.townName),
      subtitle: Text(
        '${town.code}・${town.lng.toStringAsFixed(2)}°E・'
        '${town.lat.toStringAsFixed(2)}°N',
      ),
      trailing: Icon(saved ? Icons.star : Icons.star_border, color: starColor),
      onTap: enabled ? onToggle : null,
    );
  }
}
