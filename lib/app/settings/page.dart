import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

class SettingsIndexPage extends StatelessWidget {
  const SettingsIndexPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: context.findAncestorStateOfType<NestedScrollViewState>()?.innerController,
      children: [
        ListTile(
          leading: Icon(Symbols.brush_rounded),
          title: Text('Theme', style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('Adjust how the app looks'),
          onTap: () {
            context.push('/settings/theme');
          },
        ),
      ],
    );
  }
}
