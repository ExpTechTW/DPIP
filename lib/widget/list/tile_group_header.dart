import "package:dpip/util/extension/build_context.dart";
import "package:flutter/material.dart";

class ListTileGroupHeader extends StatelessWidget {
  final String title;

  const ListTileGroupHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        title,
        style: TextStyle(
          color: context.colors.primary,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
