import 'dart:math';

import 'package:dpip/api/exptech.dart';
import 'package:dpip/core/preference.dart';
import 'package:flutter_icmp_ping/flutter_icmp_ping.dart';
import 'package:ip_country_lookup/ip_country_lookup.dart';
import 'package:ip_country_lookup/models/ip_country_data_model.dart';

Future<void> updateInfoToServer() async {
  IpCountryData countryData = await IpCountryLookup().getIpLocationData();

  List<int?> lb_ping = [];
  List<int?> lb_dev_ping = [];

  final ping = Ping('lb.exptech.dev', count: 4, timeout: 3, interval: 1);
  ping.stream.listen((event) {
    lb_ping.add(event.response?.time?.inMilliseconds);

    if (lb_ping.length == 4) {
      final ping_dev = Ping('lb-dev.exptech.dev', count: 4, timeout: 3, interval: 1);
      ping_dev.stream.listen((event) {
        lb_dev_ping.add(event.response?.time?.inMilliseconds);

        if (lb_dev_ping.length == 4) {
          ExpTech().sendNetWorkInfo(ip: countryData.ip, isp: countryData.isp, status: lb_ping, status_dev: lb_dev_ping);
        }
      });
    }
  });

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
