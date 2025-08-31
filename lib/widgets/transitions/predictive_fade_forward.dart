import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PredictiveBackFadeForwardPageTransitionsBuilder extends PageTransitionsBuilder {
  /// Creates an instance of a [PageTransitionsBuilder] that matches Android U's
  /// predictive back transition.
  const PredictiveBackFadeForwardPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return _PredictiveBackGestureDetector(
      route: route,
      builder: (BuildContext context) {
        // Only do a predictive back transition when the user is performing a
        // pop gesture. Otherwise, for things like button presses or other
        // programmatic navigation, fall back to FadeForwardsPageTransitionsBuilder.
        if (route.popGestureInProgress) {
          return _PredictiveBackPageTransition(
            animation: animation,
            secondaryAnimation: secondaryAnimation,
            getIsCurrent: () => route.isCurrent,
            child: child,
          );
        }

        return const FadeForwardsPageTransitionsBuilder().buildTransitions(
          route,
          context,
          animation,
          secondaryAnimation,
          child,
        );
      },
    );
  }
}

class _PredictiveBackGestureDetector extends StatefulWidget {
  const _PredictiveBackGestureDetector({required this.route, required this.builder});

  final WidgetBuilder builder;
  final PredictiveBackRoute route;

  @override
  State<_PredictiveBackGestureDetector> createState() => _PredictiveBackGestureDetectorState();
}

class _PredictiveBackGestureDetectorState extends State<_PredictiveBackGestureDetector> with WidgetsBindingObserver {
  /// True when the predictive back gesture is enabled.
  bool get _isEnabled {
    return widget.route.isCurrent && widget.route.popGestureEnabled;
  }

  /// The back event when the gesture first started.
  PredictiveBackEvent? get startBackEvent => _startBackEvent;
  PredictiveBackEvent? _startBackEvent;
  set startBackEvent(PredictiveBackEvent? startBackEvent) {
    if (_startBackEvent != startBackEvent && mounted) {
      setState(() {
        _startBackEvent = startBackEvent;
      });
    }
  }

  /// The most recent back event during the gesture.
  PredictiveBackEvent? get currentBackEvent => _currentBackEvent;
  PredictiveBackEvent? _currentBackEvent;
  set currentBackEvent(PredictiveBackEvent? currentBackEvent) {
    if (_currentBackEvent != currentBackEvent && mounted) {
      setState(() {
        _currentBackEvent = currentBackEvent;
      });
    }
  }

  // Begin WidgetsBindingObserver.

  @override
  bool handleStartBackGesture(PredictiveBackEvent backEvent) {
    final bool gestureInProgress = !backEvent.isButtonEvent && _isEnabled;
    if (!gestureInProgress) {
      return false;
    }

    widget.route.handleStartBackGesture(progress: 1 - backEvent.progress);
    startBackEvent = currentBackEvent = backEvent;
    return true;
  }

  @override
  void handleUpdateBackGestureProgress(PredictiveBackEvent backEvent) {
    widget.route.handleUpdateBackGestureProgress(progress: 1 - backEvent.progress);
    currentBackEvent = backEvent;
  }

  @override
  void handleCancelBackGesture() {
    widget.route.handleCancelBackGesture();
    startBackEvent = currentBackEvent = null;
  }

  @override
  void handleCommitBackGesture() {
    widget.route.handleCommitBackGesture();
    startBackEvent = currentBackEvent = null;
  }

  // End WidgetsBindingObserver.

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context);
  }
}

/// Android's predictive back page transition.
class _PredictiveBackPageTransition extends StatelessWidget {
  const _PredictiveBackPageTransition({
    required this.animation,
    required this.secondaryAnimation,
    required this.getIsCurrent,
    required this.child,
  });

