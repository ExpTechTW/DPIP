import 'package:dpip/utils/extensions/build_context.dart';
import 'package:flutter/material.dart';

void showToast(BuildContext context, ToastWidget toast) {
  final snackBar = SnackBar(
    behavior: SnackBarBehavior.floating,
    backgroundColor: Colors.transparent,
    elevation: 0,
    duration: const Duration(seconds: 3),
    content: AnimatedFade(child: Center(child: toast)),
  );
  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}

class AnimatedFade extends StatefulWidget {
  final Widget child;
  const AnimatedFade({super.key, required this.child});

  @override
  State<AnimatedFade> createState() => AnimatedFadeState();
}

class AnimatedFadeState extends State<AnimatedFade>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
      vsync: this,
      duration: Durations.short4,
      reverseDuration: Durations.short4,
  )..forward();

  late final Animation<double> _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) _controller.reverse();
    });
  }

  @override
  Widget build(BuildContext context) => FadeTransition(opacity: _opacity, child: widget.child);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class ToastWidget extends StatelessWidget {
  final List<Widget> children;
  const ToastWidget({super.key, required this.children});

  factory ToastWidget.text(String text, {Key? key, Widget? icon}) {
    return ToastWidget(
      key: key,
      children: [
        if (icon != null) icon,
        if (icon != null) const SizedBox(width: 4),
        Flexible(
          child: Builder(
            builder: (context) => Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(9999),
        color: context.colors.surfaceContainer,
        border: Border.all(color: context.colors.outlineVariant),
        boxShadow: kElevationToShadow[8],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}
