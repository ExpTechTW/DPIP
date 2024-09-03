import 'package:dpip/api/exptech.dart';
import 'package:dpip/global.dart';
import 'package:dpip/model/history.dart';
import 'package:dpip/route/settings/settings.dart';
import 'package:dpip/util/extension/build_context.dart';
import 'package:dpip/util/list_icon.dart';
import 'package:dpip/widget/error/region_out_of_service.dart';
import 'package:dpip/widget/home/event_list_route.dart';
import 'package:dpip/widget/list/timeline_tile.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class HistoryPage extends StatefulWidget {
  final Function()? onPositionUpdate;

  const HistoryPage({super.key, this.onPositionUpdate});

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
  String city = '';
  String town = '';

  final scrollController = ScrollController();
  late AnimationController animController;
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
    int code = Global.preference.getInt("user-code") ?? -1;
    city = Global.location[code.toString()]?.city ?? "";
    town = Global.location[code.toString()]?.town ?? "";
    region = code == -1 ? null : code.toString();
    refreshHistoryList();
  }

  void _handlePositionUpdate() {
    if (mounted) {
      _initData();
      widget.onPositionUpdate?.call();
    }
  }

  Future<void> refreshHistoryList() async {
    if (region == null && !country) return;
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

  Widget _buildLocationButton() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton.icon(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            settings: const RouteSettings(name: '/settings'),
            builder: (context) => const SettingsRoute(initialRoute: '/location'),
          ),
        ),
        icon: const Icon(Symbols.pin_drop_rounded),
        label: Text('$city$town', style: const TextStyle(fontSize: 20)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildLocationButton(),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: context.colors.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Expanded(child: _buildToggleButton(true, Symbols.public_rounded, '全國')),
            Expanded(child: _buildToggleButton(false, Symbols.my_location_rounded, '所在地')),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButton(bool isCountry, IconData icon, String label) {
    final isSelected = country == isCountry;
    return Stack(
      children: [
        Positioned.fill(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected ? context.colors.primaryContainer.withOpacity(0.7) : Colors.transparent,
              borderRadius: BorderRadius.horizontal(
                left: isCountry ? const Radius.circular(18) : Radius.zero,
                right: !isCountry ? const Radius.circular(18) : Radius.zero,
              ),
            ),
          ),
        ),
        InkWell(
          onTap: () => setState(() {
            country = isCountry;
            refreshHistoryList();
          }),
          child: Container(
            height: 36,
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: isSelected ? context.colors.primary : context.colors.onSurfaceVariant.withOpacity(0.8),
                ),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? context.colors.primary : context.colors.onSurfaceVariant.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryList() {
    if (region == null && !country) {
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
              height: 140,
              first: historyIndex == 0,
              showDate: showDate,
              color: context.colors.secondaryContainer,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          history.text.content["all"]!.subtitle,
                          style: context.theme.textTheme.titleMedium,
                        ),
                        Text(
                          history.text.description["all"]!,
                        ),
                      ],
                    ),
                  ),
                  if (shouldShowArrow(history))
                    const Padding(
                      padding: EdgeInsets.only(left: 8.0),
                      child: Icon(Icons.arrow_forward_ios),
                    ),
                ],
              ),
              onTap: () => handleEventList(context, history),
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

  @override
  void dispose() {
    HistoryPage.clearActiveCallback();
    scrollController.dispose();
    animController.dispose();
    super.dispose();
  }
}
