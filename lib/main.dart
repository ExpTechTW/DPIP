import 'dart:io';

import 'package:dpip/app/android.dart';
import 'package:dpip/app/ios.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:easy_localization_loader/easy_localization_loader.dart';
import 'package:flutter/material.dart';

import 'core/service.dart';

List<Locale> lang_list = const [Locale('zh', 'Hant'), Locale('ja'), Locale('en', 'US'), Locale('ko')];
String lang_path = 'assets/langs';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  final isNotificationEnabled = await requestNotificationPermission();
  final isLocationAlwaysEnabled = await requestLocationAlwaysPermission();
  if (isLocationAlwaysEnabled && isNotificationEnabled) {
    await initializeService();
  }
  if (Platform.isIOS) {
    runApp(EasyLocalization(
      supportedLocales: lang_list,
      path: lang_path,
      assetLoader: const YamlAssetLoader(),
      child: const CupertinoDPIP(),
    ));
  } else {
    runApp(EasyLocalization(
      supportedLocales: lang_list,
      path: lang_path,
      assetLoader: const YamlAssetLoader(),
      child: const AndroidDPIP(),
    ));
  }
}
