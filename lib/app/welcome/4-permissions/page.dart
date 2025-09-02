import 'dart:io';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dpip/app/home/page.dart';
import 'package:dpip/core/i18n.dart';
import 'package:dpip/core/preference.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/utils/log.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:permission_handler/permission_handler.dart';

class WelcomePermissionPage extends StatefulWidget {
  const WelcomePermissionPage({super.key});

  static const route = '/welcome/permissions';

  @override
  State<WelcomePermissionPage> createState() => _WelcomePermissionPageState();
}

class _WelcomePermissionPageState extends State<WelcomePermissionPage> with WidgetsBindingObserver {
  late Future<List<Permission>> _permissionsFuture;
  late Future<bool> _autoStartPermission;
  bool _autoStartStatus = false;
  bool _isRequestingPermission = false;
  bool _isNotificationPermission = false;

  Future<void> getNotify() async {
    if (!_isNotificationPermission) {
      await Permission.notification.request();
      if (Platform.isIOS) {
        final NotificationSettings iosrp = await FirebaseMessaging.instance.requestPermission(
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
      context.go(HomePage.route);
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

  // Future<void> _autoStartStatusCheck() async {
  //   _autoStartStatus = await Autostarter.checkAutoStartState() ?? true;
  //   _autoStartPermission = Future.value(_autoStartStatus);
  // }

  Future<void> _checkNotificationPermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.notification.status;
      _isNotificationPermission = status.isGranted;
    } else if (Platform.isIOS) {
      _isNotificationPermission = await AwesomeNotifications().isNotificationAllowed();
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
        // if (Platform.isAndroid) {
        //   _autoStartStatus = (await Autostarter.checkAutoStartState())!;
        //   _autoStartPermission = Future.value(_autoStartStatus);
        // }
      });
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
          permissions = [Permission.notification, Permission.locationAlways, Permission.photosAddOnly];
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
          permissions = [Permission.notification, Permission.location, Permission.photosAddOnly];
        }
      }

