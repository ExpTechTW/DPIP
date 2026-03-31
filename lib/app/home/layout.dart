import 'package:dpip/app/home/_models/home_location.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeLayout extends StatelessWidget {
  final Widget child;

  const HomeLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ChangeNotifierProvider<HomeLocationModel>(
        create: (_) => HomeLocationModel(),
        child: child,
      ),
    );
  }
}
