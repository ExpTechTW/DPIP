import 'package:flutter/material.dart';

import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';

import 'package:dpip/api/exptech.dart';
import 'package:dpip/api/model/announcement.dart';
import 'package:dpip/utils/extensions/build_context.dart';

final List<TagType> tagTypes = [
  TagType(id: 0, text: "錯誤", color: Colors.red),
  TagType(id: 1, text: "已解決", color: Colors.green),
  TagType(id: 2, text: "影響：小", color: Colors.grey.shade600),
  TagType(id: 3, text: "影響：中", color: Colors.orange.shade700),
  TagType(id: 4, text: "影響：大", color: Colors.purple),
  TagType(id: 5, text: "公告", color: Colors.blue.shade900),
  TagType(id: 6, text: "維修", color: Colors.teal.shade700),
  TagType(id: 7, text: "測試", color: Colors.cyan.shade700),
  TagType(id: 8, text: "變更", color: Colors.pink.shade600),
  TagType(id: 9, text: "完成", color: Colors.lightGreen.shade700),
  TagType(id: 10, text: "地震相關", color: Colors.deepOrange.shade600),
  TagType(id: 11, text: "氣象相關", color: Colors.indigo.shade600),
];

TagType _getTagTypeById(int id) {
  return tagTypes.firstWhere(
    (tagType) => tagType.id == id,
    orElse: () => TagType(id: -1, text: "未知", color: Colors.grey),
  );
}

String _formatDate(int timestamp) {
  final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
  return DateFormat('yyyy/MM/dd HH:mm').format(date);
}

class TagType {
  final int id;
  final String text;
  final Color color;

  TagType({required this.id, required this.text, required this.color});
}

class AnnouncementPage extends StatefulWidget {
  const AnnouncementPage({super.key});

  @override
  _AnnouncementPageState createState() => _AnnouncementPageState();
}

class _AnnouncementPageState extends State<AnnouncementPage> {
  List<Announcement> announcements = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchAnnouncements();
  }

  Future<void> _fetchAnnouncements() async {
    try {
      final fetchedAnnouncements = (await ExpTech().getAnnouncement()).reversed.toList();
      setState(() {
        announcements = fetchedAnnouncements;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = '${context.i18n.error_fetching_announcement} $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.i18n.announcement), elevation: 0),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [const SizedBox(height: 16), Expanded(child: _buildAnnouncementList())],
          ),
        ),
      ),
    );
  }

  Widget _buildAnnouncementList() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (errorMessage != null) {
      return Center(child: Text(errorMessage!));
    }
    if (announcements.isEmpty) {
      return Center(child: Text(context.i18n.no_announcements));
    }
    return RefreshIndicator(
      onRefresh: _fetchAnnouncements,
      child: ListView.builder(
        itemCount: announcements.length,
        itemBuilder: (context, index) {
          return AnnouncementCard(
            announcement: announcements[index],
            tagTypes: tagTypes,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AnnouncementDetailPage(announcement: announcements[index], tagTypes: tagTypes),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class AnnouncementCard extends StatelessWidget {
  final Announcement announcement;
  final List<TagType> tagTypes;
  final VoidCallback onTap;

  const AnnouncementCard({super.key, required this.announcement, required this.tagTypes, required this.onTap});

  @override
  Widget build(BuildContext context) {
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      announcement.title,
                      style: context.theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    _buildDateChip(context),
                    const SizedBox(height: 8),
                    _buildTags(context),
                  ],
                ),
              ),
              const SizedBox(width: 16),
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

  Widget _buildDateChip(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.access_time, size: 12, color: context.colors.primary),
        const SizedBox(width: 4),
        Text(
          _formatDate(announcement.time),
          style: context.theme.textTheme.bodySmall?.copyWith(
            color: context.colors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTags(BuildContext context) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: announcement.tags.map((tagId) => _buildGlassyTag(context, _getTagTypeById(tagId))).toList(),
    );
  }

  Widget _buildGlassyTag(BuildContext context, TagType tagType) {
    return Chip(
      padding: const EdgeInsets.all(0),
      side: BorderSide(color: tagType.color),
      backgroundColor: tagType.color.withOpacity(0.16),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      label: Text(tagType.text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}

class AnnouncementDetailPage extends StatelessWidget {
  final Announcement announcement;
  final List<TagType> tagTypes;

  const AnnouncementDetailPage({super.key, required this.announcement, required this.tagTypes});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.i18n.announcement_details), elevation: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                announcement.title,
                style: context.theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildDateChip(context),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: announcement.tags.map((tagId) => _buildGlassyTag(context, _getTagTypeById(tagId))).toList(),
              ),
              const SizedBox(height: 24),
              MarkdownBody(
                data: announcement.content,
                styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                  h1: context.theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                  h2: context.theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  p: context.theme.textTheme.bodyLarge,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateChip(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: context.colors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.colors.primary.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.calendar_today, size: 18, color: context.colors.primary),
          const SizedBox(width: 8),
          Text(
            _formatDate(announcement.time),
            style: context.theme.textTheme.bodyMedium?.copyWith(
              color: context.colors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassyTag(BuildContext context, TagType tagType) {
    return Chip(
      padding: const EdgeInsets.all(0),
      side: BorderSide(color: tagType.color),
      backgroundColor: tagType.color.withOpacity(0.16),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      label: Text(tagType.text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}
