/// Manages the user's saved 常用地區 (up to [RegionStore.maxSaved]).
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

/// Lists the currently saved townships with a remove action, and an **add**
/// button that opens the region picker ([RegionSelectPage]).
///
/// Splitting "review what's saved" from "browse to add" (the picker) mirrors the
/// legacy two-step flow: the More menu now opens this manage page, and adding is
/// a distinct push into the city → township picker. The add button hides once
/// the [RegionStore.maxSaved] cap is reached.
class RegionManagePage extends StatelessWidget {
  const RegionManagePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final directory = context.read<TownDirectory>();
    final store = context.watch<RegionStore>();
    final saved = store.savedCodes;
    final canAdd = saved.length < RegionStore.maxSaved;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.regionManageTitle)),
      floatingActionButton: canAdd
          ? FloatingActionButton.extended(
              onPressed: () => context.pushNamed(AppRoutes.regionSelect),
              icon: const Icon(Icons.add),
              label: Text(l10n.regionAddButton),
            )
          : null,
      body: saved.isEmpty
          ? EmptyView(icon: Icons.pin_drop_outlined, message: l10n.regionEmpty)
          : ReorderableListView.builder(
              // The drag handle is the only drag trigger, so a long-press on the
              // row (e.g. to hit delete) doesn't start a reorder.
              buildDefaultDragHandles: false,
              padding: const EdgeInsets.only(bottom: AppSpacing.xxl * 2),
              header: SectionHeader(
                l10n.regionSelectCount(saved.length, RegionStore.maxSaved),
              ),
              itemCount: saved.length,
              onReorderItem: store.reorderSaved,
              itemBuilder: (context, index) {
                final code = saved[index];
                return ListTile(
                  key: ValueKey(code),
                  leading: const Icon(Icons.location_on_outlined),
                  title: Text(directory.byCode(code)?.townName ?? code),
                  subtitle: Text(directory.byCode(code)?.cityName ?? ''),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => store.removeSaved(code),
                      ),
                      ReorderableDragStartListener(
                        index: index,
                        child: const Icon(Icons.drag_handle),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
