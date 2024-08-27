import 'package:dpip/api/exptech.dart';
import 'package:dpip/model/server_status.dart';
import 'package:dpip/util/extension/build_context.dart';
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.i18n.server_status, style: const TextStyle(fontWeight: FontWeight.bold)),
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
      body: Column(
        children: [
          _buildInfoBox(isDarkMode),
          Expanded(
            child: FutureBuilder<List<ServerStatus>>(
              future: _statusFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text('錯誤: ${snapshot.error}',
                        style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 16)),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Text(context.i18n.no_data_available,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                  );
                }

                final statuses = snapshot.data!;
                return ListView.builder(
                  itemCount: statuses.length,
                  itemBuilder: (context, index) {
                    return _buildStatusCard(statuses[index], isDarkMode);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBox(bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDarkMode ? Colors.black26 : Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: isDarkMode ? Colors.blue[300] : Colors.blue[700]),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              context.i18n.server_status_overview,
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? Colors.white70 : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(ServerStatus status, bool isDarkMode) {
    final allServices = status.services.values.toList();
    final normalServices = allServices.where((s) => s.status == 1).length;
    final abnormalServices = allServices.length - normalServices;

    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (abnormalServices == 0) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
      statusText = context.i18n.all_normal;
    } else if (abnormalServices == allServices.length) {
      statusColor = Colors.red;
      statusIcon = Icons.error;
      statusText = context.i18n.all_abnormal;
    } else {
      statusColor = Colors.orange;
      statusIcon = Icons.warning;
      statusText = context.i18n.partially_abnormal;
    }

    final cardId = status.formattedTime;
    final isExpanded = _expandedCards.contains(cardId);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      color: isDarkMode ? Colors.grey[850] : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          InkWell(
            onTap: () => _toggleExpanded(cardId),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode ? statusColor.withOpacity(0.2) : statusColor.withOpacity(0.1),
                borderRadius: const BorderRadius.all(Radius.circular(12)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDateTime(status.formattedTime),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDarkMode ? statusColor.withOpacity(0.3) : statusColor.withOpacity(0.2),
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
                        color: isDarkMode ? Colors.white70 : Colors.grey,
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
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
              ),
              itemBuilder: (context, index) {
                final entry = status.services.entries.elementAt(index);
                return _buildServiceTile(entry.key, entry.value, isDarkMode);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildServiceTile(String serviceName, ServiceStatus serviceStatus, bool isDarkMode) {
    Color getStatusColor(int status) {
      switch (status) {
        case 1:
          return Colors.green;
        case 2:
          return Colors.orange;
        case -1:
          return isDarkMode ? Colors.grey : Colors.grey[600]!;
        default:
          return Colors.red;
      }
    }

    String getStatusText(int status) {
      switch (status) {
        case 1:
          return context.i18n.normal;
        case 2:
          return context.i18n.unstable;
        case -1:
          return context.i18n.no_data;
        default:
          return context.i18n.abnormal;
      }
    }

    final statusColor = getStatusColor(serviceStatus.status);
    final statusText = getStatusText(serviceStatus.status);

    return ListTile(
      title: Text(
        serviceName,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: isDarkMode ? Colors.white : Colors.black87,
        ),
      ),
      subtitle: Text(
        context.i18n.delay(serviceStatus.count.toString()),
        style: TextStyle(
          color: isDarkMode ? Colors.white70 : Colors.black54,
        ),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isDarkMode ? statusColor.withOpacity(0.3) : statusColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          statusText,
          style: TextStyle(
            color: statusColor,
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
