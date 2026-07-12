import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';

/// Earthquake monitor. Placeholder — this is the swappable bottom-nav slot.
class EarthquakePage extends StatelessWidget {
  const EarthquakePage({super.key});

  /// Route path.
  static const String path = '/earthquake';

  /// Route name.
  static const String name = 'earthquake';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navEarthquake)),
      body: Center(child: Text(l10n.navEarthquake)),
    );
  }
}
