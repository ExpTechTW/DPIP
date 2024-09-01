import 'package:collection/collection.dart';
import 'package:dpip/api/exptech.dart';
import 'package:dpip/global.dart';
import 'package:dpip/model/history.dart';
import 'package:dpip/util/extension/build_context.dart';
import 'package:dpip/util/list_icon.dart';
import 'package:dpip/widget/error/region_out_of_service.dart';
import 'package:dpip/widget/list/timeline_tile.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class HistoryPage extends StatefulWidget {
  final Function()? onPositionUpdate;

  const HistoryPage({Key? key, this.onPositionUpdate}) : super(key: key);

  @override
  State<HistoryPage> createState() => _HistoryPageState();

  static void updatePosition() => _activeCallback?.call();

  static void setActiveCallback(VoidCallback callback) => _activeCallback = callback;

  static void clearActiveCallback() => _activeCallback = null;

  static VoidCallback? _activeCallback;
}

class _HistoryPageState extends State<HistoryPage> with TickerProviderStateMixin {
  List<History> historyList = [];
  bool country = false;
  bool isLoading = true;
  String? region;

  final scrollController = ScrollController();
  late var animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
  bool isAppBarVisible = false;

  @override
  void initState() {
    super.initState();
    animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _initData();
    HistoryPage.setActiveCallback(_handlePositionUpdate);
    _setupScrollListener();
  }

  void _setupScrollListener() {
    scrollController.addListener(() {
      if (mounted) {
        setState(() => isAppBarVisible = scrollController.offset > 1e-5);
        if (scrollController.offset < 180) {
          animController.animateTo(scrollController.offset / 180);
        }
      }
    });
  }

  void _initData() {
    final city = Global.preference.getString("location-city") ?? "";
    final town = Global.preference.getString("location-town") ?? "";
    region = Global.location.entries.firstWhereOrNull((l) => l.value.city == city && l.value.town == town)?.key;
    refreshHistoryList();
  }

  void _handlePositionUpdate() {
    if (mounted) {
      _initData();
      widget.onPositionUpdate?.call();
    }
  }

  Future<void> refreshHistoryList() async {
    if (region == null) return;
    setState(() => isLoading = true);
    try {
      final data = country ? await ExpTech().getHistory() : await ExpTech().getHistoryRegion(region!);
      if (mounted) {
        setState(() {
          historyList = data.reversed.toList();
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildLocationToggle(),
            Expanded(
              child: Stack(
                children: [
                  _buildMainContent(),
                  _buildAppBar(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return RefreshIndicator(
      onRefresh: refreshHistoryList,
      child: CustomScrollView(
        controller: scrollController,
        slivers: [
          SliverPadding(
            padding: EdgeInsets.only(bottom: context.padding.bottom),
            sliver: _buildHistoryList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationToggle() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildToggleButton(
              icon: Symbols.public_rounded,
              label: '全國',
              isSelected: country,
              onTap: () => _toggleView(true),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildToggleButton(
              icon: Symbols.my_location_rounded,
              label: '所在地',
              isSelected: !country,
              onTap: () => _toggleView(false),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? context.colors.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? context.colors.primary : context.colors.outline,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? context.colors.primary : context.colors.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? context.colors.primary : context.colors.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList() {
    if (region == null) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.only(top: 128),
          child: RegionOutOfService(),
        ),
      );
    }

    if (isLoading) {
      return const SliverToBoxAdapter(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (historyList.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(child: Text(context.i18n.no_historical_events)),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                context.i18n.historical_events,
                style: context.theme.textTheme.headlineSmall,
              ),
            );
          }
          final historyIndex = index - 1;
          final history = historyList[historyIndex];
          final showDate = historyIndex == 0 || history.time.send.day != historyList[historyIndex - 1].time.send.day;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TimeLineTile(
              time: history.time.send,
              icon: Icon(ListIcons.getListIcon(history.icon)),
              height: 100,
              first: historyIndex == 0,
              showDate: showDate,
              color: context.colors.secondaryContainer,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(history.text.content["all"]!.subtitle, style: context.theme.textTheme.titleMedium),
                  Text(history.text.description["all"]!),
                ],
              ),
              onTap: () {},
            ),
          );
        },
        childCount: historyList.isEmpty ? 1 : historyList.length + 1,
      ),
    );
  }

  Widget _buildAppBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: AnimatedOpacity(
        opacity: isAppBarVisible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: AppBar(
          elevation: 4,
          title: Text(context.i18n.history),
          backgroundColor: context.colors.surface.withOpacity(0.8),
        ),
      ),
    );
  }

  void _toggleView(bool isCountry) {
    setState(() {
      country = isCountry;
      refreshHistoryList();
    });
  }

  @override
  void dispose() {
    HistoryPage.clearActiveCallback();
    scrollController.dispose();
    animController.dispose();
    super.dispose();
  }
}
