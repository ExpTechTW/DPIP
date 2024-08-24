import 'package:collection/collection.dart';
import 'package:dpip/api/exptech.dart';
import 'package:dpip/global.dart';
import 'package:dpip/model/history.dart';
import 'package:dpip/util/extension/build_context.dart';
import 'package:dpip/util/extension/color_scheme.dart';
import 'package:dpip/util/list_icon.dart';
import 'package:dpip/widget/error/region_out_of_service.dart';
import 'package:dpip/widget/list/timeline_tile.dart';
import 'package:flutter/material.dart';

typedef PositionUpdateCallback = void Function();

class HistoryPage extends StatefulWidget {
  final Function()? onPositionUpdate;

  const HistoryPage({Key? key, this.onPositionUpdate}) : super(key: key);

  @override
  State<HistoryPage> createState() => _HistoryPageState();

  static PositionUpdateCallback? _activeCallback;

  static void setActiveCallback(PositionUpdateCallback callback) {
    _activeCallback = callback;
  }

  static void clearActiveCallback() {
    _activeCallback = null;
  }

  static void updatePosition() {
    _activeCallback?.call();
  }
}

class _HistoryPageState extends State<HistoryPage> with TickerProviderStateMixin {
  List<History> historyList = [];
  double userLat = 0;
  double userLon = 0;
  bool isUserLocationValid = false;
  bool init = false;
  String city = Global.preference.getString("location-city") ?? "";
  String town = Global.preference.getString("location-town") ?? "";
  String? region;

  late final backgroundColor = Color.lerp(context.colors.surface, context.colors.surfaceTint, 0.08);

  late final decorationTween = DecorationTween(
    begin: BoxDecoration(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      boxShadow: kElevationToShadow[4],
      color: backgroundColor,
    ),
    end: BoxDecoration(
      borderRadius: BorderRadius.zero,
      boxShadow: kElevationToShadow[4],
      color: backgroundColor,
    ),
  ).chain(CurveTween(curve: Curves.linear));

  final opacityTween = Tween(
    begin: 0.0,
    end: 1.0,
  ).chain(CurveTween(curve: Curves.linear));

  final scrollController = ScrollController();
  late final animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));

  double headerHeight = 360;
  bool isAppBarVisible = false;

  Future<void> refreshHistoryList() async {
    if (region == null) return;

    final data = await ExpTech().getHistoryRegion(region!);
    setState(() {
      init = true;
      historyList = data.reversed.toList();
    });
  }

  @override
  void initState() {
    super.initState();
    start();
    HistoryPage.setActiveCallback(sendpositionUpdate);
  }

  void start() {
    city = Global.preference.getString("location-city") ?? "";
    town = Global.preference.getString("location-town") ?? "";
    region = Global.location.entries.firstWhereOrNull((l) => (l.value.city == city) && (l.value.town == town))?.key;
    historyList = [];
    if (region == null) {
      setState(() {});
      return;
    }
    refreshHistoryList();
    double headerScrollHeight = headerHeight / 5 * 3;
    scrollController.addListener(() {
      if (scrollController.offset > 1e-5) {
        if (!isAppBarVisible) {
          setState(() => isAppBarVisible = true);
        }
      } else {
        if (isAppBarVisible) {
          setState(() => isAppBarVisible = false);
        }
      }

      if (scrollController.offset < headerScrollHeight) {
        animController.animateTo(scrollController.offset / headerScrollHeight, duration: Duration.zero);
      }
    });
    setState(() {});
  }

  void sendpositionUpdate() {
    if (mounted) {
      start();
      widget.onPositionUpdate?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final appBar = AppBar(
      elevation: 4,
      title: Text(context.i18n.history),
    );

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            RefreshIndicator(
              onRefresh: refreshHistoryList,
              child: ListView(
                padding: EdgeInsets.only(bottom: context.padding.bottom),
                controller: scrollController,
                children: (region == null)
                    ? [
                        const Padding(
                          padding: EdgeInsets.only(top: 128),
                          child: RegionOutOfService(),
                        )
                      ]
                    : [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 32, 0, 8),
                          child: Text(
                            context.i18n.historical_events,
                            style: TextStyle(fontSize: 20, color: context.colors.onSurfaceVariant),
                          ),
                        ),
                        Builder(
                          builder: (context) {
                            if (historyList.isEmpty) {
                              if (init) {
                                return Center(child: Text(context.i18n.no_historical_events));
                              }
                              return const Center(child: CircularProgressIndicator());
                            }

                            List<Widget> children = [];

                            for (var i = 0, n = historyList.length; i < n; i++) {
                              final current = historyList[i];
                              var showDate = false;

                              if (i != 0) {
                                final prev = historyList[i - 1];
                                if (current.time.send.day != prev.time.send.day) {
                                  showDate = true;
                                }
                              } else {
                                showDate = true;
                              }

                              final item = TimeLineTile(
                                time: current.time.send,
                                icon: Icon(ListIcons.getListIcon(current.type)),
                                height: 100,
                                first: i == 0,
                                showDate: showDate,
                                color: context.theme.extendedColors.blueContainer,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(current.text.content["all"]!.subtitle,
                                        style: context.theme.textTheme.titleMedium),
                                    Text(current.text.description["all"]!),
                                  ],
                                ),
                                onTap: () {},
                              );

                              children.add(item);
                            }

                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Column(
                                children: children,
                              ),
                            );
                          },
                        )
                      ],
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Visibility(
                visible: isAppBarVisible,
                child: FadeTransition(
                  opacity: animController.drive(opacityTween),
                  child: appBar,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    HistoryPage.clearActiveCallback();
    scrollController.dispose();
    super.dispose();
  }
}
