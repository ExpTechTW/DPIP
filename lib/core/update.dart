import 'dart:async';
import 'dart:math';

import 'package:dpip/api/exptech.dart';
import 'package:dpip/core/preference.dart';
import 'package:flutter_icmp_ping/flutter_icmp_ping.dart';
import 'package:ip_country_lookup/ip_country_lookup.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

Future<void> updateInfoToServer() async {
  final latitude = Preference.locationLatitude;
  final longitude = Preference.locationLongitude;

  try {
    if (latitude == null || longitude == null) return;
    if (Preference.notifyToken != '' &&
        DateTime.now().millisecondsSinceEpoch - (Preference.lastUpdateToServerTime ?? 0) > 86400 * 1 * 1000) {
      final random = Random();
      final int rand = random.nextInt(2);

      if (rand != 0) return;

      ExpTech().updateDeviceLocation(token: Preference.notifyToken, coordinates: LatLng(latitude, longitude));
    }

    _performNetworkCheck();
  } catch (e) {
    print('Network info update failed: $e');
  }
}

Future<void> _performNetworkCheck() async {
  try {
    final countryData = await IpCountryLookup().getIpLocationData();

    final ping = Ping('lb.exptech.dev', count: 3, timeout: 3, interval: 1);
    final List<int?> lb_ping = await ping.stream.take(3).map((event) => event.response?.time?.inMilliseconds).toList();

    final ping_dev = Ping('lb-dev.exptech.dev', count: 3, timeout: 3, interval: 1);
    final List<int?> lb_dev_ping = await ping_dev.stream
        .take(3)
        .map((event) => event.response?.time?.inMilliseconds)
        .toList();

    await ExpTech().sendNetWorkInfo(
      ip: countryData.ip ?? '',
      isp: countryData.isp ?? '',
      status: lb_ping,
      status_dev: lb_dev_ping,
    );
  } catch (e) {
    print('Network check failed: $e');
  }
}
