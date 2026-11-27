import 'package:dpip/core/platform/device_sensors.dart';
import 'package:dpip/core/settings/experimental_settings.dart';
import 'package:dpip/features/settings/presentation/experimental/experimental_option.dart';
import 'package:dpip/features/settings/presentation/experimental/experimental_options.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/widgets/section_header.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

/// Experimental / in-progress features, reachable from the More tab.
///
/// The entry is always there; what the page lists is decided per option by the
/// registry (`experimental_options.dart`): only what this platform supports,
/// an option that needs a sensor only on a device known to have it, and an
/// option that needs the Developer page's unlock only once it is unlocked.
/// Options are grouped under one header per category, in the categories'
/// fixed order, and a category with nothing to show is left out.
/// With nothing to show at all the page is simply empty — there is no
/// placeholder, because the only thing it could say is that this device has no
/// experiments, which the empty page already says.
class ExperimentalPage extends StatelessWidget {
  const ExperimentalPage({
    super.key,
    required this.watchWeatherCode,
    this.options = experimentalOptions,
  });

  /// Watches the live weather code from the page's context. The app wires
  /// this to the home feed, since one feature cannot import another's.
  final int? Function(BuildContext context) watchWeatherCode;

  /// The registry to list. Only tests pass anything but the default.
  final List<ExperimentalOption> options;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final unlocked = context.select<ExperimentalSettings, bool>(
      (s) => s.unlocked,
    );
    final sensors = context.select<DeviceSensors, Set<DeviceSensor>>(
      (s) => s.present,
    );
    // defaultTargetPlatform rather than the theme's platform: availability is
    // a fact about the device, not about how the UI is styled — and tests can
    // still override it.
    final sections = experimentalSections(
      options,
      platform: defaultTargetPlatform,
      unlocked: unlocked,
      sensors: sensors,
    );
    final host = ExperimentalHost(watchWeatherCode: watchWeatherCode);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.experimentalFeatures)),
      body: ListView(
        children: [
          for (final (category, entries) in sections) ...[
            SectionHeader(category.label(l10n)),
            for (final option in entries) option.build(context, host),
          ],
        ],
      ),
    );
  }
}
