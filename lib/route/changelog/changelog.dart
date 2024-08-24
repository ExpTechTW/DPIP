import 'package:dpip/api/exptech.dart';
import 'package:dpip/util/extension/build_context.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:dpip/util/extension/build_context.dart';

class ChangelogEntry {
  final String version;
  final String type;
  final String content;

  ChangelogEntry({required this.version, required this.type, required this.content});

  factory ChangelogEntry.fromJson(Map<String, dynamic> json) {
    return ChangelogEntry(
      version: json['ver'],
      type: json['type'],
      content: json['content'],
    );
  }
}

Color _getTypeColor(String type) {
  switch (type.toLowerCase()) {
    case 'alpha':
      return Colors.red;
    case 'beta':
      return Colors.orangeAccent;
    case 'release':
      return Colors.green;
    default:
      return Colors.grey;
  }
}

String _getLocalizedType(String type) {
  // 這裡可以之後替換為 l10n 的實現
  switch (type.toLowerCase()) {
    case 'alpha':
      return '內測版';
    case 'beta':
      return '公測版';
    case 'release':
      return '正式版';
    default:
      return type;
  }
}

Widget _buildTypeChip(BuildContext context, ChangelogEntry entry) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: _getTypeColor(entry.type).withOpacity(0.1),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: _getTypeColor(entry.type).withOpacity(0.3)),
    ),
    child: Text(
      _getLocalizedType(entry.type),
      style: context.theme.textTheme.bodySmall?.copyWith(
        color: _getTypeColor(entry.type),
        fontWeight: FontWeight.bold,
      ),
    ),
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
      setState(() {
        _changelogEntries = data.map((json) => ChangelogEntry.fromJson(json)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '無法載入更新日誌，請稍後再試。';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.i18n.update_log),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Expanded(
                child: _buildChangelogList(),
              ),
            ],
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
      return const Center(child: Text('目前沒有更新日誌'));
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
                MaterialPageRoute(
                  builder: (context) => ChangelogDetailPage(entry: _changelogEntries[index]),
                ),
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

  const ChangelogCard({
    super.key,
    required this.entry,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildTypeChip(context, entry),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'v${entry.version}',
                  style: context.theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
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

  const ChangelogDetailPage({
    Key? key,
    required this.entry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('v${entry.version} ${_getLocalizedType(entry.type)}'),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTypeChip(context, entry),
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
