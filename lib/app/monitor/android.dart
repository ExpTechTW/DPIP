import 'package:dpip/app/monitor/model.dart';
import 'package:flutter/material.dart';

class AndroidMonitorView extends StatelessWidget {
  static NavigationDestination navigation = NavigationDestination(
    icon: const Icon(MonitorViewModel.icon),
    selectedIcon: const Icon(
      MonitorViewModel.icon,
      fill: 1,
    ),
    label: MonitorViewModel.label,
  );

  const AndroidMonitorView({super.key});

  @override
  Widget build(BuildContext context) {
    return Text("monitor");
  }
}
