import 'package:flutter/material.dart';

class NavigationLocation extends NavigationDrawerDestination {
  NavigationLocation({
    super.key,
    required Icon super.icon,
    required super.label,
  }) : super(selectedIcon: Icon(icon.icon, fill: 1));
}

class AppLayout extends StatelessWidget {
  final Widget child;

  const AppLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
    );
  }
}
