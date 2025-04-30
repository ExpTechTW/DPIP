import 'package:flutter/material.dart';

import 'package:flutter_markdown/flutter_markdown.dart';

import 'package:dpip/api/exptech.dart';
import 'package:dpip/utils/extensions/build_context.dart';

Map<String, dynamic> supportList = {};

class ChangelogEntry {
  final String version;
  final String type;
  final String content;

  ChangelogEntry({required this.version, required this.type, required this.content});

  factory ChangelogEntry.fromJson(Map<String, dynamic> json) {
    return ChangelogEntry(version: json['ver'], type: json['type'], content: json['content']);
  }
}

Color _getSupportTypeColor(bool value) {
  if (value) return Colors.green;
  return Colors.grey;
}

String _getSupportLocalizedType(bool value) {
  if (value) return '提供服務';
  return '終止服務';
}

Color _getTypeColor(String type) {
  switch (type.toLowerCase()) {
    case 'alpha':
      return Colors.red;
    case 'beta':
      return Colors.orangeAccent;
    default:
      return Colors.green;
  }
}

String _getLocalizedType(String type) {
  switch (type.toLowerCase()) {
    case 'alpha':
      return '內測版';
    case 'beta':
      return '公測版';
    default:
      return '正式版';
  }
}

Widget _buildTypeChip(BuildContext context, ChangelogEntry entry) {
  return Chip(
    padding: const EdgeInsets.all(0),
    side: BorderSide(color: _getTypeColor(entry.type)),
    backgroundColor: _getTypeColor(entry.type).withOpacity(0.16),
    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    label: Text(_getLocalizedType(entry.type), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
  );
}

class ChangelogPage extends StatefulWidget {
  const ChangelogPage({Key? key}) : super(key: key);

  @override
  _ChangelogPageState createState() => _ChangelogPageState();
}

class _ChangelogPageState extends State<ChangelogPage> {
  List<ChangelogEntry> _changelogEntries = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchChangelog();
  }

  Future<void> _fetchChangelog() async {
    try {
      final List<dynamic> data = (await ExpTech().getChangelog()).reversed.toList();
      supportList = await ExpTech().getSupport();
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [const SizedBox(height: 16), Expanded(child: _buildChangelogList())],
          ),
        ),
      ),
    );
  }

  Widget _buildChangelogList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!));
    }
    if (_changelogEntries.isEmpty) {
      return Center(child: Text(context.i18n.no_changelog));
    }
    return RefreshIndicator(
      onRefresh: _fetchChangelog,
      child: ListView.builder(
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
    );
  }
}

class ChangelogCard extends StatelessWidget {
  final ChangelogEntry entry;
  final VoidCallback onTap;

  const ChangelogCard({super.key, required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    bool isSupport =
        supportList["support-version"] == null ? false : supportList["support-version"].contains(entry.version);
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
              Chip(
                padding: const EdgeInsets.all(0),
                side: BorderSide(color: _getSupportTypeColor(isSupport)),
                backgroundColor: _getSupportTypeColor(isSupport).withOpacity(0.16),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                label: Text(
                  _getSupportLocalizedType(isSupport),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              _buildTypeChip(context, entry),
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
                color: context.theme.textTheme.bodySmall?.color?.withOpacity(0.5),
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
    bool isSupport =
        supportList["support-version"] == null ? false : supportList["support-version"].contains(entry.version);
    return Scaffold(
      appBar: AppBar(title: Text(context.i18n.version_details), elevation: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'v${entry.version} ${_getLocalizedType(entry.type)}',
                style: context.theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Chip(
                    padding: const EdgeInsets.all(0),
                    side: BorderSide(color: _getSupportTypeColor(isSupport)),
                    backgroundColor: _getSupportTypeColor(isSupport).withOpacity(0.16),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    label: Text(
                      _getSupportLocalizedType(isSupport),
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildTypeChip(context, entry),
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
