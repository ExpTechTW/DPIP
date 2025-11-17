import 'package:dpip/utils/extensions/build_context.dart';
import 'package:flutter/material.dart';

class SheetContainer extends StatelessWidget {
  final IconData? icon;
  final String title;
  final String? description;
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
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        child: SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 16,
                  children: [
                    Row(
                      spacing: 8,
                      children: [
                        if (icon != null) Icon(icon, size: 28),
                        Text(title, style: context.texts.titleLarge),
                      ],
                    ),
                    if (description != null)
                      Text(
                        description!,
                        style: context.texts.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
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
