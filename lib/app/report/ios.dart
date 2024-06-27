import 'package:dpip/app/report/model.dart';
import 'package:flutter/cupertino.dart';

class CupertinoReportView extends StatelessWidget {
  static BottomNavigationBarItem navigation = BottomNavigationBarItem(
    icon: const Icon(ReportViewModel.icon),
    activeIcon: const Icon(
      ReportViewModel.icon,
      fill: 1,
    ),
    label: ReportViewModel.label,
  );

  const CupertinoReportView({super.key});

  @override
  Widget build(BuildContext context) {
    return Text("report");
  }
}
