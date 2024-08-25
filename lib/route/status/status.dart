import 'package:dpip/api/exptech.dart';
import 'package:dpip/model/server_status.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ServerStatusPage extends StatefulWidget {
  const ServerStatusPage({super.key});

  @override
  _ServerStatusPageState createState() => _ServerStatusPageState();
}

class _ServerStatusPageState extends State<ServerStatusPage> {
  late Future<List<ServerStatus>> _statusFuture;
  final Set<String> _expandedCards = <String>{};

  @override
  void initState() {
    super.initState();
    _statusFuture = _fetchServerStatus();
  }

  Future<List<ServerStatus>> _fetchServerStatus() async {
    return (await ExpTech().getStatus()).reversed.toList();
  }

  void _toggleExpanded(String cardId) {
    setState(() {
      if (_expandedCards.contains(cardId)) {
        _expandedCards.remove(cardId);
      } else {
        _expandedCards.add(cardId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('伺服器狀態', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _statusFuture = _fetchServerStatus();
              });
            },
          ),
        ],
      ),
      body: FutureBuilder<List<ServerStatus>>(
        future: _statusFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text('錯誤: ${snapshot.error}', style: const TextStyle(color: Colors.red, fontSize: 16)),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('沒有可用的數據', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
            );
          }

          final statuses = snapshot.data!;
          return ListView.builder(
            itemCount: statuses.length,
            itemBuilder: (context, index) {
              return _buildStatusCard(statuses[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildStatusCard(ServerStatus status) {
    final allServices = status.services.values.toList();
    final normalServices = allServices.where((s) => s.status == 1).length;
    final abnormalServices = allServices.length - normalServices;

    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (abnormalServices == 0) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
      statusText = "全部正常";
    } else if (abnormalServices == allServices.length) {
      statusColor = Colors.red;
      statusIcon = Icons.error;
      statusText = "全部異常";
    } else {
      statusColor = Colors.orange;
      statusIcon = Icons.warning;
      statusText = "部分異常";
    }

    final cardId = status.formattedTime;
    final isExpanded = _expandedCards.contains(cardId);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          InkWell(
            onTap: () => _toggleExpanded(cardId),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: const BorderRadius.all(Radius.circular(12)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDateTime(status.formattedTime),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, color: statusColor, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              statusText,
                              style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: status.services.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final entry = status.services.entries.elementAt(index);
                return _buildServiceTile(entry.key, entry.value);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildServiceTile(String serviceName, ServiceStatus serviceStatus) {
    return ListTile(
      title: Text(serviceName, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text('延遲: ${serviceStatus.count} ms'),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: serviceStatus.status == 1 ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          serviceStatus.status == 1 ? '正常' : '異常',
          style: TextStyle(
            color: serviceStatus.status == 1 ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  String _formatDateTime(String dateTimeString) {
    final dateTime = DateTime.parse(dateTimeString);
    final formatter = DateFormat('yyyy/MM/dd HH:mm');
    return formatter.format(dateTime);
  }
}
