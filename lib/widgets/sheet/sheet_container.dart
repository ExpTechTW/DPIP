import 'package:dpip/utils/extensions/build_context.dart';
import 'package:flutter/material.dart';

class SheetContainer extends StatelessWidget {
  final IconData? icon;
  final Widget title;
  final Widget? description;
  final Widget child;
  final ScrollController? scrollController;
  final Color? color;

  const SheetContainer({
    super.key,
    required this.child,
    required this.title,
    this.description,
    this.icon,
    this.scrollController,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Material(
        color: color ?? Colors.transparent,
        borderRadius: const .vertical(top: .circular(16)),
        child: SingleChildScrollView(
          controller: scrollController,
          padding: const .symmetric(horizontal: 20, vertical: 8),
          child: Column(
            mainAxisSize: .min,
            crossAxisAlignment: .start,
            spacing: 8,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
                child: Column(
                  crossAxisAlignment: .start,
                  spacing: 16,
                  children: [
                    Row(
                      spacing: 8,
                      children: [
                        if (icon != null) Icon(icon, size: 28),
                        DefaultTextStyle(
                          style: context.texts.titleLarge!,
                          child: title,
                        ),
                      ],
                    ),
                    if (description != null)
                      DefaultTextStyle(
                        child: description!,
                        style: context.texts.bodyMedium!.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
