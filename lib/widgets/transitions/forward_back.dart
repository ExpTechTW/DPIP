import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

const kBackTransition = Interval(0, 0.5, curve: Easing.emphasizedAccelerate);
const kForwardTransition = Interval(0.5, 1, curve: Easing.emphasizedDecelerate);

class ForwardBackTransitionPage extends CustomTransitionPage {
  ForwardBackTransitionPage({required super.child, super.key})
    : super(
        transitionDuration: Durations.long4,
        reverseTransitionDuration: Durations.long4,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final forwardSlide = Tween(
            begin: const Offset(0.2, 0.0),
            end: Offset.zero,
          ).chain(CurveTween(curve: kForwardTransition));

          final backwardSlide = Tween(
            begin: Offset.zero,
            end: const Offset(-0.2, 0.0),
          ).chain(CurveTween(curve: kBackTransition));

          final fadeIn = Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: kForwardTransition));
          final fadeOut = Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: kBackTransition));

          return SlideTransition(
            position: forwardSlide.animate(animation),
            child: SlideTransition(
              position: backwardSlide.animate(secondaryAnimation),
              child: FadeTransition(
                opacity: fadeIn.animate(animation),
                child: FadeTransition(opacity: fadeOut.animate(secondaryAnimation), child: Material(child: child)),
              ),
            ),
          );
        },
      );
}
