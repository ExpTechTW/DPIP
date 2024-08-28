import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import "package:dpip/route/welcome/welcome.dart";
import 'package:dpip/util/extension/build_context.dart';
import 'package:dpip/util/log.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:permission_handler/permission_handler.dart';

class WelcomePermissionPage extends StatefulWidget {
  const WelcomePermissionPage({super.key});

  @override
  State<WelcomePermissionPage> createState() => _WelcomePermissionPageState();
}

class _WelcomePermissionPageState extends State<WelcomePermissionPage> with WidgetsBindingObserver {
  late Future<List<Permission>> _permissionsFuture;
  bool _isRequestingPermission = false;
  bool _isNotificationPermission = false;

  void getNotify() {
    if (!_isNotificationPermission) {
      _checkNotificationPermission();
    }
    WelcomeRouteState.of(context)!.complete();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _permissionsFuture = _initializePermissions();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _checkNotificationPermission();
      setState(() {});
    });
  }

  Future<void> _checkNotificationPermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.notification.status;
      _isNotificationPermission = status.isGranted;
    } else if (Platform.isIOS) {
      await Firebase.initializeApp();
      final settings = await FirebaseMessaging.instance.getNotificationSettings();
      _isNotificationPermission = settings.authorizationStatus == AuthorizationStatus.authorized;
    }
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

      await _checkNotificationPermission();
    } catch (e) {
      TalkerManager.instance.error('Error initializing permissions: $e');
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
      bool isHighlighted = false;

      switch (permission) {
        case Permission.notification:
          icon = Icons.notifications;
          text = context.i18n.notification;
          description = context.i18n.notification_service_description;
          color = Colors.orange;
          isHighlighted = true;
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
        isHighlighted: isHighlighted,
      ));
    }
    return items;
  }

  Widget _buildPermissionCard(PermissionItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: context.colors.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: item.isHighlighted ? Border.all(color: Colors.red, width: 2) : null,
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: item.color.withOpacity(0.1),
            child: Icon(item.icon, color: item.color),
          ),
          title: Text(item.text),
          subtitle: Text(item.description),
          trailing: _buildPermissionSwitch(item),
        ),
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
        } else if (item.permission == Permission.notification) {
          if (Platform.isAndroid) {
            if (status == PermissionStatus.granted) {
              _isNotificationPermission = true;
            } else {
              await openAppSettings();
            }
          } else if (Platform.isIOS) {
            await Firebase.initializeApp();
            NotificationSettings iosrp = await FirebaseMessaging.instance.requestPermission(
              alert: true,
              announcement: true,
              badge: true,
              carPlay: true,
              criticalAlert: true,
              provisional: true,
              sound: true,
            );
            if (iosrp.criticalAlert == AppleNotificationSetting.enabled) {
              _isNotificationPermission = true;
            }
          }
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
        title: Text(context.i18n.permission_request),
        content: Text(context.i18n.manual_permission_enablement),
        actions: [
          TextButton(
            child: Text(context.i18n.cancel),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: Text(context.i18n.confirm),
            onPressed: () {
              openAppSettings();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: FilledButton(
            onPressed: getNotify,
            child: Text(context.i18n.next_step),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: context.padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 32, 0, 16),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Icon(
                      Symbols.security_rounded,
                      size: 80,
                      color: context.colors.primary,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      context.i18n.permission,
                      style: context.theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: context.colors.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      children: [
                        Text(
                          context.i18n.privacy_commitment,
                          style: context.theme.textTheme.titleMedium?.copyWith(
                            color: context.colors.primary.withOpacity(0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          context.i18n.disaster_info_platform,
                          style: context.theme.textTheme.titleMedium?.copyWith(
                            color: context.colors.primary.withOpacity(0.7),
                          ),
                          textAlign: TextAlign.center,
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
            FutureBuilder<List<Permission>>(
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
                return Column(children: permissionItems.map(_buildPermissionCard).toList());
              },
            ),
          ],
        ),
      ),
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
  bool isHighlighted;

  PermissionItem({
    required this.icon,
    required this.text,
    required this.description,
    required this.color,
    required this.permission,
    this.isGranted = false,
    required this.isHighlighted,
  });
}
