/// The switch that lists the phone seismometer on the Data tab, as an
/// Experimental features option.
library;

import 'package:dpip/core/settings/experimental_settings.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

/// Turns the Data tab's seismometer entry on or off. Off by default — see
/// `ExperimentalSettings.seismometerEnabled`.
class SeismometerOption extends StatelessWidget {
  const SeismometerOption({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final enabled = context.select<ExperimentalSettings, bool>(
      (s) => s.seismometerEnabled,
    );
    return SwitchListTile(
      secondary: const Icon(Icons.vibration_outlined),
      title: Text(l10n.experimentalSeismometer),
      subtitle: Text(l10n.experimentalSeismometerSubtitle),
      value: enabled,
      onChanged: context.read<ExperimentalSettings>().setSeismometerEnabled,
    );
  }
}
