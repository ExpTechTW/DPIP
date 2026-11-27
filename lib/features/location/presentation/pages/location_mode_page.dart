/// Chooses where the app takes the user's location from.
library;

import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/geo/location_mode.dart';
import 'package:dpip/core/geo/town.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/navigation/app_routes.dart';
import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// The location source: automatic (the GPS, the default) or one township set by
/// hand.
///
/// Every alert the server sends this device — earthquake early warnings
/// included — is targeted by the location the app reports, so a township set
/// by hand that is not where the user is means missing the alerts meant for
/// where they are. Choosing it is therefore behind a warning the user has to
/// acknowledge, and while it is on, this page leads with what it means and a
/// way back to automatic.
class LocationModePage extends StatelessWidget {
  const LocationModePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final mode = context.watch<LocationMode>();
    final manual = mode.manualTown;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.locationModeTitle)),
      body: ListView(
        padding: EdgeInsets.only(
          bottom: AppSpacing.xl + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          if (manual != null) _ManualBanner(town: manual),
          RadioGroup<bool>(
            groupValue: manual != null,
            onChanged: (wantManual) {
              if (wantManual == null || wantManual == (manual != null)) return;
              wantManual ? _chooseManual(context) : _switchToAuto(context);
            },
            child: Column(
              children: [
                RadioListTile<bool>(
                  value: false,
                  controlAffinity: ListTileControlAffinity.trailing,
                  secondary: const Icon(Icons.gps_fixed),
                  title: Text(l10n.locationModeAuto),
                  subtitle: Text(l10n.locationModeAutoSubtitle),
                ),
                RadioListTile<bool>(
                  value: true,
                  controlAffinity: ListTileControlAffinity.trailing,
                  secondary: Icon(
                    Icons.edit_location_alt_outlined,
                    color: colors.error,
                  ),
                  title: Text(l10n.locationModeManual),
                  subtitle: Text(
                    manual == null
                        ? l10n.locationModeManualSubtitle
                        : l10n.locationModeManualSummary(manual.fullName),
                  ),
                ),
              ],
            ),
          ),
          if (manual != null)
            ListTile(
              leading: const Icon(Icons.travel_explore_outlined),
              title: Text(l10n.locationModeChangeTown),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _pickTown(context),
            ),
        ],
      ),
    );
  }

  /// The warning, then the township picker; nothing changes unless the user
  /// acknowledges the warning and picks a township.
  static Future<void> _chooseManual(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const _ManualWarningDialog(),
    );
    if (confirmed != true || !context.mounted) return;
    await _pickTown(context);
  }

  static Future<void> _pickTown(BuildContext context) async {
    final mode = context.read<LocationMode>();
    final town = await context.pushNamed<Town>(AppRoutes.locationModeTown);
    if (town != null) await mode.setManual(town);
  }

  static Future<void> _switchToAuto(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final message = AppLocalizations.of(context).locationModeSwitchedToAuto;
    await context.read<LocationMode>().setAuto();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

/// What a township set by hand means, and the way back to automatic.
class _ManualBanner extends StatelessWidget {
  const _ManualBanner({required this.town});

  final Town town;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.errorContainer,
          borderRadius: AppRadius.medium,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: colors.onErrorContainer,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      l10n.locationModeManualBanner(town.fullName),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: FilledButton.icon(
                  onPressed: () => LocationModePage._switchToAuto(context),
                  icon: const Icon(Icons.gps_fixed),
                  label: Text(l10n.locationModeSwitchToAuto),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The warning before a township is set by hand. Its proceed button stays
/// disabled until the user ticks that they understand they may miss the
/// emergency alerts for where they are.
class _ManualWarningDialog extends StatefulWidget {
  const _ManualWarningDialog();

  @override
  State<_ManualWarningDialog> createState() => _ManualWarningDialogState();
}

class _ManualWarningDialogState extends State<_ManualWarningDialog> {
  bool _acknowledged = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      icon: Icon(Icons.warning_amber_rounded, color: colors.error, size: 40),
      title: Text(l10n.locationModeWarningTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.locationModeWarningBody),
            const SizedBox(height: AppSpacing.md),
            CheckboxListTile(
              value: _acknowledged,
              onChanged: (value) =>
                  setState(() => _acknowledged = value ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              title: Text(
                l10n.locationModeWarningAcknowledge,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.locationModeKeepAuto),
        ),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: colors.error),
          onPressed: _acknowledged
              ? () => Navigator.of(context).pop(true)
              : null,
          child: Text(l10n.locationModeWarningContinue),
        ),
      ],
    );
  }
}
