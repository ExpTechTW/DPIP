import "package:collection/collection.dart";
import "package:dpip/api/exptech.dart";
import "package:dpip/app/page/home/home.dart";
import "package:dpip/app/page/map/monitor/monitor.dart";
import "package:dpip/app/page/map/radar/radar.dart";
import "package:dpip/global.dart";
import "package:dpip/api/model/location/location.dart";
import "package:dpip/route/location_selector/search.dart";
import "package:dpip/util/extension/build_context.dart";
import "package:flutter/material.dart";
import "package:material_symbols_icons/symbols.dart";

class LocationSelectorRoute extends StatefulWidget {
  final String? city;
  final String? town;

  const LocationSelectorRoute({super.key, this.city, this.town});

  @override
  State<LocationSelectorRoute> createState() => _LocationSelectorRouteState();
}

class _LocationSelectorRouteState extends State<LocationSelectorRoute> {
  late List<String> data;
  bool _isLoading = false;

  Future<void> setLocation(Location location) async {
    setState(() => _isLoading = true);
    try {
      String? code =
          Global.location.entries
              .firstWhereOrNull(
                (l) =>
                    l.value.city == location.city &&
                    l.value.town == location.town,
              )
              ?.key;

      if (code == null) {
        Global.preference.remove("user-code");
      } else {
        Global.preference.setInt("user-code", int.parse(code));
      }

      String fcmToken = Global.preference.getString("fcm-token") ?? "";
      await ExpTech().getNotifyLocation(
        fcmToken,
        "${location.lat}",
        "${location.lng}",
      );
      Global.preference.setDouble("user-lat", location.lat);
      Global.preference.setDouble("user-lon", location.lng);

      if (!mounted) return;
      const MonitorPage(data: 0).createState();
      const HomePage().createState();
      HomePage.updatePosition();
      RadarMap.updatePosition();
      MonitorPage.updatePosition();
      Navigator.popUntil(context, ModalRoute.withName("/settings"));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${context.i18n.error_occurred} $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.city == null) {
      data = Global.location.entries.map((e) => e.value.city).toSet().toList();
    } else {
      data =
          Global.location.entries
              .where((e) => e.value.city == widget.city)
              .map((e) => e.value.town)
              .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.city ?? context.i18n.location_select),
        actions: [
          IconButton(
            icon: const Icon(Symbols.search),
            onPressed:
                _isLoading
                    ? null
                    : () async {
                      final result = await showSearch<Location>(
                        context: context,
                        delegate: LocationSelectorSearchDelegate(),
                      );

                      if (result == null) return;

                      await setLocation(result);
                    },
          ),
        ],
      ),
      body: Stack(
        children: [
          ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, index) {
              if (widget.city == null) {
                return ListTile(
                  title: Text(data[index]),
                  trailing: const Icon(Symbols.arrow_right),
                  onTap:
                      _isLoading
                          ? null
                          : () async {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                settings: RouteSettings(
                                  name: "/location_selector/${data[index]}",
                                ),
                                builder:
                                    (context) => LocationSelectorRoute(
                                      city: data[index],
                                      town: widget.town,
                                    ),
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
                  onChanged:
                      _isLoading
                          ? null
                          : (value) async {
                            if (value == null) return;

                            final location =
                                Global.location.entries.firstWhere((e) {
                                  return (e.value.city == widget.city) &&
                                      (e.value.town == value);
                                }).value;

                            await setLocation(location);
                          },
                );
              }
            },
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
