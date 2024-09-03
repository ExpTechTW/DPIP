import 'package:dpip/global.dart';
import 'package:dpip/model/history.dart';
import 'package:dpip/util/extension/build_context.dart';
import 'package:dpip/widget/map/map.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart';

import '../../util/list_icon.dart';

class ThunderstormPage extends StatelessWidget {
  final History item;

  const ThunderstormPage({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(item.text.content['all']?.title ?? ""),
      ),
      body: Stack(
        children: [
          const DpipMap(),
          _buildDraggableSheet(context),
        ],
      ),
    );
  }

  Widget _buildDraggableSheet(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.3,
      minChildSize: 0.1,
      maxChildSize: 0.9,
      snap: true,
      snapSizes: const [0.1, 0.3, 0.9],
      builder: (BuildContext context, ScrollController scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: context.colors.onPrimary,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDragHandle(),
                  const SizedBox(height: 15),
                  _buildWarningHeader(context),
                  const SizedBox(height: 15),
                  _buildWarningDetails(context),
                  const SizedBox(height: 20),
                  _buildAffectedAreas(context),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDragHandle() {
    return Center(
      child: Container(
        width: 40,
        height: 5,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _buildWarningHeader(BuildContext context) {
    final String subtitle = item.text.content["all"]?.subtitle ?? "";
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: context.colors.secondaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(ListIcons.getListIcon(item.icon), size: 32),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            subtitle,
            style: context.theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildWarningDetails(BuildContext context) {
    final DateTime sendTime = item.time.send;
    final int expireTimestamp = item.time.expires['all'];
    final TZDateTime utcDateTime = TZDateTime.fromMillisecondsSinceEpoch(UTC, expireTimestamp);
    final TZDateTime expireTime = TZDateTime.from(utcDateTime, getLocation('Asia/Taipei'));
    final String description = item.text.description["all"] ?? "";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTimeBar(context, sendTime, expireTime),
        const SizedBox(height: 15),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              description,
              style: context.theme.textTheme.bodyLarge,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeBar(BuildContext context, DateTime sendTime, DateTime expireTime) {
    final Duration duration = expireTime.difference(sendTime);
    final Duration elapsed = DateTime.now().difference(sendTime);
    final double progress = elapsed.inSeconds / duration.inSeconds;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTimeInfo(context, Icons.access_time, context.i18n.history_send_time, sendTime),
            const SizedBox(height: 12),
            _buildTimeInfo(context, Icons.timer_off, context.i18n.history_valid_until, expireTime),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: context.colors.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(context.colors.primary),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(DateFormat('MM/dd HH:mm').format(sendTime), style: context.theme.textTheme.bodySmall),
                Text(DateFormat('MM/dd HH:mm').format(expireTime), style: context.theme.textTheme.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeInfo(BuildContext context, IconData icon, String label, DateTime time) {
    return Row(
      children: [
        Icon(icon, size: 20, color: context.colors.secondary),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: context.theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
            Text(
              DateFormat('yyyy/MM/dd HH:mm').format(time),
              style: context.theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAffectedAreas(BuildContext context) {
    final List<int> areaCodes = List<int>.from(item.area);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.i18n.history_influence_area,
          style: context.theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: areaCodes.map((code) => _buildAreaChip(context, code)).toList(),
        ),
      ],
    );
  }

  Widget _buildAreaChip(BuildContext context, int code) {
    final location = Global.location[code.toString()];
    final city = location?.city ?? '';
    final town = location?.town ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8, right: 8),
      child: Material(
        elevation: 2,
        shadowColor: context.colors.shadow,
        borderRadius: BorderRadius.circular(20),
        color: context.colors.surfaceVariant,
        child: InkWell(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('選擇了 $city$town')),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.location_on,
                  size: 16,
                  color: context.colors.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  "$city$town",
                  style: TextStyle(
                    color: context.colors.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
