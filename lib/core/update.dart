import 'dart:async';
import 'dart:math';

import 'package:dpip/api/exptech.dart';
import 'package:dpip/core/preference.dart';
import 'package:dpip/utils/ping.dart';
import 'package:ip_country_lookup/ip_country_lookup.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

Future<void> updateInfoToServer() async {
  final latitude = Preference.locationLatitude;
  final longitude = Preference.locationLongitude;

  try {
    if (latitude == null || longitude == null) return;
    if (Preference.notifyToken != '' &&
        DateTime.now().millisecondsSinceEpoch -
                (Preference.lastUpdateToServerTime ?? 0) >
            86400 * 1 * 1000) {
      final random = Random();
      final int rand = random.nextInt(2);

      if (rand != 0) return;

      ExpTech().updateDeviceLocation(
        token: Preference.notifyToken,
        coordinates: LatLng(latitude, longitude),
      );
    }

    _performNetworkCheck();
  } catch (e) {
    print('Network info update failed: $e');
  }
}

Future<void> _performNetworkCheck() async {
  try {
    final countryData = await IpCountryLookup().getIpLocationData();

    Future<List<int?>> pingHost(
        String host, {
          int count = 3,
          Duration interval = const Duration(seconds: 1),
        }) async {
      final results = <int?>[];

      for (var i = 0; i < count; i++) {
        results.add(
          await tcpPing(
            host,
            port: 443,
            timeout: const Duration(seconds: 3),
          ),
        );
        if (i < count - 1) {
          await Future.delayed(interval);
        }
      }
      return results;
    }

    final lb_ping = await pingHost('lb.exptech.dev');
    final lb_dev_ping = await pingHost('lb-dev.exptech.dev');

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
