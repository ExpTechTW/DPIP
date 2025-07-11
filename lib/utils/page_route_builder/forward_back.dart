import 'package:flutter/material.dart';

class ForwardBackPageRouteBuilder extends PageRouteBuilder {
  final Widget page;

  ForwardBackPageRouteBuilder({required this.page})
    : super(pageBuilder: (context, animation, secondaryAnimation) => page);

  final backTransition = const Interval(0, 0.5, curve: Easing.emphasizedAccelerate);
  final forwardTransition = const Interval(0.5, 1, curve: Easing.emphasizedDecelerate);

  @override
  Duration get transitionDuration => Durations.long4;

  @override
  Duration get reverseTransitionDuration => Durations.long4;

  @override
  SlideTransition Function(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  )
  get transitionsBuilder => (context, animation, secondaryAnimation, child) {
    final slide = Tween(begin: const Offset(0.2, 0.0), end: Offset.zero).chain(CurveTween(curve: forwardTransition));

    final fade = Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: forwardTransition));

    return SlideTransition(
      position: animation.drive(slide),
      child: FadeTransition(opacity: animation.drive(fade), child: child),
    );
  };
}
