import 'package:dpip/core/location.dart';
import 'package:dpip/core/notify.dart';
import 'package:dpip/core/service.dart';
import 'package:dpip/global.dart';
import 'package:dpip/util/extension/build_context.dart';
import 'package:dpip/widget/list/tile_group_header.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:permission_handler/permission_handler.dart';

class SettingsLocationView extends StatefulWidget {
  const SettingsLocationView({super.key});

  @override
  State<SettingsLocationView> createState() => _SettingsLocationViewState();
}

class _SettingsLocationViewState extends State<SettingsLocationView> {
  bool isAutoLocatingEnabled = Global.preference.getBool("auto-location") ?? false;
  bool isPermanentlyDenied = false;
  bool isDenied = false;
  bool isNotDenied = false;

  String city = "";
  String town = "";

  @override
  void initState() {
    super.initState();
    initlocstatus();
  }

  Future<void> initlocstatus() async {
    final isNotificationEnabled = await requestNotificationPermission();
    final isLocationAlwaysEnabled = await requestLocationAlwaysPermission();
    if (isLocationAlwaysEnabled.locstatus == "永久拒絕") {
      setState(() {
        isPermanentlyDenied = true;
        isDenied = false;
        isNotDenied = false;
        isAutoLocatingEnabled = false;
        Global.preference.setBool("auto-location", isAutoLocatingEnabled);
      });
    } else if (isLocationAlwaysEnabled.locstatus == "拒絕") {
      setState(() {
        isPermanentlyDenied = false;
        isDenied = true;
        isNotDenied = false;
        isAutoLocatingEnabled = false;
        Global.preference.setBool("auto-location", isAutoLocatingEnabled);
      });
    } else if (!isNotificationEnabled) {
      setState(() {
        isPermanentlyDenied = false;
        isDenied = false;
        isNotDenied = true;
        isAutoLocatingEnabled = false;
        Global.preference.setBool("auto-location", isAutoLocatingEnabled);
      });
    } else {
      setAutoLocationcitytown();
    }
  }

  Future toggleAutoLocation() async {
    if (isAutoLocatingEnabled) {
      stopBackgroundService();
      setState(() {
        isAutoLocatingEnabled = false;
        Global.preference.setBool("auto-location", isAutoLocatingEnabled);
      });
    } else {
      // TODO: Check Permission and start location service
      final isNotificationEnabled = await requestNotificationPermission();
      final isLocationAlwaysEnabled = await requestLocationAlwaysPermission();
      if (isLocationAlwaysEnabled.islocstatus && isNotificationEnabled) {
        await initializeService();
      }
      setState(() {
        if (isLocationAlwaysEnabled.locstatus == "永久拒絕") {
          isPermanentlyDenied = true;
          isDenied = false;
          isNotDenied = false;
          isAutoLocatingEnabled = false;
          Global.preference.setBool("auto-location", isAutoLocatingEnabled);
        } else if (isLocationAlwaysEnabled.locstatus == "拒絕") {
          isPermanentlyDenied = false;
          isDenied = true;
          isNotDenied = false;
          isAutoLocatingEnabled = false;
          Global.preference.setBool("auto-location", isAutoLocatingEnabled);
        } else if (!isNotificationEnabled) {
          isPermanentlyDenied = false;
          isDenied = false;
          isNotDenied = true;
          isAutoLocatingEnabled = false;
          Global.preference.setBool("auto-location", isAutoLocatingEnabled);
        } else {
          isPermanentlyDenied = false;
          isDenied = false;
          isNotDenied = false;
          isAutoLocatingEnabled = true;
          Global.preference.setBool("auto-location", isAutoLocatingEnabled);
          setAutoLocationcitytown();
        }
      });
    }
  }

  Future setAutoLocationcitytown() async {
    String citytowntemp = Global.preference.getString("loc-city-town") ?? "";
    print(citytowntemp);
    if (citytowntemp != "") {
      setState(() {
          List<String> parts = citytowntemp.split(' ');
          city = parts[0];
          town = parts[1];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SwitchListTile(
              tileColor:
                  isAutoLocatingEnabled ? context.colors.primaryContainer : context.colors.surfaceContainerHighest,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                "啟用自動定位",
                style: TextStyle(
                  color: isAutoLocatingEnabled ? context.colors.onPrimaryContainer : context.colors.onSurfaceVariant,
                ),
              ),
              contentPadding: const EdgeInsets.fromLTRB(16, 4, 12, 4),
              value: isAutoLocatingEnabled,
              onChanged: (value) => toggleAutoLocation(),
            ),
          ),
          if (isPermanentlyDenied)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    Symbols.warning,
                    color: context.colors.error,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '定位功能已被永久拒絕，請移至設定"一律允許"權限',
                    style: TextStyle(color: context.colors.error),
                  ),
                ),
                TextButton(child: const Text("設定"), onPressed: () async {await openAppSettings();}),
              ]),
            ),
          if (isDenied)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    Symbols.warning,
                    color: context.colors.error,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '定位功能已被拒絕，請移至設定"一律允許"權限',
                    style: TextStyle(color: context.colors.error),
                  ),
                ),
                TextButton(child: const Text("設定"), onPressed: () async {await openAppSettings();}),
              ]),
            ),
          if (isNotDenied)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    Symbols.warning,
                    color: context.colors.error,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '通知功能已被拒絕，請移至設定允許權限',
                    style: TextStyle(color: context.colors.error),
                  ),
                ),
                TextButton(child: const Text("設定"), onPressed: () async {await openAppSettings();}),
              ]),
            ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Row(children: [
              Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Symbols.info),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text("自動定位功能將使用您的裝置上的 GPS ，根據您的地理位置，自動更新您的所在地，提供即時的天氣和地震資訊，讓您隨時掌握當地最新狀況。"),
              )
            ]),
          ),
          const ListTileGroupHeader(title: "所在地"),
          ListTile(
            leading: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Symbols.location_city),
            ),
            title: Text("縣市"),
            subtitle: Text(city),
            enabled: !isAutoLocatingEnabled,
            onTap: () {},
          ),
          ListTile(
            leading: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Icon(Symbols.forest),
            ),
            title: Text("鄉鎮"),
            subtitle: Text(town),
            enabled: !isAutoLocatingEnabled,
            onTap: () {},
          )
        ],
      ),
    );
  }
}
