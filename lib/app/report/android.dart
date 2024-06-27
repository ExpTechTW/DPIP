import 'package:dpip/app/report/model.dart';
import 'package:flutter/material.dart';

class AndroidReportView extends StatelessWidget {
  static NavigationDestination navigation = NavigationDestination(
    icon: const Icon(ReportViewModel.icon),
    selectedIcon: const Icon(
      ReportViewModel.icon,
      fill: 1,
    ),
    label: ReportViewModel.label,
  );

  const AndroidReportView({super.key});

  @override
  Widget build(BuildContext context) {
    return Text("report");
  }
}
