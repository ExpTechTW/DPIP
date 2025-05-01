import 'package:flutter/material.dart';

import 'package:flutter_markdown/flutter_markdown.dart';

import 'package:dpip/api/exptech.dart';
import 'package:dpip/utils/extensions/build_context.dart';

class SupportStatus {
  static Map<String, dynamic> supportList = {};

  static bool isVersionSupported(String version) {
    return supportList["support-version"]?.contains(version) ?? false;
  }

  static Color getSupportTypeColor(bool value) {
    return value ? Colors.green : Colors.grey;
  }

  static String getSupportLocalizedType(bool value) {
    return value ? '提供服務' : '終止服務';
  }
}

class VersionType {
  static Color getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'alpha':
        return Colors.red;
      case 'beta':
        return Colors.orangeAccent;
      default:
        return Colors.green;
    }
  }

  static String getLocalizedType(String type) {
    switch (type.toLowerCase()) {
      case 'alpha':
        return '內測版';
      case 'beta':
        return '公測版';
      default:
        return '正式版';
    }
  }
}

class SupportStatusChip extends StatelessWidget {
  final bool isSupported;

  const SupportStatusChip({super.key, required this.isSupported});

  @override
  Widget build(BuildContext context) {
    return Chip(
      padding: const EdgeInsets.all(0),
      side: BorderSide(color: SupportStatus.getSupportTypeColor(isSupported)),
      backgroundColor: SupportStatus.getSupportTypeColor(isSupported).withValues(alpha: 0.16),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      label: Text(
        SupportStatus.getSupportLocalizedType(isSupported),
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class VersionTypeChip extends StatelessWidget {
  final String type;

  const VersionTypeChip({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    return Chip(
      padding: const EdgeInsets.all(0),
      side: BorderSide(color: VersionType.getTypeColor(type)),
      backgroundColor: VersionType.getTypeColor(type).withValues(alpha: 0.16),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      label: Text(
        VersionType.getLocalizedType(type),
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class ChangelogEntry {
  final String version;
  final String type;
  final String content;

  ChangelogEntry({required this.version, required this.type, required this.content});

  factory ChangelogEntry.fromJson(Map<String, dynamic> json) {
    return ChangelogEntry(version: json['ver'], type: json['type'], content: json['content']);
  }
}

class ChangelogPage extends StatefulWidget {
  const ChangelogPage({super.key});

  static const route = '/changelog';

  @override
  State<ChangelogPage> createState() => _ChangelogPageState();
}

class _ChangelogPageState extends State<ChangelogPage> {
  List<ChangelogEntry> _changelogEntries = [];
  bool _isLoading = true;
  String? _errorMessage;
  final refreshIndicator = GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    refreshIndicator.currentState?.show();
    _fetchChangelog();
  }

  Future<void> _fetchChangelog() async {
    try {
      final List<dynamic> data = (await ExpTech().getChangelog()).reversed.toList();
      SupportStatus.supportList = await ExpTech().getSupport();
      setState(() {
        _changelogEntries = data.map((json) => ChangelogEntry.fromJson(json)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = context.i18n.unable_to_load_changelog;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.i18n.update_log), elevation: 0),
      body: RefreshIndicator(
        key: refreshIndicator,
        onRefresh: _fetchChangelog,
        child: ListView.builder(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + context.padding.bottom),
          itemCount: _changelogEntries.length,
          itemBuilder: (context, index) {
            return ChangelogCard(
              entry: _changelogEntries[index],
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ChangelogDetailPage(entry: _changelogEntries[index])),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class ChangelogCard extends StatelessWidget {
  final ChangelogEntry entry;
  final VoidCallback onTap;

  const ChangelogCard({super.key, required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isSupported = SupportStatus.isVersionSupported(entry.version);

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SupportStatusChip(isSupported: isSupported),
              const SizedBox(width: 8),
              VersionTypeChip(type: entry.type),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'v${entry.version}',
                  style: context.theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: context.theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChangelogDetailPage extends StatelessWidget {
  final ChangelogEntry entry;

  const ChangelogDetailPage({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final isSupported = SupportStatus.isVersionSupported(entry.version);

    return Scaffold(
      appBar: AppBar(title: Text(context.i18n.version_details), elevation: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'v${entry.version} ${VersionType.getLocalizedType(entry.type)}',
                style: context.theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  SupportStatusChip(isSupported: isSupported),
                  const SizedBox(width: 8),
                  VersionTypeChip(type: entry.type),
                ],
              ),
              const SizedBox(height: 24),
              MarkdownBody(
                data: entry.content,
                styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                  h1: context.theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                  h2: context.theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  h3: context.theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  p: context.theme.textTheme.bodyLarge,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
