import 'package:dpip/core/settings/home_area.dart';
import 'package:dpip/core/settings/region_store.dart';
import 'package:dpip/features/events/presentation/widgets/event_timeline.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/navigation/refresh_on_appear.dart';
import 'package:dpip/shared/widgets/empty_view.dart';
import 'package:dpip/shared/widgets/region_bar.dart';
import 'package:dpip/shared/widgets/region_pager.dart';
import 'package:dpip/shared/widgets/region_swipe_area.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Disaster-event feed — a per-area timeline of events from the DPIP history
/// feed. The region bar switches the area (a swipe pages the whole timeline);
/// each page fetches the events for its own township. 所在地 without a GPS fix
/// says so instead of showing a feed (see [_pageAt]).
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
              Expanded(child: RegionPager(itemBuilder: _pageAt)),
            ],
          ),
        ),
      ),
    );
  }

  /// The body for the area at [index].
  ///
  /// 所在地 with no GPS fix gets a notice, not a feed: the nationwide list would
  /// be indistinguishable from "these are the events where you are", which in a
  /// disaster app is the one thing it must not be mistaken for. Every other area
  /// is a township code, or null for 全國.
  Widget _pageAt(BuildContext context, int index) {
    // `read`, not `watch`: [RegionPager] already watches the store, so a fix
    // arriving rebuilds every page through it.
    final areas = context.read<RegionStore>().areas;
    final area = index >= 0 && index < areas.length
        ? areas[index]
        : const NationwideArea();
    if (area is CurrentArea && area.code == null) {
      return EmptyView(
        icon: Icons.location_off_outlined,
        message: AppLocalizations.of(context).regionCurrentUnavailable,
      );
    }
    return EventTimeline(regionCode: area.code, refreshSignal: _refresh);
  }
}
