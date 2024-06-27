import 'package:dpip/app/home/model.dart';
import 'package:flutter/cupertino.dart';

class CupertinoHomeView extends StatelessWidget {
  static BottomNavigationBarItem navigation = BottomNavigationBarItem(
    icon: const Icon(HomeViewModel.icon),
    activeIcon: const Icon(
      HomeViewModel.icon,
      fill: 1,
    ),
    label: HomeViewModel.label,
  );

  const CupertinoHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Text("home");
  }
}