  // These values were eyeballed to match the native predictive back animation
  // on a Pixel 2 running Android API 34.
  static const double _scaleFullyOpened = 1.0;
  static const double _scaleStartTransition = 0.95;
  static const double _opacityFullyOpened = 1.0;
  static const double _opacityStartTransition = 0.95;
  static const double _weightForStartState = 65.0;
  static const double _weightForEndState = 35.0;
  static const double _screenWidthDivisionFactor = 20.0;
  static const double _xShiftAdjustment = 8.0;

  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final ValueGetter<bool> getIsCurrent;
  final Widget child;

  Widget _secondaryAnimatedBuilder(BuildContext context, Widget? child) {
    final double screenWidth = MediaQuery.widthOf(context);
    final double xShift = (screenWidth / _screenWidthDivisionFactor) - _xShiftAdjustment;

    final bool isCurrent = getIsCurrent();
    final Tween<double> xShiftTween = isCurrent ? ConstantTween<double>(0) : Tween<double>(begin: xShift, end: 0);
    final Animatable<double> scaleTween =
        isCurrent
            ? ConstantTween<double>(_scaleFullyOpened)
            : TweenSequence<double>(<TweenSequenceItem<double>>[
              TweenSequenceItem<double>(
                tween: Tween<double>(begin: _scaleStartTransition, end: _scaleFullyOpened),
                weight: _weightForStartState,
              ),
              TweenSequenceItem<double>(
                tween: Tween<double>(begin: _scaleFullyOpened, end: _scaleFullyOpened),
                weight: _weightForEndState,
              ),
            ]);
    final Animatable<double> fadeTween =
        isCurrent
            ? ConstantTween<double>(_opacityFullyOpened)
            : TweenSequence<double>(<TweenSequenceItem<double>>[
              TweenSequenceItem<double>(
                tween: Tween<double>(begin: _opacityFullyOpened, end: _opacityStartTransition),
                weight: _weightForStartState,
              ),
              TweenSequenceItem<double>(
                tween: Tween<double>(begin: _opacityFullyOpened, end: _opacityFullyOpened),
                weight: _weightForEndState,
              ),
            ]);

    return Transform.translate(
      offset: Offset(xShiftTween.animate(secondaryAnimation).value, 0),
      child: Transform.scale(
        scale: scaleTween.animate(secondaryAnimation).value,
        child: Opacity(opacity: fadeTween.animate(secondaryAnimation).value, child: child),
      ),
    );
  }

  Widget _primaryAnimatedBuilder(BuildContext context, Widget? child) {
    final double screenWidth = MediaQuery.widthOf(context);
    final double xShift = (screenWidth / _screenWidthDivisionFactor) - _xShiftAdjustment;

    final Animatable<double> xShiftTween = TweenSequence<double>(<TweenSequenceItem<double>>[
      TweenSequenceItem<double>(tween: Tween<double>(begin: 0.0, end: 0.0), weight: _weightForStartState),
      TweenSequenceItem<double>(tween: Tween<double>(begin: xShift, end: 0.0), weight: _weightForEndState),
    ]);
    final Animatable<double> scaleTween = TweenSequence<double>(<TweenSequenceItem<double>>[
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: _scaleFullyOpened, end: _scaleFullyOpened),
        weight: _weightForStartState,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: _scaleStartTransition, end: _scaleFullyOpened),
        weight: _weightForEndState,
      ),
    ]);
    final Animatable<double> fadeTween = TweenSequence<double>(<TweenSequenceItem<double>>[
      TweenSequenceItem<double>(tween: Tween<double>(begin: 0.0, end: 0.0), weight: _weightForStartState),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: _opacityStartTransition, end: _opacityFullyOpened),
        weight: _weightForEndState,
      ),
    ]);

    return Transform.translate(
      offset: Offset(xShiftTween.animate(animation).value, 0),
      child: Transform.scale(
        scale: scaleTween.animate(animation).value,
        child: Opacity(opacity: fadeTween.animate(animation).value, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: secondaryAnimation,
      builder: _secondaryAnimatedBuilder,
      child: AnimatedBuilder(animation: animation, builder: _primaryAnimatedBuilder, child: child),
    );
  }
}
