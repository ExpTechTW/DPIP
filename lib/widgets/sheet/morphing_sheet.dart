import 'dart:ui';

import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/widgets/sheet/morphing_sheet_controller.dart';
import 'package:flutter/material.dart';

typedef MorphingSheetBuilder =
    Widget Function(BuildContext context, ScrollController controller, MorphingSheetController sheetController);

class MorphingSheet extends StatefulWidget {
  final MorphingSheetBuilder? fullBuilder;
  final MorphingSheetBuilder partialBuilder;
  final double maxChildSize;
  final double fullThreshold;
  final Color? backgroundColor;
  final Color? borderColor;
  final BorderRadius? borderRadius;
  final double? borderWidth;
  final EdgeInsets floatingPadding;
  final double elevation;
  final String? title;
  final bool showBackButton;
  final MorphingSheetController? controller;

  const MorphingSheet({
    super.key,
    this.fullBuilder,
    required this.partialBuilder,
    this.maxChildSize = 1.0,
    this.fullThreshold = 0.8,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius,
    this.borderWidth,
    this.floatingPadding = const EdgeInsets.symmetric(horizontal: 16.0),
    this.elevation = 8.0,
    this.title,
    this.showBackButton = true,
    this.controller,
  });

  @override
  State<MorphingSheet> createState() => _MorphingSheetState();
}

class _MorphingSheetState extends State<MorphingSheet> with SingleTickerProviderStateMixin {
  late DraggableScrollableController _controller;
  late AnimationController _morphController;
  bool _isSnapping = false;
  final GlobalKey _contentKey = GlobalKey();
  final GlobalKey _partialKey = GlobalKey();
  bool _isOverflowing = false;
  Size? _partialSize;

  static const double _verticalPadding = 8.0;
  static const double _bottomMargin = 16.0;
  static const double _minHeightRatio = 0.15;
  static const double _maxHeightRatio = 0.3;

