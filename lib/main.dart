import 'dart:io';

import 'package:dpip/app/android.dart';
import 'package:dpip/app/ios.dart';
import 'package:flutter/material.dart';

import 'core/service.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  final isNotificationEnabled = await requestNotificationPermission();
  final isLocationAlwaysEnabled = await requestlocationAlwaysPermission();
  if (isLocationAlwaysEnabled && isNotificationEnabled) {
    await initializeService();
  }
  if (Platform.isIOS) {
    runApp(const CupertinoDPIP());
  } else {
    runApp(const AndroidDPIP());
  }
}
