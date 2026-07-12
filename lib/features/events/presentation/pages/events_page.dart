import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/widgets/region_bar.dart';
import 'package:flutter/material.dart';

/// Disaster-event feed. Placeholder pending the events feature; the region bar
/// at the top switches the area the feed will be scoped to.
class EventsPage extends StatelessWidget {
  const EventsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navEvents)),
      body: Column(
        children: [
          const SizedBox(height: AppSpacing.sm),
          const RegionBar(),
          Expanded(child: Center(child: Text(l10n.navEvents))),
        ],
      ),
    );
  }
}
