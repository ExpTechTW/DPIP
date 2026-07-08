/// Base class for all map layer managers used in the DPIP map feature.
library;

import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

/// Manages the lifecycle and visibility of a single map overlay layer.
///
/// Subclasses implement [setup], [show], [hide], and [remove] to control
/// their respective MapLibre layers. Call [build] to obtain any associated
/// overlay UI (e.g. bottom sheets and legends).
abstract class MapLayerManager {
  /// The [BuildContext] used for reading providers and theme data.
  final BuildContext context;

  /// The MapLibre controller used to add, show, hide, and remove layers.
  final MapLibreMapController controller;

  /// Whether [setup] has been called and completed successfully.
  bool didSetup = false;

  bool _disposed = false;

  /// Whether [dispose] has been called.
  ///
  /// Once disposed, the underlying platform map view may already be torn down.
  /// Calling `controller` methods (e.g. `addSource`, `addLayer`) after this
  /// point throws an uncaught native exception on iOS and crashes the app, so
  /// every `await controller.…` in an async method must re-check this flag
  /// after the await and bail out early if `true`.
  bool get isDisposed => _disposed;

  /// Whether this layer is currently visible on the map.
  bool visible = false;

  /// Whether the page is allowed to pop when the back button is pressed.
  ///
  /// Return `false` to intercept the pop and handle it via [onPopInvoked].
  bool get shouldPop => true;

  /// Creates a manager bound to the given [context] and [controller].
  MapLayerManager(this.context, this.controller);

  /// Initialises map sources and layers, then sets [didSetup] to `true`.
  Future<void> setup();

  /// Called on every tick of the page timer. Override to refresh layer data.
  void tick() {}

  /// Hides this layer without removing its underlying sources.
  Future<void> hide();

  /// Makes this layer visible.
  Future<void> show();

  /// Completely removes this layer and its sources from the map.
  Future<void> remove();

  /// Releases any resources held by this manager.
  ///
  /// Subclasses overriding this **must** call `super.dispose()` so that
  /// [isDisposed] is set and in-flight controller calls short-circuit.
  @mustCallSuper
  void dispose() {
    _disposed = true;
  }

  /// Called when the user triggers a back-navigation and [shouldPop] is
  /// `false`. Override to handle custom pop behaviour (e.g. deselecting an
  /// item).
  void onPopInvoked() {}

  /// Builds the overlay UI associated with this layer.
  ///
  /// Returns an empty [SizedBox] by default.
  Widget build(BuildContext context) => const SizedBox.shrink();
}
