import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:dpip/route/welcome/tos.dart';
import 'package:dpip/util/extension/build_context.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionPage extends StatefulWidget {
  const PermissionPage({super.key});

  @override
  State<PermissionPage> createState() => _PermissionPageState();
}

class _PermissionPageState extends State<PermissionPage> {
  late List<PermissionItem> permissions;

  @override
  Future<void> didChangeDependencies() async {
    super.didChangeDependencies();
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    permissions = [
      PermissionItem(
        icon: Icons.notifications,
        text: context.i18n.notification,
        description: context.i18n.notification_service_description,
        color: Colors.orange,
        permission: Permission.notification,
      ),
      PermissionItem(
        icon: Icons.location_on,
        text: context.i18n.settings_position,
        description: context.i18n.location_based_service,
        color: Colors.blue,
        permission: Permission.location,
      ),
      PermissionItem(
        icon: Icons.storage,
        text: context.i18n.image_save,
        description: context.i18n.data_visualization_storage,
        color: Colors.green,
        permission: (androidInfo.version.sdkInt <= 32 || Platform.isIOS) ? Permission.storage : Permission.photos,
      ),
    ];
  }

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
                        color: context.colors.primary,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        context.i18n.permission,
                        style: context.theme.textTheme.headlineMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        context.i18n.privacy_commitment,
                        style: context.theme.textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ...permissions.map(_buildPermissionCard),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _continueToTOS,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(context.i18n.next_step),
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
          onChanged: (value) => _handlePermissionChange(item, value),
        );
      },
    );
  }

  void _handlePermissionChange(PermissionItem item, bool value) async {
    if (value) {
      final status = await item.permission.request();
      setState(() {
        item.isGranted = status.isGranted;
      });
    } else {
      openAppSettings();
    }
  }

  void _continueToTOS() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const TOSPage()),
    );
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
