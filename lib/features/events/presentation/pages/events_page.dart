import 'package:dpip/features/events/presentation/widgets/event_timeline.dart';
import 'package:dpip/shared/widgets/region_bar.dart';
import 'package:dpip/shared/widgets/region_pager.dart';
import 'package:dpip/shared/widgets/region_swipe_area.dart';
import 'package:flutter/material.dart';

/// Disaster-event feed — a per-area timeline of events. The region bar switches
/// the area (a swipe pages the whole timeline); content is placeholder until the
/// history API is wired.
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
                itemBuilder: (context, index) => const EventTimeline(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
