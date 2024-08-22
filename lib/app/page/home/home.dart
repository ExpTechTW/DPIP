import 'package:flutter/material.dart';
import 'package:dpip/util/extension/build_context.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.i18n.home),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                // color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '台北市 中正區',
                    style: TextStyle(
                      color: context.colors.secondary,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.cloud,
                        color: context.colors.secondary,
                        size: 32,
                      ),
                      const SizedBox(width: 16),
                      Text(
                        '27.0°C',
                        style: TextStyle(
                          color: context.colors.secondary,
                          fontSize: 48,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '降水量: 0.56 mm\n濕度: 89.0 %\n體感: 31.4°C',
                    style: TextStyle(
                      color: context.colors.secondary,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '更新時間: 07/26 00:00',
                    style: TextStyle(
                      color: context.colors.secondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: List.generate(5, (index) {
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getAlertColor(index),
                        child: Text('${index + 1}'),
                      ),
                      title: const Text('test'),
                      subtitle: const Text('2024/06/25 22:26:15\n規模 3.8 深度 17.8 公里'),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getAlertColor(int index) {
    switch (index) {
      case 0:
      case 3:
        return Colors.green;
      case 1:
        return Colors.blue;
      case 2:
        return Colors.orange;
      case 4:
      default:
        return Colors.red;
    }
  }
}