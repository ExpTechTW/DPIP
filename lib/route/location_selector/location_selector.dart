import 'package:dpip/api/exptech.dart';
import 'package:dpip/global.dart';
import 'package:dpip/route/location_selector/search.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class LocationSelectorRoute extends StatefulWidget {
  final String? city;
  final String? town;

  const LocationSelectorRoute({super.key, this.city, this.town});

  @override
  State<LocationSelectorRoute> createState() => _LocationSelectorRouteState();
}

class _LocationSelectorRouteState extends State<LocationSelectorRoute> {
  late List<String> data;

  @override
  void initState() {
    super.initState();
    if (widget.city == null) {
      data = Global.location.entries.map((e) => e.value.city).toSet().toList();
    } else {
      data = Global.location.entries.where((e) => e.value.city == widget.city).map((e) => e.value.town).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.city ?? "選擇所在地"),
        actions: [
          IconButton(
            icon: Icon(Symbols.search),
            onPressed: () async {
              final result = await showSearch<String>(
                context: context,
                delegate: LocationSelectorSearchDelegate(),
              );
            },
          )
        ],
      ),
      body: ListView.builder(
        itemCount: data.length,
        itemBuilder: (context, index) {
          if (widget.city == null) {
            return ListTile(
              title: Text(data[index]),
              trailing: const Icon(Symbols.arrow_right),
              onTap: () async {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    settings: RouteSettings(name: "/location_selector/${data[index]}"),
                    builder: (context) => LocationSelectorRoute(city: data[index], town: widget.town),
                  ),
                );
              },
            );
          } else {
            return RadioListTile(
              title: Text(data[index]),
              value: data[index],
              groupValue: widget.town,
              controlAffinity: ListTileControlAffinity.trailing,
              onChanged: (value) async {
                if (value == null) return;

                await Global.preference.setString("location-city", widget.city!);
                await Global.preference.setString("location-town", value);

                final town = Global.location.entries.firstWhere((e) => e.value.town == value).value;

                String fcmToken = Global.preference.getString("fcm-token") ?? "";
                await ExpTech().getNotifyLocation(fcmToken, "${town.lat}", "${town.lng}");

                if (!context.mounted) return;
                Navigator.popUntil(context, ModalRoute.withName("/settings"));
              },
            );
          }
        },
      ),
    );
  }
}
