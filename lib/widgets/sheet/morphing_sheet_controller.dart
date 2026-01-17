import 'package:flutter/material.dart';

/// A controller for [MorphingSheet] that allows controlling the sheet's state
/// and animation from outside the widget.
class MorphingSheetController {
  /// The controller for the draggable scrollable sheet
  DraggableScrollableController? _draggableController;

  /// The controller for the morph animation
  AnimationController? _morphController;

  /// Whether the sheet is currently snapping to a position
  bool _isSnapping = false;

  /// The minimum size of the sheet
  double? _minChildSize;

  /// The maximum size of the sheet
  double? _maxChildSize;

  /// The duration for enter animations (expanding)
  static const enterDuration = Duration(milliseconds: 400);

  /// The duration for exit animations (collapsing)
  static const exitDuration = Duration(milliseconds: 200);

  /// Attaches the controller to a [MorphingSheet]
  void attach({
    required DraggableScrollableController draggableController,
    required AnimationController morphController,
    required double minChildSize,
    required double maxChildSize,
  }) {
    _draggableController = draggableController;
    _morphController = morphController;
    _minChildSize = minChildSize;
    _maxChildSize = maxChildSize;
  }

  /// Detaches the controller from its [MorphingSheet]
  void detach() {
    _draggableController = null;
    _morphController = null;
    _minChildSize = null;
    _maxChildSize = null;
    _isSnapping = false;
  }

  /// Returns true if the controller is attached to a [MorphingSheet]
  bool get isAttached => _draggableController != null;

  /// Returns the current size of the sheet, between [minChildSize] and [maxChildSize]
  double get size => _draggableController?.size ?? _minChildSize ?? 0.0;

  /// Returns the current morph value, between 0.0 and 1.0
  double get morphValue => _morphController?.value ?? 0.0;

  /// Returns true if the sheet is currently expanded to its maximum size
  bool get isExpanded => size >= (_maxChildSize ?? 1.0);

  /// Returns true if the sheet is currently at its minimum size
  bool get isCollapsed => size <= (_minChildSize ?? 0.0);

  /// Expands the sheet to its maximum size with an animation
  Future<void> expand() async {
    if (!isAttached || _isSnapping) return;
    await snapToSize(_maxChildSize!);
  }

  /// Collapses the sheet to its minimum size with an animation
  Future<void> collapse() async {
    if (!isAttached || _isSnapping) return;
    await snapToSize(_minChildSize!);
  }

  /// Snaps the sheet to a specific size with an animation
  Future<void> snapToSize(double targetSize) async {
    if (!isAttached || _isSnapping) return;
    _isSnapping = true;

    try {
      final isExpanding = targetSize > size;
      final curve = isExpanding
          ? Easing.emphasizedDecelerate
          : Easing.emphasizedAccelerate;
      final duration = isExpanding ? enterDuration : exitDuration;

      await _draggableController!.animateTo(
        targetSize,
        duration: duration,
        curve: curve,
      );
    } finally {
      _isSnapping = false;
    }
  }

  /// Disposes the controller
  void dispose() {
    detach();
  }
}
