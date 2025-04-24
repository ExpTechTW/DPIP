import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final kBackTransition = const Interval(0, 0.5, curve: Easing.emphasizedAccelerate);
final kForwardTransition = const Interval(0.5, 1, curve: Easing.emphasizedDecelerate);

class ForwardBackTransitionPage extends CustomTransitionPage {
  ForwardBackTransitionPage({required super.child, super.key})
    : super(
        transitionDuration: Durations.long4,
        reverseTransitionDuration: Durations.long4,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          var slide = Tween(
            begin: const Offset(0.2, 0.0),
            end: Offset.zero,
          ).chain(CurveTween(curve: kForwardTransition));

          var fade = Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: kForwardTransition));

          return SlideTransition(
            position: animation.drive(slide),
            child: FadeTransition(opacity: animation.drive(fade), child: child),
          );
        },
      );
}

class BackTransitionPage extends CustomTransitionPage {
  BackTransitionPage({required super.child, super.key})
    : super(
        transitionDuration: Durations.long4,
        reverseTransitionDuration: Durations.long4,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          var slide = Tween(begin: Offset.zero, end: const Offset(-0.2, 0.0)).chain(CurveTween(curve: kBackTransition));

          var fade = Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: kForwardTransition));

          return SlideTransition(
            position: secondaryAnimation.drive(slide),
            child: FadeTransition(opacity: secondaryAnimation.drive(fade), child: child),
          );
        },
      );
}
