import 'dart:math';

import 'package:dpip/api/exptech.dart';
import 'package:dpip/core/preference.dart';
import 'package:flutter_icmp_ping/flutter_icmp_ping.dart';
import 'package:ip_country_lookup/ip_country_lookup.dart';
import 'package:ip_country_lookup/models/ip_country_data_model.dart';

Future<void> updateInfoToServer() async {
  IpCountryData countryData = await IpCountryLookup().getIpLocationData();

  try {
    final ping = Ping('lb.exptech.dev', count: 3, timeout: 3, interval: 1);
    final List<int?> lb_ping = await ping.stream.take(3).map((event) => event.response?.time?.inMilliseconds).toList();

    final ping_dev = Ping('lb-dev.exptech.dev', count: 3, timeout: 3, interval: 1);
    final List<int?> lb_dev_ping =
        await ping_dev.stream.take(3).map((event) => event.response?.time?.inMilliseconds).toList();

    await ExpTech().sendNetWorkInfo(ip: countryData.ip, isp: countryData.isp, status: lb_ping, status_dev: lb_dev_ping);
  } catch (e) {
    // 記錄錯誤，但不中斷程式
    print('Network info update failed: $e');
  }

  // 設備位置更新邏輯保持不變
  if (Preference.notifyToken != '' &&
      DateTime.now().millisecondsSinceEpoch - (Preference.lastUpdateToServerTime ?? 0) > 86400 * 1 * 1000) {
    final random = Random();
    final int rand = random.nextInt(2);

    if (rand != 0) return;

    ExpTech().updateDeviceLocation(
      token: Preference.notifyToken,
      lat: Preference.locationLatitude.toString(),
      lng: Preference.locationLongitude.toString(),
    );
  }
}
