/// The fourth welcome step, requesting runtime permissions.
library;

import 'dart:io';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dpip/core/i18n.dart';
import 'package:dpip/core/preference.dart';
import 'package:dpip/router.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/utils/log.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:permission_handler/permission_handler.dart';

/// Guides the user through granting the permissions required by DPIP.
///
/// Displays a list of [PermissionItem] cards for each required permission.
/// Tapping "next" requests notification permission and navigates to the home
/// screen, marking the first-launch flag as complete.
class WelcomePermissionPage extends StatefulWidget {
  /// Creates a [WelcomePermissionPage].
  const WelcomePermissionPage({super.key});

  @override
  State<WelcomePermissionPage> createState() => _WelcomePermissionPageState();
}

class _WelcomePermissionPageState extends State<WelcomePermissionPage>
    with WidgetsBindingObserver {
  late Future<List<Permission>> _permissionsFuture;
  late Future<bool> _autoStartPermission;
  bool _autoStartStatus = false;
  bool _isRequestingPermission = false;
  bool _isNotificationPermission = false;

  Future<void> _checkNotificationPermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.notification.status;
      _isNotificationPermission = status.isGranted;
    } else if (Platform.isIOS) {
      _isNotificationPermission = await AwesomeNotifications()
          .isNotificationAllowed();
    }
  }

  Future<List<Permission>> _initializePermissions() async {
    final deviceInfo = DeviceInfoPlugin();
    List<Permission> permissions = [];

    try {
      final PermissionStatus status = await Permission.location.status;
      if (status.isGranted) {
        if (Platform.isAndroid) {
          final androidInfo = await deviceInfo.androidInfo;
          permissions = [
            Permission.notification,
            Permission.locationAlways,
            if (androidInfo.version.sdkInt <= 28) Permission.storage,
            Permission.ignoreBatteryOptimizations,
          ];
        } else if (Platform.isIOS) {
          permissions = [
            Permission.notification,
            Permission.locationAlways,
            Permission.photosAddOnly,
          ];
        }
      } else {
        if (Platform.isAndroid) {
          final androidInfo = await deviceInfo.androidInfo;
          permissions = [
            Permission.notification,
            Permission.location,
            if (androidInfo.version.sdkInt <= 28) Permission.storage,
            Permission.ignoreBatteryOptimizations,
          ];
        } else if (Platform.isIOS) {
          permissions = [
            Permission.notification,
            Permission.location,
            Permission.photosAddOnly,
          ];
        }
      }

      await _checkNotificationPermission();
    } catch (e) {
      TalkerManager.instance.error('Error initializing permissions: $e');
    }

    return permissions;
  }

  List<PermissionItem> _createPermissionItems(
    List<Permission> permissions,
    BuildContext context,
  ) {
    final items = <PermissionItem>[];
    for (final Permission permission in permissions) {
      IconData icon;
      String text;
      String description;
      Color color;
      bool isHighlighted = false;

      switch (permission) {
        case Permission.notification:
          icon = Icons.notifications;
          text = '通知'.i18n;
          description = '在重大災害發生時以通知來傳遞即時防災資訊'.i18n;
          color = Colors.orange;
          isHighlighted = true;

        case Permission.locationAlways:
        case Permission.location:
          icon = Icons.location_on;
          text = '位置'.i18n;
          description = '使用定位來自動更新所在地設定，提供當地的即時防災資訊'.i18n;
          color = Colors.blue;

        case Permission.ignoreBatteryOptimizations:
          icon = Icons.battery_full;
          text = '省電策略'.i18n;
          description = '允許 DPIP 在背景中持續運行，以便即時防災通知資訊。'.i18n;
          color = Colors.greenAccent;

        case Permission.storage:
        case Permission.photosAddOnly:
          icon = Platform.isAndroid ? Icons.storage : Icons.photo_library;
          text = '儲存'.i18n;
          description = '用於儲存中央氣象署或 ExpTech 提供之資料視覺化圖片'.i18n;
          color = Colors.green;

        default:
          continue;
      }

      items.add(
        PermissionItem(
          icon: icon,
          text: text,
          description: description,
          color: color,
          permission: permission,
          isHighlighted: isHighlighted,
        ),
      );
    }
    return items;
  }

  Widget _buildPermissionCard(PermissionItem item) {
    return Padding(
      padding: const .symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: context.colors.surfaceContainer,
          borderRadius: .circular(16),
          border: item.isHighlighted
              ? Border.all(color: Colors.red, width: 2)
              : null,
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: item.color.withValues(alpha: 0.1),
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
        if (snapshot.connectionState == .waiting) {
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
    if (_isRequestingPermission) return;

    setState(() {
      _isRequestingPermission = true;
    });

    try {
      if (value) {
        await _requestPermission(item);
      } else {
        await openAppSettings();
      }

      setState(() {});
    } catch (e) {
      if (mounted) {
        context.scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('權限請求失敗: ${item.text}')),
        );
      }
    } finally {
      setState(() {
        _isRequestingPermission = false;
      });
    }
  }

  Future<void> _requestPermission(PermissionItem item) async {
    PermissionStatus status;

    switch (item.permission) {
      case Permission.notification:
        await _requestNotificationPermission();

      case Permission.location:
        status = await Permission.location.request();

        if (status.isPermanentlyDenied) {
          _showPermanentlyDeniedDialog(item);
        } else if (status.isGranted) {
          if (Platform.isAndroid) {
            final shouldContinue =
                await _showBackgroundLocationExplanationDialog();

            if (shouldContinue && mounted) {
              await Permission.locationAlways.request();
            }
          }
          _permissionsFuture = _initializePermissions();
        }

      case Permission.locationAlways:
        final shouldContinue = await _showBackgroundLocationExplanationDialog();

        if (shouldContinue && mounted) {
          await Permission.locationAlways.request();
        }

      case Permission.ignoreBatteryOptimizations:
      case Permission.storage:
      case Permission.photosAddOnly:
        status = await item.permission.request();

        if (status.isPermanentlyDenied) {
          _showPermanentlyDeniedDialog(item);
        }

      default:
    }
  }

  Future<void> _requestNotificationPermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.notification.request();
      if (status.isGranted) {
        _isNotificationPermission = true;
      } else if (status.isPermanentlyDenied) {
        await openAppSettings();
      }
    } else if (Platform.isIOS) {
      final NotificationSettings iosSettings = await FirebaseMessaging.instance
          .requestPermission(
            announcement: true,
            carPlay: true,
            criticalAlert: true,
            provisional: false,
          );
      if (iosSettings.criticalAlert == AppleNotificationSetting.enabled) {
        _isNotificationPermission = true;
      }
    }
  }

  void _showPermanentlyDeniedDialog(PermissionItem item) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text('權限請求'.i18n),
        content: Text('需要使用者手動到設定開啟相關權限。'.i18n),
        actions: [
          TextButton(
            child: Text('取消'.i18n),
            onPressed: () => context.pop(),
          ),
          TextButton(
            child: Text('確定'.i18n),
            onPressed: () {
              openAppSettings();
              context.pop();
            },
          ),
        ],
      ),
    );
  }

  Future<bool> _showBackgroundLocationExplanationDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => AlertDialog(
        title: Text('需要背景位置權限'.i18n),
        content: Text(
          '為了在背景持續提供即時防災資訊，DPIP 需要「永遠允許」位置權限。\n\n'
                  '接下來系統會引導您到設定頁面，請選擇「永遠允許」選項。'
              .i18n,
        ),
        actions: [
          TextButton(
            child: Text('稍後'.i18n),
            onPressed: () => context.pop(false),
          ),
          FilledButton(
            child: Text('前往設定'.i18n),
            onPressed: () => context.pop(true),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// Requests notification permission and navigates to the home screen.
  ///
  /// On iOS, also requests critical-alert permission via Firebase Messaging.
  /// Sets [Preference.isFirstLaunch] to `false` before navigating.
  Future<void> getNotify() async {
    if (!_isNotificationPermission) {
      await Permission.notification.request();
      if (Platform.isIOS) {
        final NotificationSettings iosrp = await FirebaseMessaging.instance
            .requestPermission(
              announcement: true,
              carPlay: true,
              criticalAlert: true,
              provisional: true,
            );
        if (iosrp.criticalAlert == AppleNotificationSetting.enabled) {
          _isNotificationPermission = true;
        }
      }
    }
    if (mounted) {
      Preference.isFirstLaunch = false;
      HomeRoute().go(context);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _permissionsFuture = _initializePermissions();
    // if (Platform.isAndroid) {
    //   _autoStartStatusCheck();
    // }
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _checkNotificationPermission();
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const .symmetric(horizontal: 24, vertical: 8),
          child: FilledButton(onPressed: getNotify, child: Text('下一步'.i18n)),
        ),
      ),
      body: SingleChildScrollView(
        padding: context.padding,
        child: Column(
          crossAxisAlignment: .stretch,
          children: [
            Padding(
              padding: const .fromLTRB(0, 32, 0, 16),
              child: Column(
                children: [
                  Padding(
                    padding: const .all(16),
                    child: Icon(
                      Symbols.security_rounded,
                      size: 80,
                      color: context.colors.primary,
                    ),
                  ),
                  Padding(
                    padding: const .all(16),
                    child: Text(
                      '權限'.i18n,
                      style: context.texts.headlineMedium?.copyWith(
                        fontWeight: .bold,
                        color: context.colors.primary,
                      ),
                      textAlign: .center,
                    ),
                  ),
                  Padding(
                    padding: const .all(8),
                    child: Column(
                      children: [
                        Text(
                          '我們一直和使用者站在一起，為使用者的隱私而不斷努力。'.i18n,
                          style: context.texts.titleMedium?.copyWith(
                            color: context.colors.primary.withValues(
                              alpha: 0.7,
                            ),
                          ),
                          textAlign: .center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            FutureBuilder<List<Permission>>(
              future: _permissionsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == .waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No permissions to display'));
                }

                final permissionItems = _createPermissionItems(
                  snapshot.data!,
                  context,
                );
                return Column(
                  children: permissionItems.map(_buildPermissionCard).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == .resumed) {
      setState(() {
        _permissionsFuture = _initializePermissions();
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

/// A data class describing a single permission entry in the welcome flow.
///
/// Used by [_WelcomePermissionPageState] to build the permission list UI.
class PermissionItem {
  /// The icon representing the permission category.
  final IconData icon;

  /// The display name of the permission.
  final String text;

  /// A user-facing explanation of why the permission is needed.
  final String description;

  /// The accent color used for the permission's icon avatar.
  final Color color;

  /// The underlying [Permission] object used to query and request status.
  Permission permission;

  /// Whether this permission has been granted by the user.
  bool isGranted;

  /// Whether this permission should be visually highlighted as important.
  bool isHighlighted;

  /// Creates a [PermissionItem] with the given properties.
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
