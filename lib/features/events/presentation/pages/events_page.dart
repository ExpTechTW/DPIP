import 'package:dpip/core/settings/home_area.dart';
import 'package:dpip/core/settings/region_store.dart';
import 'package:dpip/features/events/presentation/widgets/event_timeline.dart';
import 'package:dpip/shared/navigation/refresh_on_appear.dart';
import 'package:dpip/shared/widgets/region_bar.dart';
import 'package:dpip/shared/widgets/region_pager.dart';
import 'package:dpip/shared/widgets/region_swipe_area.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Disaster-event feed — a per-area timeline of events from the DPIP history
/// feed. The region bar switches the area (a swipe pages the whole timeline);
/// each page fetches the events for its own township.
///
/// The feed re-fetches whenever the tab is opened or the app returns from the
/// background ([RefreshOnAppear]): a hazard list is only worth reading if it is
/// current, and this page is stateful across tabs (IndexedStack), so without it
/// a feed fetched hours ago would sit there looking authoritative.
class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  /// This page's branch index in the shell.
  static const int tabIndex = 1;

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  /// Fires on every appearance; the timelines re-run their fetch.
  final RefreshSignal _refresh = RefreshSignal();

  @override
  void dispose() {
    _refresh.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshOnAppear(
      tabIndex: EventsPage.tabIndex,
      onAppear: _refresh.fire,
      child: Scaffold(
        body: RegionSwipeArea(
          child: Column(
            children: [
              const RegionBar(),
              Expanded(
                child: RegionPager(
                  itemBuilder: (context, index) => EventTimeline(
                    regionCode: _codeAt(context, index),
                    refreshSignal: _refresh,
                  ),
                ),
              ),
            ],
          ),
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
