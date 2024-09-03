import 'package:dpip/global.dart';
import 'package:dpip/model/history.dart';
import 'package:dpip/util/extension/build_context.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart';

class ThunderstormPage extends StatelessWidget {
  final History item;

  const ThunderstormPage({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final String title = item.text.content['all']?.title ?? "";
    final String subtitle = item.text.content["all"]?.subtitle ?? "";
    final String description = item.text.description["all"] ?? "";
    final DateTime sendTime = item.time.send;
    final String formattedSendTime = DateFormat('yyyy/MM/dd HH:mm').format(sendTime);
    final int expireTimestamp = item.time.expires['all'];
    final TZDateTime utcDateTime = TZDateTime.fromMillisecondsSinceEpoch(
      UTC,
      expireTimestamp,
    );
    final TZDateTime localDateTime = TZDateTime.from(utcDateTime, getLocation('Asia/Taipei'));
    final String formattedExpireTime = DateFormat('yyyy/MM/dd HH:mm').format(localDateTime);
    final List<int> areaCodes = List<int>.from(item.area);
    const IconData icon = Icons.bolt_rounded;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(icon, size: 48, color: Colors.yellow),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subtitle,
                        style: context.theme.textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${context.i18n.history_send_time}: $formattedSendTime',
                        style: context.theme.textTheme.titleMedium,
                      ),
                      Text(
                        '${context.i18n.history_valid_until}: $formattedExpireTime',
                        style: context.theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              description,
              style: context.theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Text(
              context.i18n.history_influence_area,
              style: context.theme.textTheme.bodyLarge,
            ),
            Wrap(
              spacing: 8,
              children: areaCodes
                  .map((code) => Chip(
                        label:
                            Text("${Global.location[code.toString()]?.city}${Global.location[code.toString()]?.town}"),
                        backgroundColor: Colors.lightBlueAccent,
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}
