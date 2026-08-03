/// 權限警告堆疊訊息
library;

import 'package:dpip/shared/widgets/location_permission_banner.dart';
import 'package:dpip/shared/widgets/notification_permission_banner.dart';
import 'package:flutter/material.dart';

class PermissionBanners extends StatelessWidget {
  const PermissionBanners({super.key});

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      bottom: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [LocationPermissionBanner(), NotificationPermissionBanner()],
      ),
    );
  }
}