  @override
  void initState() {
    super.initState();
    _controller = DraggableScrollableController();
    _morphController = AnimationController(
      vsync: this,
      duration: MorphingSheetController.enterDuration,
      reverseDuration: MorphingSheetController.exitDuration,
    );

    _controller.addListener(_onSheetPositionChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measureSizes();
      _attachController();
    });
  }

  @override
  void didUpdateWidget(MorphingSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _detachController(oldWidget.controller);
      _attachController();
    }
  }

  void _attachController() {
    if (widget.controller != null) {
      widget.controller!.attach(
        draggableController: _controller,
        morphController: _morphController,
        minChildSize: _minChildSize,
        maxChildSize: widget.maxChildSize,
      );
    }
  }

  void _detachController(MorphingSheetController? oldController) {
    if (oldController != null) {
      oldController.detach();
    }
  }

  void _measureSizes() {
    final RenderBox? contentBox = _contentKey.currentContext?.findRenderObject() as RenderBox?;
    final RenderBox? partialBox = _partialKey.currentContext?.findRenderObject() as RenderBox?;

    if (contentBox != null) {
      final screenHeight = context.screen.height;
      final isOverflowing = contentBox.size.height > screenHeight * 0.85;
      if (_isOverflowing != isOverflowing) {
        setState(() {
          _isOverflowing = isOverflowing;
        });
      }
    }

    if (partialBox != null) {
      final newSize = partialBox.size;
      if (_partialSize != newSize) {
        setState(() {
          _partialSize = newSize;
        });
      }
    }
  }

  double get _minChildSize {
    if (_partialSize == null) return _minHeightRatio;
    final screenHeight = context.screen.height;

    // Calculate total height including all padding and margin
    final totalHeight =
        _partialSize!.height + // Content height
        (_verticalPadding * 2) + // Top and bottom padding
        _bottomMargin + // Bottom margin
        context.padding.bottom + // Bottom padding
        widget.floatingPadding.vertical; // Floating padding

    // Ensure the height ratio is within bounds and responsive to content
    final calculatedRatio = totalHeight / screenHeight;

    // If the content is taller than the min ratio, use the content height
    if (calculatedRatio > _minHeightRatio) {
      return calculatedRatio.clamp(_minHeightRatio, _maxHeightRatio);
    }
    return _minHeightRatio;
  }

  void _onSheetPositionChanged() {
    if (_isSnapping) return;

    final position = _controller.size;
    final morphValue = (position - _minChildSize) / (widget.maxChildSize - _minChildSize);
    _morphController.value = morphValue.clamp(0.0, 1.0);
  }

  Future<void> _snapToPosition(double targetPosition) async {
    if (_isSnapping) return;
    _isSnapping = true;

    try {
      final isExpanding = targetPosition > _controller.size;
      final curve = isExpanding ? Easing.emphasizedDecelerate : Easing.emphasizedAccelerate;
      final duration = isExpanding ? MorphingSheetController.enterDuration : MorphingSheetController.exitDuration;

      await _controller.animateTo(targetPosition, duration: duration, curve: curve);
    } finally {
      _isSnapping = false;
    }
  }

  void _onDragEnd(double position) {
    if (position >= widget.fullThreshold) {
      _snapToPosition(widget.maxChildSize);
    } else {
      _snapToPosition(_minChildSize);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.fullBuilder == null) {
      final borderRadius = widget.borderRadius?.topLeft.y ?? 16.0;

      return Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: EdgeInsets.only(
            left: widget.floatingPadding.horizontal,
            right: widget.floatingPadding.horizontal,
            bottom: _verticalPadding,
          ),
          child: Container(
            margin: EdgeInsets.only(bottom: _bottomMargin + context.padding.bottom),
            child: PhysicalModel(
              color: Colors.transparent,
              elevation: widget.elevation,
              shadowColor: context.colors.shadow.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(borderRadius),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(borderRadius),
                  border: Border.all(
                    width: widget.borderWidth ?? 1,
                    color: widget.borderColor ?? context.colors.outline.withValues(alpha: 0.2),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(borderRadius),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Material(
                      color: (widget.backgroundColor ?? context.colors.surface).withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(borderRadius),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        children: [
                          // 漸層
                          if (_morphController.value < 1.0)
                            Positioned.fill(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      context.colors.surfaceTint.withValues(alpha: 0.04),
                                      context.colors.surfaceTint.withValues(alpha: 0.12),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              return SingleChildScrollView(
                                physics: const NeverScrollableScrollPhysics(),
                                child: SizedBox(
                                  key: _partialKey,
                                  width: constraints.maxWidth,
                                  child: widget.partialBuilder(
                                    context,
                                    ScrollController(),
                                    widget.controller ?? MorphingSheetController(),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return NotificationListener<SizeChangedLayoutNotification>(
      onNotification: (_) {
        _measureSizes();
        return true;
      },
      child: SizeChangedLayoutNotifier(
        child: DraggableScrollableSheet(
          initialChildSize: _minChildSize,
          minChildSize: _minChildSize,
          maxChildSize: widget.maxChildSize,
          controller: _controller,
          snap: true,
          snapSizes: [_minChildSize, widget.maxChildSize],
          builder: (context, scrollController) {
            return GestureDetector(
              onVerticalDragStart: (_) {},
              onVerticalDragEnd: (_) => _onDragEnd(_controller.size),
              child: AnimatedBuilder(
                animation: _morphController,
                builder: (context, child) {
                  final horizontalPadding = Tween<double>(
                    begin: widget.floatingPadding.horizontal,
                    end: 0.0,
                  ).transform(_morphController.value);

                  final bottomPadding = Tween<double>(
                    begin: _verticalPadding,
                    end: 0.0,
                  ).transform(_morphController.value);

                  final isFullScreen = _morphController.value == 1.0 && _controller.size == widget.maxChildSize;

                  final borderRadius =
                      !isFullScreen
                          ? Tween<double>(
                            begin: widget.borderRadius?.topLeft.y ?? 16.0,
                            end: _isOverflowing ? 0.0 : (widget.borderRadius?.topLeft.y ?? 16.0),
                          ).transform(_morphController.value)
                          : 0.0;

                  final elevation = Tween<double>(
                    begin: widget.elevation,
                    end: _isOverflowing ? 0.0 : widget.elevation,
                  ).transform(_morphController.value);

                  final marginBottom = Tween<double>(
                    begin: _bottomMargin + context.padding.bottom,
                    end: 0.0,
                  ).transform(_morphController.value);

                  return Padding(
                    padding: EdgeInsets.only(left: horizontalPadding, right: horizontalPadding, bottom: bottomPadding),
                    child: Container(
                      margin: EdgeInsets.only(bottom: marginBottom),
                      child: PhysicalModel(
                        color: Colors.transparent,
                        elevation: elevation,
                        shadowColor: context.colors.shadow.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(borderRadius),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(borderRadius),
                            border: Border.all(
                              color: context.colors.outline.withValues(
                                alpha: Tween<double>(begin: 0.2, end: 0.0).transform(_morphController.value),
                              ),
                              width: Tween<double>(begin: 1.0, end: 0.0).transform(_morphController.value),
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(borderRadius),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(
                                sigmaX: Tween<double>(begin: 16, end: 0).transform(_morphController.value),
                                sigmaY: Tween<double>(begin: 16, end: 0).transform(_morphController.value),
                              ),
                              child: Material(
                                color: (widget.backgroundColor ?? context.colors.surface).withValues(
                                  alpha: Tween<double>(begin: 0.6, end: 1.0).transform(_morphController.value),
                                ),
                                borderRadius: BorderRadius.circular(borderRadius),
                                clipBehavior: Clip.antiAlias,
                                child: Stack(
                                  children: [
                                    // 漸層
                                    if (_morphController.value < 1.0)
                                      Positioned.fill(
                                        child: Opacity(
                                          opacity: 1.0 - _morphController.value,
                                          child: DecoratedBox(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                                colors: [
                                                  context.colors.surfaceTint.withValues(alpha: 0.04),
                                                  context.colors.surfaceTint.withValues(alpha: 0.12),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    Stack(
                                      children: [
                                        Opacity(
                                          opacity: 1 - _morphController.value,
                                          child: LayoutBuilder(
                                            builder: (context, constraints) {
                                              return SingleChildScrollView(
                                                physics: const NeverScrollableScrollPhysics(),
                                                padding: EdgeInsets.zero,
                                                child: SizedBox(
                                                  key: _partialKey,
                                                  width: constraints.maxWidth,
                                                  child: widget.partialBuilder(
                                                    context,
                                                    scrollController,
                                                    widget.controller ?? MorphingSheetController(),
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                        Opacity(
                                          opacity: _morphController.value,
                                          child: _buildFullContent(scrollController),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFullContent(ScrollController scrollController) {
    final content = widget.fullBuilder!(context, scrollController, widget.controller ?? MorphingSheetController());

    if (!_isOverflowing) {
      return Container(key: _contentKey, child: content);
    }

    return Material(color: Colors.transparent, child: content);
  }

  @override
  void dispose() {
    _detachController(widget.controller);
    _controller.dispose();
    _morphController.dispose();
    super.dispose();
  }
}
