import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/widgets/region_bar.dart';
import 'package:dpip/shared/widgets/region_swipe_area.dart';
import 'package:flutter/material.dart';

/// Disaster-event feed. Placeholder pending the events feature; the region bar
/// at the top switches the area the feed is scoped to (swipe anywhere).
class EventsPage extends StatelessWidget {
  const EventsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: RegionSwipeArea(
        child: Column(
          children: [
            const SafeArea(bottom: false, child: RegionBar()),
            Expanded(child: Center(child: Text(l10n.navEvents))),
          ],
        ),
      ),
    );
  }
}
