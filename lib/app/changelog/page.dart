import 'package:dpip/api/exptech.dart';
import 'package:dpip/api/model/changelog/changelog.dart';
import 'package:dpip/core/i18n.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/utils/log.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

class ChangelogPage extends StatefulWidget {
  const ChangelogPage({super.key});

  static const route = '/changelog';

  @override
  State<ChangelogPage> createState() => _ChangelogPageState();
}

class _ChangelogPageState extends State<ChangelogPage> {
  bool _isLoading = false;
  List<GithubRelease>? _releases;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final v = await ExpTech().getReleases();
      if (!mounted) return;

      setState(() => _releases = v);
    } catch (e, s) {
      if (!mounted) return;

      TalkerManager.instance.error('_ChangelogPageState._refresh', e, s);
      context.scaffoldMessenger.showSnackBar(SnackBar(content: Text('無法載入更新日誌，請稍後再試。'.i18n)));
    }

    if (!mounted) return;

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('更新日誌'.i18n), elevation: 0),
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AnimatedOpacity(
              opacity: _isLoading ? 1 : 0,
              duration: Durations.short4,
              child: const LinearProgressIndicator(),
            ),
          ),
          if (_releases != null)
            ListView.builder(
              padding: EdgeInsets.fromLTRB(24, 16, 24, 16 + context.padding.bottom),
              itemCount: _releases!.length,
              itemBuilder: (context, index) {
                final release = _releases![index];

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 8,
                  children: [
                    if (index > 0) const Divider(height: 32, indent: 8, endIndent: 8),
                    Row(
                      spacing: 8,
                      children: [
                        Text(release.name, style: context.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                        if (release.prerelease)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.orangeAccent),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Pre-Release',
                              style: context.textTheme.labelSmall?.copyWith(color: Colors.orangeAccent),
                            ),
                          ),
                      ],
                    ),
                    MarkdownBody(data: release.body),
                  ],
                );
              },
            )
          else if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            Center(
              child: Column(
                children: [
                  Text('無法載入更新日誌，請稍後再試。'.i18n),
                  FilledButton.tonalIcon(
                    onPressed: _refresh,
                    icon: const Icon(Symbols.refresh_rounded),
                    label: Text('重試'.i18n),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
