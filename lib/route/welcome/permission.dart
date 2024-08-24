import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionPage extends StatefulWidget {
  const PermissionPage({Key? key}) : super(key: key);

  @override
  State<PermissionPage> createState() => _PermissionPageState();
}

class _PermissionPageState extends State<PermissionPage> {
  final List<PermissionItem> permissions = [
    PermissionItem(
      icon: Icons.notifications,
      text: 'Notification',
      description: 'Allow notifications for important updates',
      color: Colors.orange,
      permission: Permission.notification,
    ),
    PermissionItem(
      icon: Icons.location_on,
      text: 'Location',
      description: 'Enable location-based services',
      color: Colors.blue,
      permission: Permission.location,
    ),
    PermissionItem(
      icon: Icons.storage,
      text: 'Storage',
      description: 'Allow saving images and data visualization',
      color: Colors.green,
      permission: Permission.storage,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Icon(
                        Icons.security,
                        size: 80,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Privacy Policy',
                        style: Theme.of(context).textTheme.headlineMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'We are committed to protecting your privacy. Please review and grant the following permissions to use all features of the app.',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ...permissions.map(_buildPermissionCard).toList(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  if (await _areAllPermissionsGranted()) {
                    // Navigate to next page
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please grant all permissions to continue')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionCard(PermissionItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: item.color.withOpacity(0.1),
          child: Icon(item.icon, color: item.color),
        ),
        title: Text(item.text),
        subtitle: Text(item.description),
        trailing: _buildPermissionSwitch(item),
      ),
    );
  }

  Widget _buildPermissionSwitch(PermissionItem item) {
    return FutureBuilder<bool>(
      future: item.permission.isGranted,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }
        final isGranted = snapshot.data ?? false;
        return Switch(
          value: isGranted,
          onChanged: (value) async {
            if (value) {
              final status = await item.permission.request();
              setState(() {
                item.isGranted = status.isGranted;
              });
            } else {
              openAppSettings();
            }
          },
        );
      },
    );
  }

  Future<bool> _areAllPermissionsGranted() async {
    for (var item in permissions) {
      if (!(await item.permission.isGranted)) {
        return false;
      }
    }
    return true;
  }
}

class PermissionItem {
  final IconData icon;
  final String text;
  final String description;
  final Color color;
  final Permission permission;
  bool isGranted;

  PermissionItem({
    required this.icon,
    required this.text,
    required this.description,
    required this.color,
    required this.permission,
    this.isGranted = false,
  });
}