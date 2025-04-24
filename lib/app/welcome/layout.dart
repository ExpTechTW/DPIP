import 'package:flutter/material.dart';

class WelcomeLayout extends StatelessWidget {
  final Widget child;

  const WelcomeLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: child);
  }
}
