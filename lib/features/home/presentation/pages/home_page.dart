import 'package:dpip/app/theme/app_motion.dart';
import 'package:dpip/core/settings/experimental_settings.dart';
import 'package:dpip/features/home/presentation/home_reset_signal.dart';
import 'package:dpip/features/home/presentation/widgets/home_map_backdrop.dart';
import 'package:dpip/features/home/presentation/widgets/home_sheet.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Home tab — a full-bleed map with a draggable [HomeSheet] over it.
///
/// This host owns only the drag mechanics: the sheet rests at [HomeSheet.restExtent]
/// and springs back there when released, or expands to [HomeSheet.maxExtent].
/// The sheet's look and content live in [HomeSheet] / `HomeContent`.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final DraggableScrollableController _sheet = DraggableScrollableController();
  final ValueNotifier<double> _extent = ValueNotifier<double>(
    HomeSheet.restExtent,
  );
  HomeResetSignal? _resetSignal;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final signal = context.read<HomeResetSignal>();
    if (signal != _resetSignal) {
      _resetSignal?.removeListener(_resetSheet);
      _resetSignal = signal..addListener(_resetSheet);
    }
  }

  /// Snaps the sheet back to rest (used when the Home tab is re-entered).
  void _resetSheet() {
    if (!_sheet.isAttached) return;
    if ((_sheet.size - HomeSheet.restExtent).abs() < 0.001) return;
    _sheet.jumpTo(HomeSheet.restExtent);
    _extent.value = HomeSheet.restExtent;
  }

  @override
  void dispose() {
    _resetSignal?.removeListener(_resetSheet);
    _sheet.dispose();
    _extent.dispose();
    super.dispose();
  }

  bool _onExtentChanged(DraggableScrollableNotification notification) {
    _extent.value = notification.extent;
    return false;
  }

  /// Snaps the sheet to the nearest detent when a drag ends: down to
  /// [HomeSheet.restExtent] (spring-back) or up to [HomeSheet.maxExtent].
  void _settle() {
    if (!_sheet.isAttached) return;
    final size = _sheet.size;
    final target = size < (HomeSheet.restExtent + HomeSheet.maxExtent) / 2
        ? HomeSheet.restExtent
        : HomeSheet.maxExtent;
    if ((size - target).abs() < 0.001) return;
    _sheet.animateTo(target, duration: AppMotion.medium, curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    final weatherMode = context.watch<ExperimentalSettings>().weatherMode;
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: HomeMapBackdrop()),
          Listener(
            onPointerUp: (_) => _settle(),
            child: NotificationListener<DraggableScrollableNotification>(
              onNotification: _onExtentChanged,
              child: DraggableScrollableSheet(
                controller: _sheet,
                initialChildSize: HomeSheet.restExtent,
                minChildSize: HomeSheet.minExtent,
                maxChildSize: HomeSheet.maxExtent,
                builder: (context, scrollController) => HomeSheet(
                  scrollController: scrollController,
                  extent: _extent,
                  weatherMode: weatherMode,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
