/// One pickable township row of the region picker, and what tapping it does —
/// shared by the city list's search results and the township list inside a
/// city, so a township chosen from either place behaves the same.
library;

import 'package:dpip/core/geo/town.dart';
import 'package:dpip/core/settings/region_store.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/navigation/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// A township row: name, code + centroid coordinates, and a star that
/// reflects and toggles its saved state in [store].
///
/// [showCity] titles the row with the full `縣市 鄉鎮市區` name — for a search
/// result, where townships from different cities share a name (two 中正區, two
/// 東區) and the row is the only place the user can tell them apart.
///
/// [replaceCode] is the saved township this pick replaces (the manage page's
/// "change" flow), and [returnToMore] goes back to the More tab after a change
/// that landed — both as the picker received them.
class RegionTownTile extends StatelessWidget {
  const RegionTownTile({
    super.key,
    required this.town,
    required this.store,
    required this.savedCodes,
    this.replaceCode,
    this.returnToMore = false,
    this.showCity = false,
  });

  final Town town;
  final RegionStore store;

  /// [RegionStore.savedCodes], read once by the list rather than once per row
  /// (the getter allocates a fresh list each call).
  final List<String> savedCodes;
  final String? replaceCode;
  final bool returnToMore;
  final bool showCity;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final saved = savedCodes.contains(town.code);
    // Replacing: another already-saved township cannot be the replacement.
    final enabled = replaceCode == null || town.code == replaceCode || !saved;
    final canAdd = replaceCode != null || store.canSave(town.code) || saved;
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
      title: Text(showCity ? town.fullName : town.townName),
      subtitle: Text(
        '${town.code}・${town.lng.toStringAsFixed(2)}°E・'
        '${town.lat.toStringAsFixed(2)}°N',
      ),
      trailing: Icon(saved ? Icons.star : Icons.star_border, color: starColor),
      onTap: enabled ? () => _toggle(context) : null,
    );
  }

  /// A saved row removes on tap; an unsaved row adds (when under the cap) or,
  /// once full, leaves the selection unchanged and explains the limit. With a
  /// [replaceCode] the tap swaps that saved township for this one instead.
  void _toggle(BuildContext context) {
    var changed = false;
    final replace = replaceCode;
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
    if (changed && returnToMore) {
      context.goNamed(AppRoutes.more);
    }
  }
}
