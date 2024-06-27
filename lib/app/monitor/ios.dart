import 'package:dpip/app/monitor/model.dart';
import 'package:flutter/cupertino.dart';

class CupertinoMonitorView extends StatelessWidget {
  static BottomNavigationBarItem navigation = BottomNavigationBarItem(
    icon: const Icon(MonitorViewModel.icon),
    activeIcon: const Icon(
      MonitorViewModel.icon,
      fill: 1,
    ),
    label: MonitorViewModel.label,
  );

  const CupertinoMonitorView({super.key});

  @override
  Widget build(BuildContext context) {
    return Text("monitor");
  }
}
