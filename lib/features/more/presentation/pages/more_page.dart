import 'package:dpip/features/log/presentation/pages/log_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// "More" menu (settings, about, …). Placeholder pending those features.
class MorePage extends StatelessWidget {
  const MorePage({super.key});

  /// Route path.
  static const String path = '/more';

  /// Route name.
  static const String name = 'more';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('更多')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.article_outlined),
            title: const Text('App 日誌'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.pushNamed(LogPage.name),
          ),
        ],
      ),
    );
  }
}
