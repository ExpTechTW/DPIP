/// 權限警告堆疊訊息
library;

import 'package:dpip/shared/widgets/location_permission_banner.dart';
import 'package:dpip/shared/widgets/notification_permission_banner.dart';
import 'package:flutter/material.dart';

/// Stacks the location + notification nudges at the shell top.
///
/// Each banner owns its own [SafeArea] **only when visible**. Do not wrap this
/// stack in SafeArea — empty banners are [SizedBox.shrink], and an outer
/// SafeArea would still eat the status-bar inset above full-bleed tabs.
class PermissionBanners extends StatelessWidget {
  const PermissionBanners({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [LocationPermissionBanner(), NotificationPermissionBanner()],
    );
  }
}
