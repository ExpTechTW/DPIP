import 'package:dpip/app/home/model.dart';
import 'package:flutter/material.dart';

class AndroidHomeView extends StatelessWidget {
  static NavigationDestination navigation = NavigationDestination(
    icon: const Icon(HomeViewModel.icon),
    selectedIcon: const Icon(
      HomeViewModel.icon,
      fill: 1,
    ),
    label: HomeViewModel.label,
  );

  const AndroidHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Text("home");
  }
}
