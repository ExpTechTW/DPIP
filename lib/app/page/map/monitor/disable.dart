import 'package:dpip/util/extension/build_context.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class DisablePage extends StatelessWidget {
  const DisablePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Symbols.disabled_by_default_rounded,
              size: 150,
              color: Colors.grey,
            ),
            const SizedBox(height: 20),
            Text(
              '未啟用強震監視器',
              style: context.theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            Text(
              '請至設定進階功能中開啟強震監視器。',
              style: context.theme.textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}
