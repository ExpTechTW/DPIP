import 'package:dpip/core/settings/home_area.dart';
import 'package:dpip/core/settings/region_store.dart';
import 'package:dpip/features/events/presentation/widgets/event_timeline.dart';
import 'package:dpip/shared/widgets/region_bar.dart';
import 'package:dpip/shared/widgets/region_pager.dart';
import 'package:dpip/shared/widgets/region_swipe_area.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Disaster-event feed — a per-area timeline of events from the DPIP history
/// feed. The region bar switches the area (a swipe pages the whole timeline);
/// each page fetches the events for its own township.
class EventsPage extends StatelessWidget {
  const EventsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RegionSwipeArea(
        child: Column(
          children: [
            const RegionBar(),
            Expanded(
              child: RegionPager(
                itemBuilder: (context, index) =>
                    EventTimeline(regionCode: _codeAt(context, index)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The township whose events the page at [index] shows — null for 全國, and
  /// also for 所在地 with no GPS fix, which then falls back to the nationwide
  /// feed rather than showing an empty thread for an unknown place.
  static String? _codeAt(BuildContext context, int index) {
    final areas = context.read<RegionStore>().areas;
    if (index < 0 || index >= areas.length) return null;
    return switch (areas[index]) {
      NationwideArea() => null,
      CurrentArea(:final code) => code,
      SavedArea(:final code) => code,
    };
  }
}
