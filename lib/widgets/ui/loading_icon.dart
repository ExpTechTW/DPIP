import 'package:flutter/material.dart';

class LoadingIcon extends StatelessWidget {
  const LoadingIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 18,
      width: 18,
      child: CircularProgressIndicator(strokeWidth: 2),
    );
  }
}