      await _checkNotificationPermission();
    } catch (e) {
      TalkerManager.instance.error('Error initializing permissions: $e');
    }

    return permissions;
  }

  List<PermissionItem> _createPermissionItems(List<Permission> permissions, BuildContext context) {
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
          description = '用於儲存中央氣象署或 ExpTech 提供之數據可視化圖片'.i18n;
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: context.colors.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: item.isHighlighted ? Border.all(color: Colors.red, width: 2) : null,
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
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2));
        }
        final status = snapshot.data ?? PermissionStatus.denied;

        return Switch(value: status.isGranted, onChanged: (value) => _handlePermissionChange(item, value));
      },
    );
  }

  Future<void> _handlePermissionChange(PermissionItem item, bool value) async {
    if (_isRequestingPermission) return;

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
            final NotificationSettings iosrp = await FirebaseMessaging.instance.requestPermission(
              announcement: true,
              carPlay: true,
              criticalAlert: true,
              provisional: true,
            );
            if (iosrp.criticalAlert == AppleNotificationSetting.enabled) {
              _isNotificationPermission = true;
            }
          }
        } else if (item.permission == Permission.location) {
          status = await item.permission.status;
          if (status.isPermanentlyDenied) {
            _showPermanentlyDeniedDialog(item);
          }
          if (Platform.isAndroid) {
            _permissionsFuture = _initializePermissions();
            item.permission = Permission.locationAlways;
            if (status.isDenied) {
              status = await item.permission.request();
              if (status.isPermanentlyDenied) {
                _showPermanentlyDeniedDialog(item);
              } else if (status.isDenied) {
                _showPermanentlyDeniedDialog(item);
              } else if (status.isGranted) {
                _showPermanentlyDeniedDialog(item);
              }
            } else if (status.isGranted) {
              status = await item.permission.request();
              if (status.isPermanentlyDenied) {
                _showPermanentlyDeniedDialog(item);
              } else if (status.isDenied) {
                _showPermanentlyDeniedDialog(item);
              } else if (status.isGranted) {
                _showPermanentlyDeniedDialog(item);
              }
            }
          }
        } else if (item.permission == Permission.locationAlways) {
          status = await item.permission.status;
          if (status.isPermanentlyDenied) {
            _showPermanentlyDeniedDialog(item);
          }
          if (Platform.isAndroid) {
            _permissionsFuture = _initializePermissions();
            if (status.isDenied) {
              status = await item.permission.request();
              if (status.isPermanentlyDenied) {
                _showPermanentlyDeniedDialog(item);
              } else if (status.isDenied) {
                _showPermanentlyDeniedDialog(item);
              } else if (status.isGranted) {
                _showPermanentlyDeniedDialog(item);
              }
            } else if (status.isGranted) {
              status = await item.permission.request();
              if (status.isPermanentlyDenied) {
                _showPermanentlyDeniedDialog(item);
              } else if (status.isDenied) {
                _showPermanentlyDeniedDialog(item);
              } else if (status.isGranted) {
                _showPermanentlyDeniedDialog(item);
              }
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

      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to change permission: ${item.text}')));
    } finally {
      setState(() {
        _isRequestingPermission = false;
      });
    }
  }

  void _showPermanentlyDeniedDialog(PermissionItem item) {
    showDialog(
      context: context,
      builder:
          (BuildContext context) => AlertDialog(
            title: Text('權限請求'.i18n),
            content: Text('需要使用者手動到設定開啟相關權限。'.i18n),
            actions: [
              TextButton(child: Text('取消'.i18n), onPressed: () => Navigator.of(context).pop()),
              TextButton(
                child: Text('確定'.i18n),
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
          child: FilledButton(onPressed: getNotify, child: Text('下一步'.i18n)),
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
                    child: Icon(Symbols.security_rounded, size: 80, color: context.colors.primary),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      '權限'.i18n,
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
                          '我們一直和使用者站在一起，為使用者的隱私而不斷努力。'.i18n,
                          style: context.theme.textTheme.titleMedium?.copyWith(
                            color: context.colors.primary.withValues(alpha: 0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          '防災資訊平台',
                          style: context.theme.textTheme.titleMedium?.copyWith(
                            color: context.colors.primary.withValues(alpha: 0.7),
                          ),
                          textAlign: TextAlign.center,
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
            // if (Platform.isAndroid)
            //   Column(children: [
            //     Padding(
            //       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            //       child: Container(
            //         decoration: BoxDecoration(
            //           color: context.colors.surfaceContainer,
            //           borderRadius: BorderRadius.circular(16),
            //           border: null,
            //         ),
            //         child: ListTile(
            //           leading: CircleAvatar(
            //             backgroundColor: Colors.orange.withValues(alpha: 0.1),
            //             child: const Icon(Icons.start, color: Colors.orange),
            //           ),
            //           title: const Text('自動化啟動'),
            //           subtitle: const Text('允許 DPIP 在設備重新啟動或關閉後自動啟動，以持續提供防災通知服務。'),
            //           trailing: FutureBuilder<bool>(
            //             future: _autoStartPermission,
            //             builder: (context, snapshot) {
            //               if (snapshot.connectionState == ConnectionState.waiting) {
            //                 return const SizedBox(
            //                   width: 24,
            //                   height: 24,
            //                   child: CircularProgressIndicator(strokeWidth: 2),
            //                 );
            //               }
            //               _autoStartStatus = _autoStartStatus == true ? _autoStartStatus : snapshot.data ?? false;
            //               return Switch(
            //                 value: _autoStartStatus,
            //                 onChanged: (value) async {
            //                   setState(() {
            //                     _autoStartStatus = value;
            //                   });
            //                   final isAvailable = await Autostarter.isAutoStartPermissionAvailable();
            //                   if (isAvailable!) {
            //                     await Autostarter.getAutoStartPermission(newTask: true);
            //                     final newStatus = await Autostarter.checkAutoStartState();
            //                     _autoStartStatus = newStatus!;
            //                   }

            //                   _autoStartPermission = Future.value(_autoStartStatus);

            //                   setState(() {});
            //                 },
            //               );
            //             },
            //           ),
            //         ),
            //       ),
            //     )
            //   ]),
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
  Permission permission;
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
