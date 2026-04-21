/// 時間頁面
library;

import 'package:flutter/material.dart';

class TimeLayout extends StatelessWidget {
  final Widget child;

  const TimeLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: child);
  }
}
