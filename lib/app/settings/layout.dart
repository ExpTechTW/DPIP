import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SettingsLayout extends StatefulWidget {
  final Widget child;
  final String title;

  const SettingsLayout({super.key, required this.child, required this.title});

  @override
  State<SettingsLayout> createState() => _SettingsLayoutState();
}

class _SettingsLayoutState extends State<SettingsLayout> {
  final controller = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title), leading: BackButton(onPressed: () => context.pop()), centerTitle: true),
      body: widget.child,
    );
  }
}
