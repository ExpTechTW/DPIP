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

class _PermissionPageState extends State<PermissionPage> with WidgetsBindingObserver {
  late Future<List<Permission>> _permissionsFuture;
  bool _isRequestingPermission = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _permissionsFuture = _initializePermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setState(() {
        _permissionsFuture = _initializePermissions();
      });
    }
  }

  Future<List<Permission>> _initializePermissions() async {
    final deviceInfo = DeviceInfoPlugin();
    List<Permission> permissions = [];

    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        permissions = [
          Permission.notification,
          Permission.location,
          androidInfo.version.sdkInt <= 32 ? Permission.storage : Permission.photos,
        ];
      } else if (Platform.isIOS) {
        permissions = [
          Permission.notification,
          Permission.location,
          Permission.photos,
        ];
      }
    } catch (e) {
      print('Error initializing permissions: $e');
    }

    return permissions;
  }

  List<PermissionItem> _createPermissionItems(List<Permission> permissions, BuildContext context) {
    final items = <PermissionItem>[];
    for (final permission in permissions) {
      IconData icon;
      String text;
      String description;
      Color color;

      switch (permission) {
        case Permission.notification:
          icon = Icons.notifications;
          text = context.i18n.notification;
          description = context.i18n.notification_service_description;
          color = Colors.orange;
          break;
        case Permission.location:
          icon = Icons.location_on;
          text = context.i18n.settings_position;
          description = context.i18n.location_based_service;
          color = Colors.blue;
          break;
        case Permission.storage:
        case Permission.photos:
          icon = Platform.isAndroid ? Icons.storage : Icons.photo_library;
          text = context.i18n.image_save;
          description = context.i18n.data_visualization_storage;
          color = Colors.green;
          break;
        default:
          continue;
      }

      items.add(PermissionItem(
        icon: icon,
        text: text,
        description: description,
        color: color,
        permission: permission,
      ));
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: FutureBuilder<List<Permission>>(
            future: _permissionsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No permissions to display'));
              }

              final permissionItems = _createPermissionItems(snapshot.data!, context);
              return Column(
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
                          ...permissionItems.map(_buildPermissionCard),
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
              );
            },
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
    return FutureBuilder<PermissionStatus>(
      future: item.permission.status,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        }
        final status = snapshot.data ?? PermissionStatus.denied;
        return Switch(
          value: status.isGranted,
          onChanged: (value) => _handlePermissionChange(item, value),
        );
      },
    );
  }

  Future<void> _handlePermissionChange(PermissionItem item, bool value) async {
    if (_isRequestingPermission) {
      return;
    }

    setState(() {
      _isRequestingPermission = true;
    });

    try {
      PermissionStatus status;
      if (value) {
        status = await item.permission.request();
        if (status.isPermanentlyDenied) {
          _showPermanentlyDeniedDialog(item);
        }
      } else {
        status = await item.permission.status;
        if (status.isGranted) {
          await openAppSettings();
        }
      }

      item.isGranted = status.isGranted;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to change permission: ${item.text}')),
      );
    } finally {
      setState(() {
        _isRequestingPermission = false;
      });
    }
  }

  void _showPermanentlyDeniedDialog(PermissionItem item) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text('權限請求'),
        content: Text('需要使用者手動到設定開啟相關權限。'),
        actions: [
          TextButton(
            child: const Text('取消'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text('設定'),
            onPressed: () {
              openAppSettings();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
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
