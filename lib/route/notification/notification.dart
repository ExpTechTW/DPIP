import 'package:flutter/material.dart';

import 'package:intl/intl.dart';

import 'package:dpip/api/exptech.dart';
import 'package:dpip/api/model/notification_record.dart';
import 'package:dpip/utils/extensions/build_context.dart';

class NotificationHistoryPage extends StatefulWidget {
  const NotificationHistoryPage({super.key});

  @override
  _NotificationHistoryPageState createState() => _NotificationHistoryPageState();
}

class _NotificationHistoryPageState extends State<NotificationHistoryPage> {
  List<NotificationRecord> notificationRecords = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchNotificationRecords();
  }

  Future<void> _fetchNotificationRecords() async {
    try {
      final records = await ExpTech().getNotificationHistory();
      notificationRecords = records.reversed.toList();
    } catch (e) {
      errorMessage = '${context.i18n.error_fetching_notifications} $e';
    } finally {
      isLoading = false;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.i18n.notification_record), elevation: 0),
      body: SafeArea(child: _buildNotificationList()),
    );
  }

  Widget _buildNotificationList() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (errorMessage != null) {
      return Center(child: Text(errorMessage!));
    }
    if (notificationRecords.isEmpty) {
      return Center(child: Text(context.i18n.no_notification_history));
    }
    return RefreshIndicator(
      onRefresh: _fetchNotificationRecords,
      child: ListView.builder(
        itemCount: notificationRecords.length,
        itemBuilder: (context, index) {
          return NotificationCard(
            record: notificationRecords[index],
            onTap: () {
              // 導航到詳細資訊頁面
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => NotificationDetailPage(record: notificationRecords[index])),
              );
            },
          );
        },
      ),
    );
  }
}

class NotificationCard extends StatelessWidget {
  final NotificationRecord record;
  final VoidCallback onTap;

  const NotificationCard({super.key, required this.record, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            record.title,
                            style: context.theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _buildCriticalityChip(context),
                      ],
                    ),
                    _buildDateChip(context),
                    const SizedBox(height: 10),
                    Text(
                      record.body,
                      style: context.theme.textTheme.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    _buildAreaChips(context),
                  ],
                ),
              ),
              const SizedBox(width: 10),
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

  Widget _buildCriticalityChip(BuildContext context) {
    return Chip(
      label: Text(
        record.critical ? context.i18n.emergency : context.i18n.me_general,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      backgroundColor: record.critical ? Colors.red.withOpacity(0.16) : Colors.grey.withOpacity(0.16),
      side: BorderSide(color: record.critical ? Colors.red : Colors.grey),
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  Widget _buildDateChip(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.access_time, size: 16, color: context.colors.primary),
        const SizedBox(width: 4),
        Text(_formatDate(record.time), style: TextStyle(color: context.colors.primary, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildAreaChips(BuildContext context) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children:
          record.area
              .take(2)
              .map(
                (area) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: Colors.blue),
                  ),
                  child: Text(area, style: const TextStyle(fontSize: 12)),
                ),
              )
              .toList() +
          (record.area.length > 2
              ? [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: Colors.blue),
                  ),
                  child: Text('+${record.area.length - 2}', style: const TextStyle(fontSize: 12)),
                ),
              ]
              : []),
    );
  }

  String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat('yyyy/MM/dd HH:mm').format(date);
  }
}

class NotificationDetailPage extends StatelessWidget {
  final NotificationRecord record;

  const NotificationDetailPage({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.i18n.notification_details), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(record.title, style: context.theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildDateChip(context),
            const SizedBox(height: 16),
            _buildCriticalityChip(context),
            const SizedBox(height: 16),
            Text(record.body, style: context.theme.textTheme.titleMedium),
            const SizedBox(height: 24),
            Text(context.i18n.notification_area, style: context.theme.textTheme.bodyMedium),
            const SizedBox(height: 8),
            _buildAreasList(context),
          ],
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
          Text(_formatDate(record.time), style: TextStyle(color: context.colors.primary, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildCriticalityChip(BuildContext context) {
    return Chip(
      label: Text(
        record.critical ? context.i18n.emergency_notification : context.i18n.general_notification,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      backgroundColor: record.critical ? Colors.red.withOpacity(0.16) : Colors.grey.withOpacity(0.16),
      side: BorderSide(color: record.critical ? Colors.red : Colors.grey),
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  Widget _buildAreasList(BuildContext context) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children:
          record.area
              .map(
                (area) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: Colors.blue),
                  ),
                  child: Text(area, style: const TextStyle(fontSize: 12)),
                ),
              )
              .toList(),
    );
  }

  String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat('yyyy/MM/dd HH:mm:ss').format(date);
  }
}
