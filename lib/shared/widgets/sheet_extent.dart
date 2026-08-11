/// Shared bottom-sheet plumbing: tracking a draggable sheet's live extent,
/// deciding when it is flush with the top, and the grab handle. Four sheets
/// (station / DPM / typhoon / report filter) used to each copy this.
library;

import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/shared/widgets/sheet_surface.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Whether a sheet [extent] (0…1) counts as flush with the top — the grip
/// hides and the panel merges with the status bar.
bool sheetExtentIsAtTop(double extent) => extent >= 1.0 - 0.02;

/// Forwards every [DraggableScrollableNotification] from [child] into [extent],
/// so the sheet's own widgets can listen to the live scroll position.
class SheetExtentListener extends StatelessWidget {
  const SheetExtentListener({
    super.key,
    required this.extent,
    required this.child,
  });

  /// The live sheet extent (0…1), written on every scroll notification.
  final ValueNotifier<double> extent;

  /// The scrollable whose extent to track (usually a
  /// [DraggableScrollableSheet]).
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      NotificationListener<DraggableScrollableNotification>(
        onNotification: (notification) {
          extent.value = notification.extent;
          return false;
        },
        child: child,
      );
}

/// The sheet's grab handle — hidden once the sheet is flush with the top.
/// Listens to [extent] itself, flipping via a post-frame callback so the hide
/// never dirties DSS layout mid-scroll.
class SheetGrip extends StatefulWidget {
  const SheetGrip({super.key, required this.extent});

  final ValueListenable<double> extent;

  @override
  State<SheetGrip> createState() => _SheetGripState();
}

class _SheetGripState extends State<SheetGrip> with SheetExtentFlag {
  @override
  ValueListenable<double> get sheetExtent => widget.extent;

  @override
  bool sheetFlagFrom(double extent) => !sheetExtentIsAtTop(extent);

  @override
  Widget build(BuildContext context) {
    if (!sheetFlag) return const SizedBox.shrink();
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: colors.onSurfaceVariant.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

/// The full chrome of a bottom draggable sheet: extent listener, key-remount
/// [DraggableScrollableSheet], status-bar fill, and frosted [SheetSurface].
///
/// The typhoon / station / DPM sheets all share this skeleton — only the
/// remount [keyValue] and the size constants differ. [content] builds the
/// scroll body (which must not rebuild on every drag pixel; the chrome's
/// `ValueListenableBuilder` keeps the extent-reactive restyle separate).
class ExtentSheetChrome extends StatelessWidget {
  const ExtentSheetChrome({
    super.key,
    required this.extent,
    required this.keyValue,
    required this.initial,
    required this.min,
    required this.max,
    required this.snapSizes,
    required this.content,
  });

  /// Live sheet fraction — drives the chrome restyles only.
  final ValueNotifier<double> extent;

  /// Remount key — changing it pops/collapses the sheet via a fresh
  /// [DraggableScrollableSheet] seeded at [initial].
  final Object? keyValue;

  final double initial;
  final double min;
  final double max;

  /// Snap detents; enables snapping when non-empty.
  final List<double> snapSizes;

  /// Builds the sheet body from the scroll controller — once per sheet mount.
  final Widget Function(BuildContext context, ScrollController controller)
  content;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return SheetExtentListener(
      extent: extent,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: DraggableScrollableSheet(
          key: ValueKey(keyValue),
          expand: false,
          initialChildSize: initial,
          minChildSize: min,
          maxChildSize: max,
          snap: snapSizes.isNotEmpty,
          snapSizes: snapSizes,
          builder: (context, scrollController) {
            final body = content(context, scrollController);
            return ValueListenableBuilder<double>(
              valueListenable: extent,
              child: body,
              builder: (context, value, body) {
                final atTop = sheetExtentIsAtTop(value);
                final topInset = MediaQuery.paddingOf(context).top;
                return AnnotatedRegion<SystemUiOverlayStyle>(
                  value: SystemUiOverlayStyle(
                    statusBarColor: atTop ? colors.surface : Colors.transparent,
                    statusBarIconBrightness: theme.brightness == Brightness.dark
                        ? Brightness.light
                        : Brightness.dark,
                    statusBarBrightness: theme.brightness,
                  ),
                  child: SheetSurface(
                    flushTop: atTop,
                    child: Padding(
                      padding: EdgeInsets.only(top: atTop ? topInset : 0),
                      child: body!,
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/// A State deriving a boolean from the live sheet extent, flipping it via a
/// post-frame callback — a same-frame flip mid-DSS-layout would otherwise dirty
/// parentData for semantics. Self-listening keeps a widget out of the extent's
/// `ListenableBuilder`, so it only rebuilds when the derived flag actually
/// changes, not on every drag pixel.
mixin SheetExtentFlag<T extends StatefulWidget> on State<T> {
  /// The live extent to listen to.
  ValueListenable<double> get sheetExtent;

  /// The flag value for [extent].
  bool sheetFlagFrom(double extent);

  /// The current derived flag.
  bool get sheetFlag => _sheetFlag;

  late bool _sheetFlag = sheetFlagFrom(sheetExtent.value);

  @override
  void initState() {
    super.initState();
    sheetExtent.addListener(_onSheetExtent);
  }

  @override
  void didUpdateWidget(covariant T oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-bind in case the parent swapped the listenable.
    sheetExtent.removeListener(_onSheetExtent);
    sheetExtent.addListener(_onSheetExtent);
    _onSheetExtent();
  }

  @override
  void dispose() {
    sheetExtent.removeListener(_onSheetExtent);
    super.dispose();
  }

  void _onSheetExtent() {
    final next = sheetFlagFrom(sheetExtent.value);
    if (next == _sheetFlag) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final current = sheetFlagFrom(sheetExtent.value);
      if (current != _sheetFlag) setState(() => _sheetFlag = current);
    });
  }
}
