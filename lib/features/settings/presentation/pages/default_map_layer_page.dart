/// Settings: pick the Map tab's default overlay (also drives bottom-nav chrome).
library;

import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/settings/default_map_layer.dart';
import 'package:dpip/core/settings/default_map_layer_controller.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/map/default_map_layer_ui.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Full-screen list of map overlays — the active choice carries a trailing
/// check; tapping one updates [DefaultMapLayerController] (nav icon/label +
/// next map open).
class DefaultMapLayerPage extends StatelessWidget {
  const DefaultMapLayerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = context.watch<DefaultMapLayerController>();
    final current = controller.layer;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.defaultMapLayerSettings)),
      body: ListView(
        padding: EdgeInsets.only(
          bottom: AppSpacing.xl + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Text(
              l10n.defaultMapLayerSubtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          for (final layer in DefaultMapLayer.values)
            ListTile(
              leading: Icon(layer.icon),
              title: Text(layer.label(l10n)),
              trailing: current == layer
                  ? Icon(
                      Icons.check,
                      color: Theme.of(context).colorScheme.primary,
                    )
                  : null,
              onTap: () => controller.setLayer(layer),
            ),
        ],
      ),
    );
  }
}
